local PC=require 'B47ANCEDPCFramework/API';local f=PC_FIXTURE
assert(require('B47ANCEDPCFramework/Apps/Minesweeper')(PC)=='b47pc.minesweeper','bundled installer not idempotent')
local host=assert(PC.open(0,f.computer,'b47pc.minesweeper'))
assert(host.hooks.icon=='minesweeper' and PC.Assets.hasIcon('minesweeper'),'bundled app lost its custom icon')
local listed=false;for _,entry in ipairs(host.desktopHost.entries) do
 if entry.id=='b47pc.minesweeper' then assert(entry.icon=='minesweeper');listed=true end
end
assert(listed,'Minesweeper icon missing from common desktop')
assert(not host.content and not host.driveIcon:isVisible(),'Minesweeper required a disc or auto-launched')
local w=assert(host:openProgram());host:prerender();assert(w.boardFits and #w.tiles==81 and w.game.state=='ready')
f.advance(150);w.tiles[1].onRightMouseUp();assert(w.game.flags==1 and w.game.state=='ready')
f.advance(150);w.tiles[1].onRightMouseUp();f.advance(150);w.tiles[41].onclick();assert(w.game.state~='ready')
f.advance(2200);host:prerender();local board=w.game
host:desktop();host.task.onclick();assert(w.game==board,'minimize reset board')
w.newGame.onclick();assert(w.game~=board and w.game.state=='ready' and w.game.flags==0)
f.advance(150);w.mode.onclick();w.tiles[1].onclick();assert(w.game.flags==1,'mode control failed to flag')
w.mode.onclick();w.tiles[1].onclick();assert(w.game.state=='ready','flagged tile revealed')
local manager=getTextManager
for _,font in ipairs({14,24,32,42}) do
 getTextManager=function() return {getFontHeight=function() return font end,MeasureStringX=function(_,_,s) return #s*font/2 end} end
 for _,size in ipairs({{700,500},{1500,1300}}) do
  w:setWidth(size[1]);w:setHeight(size[2]);w:updateComputer()
  assert(w.small:isVisible()~=w.boardFits)
  if w.boardFits then
   assert(#w.joypadButtonsY==10)
   for _,tile in ipairs(w.tiles) do
    assert(tile.x>=0 and tile.x+tile.width<=w.width and tile.y>=w.counter.y+w.counter.height and tile.y+tile.height<=w.status.y)
    tile:prerender();tile:render()
   end
  else
   assert(#w.joypadButtonsY==1 and not w.tiles[1]:isVisible())
  end
 end
end
getTextManager=manager
local before=w.game;host:close();w.newGame.onclick();assert(w.game==before,'closed app accepted reset')
f.advance(150);host=assert(PC.open(0,f.computer,'b47pc.minesweeper'));w=host:openProgram();host:prerender()
f.home.power=false;w.tiles[1].onclick();assert(w.game.state=='ready');host:prerender();f.home.power=true
assert(w.closed and not PC.ComputerUI.active[0])
print('PASS OFFLINE bundled Minesweeper UI: explicit/no-CD launch, flag shortcut/mode, local board/minimize/reset, font/size layouts, closed/power guards')
