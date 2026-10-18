local PC=require 'B47ANCEDPCFramework/API';local f=PC_FIXTURE;local C=PC.ComputerUI
assert(PC.supports('cd-programs') and PC.getAPIInfo().cdProgramVersion==1)
local created,closed,denied,requests=0,0,0,0;local reply;local context;local active=true;local enabled=true
local row={id=41,name='Fixture CD',fullType='Fixture.Media',drive='fixture-binding'}
local def={id='fixture.cd-client',version='1.0.0',titleKey='UI_Test_CD',file='FIXTURE.EXE',mediaTypes={'Fixture.Media'},
 enabled=function() return enabled end,canUse=function() return active end,
 drive=function(ctx,command,args,callback)
  assert(ctx.player==f.actor and ctx.computer==f.computer)
  if command=='list' then callback({status='ok',mounted=row}) else callback({status='ok'}) end
 end,
 requestRun=function(ctx,request,callback)
  requests=requests+1;assert(request.program=='fixture.cd-client' and request.media==41 and request.drive==row.drive);reply=callback
 end,
 create=function(ctx)
  created=created+1;context=ctx;assert(ctx.program.id=='fixture.cd-client' and ctx.media.id==41)
  local w=ctx.window();w.action=PC.UI.button(w,{text='fixture',onClick=ctx.guard(function() w.replies=(w.replies or 0)+1 end)});return w
 end,onClose=function() closed=closed+1 end,onDenied=function(_,status) assert(status~='ok');denied=denied+1 end}
PC.registerCDProgram(def);def.mediaTypes[1]='Wrong.Media';def.create=function() error('mutated registration ran') end
local function auth(overrides)
 local result={status='ok',program={id='fixture.cd-client',version='1.0.0'},media={id=41,drive=row.drive,fullType='Fixture.Media'}}
 for k,v in pairs(overrides or {}) do result[k]=v end;reply(result);return result
end
local function open()
 local h=assert(PC.open(0,f.computer,'fixture.cd-client'));h:openDrive();assert(created==closed,'mount auto-ran program');return h
end
local host=open();host:runDisc();host:runDisc();assert(requests==1 and created==0,'pending launch duplicated request')
auth({program={id='fixture.cd-client',version='wrong'}});assert(created==0 and denied==1)
host:runDisc();auth({media={id=99,drive=row.drive,fullType='Fixture.Media'}});assert(created==0 and denied==2)
host:runDisc();reply(false);assert(created==0 and denied==3)
host:runDisc();auth({program={id='unknown',version='1.0.0'}});assert(created==0 and denied==4)
host:runDisc();auth({media={id=41,drive='wrong-binding',fullType='Fixture.Media'}});assert(created==0 and denied==5)
host:runDisc();local lastStatus;local message=host.message;host.message=function(self,key) lastStatus=key;return message(self,key) end
auth();assert(created==1 and host.content and context.isActive())
assert(lastStatus=='ComputerCDReady','successful CD launch kept pending status')
local panel=host.content;panel.action.onclick(nil,panel.action);assert(panel.replies==1)
auth();assert(created==1,'duplicate server reply launched twice')
host:applyDrive({status='ok',mounted={id=42,name='replacement',fullType='Fixture.Media',drive=row.drive}})
panel.action.onclick(nil,panel.action);assert(closed==1 and panel.replies==1 and not context.isActive())
host:close()
host=open();host:runDisc();local late=reply;host:closeApp();auth();assert(created==1,'closed browser accepted late launch');host:close();late({status='ok'})
host=open();host:runDisc();active=false;auth();active=true;assert(created==1);host:close()
host=open();host:runDisc();f.home.power=false;auth();f.home.power=true;assert(created==1);host:close()
host=open();host:runDisc();enabled=false;auth();enabled=true;assert(created==1);host:close()
host=open();host:runDisc();local specific=getSpecificPlayer;getSpecificPlayer=function() return {} end
auth();getSpecificPlayer=specific;assert(created==1,'actor replacement accepted run reply');host:close()
host=open();host:runDisc();f.advance(15001);auth();assert(created==1,'timed-out run accepted a reply')
host:runDisc();auth();assert(created==2,'timeout left launcher permanently busy');host:close();assert(closed==2)
local fail={id='fixture.cd-fail',version='1',titleKey='UI_Test_CDFail',file='FAIL.EXE',mediaTypes={'Fixture.Media'},drive=def.drive,
 requestRun=function(_,request,callback) callback({status='ok',program={id='fixture.cd-fail',version='1'},media={id=41,drive=row.drive,fullType='Fixture.Media'}}) end,
 create=function(ctx) ctx.window();error('fixture CD builder failure') end}
PC.registerCDProgram(fail);host=assert(PC.open(0,f.computer,fail.id));host:openDrive()
assert(not pcall(host.runDisc,host) and not host.content,'failed CD builder leaked a window');host:close()
assert(not pcall(PC.registerCDProgram,{id='invalid',version='1',titleKey='Title',file='../BAD.EXE',mediaTypes={'Fixture.Media'}}))
assert(not C.active[0])
print('PASS OFFLINE CD client API: explicit authenticated launch, duplicate/invalid/version/media replies, stale close, permission/power/disable loss, timeout and shared hosted lifecycle')
