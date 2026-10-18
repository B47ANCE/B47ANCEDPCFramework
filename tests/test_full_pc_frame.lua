-- Physical shell bounds and aspect are independent of apps and gameplay.
local F=require 'B47ANCEDPCFramework/CRT'
for _,font in ipairs({14,24,32,42}) do
 for _,size in ipairs({{800,700},{1000,880},{1500,1000},{1000,1500}}) do
  local w,h=size[1],size[2];local g=F.geometry(w,h,{font=font,button=font+12})
  assert(g.width>0 and g.desktopHeight>0 and math.abs(g.width/g.height-4/3)<.01,'screen aspect distorted')
  assert(g.x>=0 and g.y>=0 and g.x+g.width<=w and g.y+g.height<=h)
  assert(g.parts.monitor.y+g.parts.monitor.height<g.parts.systemUnit.y)
  assert(g.parts.keyboard==nil and g.parts.mouse==nil,'shell must contain only monitor and system unit')
  for _,part in pairs(g.parts) do assert(part.x>=0 and part.y>=0 and part.x+part.width<=w and part.y+part.height<=h) end
  local unit=g.parts.systemUnit
  assert(g.powerX>=unit.x and g.powerY>=unit.y and g.powerX+g.powerWidth<=unit.x+unit.width and g.powerY+g.powerHeight<=unit.y+unit.height)
  local calls=0;F.draw({drawRect=function(_,x,y,a,b)
   assert(x>=0 and y>=0 and a>0 and b>0 and x+a<=w+1 and y+b<=h+1,'hardware drawing escaped native root');calls=calls+1
  end,drawText=function() end},w,h);assert(calls>0 and calls<2500,'unbounded shell rendering')
 end
end
local a=F.geometry(1000,700,{font=14,button=26});local b=F.geometry(1400,700,{font=14,button=26})
assert(a.width==b.width and a.height==b.height and b.x>a.x,'widening should center, not stretch the computer')
print('PASS OFFLINE full PC: straight-on component bounds, 4:3 screen, aspect-preserving resize, case power target and bounded drawing')
