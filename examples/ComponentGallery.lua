-- Opt-in consumer example. Copy into YOUR mod's client Lua after adding the
-- B47ANCEDPCFramework dependency and examples/Translate strings to your mod.
local PC=require 'B47ANCEDPCFramework/API'
PC.registerApp({
 id='example.component-gallery',titleKey='UI_PCGallery_Title',icon='computer',
 create=function(ctx)
  local UI=ctx.ui;local panel=ctx.window({onResize=function(w,width,height)
   local m=UI.metrics();local gap=12;local usable=math.max(1,width-2*gap)
   local statusHeight=m.font+12
   UI.place(w.tabs,gap,gap,usable,math.max(1,height-statusHeight-3*gap))
   UI.place(w.status,gap,height-statusHeight-gap,usable,statusHeight)
   local page=w.tabs:page('editor');local width=math.max(1,page:getWidth()-2*gap)
   UI.place(w.heading,gap,gap,width,m.font+4)
   UI.place(w.entry,gap,20+m.font,width,m.button)
   UI.place(w.choice,gap,28+m.font+m.button,width,m.button)
   UI.place(w.toolbar,gap,36+m.font+2*m.button,width,m.button)
   local y=w.toolbar.y+w.toolbar:getHeight()+gap
   UI.place(w.list,gap,y,width,math.max(1,page:getHeight()-y-gap))
   UI.place(w.about,gap,gap,width,m.font+4)
   w.tabs:setPageFocus('editor',{{w.entry},{w.choice},{w.apply},{w.list}})
   UI.focus(w,w.tabs:focusRows())
  end})
  panel.tabs=UI.tabView(panel,{tabs={{id='editor',textKey='UI_PCGallery_Editor'},{id='about',textKey='UI_PCGallery_About'}},
   onChange=function() UI.focus(panel,panel.tabs:focusRows()) end})
  local page=panel.tabs:page('editor')
  panel.about=UI.label(panel.tabs:page('about'),{textKey='UI_PCGallery_Status'})
  panel.heading=UI.label(page,{textKey='UI_PCGallery_Heading'})
  panel.entry=UI.textEntry(page,{value=getText('UI_PCGallery_Value')})
  panel.choice=UI.combo(page,{options={
   {textKey='UI_PCGallery_Document',value='document'},
   {textKey='UI_PCGallery_Folder',value='folder'},
   {textKey='UI_PCGallery_Settings',value='settings'}}})
  panel.status=UI.statusBar(panel,{textKey='UI_PCGallery_Status'})
  panel.list=UI.list(page,{})
  panel.toolbar=UI.toolbar(page,{actions={{id='add',textKey='UI_PCGallery_Add',onClick=ctx.guard(function()
   local selected=panel.choice.options[panel.choice.selected]
   panel.list:addItem(panel.entry:getInternalText(),selected and selected.data)
  end)}}})
  panel.apply=panel.toolbar:button('add')
  panel.tabs:setPageFocus('editor',{{panel.entry},{panel.choice},{panel.apply},{panel.list}})
  UI.focus(panel,panel.tabs:focusRows())
  return panel
 end
})
