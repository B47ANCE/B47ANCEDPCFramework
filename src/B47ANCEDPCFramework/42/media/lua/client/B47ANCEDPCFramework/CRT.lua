-- Original Lua geometry adapted from the user's approved B47 / CRT 93 design.
-- No bitmap, OS asset or additional engine drawing API is required.
require 'B47ANCEDPCUI/Renderer'
local R=B47ANCEDPCUI.Renderer
local F={}
local function color(r,g,b) return {r=r/255,g=g/255,b=b/255,a=1} end
local P={body=color(212,208,181),edge=color(151,149,126),shade=color(187,183,158),light=color(233,230,205),
 dark=color(62,64,48),rim=color(112,114,91),black=color(8,18,16),green=color(105,165,90)}
local shapes={
 {color='edge',points={4,52,18,38,30,38,30,17,44,3,899,3,914,17,914,680,900,694,16,694,4,680}},
 {color='body',points={34,20,48,6,896,6,908,18,908,677,895,689,46,689,34,677}},
 {color='shade',points={18,42,31,42,31,665,18,680,7,668,7,54}},
 {color='edge',points={72,68,83,54,842,54,855,68,855,569,841,583,82,583,72,570}},
 {color='rim',points={76,70,86,59,838,59,850,70,850,567,838,578,86,578,76,568}},
 {color='dark',points={82,72,88,66,836,66,844,73,844,564,836,572,89,572,82,565}},
 {color='black',points={86,76,92,70,831,70,838,77,838,560,831,567,92,567,86,561}},
 {color='dark',points={392,694,513,694,513,735,392,735}},
 {color='shade',points={399,695,506,695,506,735,399,735}},
 {color='edge',points={184,744,196,733,275,733,284,723,638,723,648,733,732,733,747,746,747,768,734,780,198,780,184,768}},
 {color='body',points={190,741,200,736,731,736,740,745,740,764,729,773,200,773,190,765}}
}
-- Scan once in normalized authoring coordinates; render cached horizontal spans.
local spans={}
for _,shape in ipairs(shapes) do
 local points=shape.points;local low,high=780,0
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
function F.geometry(w,h,metrics)
 local x,y=math.floor(w*88/920),math.floor(h*70/780)
 local width,height=math.floor(w*748/920),math.floor(h*494/780)
 local bar=metrics.button+8;local status=metrics.font+10
 return {x=x,y=y,width=width,height=height,desktopHeight=math.max(1,height-bar-status),bar=bar,status=status,
  powerX=math.floor(w*810/920),powerY=math.floor(h*644/780),powerWidth=math.max(28,math.floor(w*36/920)),powerHeight=math.max(28,math.floor(h*34/780))}
end
function F.draw(widget,w,h)
 local sx,sy=w/920,h/780
 local function rect(x,y,a,b,c) R.rect(widget,math.floor(x*sx),math.floor(y*sy),math.ceil(a*sx),math.ceil(b*sy),c) end
 for _,shape in ipairs(spans) do for _,run in ipairs(shape.runs) do rect(run.x,run.y,run.w,run.h,shape.color) end end
 rect(47,7,849,2,P.light);rect(36,21,2,653,P.light);rect(905,22,2,641,P.shade)
 rect(8,69,2,593,P.light);rect(13,112,3,11,P.edge)
 rect(56,635,838,2,P.edge);rect(56,638,838,48,P.shade)
 rect(57,684,836,2,P.body);rect(772,638,2,47,P.edge)
 for i=0,8 do rect(74+i*10,656,5,3,P.rim) end
 rect(790,656,5,3,P.green)
 rect(410,592,100,21,P.dark)
 local scale=math.min(sx,sy);local font=B47ANCEDPCUI.Theme.metrics().font
 if scale>=.8 then
  local caption='B47 / CRT 93';local width=getTextManager():MeasureStringX(B47ANCEDPCUI.Theme.fonts.body,caption)
  R.text(widget,caption,460*sx-width/2,602*sy-font/2,P.light)
 end
 rect(402,705,3,18,P.light)
end
return F
