local CD=require 'B47ANCEDPCFramework/CDPrograms'
local f=PC_FIXTURE;local server=f.server;local drive=server.drive
local snapshot=server.snapshot;snapshot.program='fixture.cd';snapshot.programVersion='1.0.0'
local types={'Fixture.Media'};local enabled=true
local definition={id='fixture.cd',version='1.0.0',mediaTypes=types,enabled=function() return enabled end,
 accepts=function(ctx) return ctx.snapshot.program=='fixture.cd' and ctx.snapshot.programVersion=='1.0.0' end}
local service=CD.new({drive=drive,programs={definition}})
types[1]='Wrong.Media';definition.accepts=function() return false end
assert(CD.version==1 and not pcall(CD.describe,{id='bad id',version='1',mediaTypes={'Fixture.Media'}}))
assert(not pcall(CD.new,{drive=drive,programs={{id='missing',version='1',mediaTypes={'Fixture.Media'}}}}))
local offered=drive.handle(f.actor,'list',{computer=server.position});assert(#offered.choices==1)
local mounted=drive.handle(f.actor,'mount',{computer=server.position,token=offered.choices[1].token})
assert(mounted.status=='ok');local binding=mounted.mounted.drive
local request={drive=binding,media=server.media:getID(),program='fixture.cd',actor='ignored forged identity'}
local auth=service.authorize(f.actor,f.computer,request)
assert(auth.status=='ok' and auth.program.id=='fixture.cd' and auth.program.version=='1.0.0')
assert(auth.media.id==41 and auth.media.drive==binding and auth.media.fullType=='Fixture.Media')
assert(not auth.snapshot and not auth.item and not auth.player,'authorization leaked server objects/private payload')
auth.program.id='mutated';assert(service.authorize(f.actor,f.computer,request).program.id=='fixture.cd')
local list=service.list(f.actor,f.computer,binding);assert(#list.programs==1 and list.programs[1].id=='fixture.cd')
assert(service.resolve(f.actor,f.computer,request).item==server.media)
server.client(true);assert(service.authorize(f.actor,f.computer,request).status=='invalid');server.client(false)
server.permission(false);assert(service.authorize(f.actor,f.computer,request).status=='changed');server.permission(true)
f.home.power=false;assert(service.authorize(f.actor,f.computer,request).status=='unavailable');f.home.power=true
enabled=false;assert(service.authorize(f.actor,f.computer,request).status=='unavailable');enabled=true
snapshot.programVersion='2.0.0';assert(service.authorize(f.actor,f.computer,request).status=='unavailable')
assert(#service.list(f.actor,f.computer,binding).programs==0);snapshot.programVersion='1.0.0'
server.container.items={};assert(service.authorize(f.actor,f.computer,request).status=='changed');server.container.items={server.media}
local originalKind=server.media.kind;server.media.kind='Wrong.Media';assert(service.authorize(f.actor,f.computer,request).status=='changed');server.media.kind=originalKind
request.media=42;assert(service.authorize(f.actor,f.computer,request).status=='changed');request.media=41
request.program='missing';assert(service.authorize(f.actor,f.computer,request).status=='unavailable');request.program='fixture.cd'
request.media=0/0;assert(service.authorize(f.actor,f.computer,request).status=='invalid');request.media=41
assert(service.authorize(f.actor,f.computer,false).status=='invalid')
local rebuilt=CD.new({drive=server.rebuild(),programs={{id='fixture.cd',version='1.0.0',mediaTypes={'Fixture.Media'},accepts=function() return true end}}})
assert(rebuilt.authorize(f.actor,f.computer,request).status=='ok','restart/re-registration lost real binding')
drive.handle(f.actor,'eject',{computer=server.position,drive=binding})
assert(service.authorize(f.actor,f.computer,request).status=='changed','ejected CD authorized')
assert(#server.container.items==1 and server.media:getContainer()==server.container,'CD program API moved or duplicated items')
f.cdService=service
print('PASS OFFLINE CD server API: actual binding, private-payload exclusion, client/forgery/type/version/permission/power refusal, reload, eject and no item moves')
