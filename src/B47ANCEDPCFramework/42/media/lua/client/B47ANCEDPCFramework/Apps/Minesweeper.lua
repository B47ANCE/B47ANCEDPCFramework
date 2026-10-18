-- Bundled installed app. Board and mood effects are server-authoritative.
local Game=require 'B47ANCEDPCFramework/Apps/MinesweeperGame'
local Client=require 'B47ANCEDPCFramework/MinesweeperClient'
local installed=false
local function tr(key,...) return getText('UI_B47PC_Mines_'..key,...) end
return function(PC)
 local id='b47pc.minesweeper';if installed then return id end
 PC.registerApp({id=id,titleKey='UI_B47PC_Mines_Title',icon='application',create=function(ctx)
  local UI,A=ctx.ui,ctx.assets;local started,finished;local flagMode=false;local panel
  local token,seq,cancel,pending,pendingAt,issue;local generation=0;local reliefUntil=0
  local function elapsed()
   return started and math.max(0,math.floor(((finished or getTimestampMs())-started)/1000)) or 0
  end
  local function update()
   if pending and getTimestampMs()-pendingAt>15000 then
    if cancel then cancel() end;generation=generation+1;pending=false;issue='Unavailable'
    Client.stop(ctx.player,token);token=nil
   end
   local g=panel.game
   if g.state~='ready' and not started then started=getTimestampMs() end
   if (g.state=='won' or g.state=='lost') and not finished then finished=getTimestampMs() end
   panel.counter:setText(tr('Counter',g.mines-g.flags,elapsed()))
   panel.status:setText(tr(pending and 'Pending' or issue or getTimestampMs()<reliefUntil and 'Relief' or g.state))
   panel.mode.title=tr(flagMode and 'FlagMode' or 'RevealMode')
  end
  local function submit(command,args)
   if pending then return end
   generation=generation+1;local current=generation;pending=true;pendingAt=getTimestampMs();issue=false
   cancel=Client.request(ctx.player,command,args,ctx.guard(function(result)
    if generation~=current then return end;pending=false;cancel=nil
    local board=Client.view(result)
    if board then
     panel.game=board;token=result.token;seq=result.seq
     if command=='start' then started=nil;finished=nil;flagMode=false end
     if result.relief then reliefUntil=getTimestampMs()+3000 end
    else issue=result and result.status=='busy' and 'Busy' or 'Unavailable' end
    update()
   end))
   update()
  end
  local function newGame()
   local sq=ctx.computer:getSquare()
   submit('start',{computer={x=sq:getX(),y=sq:getY(),z=sq:getZ(),index=ctx.computer:getObjectIndex()}})
  end
  local function act(x,y,flag)
   if not panel.boardFits or not token then return end
   submit('move',{token=token,seq=seq+1,action=flag and 'flag' or 'reveal',x=x,y=y})
  end
  panel=ctx.window({onResize=function(w,width,height)
   local m=UI.metrics();local gap=12;local usable=math.max(1,width-24)
   UI.place(w.newGame,gap,gap,(usable-8)/2,m.button);UI.place(w.mode,gap+(usable+8)/2,gap,(usable-8)/2,m.button)
   UI.place(w.counter,gap,20+m.button,usable,m.font+4)
   local top=32+m.button+m.font;local statusHeight=m.font+12
   UI.place(w.status,gap,height-statusHeight-gap,usable,statusHeight)
   local room=math.max(0,height-statusHeight-2*gap-top)
   local size=math.floor(math.min(usable/9,room/9,math.max(30,m.font+12)))
   w.boardFits=size>=m.font+4
   local x=gap+math.floor((usable-9*size)/2);local rows={{w.newGame,w.mode}}
   for yy=1,9 do local row={};for xx=1,9 do
    local b=w.tiles[(yy-1)*9+xx];b:setVisible(w.boardFits)
    if w.boardFits then UI.place(b,x+(xx-1)*size,top+(yy-1)*size,size,size);row[#row+1]=b end
   end;if #row>0 then rows[#rows+1]=row end end
   w.small:setVisible(not w.boardFits);UI.place(w.small,gap,top,usable,m.font+4)
   UI.focus(w,rows)
  end,onUpdate=update,onClose=function()
   generation=generation+1;if cancel then cancel() end;Client.stop(ctx.player,token);token=nil
  end})
  panel.game=Game.new();panel.tiles={}
  panel.newGame=UI.button(panel,{textKey='UI_B47PC_Mines_New',onClick=ctx.guard(newGame)})
  panel.mode=UI.button(panel,{textKey='UI_B47PC_Mines_RevealMode',onClick=ctx.guard(function() flagMode=not flagMode;update() end)})
  panel.counter=UI.label(panel,{})
  panel.status=UI.statusBar(panel,{})
  panel.small=UI.label(panel,{textKey='UI_B47PC_Mines_Small'})
  for y=1,9 do for x=1,9 do
   local xx,yy=x,y
   local b=UI.button(panel,{tooltipKey='UI_B47PC_Mines_Help',onClick=ctx.guard(function() act(xx,yy,flagMode) end)})
   -- Right-click is a shortcut; the mode control provides the same action to a controller.
   b.onRightMouseUp=ctx.guard(function() act(xx,yy,true);return true end)
   b.prerender=function(self)
    local c=panel.game:cell(xx,yy);A.panel(self,0,0,self:getWidth(),self:getHeight(),c.exploded and 'shadow' or 'grey')
    A.bevel(self,0,0,self:getWidth(),self:getHeight(),c.open)
   end
   b.render=function(self)
    local c=panel.game:cell(xx,yy);local text='';local role='black'
    if panel.game.state=='lost' and c.flag and not c.mine then text=tr('WrongMark')
    elseif c.flag then text=tr('FlagMark');role='blue'
    elseif c.mine and panel.game.state=='lost' then text=tr('MineMark')
    elseif c.open and c.count>0 then text=tostring(c.count);role=c.count==1 and 'blue' or 'black' end
    if c.exploded then role='white' end
    local color=A.color(role)
    self:drawTextCentre(text,self:getWidth()/2,(self:getHeight()-UI.metrics().font)/2,color.r,color.g,color.b,1,UIFont.Small)
    if self.joypadFocused or self.joyfocus then A.bevel(self,2,2,self:getWidth()-4,self:getHeight()-4,true) end
   end
   panel.tiles[#panel.tiles+1]=b
  end end
  newGame();return panel
 end})
 installed=true;return id
end
