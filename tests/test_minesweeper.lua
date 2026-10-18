local Game=require 'B47ANCEDPCFramework/Apps/MinesweeperGame'
local function new()
 local seed=3;return Game.new(function(a,b) seed=(seed*73+19)%997;return a+seed%(b-a+1) end)
end
for y=1,9 do for x=1,9 do
 local g=new();assert(g.state=='ready' and g:reveal(x,y));local mines=0
 for yy=1,9 do for xx=1,9 do
  local c=g:cell(xx,yy);if c.mine then mines=mines+1 end
  if math.abs(xx-x)<=1 and math.abs(yy-y)<=1 then assert(not c.mine,'unsafe first reveal') end
  local expected=0
  for yyy=math.max(1,yy-1),math.min(9,yy+1) do for xxx=math.max(1,xx-1),math.min(9,xx+1) do
   if (xxx~=xx or yyy~=yy) and g:cell(xxx,yyy).mine then expected=expected+1 end
  end end
  assert(c.count==expected and not (c.mine and c.open))
 end end
 assert(mines==10 and g:cell(x,y).count==0 and g.revealed>=4)
end end
local g=new();for x=1,9 do assert(g:flag(x,1)) end;assert(g:flag(1,2) and not g:flag(2,2) and g.flags==10)
assert(not g:reveal(1,1) and g.state=='ready');assert(g:flag(1,1) and g.flags==9)
assert(not g:reveal(0,1) and not g:flag(1,10) and not g:cell(0/0,1))
g=new();g:reveal(5,5)
for y=1,9 do for x=1,9 do if not g:cell(x,y).mine then g:reveal(x,y) end end end
assert(g.state=='won' and g.revealed==71 and g.flags==10 and not g:flag(1,1) and not g:reveal(1,1))
g=new();g:reveal(5,5);local exploded
for y=1,9 do for x=1,9 do if g:cell(x,y).mine and not exploded then g:reveal(x,y);exploded=g:cell(x,y) end end end
assert(g.state=='lost' and exploded.exploded and not g:flag(1,1))
-- A deliberately wrong flag beside an opened number must not make chording safe.
g=new();g:reveal(5,5);local chosen
for y=1,9 do for x=1,9 do
 local c=g:cell(x,y)
 if not chosen and c.open and c.count>0 then
  local safe,mines={},{}
  for yy=math.max(1,y-1),math.min(9,y+1) do for xx=math.max(1,x-1),math.min(9,x+1) do
   local other=g:cell(xx,yy)
   if not other.open and not other.mine then safe[#safe+1]={xx,yy} elseif other.mine then mines[#mines+1]={xx,yy} end
  end end
  if #safe>0 and #mines>0 then chosen={x,y,safe=safe,mines=mines,count=c.count} end
 end
end end
assert(chosen,'fixture lacks a chord case')
assert(not g:chord(chosen[1],chosen[2]))
g:flag(chosen.safe[1][1],chosen.safe[1][2])
for i=1,chosen.count-1 do g:flag(chosen.mines[i][1],chosen.mines[i][2]) end
assert(g:chord(chosen[1],chosen[2]) and g.state=='lost','incorrect chord did not expose mine')
g=new();g:reveal(5,5)
for _,point in ipairs(chosen.mines) do g:flag(point[1],point[2]) end
local before=g.revealed;assert(g:chord(chosen[1],chosen[2]) and g.state~='lost' and g.revealed>before,'correct chord failed to reveal safe neighbors')
print('PASS OFFLINE Minesweeper: all 81 first-click positions, exact mines/counts, flood reveal, flag cap, invalid cells, win/loss and incorrect chord')
