-- Front-facing full PC, independently drawn from the user's approved PC artwork.
-- No bitmap, OS asset or additional engine drawing API is required.
require 'B47ANCEDPCUI/Renderer'
local R=B47ANCEDPCUI.Renderer
local F={}
local function color(r,g,b) return {r=r/255,g=g/255,b=b/255,a=1} end
local P={body=color(204,184,145),edge=color(121,103,73),shade=color(171,148,111),light=color(234,218,182),
 dark=color(61,54,39),rim=color(89,83,61),black=color(8,18,16),green=color(105,165,90)}
local shapes={
 {color='edge',points={40,20,60,0,940,0,960,20,960,688,940,708,60,708,40,688}},
 {color='body',points={46,23,63,6,937,6,954,23,954,684,937,702,63,702,46,684}},
 {color='shade',points={430,704,570,704,570,722,430,722}},
 {color='edge',points={86,48,100,34,900,34,914,48,914,648,900,662,100,662,86,648}},
 {color='rim',points={91,50,103,39,897,39,909,50,909,646,897,657,103,657,91,646}},
 {color='black',points={96,51,103,44,897,44,904,51,904,645,897,652,103,652,96,645}},
 {color='edge',points={50,732,60,722,940,722,950,732,950,822,940,832,60,832,50,822}},
 {color='body',points={56,734,63,728,937,728,944,734,944,818,937,826,63,826,56,818}}
}
-- Scan once in normalized authoring coordinates; render cached horizontal spans.
local spans={}
for _,shape in ipairs(shapes) do
 local points=shape.points;local low,high=1000,0
 for i=2,#points,2 do low=math.min(low,points[i]);high=math.max(high,points[i]) end
 local runs={};local last
 for y=low,high-1 do
  local cuts={};local at=y+.5
  for i=1,#points,2 do
   local j=i+2;if j>#points then j=1 end
   local x1,y1,x2,y2=points[i],points[i+1],points[j],points[j+1]
   if (y1<=at and y2>at) or (y2<=at and y1>at) then cuts[#cuts+1]=x1+(at-y1)*(x2-x1)/(y2-y1) end
  end
  table.sort(cuts)
  for i=1,#cuts-1,2 do
   local x,w=math.floor(cuts[i]),math.ceil(cuts[i+1])-math.floor(cuts[i])
   if last and last.x==x and last.w==w and last.y+last.h==y then last.h=last.h+1
   else last={x=x,y=y,w=w,h=1};runs[#runs+1]=last end
  end
 end
 spans[#spans+1]={color=P[shape.color],runs=runs}
end
local function transform(w,h)
 local scale=math.min(w/1000,h/840)
 return scale,math.floor((w-1000*scale)/2),math.floor((h-840*scale)/2)
end
function F.geometry(w,h,metrics)
 local scale,ox,oy=transform(w,h)
 local function box(x,y,a,b) return {x=ox+math.floor(x*scale),y=oy+math.floor(y*scale),width=math.floor(a*scale),height=math.floor(b*scale)} end
 local screen=box(100,48,800,600);local x,y,width,height=screen.x,screen.y,screen.width,screen.height
 local bar=metrics.button+8;local status=metrics.font+10
 return {x=x,y=y,width=width,height=height,desktopHeight=math.max(1,height-bar-status),bar=bar,status=status,
  powerX=ox+math.floor(856*scale),powerY=oy+math.floor(753*scale),powerWidth=math.max(28,math.floor(40*scale)),powerHeight=math.max(28,math.floor(40*scale)),
  parts={monitor=box(40,0,920,708),systemUnit=box(50,722,900,110)}}
end
function F.draw(widget,w,h)
 local scale,ox,oy=transform(w,h)
 local function rect(x,y,a,b,c) R.rect(widget,ox+math.floor(x*scale),oy+math.floor(y*scale),math.ceil(a*scale),math.ceil(b*scale),c) end
 for _,shape in ipairs(spans) do for _,run in ipairs(shape.runs) do rect(run.x,run.y,run.w,run.h,shape.color) end end
 rect(64,7,873,3,P.light);rect(47,24,3,658,P.light);rect(949,24,4,658,P.shade)
 for i=0,16 do rect(68+i*49,16+(i%3)*5,5,3,P.shade) end
 for i=0,12 do rect(81+i*11,678,6,3,P.rim) end
 rect(808,677,7,5,P.green);rect(435,670,130,23,P.dark)
 local font=B47ANCEDPCUI.Theme.metrics().font
 if scale>=.8 then
  local caption=R.fit('B47 / CRT 93',122*scale);local width=getTextManager():MeasureStringX(B47ANCEDPCUI.Theme.fonts.body,caption)
  R.text(widget,caption,ox+500*scale-width/2,oy+682*scale-font/2,P.light)
 end
 -- Horizontal case: floppy drive, CD tray, front vents and existing logoff control.
 rect(64,729,872,3,P.light);rect(57,735,3,81,P.light);rect(60,819,876,5,P.shade)
 rect(89,745,179,55,P.edge);rect(93,749,171,47,P.shade);rect(106,761,144,9,P.black)
 rect(111,774,103,3,P.light);rect(238,778,12,10,P.body)
 rect(300,744,382,57,P.edge);rect(305,749,372,47,P.body);rect(317,761,346,5,P.black)
 rect(316,782,313,2,P.shade);rect(649,777,15,12,P.shade);rect(318,778,6,3,P.green)
 for row=0,5 do for col=0,8 do rect(714+col*12,747+row*9,8,3,P.dark) end end
 rect(846,744,60,61,P.shade);rect(915,758,6,5,P.green)
end
return F
