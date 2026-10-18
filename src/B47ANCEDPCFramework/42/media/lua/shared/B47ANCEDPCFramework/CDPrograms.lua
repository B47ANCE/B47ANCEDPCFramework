-- CD program API 1. Registered Lua implements programs; discs supply data only.
local Device=require 'B47ANCEDPCFramework/Device'
local CD={version=1}
local function identifier(value)
 return type(value)=='string' and #value>0 and #value<=80 and value:match('^[%w_.-]+$')~=nil
end
function CD.describe(d)
 assert(type(d)=='table' and identifier(d.id) and identifier(d.version),'invalid CD program identity/version')
 assert(type(d.mediaTypes)=='table' and #d.mediaTypes>0,'CD program requires mediaTypes')
 local types,seen={},{}
 for _,fullType in ipairs(d.mediaTypes) do
  assert(type(fullType)=='string' and #fullType<=128 and fullType:match('^[%w_-]+%.[%w_.-]+$') and not seen[fullType],'invalid or duplicate CD media type')
  types[#types+1]=fullType;seen[fullType]=true
 end
 assert(#types>0,'CD program requires mediaTypes')
 return {id=d.id,version=d.version,mediaTypes=types}
end
function CD.acceptsType(d,fullType)
 for _,kind in ipairs(d.mediaTypes) do if kind==fullType then return true end end;return false
end
local function itemID(value)
 return type(value)=='number' and value==value and value%1==0 and value>=-2147483648 and value<=2147483647
end
function CD.new(o)
 assert(type(o)=='table' and type(o.drive)=='table' and type(o.drive.read)=='function','CD programs require a server DriveService')
 local drive=o.drive;local programs={};local service={}
 for _,definition in ipairs(o.programs or {}) do
  local d=CD.describe(definition)
  assert(not programs[d.id] and type(definition.accepts)=='function','duplicate CD program or missing server accepts callback')
  assert(definition.enabled==nil or type(definition.enabled)=='function','invalid CD enabled callback')
  d.accepts=definition.accepts;d.enabled=definition.enabled;programs[d.id]=d
 end
 local function mounted(actor,computer,id)
  if isClient() or not actor or actor:isDead() or not identifier(id) then return nil,'invalid' end
  if not Device.computer(actor,computer,true) then return nil,'unavailable' end
  local item,snapshot,resolved=drive.read(actor,id,computer)
  if not item or resolved~=computer then return nil,'changed' end
  return {player=actor,computer=computer,item=item,snapshot=snapshot,drive=id}
 end
 local function accepts(d,ctx)
  return CD.acceptsType(d,ctx.item:getFullType()) and (not d.enabled or d.enabled(ctx)==true) and d.accepts(ctx)==true
 end
 function service.list(actor,computer,id)
  local ctx,status=mounted(actor,computer,id);if not ctx then return {status=status} end
  local result={status='ok',programs={}}
  for _,d in pairs(programs) do if accepts(d,ctx) then result.programs[#result.programs+1]={id=d.id,version=d.version} end end
  table.sort(result.programs,function(a,b) return a.id<b.id end);return result
 end
 function service.resolve(actor,computer,request)
  if type(request)~='table' or not identifier(request.program) or not itemID(request.media) then return nil,'invalid' end
  local ctx,status=mounted(actor,computer,request.drive);if not ctx then return nil,status end
  local d=programs[request.program]
  if ctx.item:getID()~=request.media then return nil,'changed' end
  if not d or not accepts(d,ctx) then return nil,'unavailable' end
  ctx.program={id=d.id,version=d.version};return ctx
 end
 function service.authorize(actor,computer,request)
  local ctx,status=service.resolve(actor,computer,request);if not ctx then return {status=status} end
  return {status='ok',program=ctx.program,media={id=ctx.item:getID(),drive=ctx.drive,fullType=ctx.item:getFullType()}}
 end
 return service
end
return CD
