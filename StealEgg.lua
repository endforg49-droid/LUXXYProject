--=============================================================
--  STEAL AN EGG — LUXXY  v3.1.0
--  Anti-blink (speed cap + ownership reclaim) • Vertical escape
--=============================================================

if _G.LuxxyCleanup then pcall(_G.LuxxyCleanup) end
_G.LuxxyRunning = true

local Cleanup = {}
_G.LuxxyCleanup = function()
    _G.LuxxyRunning = false
    for _, fn in ipairs(Cleanup) do pcall(fn) end
end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local SoundService      = game:GetService("SoundService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

for _, obj in ipairs((function()
    local list = {}
    pcall(function()
        for _, c in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if c.Name == "LuxxyStealAnEgg" then table.insert(list, c) end
        end
    end)
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then for _, c in ipairs(pg:GetChildren()) do
            if c.Name == "LuxxyStealAnEgg" then table.insert(list, c) end
        end end
    end)
    if gethui then pcall(function()
        for _, c in ipairs(gethui():GetChildren()) do
            if c.Name == "LuxxyStealAnEgg" then table.insert(list, c) end
        end
    end) end
    return list
end)()) do pcall(function() obj:Destroy() end) end

pcall(function()
    local char = LocalPlayer.Character
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if d.Name == "LuxxySpoofVelocity" or d.Name == "LuxxySpoofGyro" then
                d:Destroy()
            end
        end
    end
end)

local function getGuiParent()
    if gethui then
        local ok, h = pcall(gethui); if ok and h then return h end
    end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then
        local ok3 = pcall(function() return cg.Name end)
        if ok3 then return cg end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local CONFIG = {
    Title = "STEAL AN EGG — LUXXY",
    Version = "3.1.0",
    SaveFile = "LuxxyConfig.json",
    Thumbnail = "rbxassetid://134782047288874",
    Colors = {
        LeafGreen   = Color3.fromRGB(34, 139, 34),
        BrightGreen = Color3.fromRGB(60, 200, 90),
        White       = Color3.fromRGB(255, 255, 255),
        SoftWhite   = Color3.fromRGB(240, 255, 245),
        Dark        = Color3.fromRGB(15, 30, 20),
        Darker      = Color3.fromRGB(8, 18, 12),
        Border      = Color3.fromRGB(120, 220, 150),
        Danger      = Color3.fromRGB(255, 70, 70),
    },
    MoveSpeed = 60,
    MaxSafeSpeed = 120,            -- batas aman anti-blink
    HoverDist = 3,
    FakeWalkSpeed = 16,
    VelLerp = 0.2,                 -- smoothing lebih halus
    MoveToInterval = 8,            -- jarang panggil MoveTo
    LookAhead = 12,
    AvoidStrength = 2.0,
    -- Network ownership
    NetworkReclaimInterval = 0.3,  -- reclaim tiap 0.3 detik
    MinOwnerReclaimDiff = 200,     -- reclaim kalau GetNetworkOwner ≠ LocalPlayer
    -- Biome
    MinBiomeVolume = 40000,
    BiomeYPad = 80,
    PlayerBiomeRange = 350,
    -- Boss
    BossDetectRange = 220,
    BossWarnRange   = 80,
    BossClimbRange  = 45,
    BossPanicRange  = 15,
    BossBaseRushMult = 1.25,
    BossClimbMult    = 1.35,
    BossPanicMult    = 1.45,
    BossPanicAltitude = 35,        -- turun dari 60
    BossClimbAltitude = 25,        -- turun dari 40
    EscapeHoldTime = 5,
    BossCheckInterval = 0.1,
    -- Egg retry
    EggRetryMax = 3,
}

local BIOMES = {
    "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano",
    "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom",
    "Titan Temple", "Demons",
}
local BIOME_LOOKUP = {}
for _, b in ipairs(BIOMES) do
    BIOME_LOOKUP[string.lower(b)] = b
    BIOME_LOOKUP[string.lower(string.gsub(b, " ", ""))] = b
end

local EGG_DATA = {
    {name="Red Panda", value=450000}, {name="Cosmic Gorilla", value=180000},
    {name="Ankylosaurus", value=120000}, {name="Orca", value=80000},
    {name="Chillin Chilli", value=55000}, {name="Mammoth", value=42000},
    {name="Tiger", value=28000}, {name="Koi", value=12000000},
    {name="Snowy Owl", value=7500000}, {name="La Vacca Saturno Saturnita", value=2200000},
    {name="Beluga Whale", value=850000}, {name="Whale Shark", value=700000},
    {name="King Mammoth", value=400000}, {name="Stag", value=145000000},
    {name="Cosmic Dragon", value=60000000}, {name="Tralaledon", value=32000000},
    {name="T-Rex", value=25000000}, {name="Kraken", value=15000000},
    {name="Cerberus", value=8000000}, {name="Yeti", value=5000000},
    {name="King Snake", value=3500000}, {name="Kitsune", value=1800000000},
    {name="Unicorn", value=1000000000},
}

local State = {
    StealEgg = false, StealBestEgg = false, ESP = false,
    MoveSpeed = CONFIG.MoveSpeed,
    SelectedBiomes = {},
}

local function saveConfig()
    pcall(function()
        if writefile then
            writefile(CONFIG.SaveFile, HttpService:JSONEncode({
                StealEgg = State.StealEgg, StealBestEgg = State.StealBestEgg,
                ESP = State.ESP, MoveSpeed = State.MoveSpeed,
                SelectedBiomes = State.SelectedBiomes,
            }))
        end
    end)
end

local function loadConfig()
    local ok, res = pcall(function()
        if isfile and isfile(CONFIG.SaveFile) then
            return HttpService:JSONDecode(readfile(CONFIG.SaveFile))
        end
    end)
    if ok and res then
        State.StealEgg       = res.StealEgg or false
        State.StealBestEgg   = res.StealBestEgg or false
        State.ESP            = res.ESP or false
        State.MoveSpeed      = res.MoveSpeed or CONFIG.MoveSpeed
        State.SelectedBiomes = res.SelectedBiomes or {}
    end
end
loadConfig()

-- clamp speed yang tersimpan
State.MoveSpeed = math.min(State.MoveSpeed, CONFIG.MaxSafeSpeed)

local function new(class, props, children)
    local obj = Instance.new(class)
    if type(props) == "table" then
        for k,v in pairs(props) do if k ~= "Parent" then obj[k] = v end end
    end
    if type(children) == "table" then
        if #children > 0 then
            for _, c in ipairs(children) do
                if typeof(c) == "Instance" then c.Parent = obj end
            end
        else
            for k,v in pairs(children) do
                if k == "Parent" then obj.Parent = v else obj[k] = v end
            end
        end
    end
    if type(props) == "table" and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function playClick()
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://6895079853"
        s.Volume = 0.35
        s.Parent = SoundService; s:Play()
        task.delay(1, function() pcall(function() s:Stop() end); s:Destroy() end)
    end)
end

local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title=title, Text=text, Duration=2})
    end)
end

local function applyGradient(parent, cols, speed)
    speed = speed or 0.4
    local g = Instance.new("UIGradient")
    g.Rotation = 0; g.Parent = parent
    local seq = {}
    local n = #cols
    for i = 1, n do
        table.insert(seq, ColorSequenceKeypoint.new((i-1)/n, cols[i]))
    end
    table.insert(seq, ColorSequenceKeypoint.new(1, cols[1]))
    g.Color = ColorSequence.new(seq)
    task.spawn(function()
        local phase = 0
        while g.Parent and _G.LuxxyRunning do
            phase = phase + RunService.RenderStepped:Wait() * speed
            if phase > 1 then phase = phase - 1 end
            g.Offset = Vector2.new(-1 + phase * 2, 0)
        end
    end)
    return g
end

local function fmtNum(n)
    if n >= 1e9 then return string.format("%.2fB", n/1e9) end
    if n >= 1e6 then return string.format("%.2fM", n/1e6) end
    if n >= 1e3 then return string.format("%.1fK", n/1e3) end
    return tostring(math.floor(n))
end

local PARENT = getGuiParent()
if PARENT:FindFirstChild("LuxxyStealAnEgg") then PARENT.LuxxyStealAnEgg:Destroy() end

local ScreenGui = new("ScreenGui", {
    Name = "LuxxyStealAnEgg", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
    Parent = PARENT,
})

local OpenBtn = new("TextButton", {
    Parent = ScreenGui, Size = UDim2.new(0, 56, 0, 56),
    Position = UDim2.new(1, -76, 0, 70),
    BackgroundColor3 = CONFIG.Colors.LeafGreen,
    Text = "", AutoButtonColor = false, BorderSizePixel = 0,
})
new("UICorner", {CornerRadius = UDim.new(1, 0), Parent = OpenBtn})
new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 2, Parent = OpenBtn})
applyGradient(OpenBtn, {CONFIG.Colors.LeafGreen, CONFIG.Colors.BrightGreen, CONFIG.Colors.LeafGreen}, 0.5)

local GearIcon = new("TextLabel", {
    Parent = OpenBtn, Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1, Text = "⚙️",
    TextColor3 = CONFIG.Colors.White, Font = Enum.Font.GothamBold,
    TextSize = 30, Rotation = 0,
})

local Main = new("Frame", {
    Parent = ScreenGui, Size = UDim2.new(0, 460, 0, 540),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = CONFIG.Colors.Dark,
    BorderSizePixel = 0, Visible = false, ClipsDescendants = true,
})
new("UICorner", {CornerRadius = UDim.new(0, 16), Parent = Main})
new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 2, Parent = Main})

local Matrix = new("Frame", {
    Parent = Main, Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 0.35, BackgroundColor3 = CONFIG.Colors.Darker,
    ZIndex = 0, ClipsDescendants = true,
})
new("UICorner", {CornerRadius = UDim.new(0, 16), Parent = Matrix})

local matrixHolder = new("Frame", {
    Parent = Matrix, Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1, ClipsDescendants = true,
})
task.spawn(function()
    while matrixHolder.Parent and _G.LuxxyRunning do
        local line = new("Frame", {
            Parent = matrixHolder,
            Size = UDim2.new(0, 1, 0, math.random(20, 60)),
            Position = UDim2.new(math.random(), 0, -0.1, 0),
            BackgroundColor3 = CONFIG.Colors.BrightGreen,
            BackgroundTransparency = 0.6, BorderSizePixel = 0,
        })
        TweenService:Create(line, TweenInfo.new(math.random(3,6), Enum.EasingStyle.Linear), {
            Position = UDim2.new(line.Position.X.Scale, 0, 1.1, 0),
            BackgroundTransparency = 1,
        }):Play()
        task.delay(6, function() pcall(function() line:Destroy() end) end)
        task.wait(0.1)
    end
end)

local Header = new("Frame", {
    Parent = Main, Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = CONFIG.Colors.LeafGreen,
    BorderSizePixel = 0, ZIndex = 2,
})
new("UICorner", {CornerRadius = UDim.new(0, 16), Parent = Header})
applyGradient(Header, {CONFIG.Colors.LeafGreen, CONFIG.Colors.BrightGreen, CONFIG.Colors.LeafGreen}, 0.25)

local Thumb = new("ImageLabel", {
    Parent = Header, Size = UDim2.new(0, 60, 0, 60),
    Position = UDim2.new(0, 12, 0.5, -30),
    BackgroundColor3 = CONFIG.Colors.White,
    Image = CONFIG.Thumbnail, ScaleType = Enum.ScaleType.Crop,
    BorderSizePixel = 0, ZIndex = 3,
})
new("UICorner", {CornerRadius = UDim.new(0, 10), Parent = Thumb})
new("UIStroke", {Color = CONFIG.Colors.White, Thickness = 2, Parent = Thumb})

new("TextLabel", {
    Parent = Header, Size = UDim2.new(1, -100, 0, 24),
    Position = UDim2.new(0, 82, 0, 16),
    BackgroundTransparency = 1, Text = CONFIG.Title,
    TextColor3 = CONFIG.Colors.White, Font = Enum.Font.GothamBlack,
    TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
})
new("TextLabel", {
    Parent = Header, Size = UDim2.new(1, -100, 0, 18),
    Position = UDim2.new(0, 82, 0, 42),
    BackgroundTransparency = 1,
    Text = "v"..CONFIG.Version.."  •  anti-blink",
    TextColor3 = CONFIG.Colors.SoftWhite, Font = Enum.Font.Gotham,
    TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
})

local CloseBtn = new("TextButton", {
    Parent = Header, Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -40, 0, 12),
    BackgroundColor3 = CONFIG.Colors.Dark, Text = "✕",
    TextColor3 = CONFIG.Colors.White, Font = Enum.Font.GothamBold,
    TextSize = 14, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 4,
})
new("UICorner", {CornerRadius = UDim.new(1, 0), Parent = CloseBtn})

local TabHolder = new("Frame", {
    Parent = Main, Size = UDim2.new(1, -24, 0, 34),
    Position = UDim2.new(0, 12, 0, 90),
    BackgroundTransparency = 1, ZIndex = 2,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = TabHolder,
})

local Pages, TabBtns = {}, {}
local function makeTab(name, idx)
    local b = new("TextButton", {
        Parent = TabHolder, Size = UDim2.new(0, 100, 0, 34),
        BackgroundColor3 = CONFIG.Colors.Darker, Text = name,
        TextColor3 = CONFIG.Colors.SoftWhite, Font = Enum.Font.GothamBold,
        TextSize = 14, AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = idx,
    })
    new("UICorner", {CornerRadius = UDim.new(0, 8), Parent = b})
    new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 1, Transparency = 0.6, Parent = b})
    TabBtns[name] = b
    local page = new("ScrollingFrame", {
        Parent = Main, Size = UDim2.new(1, -24, 1, -200),
        Position = UDim2.new(0, 12, 0, 134),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4, ScrollBarImageColor3 = CONFIG.Colors.BrightGreen,
        Visible = (idx == 1), ZIndex = 2,
    })
    new("UIListLayout", {
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page,
    })
    Pages[name] = page
    return page
end

local function selectTab(name)
    for n, p in pairs(Pages) do
        p.Visible = (n == name)
        TabBtns[n].BackgroundColor3 = (n == name) and CONFIG.Colors.LeafGreen or CONFIG.Colors.Darker
    end
end

local MainPage = makeTab("MAIN", 1)
local InfoPage = makeTab("INFO", 2)

for name, b in pairs(TabBtns) do
    b.MouseButton1Click:Connect(function() playClick(); selectTab(name) end)
end

local Footer = new("TextLabel", {
    Parent = Main, Size = UDim2.new(1, -24, 0, 20),
    Position = UDim2.new(0, 12, 1, -26),
    BackgroundTransparency = 1, Text = "Ready  •  idle",
    TextColor3 = CONFIG.Colors.BrightGreen, Font = Enum.Font.Gotham,
    TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
})

local function section(parent, text, order)
    local f = new("Frame", {
        Parent = parent, Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1, LayoutOrder = order,
    })
    new("TextLabel", {
        Parent = f, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "▎ "..text, TextColor3 = CONFIG.Colors.BrightGreen,
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    new("Frame", {
        Parent = f, Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = CONFIG.Colors.Border,
        BackgroundTransparency = 0.6, BorderSizePixel = 0,
    })
    return f
end

local function makeToggle(parent, label, initial, callback, order)
    local row = new("Frame", {
        Parent = parent, Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CONFIG.Colors.Darker, BackgroundTransparency = 0.25,
        BorderSizePixel = 0, LayoutOrder = order,
    })
    new("UICorner", {CornerRadius = UDim.new(0, 10), Parent = row})
    new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 1, Transparency = 0.7, Parent = row})
    new("TextLabel", {
        Parent = row, Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1,
        Text = label, TextColor3 = CONFIG.Colors.SoftWhite,
        Font = Enum.Font.GothamBold, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local switch = new("Frame", {
        Parent = row, Size = UDim2.new(0, 46, 0, 24),
        Position = UDim2.new(1, -58, 0.5, -12),
        BackgroundColor3 = CONFIG.Colors.Dark, BorderSizePixel = 0,
    })
    new("UICorner", {CornerRadius = UDim.new(1, 0), Parent = switch})
    local knob = new("Frame", {
        Parent = switch, Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = CONFIG.Colors.White, BorderSizePixel = 0,
    })
    new("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})

    local isOn = initial and true or false
    local function render(animated)
        local targetPos = isOn and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local targetCol = isOn and CONFIG.Colors.LeafGreen or CONFIG.Colors.Dark
        local info = TweenInfo.new(animated and 0.2 or 0, Enum.EasingStyle.Quad)
        TweenService:Create(knob, info, {Position = targetPos}):Play()
        TweenService:Create(switch, info, {BackgroundColor3 = targetCol}):Play()
    end
    render(false)
    local btn = new("TextButton", {
        Parent = row, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "",
    })
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        playClick(); render(true)
        notify("LUXXY", label.." : "..(isOn and "ON" or "OFF"))
        if callback then callback(isOn) end
        saveConfig()
    end)
    return {set = function(v) isOn = v; render(true) end}
end

local function makeSlider(parent, label, min, max, initial, callback, order)
    local row = new("Frame", {
        Parent = parent, Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = CONFIG.Colors.Darker, BackgroundTransparency = 0.25,
        BorderSizePixel = 0, LayoutOrder = order,
    })
    new("UICorner", {CornerRadius = UDim.new(0, 10), Parent = row})
    new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 1, Transparency = 0.7, Parent = row})
    local title = new("TextLabel", {
        Parent = row, Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 12, 0, 6), BackgroundTransparency = 1,
        Text = label.." : "..initial, TextColor3 = CONFIG.Colors.SoftWhite,
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local bar = new("Frame", {
        Parent = row, Size = UDim2.new(1, -24, 0, 8),
        Position = UDim2.new(0, 12, 0, 38),
        BackgroundColor3 = CONFIG.Colors.Dark, BorderSizePixel = 0,
    })
    new("UICorner", {CornerRadius = UDim.new(1, 0), Parent = bar})
    local fill = new("Frame", {
        Parent = bar, Size = UDim2.new((initial-min)/(max-min), 0, 1, 0),
        BackgroundColor3 = CONFIG.Colors.BrightGreen, BorderSizePixel = 0,
    })
    new("UICorner", {CornerRadius = UDim.new(1, 0), Parent = fill})
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(CONFIG.Colors.LeafGreen, CONFIG.Colors.BrightGreen)
    g.Parent = fill
    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        local val = math.floor(min + (max-min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        title.Text = label.." : "..val
        callback(val); saveConfig()
    end
    local c1 = bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(i.Position.X)
        end
    end)
    local c2 = UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    local c3 = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    table.insert(Cleanup, function() c1:Disconnect() end)
    table.insert(Cleanup, function() c2:Disconnect() end)
    table.insert(Cleanup, function() c3:Disconnect() end)
    return row
end

local order = 0
local function nextOrder() order = order + 1; return order end

section(MainPage, "STEAL ENGINE", nextOrder())

makeToggle(MainPage, "🥚  STEAL EGG (biome aware)", State.StealEgg, function(v)
    State.StealEgg = v
    Footer.Text = v and "Steal Egg aktif • memindai biome..." or "Ready • idle"
end, nextOrder())

makeSlider(MainPage, "🏃 Move Speed (max "..CONFIG.MaxSafeSpeed..")", 16, CONFIG.MaxSafeSpeed, State.MoveSpeed, function(v)
    State.MoveSpeed = v
end, nextOrder())

section(MainPage, "SELECT BIOME (untuk STEAL EGG)", nextOrder())

local BiomeHolder = new("Frame", {
    Parent = MainPage, Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, LayoutOrder = nextOrder(),
})
new("UIGridLayout", {
    CellSize = UDim2.new(0.5, -4, 0, 32),
    CellPadding = UDim2.new(0, 8, 0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder, Parent = BiomeHolder,
})

local BIOME_COLORS = {
    ["Forest"]         = {Color3.fromRGB(34,139,34),  Color3.fromRGB(120,220,120)},
    ["Lake"]           = {Color3.fromRGB(40,140,200), Color3.fromRGB(180,230,255)},
    ["Desert"]         = {Color3.fromRGB(220,190,120),Color3.fromRGB(255,240,200)},
    ["Jungle"]         = {Color3.fromRGB(20,120,60),  Color3.fromRGB(80,200,120)},
    ["Snow"]           = {Color3.fromRGB(200,230,255),Color3.fromRGB(255,255,255)},
    ["Volcano"]        = {Color3.fromRGB(180,40,20),  Color3.fromRGB(255,140,60)},
    ["Abyss Ocean"]    = {Color3.fromRGB(10,30,80),   Color3.fromRGB(60,120,200)},
    ["Prehistoric"]    = {Color3.fromRGB(90,60,30),   Color3.fromRGB(180,140,80)},
    ["Cosmic"]         = {Color3.fromRGB(80,20,140),  Color3.fromRGB(200,120,255)},
    ["Cherry Blossom"] = {Color3.fromRGB(255,180,220),Color3.fromRGB(255,255,255)},
    ["Titan Temple"]   = {Color3.fromRGB(180,140,60), Color3.fromRGB(255,220,140)},
    ["Demons"]         = {Color3.fromRGB(90,0,0),     Color3.fromRGB(255,60,60)},
}

local biomeButtons = {}
local function refreshBiomeVisual(name)
    local e = biomeButtons[name]; if not e then return end
    local on = State.SelectedBiomes[name] == true
    e.stroke.Color = on and e.colorA or CONFIG.Colors.Border
    e.stroke.Thickness = on and 2.5 or 1
    e.stroke.Transparency = on and 0 or 0.5
    e.label.TextColor3 = on and CONFIG.Colors.White or CONFIG.Colors.SoftWhite
    e.label.Text = (on and "✔ " or "")..name
    e.btn.BackgroundTransparency = on and 0.15 or 0.65
end

for i, biomeName in ipairs(BIOMES) do
    local colors = BIOME_COLORS[biomeName] or {CONFIG.Colors.LeafGreen, CONFIG.Colors.BrightGreen}
    local b = new("TextButton", {
        Parent = BiomeHolder, Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = CONFIG.Colors.Darker, BackgroundTransparency = 0.65,
        Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i,
    })
    new("UICorner", {CornerRadius = UDim.new(0, 8), Parent = b})
    local stroke = new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 1, Parent = b})
    local label = new("TextLabel", {
        Parent = b, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = biomeName, TextColor3 = CONFIG.Colors.SoftWhite,
        Font = Enum.Font.GothamBold, TextSize = 11,
    })
    applyGradient(b, {colors[1], colors[2], colors[1]}, 0.5)
    biomeButtons[biomeName] = {btn=b, stroke=stroke, label=label, colorA=colors[1]}
    refreshBiomeVisual(biomeName)
    b.MouseButton1Click:Connect(function()
        State.SelectedBiomes[biomeName] = not State.SelectedBiomes[biomeName]
        playClick(); refreshBiomeVisual(biomeName); saveConfig()
    end)
end

local SelAllBiome = new("TextButton", {
    Parent = MainPage, Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = CONFIG.Colors.LeafGreen,
    Text = "✔  SELECT ALL BIOMES",
    TextColor3 = CONFIG.Colors.White, Font = Enum.Font.GothamBold,
    TextSize = 13, AutoButtonColor = false, BorderSizePixel = 0,
    LayoutOrder = nextOrder(),
})
new("UICorner", {CornerRadius = UDim.new(0, 8), Parent = SelAllBiome})
new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 2, Parent = SelAllBiome})
applyGradient(SelAllBiome, {CONFIG.Colors.LeafGreen, CONFIG.Colors.BrightGreen, CONFIG.Colors.LeafGreen}, 0.4)

local allBiomeOn = false
SelAllBiome.MouseButton1Click:Connect(function()
    allBiomeOn = not allBiomeOn
    for _, biomeName in ipairs(BIOMES) do
        State.SelectedBiomes[biomeName] = allBiomeOn
        refreshBiomeVisual(biomeName)
    end
    playClick()
    SelAllBiome.Text = allBiomeOn and "✕  DESELECT ALL BIOMES" or "✔  SELECT ALL BIOMES"
    notify("LUXXY", allBiomeOn and "Semua biome dipilih" or "Semua biome dihapus")
    saveConfig()
end)

section(MainPage, "BEST + ESP", nextOrder())

makeToggle(MainPage, "👑  STEAL BEST EGG (SEMUA biome)", State.StealBestEgg, function(v)
    State.StealBestEgg = v
    notify("LUXXY", v and "Mencari best egg di SEMUA biome..." or "Auto best OFF")
end, nextOrder())

makeToggle(MainPage, "🔍  ESP EGGS (light mode)", State.ESP, function(v)
    State.ESP = v
    if not v and clearAllESP then clearAllESP() end
end, nextOrder())

local InfoLabel = new("TextLabel", {
    Parent = InfoPage, Size = UDim2.new(1, -12, 0, 580),
    Position = UDim2.new(0, 6, 0, 0),
    BackgroundColor3 = CONFIG.Colors.Darker, BackgroundTransparency = 0.3,
    Text = "🌿 STEAL AN EGG — LUXXY\nVersion : "..CONFIG.Version..
        "\n\nANTI-BLINK v3.1:\n"..
        "  • Speed cap di "..CONFIG.MaxSafeSpeed.." stud/s\n"..
        "  • Network ownership reclaim tiap "..CONFIG.NetworkReclaimInterval.."s\n"..
        "  • Velocity smoothing (lerp "..CONFIG.VelLerp..")\n"..
        "  • MoveTo jarang (tiap "..CONFIG.MoveToInterval.." frame)\n"..
        "  • Boss escape speed max 1.45×\n\n"..
        "ANTI-BOSS:\n"..
        "  • Waspada (≤"..CONFIG.BossWarnRange.."): rush base\n"..
        "  • Climb (≤"..CONFIG.BossClimbRange.."): naik diagonal → "..CONFIG.BossClimbAltitude.." stud\n"..
        "  • Panic (≤"..CONFIG.BossPanicRange.."): naik lurus → "..CONFIG.BossPanicAltitude.." stud\n"..
        "  • Hold escape "..CONFIG.EscapeHoldTime.."s setelah boss hilang\n\n"..
        "FITUR:\n"..
        "  • Best Egg cari SEMUA biome\n"..
        "  • Egg jatuh → retry max "..CONFIG.EggRetryMax.."×\n"..
        "  • Toggle OFF → instant stop\n\n"..
        "Biome: "..table.concat(BIOMES, ", ").."\n\n— Luxxy 🌿",
    TextColor3 = CONFIG.Colors.SoftWhite, Font = Enum.Font.Gotham,
    TextSize = 12, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    BorderSizePixel = 0, LayoutOrder = 1,
})
new("UICorner", {CornerRadius = UDim.new(0, 10), Parent = InfoLabel})
new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 1, Transparency = 0.5, Parent = InfoLabel})
new("UIPadding", {
    PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12),
    PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10), Parent = InfoLabel,
})

local isOpen = false
local gearRotation = 0

local function rotateGear(delta, duration)
    gearRotation = gearRotation + delta
    TweenService:Create(GearIcon,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Rotation = gearRotation}):Play()
end

local function getTargetSize()
    local vp = Camera.ViewportSize
    return math.min(460, vp.X - 30), math.min(540, vp.Y - 140)
end

local function openUI()
    if isOpen then return end
    isOpen = true
    rotateGear(180, 0.5)
    local w, h = getTargetSize()
    local btnCenter = OpenBtn.AbsolutePosition + OpenBtn.AbsoluteSize / 2
    Main.Visible = true
    Main.Size = UDim2.new(0, 20, 0, 20)
    Main.Position = UDim2.fromOffset(btnCenter.X, btnCenter.Y)
    Main.BackgroundTransparency = 1
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(w, h),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
    }):Play()
    playClick()
end

local function closeUI()
    if not isOpen then return end
    isOpen = false
    rotateGear(-180, 0.4)
    local btnCenter = OpenBtn.AbsolutePosition + OpenBtn.AbsoluteSize / 2
    local t = TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.fromOffset(btnCenter.X, btnCenter.Y),
        BackgroundTransparency = 1,
    })
    t:Play()
    t.Completed:Connect(function() Main.Visible = false end)
    playClick()
end

local cOpen = OpenBtn.MouseButton1Click:Connect(function()
    if isOpen then closeUI() else openUI() end
end)
local cClose = CloseBtn.MouseButton1Click:Connect(closeUI)
table.insert(Cleanup, function() cOpen:Disconnect() end)
table.insert(Cleanup, function() cClose:Disconnect() end)

do
    local dragging, dragStart, startPos
    local c1 = Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = Main.Position
        end
    end)
    local c2 = UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    local c3 = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    table.insert(Cleanup, function() c1:Disconnect() end)
    table.insert(Cleanup, function() c2:Disconnect() end)
    table.insert(Cleanup, function() c3:Disconnect() end)
end

local cVp = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if isOpen then
        local mw, mh = getTargetSize()
        Main.Size = UDim2.fromOffset(math.min(Main.Size.X.Offset, mw), math.min(Main.Size.Y.Offset, mh))
    end
end)
table.insert(Cleanup, function() cVp:Disconnect() end)

--=============================================================
--  BIOME SYSTEM
--=============================================================
local biomeRegions = {}

local function computeVolume(cf, size)
    return size.X * size.Y * size.Z
end

local function isBiomeCandidate(obj)
    if obj:IsA("Model") then
        local ok, cf, size = pcall(function() return obj:GetBoundingBox() end)
        if not ok then return nil end
        local vol = computeVolume(cf, size)
        if vol < CONFIG.MinBiomeVolume then return nil end
        return cf, size, vol
    elseif obj:IsA("BasePart") then
        local vol = computeVolume(obj.CFrame, obj.Size)
        if vol < CONFIG.MinBiomeVolume then return nil end
        return obj.CFrame, obj.Size, vol
    end
    return nil
end

local function refreshBiomeRegions()
    local newList = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local lower = string.lower(obj.Name)
            local canonical
            for key, canonicalName in pairs(BIOME_LOOKUP) do
                if string.find(lower, key, 1, true) then
                    canonical = canonicalName
                    break
                end
            end
            if canonical then
                local cf, size, vol = isBiomeCandidate(obj)
                if cf and size and vol then
                    table.insert(newList, {
                        part = obj, name = canonical,
                        cf = cf, size = size, volume = vol,
                    })
                end
            end
        end
    end
    table.sort(newList, function(a, b) return a.volume > b.volume end)
    biomeRegions = newList
end

local function getBiomeByAncestor(obj)
    local cur = obj
    local depth = 0
    while cur and cur ~= Workspace and depth < 8 do
        local lower = string.lower(cur.Name)
        for key, canonical in pairs(BIOME_LOOKUP) do
            if string.find(lower, key, 1, true) then return canonical end
        end
        cur = cur.Parent; depth = depth + 1
    end
    return nil
end

local function getBiomeByPosition(pos)
    for _, entry in ipairs(biomeRegions) do
        if entry.part and entry.part.Parent then
            local lp = entry.cf:PointToObjectSpace(pos)
            local hx, hy, hz = entry.size.X/2, entry.size.Y/2 + CONFIG.BiomeYPad, entry.size.Z/2
            if math.abs(lp.X) <= hx and math.abs(lp.Y) <= hy and math.abs(lp.Z) <= hz then
                return entry.name
            end
        end
    end
    return nil
end

local function getPlayerBiome()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return getBiomeByPosition(hrp.Position)
end

local function getEggBiome(egg, pos)
    local byAnc = getBiomeByAncestor(egg)
    if byAnc then return byAnc end
    if not pos then
        if egg:IsA("BasePart") then pos = egg.Position
        elseif egg:IsA("Model") then
            local p = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
            if p then pos = p.Position end
        end
    end
    if pos then
        local b = getBiomeByPosition(pos)
        if b then return b end
    end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and pos then
        if (hrp.Position - pos).Magnitude <= CONFIG.PlayerBiomeRange then
            return getPlayerBiome()
        end
    end
    return nil
end

--=============================================================
--  EGG DETECTION
--=============================================================
local EGG_NAME_BLACKLIST = {
    "fuse", "machine", "fuser", "station", "spawner",
    "shop", "store", "toko", "pedestal", "display",
    "base", "plot", "portal", "teleport", "tomb",
    "cage", "sign", "board", "decal",
}
local EGG_KW = {"egg", "telur"}
local STEAL_VERBS = {"steal", "take", "grab", "collect", "pick", "curi", "mencuri", "ambil", "mengambil"}

local function containsAny(str, list)
    str = string.lower(str or "")
    for _, kw in ipairs(list) do
        if string.find(str, kw, 1, true) then return kw end
    end
    return nil
end

local function isBlacklisted(obj)
    if containsAny(obj.Name, EGG_NAME_BLACKLIST) then return true end
    local p = obj.Parent
    local depth = 0
    while p and p ~= Workspace and depth < 3 do
        if containsAny(p.Name, EGG_NAME_BLACKLIST) then return true end
        p = p.Parent; depth = depth + 1
    end
    return false
end

local function findStealPrompt(obj)
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at = string.lower(d.ActionText or "")
            local ot = string.lower(d.ObjectText or "")
            local verbMatch = containsAny(at, STEAL_VERBS) or containsAny(ot, STEAL_VERBS)
            local eggMatch = containsAny(ot, EGG_KW) or containsAny(at, EGG_KW)
            if verbMatch and eggMatch then return d end
            if eggMatch and (at ~= "" or ot ~= "") then return d end
        end
    end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ClickDetector") then
            if containsAny(obj.Name, EGG_KW) then return d end
        end
    end
    return nil
end

local function isEggObject(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    if isBlacklisted(obj) then return false end
    local prompt = findStealPrompt(obj)
    if not prompt then return false end
    local nameHas = containsAny(obj.Name, EGG_KW)
    if not nameHas and prompt:IsA("ProximityPrompt") then
        nameHas = containsAny(prompt.ObjectText, EGG_KW)
    end
    if not nameHas and obj.Parent then
        nameHas = containsAny(obj.Parent.Name, EGG_KW)
    end
    return nameHas and true or false
end

local function getEggMutation(egg)
    for _, key in ipairs({"Mutation","mutation","Mutated","mutated"}) do
        if egg.GetAttribute then
            local v = egg:GetAttribute(key)
            if v and v ~= false and v ~= "" then return tostring(v) end
        end
    end
    for _, d in ipairs(egg:GetDescendants()) do
        if d:IsA("ValueBase") and (d.Name == "Mutation" or d.Name == "Mutated") then
            local v = d.Value
            if v and v ~= false and v ~= "" then return tostring(v) end
        end
        if d:IsA("TextLabel") and d.Text ~= "" then
            local lower = string.lower(d.Text)
            if string.find(lower, "mutat", 1, true) or string.find(lower, "rainbow", 1, true)
                or string.find(lower, "gold", 1, true) or string.find(lower, "shiny", 1, true) then
                return d.Text
            end
        end
    end
    local lower = string.lower(egg.Name)
    for _, kw in ipairs({"rainbow","gold","golden","shiny","mutated","galaxy","shadow"}) do
        if string.find(lower, kw, 1, true) then
            return string.upper(kw:sub(1,1))..kw:sub(2)
        end
    end
    return nil
end

local function getEggPosition(egg)
    local prompt = findStealPrompt(egg)
    if prompt then
        if prompt:IsA("ProximityPrompt") then
            local attach = prompt.Parent
            if attach and attach:IsA("BasePart") then return attach.Position
            elseif attach and attach:IsA("Attachment") and attach.Parent then return attach.WorldPosition end
        elseif prompt:IsA("ClickDetector") then
            local parent = prompt.Parent
            if parent and parent:IsA("BasePart") then return parent.Position end
        end
    end
    if egg:IsA("Model") then
        local p = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
        return p and p.Position
    elseif egg:IsA("BasePart") then
        return egg.Position
    end
end

local function getEggPrice(egg)
    local nameL = string.lower(egg.Name)
    local best = 0
    for _, d in ipairs(EGG_DATA) do
        if string.find(nameL, string.lower(d.name), 1, true) and d.value > best then
            best = d.value
        end
    end
    return best
end

local function findEggs()
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isEggObject(obj) then table.insert(eggs, obj) end
    end
    return eggs
end

local function hasAnyBiomeSelected()
    for _, v in pairs(State.SelectedBiomes) do if v then return true end end
    return false
end

local function isSelectedBiome(egg, pos)
    if not hasAnyBiomeSelected() then return true end
    local biome = getEggBiome(egg, pos)
    if not biome then return false end
    return State.SelectedBiomes[biome] == true
end

--=============================================================
--  ESP
--=============================================================
local espCache = {}

function clearAllESP()
    for egg, data in pairs(espCache) do
        pcall(function()
            if data.highlight then data.highlight:Destroy() end
            if data.billboard then data.billboard:Destroy() end
        end)
    end
    espCache = {}
end

local function buildESP(egg)
    local mut = getEggMutation(egg)
    local price = getEggPrice(egg)
    local biome = getEggBiome(egg) or "Unknown"

    local outlineColor = Color3.fromRGB(60, 200, 90)
    if mut then outlineColor = Color3.fromRGB(255,100,255) end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = egg
    highlight.FillTransparency = 1
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ScreenGui

    local bb = Instance.new("BillboardGui")
    bb.Adornee = egg
    bb.Size = UDim2.new(0, 220, 0, 60)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 350
    bb.Parent = ScreenGui

    local bg = Instance.new("Frame", bb)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 0.4
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    local bgStroke = Instance.new("UIStroke", bg)
    bgStroke.Color = outlineColor
    bgStroke.Thickness = 1.5

    local nameLbl = Instance.new("TextLabel", bg)
    nameLbl.Size = UDim2.new(1, -8, 0, 20)
    nameLbl.Position = UDim2.new(0, 4, 0, 4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = outlineColor
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextStrokeTransparency = 0.4
    nameLbl.Text = (mut and "✨ "..mut.." " or "")..egg.Name

    local infoLbl = Instance.new("TextLabel", bg)
    infoLbl.Size = UDim2.new(1, -8, 0, 16)
    infoLbl.Position = UDim2.new(0, 4, 0, 26)
    infoLbl.BackgroundTransparency = 1
    infoLbl.TextColor3 = Color3.fromRGB(255,255,255)
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 11
    infoLbl.TextStrokeTransparency = 0.5
    infoLbl.Text = price > 0 and ("💰 $"..fmtNum(price).."/s") or "💵 $?"

    local biomeLbl = Instance.new("TextLabel", bg)
    biomeLbl.Size = UDim2.new(1, -8, 0, 16)
    biomeLbl.Position = UDim2.new(0, 4, 0, 42)
    biomeLbl.BackgroundTransparency = 1
    biomeLbl.TextColor3 = CONFIG.Colors.BrightGreen
    biomeLbl.Font = Enum.Font.GothamBold
    biomeLbl.TextSize = 11
    biomeLbl.TextStrokeTransparency = 0.5
    biomeLbl.Text = "🌍 "..biome

    espCache[egg] = {
        highlight = highlight, billboard = bb,
        nameLbl = nameLbl, infoLbl = infoLbl, biomeLbl = biomeLbl,
        cachedPrice = price, cachedBiome = biome, cachedMut = mut,
    }
end

task.spawn(function()
    local scanInterval = 0.25
    local lastScan = 0
    while _G.LuxxyRunning do
        local dt = RunService.Heartbeat:Wait()
        if State.ESP then
            lastScan = lastScan + dt
            if lastScan >= scanInterval then
                lastScan = 0
                local eggs = findEggs()
                local alive = {}
                for _, egg in ipairs(eggs) do
                    alive[egg] = true
                    if not espCache[egg] then
                        buildESP(egg)
                    else
                        local data = espCache[egg]
                        local price = getEggPrice(egg)
                        local biome = getEggBiome(egg) or "Unknown"
                        local mut = getEggMutation(egg)
                        if price ~= data.cachedPrice or biome ~= data.cachedBiome or mut ~= data.cachedMut then
                            data.cachedPrice = price
                            data.cachedBiome = biome
                            data.cachedMut = mut
                            local outlineColor = Color3.fromRGB(60, 200, 90)
                            if mut then outlineColor = Color3.fromRGB(255,100,255) end
                            data.highlight.OutlineColor = outlineColor
                            data.nameLbl.TextColor3 = outlineColor
                            data.nameLbl.Text = (mut and "✨ "..mut.." " or "")..egg.Name
                            data.infoLbl.Text = price > 0 and ("💰 $"..fmtNum(price).."/s") or "💵 $?"
                            data.biomeLbl.Text = "🌍 "..biome
                        end
                    end
                end
                for egg, data in pairs(espCache) do
                    if not alive[egg] or not egg.Parent then
                        pcall(function()
                            data.highlight:Destroy(); data.billboard:Destroy()
                        end)
                        espCache[egg] = nil
                    end
                end
            end
        else
            if next(espCache) then clearAllESP() end
        end
    end
end)

--=============================================================
--  BOSS DETECTION
--=============================================================
local BOSS_KEYWORDS = {
    "boss", "guard", "chaser", "monster", "police", "cop",
    "enemy", "pursuer", "hunter", "evil", "demon", "grinch",
    "thief", "captor", "secur", "warden", "npc", "tembak", "pencuri",
}

local function isBossModel(model)
    if not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end

    local owner = model:GetAttribute("Owner")
        or model:GetAttribute("Player")
        or model:GetAttribute("OwnerId")
        or model:GetAttribute("UserId")
    if owner then return false end

    local nameLower = string.lower(model.Name)
    for _, kw in ipairs(BOSS_KEYWORDS) do
        if string.find(nameLower, kw, 1, true) then return true end
    end

    local p = model.Parent
    local depth = 0
    while p and p ~= Workspace and depth < 3 do
        local pl = string.lower(p.Name)
        for _, kw in ipairs(BOSS_KEYWORDS) do
            if string.find(pl, kw, 1, true) then return true end
        end
        p = p.Parent; depth = depth + 1
    end

    if model:GetAttribute("IsBoss") or model:GetAttribute("Boss") or model:GetAttribute("Enemy") then
        return true
    end
    return false
end

local function findNearestBoss(maxRange)
    maxRange = maxRange or CONFIG.BossDetectRange
    local char = LocalPlayer.Character
    if not char then return nil, nil, math.huge end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil, math.huge end
    local myPos = hrp.Position

    local nearest, nearestPos, nearestDist = nil, nil, maxRange
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isBossModel(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local ehrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if ehrp then
                    local d = (ehrp.Position - myPos).Magnitude
                    if d < nearestDist then
                        nearest = obj
                        nearestPos = ehrp.Position
                        nearestDist = d
                    end
                end
            end
        end
    end
    return nearest, nearestPos, nearestDist
end

--=============================================================
--  OBSTACLE AVOID
--=============================================================
local steerMemory = { side = nil, stuckFrames = 0 }

local function resetSteer()
    steerMemory.side = nil
    steerMemory.stuckFrames = 0
end

local function computeSteerDirection(hrp, char, dirUnit, lookAhead)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local origin = hrp.Position
    local fwdHit = Workspace:Raycast(origin, dirUnit * lookAhead, rayParams)
    if not fwdHit then
        resetSteer()
        return dirUnit, false
    end

    local flatNormal = Vector3.new(fwdHit.Normal.X, 0, fwdHit.Normal.Z)
    if flatNormal.Magnitude > 0.1 then
        local slide = dirUnit - flatNormal * dirUnit:Dot(flatNormal)
        if slide.Magnitude > 0.2 then
            local slideHit = Workspace:Raycast(origin, slide.Unit * lookAhead, rayParams)
            if not slideHit then
                resetSteer()
                return slide.Unit, false
            end
        end
    end

    local right = Vector3.new(dirUnit.Z, 0, -dirUnit.X).Unit
    local left = -right

    if steerMemory.side then
        steerMemory.stuckFrames = steerMemory.stuckFrames + 1
        if steerMemory.stuckFrames > 25 then
            steerMemory.side = nil
            steerMemory.stuckFrames = 0
        end
    end

    if not steerMemory.side then
        local hitL = Workspace:Raycast(origin, left * lookAhead, rayParams)
        local hitR = Workspace:Raycast(origin, right * lookAhead, rayParams)
        if hitL and not hitR then
            steerMemory.side = "right"
        elseif hitR and not hitL then
            steerMemory.side = "left"
        elseif not hitL and not hitR then
            local leftDir = (dirUnit + left * CONFIG.AvoidStrength).Unit
            local rightDir = (dirUnit + right * CONFIG.AvoidStrength).Unit
            steerMemory.side = (leftDir:Dot(dirUnit) > rightDir:Dot(dirUnit)) and "left" or "right"
        else
            return dirUnit, true
        end
        steerMemory.stuckFrames = 0
    end

    local steerDir
    if steerMemory.side == "left" then
        steerDir = (dirUnit + left * CONFIG.AvoidStrength).Unit
    else
        steerDir = (dirUnit + right * CONFIG.AvoidStrength).Unit
    end

    local checkHit = Workspace:Raycast(origin, steerDir * lookAhead, rayParams)
    if checkHit then
        local otherSide = (steerMemory.side == "left") and "right" or "left"
        local otherDir = (steerMemory.side == "left") and right or left
        local otherSteer = (dirUnit + otherDir * CONFIG.AvoidStrength).Unit
        local otherHit = Workspace:Raycast(origin, otherSteer * lookAhead, rayParams)
        if not otherHit then
            steerMemory.side = otherSide
            steerMemory.stuckFrames = 0
            steerDir = otherSteer
        else
            return dirUnit, true
        end
    end

    return steerDir, false
end

--=============================================================
--  WALK-SPOOF v8 — ANTI-BLINK
--=============================================================
local spoofState = { vel = nil, gyro = nil, active = false }

local function stopSpoof()
    if spoofState.vel then pcall(function() spoofState.vel:Destroy() end); spoofState.vel = nil end
    if spoofState.gyro then pcall(function() spoofState.gyro:Destroy() end); spoofState.gyro = nil end
    spoofState.active = false
end

table.insert(Cleanup, function()
    stopSpoof()
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d.Name == "LuxxySpoofVelocity" or d.Name == "LuxxySpoofGyro" then
                    d:Destroy()
                end
            end
        end
    end)
end)

local function spoofMoveTo(targetPos, speed)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    pcall(function() hrp:SetNetworkOwner(LocalPlayer) end)
    resetSteer()

    local hoverPos = targetPos + Vector3.new(0, CONFIG.HoverDist, 0)

    local origSpeed = hum.WalkSpeed
    hum.WalkSpeed = CONFIG.FakeWalkSpeed
    local wsConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if hum.WalkSpeed ~= CONFIG.FakeWalkSpeed then
            hum.WalkSpeed = CONFIG.FakeWalkSpeed
        end
    end)

    stopSpoof()
    local vel = Instance.new("BodyVelocity")
    vel.Name = "LuxxySpoofVelocity"
    vel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    vel.Velocity = Vector3.zero
    vel.Parent = hrp

    local gyro = Instance.new("BodyGyro")
    gyro.Name = "LuxxySpoofGyro"
    gyro.MaxTorque = Vector3.new(0, 1e5, 0)
    gyro.P = 12000
    gyro.D = 450
    gyro.CFrame = hrp.CFrame
    gyro.Parent = hrp

    spoofState.vel, spoofState.gyro, spoofState.active = vel, gyro, true

    -- Speed di-clamp ke batas aman
    local baseSpeed = math.clamp(speed or State.MoveSpeed, 16, CONFIG.MaxSafeSpeed)
    local currentSpeed = baseSpeed
    local targetSpeed = baseSpeed

    local t0 = tick()
    local currentVel = Vector3.zero
    local lastProgress = tick()
    local lastDist = (hoverPos - hrp.Position).Magnitude
    local frameCounter = 0
    local jumpCooldown = 0
    local lastBossCheck = 0
    local lastNetReclaim = 0
    local lookAhead = math.max(CONFIG.LookAhead, baseSpeed * 0.15)

    local escapeActive = false
    local escapeMode = "none"
    local escapeUntil = 0
    local lastEscapeFooter = tick()
    local groundY = hrp.Position.Y
    local panicTargetY = nil

    while _G.LuxxyRunning and char.Parent and hrp.Parent and hum.Health > 0 do
        if not (State.StealEgg or State.StealBestEgg) then break end
        if not vel or not vel.Parent then break end
        frameCounter = frameCounter + 1

        local dt = RunService.Heartbeat:Wait()
        if not dt then break end

        if hum.WalkSpeed ~= CONFIG.FakeWalkSpeed then
            hum.WalkSpeed = CONFIG.FakeWalkSpeed
        end

        -- === NETWORK OWNERSHIP RECLAIM (anti-blink utama) ===
        if tick() - lastNetReclaim > CONFIG.NetworkReclaimInterval then
            lastNetReclaim = tick()
            pcall(function()
                local owner = hrp:GetNetworkOwner()
                if owner ~= LocalPlayer then
                    hrp:SetNetworkOwner(LocalPlayer)
                end
            end)
        end

        -- === BOSS CHECK ===
        if tick() - lastBossCheck > CONFIG.BossCheckInterval then
            lastBossCheck = tick()
            local boss, bossPos, bossDist = findNearestBoss(CONFIG.BossDetectRange)

            if bossPos and bossDist < CONFIG.BossWarnRange then
                escapeActive = true
                escapeUntil = tick() + CONFIG.EscapeHoldTime

                if bossDist < CONFIG.BossPanicRange then
                    escapeMode = "panic"
                    if not panicTargetY then
                        panicTargetY = hrp.Position.Y + CONFIG.BossPanicAltitude
                    end
                elseif bossDist < CONFIG.BossClimbRange then
                    escapeMode = "climb"
                    panicTargetY = nil
                else
                    escapeMode = "waspada"
                    panicTargetY = nil
                end

                if tick() - lastEscapeFooter > 0.7 then
                    lastEscapeFooter = tick()
                    local tag = escapeMode == "panic" and "🚨 PANIC" or (escapeMode == "climb" and "⚠️ CLIMB" or "⚠️ WASPADA")
                    Footer.Text = tag.." — Boss "..math.floor(bossDist).." stud"
                end
            else
                if not (escapeActive and tick() < escapeUntil) then
                    if escapeActive then
                        escapeActive = false
                        escapeMode = "none"
                        panicTargetY = nil
                    end
                end
            end
        end

        -- === TARGET & SPEED ===
        local dirUnit
        local localTarget

        if escapeActive and escapeMode == "panic" and panicTargetY then
            local boss, bossPos = findNearestBoss(CONFIG.BossDetectRange)
            local horizDir = Vector3.zero
            if bossPos then
                horizDir = hrp.Position - bossPos
                horizDir = Vector3.new(horizDir.X, 0, horizDir.Z)
                if horizDir.Magnitude > 0.1 then horizDir = horizDir.Unit * 0.3 else horizDir = Vector3.zero end
            end
            local upDir = Vector3.new(0, 1, 0)
            dirUnit = (upDir + horizDir).Unit
            localTarget = hrp.Position + dirUnit * 20
            targetSpeed = math.min(baseSpeed * CONFIG.BossPanicMult, CONFIG.MaxSafeSpeed)
            if hrp.Position.Y >= panicTargetY then
                dirUnit = horizDir.Magnitude > 0.1 and horizDir.Unit or Vector3.new(0, 0, 0)
                localTarget = hrp.Position + dirUnit * 10
                targetSpeed = baseSpeed * 0.8
            end

        elseif escapeActive and escapeMode == "climb" then
            local boss, bossPos = findNearestBoss(CONFIG.BossDetectRange)
            local awayH = Vector3.new(1, 0, 0)
            if bossPos then
                awayH = hrp.Position - bossPos
                awayH = Vector3.new(awayH.X, 0, awayH.Z)
                if awayH.Magnitude > 0.1 then awayH = awayH.Unit end
            end
            local climbTargetY = groundY + CONFIG.BossClimbAltitude
            local needUp = hrp.Position.Y < climbTargetY
            local up = needUp and 0.9 or 0.15
            dirUnit = (awayH + Vector3.new(0, up, 0)).Unit
            localTarget = hrp.Position + dirUnit * 15
            targetSpeed = math.min(baseSpeed * CONFIG.BossClimbMult, CONFIG.MaxSafeSpeed)

        elseif escapeActive and escapeMode == "waspada" then
            local basePos = getMyBase()
            local toBase = basePos - hrp.Position
            if toBase.Magnitude > 5 then
                dirUnit = Vector3.new(toBase.X, 0.2, toBase.Z).Unit
                localTarget = basePos
            else
                dirUnit = Vector3.zero
                localTarget = hrp.Position
            end
            targetSpeed = math.min(baseSpeed * CONFIG.BossBaseRushMult, CONFIG.MaxSafeSpeed)

        else
            local toTarget = hoverPos - hrp.Position
            local dist = toTarget.Magnitude
            if dist < 4 then break end
            dirUnit = toTarget.Unit
            localTarget = hoverPos
            targetSpeed = baseSpeed
        end

        if tick() - t0 > 120 then break end

        currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * 0.15

        local steerDir = dirUnit
        local shouldJump = false
        if not escapeActive or escapeMode == "waspada" then
            steerDir, shouldJump = computeSteerDirection(hrp, char, dirUnit, lookAhead)
        end

        if shouldJump and tick() - jumpCooldown > 0.8 then
            hum.Jump = true
            jumpCooldown = tick()
        end

        local targetVel = steerDir * currentSpeed
        currentVel = currentVel:Lerp(targetVel, CONFIG.VelLerp)
        vel.Velocity = currentVel

        local horizLook = Vector3.new(currentVel.X, 0, currentVel.Z)
        if horizLook.Magnitude > 1 then
            gyro.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + horizLook.Unit)
        elseif dirUnit.Magnitude > 0.1 then
            local dirH = Vector3.new(dirUnit.X, 0, dirUnit.Z)
            if dirH.Magnitude > 0.1 then
                gyro.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dirH.Unit)
            end
        end

        if frameCounter % CONFIG.MoveToInterval == 0 then
            pcall(function()
                if currentVel.Magnitude > 0.5 then
                    hum:MoveTo(hrp.Position + currentVel.Unit * 4)
                end
            end)
        end

        local toT = hoverPos - hrp.Position
        local dNow = toT.Magnitude
        if not escapeActive then
            if math.abs(lastDist - dNow) < 0.4 then
                if tick() - lastProgress > 1.5 and tick() - jumpCooldown > 0.5 then
                    hum.Jump = true
                    jumpCooldown = tick()
                    lastProgress = tick()
                end
            else
                lastProgress = tick()
            end
            lastDist = dNow
        end
    end

    if vel then vel.Velocity = Vector3.zero end
    pcall(function() hum:MoveTo(hrp.Position) end)
    task.wait(0.05)
    stopSpoof()

    wsConn:Disconnect()
    if hum.Parent then hum.WalkSpeed = origSpeed end
end

local function getMyBase()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local owner = obj:GetAttribute("Owner") or obj:GetAttribute("Player")
            if owner == LocalPlayer.Name or owner == LocalPlayer.UserId then
                local pos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position) or obj.Position
                if pos then return pos end
            end
        end
    end
    local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
    return sp and sp.Position or Vector3.new(0, 20, 0)
end

local function tryGrabEgg(egg)
    local prompt = findStealPrompt(egg)
    if prompt then
        if prompt:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(prompt) end); return true
        elseif prompt:IsA("ClickDetector") then
            pcall(function() fireclickdetector(prompt) end); return true
        end
    end
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
            or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChildOfClass("Tool"))
        if tool then pcall(function() tool:Activate() end); return true end
    end
    return false
end

local function eggScore(egg)
    local price = getEggPrice(egg)
    local mut = getEggMutation(egg)
    local base = price > 0 and price or 0
    if mut then base = base * 2.5 end
    return base
end

--=============================================================
--  MAIN STEAL LOOP
--=============================================================
task.spawn(function()
    local lastBiomeRefresh = 0
    while _G.LuxxyRunning do
        RunService.Heartbeat:Wait()
        if State.StealEgg or State.StealBestEgg then
            if tick() - lastBiomeRefresh > 8 then
                refreshBiomeRegions()
                lastBiomeRefresh = tick()
            end

            local eggs = findEggs()
            local target

            if State.StealBestEgg then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local myPos = hrp and hrp.Position
                local bestScore, bestDist = -1, math.huge
                for _, egg in ipairs(eggs) do
                    local pos = getEggPosition(egg)
                    local sc = eggScore(egg)
                    local d = (myPos and pos) and (myPos - pos).Magnitude or 0
                    if sc > bestScore or (sc == bestScore and d < bestDist) then
                        bestScore = sc; bestDist = d; target = egg
                    end
                end
            else
                for _, egg in ipairs(eggs) do
                    local pos = getEggPosition(egg)
                    if isSelectedBiome(egg, pos) then
                        target = egg; break
                    end
                end
            end

            if target then
                local pos = getEggPosition(target)
                if pos then
                    local biome = getEggBiome(target, pos) or "?"
                    local price = getEggPrice(target)
                    local mut = getEggMutation(target)
                    Footer.Text = "➜ ["..biome.."] "..target.Name..
                        (price > 0 and (" $"..fmtNum(price)) or "")..
                        (mut and (" ✨"..mut) or "")

                    local retries = 0
                    while retries <= CONFIG.EggRetryMax do
                        if not (State.StealEgg or State.StealBestEgg) then break end
                        local nowPos = getEggPosition(target)
                        if not nowPos then break end

                        spoofMoveTo(nowPos, State.MoveSpeed)
                        if not (State.StealEgg or State.StealBestEgg) then break end

                        tryGrabEgg(target)
                        task.wait(0.45)

                        local stillThere = target.Parent ~= nil and isEggObject(target)
                        if not stillThere then break end

                        retries = retries + 1
                        if retries <= CONFIG.EggRetryMax then
                            local b2 = getEggBiome(target, getEggPosition(target)) or "?"
                            Footer.Text = "➜ Egg jatuh di ["..b2.."]! Ambil ulang ("..retries.."/"..CONFIG.EggRetryMax..")"
                        end
                    end

                    if State.StealEgg or State.StealBestEgg then
                        Footer.Text = "➜ Kembali ke base"
                        spoofMoveTo(getMyBase(), State.MoveSpeed)
                    end
                    task.wait(0.3)
                else
                    Footer.Text = "Egg ditemukan, posisi invalid"
                    task.wait(0.5)
                end
            else
                local biomeList = {}
                for b, v in pairs(State.SelectedBiomes) do if v then table.insert(biomeList, b) end end
                local biomeStr = #biomeList > 0 and (" ["..table.concat(biomeList, ",").."]") or ""
                if State.StealBestEgg then
                    Footer.Text = "Cari best egg SEMUA biome ("..#eggs.." egg)"
                else
                    Footer.Text = "Cari egg"..biomeStr.." ("..#eggs.." egg)"
                end
                task.wait(0.5)
            end
        else
            if spoofState.active then stopSpoof() end
        end
    end
end)

task.spawn(function()
    refreshBiomeRegions()
    task.wait(3)
    refreshBiomeRegions()
end)

selectTab("MAIN")
notify("LUXXY", "v"..CONFIG.Version.." loaded 🌿")
print("[LUXXY] Loaded • v"..CONFIG.Version.." • anti-blink ready")
