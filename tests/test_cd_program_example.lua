local PC=require 'B47ANCEDPCFramework/API';local f=PC_FIXTURE;local server=f.server
server.snapshot.program='example.cd-program';server.snapshot.programVersion='1.0.0'
local service=dofile(EXAMPLE_ROOT..'/CDProgramServer.lua')(server.drive,{'Fixture.Media'})
local registered=dofile(EXAMPLE_ROOT..'/CDProgram.lua')({mediaTypes={'Fixture.Media'},
 drive=function(ctx,command,args,reply)
  args.computer=server.position;reply(server.drive.handle(f.actor,command,args))
 end,
 requestRun=function(ctx,request,reply) reply(service.authorize(f.actor,f.computer,request)) end})
assert(registered=='example.cd-program')
local host=assert(PC.open(0,f.computer,registered));local browser=host:openDrive()
assert(not host.mounted and not host.content.b47PCSDKWindow)
browser.insert.onclick();assert(host.mounted and not host.content.b47PCSDKWindow,'physical mount auto-ran CD')
host:runDisc();assert(host.content.b47PCSDKWindow and host.content.message and host.content.status)
local panel=host.content;host:prerender();assert(not panel.closed)
server.container.items={};f.advance(2001);host:prerender()
assert(panel.closed and not host.content,'actual server media loss failed to close CD program')
server.container.items={server.media};host:close()
server.drive.handle(f.actor,'eject',{computer=server.position,drive=f.computer:getModData().FixtureDrive})
assert(#server.container.items==1,'example changed physical CD ownership')
print('PASS OFFLINE real CD consumer examples: opt-in registration, server-owned list/mount/authorize, explicit EXE launch, hosted controls and polled media-loss closure')
