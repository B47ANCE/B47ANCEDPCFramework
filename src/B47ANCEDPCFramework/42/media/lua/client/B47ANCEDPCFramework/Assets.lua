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
 r(1,0,36,26,'grey');r(5,4,28,17,'black');r(7,6,24,13,'teal');r(15,26,8,4,'grey');r(8,30,24,4,'light')
end
function drawings.disc(r)
 for n=0,5 do local inset=math.abs(2.5-n)*3;r(inset,n*5,36-inset*2,5,n%2==0 and 'light' or 'grey') end
 r(15,12,7,7,'teal')
end
function drawings.writer(r) r(0,10,38,23,'grey');r(4,15,29,4,'black');r(27,25,5,3,'teal') end
function drawings.application(r) r(1,2,36,30,'light');r(3,4,32,7,'blue');r(6,15,9,12,'teal');r(19,15,13,3,'shadow');r(19,22,10,3,'shadow') end
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
