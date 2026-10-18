-- Local presentation only. Applications supply already-authorized information.
local Device=require 'B47ANCEDPCFramework/Device'
local N={version=1}
local function boundary(s,n)
 while n>0 and s:byte(n+1) and s:byte(n+1)>=128 and s:byte(n+1)<192 do n=n-1 end
 return n
end
local function valid(host)
 local d=host and host.desktopHost
 return d and type(host.sessionKey)=='string' and d:live(host) and getSpecificPlayer(d.playerNum)==d.actor
  and Device.computer(d.actor,d.computer,true) and host.hooks.enabled() and host.hooks.canUse(d.actor,d.computer,true)
end
local function text(s,max)
 return type(s)=='string' and #s>0 and #s<=max and not s:find('[%z\1-\8\11\12\14-\31]')
end
function N.post(host,notice)
 if not valid(host) or type(notice)~='table' or not text(notice.id,80)
  or not text(notice.title,128) or not text(notice.message,512)
  or notice.onOpen~=nil and type(notice.onOpen)~='function'
  or notice.severity~=nil and notice.severity~='info' and notice.severity~='warning' and notice.severity~='error' then return false end
 local d=host.desktopHost;d.notices=d.notices or {};local key=host.sessionKey..'\0'..notice.id
 local previous=d.notices[key];local count,owned=0,0
 for _,row in pairs(d.notices) do count=count+1;if row.host==host then owned=owned+1 end end
 if not previous and (count>=32 or owned>=16) then return false end
 local changed=not previous or previous.title~=notice.title or previous.message~=notice.message or previous.severity~=(notice.severity or 'info')
 d.notices[key]={id=notice.id,host=host,title=notice.title,message=notice.message,severity=notice.severity or 'info',onOpen=notice.onOpen,
  at=previous and previous.at or getTimestampMs(),unread=not previous or previous.unread or changed and notice.silent~=true}
 if changed and notice.silent~=true then d.noticeSelected=key;d.noticeToastUntil=getTimestampMs()+8000 end
 return true
end
function N.dismiss(host,id)
 if not valid(host) or type(id)~='string' then return false end
 local d=host.desktopHost;if d.notices then d.notices[host.sessionKey..'\0'..id]=nil end;return true
end
function N.clear(host)
 local d=host and host.desktopHost;if not d or not d.notices then return end
 for key,row in pairs(d.notices) do if row.host==host then d.notices[key]=nil end end
end
function N.list(host)
 if not valid(host) then return {} end
 local out={};for _,row in pairs(host.desktopHost.notices or {}) do if row.host==host then
  out[#out+1]={id=row.id,title=row.title,message=row.message,severity=row.severity,unread=row.unread==true}
 end end;table.sort(out,function(a,b) return a.id<b.id end);return out
end
function N.mount(d,UI,A)
 d.notices={}
 local function tr(k,...) return getText('UI_B47PC_'..k,...) end
 local box=UI.panel(d.surface,{color='grey'});box:setVisible(false);d.notificationPanel=box
 local function selected()
  local rows={}
  for key,row in pairs(d.notices) do
   if valid(row.host) then rows[#rows+1]={key=key,row=row} else d.notices[key]=nil end
  end
  table.sort(rows,function(a,b) return a.row.at==b.row.at and a.key<b.key or a.row.at>b.row.at end)
  local index=1;for n,row in ipairs(rows) do if row.key==d.noticeSelected then index=n end end
  return rows,index,rows[index] and rows[index].row
 end
 box:setWantKeyEvents(true)
 box.isKeyConsumed=function(self,key) return self:isVisible() and d.playerNum==0 and key==Keyboard.KEY_ESCAPE end
 box.onKeyRelease=function(self,key) if self:isKeyConsumed(key) then d.noticeExpanded=false;d.noticeToastUntil=0;setJoypadFocus(d.playerNum,d.root) end end
 local dismiss=UI.button(box,{textKey='UI_B47PC_NotificationDismiss',onClick=function()
  local rows,index=selected();if rows[index] then d.notices[rows[index].key]=nil end
 end})
 local open=UI.button(box,{textKey='UI_B47PC_NotificationOpen',onClick=function()
  local _,_,row=selected();if not row or not valid(row.host) then return end
  row.unread=false;d.noticeExpanded=false;d.noticeToastUntil=0;d:activate(row.host)
  if row.onOpen then row.onOpen() end
 end})
 local previous=UI.button(box,{text='<',onClick=function()
  local rows,index=selected();if #rows>0 then d.noticeSelected=rows[math.max(1,index-1)].key end
 end})
 local next=UI.button(box,{text='>',onClick=function()
  local rows,index=selected();if #rows>0 then d.noticeSelected=rows[math.min(#rows,index+1)].key end
 end})
 d.noticeButton=UI.button(d.root,{text='!',tooltipKey='UI_B47PC_Notifications',onClick=function()
  d.noticeExpanded=not d.noticeExpanded;d.noticeToastUntil=0
  d:refreshFocus();setJoypadFocus(d.playerNum,d.noticeExpanded and box or d.root)
 end})
 UI.focus(box,{{previous,next},{open,dismiss}})
 box.onJoypadDown=function(_,key) if key==Joypad.BButton then d.noticeExpanded=false;d.noticeToastUntil=0;setJoypadFocus(d.playerNum,d.root) else ISPanelJoypad.onJoypadDown(box,key) end end
 function d:updateNotifications()
  local rows,index,row=selected();local m=UI.metrics();local g=self.geometry
  local unread=0;for _,entry in ipairs(rows) do if entry.row.unread then unread=unread+1 end end
  self.noticeButton:setTitle(unread>0 and ('! '..unread) or '!');self.noticeButton:setEnable(#rows>0)
  UI.place(self.noticeButton,g.x+g.width-m.button*2-8,g.y+g.height-g.bar+4,m.button*2,m.button)
  box:setVisible(row~=nil and (self.noticeExpanded or getTimestampMs()<(self.noticeToastUntil or 0)))
  if not row then open.tooltip=nil;if open.tooltipUI then open.tooltipUI:setVisible(false) end;return end
  local w=math.min(g.width-16,math.max(340,m.font*26));local h=math.min(g.desktopHeight-16,7*m.font+2*m.button+40)
  UI.place(box,g.width-w-8,g.desktopHeight-h-8,w,h)
  UI.place(previous,8,h-m.button-8,m.button,m.button);UI.place(next,12+m.button,h-m.button-8,m.button,m.button)
  UI.place(open,20+2*m.button,h-m.button-8,(w-36-2*m.button)/2,m.button)
  UI.place(dismiss,24+2*m.button+(w-36-2*m.button)/2,h-m.button-8,(w-36-2*m.button)/2,m.button)
  previous:setEnable(index>1);next:setEnable(index<#rows)
  open:setEnable(valid(row.host))
  box.prerender=function(self)
   A.panel(self,0,0,w,h,'grey');A.bevel(self,0,0,w,h)
   A.text(self,tr('Notifications')..' ('..index..' / '..#rows..')',8,6,w-16,'black')
   A.text(self,row.title,8,m.font+12,w-16,row.severity=='error' and 'blue' or 'black')
   -- A bounded tooltip retains the full text if the small CRT clips a line.
   local remaining=row.message;local line=0;local maxChars=math.max(12,math.floor((w-16)/(m.font*.65)))
   while #remaining>0 and line<4 do
    local length=boundary(remaining,maxChars)
    A.text(self,remaining:sub(1,length),8,2*m.font+20+line*(m.font+2),w-16,'black')
    remaining=remaining:sub(length+1);line=line+1
   end
  end
  open.tooltip=row.title..' <LINE> '..row.message
  UI.focus(box,{{previous,next},{open,dismiss}})
  if box:isVisible() then box:bringToTop() end
 end
end
return N
