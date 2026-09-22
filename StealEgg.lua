-- LUXXY v3.2.2 — Compact Edition (hybrid sniper)
if _G.LuxxyCleanup then pcall(_G.LuxxyCleanup) end
_G.LuxxyRunning = true
local Cln = {}; _G.LuxxyCleanup = function() _G.LuxxyRunning=false; for _,f in ipairs(Cln) do pcall(f) end end

local P=game:GetService("Players") local R=game:GetService("RunService") local T=game:GetService("TweenService")
local U=game:GetService("UserInputService") local H=game:GetService("HttpService") local S=game:GetService("SoundService")
local W=game:GetService("Workspace") local RS=game:GetService("ReplicatedStorage")
local LP=P.LocalPlayer local Cam=W.CurrentCamera

-- REMOTE FETCH
local rem = {}
local function gr(...)
    local ok,r=pcall(function() local o=RS for _,p in ipairs({...}) do o=o:WaitForChild(p,2); if not o then return nil end end return o end)
    return ok and r or nil
end
task.spawn(function()
    rem.Tool=gr("Packages","Networking","RE/ToolTrigger/Trigger")
    rem.Carry=gr("Packages","Networking","RF/EggWorld/AskFieldEggCarry")
    rem.Rig=gr("Packages","Networking","RE/RigSync/Primed")
    print("[LUXXY] Remote:",rem.Tool~=nil,rem.Carry~=nil,rem.Rig~=nil)
end)
local function resync() local c=LP.Character if c and rem.Rig then pcall(function() rem.Rig:FireServer(c) end) end end

-- CLEANUP
for _,o in ipairs((function() local l={} for _,c in ipairs(game:GetService("CoreGui"):GetChildren()) do if c.Name=="LuxxyStealAnEgg" then table.insert(l,c) end end local pg=LP:FindFirstChild("PlayerGui"); if pg then for _,c in ipairs(pg:GetChildren()) do if c.Name=="LuxxyStealAnEgg" then table.insert(l,c) end end end if gethui then for _,c in ipairs(gethui():GetChildren()) do if c.Name=="LuxxyStealAnEgg" then table.insert(l,c) end end end return l end)()) do pcall(function() o:Destroy() end) end
pcall(function() local c=LP.Character if c then for _,d in ipairs(c:GetDescendants()) do if d.Name:find("Luxxy") then d:Destroy() end end end end)

local function GP() if gethui then local ok,h=pcall(gethui); if ok and h then return h end end local ok,cg=pcall(function() return game:GetService("CoreGui") end); if ok and cg then local k=pcall(function() return cg.Name end); if k then return cg end end return LP:WaitForChild("PlayerGui") end

local CFG={
    Ver="3.2.2", Save="LuxxyCfg.json", Thumb="rbxassetid://134782047288874",
    Col={G=Color3.fromRGB(34,139,34), B=Color3.fromRGB(60,200,90), W=Color3.fromRGB(255,255,255),
         SW=Color3.fromRGB(240,255,245), D=Color3.fromRGB(15,30,20), DK=Color3.fromRGB(8,18,12), Bd=Color3.fromRGB(120,220,150)},
    Speed=130, MaxSpd=180, Hover=3, Fake=16, Look=12, Avoid=2.0,
    MinBiome=40000, YPad=80, PBRange=350,
    BossR=250, BossBoost=1.4, BossTick=0.1, BossDodge=35, BossWall=25, BossWallR=60,
    BossHop=18, BossHopStep=4, BossHopDur=0.2, BossMin=4, BossMinWS=3,
    BossSafe=12, BossCrit=5, BossCritHop=75, BossCritDur=0.35, BossEscape=45,
    BossYMax=40,
    EggRetry=3, EggTick=0.5, BiomeTick=8,
    RemoteCD=0.4, SniperRange=18, SniperWait=0.5,
    SniperTiers={18,12,8},
    ACEnable=true, ACLerp=0.08, ACPauseDur=0.6, ACSpeedDrop=0.4, ACResync=3, ACWatcher=15,
}

-- DATA
local BIOMES={"Forest","Lake","Desert","Jungle","Snow","Volcano","Abyss Ocean","Prehistoric","Cosmic","Cherry Blossom","Titan Temple","Demons"}
local BL={} for _,b in ipairs(BIOMES) do BL[b:lower()]=b; BL[(b:gsub(" ","")):lower()]=b end
local RAR={Common={1,Color3.fromRGB(200,200,200)},Uncommon={1,Color3.fromRGB(60,220,80)},Rare={1,Color3.fromRGB(40,120,255)},Epic={1,Color3.fromRGB(150,60,255)},Legendary={1,Color3.fromRGB(255,220,40)},Mythic={1,Color3.fromRGB(255,60,60)},Cosmic={1,Color3.fromRGB(180,80,255)},Secret={1,Color3.fromRGB(255,255,255)},Divine={1,Color3.fromRGB(255,180,255)}}
local RNAME={} for k in pairs(RAR) do RNAME[k]=true end
local EGGV={["Red Panda"]=450000,["Cosmic Gorilla"]=180000,["Ankylosaurus"]=120000,["Orca"]=80000,["Chillin Chilli"]=55000,["Mammoth"]=42000,["Tiger"]=28000,["Koi"]=12000000,["Snowy Owl"]=7500000,["La Vacca Saturno Saturnita"]=2200000,["Beluga Whale"]=850000,["Whale Shark"]=700000,["King Mammoth"]=400000,["Stag"]=145000000,["Cosmic Dragon"]=60000000,["Tralaledon"]=32000000,["T-Rex"]=25000000,["Kraken"]=15000000,["Cerberus"]=8000000,["Yeti"]=5000000,["King Snake"]=3500000,["Kitsune"]=1800000000,["Unicorn"]=1000000000}

local St={Steal=false,Best=false,ESP=false,BESP=false,RF=true,AC=true,SniperEnable=true,Move=CFG.Speed,SB={}}

local function sv() pcall(function() if writefile then writefile(CFG.Save,H:JSONEncode({S=St.Steal,B=St.Best,E=St.ESP,BES=St.BESP,RF=St.RF,AC=St.AC,SN=St.SniperEnable,M=St.Move,SB=St.SB})) end end) end
pcall(function() if isfile and isfile(CFG.Save) then local r=H:JSONDecode(readfile(CFG.Save)) St.Steal=r.S or false; St.Best=r.B or false; St.ESP=r.E or false; St.BESP=r.BES or false; St.RF=r.RF~=false; St.AC=r.AC~=false; St.SniperEnable=r.SN~=false; St.Move=r.M or CFG.Speed; St.SB=r.SB or {} end end)

local function nw(c,p,ch) local o=Instance.new(c); if p then for k,v in pairs(p) do if k~="Parent" then o[k]=v end end end; if ch then for _,x in ipairs(ch) do if typeof(x)=="Instance" then x.Parent=o else for k,v in pairs(x) do if k=="Parent" then o.Parent=v else o[k]=v end end end end; if p and p.Parent then o.Parent=p.Parent end; return o end
local function click() pcall(function() local s=Instance.new("Sound") s.SoundId="rbxassetid://6895079853" s.Volume=.3 s.Parent=S; s:Play(); task.delay(1,function() pcall(function() s:Stop() end); s:Destroy() end) end) end
local function nt(t,x) pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=t,Text=x,Duration=2}) end) end
local function grad(p,c1,c2) local g=Instance.new("UIGradient",p); g.Color=ColorSequence.new(c1,c2); g.Rotation=45; return g end
local function fmt(n) if n>=1e9 then return string.format("%.1fB",n/1e9) elseif n>=1e6 then return string.format("%.1fM",n/1e6) elseif n>=1e3 then return string.format("%.0fK",n/1e3) end return tostring(math.floor(n)) end

-- UI
local Par=GP()
local SG=nw("ScreenGui",{Name="LuxxyStealAnEgg",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true,Parent=Par})
local OB=nw("TextButton",{Parent=SG,Size=UDim2.new(0,52,0,52),Position=UDim2.new(1,-72,0,70),BackgroundColor3=CFG.Col.G,Text="",AutoButtonColor=false,BorderSizePixel=0})
nw("UICorner",{CornerRadius=UDim.new(1,0),Parent=OB}) nw("UIStroke",{Color=CFG.Col.Bd,Thickness=2,Parent=OB}) grad(OB,CFG.Col.G,CFG.Col.B)
local GI=nw("TextLabel",{Parent=OB,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="⚙️",TextColor3=CFG.Col.W,Font=Enum.Font.GothamBold,TextSize=28})

local M=nw("Frame",{Parent=SG,Size=UDim2.new(0,440,0,520),Position=UDim2.new(.5,0,.5,0),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=CFG.Col.D,BorderSizePixel=0,Visible=false,ClipsDescendants=true})
nw("UICorner",{CornerRadius=UDim.new(0,16),Parent=M}) nw("UIStroke",{Color=CFG.Col.Bd,Thickness=2,Parent=M})
local MTX=nw("Frame",{Parent=M,Size=UDim2.new(1,0,1,0),BackgroundTransparency=.4,BackgroundColor3=CFG.Col.DK,ZIndex=0,ClipsDescendants=true}); nw("UICorner",{CornerRadius=UDim.new(0,16),Parent=MTX})
task.spawn(function() while _G.LuxxyRunning and MTX.Parent do local l=nw("Frame",{Parent=MTX,Size=UDim2.new(0,1,0,math.random(20,50)),Position=UDim2.new(math.random(),0,-.1,0),BackgroundColor3=CFG.Col.B,BackgroundTransparency=.7,BorderSizePixel=0}); T:Create(l,TweenInfo.new(math.random(3,6),Enum.EasingStyle.Linear),{Position=UDim2.new(l.Position.X.Scale,0,1.1,0),BackgroundTransparency=1}):Play(); task.delay(6,function() l:Destroy() end); task.wait(.15) end end)

local HD=nw("Frame",{Parent=M,Size=UDim2.new(1,0,0,72),BackgroundColor3=CFG.Col.G,BorderSizePixel=0,ZIndex=2}); nw("UICorner",{CornerRadius=UDim.new(0,16),Parent=HD}); grad(HD,CFG.Col.G,CFG.Col.B)
local TH=nw("ImageLabel",{Parent=HD,Size=UDim2.new(0,54,0,54),Position=UDim2.new(0,10,.5,-27),BackgroundColor3=CFG.Col.W,Image=CFG.Thumb,ScaleType=Enum.ScaleType.Crop,BorderSizePixel=0,ZIndex=3}); nw("UICorner",{CornerRadius=UDim.new(0,8),Parent=TH}); nw("UIStroke",{Color=CFG.Col.W,Thickness=2,Parent=TH})
nw("TextLabel",{Parent=HD,Size=UDim2.new(1,-90,0,22),Position=UDim2.new(0,74,0,14),BackgroundTransparency=1,Text="STEAL AN EGG — LUXXY",TextColor3=CFG.Col.W,Font=Enum.Font.GothamBlack,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3})
nw("TextLabel",{Parent=HD,Size=UDim2.new(1,-90,0,16),Position=UDim2.new(0,74,0,38),BackgroundTransparency=1,Text="v"..CFG.Ver.." • hybrid sniper",TextColor3=CFG.Col.SW,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3})
local CB=nw("TextButton",{Parent=HD,Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-36,0,10),BackgroundColor3=CFG.Col.D,Text="✕",TextColor3=CFG.Col.W,Font=Enum.Font.GothamBold,TextSize=13,AutoButtonColor=false,BorderSizePixel=0,ZIndex=4}); nw("UICorner",{CornerRadius=UDim.new(1,0),Parent=CB})

local PC=nw("ScrollingFrame",{Parent=M,Size=UDim2.new(1,-20,1,-158),Position=UDim2.new(0,10,0,80),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=CFG.Col.B,ZIndex=2})
nw("UIListLayout",{Parent=PC,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
local FT=nw("TextLabel",{Parent=M,Size=UDim2.new(1,-20,0,18),Position=UDim2.new(0,10,1,-24),BackgroundTransparency=1,Text="Ready",TextColor3=CFG.Col.B,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3})

local ord=0 local function no() ord=ord+1 return ord end
local function sec(txt) local f=nw("Frame",{Parent=PC,Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=no()}); nw("TextLabel",{Parent=f,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="▎ "..txt,TextColor3=CFG.Col.B,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left}); return f end
local function tg(lbl,init,cb) local row=nw("Frame",{Parent=PC,Size=UDim2.new(1,0,0,36),BackgroundColor3=CFG.Col.DK,BackgroundTransparency=.3,BorderSizePixel=0,LayoutOrder=no()}); nw("UICorner",{CornerRadius=UDim.new(0,8),Parent=row}); nw("UIStroke",{Color=CFG.Col.Bd,Thickness=1,Transparency=.7,Parent=row})
    nw("TextLabel",{Parent=row,Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=lbl,TextColor3=CFG.Col.SW,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left})
    local sw=nw("Frame",{Parent=row,Size=UDim2.new(0,42,0,22),Position=UDim2.new(1,-54,.5,-11),BackgroundColor3=CFG.Col.D,BorderSizePixel=0}); nw("UICorner",{CornerRadius=UDim.new(1,0),Parent=sw})
    local kn=nw("Frame",{Parent=sw,Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,3,.5,-8),BackgroundColor3=CFG.Col.W,BorderSizePixel=0}); nw("UICorner",{CornerRadius=UDim.new(1,0),Parent=kn})
    local on=init and true or false
    local function rnd(anim) T:Create(kn,TweenInfo.new(anim and .2 or 0,Enum.EasingStyle.Quad),{Position=on and UDim2.new(1,-19,.5,-8) or UDim2.new(0,3,.5,-8)}):Play(); T:Create(sw,TweenInfo.new(anim and .2 or 0,Enum.EasingStyle.Quad),{BackgroundColor3=on and CFG.Col.G or CFG.Col.D}):Play() end
    rnd(false)
    local bt=nw("TextButton",{Parent=row,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""})
    bt.MouseButton1Click:Connect(function() on=not on; click(); rnd(true); nt("LUXXY",lbl..": "..(on and "ON" or "OFF")); if cb then cb(on) end; sv() end)
    return {set=function(v) on=v; rnd(true) end}
end
local function sl(lbl,mn,mx,init,cb) local row=nw("Frame",{Parent=PC,Size=UDim2.new(1,0,0,48),BackgroundColor3=CFG.Col.DK,BackgroundTransparency=.3,BorderSizePixel=0,LayoutOrder=no()}); nw("UICorner",{CornerRadius=UDim.new(0,8),Parent=row}); nw("UIStroke",{Color=CFG.Col.Bd,Thickness=1,Transparency=.7,Parent=row})
    local t=nw("TextLabel",{Parent=row,Size=UDim2.new(1,-16,0,18),Position=UDim2.new(0,10,0,4),BackgroundTransparency=1,Text=lbl..": "..init,TextColor3=CFG.Col.SW,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left})
    local br=nw("Frame",{Parent=row,Size=UDim2.new(1,-20,0,7),Position=UDim2.new(0,10,0,34),BackgroundColor3=CFG.Col.D,BorderSizePixel=0}); nw("UICorner",{CornerRadius=UDim.new(1,0),Parent=br})
    local fl=nw("Frame",{Parent=br,Size=UDim2.new((init-mn)/(mx-mn),0,1,0),BackgroundColor3=CFG.Col.B,BorderSizePixel=0}); nw("UICorner",{CornerRadius=UDim.new(1,0),Parent=fl}); grad(fl,CFG.Col.G,CFG.Col.B)
    local dg=false
    local function setf(x) local rl=math.clamp((x-br.AbsolutePosition.X)/math.max(br.AbsoluteSize.X,1),0,1); local v=math.floor(mn+(mx-mn)*rl); fl.Size=UDim2.new(rl,0,1,0); t.Text=lbl..": "..v; cb(v); sv() end
    local c1=br.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=true; setf(i.Position.X) end end)
    local c2=U.InputChanged:Connect(function(i) if dg and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setf(i.Position.X) end end)
    local c3=U.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=false end end)
    table.insert(Cln,function() c1:Disconnect(); c2:Disconnect(); c3:Disconnect() end)
end

-- UI Content
sec("STEAL ENGINE")
tg("🥚 STEAL EGG (biome filter)",St.Steal,function(v) St.Steal=v; FT.Text=v and "Memulai..." or "Ready" end)
sl("🏃 Speed (cap 180)",40,180,St.Move,function(v) St.Move=math.min(v,CFG.MaxSpd) end)
tg("🎯 HYBRID SNIPER (18→12→8)",St.SniperEnable,function(v) St.SniperEnable=v end)
tg("🛡 ANTI-CORRECTION",St.AC,function(v) St.AC=v end)
local rb=nw("TextButton",{Parent=PC,Size=UDim2.new(1,0,0,30),BackgroundColor3=CFG.Col.D,Text="🔄 FORCE RIG RESYNC",TextColor3=CFG.Col.SW,Font=Enum.Font.GothamBold,TextSize=12,AutoButtonColor=false,BorderSizePixel=0,LayoutOrder=no()}); nw("UICorner",{CornerRadius=UDim.new(0,8),Parent=rb}); nw("UIStroke",{Color=CFG.Col.Bd,Thickness=1,Parent=rb})
rb.MouseButton1Click:Connect(function() click(); resync(); nt("LUXXY","Resync dikirim") end)
tg("⚡ REMOTE STEAL FIRST",St.RF,function(v) St.RF=v end)

sec("BIOME FILTER (Steal Egg)")
local BH=nw("Frame",{Parent=PC,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=no()})
nw("UIGridLayout",{Parent=BH,CellSize=UDim2.new(.5,-4,0,28),CellPadding=UDim.new(0,6,0,5),SortOrder=Enum.SortOrder.LayoutOrder})
local BC={Forest={Color3.fromRGB(34,139,34),Color3.fromRGB(120,220,120)},Lake={Color3.fromRGB(40,140,200),Color3.fromRGB(180,230,255)},Desert={Color3.fromRGB(220,190,120),Color3.fromRGB(255,240,200)},Jungle={Color3.fromRGB(20,120,60),Color3.fromRGB(80,200,120)},Snow={Color3.fromRGB(200,230,255),Color3.fromRGB(255,255,255)},Volcano={Color3.fromRGB(180,40,20),Color3.fromRGB(255,140,60)},["Abyss Ocean"]={Color3.fromRGB(10,30,80),Color3.fromRGB(60,120,200)},Prehistoric={Color3.fromRGB(90,60,30),Color3.fromRGB(180,140,80)},Cosmic={Color3.fromRGB(80,20,140),Color3.fromRGB(200,120,255)},["Cherry Blossom"]={Color3.fromRGB(255,180,220),Color3.fromRGB(255,255,255)},["Titan Temple"]={Color3.fromRGB(180,140,60),Color3.fromRGB(255,220,140)},Demons={Color3.fromRGB(90,0,0),Color3.fromRGB(255,60,60)}}
local BB={}
local function rbB(n) local e=BB[n]; if not e then return end; local on=St.SB[n]==true; e.s.Color=on and e.c or CFG.Col.Bd; e.s.Thickness=on and 2 or 1; e.s.Transparency=on and 0 or .5; e.l.TextColor3=on and CFG.Col.W or CFG.Col.SW; e.l.Text=(on and "✔ " or "")..n; e.b.BackgroundTransparency=on and .15 or .65 end
for i,bn in ipairs(BIOMES) do local c=BC[bn] or {CFG.Col.G,CFG.Col.B}; local b=nw("TextButton",{Parent=BH,Size=UDim2.new(0,0,0,0),BackgroundColor3=CFG.Col.DK,BackgroundTransparency=.65,Text="",AutoButtonColor=false,BorderSizePixel=0,LayoutOrder=i})
    nw("UICorner",{CornerRadius=UDim.new(0,6),Parent=b}); local s=nw("UIStroke",{Color=CFG.Col.Bd,Thickness=1,Parent=b}); local l=nw("TextLabel",{Parent=b,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=bn,TextColor3=CFG.Col.SW,Font=Enum.Font.GothamBold,TextSize=10}); grad(b,c[1],c[2])
    BB[bn]={b=b,s=s,l=l,c=c[1]}; rbB(bn)
    b.MouseButton1Click:Connect(function() St.SB[bn]=not St.SB[bn]; click(); rbB(bn); sv() end) end
local ab=nw("TextButton",{Parent=PC,Size=UDim2.new(1,0,0,28),BackgroundColor3=CFG.Col.G,Text="✔ SELECT ALL BIOMES",TextColor3=CFG.Col.W,Font=Enum.Font.GothamBold,TextSize=12,AutoButtonColor=false,BorderSizePixel=0,LayoutOrder=no()}); nw("UICorner",{CornerRadius=UDim.new(0,8),Parent=ab}); nw("UIStroke",{Color=CFG.Col.Bd,Thickness=2,Parent=ab})
local aon=false
ab.MouseButton1Click:Connect(function() aon=not aon; for _,bn in ipairs(BIOMES) do St.SB[bn]=aon; rbB(bn) end; click(); ab.Text=aon and "✕ DESELECT ALL" or "✔ SELECT ALL BIOMES"; sv() end)

sec("BEST + ESP")
tg("👑 STEAL BEST EGG (semua biome)",St.Best,function(v) St.Best=v end)
tg("🔍 ESP EGGS",St.ESP,function(v) St.ESP=v; if not v then clearESP() end end)
tg("👾 ESP BOSS",St.BESP,function(v) St.BESP=v; if not v then clearBESP() end end)

-- UI ANIM
local op=false; local gr=0
local function rotG(d,dur) gr=gr+d; T:Create(GI,TweenInfo.new(dur,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Rotation=gr}):Play() end
local function gts() local v=Cam.ViewportSize; return math.min(440,v.X-30),math.min(520,v.Y-140) end
local function open() if op then return end; op=true; rotG(180,.5); local w,h=gts(); local b=OB.AbsolutePosition+OB.AbsoluteSize/2; M.Visible=true; M.Size=UDim2.new(0,20,0,20); M.Position=UDim2.fromOffset(b.X,b.Y); M.BackgroundTransparency=1; T:Create(M,TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(w,h),Position=UDim2.new(.5,0,.5,0),BackgroundTransparency=0}):Play(); click() end
local function close() if not op then return end; op=false; rotG(-180,.4); local b=OB.AbsolutePosition+OB.AbsoluteSize/2; local t=T:Create(M,TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,20,0,20),Position=UDim2.fromOffset(b.X,b.Y),BackgroundTransparency=1}); t:Play(); t.Completed:Connect(function() M.Visible=false end); click() end
local cOB=OB.MouseButton1Click:Connect(function() if op then close() else open() end end)
local cCB=CB.MouseButton1Click:Connect(close)
table.insert(Cln,function() cOB:Disconnect(); cCB:Disconnect() end)
do local dg,dS,sP; local c1=HD.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=true; dS=i.Position; sP=M.Position end end)
  local c2=U.InputChanged:Connect(function(i) if dg and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-dS; M.Position=UDim2.new(sP.X.Scale,sP.X.Offset+d.X,sP.Y.Scale,sP.Y.Offset+d.Y) end end)
  local c3=U.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=false end end)
  table.insert(Cln,function() c1:Disconnect(); c2:Disconnect(); c3:Disconnect() end) end

-- BIOME SYSTEM
local BR={} local bBusy=false
local function cv(cf,s) return s.X*s.Y*s.Z end
local function bc(ob) if ob:IsA("Model") then local ok,cf,s=pcall(function() return ob:GetBoundingBox() end); if not ok then return end; local v=cv(cf,s); if v<CFG.MinBiome then return end; return cf,s,v elseif ob:IsA("BasePart") then local v=cv(ob.CFrame,ob.Size); if v<CFG.MinBiome then return end; return ob.CFrame,ob.Size,v end end
function refreshBR() if bBusy then return end; bBusy=true; task.spawn(function() pcall(function() local nl={} for _,ob in ipairs(W:GetDescendants()) do if ob:IsA("BasePart") or ob:IsA("Model") then local lw=ob.Name:lower(); for k,c in pairs(BL) do if lw:find(k,1,true) then local cf,s,v=bc(ob); if cf and s and v then table.insert(nl,{p=ob,n=c,cf=cf,s=s,v=v}) end break end end end end table.sort(nl,function(a,b) return a.v>b.v end) BR=nl; print("[LUXXY] Biome:",#nl) end) bBusy=false end) end
local function bByAnc(ob) local c=ob local d=0 while c and c~=W and d<8 do local lw=c.Name:lower(); for k,cn in pairs(BL) do if lw:find(k,1,true) then return cn end end c=c.Parent; d=d+1 end end
local function bByPos(p) for _,e in ipairs(BR) do if e.p and e.p.Parent then local lp=e.cf:PointToObjectSpace(p); if math.abs(lp.X)<=e.s.X/2 and math.abs(lp.Y)<=e.s.Y/2+CFG.YPad and math.abs(lp.Z)<=e.s.Z/2 then return e.n end end end end
local function pb() local c=LP.Character local h=c and c:FindFirstChild("HumanoidRootPart"); if h then return bByPos(h.Position) end end
local function eggBiome(e,p) local a=bByAnc(e); if a then return a end; if not p then if e:IsA("BasePart") then p=e.Position elseif e:IsA("Model") then local pp=e.PrimaryPart or e:FindFirstChildWhichIsA("BasePart"); if pp then p=pp.Position end end end; if p then local b=bByPos(p); if b then return b end end; local c=LP.Character local h=c and c:FindFirstChild("HumanoidRootPart"); if h and p and (h.Position-p).Magnitude<=CFG.PBRange then return pb() end end

-- EGG DETECT
local BLT={"fuse","machine","fuser","station","spawner","shop","store","toko","pedestal","display","base","plot","portal","teleport","tomb","cage","sign","board","decal"}
local EKW={"egg","telur"} local SVRB={"steal","take","grab","collect","pick","curi","mencuri","ambil","mengambil"}
local function ck(s,l) s=s:lower() for _,k in ipairs(l) do if s:find(k,1,true) then return k end end end
local function isBL(ob) if ck(ob.Name,BLT) then return true end local p=ob.Parent local d=0 while p and p~=W and d<3 do if ck(p.Name,BLT) then return true end p=p.Parent; d=d+1 end end
local function fsP(ob) for _,d in ipairs(ob:GetDescendants()) do if d:IsA("ProximityPrompt") then local at=(d.ActionText or ""):lower(); local ot=(d.ObjectText or ""):lower(); if (ck(at,SVRB) or ck(ot,SVRB)) and (ck(ot,EKW) or ck(at,EKW)) then return d end; if ck(ot,EKW) and (at~="" or ot~="") then return d end end end; for _,d in ipairs(ob:GetDescendants()) do if d:IsA("ClickDetector") and ck(ob.Name,EKW) then return d end end end
local function isEgg(ob) if not (ob:IsA("Model") or ob:IsA("BasePart")) then return false end; if isBL(ob) then return false end; local p=fsP(ob); if not p then return false end; local nh=ck(ob.Name,EKW); if not nh and p:IsA("ProximityPrompt") then nh=ck(p.ObjectText,EKW) end; if not nh and ob.Parent then nh=ck(ob.Parent.Name,EKW) end; return nh and true or false end
local function eRar(e) for _,d in ipairs(e:GetDescendants()) do if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then if d.Text~="" then for k in pairs(RNAME) do if d.Text:lower():find(k:lower(),1,true) then return k end end end end end end
local function eMut(e) for _,k in ipairs({"Mutation","mutation","Mutated","mutated"}) do if e.GetAttribute then local v=e:GetAttribute(k); if v and v~=false and v~="" then return tostring(v) end end end; local lw=e.Name:lower(); for _,k in ipairs({"rainbow","gold","golden","shiny","mutated","galaxy","shadow"}) do if lw:find(k,1,true) then return k:sub(1,1):upper()..k:sub(2) end end end
local function ePos(e) local p=fsP(e); if p then if p:IsA("ProximityPrompt") then local a=p.Parent; if a:IsA("BasePart") then return a.Position elseif a:IsA("Attachment") and a.Parent then return a.WorldPosition end elseif p:IsA("ClickDetector") then local pp=p.Parent; if pp:IsA("BasePart") then return pp.Position end end end; if e:IsA("Model") then local pp=e.PrimaryPart or e:FindFirstChildWhichIsA("BasePart"); return pp and pp.Position elseif e:IsA("BasePart") then return e.Position end end
local function ePrice(e) local nl=e.Name:lower(); local b=0 for n,v in pairs(EGGV) do if nl:find(n:lower(),1,true) and v>b then b=v end end; if b>0 then return b end; local r=eRar(e); if r and RAR[r] then return RAR[r][1]*1000000 end return 0 end
local function findEggs() local l={} for _,ob in ipairs(W:GetDescendants()) do if isEgg(ob) then table.insert(l,ob) end end return l end
local function hSel() for _,v in pairs(St.SB) do if v then return true end end end
local function selB(e,p) if not hSel() then return true end local b=eggBiome(e,p); if not b then return false end return St.SB[b]==true end

-- REMOTE STEAL + HYBRID SNIPER
local function eggTools() local c=LP.Character if not c then return {} end local l={} for _,x in ipairs(c:GetChildren()) do if x:IsA("Tool") then local n=x.Name:lower(); if n:find("egg",1,true) or n:find("telur",1,true) then table.insert(l,x) end end end return l end
local lastRF=0
local function remoteFire() if not rem.Tool then return false end local tl=eggTools(); if #tl==0 then return false end local f=false for _,t in ipairs(tl) do if pcall(function() rem.Tool:FireServer(t) end) then f=true end end return f end

-- HYBRID: coba beberapa tier jarak
local function sniperAttempt(target)
    if not St.SniperEnable or not rem.Tool then return false end
    local c=LP.Character if not c then return false end
    local h=c:FindFirstChild("HumanoidRootPart"); if not h then return false end
    local p=ePos(target); if not p then return false end
    for _,tier in ipairs(CFG.SniperTiers) do
        local d=(h.Position-p).Magnitude
        if d<=tier and tick()-lastRF>=CFG.RemoteCD then
            lastRF=tick()
            local ok=remoteFire()
            if ok then
                task.wait(CFG.SniperWait)
                local still=target.Parent~=nil and isEgg(target)
                if not still then return true end
            end
        end
    end
    return false
end

local function tryGrab(e)
    if St.RF and rem.Tool and tick()-lastRF>CFG.RemoteCD then lastRF=tick(); remoteFire() end
    local p=fsP(e)
    if p then if p:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(p) end); return true elseif p:IsA("ClickDetector") then pcall(function() fireclickdetector(p) end); return true end end
    local c=LP.Character if c then local t=c:FindFirstChildOfClass("Tool") or (LP.Backpack and LP.Backpack:FindFirstChildOfClass("Tool")); if t then pcall(function() t:Activate() end); return true end end
    return false
end

-- ESP EGGS
local EC={} function clearESP() for e,d in pairs(EC) do pcall(function() d.h:Destroy(); d.b:Destroy() end) end EC={} end
local function bESP(e) local r=eRar(e) or "?"; local m=eMut(e); local p=ePrice(e); local b=eggBiome(e) or "?"
    local col=RAR[r] and RAR[r][2] or Color3.new(1,1,1); if m then col=Color3.fromRGB(255,100,255) end
    local h=Instance.new("Highlight") h.Adornee=e h.FillTransparency=1 h.OutlineColor=col h.OutlineTransparency=0 h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop h.Parent=SG
    local bg=Instance.new("BillboardGui") bg.Adornee=e bg.Size=UDim2.new(0,200,0,64) bg.StudsOffset=Vector3.new(0,3,0) bg.AlwaysOnTop=true bg.MaxDistance=350 bg.Parent=SG
    local f=nw("Frame",{Parent=bg,Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.4,BorderSizePixel=0}); nw("UICorner",{CornerRadius=UDim.new(0,8),Parent=f}); local st=nw("UIStroke",{Parent=f,Color=col,Thickness=1.5})
    local n=nw("TextLabel",{Parent=f,Size=UDim2.new(1,-8,0,18),Position=UDim2.new(0,4,0,3),BackgroundTransparency=1,TextColor3=col,Font=Enum.Font.GothamBold,TextSize=12,Text=(m and "✨ "..m.." " or "")..e.Name})
    local i=nw("TextLabel",{Parent=f,Size=UDim2.new(1,-8,0,15),Position=UDim2.new(0,4,0,24),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=10,Text="Rarity:"..r.." • $"..fmt(p)})
    local bi=nw("TextLabel",{Parent=f,Size=UDim2.new(1,-8,0,15),Position=UDim2.new(0,4,0,39),BackgroundTransparency=1,TextColor3=CFG.Col.B,Font=Enum.Font.GothamBold,TextSize=10,Text="🌍 "..b})
    EC[e]={h=h,b=bg,cr=r,cp=p,cb=b,cm=m,n=n,i=i,bi=bi,st=st} end
task.spawn(function() local lS=0 local iv=.25 while _G.LuxxyRunning do local dt=R.Heartbeat:Wait() if St.ESP then lS=lS+dt if lS>=iv then lS=0 local el=findEggs() local al={} for _,e in ipairs(el) do al[e]=true if not EC[e] then bESP(e) else local d=EC[e]; local r=eRar(e) or "?"; local p=ePrice(e); local b=eggBiome(e) or "?"; local m=eMut(e); if r~=d.cr or p~=d.cp or b~=d.cb or m~=d.cm then d.cr=r d.cp=p d.cb=b d.cm=m local c=RAR[r] and RAR[r][2] or Color3.new(1,1,1); if m then c=Color3.fromRGB(255,100,255) end; d.h.OutlineColor=c; d.n.TextColor3=c; d.n.Text=(m and "✨ "..m.." " or "")..e.Name; d.i.Text="Rarity:"..r.." • $"..fmt(p); d.bi.Text="🌍 "..b; d.st.Color=c end end end for e,d in pairs(EC) do if not al[e] or not e.Parent then pcall(function() d.h:Destroy(); d.b:Destroy() end); EC[e]=nil end end end else if next(EC) then clearESP() end end end end)

-- BOSS DETECT (Y-filtered)
local BKW={"boss","guard","chaser","monster","police","cop","enemy","pursuer","hunter","evil","demon","grinch","thief","captor","secur","warden","gorilla","gorila","tiger","harimau","chicken","ayam","scorpion","kalajengking","trex","t-rex","rex","yeti","whale","beluga","paus","crab","kepiting","dragon","naga","knight","king","giant","beast","creature","mammoth","shark","hiu","spider","laba","wolf","serigala","bear","beruang","snake","ular","ape","chimp","turtle","kura","squid","octopus","gurita","rhino","badak","elephant","gajah","lion","singa","leopard","macan","panther","boar","babi","brock","scramble"}
local BPB={"pet","companion","follower","buddy","hat","accessory"}
local function ckS(s,l) s=(s or ""):lower() for _,k in ipairs(l) do if s:find(k,1,true) then return true end end end
local function mSize(m) if not m:IsA("Model") then return 0 end local ok,cf,s=pcall(function() return m:GetBoundingBox() end); if not ok then return 0 end return math.max(s.X,s.Y,s.Z) end
local function mRad(m) if not m:IsA("Model") then return 5 end local ok,cf,s=pcall(function() return m:GetBoundingBox() end); if not ok then return 5 end return math.max(s.X,s.Z)/2 end
local function isMine(ow) if not ow then return false end if ow==LP.Name or ow==LP.UserId or tostring(ow)==tostring(LP.UserId) then return true end return false end
local function isBoss(m)
    if not m:IsA("Model") then return false end
    if P:GetPlayerFromCharacter(m) then return false end
    local hm=m:FindFirstChildOfClass("Humanoid"); if not hm or hm.Health<=0 then return false end
    local h=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart; if not h then return false end
    local pc=LP.Character local ph=pc and pc:FindFirstChild("HumanoidRootPart")
    if ph and math.abs(h.Position.Y - ph.Position.Y) > CFG.BossYMax then return false end
    local ow=m:GetAttribute("Owner") or m:GetAttribute("Player") or m:GetAttribute("OwnerId") or m:GetAttribute("UserId") or m:GetAttribute("OwnerName")
    if isMine(ow) then return false end
    if ckS(m.Name,BPB) then return false end
    local ba=m:GetAttribute("IsBoss") or m:GetAttribute("Boss") or m:GetAttribute("Enemy") or m:GetAttribute("Chase")
    local mv=hm.WalkSpeed>=CFG.BossMinWS
    if not mv and not ba then return false end
    if ba then return true end
    if mv and ckS(m.Name,BKW) then return true end
    if mv and mSize(m)>=CFG.BossMin then return true end
    return false
end
local function findBoss(mx) mx=mx or CFG.BossR local c=LP.Character if not c then return end local h=c:FindFirstChild("HumanoidRootPart"); if not h then return end local mp=h.Position
    local n,nd,np=nil,mx,nil
    local roots={W} for _,nm in ipairs({"Monsters","Bosses","Enemies","NPCs","Mobs","Chase","Creatures","DrScrambleEvent","Events","Event"}) do local f=W:FindFirstChild(nm); if f then table.insert(roots,f) end end
    for _,r in ipairs(roots) do for _,ob in ipairs(r:GetChildren()) do if ob:IsA("Model") and isBoss(ob) then local eh=ob:FindFirstChild("HumanoidRootPart") or ob.PrimaryPart; if eh then local d=(eh.Position-mp).Magnitude; if d<nd then n=ob nd=d np=eh.Position end end end end end
    return n,nd,np
end

-- BOSS ESP
local BEC={} function clearBESP() for b,d in pairs(BEC) do pcall(function() d.h:Destroy(); d.b:Destroy() end) end BEC={} end
local function bBESP(b) local h=Instance.new("Highlight") h.Adornee=b h.FillTransparency=.85 h.FillColor=Color3.fromRGB(255,0,0) h.OutlineColor=Color3.fromRGB(255,50,50) h.OutlineTransparency=0 h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop h.Parent=SG
    local bg=Instance.new("BillboardGui") bg.Adornee=b bg.Size=UDim2.new(0,180,0,42) bg.StudsOffset=Vector3.new(0,5,0) bg.AlwaysOnTop=true bg.MaxDistance=500 bg.Parent=SG
    local f=nw("Frame",{Parent=bg,Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(60,0,0),BackgroundTransparency=.3,BorderSizePixel=0}); nw("UICorner",{CornerRadius=UDim.new(0,8),Parent=f}); nw("UIStroke",{Parent=f,Color=Color3.fromRGB(255,80,80),Thickness=2})
    local n=nw("TextLabel",{Parent=f,Size=UDim2.new(1,-8,0,18),Position=UDim2.new(0,4,0,2),BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,200,200),Font=Enum.Font.GothamBlack,TextSize=13,Text="👹 "..b.Name})
    local d=nw("TextLabel",{Parent=f,Size=UDim2.new(1,-8,0,16),Position=UDim2.new(0,4,0,22),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=11,Text="Distance: 0"})
    BEC[b]={h=h,b=bg,d=d} end
task.spawn(function() local lS=0 local iv=.3 while _G.LuxxyRunning do local dt=R.Heartbeat:Wait() if St.BESP then lS=lS+dt if lS>=iv then lS=0 local c=LP.Character local h=c and c:FindFirstChild("HumanoidRootPart"); local mp=h and h.Position; local al={}
    for _,ob in ipairs(W:GetDescendants()) do if ob:IsA("Model") and isBoss(ob) then al[ob]=true if not BEC[ob] then bBESP(ob) end local eh=ob:FindFirstChild("HumanoidRootPart") or ob.PrimaryPart; if eh and mp then local d=(mp-eh.Position).Magnitude; local dt2=BEC[ob]; if dt2 then local r=mRad(ob); dt2.d.Text=string.format("Dist:%.0f R:%.0f",d,r); dt2.d.TextColor3=d<30 and Color3.fromRGB(255,60,60) or (d<80 and Color3.fromRGB(255,200,60) or Color3.new(1,1,1)) end end end end
    for b,d in pairs(BEC) do if not al[b] or not b.Parent then pcall(function() d.h:Destroy(); d.b:Destroy() end); BEC[b]=nil end end end else if next(BEC) then clearBESP() end end end end)

-- OBSTACLE AVOID
local SM={s=nil,f=0}
local function rst() SM.s=nil SM.f=0 end
local function steer(hp,ch,du,la) local rp=RaycastParams.new() rp.FilterDescendantsInstances={ch} rp.FilterType=Enum.RaycastFilterType.Exclude
    local o=hp.Position local fh=W:Raycast(o,du*la,rp); if not fh then rst() return du,false end
    local fn=Vector3.new(fh.Normal.X,0,fh.Normal.Z); if fn.Magnitude>.1 then local sl=du-fn*du:Dot(fn); if sl.Magnitude>.2 then local sh=W:Raycast(o,sl.Unit*la,rp); if not sh then rst() return sl.Unit,false end end end
    local rt=Vector3.new(du.Z,0,-du.X).Unit local lf=-rt
    if SM.s then SM.f=SM.f+1 if SM.f>25 then SM.s=nil SM.f=0 end end
    if not SM.s then local hl=W:Raycast(o,lf*la,rp) local hr=W:Raycast(o,rt*la,rp)
        if hl and not hr then SM.s="r" elseif hr and not hl then SM.s="l" elseif not hl and not hr then local ld=(du+lf*CFG.Avoid).Unit; local rd=(du+rt*CFG.Avoid).Unit; SM.s=ld:Dot(du)>rd:Dot(du) and "l" or "r" else return du,true end SM.f=0 end
    local sd=SM.s=="l" and (du+lf*CFG.Avoid).Unit or (du+rt*CFG.Avoid).Unit
    local ch2=W:Raycast(o,sd*la,rp); if ch2 then local os=SM.s=="l" and "r" or "l"; local od=SM.s=="l" and rt or lf; local osd=(du+od*CFG.Avoid).Unit; local oh=W:Raycast(o,osd*la,rp); if not oh then SM.s=os SM.f=0 sd=osd else return du,true end end
    return sd,false end
local function wall(p,r) local bp,bd=nil,r for _,ob in ipairs(W:GetDescendants()) do if ob:IsA("BasePart") and ob.CanCollide then local sz=ob.Size; local v=sz.X*sz.Y*sz.Z; if v>=2000 then local d=(ob.Position-p).Magnitude; if d<bd then bp=ob bd=d end end end end return bp,bd end

-- MOVEMENT ANTI-CORRECTION
local MS={v=nil,g=nil,a=false}
local function stop() if MS.v then pcall(function() MS.v:Destroy() end); MS.v=nil end; if MS.g then pcall(function() MS.g:Destroy() end); MS.g=nil end; MS.a=false end
table.insert(Cln,function() stop() pcall(function() local c=LP.Character if c then for _,d in ipairs(c:GetDescendants()) do if d.Name=="LuxxyV" or d.Name=="LuxxyG" then d:Destroy() end end end end) end)
local function move(tp,bs)
    local c=LP.Character if not c then return end local hm=c:FindFirstChildOfClass("Humanoid") local h=c:FindFirstChild("HumanoidRootPart"); if not hm or not h then return end
    pcall(function() h:SetNetworkOwner(LP) end) stop() MS.a=true rst()
    local os=hm.WalkSpeed hm.WalkSpeed=CFG.Fake
    local wc=hm:GetPropertyChangedSignal("WalkSpeed"):Connect(function() if hm.WalkSpeed~=CFG.Fake then hm.WalkSpeed=CFG.Fake end end)
    local v=Instance.new("BodyVelocity",h) v.Name="LuxxyV" v.MaxForce=Vector3.new(1e5,0,1e5) v.Velocity=Vector3.zero MS.v=v
    local g=Instance.new("BodyGyro",h) g.Name="LuxxyG" g.MaxTorque=Vector3.new(0,1e5,0) g.P=12000 g.D=450 g.CFrame=h.CFrame MS.g=g
    local hp=tp+Vector3.new(0,CFG.Hover,0)
    local lBC=0 local bo,bd,bp=nil,math.huge,nil local br=5
    local t0=tick() local cv=Vector3.zero local cs=bs
    local lH,lHU=0,0 local lCH,lCHU=0,0 local lW=0 local wt,wtU=nil,0 local esc=false local lF=0
    local lP=h.Position local lPC=tick() local cP=0 local sMul=1 local cC=0 local lR=tick()
    while _G.LuxxyRunning and c.Parent and h.Parent and hm.Health>0 and MS.a do
        if not (St.Steal or St.Best) then break end if not v.Parent then break end if tick()-t0>120 then break end
        if hm.WalkSpeed~=CFG.Fake then hm.WalkSpeed=CFG.Fake end
        if St.AC then local now=tick() local dt=now-lPC
            if dt>.05 then local np=h.Position local mv=(np-lP).Magnitude local ex=cv.Magnitude*dt local df=math.abs(mv-ex)
                if df>CFG.ACWatcher and cv.Magnitude>30 then cC=cC+1 cP=now+CFG.ACPauseDur sMul=CFG.ACSpeedDrop; pcall(resync)
                else sMul=math.min(1,sMul+.02) end
                lP=np lPC=now end end
        if tick()-lR>CFG.ACResync then lR=tick() pcall(resync) end
        local paused=tick()<cP
        if tick()-lBC>CFG.BossTick then lBC=tick() bo,bd,bp=findBoss(CFG.BossR)
            if bo then br=mRad(bo) end
            if bo and bd<CFG.BossR then local r=1-math.clamp(bd/CFG.BossR,0,1); cs=bs*(1+CFG.BossBoost*r) else cs=bs end
            cs=math.clamp(cs,16,CFG.MaxSpd)*sMul
            local eR=br+CFG.BossSafe local sR=eR+20
            if bo and bd<eR then esc=true elseif not bo or bd>sR then esc=false end
            if bo and bd<CFG.BossHop and tick()-lH>.4 then lHU=tick()+CFG.BossHopDur lH=tick() v.MaxForce=Vector3.new(1e5,1e5,1e5) end
            if bo and bd<br+CFG.BossCrit and tick()-lCH>.8 then lCHU=tick()+CFG.BossCritDur lCH=tick() v.MaxForce=Vector3.new(1e5,1e5,1e5) end
            if tick()-lF>.3 then lF=tick() if bo and bp then local px="⚠"; if bd<br+CFG.BossCrit then px="🚨CRIT" elseif esc then px="🚨ESC" end; FT.Text=string.format("%s %.0f R:%.0f Spd:%.0f%s",px,bd,br,cs,paused and " ⏸" or (cC>0 and " 🛡" or "")) end end
        end
        local hop=tick()<lHU local chop=tick()<lCHU
        if not hop and not chop then v.MaxForce=Vector3.new(1e5,0,1e5) end
        local dr
        if esc and bo and bp and bd then
            local aw=h.Position-bp aw=Vector3.new(aw.X,0,aw.Z); if aw.Magnitude<.1 then aw=Vector3.new(math.random()-.5,0,math.random()-.5) end
            local au=aw.Unit local crit=bd<br+CFG.BossCrit
            if crit then local tb=bp-h.Position tb=Vector3.new(tb.X,0,tb.Z); if tb.Magnitude<.1 then tb=au end; tb=tb.Unit
                local pp=Vector3.new(-au.Z,0,au.X); if pp:Dot(tb)>0 then pp=-pp end
                dr=pp*.7+au*.3; if dr.Magnitude>.1 then dr=dr.Unit else dr=pp end
            else dr=au end
        else
            local tt=hp-h.Position local d=tt.Magnitude; if d<4 then break end dr=tt.Unit
            if bo and bd<CFG.BossWall and tick()-lW>2 then lW=tick() local wl=wall(h.Position,CFG.BossWallR); if wl then wt=wl.Position wtU=tick()+1.5 end end
            if wt and tick()<wtU then local wd=wt-h.Position; if wd.Magnitude>3 then dr=(wd.Unit*.7+dr*.3).Unit end else wt=nil end
            if bo and bp and bd<CFG.BossDodge then local aw=h.Position-bp; aw=Vector3.new(aw.X,0,aw.Z); if aw.Magnitude>.1 then local rp=aw.Unit; local w=math.clamp((1-bd/CFG.BossDodge)*1.5,0,1); dr=dr*(1-w)+rp*w; if dr.Magnitude>.1 then dr=dr.Unit else dr=rp end end end
        end
        local la=math.max(CFG.Look,cs*.12) local sd=steer(h,c,dr,la); dr=sd
        local tv
        if paused then tv=Vector3.zero
        elseif chop then tv=Vector3.new(dr.X*cs,CFG.BossCritHop,dr.Z*cs)
        elseif hop then tv=Vector3.new(dr.X*cs,CFG.BossHopStep*60,dr.Z*cs)
        else tv=dr*cs end
        local lm=St.AC and CFG.ACLerp or .5
        cv=cv:Lerp(tv,lm) v.Velocity=cv
        local lt=Vector3.new(cv.X,0,cv.Z); if lt.Magnitude>1 then g.CFrame=CFrame.lookAt(h.Position,h.Position+lt) end
        R.Heartbeat:Wait()
    end
    if v then v.Velocity=Vector3.zero end pcall(function() hm:MoveTo(h.Position) end) task.wait(.05) stop()
    wc:Disconnect() if hm.Parent then hm.WalkSpeed=os end
end

local function myBase() for _,ob in ipairs(W:GetDescendants()) do if ob:IsA("Model") or ob:IsA("BasePart") then local ow=ob:GetAttribute("Owner") or ob:GetAttribute("Player"); if ow==LP.Name or ow==LP.UserId then local p=ob:IsA("Model") and (ob.PrimaryPart and ob.PrimaryPart.Position) or ob.Position; if p then return p end end end end local sp=W:FindFirstChildOfClass("SpawnLocation"); return sp and sp.Position or Vector3.new(0,20,0) end
local function eScore(e) local r=eRar(e) local p=ePrice(e) local m=eMut(e); local b=p>0 and p or 0; if b==0 and r and RAR[r] then b=RAR[r][1]*1000000 end; if m then b=b*2.5 end return b end

-- MAIN LOOP
task.spawn(function()
    print("[LUXXY] Loop start")
    local lBR=0 local lER=0 local ce={}
    while _G.LuxxyRunning do
        R.Heartbeat:Wait()
        if St.Steal or St.Best then
            if tick()-lBR>CFG.BiomeTick then refreshBR() lBR=tick() end
            if tick()-lER>CFG.EggTick then lER=tick() local ok,r=pcall(findEggs); if ok then ce=r else ce={} end end
            local es=ce
            if #es==0 then FT.Text="Cari egg... (0)" task.wait(.3)
            else
                local tg
                if St.Best then local c=LP.Character local h=c and c:FindFirstChild("HumanoidRootPart"); local mp=h and h.Position; local bs,bd=-1,math.huge
                    for _,e in ipairs(es) do local p=ePos(e); if p then local sc=eScore(e); local d=mp and (mp-p).Magnitude or 0; if sc>bs or (sc==bs and d<bd) then bs=sc bd=d tg=e end end end
                else for _,e in ipairs(es) do local p=ePos(e); if selB(e,p) then tg=e break end end end
                if tg then
                    local p=ePos(tg)
                    if p then
                        local b=eggBiome(tg,p) or "?" local pr=ePrice(tg) local mu=eMut(tg)
                        FT.Text="➜ ["..b.."] "..tg.Name..(pr>0 and " $"..fmt(pr) or "")..(mu and " ✨"..mu or "")
                        -- HYBRID: coba remote di tiap tier
                        local ok=false
                        if St.SniperEnable then
                            for i,tier in ipairs(CFG.SniperTiers) do
                                if not (St.Steal or St.Best) then break end
                                local ch=LP.Character local hh=ch and ch:FindFirstChild("HumanoidRootPart")
                                local mp=hh and hh.Position
                                local cp=ePos(tg)
                                if not cp then break end
                                local curr=(mp and cp) and (mp-cp).Magnitude or 999
                                if curr>tier then
                                    local dir=cp-mp
                                    if dir.Magnitude>0.1 then
                                        local approach=cp-dir.Unit*tier
                                        pcall(move,approach,St.Move)
                                        if not (St.Steal or St.Best) then break end
                                    end
                                end
                                local sOk,sRes=pcall(sniperAttempt,tg)
                                if sOk and sRes then
                                    FT.Text="🎯 Hit tier "..tier.."!"
                                    print("[LUXXY] Sniper tier",tier,"hit")
                                    ok=true; break
                                end
                                task.wait(0.15)
                            end
                        end
                        if not ok then
                            local ret=0
                            while ret<=CFG.EggRetry do
                                if not (St.Steal or St.Best) then break end
                                local np=ePos(tg); if not np then break end
                                local mOk,mEr=pcall(move,np,St.Move)
                                if not mOk then FT.Text="⚠ Move err" task.wait(1) break end
                                if not (St.Steal or St.Best) then break end
                                pcall(tryGrab,tg) task.wait(.4)
                                local still=tg.Parent~=nil and isEgg(tg); if not still then break end
                                ret=ret+1
                                if ret<=CFG.EggRetry then local b2=eggBiome(tg,ePos(tg)) or "?"; FT.Text="➜ Retry "..ret.."/"..CFG.EggRetry end
                            end
                        end
                        if St.Steal or St.Best then
                            local bb,bdd=findBoss(CFG.BossR)
                            if bb and bdd<CFG.BossEscape then FT.Text="🚨 Kabur boss..." else FT.Text="➜ Base" end
                            pcall(move,myBase(),St.Move)
                        end
                        task.wait(.2)
                    end
                else
                    local bl={} for bn,v in pairs(St.SB) do if v then table.insert(bl,bn) end end
                    local bs=(not St.Best and #bl>0) and " ["..table.concat(bl,",").."]" or ""
                    FT.Text=(St.Best and "Best egg" or "Cari egg")..bs.." ("..#es..")"
                    task.wait(.3)
                end
            end
        else if MS.a then stop() end end
    end
    print("[LUXXY] Loop stop")
end)
task.spawn(function() refreshBR() task.wait(3) refreshBR() end)
nt("LUXXY","v"..CFG.Ver.." loaded 🌿")
print("[LUXXY] Loaded v"..CFG.Ver)
