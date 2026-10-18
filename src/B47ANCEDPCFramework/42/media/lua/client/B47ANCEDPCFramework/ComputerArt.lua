-- Original code-native pixel artwork. No textures, external OS assets or state.
require 'B47ANCEDPCUI/Renderer'
local R=B47ANCEDPCUI.Renderer
local A={}
local function c(r,g,b) return {r=r,g=g,b=b,a=1} end
A.colors={ink=c(.12,.14,.14),shade=c(.39,.38,.32),shell=c(.73,.71,.61),
 face=c(.83,.81,.71),light=c(.91,.89,.79),edge=c(.59,.57,.48),deck=c(.79,.77,.67),
 recess=c(.24,.25,.22),glass=c(.035,.07,.065),rim=c(.075,.105,.095),
 teal=c(0,.34,.33),glint=c(.16,.30,.28),silver=c(.69,.77,.78),
 white=c(.94,.97,.93),blue=c(.12,.26,.48),green=c(.40,.75,.24),
 amber=c(.93,.65,.23),red=c(.68,.22,.14),paper=c(.98,.96,.83)}
local P=A.colors
-- Each rectangle uses a 32x32 authoring grid; layers are deliberately editable.
A.icons={
 disc={
  {11,1,10,2,'ink'},{7,3,18,2,'ink'},{5,5,22,3,'ink'},
  {3,8,26,9,'ink'},{5,17,22,3,'ink'},{7,20,18,2,'ink'},
  {11,22,10,2,'ink'},{11,2,10,2,'white'},{8,4,16,2,'white'},
  {6,6,20,3,'silver'},{4,9,24,7,'silver'},{6,16,20,3,'silver'},
  {8,19,16,2,'white'},{10,6,4,2,'white'},{7,9,5,2,'white'},
  {20,15,5,2,'white'},{13,8,6,10,'shade'},{12,10,8,6,'shade'},
  {14,10,4,6,'teal'},{13,11,6,4,'teal'},
  {2,20,29,11,'ink'},{3,20,27,2,'light'},{3,22,27,7,'shell'},
  {4,28,25,2,'shade'},{5,23,19,3,'recess'},{6,23,17,1,'ink'},
  {25,24,3,2,'light'},{26,27,2,1,'green'}},
 writer={
  {3,7,26,3,'ink'},{1,10,30,18,'ink'},{3,9,25,3,'light'},
  {2,12,28,14,'shell'},{3,24,26,3,'shade'},{4,15,22,6,'recess'},
  {5,16,20,2,'ink'},{6,20,18,2,'light'},{5,24,3,1,'red'},
  {22,23,5,2,'light'},{19,3,8,2,'ink'},{17,5,12,2,'ink'},
  {16,7,14,10,'ink'},{18,17,10,2,'ink'},{19,4,7,2,'white'},
  {18,7,11,8,'silver'},{20,15,7,2,'white'},{22,8,4,5,'shade'},
  {23,9,2,3,'teal'},{9,22,3,7,'ink'},{12,19,3,7,'ink'},
  {15,16,3,7,'ink'},{18,13,3,7,'ink'},{21,10,3,7,'ink'},
  {10,23,2,4,'amber'},{13,20,2,4,'amber'},{16,17,2,4,'amber'},
  {19,14,2,4,'amber'},{22,11,2,3,'red'},{9,28,2,2,'paper'}},
 application={
  {2,3,26,21,'ink'},{3,4,24,18,'shell'},{5,6,20,14,'blue'},
  {12,24,7,3,'shade'},{7,27,17,3,'ink'},{8,27,15,2,'light'},
  {16,10,14,21,'ink'},{17,11,12,18,'paper'},{17,11,12,3,'green'},
  {19,17,2,2,'blue'},{23,17,4,1,'shade'},{19,21,2,2,'blue'},
  {23,21,4,1,'shade'},{19,25,2,2,'blue'},{23,25,4,1,'shade'}}}
function A.icon(w,kind,x,y,scale)
 for _,v in ipairs(A.icons[kind] or A.icons.application) do
  R.rect(w,x+v[1]*scale,y+v[2]*scale,v[3]*scale,v[4]*scale,P[v[5]])
 end
end
-- Separate 16px silhouettes keep taskbar icons crisp at integer scale.
local mini={
 desktop={{1,1,14,10,'ink'},{2,2,12,8,'shell'},{3,3,10,6,'teal'},{6,11,4,2,'shade'},{3,13,10,2,'light'}},
 drive={{4,0,8,2,'ink'},{2,2,12,7,'silver'},{6,3,4,4,'teal'},{1,9,14,6,'ink'},{2,10,12,4,'shell'},{3,11,8,1,'shade'},{12,12,1,1,'green'}},
 writer={{1,4,14,11,'ink'},{2,5,12,9,'shell'},{3,7,10,2,'shade'},{8,0,6,6,'silver'},{10,1,2,3,'teal'},{5,10,2,4,'amber'},{7,8,2,4,'amber'},{9,6,2,4,'amber'}},
 ledger={{1,1,13,12,'ink'},{2,2,11,10,'blue'},{7,5,8,10,'ink'},{8,6,6,8,'paper'},{9,8,2,1,'green'},{9,11,4,1,'shade'}}}
function A.miniIcon(w,kind,x,y,scale)
 for _,v in ipairs(mini[kind] or mini.ledger) do
  R.rect(w,x+v[1]*scale,y+v[2]*scale,v[3]*scale,v[4]*scale,P[v[5]])
 end
end
local function cutbox(w,x,y,width,height,cut,color)
 R.rect(w,x+cut,y,width-2*cut,height,color)
 R.rect(w,x,y+cut,width,height-2*cut,color)
 for i=0,cut-1 do
  R.rect(w,x+cut-i,y+i,width-2*(cut-i),1,color)
  R.rect(w,x+cut-i,y+height-i-1,width-2*(cut-i),1,color)
 end
end
function A.geometry(width,height,font,button)
 local g={x=88,y=70,width=width-172,height=height-288-math.max(0,font-28)}
 g.taskY=g.y+g.height-button-4
 g.statusY=g.taskY-font-9
 g.desktopHeight=g.statusY-g.y-8
 g.panelY=g.y+g.height+math.max(74,font+46);g.panelHeight=50
 g.powerX=width-110;g.powerY=g.panelY+8
 return g
end
function A.monitor(w,g)
 local width,height=w:getWidth(),w:getHeight()
 -- Broad pedestal, swivel neck and offset rear housing give the case depth.
 cutbox(w,width*.40,height-104,width*.23,72,8,P.shade)
 cutbox(w,width*.42,height-99,width*.19,61,7,P.shell)
 R.rect(w,width*.43,height-80,3,34,P.light)
 cutbox(w,width*.30,height-59,width*.43,29,7,P.edge)
 cutbox(w,width*.20,height-42,width*.61,38,7,P.edge)
 cutbox(w,width*.20,height-46,width*.60,32,6,P.face)
 R.rect(w,width*.22,height-45,width*.56,1,P.light)
 cutbox(w,3,37,width-35,height-134,10,P.edge)
 R.rect(w,5,54,3,height-172,P.light)
 for n=0,9 do R.rect(w,13,112+n*17,3,11,P.shade) end
 -- Heavy front molding, rather than a thin flat border around the desktop.
 cutbox(w,29,3,width-35,height-89,14,P.edge)
 cutbox(w,32,6,width-42,height-97,12,P.face)
 R.rect(w,47,7,width-77,1,P.light)
 R.rect(w,33,25,1,height-140,P.light)
 R.rect(w,width-15,29,3,height-147,P.shell)
 -- A quiet molded lip and directional recess shading replace concentric stripes.
 cutbox(w,g.x-20,g.y-20,g.width+40,g.height+40,12,P.shell)
 cutbox(w,g.x-16,g.y-15,g.width+32,g.height+30,10,P.recess)
 R.rect(w,g.x-6,g.y-15,g.width+12,2,P.shade)
 R.rect(w,g.x+g.width+13,g.y-4,2,g.height+8,P.edge)
 R.rect(w,g.x-5,g.y+g.height+13,g.width+10,1,P.light)
 cutbox(w,g.x-4,g.y-3,g.width+8,g.height+6,4,P.glass)
 -- Reflections stay on the glass rim, away from application text and controls.
 R.rect(w,g.x+8,g.y-2,g.width-16,1,P.glint)
 R.rect(w,g.x-2,g.y+8,1,g.height-16,P.glint)
 local label='B47 / CRT 93';local font=B47ANCEDPCUI.Theme.fonts.body
 local badge=getTextManager():MeasureStringX(font,label)
 local badgeX=math.floor((width-badge-18)/2);local badgeY=g.y+g.height+29
 local badgeH=getTextManager():getFontHeight(font)+8
 R.rect(w,badgeX,badgeY,badge+18,badgeH,P.edge)
 R.rect(w,badgeX+1,badgeY+1,badge+16,badgeH-2,P.recess)
 R.text(w,label,badgeX+9,badgeY+4,P.light)
 -- Separate lower control deck and the inset physical power switch.
 R.rect(w,54,g.panelY-1,width-88,1,P.edge)
 R.rect(w,54,g.panelY,width-88,g.panelHeight,P.deck)
 R.rect(w,54,g.panelY+g.panelHeight-1,width-88,1,P.edge)
 R.rect(w,width-144,g.panelY,1,g.panelHeight,P.edge)
 for n=0,7 do R.rect(w,74+n*11,g.panelY+20,6,3,P.shade) end
 R.rect(w,g.powerX-20,g.powerY+12,6,4,P.recess)
 R.rect(w,g.powerX-19,g.powerY+13,4,2,P.green)
end
function A.power(w)
 local width,height=w:getWidth(),w:getHeight()
 cutbox(w,0,0,width,height,4,P.edge)
 cutbox(w,1,1,width-3,height-3,3,w.pressed and P.shell or P.face)
 local x=math.floor(width/2);local y=math.floor(height/2)
 R.rect(w,x-6,y-3,2,7,P.shade);R.rect(w,x+4,y-3,2,7,P.shade)
 R.rect(w,x-4,y+4,8,2,P.shade);R.rect(w,x-1,y-7,2,8,P.recess)
end
function A.glass(w,g)
 cutbox(w,g.x,g.y,g.width,g.height,6,P.teal)
end
function A.desktop(w)
 cutbox(w,0,0,w:getWidth(),w:getHeight(),6,P.teal)
end
return A
