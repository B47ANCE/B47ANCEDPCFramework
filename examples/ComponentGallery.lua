-- Opt-in consumer example. Copy into YOUR mod's client Lua after adding the
-- B47ANCEDPCFramework dependency and examples/Translate strings to your mod.
local PC=require 'B47ANCEDPCFramework/API'
PC.registerApp({
 id='example.component-gallery',titleKey='UI_PCGallery_Title',icon='computer',
 create=function(ctx)
  local UI=ctx.ui;local panel=ctx.window({onResize=function(w,width,height)
   local m=UI.metrics();local gap=12;local usable=math.max(1,width-2*gap)
   UI.place(w.heading,gap,gap,usable,m.font+4)
   UI.place(w.entry,gap,20+m.font,usable,m.button)
   UI.place(w.choice,gap,28+m.font+m.button,usable,m.button)
   UI.place(w.apply,gap,36+m.font+2*m.button,usable,m.button)
   local y=48+m.font+3*m.button
   UI.place(w.list,gap,y,usable,math.max(1,height-y-m.font-20))
   UI.place(w.status,gap,height-m.font-8,usable,m.font+4)
  end})
  panel.heading=UI.label(panel,{textKey='UI_PCGallery_Heading'})
  panel.entry=UI.textEntry(panel,{value=getText('UI_PCGallery_Value')})
  panel.choice=UI.combo(panel,{options={
   {textKey='UI_PCGallery_Document',value='document'},
   {textKey='UI_PCGallery_Folder',value='folder'},
   {textKey='UI_PCGallery_Settings',value='settings'}}})
  panel.status=UI.label(panel,{textKey='UI_PCGallery_Status'})
  panel.list=UI.list(panel,{})
  panel.apply=UI.button(panel,{textKey='UI_PCGallery_Add',onClick=ctx.guard(function()
   local selected=panel.choice.options[panel.choice.selected]
   panel.list:addItem(panel.entry:getInternalText(),selected and selected.data)
  end)})
  UI.focus(panel,{{panel.entry},{panel.choice},{panel.apply},{panel.list}})
  return panel
 end
})
