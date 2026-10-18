-- Pure board rules; authoritative gameplay sessions are owned by the server service.
local Game={width=9,height=9,mines=10}
function Game.new(random)
 local g={width=9,height=9,mines=10,state='ready',flags=0,revealed=0,cells={}}
 random=random or math.random
 for i=1,81 do g.cells[i]={mine=false,open=false,flag=false,count=0} end
 local function index(x,y)
  if type(x)~='number' or type(y)~='number' or x%1~=0 or y%1~=0 or x<1 or x>9 or y<1 or y>9 then return end
  return (y-1)*9+x
 end
 local function adjacent(i,visit)
  local x,y=(i-1)%9+1,math.floor((i-1)/9)+1
  for yy=math.max(1,y-1),math.min(9,y+1) do for xx=math.max(1,x-1),math.min(9,x+1) do
   local n=index(xx,yy);if n~=i then visit(n,g.cells[n]) end
  end end
 end
 local function populate(first)
  local excluded={[first]=true};adjacent(first,function(i) excluded[i]=true end)
  local candidates={};for i=1,81 do if not excluded[i] then candidates[#candidates+1]=i end end
  for i=1,10 do
   local n=random(i,#candidates);assert(type(n)=='number' and n%1==0 and n>=i and n<=#candidates,'invalid Minesweeper random result')
   candidates[i],candidates[n]=candidates[n],candidates[i];g.cells[candidates[i]].mine=true
  end
  for i,c in ipairs(g.cells) do adjacent(i,function(_,other) if other.mine then c.count=c.count+1 end end) end
  g.state='playing'
 end
 local function uncover(first)
  local c=g.cells[first];if c.open or c.flag then return false end
  if c.mine then c.open=true;c.exploded=true;g.state='lost';return true end
  local queue,seen={first},{[first]=true};local next=1
  while next<=#queue do
   local i=queue[next];next=next+1;local cell=g.cells[i]
   if not cell.open and not cell.flag and not cell.mine then
    cell.open=true;g.revealed=g.revealed+1
    if cell.count==0 then adjacent(i,function(n,other)
     if not seen[n] and not other.open and not other.flag and not other.mine then seen[n]=true;queue[#queue+1]=n end
    end) end
   end
  end
  if g.revealed==71 then
   g.state='won';for _,cell in ipairs(g.cells) do if cell.mine then cell.flag=true end end;g.flags=10
  end
  return true
 end
 function g:cell(x,y) local i=index(x,y);return i and self.cells[i] end
 function g:flag(x,y)
  local i=index(x,y);local c=i and self.cells[i]
  if not c or c.open or self.state=='won' or self.state=='lost' or not c.flag and self.flags>=10 then return false end
  c.flag=not c.flag;self.flags=self.flags+(c.flag and 1 or -1);return true
 end
 function g:reveal(x,y)
  local i=index(x,y);local c=i and self.cells[i]
  if not c or c.flag or self.state=='won' or self.state=='lost' then return false end
  if c.open then return self:chord(x,y) end
  if self.state=='ready' then populate(i) end
  return uncover(i)
 end
 function g:chord(x,y)
  local i=index(x,y);local c=i and self.cells[i]
  if not c or not c.open or c.count==0 or self.state~='playing' then return false end
  local flags=0;adjacent(i,function(_,cell) if cell.flag then flags=flags+1 end end)
  if flags~=c.count then return false end
  local changed=false
  adjacent(i,function(n,cell) if self.state=='playing' and not cell.flag and not cell.open then changed=uncover(n) or changed end end)
  return changed
 end
 return g
end
return Game
