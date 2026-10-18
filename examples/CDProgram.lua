-- Opt-in client installer. The owning mod supplies authenticated transports and
-- its own real CD item types; importing this file alone registers nothing.
local PC=require 'B47ANCEDPCFramework/API'
return function(adapter)
 return PC.registerCDProgram({
  id='example.cd-program',version='1.0.0',titleKey='UI_PCCD_Title',file='EXAMPLE.EXE',
  mediaTypes=adapter.mediaTypes,drive=adapter.drive,requestRun=adapter.requestRun,
  create=function(ctx)
   local UI=ctx.ui
   local panel=ctx.window({onResize=function(w,width,height)
    UI.place(w.message,12,12,math.max(1,width-24),UI.metrics().font+4)
    UI.place(w.status,12,height-UI.metrics().font-24,math.max(1,width-24),UI.metrics().font+12)
   end})
   panel.message=UI.label(panel,{textKey='UI_PCCD_Ready'})
   panel.status=UI.statusBar(panel,{text=ctx.program.id..' '..ctx.program.version})
   return panel
  end
 })
end
