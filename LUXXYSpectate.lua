--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║         LUXXY SPECTATE — Player Spectator v2                 ║
    ║         Far Spectate | Toggle Button | Teleport              ║
    ║         Compatible: Delta Executor                            ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

--=============================================================
-- [ CONFIG ]
--=============================================================
local CONFIG = {
    ColorPrimary    = Color3.fromRGB(80, 190, 255),
    ColorSecondary  = Color3.fromRGB(200, 240, 255),
    ColorWhite      = Color3.fromRGB(255, 255, 255),
    ColorBackground = Color3.fromRGB(8, 20, 35),
    ColorDark       = Color3.fromRGB(15, 32, 52),
    ColorText       = Color3.fromRGB(255, 255, 255),
    ColorTextDim    = Color3.fromRGB(180, 210, 235),
    ColorRed        = Color3.fromRGB(220, 60, 60),
    ColorGreen      = Color3.fromRGB(60, 220, 120),
    ColorBlue       = Color3.fromRGB(0, 120, 200),
    ColorYellow     = Color3.fromRGB(255, 200, 60),

    UIFrameWidth    = 300,
    UIFrameHeight   = 440,
}

--=============================================================
-- [ SERVICES ]
--=============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local Camera             = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

--=============================================================
-- [ CLEANUP ]
--=============================================================
pcall(function()
    local old = CoreGui:FindFirstChild("LuxxysSpectate")
    if old then old:Destroy() end
end)

--=============================================================
-- [ UTILS ]
--=============================================================
local function new(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    return inst
end

local function corner(parent, radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function stroke(parent, color, thickness)
    return new("UIStroke", {
        Color = color or CONFIG.ColorPrimary,
        Thickness = thickness or 1.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function gradient(parent, c1, c2, rot)
    return new("UIGradient", {
        Color = ColorSequence.new(c1 or CONFIG.ColorPrimary, c2 or CONFIG.ColorSecondary),
        Rotation = rot or 0,
        Parent = parent,
    })
end

local function tween(inst, props, time, style)
    return TweenService:Create(inst, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad), props)
end

--=============================================================
-- [ STATE ]
--=============================================================
local State = {
    SelectedPlayer = nil,
    SpectateTarget = nil,
    SortedPlayers = {},
    IsSpectating = false,
}

--=============================================================
-- [ ROOT GUI ]
--=============================================================
local ScreenGui = new("ScreenGui", {
    Name = "LuxxysSpectate",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = CoreGui,
})

--=============================================================
-- [ MAIN FRAME ]
--=============================================================
local MainFrame = new("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, CONFIG.UIFrameWidth, 0, CONFIG.UIFrameHeight),
    Position = UDim2.new(0.5, -CONFIG.UIFrameWidth/2, 0.5, -CONFIG.UIFrameHeight/2),
    BackgroundColor3 = CONFIG.ColorBackground,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true,
    ZIndex = 1,
    Parent = ScreenGui,
})
corner(MainFrame, 14)
stroke(MainFrame, CONFIG.ColorPrimary, 2)
gradient(MainFrame, CONFIG.ColorPrimary, CONFIG.ColorSecondary, 45)

--=============================================================
-- [ HEADER ]
--=============================================================
local Header = new("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = CONFIG.ColorBackground,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    ZIndex = 2,
    Parent = MainFrame,
})
corner(Header, 14)

local headerGrad = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = CONFIG.ColorPrimary,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = Header,
})
corner(headerGrad, 14)
gradient(headerGrad, CONFIG.ColorPrimary, CONFIG.ColorSecondary, 0)

local headerShimmer = new("Frame", {
    Size = UDim2.new(0, 60, 1, 0),
    Position = UDim2.new(-0.3, 0, 0, 0),
    BackgroundColor3 = CONFIG.ColorWhite,
    BackgroundTransparency = 0.7,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = Header,
})
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    }),
    Parent = headerShimmer,
})
task.spawn(function()
    while headerShimmer.Parent do
        headerShimmer.Position = UDim2.new(-0.3, 0, 0, 0)
        tween(headerShimmer, { Position = UDim2.new(1.3, 0, 0, 0) }, 2.5, Enum.EasingStyle.Linear):Play()
        task.wait(3)
    end
end)

new("TextLabel", {
    Size = UDim2.new(1, -90, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "LUXXY SPECTATE",
    TextColor3 = CONFIG.ColorWhite,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 10,
    Parent = Header,
})

local MinimizeBtn = new("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -60, 0.5, -12),
    BackgroundColor3 = CONFIG.ColorDark,
    BackgroundTransparency = 0.2,
    Text = "−",
    TextColor3 = CONFIG.ColorWhite,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = Header,
})
corner(MinimizeBtn, 6)

local CloseBtn = new("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -32, 0.5, -12),
    BackgroundColor3 = CONFIG.ColorRed,
    Text = "X",
    TextColor3 = CONFIG.ColorWhite,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = Header,
})
corner(CloseBtn, 6)

--=============================================================
-- [ DRAG ]
--=============================================================
local dragging, dragInput, dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

--=============================================================
-- [ BODY ]
--=============================================================
local Body = new("Frame", {
    Name = "Body",
    Size = UDim2.new(1, -16, 1, -52),
    Position = UDim2.new(0, 8, 0, 44),
    BackgroundTransparency = 1,
    ZIndex = 5,
    Parent = MainFrame,
})

--=============================================================
-- [ STATUS BOX ]
--=============================================================
local StatusBox = new("Frame", {
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = CONFIG.ColorDark,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    ZIndex = 6,
    Parent = Body,
})
corner(StatusBox, 8)
stroke(StatusBox, CONFIG.ColorPrimary, 1)
gradient(StatusBox, CONFIG.ColorPrimary, CONFIG.ColorSecondary, 45)

local Badge = new("Frame", {
    Size = UDim2.new(0, 90, 0, 20),
    Position = UDim2.new(0, 10, 0, 8),
    BackgroundColor3 = CONFIG.ColorPrimary,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    ZIndex = 7,
    Parent = StatusBox,
})
corner(Badge, 5)

local BadgeDot = new("Frame", {
    Size = UDim2.new(0, 6, 0, 6),
    Position = UDim2.new(0, 8, 0.5, -3),
    BackgroundColor3 = CONFIG.ColorWhite,
    BorderSizePixel = 0,
    ZIndex = 8,
    Parent = Badge,
})
corner(BadgeDot, 3)

local BadgeText = new("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 18, 0, 0),
    BackgroundTransparency = 1,
    Text = "IDLE",
    TextColor3 = CONFIG.ColorWhite,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 8,
    Parent = Badge,
})

local CounterText = new("TextLabel", {
    Size = UDim2.new(0, 60, 0, 20),
    Position = UDim2.new(1, -70, 0, 8),
    BackgroundColor3 = CONFIG.ColorDark,
    BackgroundTransparency = 0.3,
    Text = "0/0",
    TextColor3 = CONFIG.ColorWhite,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BorderSizePixel = 0,
    ZIndex = 7,
    Parent = StatusBox,
})
corner(CounterText, 5)

local TargetName = new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 18),
    Position = UDim2.new(0, 10, 0, 30),
    BackgroundTransparency = 1,
    Text = "Belum ada target",
    TextColor3 = CONFIG.ColorWhite,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 7,
    Parent = StatusBox,
})

--=============================================================
-- [ CONTROLS ROW — Prev / Spectate (Toggle) / Next ]
--=============================================================
local ControlsRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 36),
    Position = UDim2.new(0, 0, 0, 64),
    BackgroundTransparency = 1,
    ZIndex = 6,
    Parent = Body,
})

local PrevBtn = new("TextButton", {
    Size = UDim2.new(0, 40, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = CONFIG.ColorDark,
    Text = "◄",
    TextColor3 = CONFIG.ColorPrimary,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    BorderSizePixel = 0,
    ZIndex = 7,
    Parent = ControlsRow,
})
corner(PrevBtn, 8)
stroke(PrevBtn, CONFIG.ColorPrimary, 1)

-- Tombol utama (bisa berubah jadi STOP saat spectate aktif)
local SpectateBtn = new("TextButton", {
    Size = UDim2.new(1, -100, 1, 0),
    Position = UDim2.new(0, 46, 0, 0),
    BackgroundColor3 = CONFIG.ColorPrimary,
    Text = "▶ SPECTATE",
    TextColor3 = CONFIG.ColorWhite,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    BorderSizePixel = 0,
    ZIndex = 7,
    Parent = ControlsRow,
})
corner(SpectateBtn, 8)
local specGrad = gradient(SpectateBtn, CONFIG.ColorPrimary, CONFIG.ColorSecondary, 0)

local NextBtn = new("TextButton", {
    Size = UDim2.new(0, 40, 1, 0),
    Position = UDim2.new(1, -40, 0, 0),
    BackgroundColor3 = CONFIG.ColorDark,
    Text = "►",
    TextColor3 = CONFIG.ColorPrimary,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    BorderSizePixel = 0,
    ZIndex = 7,
    Parent = ControlsRow,
})
corner(NextBtn, 8)
stroke(NextBtn, CONFIG.ColorPrimary, 1)

--=============================================================
-- [ TELEPORT BUTTON ]
--=============================================================
local TeleportBtn = new("TextButton", {
    Size = UDim2.new(1, 0, 0, 32),
    Position = UDim2.new(0, 0, 0, 106),
    BackgroundColor3 = CONFIG.ColorBlue,
    Text = "⚡ TELEPORT TO PLAYER",
    TextColor3 = CONFIG.ColorWhite,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    BorderSizePixel = 0,
    ZIndex = 6,
    Parent = Body,
})
corner(TeleportBtn, 8)
gradient(TeleportBtn, CONFIG.ColorBlue, CONFIG.ColorPrimary, 0)

--=============================================================
-- [ PLAYER LIST ]
--=============================================================
local ListLabel = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 0, 146),
    BackgroundTransparency = 1,
    Text = "SELECTED PLAYER LIST:",
    TextColor3 = CONFIG.ColorPrimary,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6,
    Parent = Body,
})

local ListScroll = new("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -168),
    Position = UDim2.new(0, 0, 0, 168),
    BackgroundColor3 = CONFIG.ColorDark,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = CONFIG.ColorPrimary,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 6,
    Parent = Body,
})
corner(ListScroll, 8)

new("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = ListScroll,
})

new("UIPadding", {
    PaddingTop = UDim.new(0, 4),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 4),
    Parent = ListScroll,
})

--=============================================================
-- [ PLAYER LIST LOGIC ]
--=============================================================
local listItems = {}

local function getSortedPlayers()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr)
        end
    end

    local myChar = LocalPlayer.Character
    local myPos = (myChar and myChar:FindFirstChild("HumanoidRootPart")) and myChar.HumanoidRootPart.Position or Vector3.new(0, 0, 0)

    table.sort(list, function(a, b)
        local aChar = a.Character
        local bChar = b.Character
        local aPos = (aChar and aChar:FindFirstChild("HumanoidRootPart")) and aChar.HumanoidRootPart.Position or Vector3.new(0, 0, 0)
        local bPos = (bChar and bChar:FindFirstChild("HumanoidRootPart")) and bChar.HumanoidRootPart.Position or Vector3.new(0, 0, 0)
        return (aPos - myPos).Magnitude < (bPos - myPos).Magnitude
    end)
    return list
end

local function getDistanceTo(plr)
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return 0 end
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    return (hrp.Position - myHrp.Position).Magnitude
end

local function highlightSelected()
    for plr, item in pairs(listItems) do
        if plr == State.SelectedPlayer then
            item.Frame.BackgroundColor3 = CONFIG.ColorPrimary
            item.Frame.BackgroundTransparency = 0.4
            item.Dot.BackgroundColor3 = CONFIG.ColorWhite
        else
            item.Frame.BackgroundColor3 = CONFIG.ColorDark
            item.Frame.BackgroundTransparency = 0.3
            item.Dot.BackgroundColor3 = CONFIG.ColorGreen
        end
    end

    if State.SelectedPlayer then
        TargetName.Text = State.SelectedPlayer.DisplayName .. " (@" .. State.SelectedPlayer.Name .. ")"
    else
        TargetName.Text = "Belum ada target"
    end
end

local function createListItem(plr)
    local itemFrame = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = CONFIG.ColorDark,
        BackgroundTransparency = 0.3,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 7,
        Parent = ListScroll,
    })
    corner(itemFrame, 6)
    stroke(itemFrame, CONFIG.ColorPrimary, 1)

    local dot = new("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 10, 0.5, -4),
        BackgroundColor3 = CONFIG.ColorGreen,
        BorderSizePixel = 0,
        ZIndex = 8,
        Parent = itemFrame,
    })
    corner(dot, 4)

    local nameLabel = new("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 26, 0, 0),
        BackgroundTransparency = 1,
        Text = plr.DisplayName,
        TextColor3 = CONFIG.ColorWhite,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8,
        Parent = itemFrame,
    })

    local distLabel = new("TextLabel", {
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -68, 0.5, -10),
        BackgroundColor3 = CONFIG.ColorPrimary,
        BackgroundTransparency = 0.3,
        Text = "0m",
        TextColor3 = CONFIG.ColorWhite,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        BorderSizePixel = 0,
        ZIndex = 8,
        Parent = itemFrame,
    })
    corner(distLabel, 4)

    itemFrame.MouseButton1Click:Connect(function()
        State.SelectedPlayer = plr
        highlightSelected()
    end)

    listItems[plr] = {
        Frame = itemFrame,
        Dot = dot,
        NameLabel = nameLabel,
        DistLabel = distLabel,
    }
end

local function removeListItem(plr)
    if listItems[plr] then
        listItems[plr].Frame:Destroy()
        listItems[plr] = nil
        if State.SelectedPlayer == plr then
            State.SelectedPlayer = nil
            highlightSelected()
        end
    end
end

local function refreshPlayerList()
    State.SortedPlayers = getSortedPlayers()

    for _, plr in ipairs(State.SortedPlayers) do
        if not listItems[plr] then
            createListItem(plr)
        end
    end

    for plr, _ in pairs(listItems) do
        if not plr.Parent then
            removeListItem(plr)
        end
    end

    for _, plr in ipairs(State.SortedPlayers) do
        local item = listItems[plr]
        if item then
            item.DistLabel.Text = string.format("%.1fm", getDistanceTo(plr))
            item.NameLabel.Text = plr.DisplayName
        end
    end

    local total = #State.SortedPlayers
    local currentIdx = 0
    for i, plr in ipairs(State.SortedPlayers) do
        if plr == State.SelectedPlayer then currentIdx = i; break end
    end
    CounterText.Text = currentIdx .. "/" .. total
end

--=============================================================
-- [ SPECTATE LOGIC — bisa jauh tanpa batas ]
--=============================================================
local specConn = nil

local function startSpectate(plr)
    if not plr or not plr.Parent then return end
    local char = plr.Character
    if not char then
        -- Coba tunggu sebentar
        local loaded = false
        local conn
        conn = plr.CharacterAdded:Connect(function(newChar)
            loaded = true
            if conn then conn:Disconnect() end
            -- Retry dengan karakter baru
            local humanoid = newChar:FindFirstChildOfClass("Humanoid")
            if humanoid and State.SpectateTarget == plr then
                Camera.CameraSubject = humanoid
            end
        end)
        task.wait(0.3)
        char = plr.Character
        if not char then return end
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    State.SpectateTarget = plr
    State.SelectedPlayer = plr
    State.IsSpectating = true

    -- Set camera ke player (bisa jarak berapapun — kamera akan teleport)
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = humanoid

    -- Update UI
    Badge.BackgroundColor3 = CONFIG.ColorRed
    BadgeText.Text = "SPECTATING"

    -- Tombol berubah jadi STOP
    SpectateBtn.Text = "■ STOP SPECTATE"
    SpectateBtn.BackgroundColor3 = CONFIG.ColorRed
    if specGrad then specGrad:Destroy() end

    TargetName.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"

    -- Kalau target respawn, update camera subject (unlimited time)
    if specConn then specConn:Disconnect() end
    specConn = plr.CharacterAdded:Connect(function(newChar)
        if State.SpectateTarget == plr then
            task.wait(0.5)
            local newHumanoid = newChar:FindFirstChildOfClass("Humanoid")
            if newHumanoid then
                Camera.CameraSubject = newHumanoid
            end
        end
    end)

    -- Auto-stop kalau target keluar game
    highlightSelected()
end

local function stopSpectate()
    State.SpectateTarget = nil
    State.IsSpectating = false

    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            Camera.CameraSubject = humanoid
            Camera.CameraType = Enum.CameraType.Custom
        end
    end

    if specConn then
        specConn:Disconnect()
        specConn = nil
    end

    -- Update UI
    Badge.BackgroundColor3 = CONFIG.ColorPrimary
    BadgeText.Text = "IDLE"

    SpectateBtn.Text = "▶ SPECTATE"
    SpectateBtn.BackgroundColor3 = CONFIG.ColorPrimary
    gradient(SpectateBtn, CONFIG.ColorPrimary, CONFIG.ColorSecondary, 0)

    highlightSelected()
end

local function toggleSpectate()
    if State.IsSpectating then
        stopSpectate()
    else
        if State.SelectedPlayer then
            startSpectate(State.SelectedPlayer)
        else
            if #State.SortedPlayers > 0 then
                State.SelectedPlayer = State.SortedPlayers[1]
                highlightSelected()
                startSpectate(State.SelectedPlayer)
            end
        end
    end
end

--=============================================================
-- [ TELEPORT LOGIC ]
--=============================================================
local function teleportToPlayer(plr)
    if not plr or not plr.Parent then return end
    local char = plr.Character
    if not char then return end
    local targetHrp = char:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return end

    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    -- Teleport ke posisi target (3 studs di samping)
    local targetPos = targetHrp.Position
    local offset = Vector3.new(3, 0, 3)
    local newPos = targetPos + offset

    -- Coba beberapa metode teleport
    pcall(function()
        myHrp.CFrame = CFrame.new(newPos)
    end)

    pcall(function()
        if myChar.PrimaryPart then
            myChar:PivotTo(CFrame.new(newPos))
        end
    end)

    pcall(function()
        myChar:MoveTo(newPos)
    end)
end

--=============================================================
-- [ BUTTON EVENTS ]
--=============================================================
PrevBtn.MouseButton1Click:Connect(function()
    local list = State.SortedPlayers
    if #list == 0 then return end

    local idx = 0
    for i, plr in ipairs(list) do
        if plr == State.SelectedPlayer then idx = i; break end
    end

    idx = idx - 1
    if idx < 1 then idx = #list end
    State.SelectedPlayer = list[idx]
    highlightSelected()
    refreshPlayerList()

    -- Kalau sedang spectate, ganti target
    if State.IsSpectating then
        startSpectate(State.SelectedPlayer)
    end
end)

NextBtn.MouseButton1Click:Connect(function()
    local list = State.SortedPlayers
    if #list == 0 then return end

    local idx = 0
    for i, plr in ipairs(list) do
        if plr == State.SelectedPlayer then idx = i; break end
    end

    idx = idx + 1
    if idx > #list then idx = 1 end
    State.SelectedPlayer = list[idx]
    highlightSelected()
    refreshPlayerList()

    -- Kalau sedang spectate, ganti target
    if State.IsSpectating then
        startSpectate(State.SelectedPlayer)
    end
end)

SpectateBtn.MouseButton1Click:Connect(toggleSpectate)

TeleportBtn.MouseButton1Click:Connect(function()
    if State.SelectedPlayer then
        teleportToPlayer(State.SelectedPlayer)
    end
end)

--=============================================================
-- [ PLAYER EVENTS ]
--=============================================================
Players.PlayerAdded:Connect(function(plr)
    task.wait(0.5)
    refreshPlayerList()
end)

Players.PlayerRemoving:Connect(function(plr)
    removeListItem(plr)

    -- Kalau yang keluar adalah target spectate, stop otomatis
    if State.SpectateTarget == plr then
        stopSpectate()
    end

    refreshPlayerList()
end)

--=============================================================
-- [ MINIMIZE / CLOSE ]
--=============================================================
local isMinimized = false

MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        tween(Body, { Size = UDim2.new(1, -16, 0, 0) }, 0.25):Play()
        tween(MainFrame, { Size = UDim2.new(0, CONFIG.UIFrameWidth, 0, 40) }, 0.25):Play()
        MinimizeBtn.Text = "+"
    else
        tween(MainFrame, { Size = UDim2.new(0, CONFIG.UIFrameWidth, 0, CONFIG.UIFrameHeight) }, 0.25):Play()
        tween(Body, { Size = UDim2.new(1, -16, 1, -52) }, 0.25):Play()
        MinimizeBtn.Text = "−"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    stopSpectate()
    tween(MainFrame, { Size = UDim2.new(0, 0, 0, 0) }, 0.2):Play()
    task.wait(0.25)
    ScreenGui:Destroy()
end)

--=============================================================
-- [ LOOPS ]
--=============================================================
task.spawn(function()
    while ScreenGui.Parent do
        refreshPlayerList()
        task.wait(0.5)
    end
end)

-- Camera follow guarantee
RunService.RenderStepped:Connect(function()
    if State.SpectateTarget then
        if not State.SpectateTarget.Parent then
            stopSpectate()
            return
        end
        local char = State.SpectateTarget.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and Camera.CameraSubject ~= humanoid then
                Camera.CameraSubject = humanoid
            end
        end
    end
end)

refreshPlayerList()
