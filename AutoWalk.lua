--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  LuxxyHub - AutoWalk (v10.5 PRECISION)                   ║
    ║  100% Exact Path + Real Animations + Speed Boost         ║
    ║                                                           ║
    ║  ✅ Recording playback 100% akurat                       ║
    ║  ✅ Speed boost = accelerate jalur, bukan steering       ║
    ║  ✅ Smooth animations (Walk, Run, Jump, Swim)           ║
    ║  ✅ NO BLINKING - Physics-based + CFrame precision      ║
    ╚═══════════════════════════════════════════════════════════╝
]]

local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local SoundService     = game:GetService("SoundService")
local Debris           = game:GetService("Debris")
local LocalPlayer      = Players.LocalPlayer

local function log(msg) print("[LuxxyHub v10.5 PRECISION] " .. tostring(msg)) end
log("Script started - PRECISION MODE")

-- ================================================================
-- PARENT GUI
-- ================================================================
local function tryGetGui()
    if typeof(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui and typeof(hui) == "Instance" then return hui end
    end
    local ok, pg = pcall(function() return LocalPlayer:WaitForChild("PlayerGui", 3) end)
    if ok and pg and typeof(pg) == "Instance" then return pg end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg and typeof(cg) == "Instance" then return cg end
    return nil
end

local parentGui = tryGetGui()
if not parentGui then warn("[LuxxyHub] No parent GUI"); return end

local function cleanupIn(gui)
    if not gui then return end
    pcall(function()
        for _, v in ipairs(gui:GetChildren()) do
            if v.Name == "LuxxyHub_AutoWalk" then v:Destroy() end
        end
    end)
end
cleanupIn(parentGui)
pcall(function() cleanupIn(game:GetService("CoreGui")) end)
pcall(function() cleanupIn(LocalPlayer:WaitForChild("PlayerGui", 2)) end)
task.wait(0.1)

-- ================================================================
-- CONFIG
-- ================================================================
local CONFIG = {
    FILE_NAME       = "LuxxyHub_AutoWalk_Config.json",
    RECORD_INTERVAL = 0.04,
    DEFAULT_SPEED   = 16,
    MIN_MULT        = 1,
    MAX_MULT        = 10,
    DEFAULT_MULT    = 1,
    BACK_SECONDS    = 2,
    HISTORY_BUFFER  = 10,
    TELEPORT_THRESHOLD = 25,
    TELEPORT_JUMP_DETECT = 30,
    REWIND_COOLDOWN = 2.0,
    SPEED_SMOOTH_SAMPLES = 6,
    
    -- ★ PRECISION SETTINGS (v10.5)
    CFRAME_LERP_ALPHA = 0.15,
    VELOCITY_LERP_ALPHA = 0.2,
    WALK_SPEED_MIN = 10,
    WALK_SPEED_MAX = 20,
    RUN_SPEED_MIN = 22,
    RUN_SPEED_MAX = 100,
    
    TRAIL_LIFETIME   = 999,
    TRAIL_THICKNESS  = 0.8,
    TRAIL_COLOR_1    = Color3.fromRGB(88, 30, 160),
    TRAIL_COLOR_2    = Color3.fromRGB(255, 255, 255),
    TRAIL_COLOR_3    = Color3.fromRGB(190, 145, 255),
    THEME = {
        BG_DARK      = Color3.fromRGB(10, 6, 18),
        BG_PANEL     = Color3.fromRGB(22, 14, 38),
        BG_ELEMENT   = Color3.fromRGB(32, 22, 52),
        BG_ELEMENT2  = Color3.fromRGB(42, 30, 68),
        PURPLE_DARK  = Color3.fromRGB(88, 30, 160),
        PURPLE       = Color3.fromRGB(150, 80, 240),
        PURPLE_LIGHT = Color3.fromRGB(190, 145, 255),
        WHITE        = Color3.fromRGB(255, 255, 255),
        BLACK        = Color3.fromRGB(0, 0, 0),
        TEXT         = Color3.fromRGB(240, 238, 250),
        TEXT_DIM     = Color3.fromRGB(160, 155, 185),
        GREEN        = Color3.fromRGB(80, 220, 130),
        RED          = Color3.fromRGB(240, 80, 90),
        GOLD         = Color3.fromRGB(240, 200, 80),
        CYAN         = Color3.fromRGB(80, 220, 240),
    },
    IMG_OPEN    = "rbxassetid://125806010780793",
    IMG_ACTIVE  = "rbxassetid://72484610504506",
    SOUND_CLICK = "rbxassetid://6895079853",
    BG_IMAGE_ID      = "rbxassetid://125806010780793",
    BG_IMAGE_TRANS   = 0.75,
    BG_IMAGE_COLOR   = Color3.fromRGB(180, 140, 230),
}
local T = CONFIG.THEME

-- ================================================================
-- STATE
-- ================================================================
local activeGradients = {}
local STATE = {
    uiOpen = false,
    currentPage = "MAIN",
    savedWalks = {},
    checkpoints = {},
    speedMultiplier = CONFIG.DEFAULT_MULT,
    recording = { active = false, points = {}, startTime = 0, conn = nil, prevPos = nil, prevTime = 0, speedBuf = {} },
    currentRecording = {},
    playing = { active = false, conn = nil },
    currentPlayingId = nil,
    history = {},
    miniOpen = false,
    controlsRef = nil,
    autoRewindEnabled = true,
    lastRewindTime = 0,
    trail = nil,
    trailAttachments = {},
    trailEnabled = true,
}

-- ================================================================
-- UTILS
-- ================================================================
local function newInst(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end

local function tween(obj, time, props, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props)
    t:Play()
    return t
end

local function playClick()
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = CONFIG.SOUND_CLICK
        s.Volume = 0.35
        s.Parent = SoundService
        s:Play()
        Debris:AddItem(s, 3)
    end)
end

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ================================================================
-- GRADIENT STROKE
-- ================================================================
local function applyGradientStroke(frame, thickness, cornerRadius)
    thickness = thickness or 2
    if cornerRadius then
        local existing = frame:FindFirstChildOfClass("UICorner")
        if not existing then
            newInst("UICorner", { CornerRadius = UDim.new(0, cornerRadius) }, frame)
        end
    end
    local stroke = newInst("UIStroke", {
        Name = "GradientStroke",
        Thickness = thickness,
        Color = Color3.new(1, 1, 1),
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, frame)
    local grad = newInst("UIGradient", {
        Name = "StrokeGradient",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, T.PURPLE_DARK),
            ColorSequenceKeypoint.new(0.33, T.WHITE),
            ColorSequenceKeypoint.new(0.66, T.PURPLE_LIGHT),
            ColorSequenceKeypoint.new(1.00, T.PURPLE_DARK),
        }),
    }, stroke)
    table.insert(activeGradients, grad)
    return stroke, grad
end

local function addBgImage(frame, cornerRadius)
    cornerRadius = cornerRadius or 14
    local bg = newInst("ImageLabel", {
        Name = "BgImage",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = CONFIG.BG_IMAGE_ID,
        ImageTransparency = CONFIG.BG_IMAGE_TRANS,
        ImageColor3 = CONFIG.BG_IMAGE_COLOR,
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = frame.ZIndex or 1,
    }, frame)
    newInst("UICorner", { CornerRadius = UDim.new(0, cornerRadius) }, bg)
    return bg
end

RunService.Heartbeat:Connect(function()
    local flow = ((os.clock() * 0.6) % 2) - 1
    for i = #activeGradients, 1, -1 do
        local g = activeGradients[i]
        if g and g.Parent then
            g.Offset = Vector2.new(flow, 0)
        else
            table.remove(activeGradients, i)
        end
    end
end)

-- ================================================================
-- SCREENGUI
-- ================================================================
local ScreenGui = newInst("ScreenGui", {
    Name = "LuxxyHub_AutoWalk",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Enabled = true,
}, parentGui)

local notifHolder = newInst("Frame", {
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    ZIndex = 490,
}, ScreenGui)

local function notify(text, color)
    local bg = newInst("Frame", {
        Size = UDim2.new(0, 0, 0, 34),
        Position = UDim2.new(0.5, 0, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = T.BG_PANEL,
        BorderSizePixel = 0,
        ZIndex = 500,
    }, notifHolder)
    newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, bg)
    applyGradientStroke(bg, 1.5, 8)
    newInst("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or T.TEXT,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 502,
    }, bg)
    tween(bg, 0.3, { Size = UDim2.new(0, 260, 0, 34) })
    task.delay(2.4, function()
        local tw = tween(bg, 0.25, { Size = UDim2.new(0, 0, 0, 34), BackgroundTransparency = 1 })
        tw.Completed:Connect(function() bg:Destroy() end)
    end)
end

-- ================================================================
-- SIZES
-- ================================================================
local vps = workspace.CurrentCamera.ViewportSize
local isMob = isMobile()
local MAIN_W  = isMob and math.clamp(vps.X * 0.92, 300, 420) or math.clamp(vps.X * 0.42, 400, 520)
local MAIN_H  = isMob and math.clamp(vps.Y * 0.72, 300, 380) or math.clamp(vps.Y * 0.68, 340, 420)
local SIDEBAR_W = isMob and 78 or 96
local MINI_W  = math.clamp(vps.X * (isMob and 0.72 or 0.28), 240, 300)
local MINI_H  = math.clamp(vps.Y - 80, 320, 520)

-- ================================================================
-- FLOAT BUTTON
-- ================================================================
local FLOAT_BTN_X = 20
local FLOAT_BTN_Y = 140

local floatBtn = newInst("ImageButton", {
    Name = "FloatBtn",
    Size = UDim2.new(0, 54, 0, 54),
    Position = UDim2.new(0, FLOAT_BTN_X, 0, FLOAT_BTN_Y),
    AnchorPoint = Vector2.new(0, 0),
    BackgroundColor3 = T.BG_PANEL,
    BorderSizePixel = 0,
    Image = CONFIG.IMG_OPEN,
    ImageColor3 = Color3.new(1, 1, 1),
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 100, Active = true, AutoButtonColor = false,
}, ScreenGui)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, floatBtn)
applyGradientStroke(floatBtn, 2, 30)
newInst("UIPadding", {
    PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
}, floatBtn)

-- ================================================================
-- MAIN FRAME
-- ================================================================
local mainFrame = newInst("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, MAIN_W, 0, MAIN_H),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = T.BG_PANEL,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 50,
    ClipsDescendants = true,
}, ScreenGui)
newInst("UICorner", { CornerRadius = UDim.new(0, 14) }, mainFrame)
addBgImage(mainFrame, 14)
applyGradientStroke(mainFrame, 2, 14)

-- ================================================================
-- TRAIL
-- ================================================================
local function destroyTrail()
    if STATE.trail then
        pcall(function() STATE.trail.Enabled = false end)
        pcall(function() STATE.trail:Destroy() end)
        STATE.trail = nil
    end
    for _, a in ipairs(STATE.trailAttachments) do
        if a and a.Parent then pcall(function() a:Destroy() end) end
    end
    STATE.trailAttachments = {}
end

local function createTrail()
    destroyTrail()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local halfT = (CONFIG.TRAIL_THICKNESS or 0.8) / 2
    local a0 = newInst("Attachment", { Name = "LuxxyTrailA0", Position = Vector3.new(0, halfT, 0) }, root)
    local a1 = newInst("Attachment", { Name = "LuxxyTrailA1", Position = Vector3.new(0, -halfT, 0) }, root)
    local trail = newInst("Trail", {
        Name = "LuxxyTrail",
        Attachment0 = a0, Attachment1 = a1,
        Lifetime = CONFIG.TRAIL_LIFETIME,
        MinLength = 0, FaceCamera = true,
        LightEmission = 0.6, LightInfluence = 0,
        WidthScale = NumberSequence.new(1),
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, CONFIG.TRAIL_COLOR_1),
            ColorSequenceKeypoint.new(0.50, CONFIG.TRAIL_COLOR_2),
            ColorSequenceKeypoint.new(1.00, CONFIG.TRAIL_COLOR_3),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.0, 0.15),
            NumberSequenceKeypoint.new(0.85, 0.4),
            NumberSequenceKeypoint.new(1.0, 1.0),
        }),
        Enabled = true,
    }, root)
    STATE.trail = trail
    STATE.trailAttachments = { a0, a1 }
end

-- ================================================================
-- OPEN / CLOSE
-- ================================================================
local toggleLock = false

local function setFloatImage(active)
    tween(floatBtn, 0.15, { ImageTransparency = 1 })
    task.delay(0.15, function()
        floatBtn.Image = active and CONFIG.IMG_ACTIVE or CONFIG.IMG_OPEN
        tween(floatBtn, 0.15, { ImageTransparency = 0 })
    end)
end

local function openUI()
    if STATE.uiOpen then return end
    STATE.uiOpen = true
    playClick()
    setFloatImage(true)
    mainFrame.Visible = true
    mainFrame.BackgroundTransparency = 1
    mainFrame.Size = UDim2.new(0, MAIN_W * 0.9, 0, MAIN_H * 0.9)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    tween(mainFrame, 0.3, {
        Size = UDim2.new(0, MAIN_W, 0, MAIN_H),
        BackgroundTransparency = 0,
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function closeUI()
    if not STATE.uiOpen then return end
    STATE.uiOpen = false
    playClick()
    setFloatImage(false)
    local tw = tween(mainFrame, 0.22, {
        Size = UDim2.new(0, MAIN_W * 0.9, 0, MAIN_H * 0.9),
        BackgroundTransparency = 1,
    }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    tw.Completed:Connect(function() mainFrame.Visible = false end)
end

local function toggleUI()
    if toggleLock then return end
    toggleLock = true
    task.delay(0.35, function() toggleLock = false end)
    if STATE.uiOpen then closeUI() else openUI() end
end

floatBtn.Activated:Connect(toggleUI)
makeDraggable(mainFrame)

-- ================================================================
-- UI CONTENT
-- ================================================================
local headerH = 42
local header = newInst("Frame", {
    Size = UDim2.new(1, 0, 0, headerH),
    BackgroundColor3 = T.BG_DARK,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 51,
}, mainFrame)
newInst("UICorner", { CornerRadius = UDim.new(0, 14) }, header)
newInst("Frame", {
    Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = T.BG_DARK, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 51,
}, header)

newInst("TextLabel", {
    Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1, Text = "LuxxyHub  •  AutoWalk v10.5",
    TextColor3 = T.WHITE, TextSize = 15, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52,
}, header)

local closeMainBtn = newInst("TextButton", {
    Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -34, 0.5, -14),
    BackgroundColor3 = T.BG_ELEMENT, BorderSizePixel = 0,
    Text = "✕", TextColor3 = T.TEXT, TextSize = 14,
    Font = Enum.Font.GothamBold, AutoButtonColor = false, Active = true, ZIndex = 52,
}, header)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, closeMainBtn)
closeMainBtn.Activated:Connect(closeUI)

local sidebar = newInst("Frame", {
    Size = UDim2.new(0, SIDEBAR_W, 1, -headerH - 16),
    Position = UDim2.new(0, 8, 0, headerH + 4),
    BackgroundColor3 = T.BG_DARK, BackgroundTransparency = 0.35,
    BorderSizePixel = 0, ZIndex = 51,
}, mainFrame)
newInst("UICorner", { CornerRadius = UDim.new(0, 10) }, sidebar)
newInst("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
newInst("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8) }, sidebar)

local function makeSidebarBtn(text, order)
    local b = newInst("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.BG_ELEMENT,
        BorderSizePixel = 0, Text = text, TextColor3 = T.TEXT,
        TextSize = 12, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        AutoButtonColor = false, Active = true, ZIndex = 52,
    }, sidebar)
    b.LayoutOrder = order
    newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
    applyGradientStroke(b, 1.5, 8)
    return b
end

local btnMain = makeSidebarBtn("MAIN 🏠", 1)
local btnInfo = makeSidebarBtn("INFO 📢", 2)

local contentX = SIDEBAR_W + 16
local content = newInst("Frame", {
    Size = UDim2.new(1, -contentX - 8, 1, -headerH - 16),
    Position = UDim2.new(0, contentX, 0, headerH + 4),
    BackgroundColor3 = T.BG_DARK, BackgroundTransparency = 0.35,
    BorderSizePixel = 0, ZIndex = 51, ClipsDescendants = true,
}, mainFrame)
newInst("UICorner", { CornerRadius = UDim.new(0, 10) }, content)

local pageMain = newInst("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = true, ZIndex = 52 }, content)
local pageInfo = newInst("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 52 }, content)

local topRow = newInst("Frame", {
    Size = UDim2.new(1, -20, 0, 38), Position = UDim2.new(0, 10, 0, 10),
    BackgroundTransparency = 1, ZIndex = 53,
}, pageMain)

local execBtnW = 92
local recordLabel = newInst("TextLabel", {
    Size = UDim2.new(1, -(execBtnW + 6), 1, 0),
    BackgroundColor3 = T.BG_ELEMENT, BorderSizePixel = 0,
    Text = "📹 AUTO WALK RECORD", TextColor3 = T.TEXT,
    TextSize = 12, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 54,
}, topRow)
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, recordLabel)
applyGradientStroke(recordLabel, 1.5, 8)

local execBtn = newInst("TextButton", {
    Size = UDim2.new(0, execBtnW, 1, 0), Position = UDim2.new(1, -execBtnW, 0, 0),
    BackgroundColor3 = T.PURPLE_DARK, BorderSizePixel = 0,
    Text = "▶ EXECUTE", TextColor3 = T.WHITE,
    TextSize = 12, Font = Enum.Font.GothamBold,
    AutoButtonColor = false, Active = true, ZIndex = 54,
}, topRow)
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, execBtn)
applyGradientStroke(execBtn, 2, 8)

local savedHeader = newInst("Frame", {
    Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 54),
    BackgroundTransparency = 1, ZIndex = 53,
}, pageMain)
newInst("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    Text = "SAVED WALK  (auto-saved)", TextColor3 = T.PURPLE_LIGHT,
    TextSize = 11, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 54,
}, savedHeader)

local savedScroll = newInst("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -154), Position = UDim2.new(0, 10, 0, 78),
    BackgroundColor3 = T.BG_ELEMENT, BackgroundTransparency = 0.6,
    BorderSizePixel = 0, ScrollBarThickness = 4,
    ScrollBarImageColor3 = T.PURPLE,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 53,
}, pageMain)
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, savedScroll)
applyGradientStroke(savedScroll, 1.5, 8)
newInst("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, savedScroll)
newInst("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, savedScroll)

local speedRow = newInst("Frame", {
    Size = UDim2.new(1, -20, 0, 60), Position = UDim2.new(0, 10, 1, -70),
    BackgroundColor3 = T.BG_ELEMENT, BackgroundTransparency = 0.55,
    BorderSizePixel = 0, ZIndex = 53,
}, pageMain)
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, speedRow)
applyGradientStroke(speedRow, 1.5, 8)
newInst("TextLabel", {
    Size = UDim2.new(1, -80, 0, 20), Position = UDim2.new(0, 12, 0, 6),
    BackgroundTransparency = 1, Text = "SPEED BOOST",
    TextColor3 = T.PURPLE_LIGHT, TextSize = 11,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 54,
}, speedRow)
local speedValLabel = newInst("TextLabel", {
    Size = UDim2.new(0, 70, 0, 20), Position = UDim2.new(1, -82, 0, 6),
    BackgroundTransparency = 1, Text = "×" .. CONFIG.DEFAULT_MULT,
    TextColor3 = T.WHITE, TextSize = 11, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 54,
}, speedRow)

local sliderTrack = newInst("Frame", {
    Size = UDim2.new(1, -24, 0, 8), Position = UDim2.new(0, 12, 0, 38),
    BackgroundColor3 = T.BG_ELEMENT2, BorderSizePixel = 0, ZIndex = 54,
}, speedRow)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderTrack)

local sliderFill = newInst("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = T.PURPLE, BorderSizePixel = 0, ZIndex = 55,
}, sliderTrack)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderFill)

local sliderKnob = newInst("Frame", {
    Size = UDim2.new(0, 16, 0, 16),
    Position = UDim2.new(0, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = T.WHITE, BorderSizePixel = 0, ZIndex = 56,
}, sliderTrack)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, sliderKnob)

-- INFO
newInst("TextLabel", {
    Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 10),
    BackgroundTransparency = 1, Text = "LuxxyHub  •  AutoWalk v10.5 PRECISION",
    TextColor3 = T.WHITE, TextSize = 16, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53,
}, pageInfo)
newInst("TextLabel", {
    Size = UDim2.new(1, -20, 1, -50), Position = UDim2.new(0, 10, 0, 42),
    BackgroundTransparency = 1,
    Text = "📢 INFO v10.5 PRECISION\n\n• 100% Exact Path (CFrame Lerp)\n• Speed boost = accelerate jalur\n• Smooth animation: WALK, RUN, JUMP, SWIM\n• NO BLINKING - Physics + CFrame\n\nSpeed Boost:\n- ×1 = normal\n- ×2 = 2x lebih cepat\n- ×5 = 5x lebih cepat\n- ×10 = 10x lebih cepat",
    TextColor3 = T.TEXT_DIM, TextSize = 12, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true, ZIndex = 53,
}, pageInfo)

-- ================================================================
-- MINI UI
-- ================================================================
local miniUI = newInst("Frame", {
    Name = "MiniRecord",
    Size = UDim2.new(0, MINI_W, 0, MINI_H),
    Position = UDim2.new(1, -MINI_W/2 - 16, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = T.BG_PANEL, BorderSizePixel = 0,
    Visible = false, ZIndex = 200, ClipsDescendants = true,
}, ScreenGui)
newInst("UICorner", { CornerRadius = UDim.new(0, 12) }, miniUI)
addBgImage(miniUI, 12)
applyGradientStroke(miniUI, 2, 12)
makeDraggable(miniUI)

local miniHeaderH = 32
local miniHeader = newInst("Frame", {
    Size = UDim2.new(1, 0, 0, miniHeaderH),
    BackgroundColor3 = T.BG_DARK, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, ZIndex = 201,
}, miniUI)
newInst("UICorner", { CornerRadius = UDim.new(0, 12) }, miniHeader)
newInst("Frame", {
    Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = T.BG_DARK, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, ZIndex = 201,
}, miniHeader)
newInst("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "📹 RECORD WALK",
    TextColor3 = T.WHITE, TextSize = 12, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202,
}, miniHeader)

local miniMinBtn = newInst("TextButton", {
    Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -50, 0.5, -11),
    BackgroundColor3 = T.BG_ELEMENT, BorderSizePixel = 0,
    Text = "─", TextColor3 = T.TEXT, TextSize = 12,
    Font = Enum.Font.GothamBold, AutoButtonColor = false, Active = true, ZIndex = 202,
}, miniHeader)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, miniMinBtn)

local miniCloseBtn = newInst("TextButton", {
    Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -26, 0.5, -11),
    BackgroundColor3 = T.BG_ELEMENT, BorderSizePixel = 0,
    Text = "✕", TextColor3 = T.TEXT, TextSize = 12,
    Font = Enum.Font.GothamBold, AutoButtonColor = false, Active = true, ZIndex = 202,
}, miniHeader)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, miniCloseBtn)

local miniBody = newInst("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -miniHeaderH), Position = UDim2.new(0, 0, 0, miniHeaderH),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = T.PURPLE,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 201,
}, miniUI)
newInst("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, miniBody)
newInst("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, miniBody)

local arRow = newInst("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.BG_ELEMENT, BorderSizePixel = 0, ZIndex = 202 }, miniBody)
arRow.LayoutOrder = 1
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, arRow)
applyGradientStroke(arRow, 1, 8)
newInst("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1, Text = "🛡 AUTO-REWIND",
    TextColor3 = T.CYAN, TextSize = 11, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 203,
}, arRow)
local arToggle = newInst("TextButton", {
    Size = UDim2.new(0, 48, 0, 24), Position = UDim2.new(1, -56, 0.5, -12),
    BackgroundColor3 = T.PURPLE, BorderSizePixel = 0, Text = "",
    AutoButtonColor = false, Active = true, ZIndex = 204,
}, arRow)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, arToggle)
local arKnob = newInst("Frame", {
    Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -21, 0.5, -9),
    BackgroundColor3 = T.WHITE, BorderSizePixel = 0, ZIndex = 205,
}, arToggle)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, arKnob)

local trailRow = newInst("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.BG_ELEMENT, BorderSizePixel = 0, ZIndex = 202 }, miniBody)
trailRow.LayoutOrder = 2
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, trailRow)
applyGradientStroke(trailRow, 1, 8)
newInst("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1, Text = "✨ SHOW TRAIL",
    TextColor3 = T.PURPLE_LIGHT, TextSize = 11, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 203,
}, trailRow)
local trailToggle = newInst("TextButton", {
    Size = UDim2.new(0, 48, 0, 24), Position = UDim2.new(1, -56, 0.5, -12),
    BackgroundColor3 = T.PURPLE, BorderSizePixel = 0, Text = "",
    AutoButtonColor = false, Active = true, ZIndex = 204,
}, trailRow)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, trailToggle)
local trailKnob = newInst("Frame", {
    Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -21, 0.5, -9),
    BackgroundColor3 = T.WHITE, BorderSizePixel = 0, ZIndex = 205,
}, trailToggle)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, trailKnob)

local recRow = newInst("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.BG_ELEMENT, BorderSizePixel = 0, ZIndex = 202 }, miniBody)
recRow.LayoutOrder = 3
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, recRow)
newInst("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1, Text = "RECORD", TextColor3 = T.WHITE,
    TextSize = 12, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 203,
}, recRow)
local recToggle = newInst("TextButton", {
    Size = UDim2.new(0, 48, 0, 24), Position = UDim2.new(1, -56, 0.5, -12),
    BackgroundColor3 = T.BG_ELEMENT2, BorderSizePixel = 0, Text = "",
    AutoButtonColor = false, Active = true, ZIndex = 204,
}, recRow)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, recToggle)
local recKnob = newInst("Frame", {
    Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 3, 0.5, -9),
    BackgroundColor3 = T.WHITE, BorderSizePixel = 0, ZIndex = 205,
}, recToggle)
newInst("UICorner", { CornerRadius = UDim.new(1, 0) }, recKnob)

local statsLabel = newInst("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
    Text = "0.0 studs  •  0.00 s  •  0 pts  •  spd 0",
    TextColor3 = T.TEXT_DIM, TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202,
}, miniBody)
statsLabel.LayoutOrder = 4

local backBtn = newInst("TextButton", {
    Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.BG_ELEMENT,
    BorderSizePixel = 0, Text = "⏪  BACK 2 SECONDS",
    TextColor3 = T.WHITE, TextSize = 11, Font = Enum.Font.GothamBold,
    AutoButtonColor = false, Active = true, ZIndex = 202,
}, miniBody)
backBtn.LayoutOrder = 5
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, backBtn)
applyGradientStroke(backBtn, 1, 8)

local cpSection = newInst("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, ZIndex = 202 }, miniBody)
cpSection.LayoutOrder = 6
newInst("TextLabel", {
    Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1,
    Text = "📍 CHECKPOINTS", TextColor3 = T.GOLD,
    TextSize = 10, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 203,
}, cpSection)
local cpCountLabel = newInst("TextLabel", {
    Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0),
    BackgroundTransparency = 1, Text = "0 CP",
    TextColor3 = T.TEXT_DIM, TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 203,
}, cpSection)

local cpScroll = newInst("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = T.BG_DARK,
    BackgroundTransparency = 0.5, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = T.PURPLE,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 202,
}, miniBody)
cpScroll.LayoutOrder = 7
newInst("UICorner", { CornerRadius = UDim.new(0, 6) }, cpScroll)
applyGradientStroke(cpScroll, 1, 6)
newInst("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, cpScroll)
newInst("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, cpScroll)

local cpActionRow = newInst("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 202 }, miniBody)
cpActionRow.LayoutOrder = 8
local setCpBtn = newInst("TextButton", {
    Size = UDim2.new(0.49, 0, 1, 0), BackgroundColor3 = T.BG_ELEMENT,
    BorderSizePixel = 0, Text = "📍 SET CP",
    TextColor3 = T.GOLD, TextSize = 11, Font = Enum.Font.GothamBold,
    AutoButtonColor = false, Active = true, ZIndex = 203,
}, cpActionRow)
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, setCpBtn)
applyGradientStroke(setCpBtn, 1, 8)

local combineCpBtn = newInst("TextButton", {
    Size = UDim2.new(0.49, 0, 1, 0), Position = UDim2.new(0.51, 0, 0, 0),
    BackgroundColor3 = T.PURPLE, BorderSizePixel = 0,
    Text = "🔗 COMBINE", TextColor3 = T.WHITE,
    TextSize = 11, Font = Enum.Font.GothamBold,
    AutoButtonColor = false, Active = true, ZIndex = 203,
}, cpActionRow)
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, combineCpBtn)
applyGradientStroke(combineCpBtn, 1, 8)

local saveClearRow = newInst("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 202 }, miniBody)
saveClearRow.LayoutOrder = 9
local saveWalkBtn = newInst("TextButton", {
    Size = UDim2.new(0.49, 0, 1, 0), BackgroundColor3 = T.PURPLE_DARK,
    BorderSizePixel = 0, Text = "💾 SAVE WALK",
    TextColor3 = T.WHITE, TextSize = 11, Font = Enum.Font.GothamBold,
    AutoButtonColor = false, Active = true, ZIndex = 203,
}, saveClearRow)
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, saveWalkBtn)
applyGradientStroke(saveWalkBtn, 1, 8)

local clearWalkBtn = newInst("TextButton", {
    Size = UDim2.new(0.49, 0, 1, 0), Position = UDim2.new(0.51, 0, 0, 0),
    BackgroundColor3 = T.BG_ELEMENT, BorderSizePixel = 0,
    Text = "🗑 CLEAR", TextColor3 = T.RED,
    TextSize = 11, Font = Enum.Font.GothamBold,
    AutoButtonColor = false, Active = true, ZIndex = 203,
}, saveClearRow)
newInst("UICorner", { CornerRadius = UDim.new(0, 8) }, clearWalkBtn)
applyGradientStroke(clearWalkBtn, 1, 8)

local nameInput = newInst("TextBox", {
    Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.BG_ELEMENT,
    BorderSizePixel = 0, Text = "", PlaceholderText = "Nama walk...",
    TextColor3 = T.TEXT, PlaceholderColor3 = T.TEXT_DIM,
    TextSize = 11, Font = Enum.Font.Gotham,
    ClearTextOnFocus = false, Visible = false, ZIndex = 203,
}, miniBody)
nameInput.LayoutOrder = 10
newInst("UICorner", { CornerRadius = UDim.new(0, 6) }, nameInput)
applyGradientStroke(nameInput, 1, 6)

local confirmSaveBtn = newInst("TextButton", {
    Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.PURPLE,
    BorderSizePixel = 0, Text = "CONFIRM SAVE",
    TextColor3 = T.WHITE, TextSize = 11, Font = Enum.Font.GothamBold,
    AutoButtonColor = false, Visible = false, Active = true, ZIndex = 203,
}, miniBody)
confirmSaveBtn.LayoutOrder = 11
newInst("UICorner", { CornerRadius = UDim.new(0, 6) }, confirmSaveBtn)
applyGradientStroke(confirmSaveBtn, 1, 6)

local countdownLabel = newInst("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = T.BLACK,
    BackgroundTransparency = 0.5, Text = "", TextColor3 = T.WHITE,
    TextSize = 80, Font = Enum.Font.GothamBlack, Visible = false, ZIndex = 300,
}, miniUI)
newInst("UICorner", { CornerRadius = UDim.new(0, 12) }, countdownLabel)

-- ================================================================
-- SPEED SLIDER
-- ================================================================
local function updateSliderVisual(mult)
    mult = math.clamp(mult, CONFIG.MIN_MULT, CONFIG.MAX_MULT)
    STATE.speedMultiplier = mult
    local range = CONFIG.MAX_MULT - CONFIG.MIN_MULT
    local alpha = (mult - CONFIG.MIN_MULT) / range
    sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
    sliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
    speedValLabel.Text = "×" .. mult
end

local function updateSliderFromInput(inputX)
    local trackAbs = sliderTrack.AbsolutePosition.X
    local trackW = sliderTrack.AbsoluteSize.X
    if trackW <= 0 then return end
    local alpha = math.clamp((inputX - trackAbs) / trackW, 0, 1)
    local mult = math.floor(CONFIG.MIN_MULT + alpha * (CONFIG.MAX_MULT - CONFIG.MIN_MULT) + 0.5)
    updateSliderVisual(mult)
end

updateSliderVisual(CONFIG.DEFAULT_MULT)

local draggingSlider = false
sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateSliderFromInput(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        updateSliderFromInput(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if draggingSlider then draggingSlider = false; saveConfig(true) end
    end
end)

-- ================================================================
-- SIDEBAR SWITCH
-- ================================================================
local function switchPage(id)
    STATE.currentPage = id
    pageMain.Visible = (id == "MAIN")
    pageInfo.Visible = (id == "INFO")
    tween(btnMain, 0.15, { BackgroundColor3 = (id == "MAIN") and T.PURPLE_DARK or T.BG_ELEMENT })
    tween(btnInfo, 0.15, { BackgroundColor3 = (id == "INFO") and T.PURPLE_DARK or T.BG_ELEMENT })
end
switchPage("MAIN")
btnMain.Activated:Connect(function() playClick(); switchPage("MAIN") end)
btnInfo.Activated:Connect(function() playClick(); switchPage("INFO") end)

-- ================================================================
-- CONTROLS
-- ================================================================
local function getControls()
    if STATE.controlsRef then return STATE.controlsRef end
    local ok, controls = pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        if not ps then return nil end
        local pm = ps:FindFirstChild("PlayerModule")
        if not pm then return nil end
        local mod = require(pm)
        return mod:GetControls()
    end)
    if ok and controls then STATE.controlsRef = controls; return controls end
    return nil
end
local function disableControls()
    local c = getControls(); if c then pcall(function() c:Disable() end) end
end
local function enableControls()
    local c = getControls(); if c then pcall(function() c:Enable() end) end
end

-- ================================================================
-- HELPERS
-- ================================================================
local function getChar() return LocalPlayer.Character end
local function getRoot()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function normalizeState(s)
    if not s then return "Running" end
    return tostring(s):gsub("Enum%.HumanoidStateType%.", "")
end
local function shortestAngle(from, to)
    local diff = to - from
    while diff > math.pi do diff = diff - math.pi * 2 end
    while diff < -math.pi do diff = diff + math.pi * 2 end
    return diff
end

-- ================================================================
-- AUTO-REWIND
-- ================================================================
local rewindBusy = false
local function findHistoryAt(targetT)
    for i = #STATE.history, 1, -1 do
        if STATE.history[i].t <= targetT then return STATE.history[i] end
    end
    return nil
end

local function doRewind(reason)
    if rewindBusy then return end
    if (tick() - STATE.lastRewindTime) < CONFIG.REWIND_COOLDOWN then return end
    rewindBusy = true
    STATE.lastRewindTime = tick()
    local root = getRoot()
    if not root then rewindBusy = false; return end
    local target = findHistoryAt(tick() - CONFIG.BACK_SECONDS)
    if not target then
        notify("⚠ Tidak ada riwayat untuk rewind", T.RED)
        rewindBusy = false; return
    end
    if STATE.trail then STATE.trail.Enabled = false end
    root.CFrame = CFrame.new(target.pos + Vector3.new(0, 2, 0)) * CFrame.Angles(0, target.rot, 0)
    pcall(function() root.AssemblyLinearVelocity = Vector3.zero end)
    STATE.history = { { t = tick(), pos = target.pos, rot = target.rot } }
    notify("🛡 " .. (reason or "Auto-Rewind"), T.CYAN)
    task.delay(0.15, function()
        if STATE.trail then pcall(function() STATE.trail.Enabled = true end) end
    end)
    task.delay(0.8, function() rewindBusy = false end)
end

local lastPos = nil
local steppedConn = RunService.Stepped:Connect(function()
    if not STATE.autoRewindEnabled or STATE.playing.active or STATE.recording.active or rewindBusy then
        lastPos = nil; return
    end
    local root = getRoot()
    if not root then lastPos = nil; return end
    local curPos = root.Position
    table.insert(STATE.history, { t = tick(), pos = curPos, rot = 0 })
    while #STATE.history > 0 and tick() - STATE.history[1].t > CONFIG.HISTORY_BUFFER do
        table.remove(STATE.history, 1)
    end
    if lastPos then
        local delta = (curPos - lastPos).Magnitude
        if delta > CONFIG.TELEPORT_JUMP_DETECT then
            doRewind("Auto-Rewind (teleport terdeteksi)")
        end
    end
    lastPos = curPos
end)

local function updateARToggleVisual()
    if STATE.autoRewindEnabled then
        tween(arKnob, 0.2, { Position = UDim2.new(1, -21, 0.5, -9) })
        tween(arToggle, 0.2, { BackgroundColor3 = T.PURPLE })
    else
        tween(arKnob, 0.2, { Position = UDim2.new(0, 3, 0.5, -9) })
        tween(arToggle, 0.2, { BackgroundColor3 = T.BG_ELEMENT2 })
    end
end
arToggle.Activated:Connect(function()
    playClick()
    STATE.autoRewindEnabled = not STATE.autoRewindEnabled
    updateARToggleVisual()
    notify(STATE.autoRewindEnabled and "🛡 Auto-Rewind ON" or "🛡 Auto-Rewind OFF",
           STATE.autoRewindEnabled and T.CYAN or T.TEXT_DIM)
end)
updateARToggleVisual()

local function updateTrailToggleVisual()
    if STATE.trailEnabled then
        tween(trailKnob, 0.2, { Position = UDim2.new(1, -21, 0.5, -9) })
        tween(trailToggle, 0.2, { BackgroundColor3 = T.PURPLE })
    else
        tween(trailKnob, 0.2, { Position = UDim2.new(0, 3, 0.5, -9) })
        tween(trailToggle, 0.2, { BackgroundColor3 = T.BG_ELEMENT2 })
    end
end
trailToggle.Activated:Connect(function()
    playClick()
    STATE.trailEnabled = not STATE.trailEnabled
    updateTrailToggleVisual()
    notify(STATE.trailEnabled and "✨ Trail ON" or "✨ Trail OFF",
           STATE.trailEnabled and T.PURPLE_LIGHT or T.TEXT_DIM)
end)
updateTrailToggleVisual()

-- ================================================================
-- RECORD
-- ================================================================
local function startRecording()
    if STATE.recording.active then return end
    STATE.recording.active = true
    STATE.recording.points = {}
    STATE.recording.startTime = tick()
    STATE.recording.prevPos = nil
    STATE.recording.prevTime = tick()
    STATE.recording.speedBuf = {}

    if STATE.trailEnabled then createTrail() end

    STATE.recording.conn = RunService.Heartbeat:Connect(function(dt)
        if not STATE.recording.active then return end
        local root, hum = getRoot(), getHum()
        if not root or not hum then return end

        local now = tick()
        local nowRel = now - STATE.recording.startTime
        local last = STATE.recording.points[#STATE.recording.points]
        if last and (nowRel - last.time) < CONFIG.RECORD_INTERVAL then return end

        local actualSpeed = 0
        if STATE.recording.prevPos then
            local dtReal = now - STATE.recording.prevTime
            if dtReal > 0.001 then
                local dist = (root.Position - STATE.recording.prevPos).Magnitude
                actualSpeed = dist / dtReal
            end
        end
        STATE.recording.prevPos = root.Position
        STATE.recording.prevTime = now

        if actualSpeed > 0 then
            table.insert(STATE.recording.speedBuf, actualSpeed)
            if #STATE.recording.speedBuf > CONFIG.SPEED_SMOOTH_SAMPLES then
                table.remove(STATE.recording.speedBuf, 1)
            end
        end
        local smoothSpeed = 0
        if #STATE.recording.speedBuf > 0 then
            local sum = 0
            for _, v in ipairs(STATE.recording.speedBuf) do sum = sum + v end
            smoothSpeed = sum / #STATE.recording.speedBuf
        end

        local inputSpeed = hum.WalkSpeed
        local finalSpeed
        if smoothSpeed > 1 then
            finalSpeed = smoothSpeed
        else
            finalSpeed = inputSpeed
        end
        finalSpeed = math.clamp(finalSpeed, 1, 300)

        local _, yRot = root.CFrame:ToOrientation()
        local st = hum:GetState()
        local stName = "Running"
        if st == Enum.HumanoidStateType.Jumping then stName = "Jumping"
        elseif st == Enum.HumanoidStateType.Freefall then stName = "Freefall"
        elseif st == Enum.HumanoidStateType.Climbing then stName = "Climbing"
        elseif st == Enum.HumanoidStateType.Swimming then stName = "Swimming" end

        table.insert(STATE.recording.points, {
            pos = root.Position, rot = yRot, time = nowRel,
            speed = finalSpeed, state = stName,
        })

        local totalDist = 0
        for i = 2, #STATE.recording.points do
            totalDist = totalDist + (STATE.recording.points[i].pos - STATE.recording.points[i - 1].pos).Magnitude
        end
        statsLabel.Text = string.format("%.1f studs  •  %.2f s  •  %d pts  •  spd %.1f",
            totalDist, nowRel, #STATE.recording.points, finalSpeed)
    end)

    notify("🔴 Recording dimulai", T.GREEN)
end

local function stopRecording()
    if not STATE.recording.active then return end
    STATE.recording.active = false
    if STATE.recording.conn then STATE.recording.conn:Disconnect(); STATE.recording.conn = nil end
    STATE.currentRecording = STATE.recording.points
    task.spawn(function()
        if STATE.trail then
            pcall(function() tween(STATE.trail, 1.2, { Transparency = NumberSequence.new(1) }) end)
            task.wait(1.3)
        end
        destroyTrail()
    end)
    notify("⏹ Recording dihentikan (" .. #STATE.recording.points .. " titik)", T.TEXT)
end

local recToggleState = false
recToggle.Activated:Connect(function()
    recToggleState = not recToggleState
    playClick()
    if recToggleState then
        tween(recKnob, 0.2, { Position = UDim2.new(1, -21, 0.5, -9) })
        tween(recToggle, 0.2, { BackgroundColor3 = T.PURPLE })
        startRecording()
    else
        tween(recKnob, 0.2, { Position = UDim2.new(0, 3, 0.5, -9) })
        tween(recToggle, 0.2, { BackgroundColor3 = T.BG_ELEMENT2 })
        stopRecording()
    end
end)

-- ================================================================
-- ★★★ PLAYBACK v10.5 PRECISION — 100% EXACT PATH ★★★
-- ================================================================
local function stopPlayback()
    if STATE.playing.conn then STATE.playing.conn:Disconnect(); STATE.playing.conn = nil end
    STATE.playing.active = false
    STATE.currentPlayingId = nil
    local h = getHum()
    if h then
        h:Move(Vector3.zero, false)
        h.AutoRotate = true
        h.WalkSpeed = CONFIG.DEFAULT_SPEED
    end
    local r = getRoot()
    if r then
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
    end
    enableControls()
    destroyTrail()
end

local function playWalk(points, id)
    if not points or #points < 2 then notify("❌ Tidak ada data walk", T.RED); return end
    local char = getChar()
    if not char then notify("❌ Character belum siap", T.RED); return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
    if not root or not hum then notify("❌ Humanoid tidak ditemukan", T.RED); return end

    stopPlayback()
    destroyTrail()

    -- Teleport ke waypoint pertama kalau jauh
    local first = points[1]
    if (root.Position - first.pos).Magnitude > CONFIG.TELEPORT_THRESHOLD then
        root.CFrame = CFrame.new(first.pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, first.rot, 0)
        task.wait(0.3)
        hum = getHum(); root = getRoot()
        if not hum or not root then return end
    end

    -- ★ SETUP HUMANOID
    hum.AutoRotate = false
    hum.PlatformStand = false
    hum.Sit = false
    hum.UseJumpPower = true
    if hum.JumpPower < 40 then hum.JumpPower = 50 end
    hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)

    disableControls()
    STATE.playing.active = true
    STATE.currentPlayingId = id

    local progress = 0
    local totalTime = points[#points].time
    local multiplier = STATE.speedMultiplier
    local lastJumpTime = 0
    local lastJumpIdx = 0
    local lastProgressTime = tick()
    local lastProgressPos = root.Position

    log("Playback v10.5 PRECISION: " .. #points .. " waypoints, duration=" .. string.format("%.2f", totalTime) .. "s, multiplier=×" .. multiplier)

    STATE.playing.conn = RunService.Stepped:Connect(function(_, dt)
        if not STATE.playing.active then return end
        if dt <= 0 or dt > 1 then return end

        local r = getRoot()
        local h = getHum()
        if not r or not h then stopPlayback(); return end

        -- ★ PROGRESS dengan speed boost
        progress = progress + dt * multiplier
        if progress >= totalTime then
            stopPlayback()
            refreshSavedList()
            notify("✅ AutoWalk selesai", T.GREEN)
            return
        end

        -- ★ FIND EXACT INTERPOLATION POINT
        local idx = 1
        for i = 1, #points do
            if points[i].time >= progress then idx = i; break end
        end
        if idx >= #points then idx = #points - 1 end

        local p1 = points[idx]
        local p2 = points[idx + 1] or p1

        -- ★ INTERPOLASI PRESISI
        local segDur = p2.time - p1.time
        local rawAlpha = segDur > 0 and ((progress - p1.time) / segDur) or 0
        rawAlpha = math.clamp(rawAlpha, 0, 1)

        -- Smoothstep untuk smooth motion
        local alpha = rawAlpha * rawAlpha * (3 - 2 * rawAlpha)

        local targetPos = p1.pos:Lerp(p2.pos, alpha)
        local targetRot = p1.rot + shortestAngle(p1.rot, p2.rot) * alpha

        -- ★ APPLY POSITION (CFrame dengan smooth lerp)
        local targetCF = CFrame.new(targetPos) * CFrame.Angles(0, targetRot, 0)
        r.CFrame = r.CFrame:Lerp(targetCF, CONFIG.CFRAME_LERP_ALPHA)

        -- ★ RESET VELOCITY
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero

        -- ★ ANIMATION: Set WalkSpeed berdasarkan recorded speed
        local recSpeed = (p1.speed and p1.speed > 0) and p1.speed or CONFIG.DEFAULT_SPEED
        local animSpeed = math.clamp(recSpeed * multiplier, CONFIG.WALK_SPEED_MIN, CONFIG.RUN_SPEED_MAX)

        if math.abs(h.WalkSpeed - animSpeed) > 1 then
            h.WalkSpeed = animSpeed
        end

        -- ★ STEERING via Humanoid:Move (untuk animasi berjalan)
        local dirToTarget = targetPos - r.Position
        local flatDir = Vector3.new(dirToTarget.X, 0, dirToTarget.Z)

        if flatDir.Magnitude > 0.2 then
            h:Move(flatDir.Unit, false)
        else
            h:Move(Vector3.zero, false)
        end

        -- ★ JUMP DETECTION & TRIGGER
        for i = math.max(idx, lastJumpIdx), math.min(idx + 2, #points) do
            local st = normalizeState(points[i].state)
            if st == "Jumping" then
                if (tick() - lastJumpTime) > 0.3 then
                    local cs = h:GetState()
                    local canJump = (cs == Enum.HumanoidStateType.Running)
                                 or (cs == Enum.HumanoidStateType.Landed)
                                 or (cs == Enum.HumanoidStateType.Idle)
                    if canJump then
                        h.Jump = true
                        lastJumpTime = tick()
                        lastJumpIdx = i
                    end
                end
                break
            end
        end

        -- ★ STUCK DETECTION
        if (r.Position - lastProgressPos).Magnitude > 0.5 then
            lastProgressTime = tick()
            lastProgressPos = r.Position
        elseif (tick() - lastProgressTime) > 6 then
            stopPlayback()
            notify("⚠ Playback stuck", T.RED)
        end
    end)
end

-- ================================================================
-- BACK 2 SECONDS
-- ================================================================
local function showCountdown(callback)
    countdownLabel.Visible = true
    countdownLabel.TextTransparency = 1
    for _, n in ipairs({ 3, 2, 1 }) do
        countdownLabel.Text = tostring(n)
        countdownLabel.TextTransparency = 0
        countdownLabel.TextSize = 120
        tween(countdownLabel, 0.4, { TextSize = 80 })
        task.wait(0.7)
    end
    countdownLabel.Visible = false
    if callback then callback() end
end

backBtn.Activated:Connect(function()
    playClick()
    local target = findHistoryAt(tick() - CONFIG.BACK_SECONDS)
    if not target then notify("❌ Riwayat belum cukup", T.RED); return end
    local root = getRoot()
    if not root then return end
    if STATE.trail then STATE.trail.Enabled = false end
    root.CFrame = CFrame.new(target.pos) * CFrame.Angles(0, target.rot, 0)
    notify("⏪ Kembali 2 detik", T.PURPLE_LIGHT)
    task.delay(0.15, function()
        if STATE.trail then pcall(function() STATE.trail.Enabled = true end) end
    end)
    local hum = getHum()
    if hum then
        hum.WalkSpeed = 0
        showCountdown(function() if hum then hum.WalkSpeed = CONFIG.DEFAULT_SPEED end end)
    else showCountdown(nil) end
end)

clearWalkBtn.Activated:Connect(function()
    playClick()
    STATE.recording.points = {}
    STATE.currentRecording = {}
    statsLabel.Text = "0.0 studs  •  0.00 s  •  0 pts  •  spd 0"
    destroyTrail()
    notify("🗑 Recording dibersihkan", T.RED)
end)

-- ================================================================
-- SAVE / LOAD
-- ================================================================
local function compressPoint(p)
    local out = {
        p = { math.floor(p.pos.X * 100) / 100, math.floor(p.pos.Y * 100) / 100, math.floor(p.pos.Z * 100) / 100 },
        r = math.floor((p.rot or 0) * 1000) / 1000,
        t = math.floor((p.time or 0) * 100) / 100,
    }
    if p.speed and math.abs(p.speed - CONFIG.DEFAULT_SPEED) > 0.5 then out.s = math.floor(p.speed * 10) / 10 end
    if p.state and p.state ~= "Running" then out.st = p.state end
    return out
end

local function decompressPoint(c)
    return {
        pos = Vector3.new(c.p[1], c.p[2], c.p[3]),
        rot = c.r or 0, time = c.t or 0,
        speed = c.s or CONFIG.DEFAULT_SPEED,
        state = c.st or "Running",
    }
end

local saveCooldown = false
local function saveConfig(silent)
    if saveCooldown then return end
    saveCooldown = true
    task.delay(0.5, function() saveCooldown = false end)
    local walksData = {}
    for _, w in ipairs(STATE.savedWalks) do
        local pts = {}
        for _, p in ipairs(w.points or {}) do table.insert(pts, compressPoint(p)) end
        table.insert(walksData, { n = w.name, pts = pts })
    end
    local data = {
        walks = walksData,
        multiplier = STATE.speedMultiplier,
        autoRewind = STATE.autoRewindEnabled,
        trailEnabled = STATE.trailEnabled,
    }
    pcall(function()
        if typeof(writefile) == "function" then
            writefile(CONFIG.FILE_NAME, HttpService:JSONEncode(data))
        end
    end)
end

local function loadConfig()
    if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then return end
    local ok, content = pcall(function()
        if isfile(CONFIG.FILE_NAME) then return readfile(CONFIG.FILE_NAME) end
    end)
    if not ok or not content or content == "" then return end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, content)
    if not ok2 or typeof(data) ~= "table" then return end
    if data.walks then
        STATE.savedWalks = {}
        for _, w in ipairs(data.walks) do
            local points = {}
            for _, cp in ipairs(w.pts or {}) do
                if cp.p and typeof(cp.p) == "table" then
                    table.insert(points, decompressPoint(cp))
                elseif cp.pos then
                    local pos = cp.pos
                    if typeof(pos) == "table" and pos.x then pos = Vector3.new(pos.x, pos.y, pos.z) end
                    table.insert(points, { pos = pos, rot = cp.rot or 0, time = cp.time or 0,
                        speed = cp.speed or CONFIG.DEFAULT_SPEED, state = normalizeState(cp.state) })
                end
            end
            table.insert(STATE.savedWalks, { name = w.n or w.name or "Walk", points = points, speed = w.speed or CONFIG.DEFAULT_SPEED })
        end
        notify("📂 " .. #STATE.savedWalks .. " walk dimuat", T.GREEN)
    end
    local mult = data.multiplier or data.speed
    if mult then
        mult = math.clamp(math.floor(mult + 0.5), CONFIG.MIN_MULT, CONFIG.MAX_MULT)
        updateSliderVisual(mult)
    end
    if data.autoRewind ~= nil then
        STATE.autoRewindEnabled = data.autoRewind
        updateARToggleVisual()
    end
    if data.trailEnabled ~= nil then
        STATE.trailEnabled = data.trailEnabled
        updateTrailToggleVisual()
    end
end

-- ================================================================
-- SAVED WALK LIST
-- ================================================================
local refreshSavedList
refreshSavedList = function()
    for _, c in ipairs(savedScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    if #STATE.savedWalks == 0 then
        local empty = newInst("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
            Text = "Belum ada walk tersimpan.", TextColor3 = T.TEXT_DIM,
            TextSize = 12, Font = Enum.Font.Gotham, ZIndex = 54,
        }, savedScroll)
        empty.LayoutOrder = 1; return
    end
    for i, w in ipairs(STATE.savedWalks) do
        local entry = newInst("Frame", {
            Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.BG_ELEMENT2,
            BorderSizePixel = 0, ZIndex = 54,
        }, savedScroll)
        newInst("UICorner", { CornerRadius = UDim.new(0, 6) }, entry)
        entry.LayoutOrder = i
        newInst("TextLabel", {
            Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1, Text = w.name or ("Walk " .. i),
            TextColor3 = T.TEXT, TextSize = 12, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 55,
        }, entry)
        local isPlaying = (STATE.currentPlayingId == w.name)
        local playB = newInst("TextButton", {
            Size = UDim2.new(0, 66, 0, 26), Position = UDim2.new(1, -106, 0.5, -13),
            BackgroundColor3 = isPlaying and T.RED or T.PURPLE_DARK, BorderSizePixel = 0,
            Text = isPlaying and "⏹ STOP" or "▶ PLAY", TextColor3 = T.WHITE,
            TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false,
            Active = true, ZIndex = 55,
        }, entry)
        newInst("UICorner", { CornerRadius = UDim.new(0, 6) }, playB)
        applyGradientStroke(playB, 1, 6)
        local delB = newInst("TextButton", {
            Size = UDim2.new(0, 32, 0, 26), Position = UDim2.new(1, -36, 0.5, -13),
            BackgroundColor3 = T.BG_ELEMENT, BorderSizePixel = 0,
            Text = "🗑", TextColor3 = T.RED, TextSize = 12,
            Font = Enum.Font.GothamBold, AutoButtonColor = false, Active = true, ZIndex = 55,
        }, entry)
        newInst("UICorner", { CornerRadius = UDim.new(0, 6) }, delB)
        applyGradientStroke(delB, 1, 6)
        playB.Activated:Connect(function()
            playClick()
            if STATE.currentPlayingId == w.name and STATE.playing.active then
                stopPlayback(); refreshSavedList()
                notify("⏹ Walk dihentikan", T.TEXT)
            else
                stopPlayback()
                playWalk(w.points, w.name)
                refreshSavedList()
                notify("▶ Memutar: " .. (w.name or "Walk"), T.PURPLE_LIGHT)
            end
        end)
        delB.Activated:Connect(function()
            playClick()
            if STATE.currentPlayingId == w.name then stopPlayback() end
            table.remove(STATE.savedWalks, i)
            refreshSavedList(); saveConfig(true)
            notify("🗑 Walk dihapus", T.RED)
        end)
    end
end

-- ================================================================
-- CHECKPOINT
-- ================================================================
local refreshCpList
refreshCpList = function()
    for _, c in ipairs(cpScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    cpCountLabel.Text = #STATE.checkpoints .. " CP"
    if #STATE.checkpoints == 0 then
        local empty = newInst("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
            Text = "Belum ada CP. Rekam lalu SET CP.",
            TextColor3 = T.TEXT_DIM, TextSize = 9, Font = Enum.Font.Gotham, ZIndex = 203,
        }, cpScroll)
        empty.LayoutOrder = 1; return
    end
    for i, cp in ipairs(STATE.checkpoints) do
        local entry = newInst("Frame", {
            Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = T.BG_ELEMENT2,
            BorderSizePixel = 0, ZIndex = 203,
        }, cpScroll)
        newInst("UICorner", { CornerRadius = UDim.new(0, 4) }, entry)
        entry.LayoutOrder = i
        newInst("TextLabel", {
            Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1, Text = cp.name .. "  (" .. #cp.points .. " pts)",
            TextColor3 = T.GOLD, TextSize = 10, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 204,
        }, entry)
        local delCp = newInst("TextButton", {
            Size = UDim2.new(0, 22, 0, 18), Position = UDim2.new(1, -24, 0.5, -9),
            BackgroundColor3 = T.BG_ELEMENT, BorderSizePixel = 0,
            Text = "✕", TextColor3 = T.RED, TextSize = 10,
            Font = Enum.Font.GothamBold, AutoButtonColor = false, Active = true, ZIndex = 204,
        }, entry)
        newInst("UICorner", { CornerRadius = UDim.new(0, 4) }, delCp)
        delCp.Activated:Connect(function()
            playClick()
            table.remove(STATE.checkpoints, i)
            refreshCpList()
            notify("🗑 CP dihapus", T.RED)
        end)
    end
end

setCpBtn.Activated:Connect(function()
    playClick()
    local pts = STATE.recording.points
    if #pts < 2 then notify("❌ Belum ada rekaman untuk dijadikan CP", T.RED); return end
    local cpName = "CP" .. (#STATE.checkpoints + 1)
    table.insert(STATE.checkpoints, { name = cpName, points = pts })
    refreshCpList()
    STATE.recording.points = {}
    STATE.currentRecording = {}
    statsLabel.Text = "0.0 studs  •  0.00 s  •  0 pts  •  spd 0"
    destroyTrail()
    if recToggleState then
        recToggleState = false
        tween(recKnob, 0.2, { Position = UDim2.new(0, 3, 0.5, -9) })
        tween(recToggle, 0.2, { BackgroundColor3 = T.BG_ELEMENT2 })
        if STATE.recording.active then
            STATE.recording.active = false
            if STATE.recording.conn then STATE.recording.conn:Disconnect(); STATE.recording.conn = nil end
        end
    end
    notify("📍 " .. cpName .. " disimpan (" .. #pts .. " pts)", T.GOLD)
end)

local pendingAction = nil
combineCpBtn.Activated:Connect(function()
    playClick()
    if #STATE.checkpoints == 0 then notify("❌ Belum ada checkpoint", T.RED); return end
    pendingAction = "combine"
    nameInput.Text = ""
    nameInput.Visible = true
    confirmSaveBtn.Visible = true
    notify("✏ Masukkan nama walk combined", T.PURPLE_LIGHT)
end)

saveWalkBtn.Activated:Connect(function()
    playClick()
    local pts = STATE.recording.points
    if #pts < 2 then notify("❌ Belum ada rekaman", T.RED); return end
    pendingAction = "saveCurrent"
    nameInput.Text = ""
    nameInput.Visible = true
    confirmSaveBtn.Visible = true
end)

confirmSaveBtn.Activated:Connect(function()
    playClick()
    local name = nameInput.Text
    if name == "" or name == nil then name = "Walk " .. (#STATE.savedWalks + 1) end
    if pendingAction == "combine" then
        local combined = {}
        local timeOffset = 0
        for _, cp in ipairs(STATE.checkpoints) do
            local cpLastT = 0
            for _, p in ipairs(cp.points) do
                table.insert(combined, { pos = p.pos, rot = p.rot, time = p.time + timeOffset, speed = p.speed, state = p.state })
                cpLastT = math.max(cpLastT, p.time)
            end
            timeOffset = timeOffset + cpLastT
        end
        if #combined < 2 then
            notify("❌ Combine gagal", T.RED)
            nameInput.Visible = false
            confirmSaveBtn.Visible = false
            pendingAction = nil
            return
        end
        table.insert(STATE.savedWalks, { name = name, points = combined, speed = STATE.speedMultiplier })
        notify("🔗 Combined (" .. #STATE.checkpoints .. " CP → " .. #combined .. " pts)", T.GREEN)
        STATE.checkpoints = {}
        refreshCpList()
    else
        local pts = STATE.recording.points
        if #pts < 2 then
            notify("❌ Belum ada rekaman", T.RED)
            nameInput.Visible = false
            confirmSaveBtn.Visible = false
            pendingAction = nil
            return
        end
        table.insert(STATE.savedWalks, { name = name, points = pts, speed = STATE.speedMultiplier })
        notify("💾 Walk tersimpan: " .. name, T.GREEN)
    end
    refreshSavedList()
    saveConfig(true)
    nameInput.Visible = false
    confirmSaveBtn.Visible = false
    pendingAction = nil
end)

-- ================================================================
-- MINI UI CONTROLS
-- ================================================================
local miniMinimized = false
local miniFullSize = UDim2.new(0, MINI_W, 0, MINI_H)
local miniMinSize  = UDim2.new(0, MINI_W, 0, 32)

local function openMini()
    STATE.miniOpen = true
    miniUI.Visible = true
    miniUI.Size = UDim2.new(0, MINI_W * 0.9, 0, MINI_H * 0.9)
    miniUI.BackgroundTransparency = 1
    tween(miniUI, 0.3, { Size = miniFullSize, BackgroundTransparency = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function closeMini()
    STATE.miniOpen = false
    local tw = tween(miniUI, 0.22, {
        Size = UDim2.new(0, MINI_W * 0.85, 0, MINI_H * 0.85),
        BackgroundTransparency = 1,
    }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    tw.Completed:Connect(function()
        miniUI.Visible = false
        miniUI.BackgroundTransparency = 0
        miniMinimized = false
        miniUI.Size = miniFullSize
        miniBody.Visible = true
    end)
end

execBtn.Activated:Connect(function()
    playClick()
    if STATE.miniOpen then closeMini() else openMini() end
end)
miniCloseBtn.Activated:Connect(function() playClick(); closeMini() end)
miniMinBtn.Activated:Connect(function()
    playClick()
    miniMinimized = not miniMinimized
    if miniMinimized then
        tween(miniUI, 0.25, { Size = miniMinSize })
        miniBody.Visible = false
    else
        tween(miniUI, 0.25, { Size = miniFullSize })
        miniBody.Visible = true
    end
end)

-- ================================================================
-- INIT
-- ================================================================
loadConfig()
refreshSavedList()
refreshCpList()

LocalPlayer.CharacterAdded:Connect(function(char)
    STATE.history = {}
    lastPos = nil
    stopPlayback()
    destroyTrail()
    task.wait(1)
    refreshSavedList()
end)

ScreenGui.AncestryChanged:Connect(function()
    if not ScreenGui.Parent then
        stopPlayback()
        enableControls()
        destroyTrail()
        if STATE.recording.conn then STATE.recording.conn:Disconnect() end
        if steppedConn then steppedConn:Disconnect() end
    end
end)

task.delay(0.6, function()
    notify("✨ LuxxyHub AutoWalk v10.5 PRECISION dimuat", T.PURPLE_LIGHT)
end)

log("Script loaded - PRECISION MODE ACTIVE")
