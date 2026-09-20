--=============================================================
--  STEAL AN EGG — LUXXY
--  Luxury Green/White UI  •  Matrix Background  •  Mobile & PC
--  Author: (your name)
--  Version: 1.0.0
--=============================================================

--// SERVICES
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local SoundService      = game:GetService("SoundService")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--=============================================================
--  CONFIG  (edit di sini kalau perlu)
--=============================================================
local CONFIG = {
    Title        = "STEAL AN EGG — LUXXY",
    Version      = "1.0.0",
    SaveFile     = "LuxxyConfig.json",
    Thumbnail    = "rbxassetid://134782047288874", -- ganti ID thumbnail map
    Colors = {
        LeafGreen   = Color3.fromRGB(34, 139, 34),
        BrightGreen = Color3.fromRGB(60, 200, 90),
        White       = Color3.fromRGB(255, 255, 255),
        SoftWhite   = Color3.fromRGB(240, 255, 245),
        Dark        = Color3.fromRGB(15, 30, 20),
        Darker      = Color3.fromRGB(8, 18, 12),
        Border      = Color3.fromRGB(120, 220, 150),
    },
    FlySpeed     = 55,     -- kecepatan default saat drag egg
}

--=============================================================
--  EGG DATA (referensi nilai tertinggi)
--=============================================================
local EGG_DATA = {
    -- Mythic tier
    {name="Red Panda",      value=450000,     source="Cherry Blossom"},
    {name="Cosmic Gorilla", value=180000,     source="Event"},
    {name="Ankylosaurus",   value=120000,     source="Event"},
    {name="Orca",           value=80000,      source="Event"},
    {name="Chillin Chilli", value=55000,      source="Event"},
    {name="Mammoth",        value=42000,      source="Event"},
    {name="Tiger",          value=28000,      source="Event"},
    -- Other Pets
    {name="Koi",            value=12000000,   source="Cherry Blossom"},
    {name="Snowy Owl",      value=7500000,    source="Cherry Blossom"},
    {name="La Vacca Saturno Saturnita", value=2200000, source="Cosmic"},
    {name="Beluga Whale",   value=850000,     source="Abyss Ocean"},
    {name="Whale Shark",    value=700000,     source="Abyss Ocean"},
    {name="King Mammoth",   value=400000,     source="Snow"},
    -- Next tier
    {name="Stag",           value=145000000,  source="Cherry Blossom"},
    {name="Cosmic Dragon",  value=60000000,   source="Event"},
    {name="Tralaledon",     value=32000000,   source="Event"},
    {name="T-Rex",          value=25000000,   source="Event"},
    {name="Kraken",         value=15000000,   source="Event"},
    {name="Cerberus",       value=8000000,    source="Event"},
    {name="Yeti",           value=5000000,    source="Event"},
    {name="King Snake",     value=3500000,    source="Event"},
    -- Highest
    {name="Kitsune",        value=1800000000, source="Cherry Blossom"},
    {name="Unicorn",        value=1000000000, source="Cosmic"},
}

--=============================================================
--  RARITY LIST + GRADIENT
--=============================================================
local RARITY = {
    {name="Common",    c1=Color3.fromRGB(160,160,160), c2=Color3.fromRGB(255,255,255)},
    {name="Uncommon",  c1=Color3.fromRGB(60,220,80),   c2=Color3.fromRGB(255,255,255)},
    {name="Rare",      c1=Color3.fromRGB(40,120,255),  c2=Color3.fromRGB(255,255,255)},
    {name="Epic",      c1=Color3.fromRGB(150,60,255),  c2=Color3.fromRGB(255,255,255)},
    {name="Legendary", c1=Color3.fromRGB(255,220,40),  c2=Color3.fromRGB(255,255,255)},
    {name="Mythic",    c1=Color3.fromRGB(255,60,60),   c2=Color3.fromRGB(255,255,255)},
    {name="Cosmic",    c1=Color3.fromRGB(80,20,140),   c2=Color3.fromRGB(255,255,255)},
    {name="Secret",    c1=Color3.fromRGB(90,90,90),    c2=Color3.fromRGB(255,255,255)},
    {name="Divine",    c1=Color3.fromRGB(255,255,255), c2=Color3.fromRGB(255,120,220), c3=Color3.fromRGB(160,60,255)},
}

--=============================================================
--  STATE
--=============================================================
local State = {
    StealEgg      = false,
    StealBestEgg  = false,
    FlySpeed      = CONFIG.FlySpeed,
    SelectedRarities = {},   -- name -> true
}

--=============================================================
--  CONFIG SAVE/LOAD
--=============================================================
local function saveConfig()
    local data = {
        StealEgg      = State.StealEgg,
        StealBestEgg  = State.StealBestEgg,
        FlySpeed      = State.FlySpeed,
        SelectedRarities = State.SelectedRarities,
    }
    pcall(function()
        writefile(CONFIG.SaveFile, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    local ok, res = pcall(function()
        if isfile and isfile(CONFIG.SaveFile) then
            return HttpService:JSONDecode(readfile(CONFIG.SaveFile))
        end
    end)
    if ok and res then
        State.StealEgg          = res.StealEgg or false
        State.StealBestEgg      = res.StealBestEgg or false
        State.FlySpeed          = res.FlySpeed or CONFIG.FlySpeed
        State.SelectedRarities  = res.SelectedRarities or {}
    end
end
loadConfig()

--=============================================================
--  UTILS
--=============================================================
local function playClick()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://9114419348"  -- klik halus
    s.Volume  = 0.5
    s.Parent  = SoundService
    s:Play()
    task.delay(1, function() s:Destroy() end)
end

local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = 2
        })
    end)
end

local function new(class, props, children)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do obj[k] = v end
    for _,c in ipairs(children or {}) do c.Parent = obj end
    return obj
end

-- Gradient animated
local function animateGradient(gradient, c1, c2, c3)
    task.spawn(function()
        while gradient.Parent do
            local t = TweenService:Create(gradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Color = ColorSequence.new(c1)
            })
            t:Play(); t.Completed:Wait()
            local t2 = TweenService:Create(gradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Color = ColorSequence.new(c2)
            })
            t2:Play(); t2.Completed:Wait()
            if c3 then
                local t3 = TweenService:Create(gradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Color = ColorSequence.new(c3)
                })
                t3:Play(); t3.Completed:Wait()
            end
        end
    end)
end

local function applyGradient(parent, c1, c2, c3)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = 45
    g.Parent = parent
    animateGradient(g, c1, c2, c3)
    return g
end

--=============================================================
--  GUI BUILD
--=============================================================
-- Hapus lama
if CoreGui:FindFirstChild("LuxxyStealAnEgg") then
    CoreGui.LuxxyStealAnEgg:Destroy()
end

local ScreenGui = new("ScreenGui", {
    Name = "LuxxyStealAnEgg",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
})
ScreenGui.Parent = CoreGui

--=== OPEN BUTTON ===
local OpenBtn = new("TextButton", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 130, 0, 44),
    Position = UDim2.new(0, 16, 0, 16),
    BackgroundColor3 = CONFIG.Colors.LeafGreen,
    Text = "🌿 LUXXY",
    TextColor3 = CONFIG.Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    AutoButtonColor = false,
    BorderSizePixel = 0,
})
new("UICorner", {CornerRadius = UDim.new(0, 12)}, {Parent = OpenBtn})
local openStroke = new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 2}, {Parent = OpenBtn})
applyGradient(OpenBtn, CONFIG.Colors.LeafGreen, CONFIG.Colors.BrightGreen)

--=== MAIN FRAME ===
local Main = new("Frame", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 460, 0, 500),
    Position = UDim2.new(0.5, -230, 0.5, -250),
    BackgroundColor3 = CONFIG.Colors.Dark,
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
})
new("UICorner", {CornerRadius = UDim.new(0, 16)}, {Parent = Main})
new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 2}, {Parent = Main})

-- Matrix background
local Matrix = new("Frame", {
    Parent = Main,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 0.35,
    BackgroundColor3 = CONFIG.Colors.Darker,
    ZIndex = 0,
    ClipsDescendants = true,
})
new("UICorner", {CornerRadius = UDim.new(0, 16)}, {Parent = Matrix})

-- matrix rain (garis-garis vertikal animasi)
local matrixHolder = new("Frame", {
    Parent = Matrix,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
})
task.spawn(function()
    while matrixHolder.Parent do
        local line = new("Frame", {
            Parent = matrixHolder,
            Size = UDim2.new(0, 1, 0, math.random(20, 60)),
            Position = UDim2.new(math.random(), 0, -0.1, 0),
            BackgroundColor3 = CONFIG.Colors.BrightGreen,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
        })
        TweenService:Create(line, TweenInfo.new(math.random(3,6), Enum.EasingStyle.Linear), {
            Position = UDim2.new(line.Position.X.Scale, 0, 1.1, 0),
            BackgroundTransparency = 1,
        }):Play()
        task.delay(6, function() line:Destroy() end)
        task.wait(0.08)
    end
end)

--=== HEADER ===
local Header = new("Frame", {
    Parent = Main,
    Size = UDim2.new(1, 0, 0, 90),
    BackgroundColor3 = CONFIG.Colors.LeafGreen,
    BorderSizePixel = 0,
    ZIndex = 2,
})
new("UICorner", {CornerRadius = UDim.new(0, 16)}, {Parent = Header})
applyGradient(Header, CONFIG.Colors.LeafGreen, CONFIG.Colors.BrightGreen)

-- Thumbnail
local Thumb = new("ImageLabel", {
    Parent = Header,
    Size = UDim2.new(0, 70, 0, 70),
    Position = UDim2.new(0, 12, 0.5, -35),
    BackgroundColor3 = CONFIG.Colors.White,
    Image = CONFIG.Thumbnail,
    ScaleType = Enum.ScaleType.Crop,
    BorderSizePixel = 0,
    ZIndex = 3,
})
new("UICorner", {CornerRadius = UDim.new(0, 10)}, {Parent = Thumb})
new("UIStroke", {Color = CONFIG.Colors.White, Thickness = 2}, {Parent = Thumb})

local Title = new("TextLabel", {
    Parent = Header,
    Size = UDim2.new(1, -100, 0, 30),
    Position = UDim2.new(0, 92, 0, 18),
    BackgroundTransparency = 1,
    Text = CONFIG.Title,
    TextColor3 = CONFIG.Colors.White,
    Font = Enum.Font.GothamBlack,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
})
local SubTitle = new("TextLabel", {
    Parent = Header,
    Size = UDim2.new(1, -100, 0, 20),
    Position = UDim2.new(0, 92, 0, 48),
    BackgroundTransparency = 1,
    Text = "v"..CONFIG.Version.."  •  luxury edition",
    TextColor3 = CONFIG.Colors.SoftWhite,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
})

-- Close button
local CloseBtn = new("TextButton", {
    Parent = Header,
    Size = UDim2.new(0, 34, 0, 34),
    Position = UDim2.new(1, -44, 0, 12),
    BackgroundColor3 = CONFIG.Colors.Dark,
    Text = "✕",
    TextColor3 = CONFIG.Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    AutoButtonColor = false,
    BorderSizePixel = 0,
    ZIndex = 4,
})
new("UICorner", {CornerRadius = UDim.new(1, 0)}, {Parent = CloseBtn})

--=== TAB BUTTONS ===
local TabHolder = new("Frame", {
    Parent = Main,
    Size = UDim2.new(1, -24, 0, 34),
    Position = UDim2.new(0, 12, 0, 100),
    BackgroundTransparency = 1,
    ZIndex = 2,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, {Parent = TabHolder})

local Pages = {}
local TabBtns = {}
local function makeTab(name, idx)
    local b = new("TextButton", {
        Parent = TabHolder,
        Size = UDim2.new(0, 100, 0, 34),
        BackgroundColor3 = CONFIG.Colors.Darker,
        Text = name,
        TextColor3 = CONFIG.Colors.SoftWhite,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        LayoutOrder = idx,
    })
    new("UICorner", {CornerRadius = UDim.new(0, 8)}, {Parent = b})
    new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 1, Transparency = 0.6}, {Parent = b})
    TabBtns[name] = b

    local page = new("ScrollingFrame", {
        Parent = Main,
        Size = UDim2.new(1, -24, 1, -210),
        Position = UDim2.new(0, 12, 0, 144),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CONFIG.Colors.BrightGreen,
        Visible = (idx == 1),
        ZIndex = 2,
    })
    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, {Parent = page})
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
    b.MouseButton1Click:Connect(function()
        playClick(); selectTab(name)
    end)
end

--=== FOOTER (status) ===
local Footer = new("TextLabel", {
    Parent = Main,
    Size = UDim2.new(1, -24, 0, 20),
    Position = UDim2.new(0, 12, 1, -26),
    BackgroundTransparency = 1,
    Text = "Ready  •  idle",
    TextColor3 = CONFIG.Colors.BrightGreen,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
})

--=============================================================
--  UI HELPERS : Toggle, Rarity, Section
--=============================================================
local function section(parent, text, order)
    local f = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = order,
    })
    new("TextLabel", {
        Parent = f,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "▎ "..text,
        TextColor3 = CONFIG.Colors.BrightGreen,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    new("Frame", {
        Parent = f,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = CONFIG.Colors.Border,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
    })
    return f
end

local function makeToggle(parent, label, initial, callback, order)
    local row = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CONFIG.Colors.Darker,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = order,
    })
    new("UICorner", {CornerRadius = UDim.new(0, 10)}, {Parent = row})
    new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 1, Transparency = 0.7}, {Parent = row})

    new("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = CONFIG.Colors.SoftWhite,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local switch = new("Frame", {
        Parent = row,
        Size = UDim2.new(0, 46, 0, 24),
        Position = UDim2.new(1, -58, 0.5, -12),
        BackgroundColor3 = CONFIG.Colors.Dark,
        BorderSizePixel = 0,
    })
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, {Parent = switch})

    local knob = new("Frame", {
        Parent = switch,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = CONFIG.Colors.White,
        BorderSizePixel = 0,
    })
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, {Parent = knob})

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(CONFIG.Colors.LeafGreen, CONFIG.Colors.BrightGreen)
    gradient.Rotation = 0
    gradient.Parent = switch

    local isOn = initial and true or false

    local function render(animated)
        local targetPos  = isOn and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local targetCol  = isOn and CONFIG.Colors.LeafGreen or CONFIG.Colors.Dark
        local info = TweenInfo.new(animated and 0.2 or 0, Enum.EasingStyle.Quad)
        TweenService:Create(knob, info, {Position = targetPos}):Play()
        TweenService:Create(switch, info, {BackgroundColor3 = targetCol}):Play()
    end
    render(false)

    local btn = new("TextButton", {
        Parent = row,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    })
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        playClick()
        render(true)
        notify("LUXXY", label.." : "..(isOn and "ON" or "OFF"))
        if callback then callback(isOn) end
        saveConfig()
    end)

    return {row = row, get = function() return isOn end, set = function(v) isOn = v; render(true) end}
end

local function makeSlider(parent, label, min, max, initial, callback, order)
    local row = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = CONFIG.Colors.Darker,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = order,
    })
    new("UICorner", {CornerRadius = UDim.new(0, 10)}, {Parent = row})
    new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 1, Transparency = 0.7}, {Parent = row})

    local title = new("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = label.." : "..initial,
        TextColor3 = CONFIG.Colors.SoftWhite,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local bar = new("Frame", {
        Parent = row,
        Size = UDim2.new(1, -24, 0, 8),
        Position = UDim2.new(0, 12, 0, 38),
        BackgroundColor3 = CONFIG.Colors.Dark,
        BorderSizePixel = 0,
    })
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, {Parent = bar})

    local fill = new("Frame", {
        Parent = bar,
        Size = UDim2.new((initial-min)/(max-min), 0, 1, 0),
        BackgroundColor3 = CONFIG.Colors.BrightGreen,
        BorderSizePixel = 0,
    })
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, {Parent = fill})
    local g = Instance.new("UIGradient", fill)
    g.Color = ColorSequence.new(CONFIG.Colors.LeafGreen, CONFIG.Colors.BrightGreen)
    g.Rotation = 0

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max-min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        title.Text = label.." : "..val
        callback(val)
        saveConfig()
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return row
end

--=============================================================
--  MAIN PAGE CONTENT
--=============================================================
local order = 0
local function nextOrder() order = order + 1; return order end

section(MainPage, "STEAL ENGINE", nextOrder())

-- Toggle STEAL EGG
makeToggle(MainPage, "🥚  STEAL EGG", State.StealEgg, function(v)
    State.StealEgg = v
    Footer.Text = v and "Steal Egg aktif • memindai..." or "Ready • idle"
end, nextOrder())

-- Speed drag slider
makeSlider(MainPage, "⚡ Drag / Fly Speed", 20, 250, State.FlySpeed, function(v)
    State.FlySpeed = v
end, nextOrder())

-- Rarity section
section(MainPage, "SELECT RARITY", nextOrder())

local RarityHolder = new("Frame", {
    Parent = MainPage,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = nextOrder(),
})
new("UIGridLayout", {
    CellSize = UDim2.new(0.5, -4, 0, 34),
    CellPadding = UDim2.new(0, 8, 0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, {Parent = RarityHolder})

local rarityButtons = {}
local function refreshRarityVisual(name)
    local entry = rarityButtons[name]
    if not entry then return end
    local on = State.SelectedRarities[name] == true
    entry.stroke.Color = on and entry.colorA or CONFIG.Colors.Border
    entry.stroke.Thickness = on and 2 or 1
    entry.label.TextColor3 = on and CONFIG.Colors.White or CONFIG.Colors.SoftWhite
    entry.label.Text = (on and "✔  " or "")..name
end

for i, r in ipairs(RARITY) do
    local b = new("TextButton", {
        Parent = RarityHolder,
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = CONFIG.Colors.Darker,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        LayoutOrder = i,
    })
    new("UICorner", {CornerRadius = UDim.new(0, 8)}, {Parent = b})
    local stroke = new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 1}, {Parent = b})
    local label = new("TextLabel", {
        Parent = b,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = r.name,
        TextColor3 = CONFIG.Colors.SoftWhite,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    })
    -- gradient pada tombol
    local g = Instance.new("UIGradient", b)
    g.Color = ColorSequence.new(r.c1, r.c2)
    g.Rotation = 45
    animateGradient(g, r.c1, r.c2, r.c3)
    b.BackgroundTransparency = 0.55

    rarityButtons[r.name] = {btn=b, stroke=stroke, label=label, colorA=r.c1}
    refreshRarityVisual(r.name)

    b.MouseButton1Click:Connect(function()
        State.SelectedRarities[r.name] = not State.SelectedRarities[r.name]
        playClick()
        refreshRarityVisual(r.name)
        saveConfig()
    end)
end

-- Select All / None
local SelAll = new("TextButton", {
    Parent = MainPage,
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundColor3 = CONFIG.Colors.LeafGreen,
    Text = "✔  SELECT ALL",
    TextColor3 = CONFIG.Colors.White,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    AutoButtonColor = false,
    BorderSizePixel = 0,
    LayoutOrder = nextOrder(),
})
new("UICorner", {CornerRadius = UDim.new(0, 8)}, {Parent = SelAll})
new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 2}, {Parent = SelAll})

local allOn = false
SelAll.MouseButton1Click:Connect(function()
    allOn = not allOn
    for _, r in ipairs(RARITY) do
        State.SelectedRarities[r.name] = allOn
        refreshRarityVisual(r.name)
    end
    playClick()
    SelAll.Text = allOn and "✕  DESELECT ALL" or "✔  SELECT ALL"
    notify("LUXXY", allOn and "Semua rarity dipilih" or "Semua rarity dihapus")
    saveConfig()
end)

-- Steal Best Egg toggle
section(MainPage, "AUTO BEST", nextOrder())
makeToggle(MainPage, "👑  STEAL BEST EGG", State.StealBestEgg, function(v)
    State.StealBestEgg = v
    notify("LUXXY", v and "Mencari egg terbaik..." or "Auto best OFF")
end, nextOrder())

--=============================================================
--  INFO PAGE
--=============================================================
local infoText = [[
🌿 STEAL AN EGG — LUXXY
Luxury green edition

Version : ]]..CONFIG.Version..[[
Build   : Stable
Engine  : Raycast + Tween Fly
Author  : (your name)

Fitur:
• Steal Egg otomatis (rarity filter)
• Auto Best Egg berdasarkan value/s
• Fly drag dengan speed slider
• Save Config otomatis

Catatan:
Data egg/pet di script ini adalah
referensi umum. Jika game memiliki
nilai berbeda, script akan
menyesuaikan ke objek di map.

Tekan MAIN untuk kembali ke panel.

— Luxxy 🌿
]]

local InfoLabel = new("TextLabel", {
    Parent = InfoPage,
    Size = UDim2.new(1, -12, 0, 340),
    Position = UDim2.new(0, 6, 0, 0),
    BackgroundColor3 = CONFIG.Colors.Darker,
    BackgroundTransparency = 0.3,
    Text = infoText,
    TextColor3 = CONFIG.Colors.SoftWhite,
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    BorderSizePixel = 0,
    LayoutOrder = 1,
})
new("UICorner", {CornerRadius = UDim.new(0, 10)}, {Parent = InfoLabel})
new("UIStroke", {Color = CONFIG.Colors.Border, Thickness = 1, Transparency = 0.5}, {Parent = InfoLabel})
new("UIPadding", {PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12), PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10)}, {Parent = InfoLabel})

--=============================================================
--  OPEN / CLOSE ANIMATION
--=============================================================
local isOpen = false
local function openUI()
    if isOpen then return end
    isOpen = true
    Main.Visible = true
    Main.Size = UDim2.new(0, 460, 0, 0)
    Main.BackgroundTransparency = 1
    TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 460, 0, 500),
        BackgroundTransparency = 0,
    }):Play()
    playClick()
end
local function closeUI()
    if not isOpen then return end
    isOpen = false
    local t = TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 460, 0, 0),
        BackgroundTransparency = 1,
    })
    t:Play()
    t.Completed:Connect(function() Main.Visible = false end)
    playClick()
end

OpenBtn.MouseButton1Click:Connect(openUI)
CloseBtn.MouseButton1Click:Connect(closeUI)

-- Draggable header (PC + mobile)
do
    local dragging, dragStart, startPos
    Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Responsive (HP kecil)
local function fitScreen()
    local vp = Camera.ViewportSize
    local w = math.min(460, vp.X - 30)
    local h = math.min(500, vp.Y - 60)
    Main.Size = UDim2.new(0, w, 0, h)
end
fitScreen()
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScreen)

--=============================================================
--  FLY + COLLECT ENGINE
--=============================================================
local flyBodyVel, flyBodyGyro, flyAttach

local function startFly()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    if flyBodyVel then return end
    flyBodyVel = Instance.new("BodyVelocity", hrp)
    flyBodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBodyVel.Velocity = Vector3.zero
    flyBodyGyro = Instance.new("BodyGyro", hrp)
    flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBodyGyro.P = 20000
    flyBodyGyro.D = 500
    flyBodyGyro.CFrame = hrp.CFrame
end

local function stopFly()
    if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
end

local function flyTo(targetPos, speed)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    startFly()
    local dir = (targetPos - hrp.Position)
    local dist = dir.Magnitude
    if dist < 1 then return end
    flyBodyVel.Velocity = dir.Unit * (speed or State.FlySpeed)
    local t0 = tick()
    while flyBodyVel and flyBodyVel.Parent do
        dir = (targetPos - hrp.Position)
        if dir.Magnitude < 3 then break end
        if tick() - t0 > 8 then break end
        flyBodyVel.Velocity = dir.Unit * (speed or State.FlySpeed)
        flyBodyGyro.CFrame = CFrame.new(hrp.Position, targetPos)
        RunService.Heartbeat:Wait()
    end
    if flyBodyVel then flyBodyVel.Velocity = Vector3.zero end
end

-- cari egg di map
local function isSelectedRarity(egg)
    -- kosong = semua rarity lolos
    local any = false
    for _, v in pairs(State.SelectedRarities) do if v then any = true; break end end
    if not any then return true end

    -- coba baca nama/model/attribute
    local name = egg.Name
    local model = egg
    local rarityAttr = model:GetAttribute("Rarity")
        or (model.Parent and model.Parent:GetAttribute and model.Parent:GetAttribute("Rarity"))
        or (model:FindFirstChild("Rarity") and model.Rarity.Value)
    local rarityStr = tostring(rarityAttr or "")

    if rarityStr ~= "" then
        return State.SelectedRarities[rarityStr] == true
    end

    -- fallback: cocokkan substring nama
    for r, _ in pairs(State.SelectedRarities) do
        if r ~= "" and string.find(string.lower(name), string.lower(r), 1, true) then
            return true
        end
    end
    return false
end

local function findEggs()
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Egg" or string.find(string.lower(obj.Name), "egg") then
            if obj:IsA("Model") or obj:IsA("BasePart") then
                table.insert(eggs, obj)
            end
        end
    end
    return eggs
end

local function getEggPosition(egg)
    if egg:IsA("Model") then
        local primary = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
        if primary then return primary.Position end
    elseif egg:IsA("BasePart") then
        return egg.Position
    end
    return nil
end

local function getEggValue(egg)
    local n = string.lower(egg.Name)
    local best = 0
    for _, d in ipairs(EGG_DATA) do
        if string.find(n, string.lower(d.name), 1, true) then
            if d.value > best then best = d.value end
        end
    end
    return best
end

local function getMyBase()
    -- cari base/plot pemilik
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local owner = obj:GetAttribute("Owner") or obj:GetAttribute("Player")
            if owner == LocalPlayer.Name or owner == LocalPlayer.UserId then
                local pos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position) or obj.Position
                if pos then return pos end
            end
        end
    end
    -- fallback: spawn
    local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
    return sp and sp.Position or Vector3.new(0, 20, 0)
end

-- interaksi ambil egg (cari ProximityPrompt / ClickDetector / tool)
local function tryGrabEgg(egg)
    -- ProximityPrompt
    for _, obj in ipairs(egg:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(obj)
            end)
            return true
        end
        if obj:IsA("ClickDetector") then
            pcall(function()
                fireclickdetector(obj)
            end)
            return true
        end
    end
    -- Tool di backpack
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChildOfClass("Tool"))
        if tool then
            pcall(function() tool:Activate() end)
            return true
        end
    end
    return false
end

-- loop utama
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if State.StealEgg or State.StealBestEgg then
            local eggs = findEggs()
            local target, targetValue, targetPos

            if State.StealBestEgg then
                for _, egg in ipairs(eggs) do
                    local v = getEggValue(egg)
                    if v > (targetValue or 0) then
                        targetValue = v
                        target = egg
                    end
                end
            else
                for _, egg in ipairs(eggs) do
                    if isSelectedRarity(egg) then
                        target = egg
                        break
                    end
                end
            end

            if target then
                targetPos = getEggPosition(target)
                if targetPos then
                    Footer.Text = "➜ Menuju egg : "..target.Name
                    flyTo(targetPos, State.FlySpeed)
                    tryGrabEgg(target)
                    task.wait(0.4)

                    local basePos = getMyBase()
                    Footer.Text = "➜ Kembali ke base"
                    flyTo(basePos, State.FlySpeed)
                    task.wait(0.3)
                end
            else
                Footer.Text = (State.StealBestEgg and "Mencari best egg..." or "Mencari egg...")
            end
        else
            if flyBodyVel then stopFly() end
        end
    end
end)

--=============================================================
--  INIT
--=============================================================
if State.StealEgg or State.StealBestEgg then
    notify("LUXXY", "Config dimuat • fitur aktif")
end

selectTab("MAIN")
notify("LUXXY", "Script loaded 🌿  Tekan 🌿 LUXXY untuk membuka")
print("[LUXXY] Steal An Egg loaded • v"..CONFIG.Version)
