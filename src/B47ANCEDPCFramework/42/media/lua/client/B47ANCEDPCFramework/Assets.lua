-- Public drawing assets API 1. Original Lua geometry, no texture/global overrides.
require 'B47ANCEDPCUI/Renderer'
local R=B47ANCEDPCUI.Renderer
local A={version=1}
local function color(r,g,b) return {r=r,g=g,b=b,a=1} end
local palette={case=color(.25,.24,.21),grey=color(.75,.75,.72),light=color(.96,.96,.91),shadow=color(.36,.36,.34),
 black=color(.04,.05,.05),white=color(1,1,.97),blue=color(.03,.07,.38),teal=color(0,.37,.36),muted=color(.3,.32,.32)}
function A.color(name)
 local c=assert(palette[name],'unknown PC color');return {r=c.r,g=c.g,b=c.b,a=c.a}
end
function A.palette() local p={};for name in pairs(palette) do p[name]=A.color(name) end;return p end
function A.bevel(w,x,y,width,height,pressed)
 local first,last=pressed and palette.shadow or palette.light,pressed and palette.light or palette.shadow
 R.rect(w,x,y,width,2,first);R.rect(w,x,y,2,height,first)
 R.rect(w,x,y+height-2,width,2,last);R.rect(w,x+width-2,y,2,height,last)
end
function A.panel(w,x,y,width,height,role)
 R.rect(w,x,y,width,height,assert(palette[role or 'grey'],'unknown PC color'))
end
local drawings={}
function drawings.computer(r)
 r(1,1,37,27,'black');r(3,3,33,23,'grey');r(5,5,29,19,'light');r(7,7,25,15,'shadow')
 r(9,9,21,11,'teal');r(15,28,9,4,'shadow');r(11,32,18,3,'grey');r(6,35,29,3,'light')
end
function drawings.disc(r)
 r(12,0,15,2,'black');r(8,2,23,3,'black');r(5,5,29,4,'black');r(3,9,33,15,'black');r(6,24,27,4,'black')
 r(12,2,14,2,'white');r(9,4,21,3,'light');r(6,7,27,5,'light');r(5,12,29,10,'grey');r(8,22,23,4,'light')
 r(15,11,10,2,'shadow');r(13,13,14,9,'shadow');r(16,13,8,8,'teal');r(17,11,6,2,'teal')
 r(2,27,36,12,'black');r(4,28,32,8,'grey');r(5,29,30,2,'light');r(7,33,24,2,'shadow');r(31,35,3,2,'teal')
end
function drawings.writer(r)
 r(1,12,36,26,'black');r(3,14,32,21,'grey');r(4,14,29,4,'light');r(5,21,26,6,'black');r(7,23,22,2,'shadow')
 r(23,1,13,3,'black');r(21,4,17,23,'black');r(23,5,12,18,'grey');r(25,6,8,10,'light');r(26,8,4,7,'teal')
 r(5,29,15,3,'shadow');r(8,33,3,7,'light');r(12,28,3,9,'light');r(16,25,3,8,'light');r(27,31,6,3,'teal')
end
function drawings.application(r)
 r(1,1,29,25,'black');r(3,3,25,20,'grey');r(5,5,21,15,'blue');r(7,7,17,11,'teal');r(10,26,12,3,'shadow');r(6,29,21,3,'grey')
 r(21,13,17,26,'black');r(23,15,13,22,'light');r(25,17,9,3,'blue')
 for y=23,32,4 do r(25,y,2,2,'teal');r(29,y,5,2,'shadow') end
end
function drawings.folder(r) r(1,7,17,7,'light');r(1,12,36,21,'grey');r(4,15,32,17,'light') end
function drawings.document(r) r(7,1,25,33,'light');for y=8,26,6 do r(11,y,17,2,'shadow') end end
function drawings.settings(r) r(1,3,36,29,'grey');for x=8,30,11 do r(x,7,2,21,'shadow');r(x-3,x==19 and 11 or 20,8,4,'light') end end
function A.hasIcon(id) return type(id)=='string' and drawings[id]~=nil end
function A.registerIcon(id,draw)
 assert(type(id)=='string' and #id<=80 and id:match('^[%w_.-]+$') and type(draw)=='function','invalid PC icon registration')
 assert(not drawings[id] or drawings[id]==draw,'duplicate PC icon')
 drawings[id]=draw;return id
end
function A.icons() local ids={};for id in pairs(drawings) do ids[#ids+1]=id end;table.sort(ids);return ids end
function A.drawIcon(w,id,x,y,size)
 local draw=assert(drawings[id],'unknown PC icon');size=size or 40
 assert(type(size)=='number' and size==size and size>0 and size<math.huge,'invalid PC icon size')
 local scale=size/40
 draw(function(a,b,c,d,role)
  for _,value in ipairs({a,b,c,d}) do assert(type(value)=='number' and value==value and math.abs(value)<math.huge,'invalid PC icon geometry') end
  assert(a>=0 and b>=0 and c>0 and d>0 and a+c<=40 and b+d<=40,'PC icon exceeds its 40x40 drawing bounds')
  R.rect(w,x+a*scale,y+b*scale,c*scale,d*scale,assert(palette[role],'unknown PC icon color'))
 end)
end
function A.text(w,caption,x,y,width,role)
 R.text(w,R.fit(caption,width),x,y,assert(palette[role or 'black'],'unknown PC color'))
end
return A
