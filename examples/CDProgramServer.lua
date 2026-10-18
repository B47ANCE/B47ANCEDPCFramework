-- Opt-in server installer. DriveService already validates the real CD and its
-- app-owned snapshot. Do not call this accepts predicate on client claims.
local CD=require 'B47ANCEDPCFramework/CDPrograms'
return function(drive,mediaTypes)
 return CD.new({drive=drive,programs={{
  id='example.cd-program',version='1.0.0',mediaTypes=mediaTypes,
  accepts=function(ctx)
   return type(ctx.snapshot)=='table' and ctx.snapshot.program=='example.cd-program'
    and ctx.snapshot.programVersion=='1.0.0'
  end
 }}})
end
