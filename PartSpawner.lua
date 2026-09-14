--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║         LUXXY PRIVATE PART — Client-Side Invisible Part      ║
    ║         Spawn In Front | Blue Sky Gradient Button            ║
    ║         Compatible: Delta Executor                            ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

--=============================================================
-- [ CONFIG ]
--=============================================================
local CONFIG = {
    LogoId          = "rbxassetid://117824631017448",
    PartColor       = Color3.fromRGB(80, 200, 255),
    PartTransparency = 0.1,

    ColorPrimary    = Color3.fromRGB(80, 190, 255),
    ColorSecondary  = Color3.fromRGB(0, 120, 200),
    ColorBackground = Color3.fromRGB(0, 0, 0),
    ColorText       = Color3.fromRGB(255, 255, 255),
    ColorCyanDark   = Color3.fromRGB(0, 55, 65),
    ColorCyanDark2  = Color3.fromRGB(0, 35, 45),
    ColorNeon       = Color3.fromRGB(80, 220, 255),
    ColorRed        = Color3.fromRGB(200, 40, 40),

    DefaultSize     = { 10, 1, 10 },
    DefaultRotation = { 0, 0, 0 },
    DistanceInFront = 8,     -- jarak part di depan karakter (studs)
    HeightOffset    = 0,     -- offset tinggi dari kaki karakter

    UIFrameWidth    = 300,
    UIHeaderHeight  = 36,
    UIBodyHeight    = 420,
    SliderHeight    = 38,
}

--=============================================================
-- [ SERVICES ]
--=============================================================
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--=============================================================
-- [ CLEANUP ]
--=============================================================
pcall(function()
    local old = CoreGui:FindFirstChild("LuxxysPrivatePart")
    if old then old:Destroy() end
end)
pcall(function()
    local oldPart = workspace:FindFirstChild("LuxxysPrivatePart")
    if oldPart then oldPart:Destroy() end
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
        Color = color or CONFIG.ColorNeon,
        Thickness = thickness or 1.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function gradient(parent, c1, c2, rot)
    return new("UIGradient", {
        Color = ColorSequence.new(c1 or CONFIG.ColorPrimary, c2 or CONFIG.ColorSecondary),
        Rotation = rot or 90,
        Parent = parent,
    })
end

--=============================================================
-- [ POSISI TENGAH LAYAR ]
--=============================================================
local viewportSize = Camera.ViewportSize
local uiWidth = CONFIG.UIFrameWidth
local headerH = CONFIG.UIHeaderHeight
local bodyH = CONFIG.UIBodyHeight
local totalH = headerH + bodyH

local startX = math.floor((viewportSize.X - uiWidth) / 2)
local startY = math.max(20, math.floor((viewportSize.Y - totalH) / 2) - 20)

--=============================================================
-- [ ROOT GUI ]
--=============================================================
local ScreenGui = new("ScreenGui", {
    Name = "LuxxysPrivatePart",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = CoreGui,
})

--=============================================================
-- [ HEADER BAR ]
--=============================================================
local Header = new("Frame", {
    Name = "Header",
    Size = UDim2.new(0, uiWidth, 0, headerH),
    Position = UDim2.new(0, startX, 0, startY),
    BackgroundColor3 = CONFIG.ColorBackground,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
    ClipsDescendants = true,
    ZIndex = 100,
    Parent = ScreenGui,
})
corner(Header, 10)
stroke(Header, CONFIG.ColorNeon, 2)
gradient(Header, CONFIG.ColorPrimary, CONFIG.ColorSecondary, 45)

-- Shimmer header
local headerShimmer = new("Frame", {
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.75,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 40, 1, 0),
    Position = UDim2.new(-0.3, 0, 0, 0),
    ZIndex = 101,
    Parent = Header,
})
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    }),
    Parent = headerShimmer,
})
task.spawn(function()
    while headerShimmer.Parent do
        headerShimmer.Position = UDim2.new(-0.3, 0, 0, 0)
        TweenService:Create(headerShimmer, TweenInfo.new(2, Enum.EasingStyle.Linear), {
            Position = UDim2.new(1.3, 0, 0, 0),
        }):Play()
        task.wait(2.5)
    end
end)

-- Judul
new("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "PART SPAWNER - Luxxy",
    TextColor3 = CONFIG.ColorText,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 102,
    Parent = Header,
})

-- Minimize button (− biru)
local MinimizeBtn = new("TextButton", {
    Size = UDim2.new(0, 22, 0, 22),
    Position = UDim2.new(1, -52, 0.5, -11),
    BackgroundColor3 = CONFIG.ColorPrimary,
    Text = "−",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    BorderSizePixel = 0,
    ZIndex = 103,
    Parent = Header,
})
corner(MinimizeBtn, 5)
gradient(MinimizeBtn, CONFIG.ColorPrimary, CONFIG.ColorNeon, 0)

-- Close button (X merah)
local CloseBtn = new("TextButton", {
    Size = UDim2.new(0, 22, 0, 22),
    Position = UDim2.new(1, -26, 0.5, -11),
    BackgroundColor3 = CONFIG.ColorRed,
    Text = "X",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    BorderSizePixel = 0,
    ZIndex = 103,
    Parent = Header,
})
corner(CloseBtn, 5)

--=============================================================
-- [ BODY ]
--=============================================================
local Body = new("Frame", {
    Name = "Body",
    Size = UDim2.new(0, uiWidth, 0, bodyH),
    Position = UDim2.new(0, startX, 0, startY + headerH + 4),
    BackgroundColor3 = CONFIG.ColorBackground,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 90,
    Parent = ScreenGui,
})
corner(Body, 10)
stroke(Body, CONFIG.ColorNeon, 2)
gradient(Body, CONFIG.ColorPrimary, CONFIG.ColorSecondary, 45)

-- Shimmer body
local bodyShimmer = new("Frame", {
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 50, 1, 0),
    Position = UDim2.new(-0.3, 0, 0, 0),
    ZIndex = 91,
    Parent = Body,
})
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    }),
    Parent = bodyShimmer,
})
task.spawn(function()
    while bodyShimmer.Parent do
        bodyShimmer.Position = UDim2.new(-0.3, 0, 0, 0)
        TweenService:Create(bodyShimmer, TweenInfo.new(3, Enum.EasingStyle.Linear), {
            Position = UDim2.new(1.3, 0, 0, 0),
        }):Play()
        task.wait(3.5)
    end
end)

-- Inner body
local InnerBody = new("Frame", {
    Size = UDim2.new(1, -4, 1, -4),
    Position = UDim2.new(0, 2, 0, 2),
    BackgroundColor3 = Color3.fromRGB(0, 8, 18),
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    ZIndex = 92,
    Parent = Body,
})
corner(InnerBody, 8)

--=============================================================
-- [ SLIDER FUNCTION ]
--=============================================================
local function makeSlider(parent, labelText, minV, maxV, defaultV, stepV, yPos, onChange)
    local h = CONFIG.SliderHeight

    local container = new("Frame", {
        Size = UDim2.new(1, -16, 0, h),
        Position = UDim2.new(0, 8, 0, yPos),
        BackgroundColor3 = CONFIG.ColorCyanDark,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = parent,
    })
    corner(container, 6)
    stroke(container, CONFIG.ColorPrimary, 1)

    new("TextLabel", {
        Size = UDim2.new(0, 70, 0, 14),
        Position = UDim2.new(0, 8, 0, 3),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = CONFIG.ColorPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11,
        Parent = container,
    })

    local valueDisplay = new("TextLabel", {
        Size = UDim2.new(0, 60, 0, 14),
        Position = UDim2.new(1, -68, 0, 3),
        BackgroundTransparency = 1,
        Text = string.format("%.1f", defaultV),
        TextColor3 = CONFIG.ColorText,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 11,
        Parent = container,
    })

    local track = new("Frame", {
        Size = UDim2.new(1, -16, 0, 7),
        Position = UDim2.new(0, 8, 0, 22),
        BackgroundColor3 = Color3.fromRGB(20, 40, 60),
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = container,
    })
    corner(track, 3)

    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CONFIG.ColorPrimary,
        BorderSizePixel = 0,
        ZIndex = 12,
        Parent = track,
    })
    corner(fill, 3)
    gradient(fill, CONFIG.ColorPrimary, CONFIG.ColorNeon, 0)

    local knob = new("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 0.5, -6),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CONFIG.ColorText,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = track,
    })
    corner(knob, 3)
    new("UIStroke", {
        Color = CONFIG.ColorNeon,
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = knob,
    })

    local clickArea = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 15,
        Parent = track,
    })

    local currentValue = defaultV
    local dragging = false

    local function updateFromPosition(mouseX)
        local trackAbsPos = track.AbsolutePosition.X
        local trackAbsSize = track.AbsoluteSize.X
        if trackAbsSize <= 0 then return end
        local relativeX = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
        local rawVal = minV + (maxV - minV) * relativeX
        local stepped = math.floor(rawVal / stepV + 0.5) * stepV
        stepped = math.clamp(stepped, minV, maxV)
        currentValue = stepped
        valueDisplay.Text = string.format("%.1f", stepped)
        local ratio = (stepped - minV) / (maxV - minV)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, -6)
        if onChange then onChange(stepped) end
    end

    local defaultRatio = (defaultV - minV) / (maxV - minV)
    fill.Size = UDim2.new(defaultRatio, 0, 1, 0)
    knob.Position = UDim2.new(defaultRatio, 0, 0.5, -6)

    clickArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromPosition(input.Position.X)
        end
    end)
    clickArea.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromPosition(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        get = function() return currentValue end,
        set = function(val)
            currentValue = val
            valueDisplay.Text = string.format("%.1f", val)
            local ratio = (val - minV) / (maxV - minV)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            knob.Position = UDim2.new(ratio, 0, 0.5, -6)
            if onChange then onChange(val) end
        end,
    }
end

--=============================================================
-- [ BUILD UI CONTENT ]
--=============================================================
local sizeValues = { X = CONFIG.DefaultSize[1], Y = CONFIG.DefaultSize[2], Z = CONFIG.DefaultSize[3] }
local rotValues  = { X = CONFIG.DefaultRotation[1], Y = CONFIG.DefaultRotation[2], Z = CONFIG.DefaultRotation[3] }

local sliderH = CONFIG.SliderHeight
local contentStartY = 8

-- Section SIZE
new("TextLabel", {
    Size = UDim2.new(1, -16, 0, 14),
    Position = UDim2.new(0, 8, 0, contentStartY),
    BackgroundTransparency = 1,
    Text = "📐 SIZE",
    TextColor3 = CONFIG.ColorPrimary,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
    Parent = InnerBody,
})

makeSlider(InnerBody, "Size X", 1, 100, CONFIG.DefaultSize[1], 0.5, contentStartY + 18, function(v) sizeValues.X = v end)
makeSlider(InnerBody, "Size Y", 1, 100, CONFIG.DefaultSize[2], 0.5, contentStartY + 18 + sliderH + 4, function(v) sizeValues.Y = v end)
makeSlider(InnerBody, "Size Z", 1, 100, CONFIG.DefaultSize[3], 0.5, contentStartY + 18 + (sliderH + 4) * 2, function(v) sizeValues.Z = v end)

-- Section ROTATION
local rotStart = contentStartY + 18 + (sliderH + 4) * 3 + 6

new("TextLabel", {
    Size = UDim2.new(1, -16, 0, 14),
    Position = UDim2.new(0, 8, 0, rotStart),
    BackgroundTransparency = 1,
    Text = "🔄 ROTATION",
    TextColor3 = CONFIG.ColorPrimary,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
    Parent = InnerBody,
})

makeSlider(InnerBody, "Rot X", -180, 180, CONFIG.DefaultRotation[1], 1, rotStart + 18, function(v) rotValues.X = v end)
makeSlider(InnerBody, "Rot Y", -180, 180, CONFIG.DefaultRotation[2], 1, rotStart + 18 + sliderH + 4, function(v) rotValues.Y = v end)
makeSlider(InnerBody, "Rot Z", -180, 180, CONFIG.DefaultRotation[3], 1, rotStart + 18 + (sliderH + 4) * 2, function(v) rotValues.Z = v end)

--=============================================================
-- [ SPAWN BUTTON — Blue Sky Gradient Bergerak ]
--=============================================================
local btnStart = rotStart + 18 + (sliderH + 4) * 3 + 8

local SpawnBtn = new("TextButton", {
    Size = UDim2.new(1, -16, 0, 36),
    Position = UDim2.new(0, 8, 0, btnStart),
    BackgroundColor3 = Color3.fromRGB(80, 190, 255),
    Text = "🚀 SPAWN PART",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = InnerBody,
})
corner(SpawnBtn, 6)
stroke(SpawnBtn, Color3.fromRGB(200, 240, 255), 2)

-- Gradient biru sky → putih → biru sky, berjalan
local spawnGrad = new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(80, 190, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 240, 255)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(80, 190, 255)),
    }),
    Rotation = 0,
    Parent = SpawnBtn,
})

task.spawn(function()
    while spawnGrad.Parent do
        spawnGrad.Offset = Vector2.new(-1, 0)
        TweenService:Create(spawnGrad, TweenInfo.new(2, Enum.EasingStyle.Linear),
            { Offset = Vector2.new(1, 0) }):Play()
        task.wait(2)
    end
end)

-- Status label
local statusLabel = new("TextLabel", {
    Size = UDim2.new(1, -16, 0, 14),
    Position = UDim2.new(0, 8, 0, btnStart + 42),
    BackgroundTransparency = 1,
    Text = "Siap spawn part di depan kamu",
    TextColor3 = CONFIG.ColorPrimary,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 10,
    Parent = InnerBody,
})

-- Delete button
local DeleteBtn = new("TextButton", {
    Size = UDim2.new(1, -16, 0, 26),
    Position = UDim2.new(0, 8, 0, btnStart + 60),
    BackgroundColor3 = CONFIG.ColorRed,
    Text = "🗑️ Hapus Part",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = InnerBody,
})
corner(DeleteBtn, 6)

--=============================================================
-- [ SINKRONISASI POSISI ]
--=============================================================
local function updateBodyPosition()
    Body.Position = UDim2.new(
        Header.Position.X.Scale, Header.Position.X.Offset,
        Header.Position.Y.Scale, Header.Position.Y.Offset + headerH + 4
    )
end
Header:GetPropertyChangedSignal("Position"):Connect(updateBodyPosition)
updateBodyPosition()

--=============================================================
-- [ MINIMIZE / EXPAND ]
--=============================================================
local isMinimized = false

local function minimizeUI()
    if isMinimized then return end
    isMinimized = true

    local startPos = Header.Position

    local shrinkTween = TweenService:Create(Body, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, uiWidth, 0, 0),
        Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset + headerH),
        BackgroundTransparency = 1,
    })
    shrinkTween:Play()

    for _, d in ipairs(InnerBody:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            pcall(function() TweenService:Create(d, TweenInfo.new(0.2), { TextTransparency = 1 }):Play() end)
            if d:IsA("TextButton") then
                pcall(function() TweenService:Create(d, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play() end)
            end
        elseif d:IsA("Frame") then
            pcall(function() TweenService:Create(d, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play() end)
        end
    end

    shrinkTween.Completed:Wait()
    Body.Visible = false
end

local function expandUI()
    if not isMinimized then return end
    isMinimized = false

    Body.Visible = true
    Body.Size = UDim2.new(0, uiWidth, 0, 0)
    Body.Position = UDim2.new(Header.Position.X.Scale, Header.Position.X.Offset, Header.Position.Y.Scale, Header.Position.Y.Offset + headerH)
    Body.BackgroundTransparency = 1

    TweenService:Create(Body, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, uiWidth, 0, bodyH),
        Position = UDim2.new(Header.Position.X.Scale, Header.Position.X.Offset, Header.Position.Y.Scale, Header.Position.Y.Offset + headerH + 4),
        BackgroundTransparency = 0.1,
    }):Play()

    TweenService:Create(InnerBody, TweenInfo.new(0.25), { BackgroundTransparency = 0.05 }):Play()

    for _, d in ipairs(InnerBody:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            pcall(function() TweenService:Create(d, TweenInfo.new(0.25), { TextTransparency = 0 }):Play() end)
        end
        if d:IsA("Frame") then
            pcall(function() TweenService:Create(d, TweenInfo.new(0.25), { BackgroundTransparency = 0.3 }):Play() end)
        end
    end
end

MinimizeBtn.MouseButton1Click:Connect(function()
    if isMinimized then expandUI() else minimizeUI() end
end)

--=============================================================
-- [ CLOSE BUTTON ]
--=============================================================
CloseBtn.MouseButton1Click:Connect(function()
    local spawnedPart = workspace:FindFirstChild("LuxxysPrivatePart")
    if spawnedPart then spawnedPart:Destroy() end

    TweenService:Create(Header, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    }):Play()
    TweenService:Create(Body, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    }):Play()

    task.wait(0.3)
    ScreenGui:Destroy()
end)

--=============================================================
-- [ PART SPAWN LOGIC — Spawn di DEPAN karakter ]
--=============================================================
local function spawnPart()
    local existing = workspace:FindFirstChild("LuxxysPrivatePart")
    if existing then existing:Destroy() end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        statusLabel.Text = "❌ Karakter belum ready"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    local hrp = char.HumanoidRootPart

    -- Ambil arah hadap karakter (look vector)
    local lookVector = hrp.CFrame.LookVector

    -- Posisi part: di DEPAN karakter sesuai arah hadap
    local spawnPos = hrp.Position + (lookVector * CONFIG.DistanceInFront) + Vector3.new(0, CONFIG.HeightOffset, 0)

    -- Buat part
    local part = Instance.new("Part")
    part.Name = "LuxxysPrivatePart"
    part.Size = Vector3.new(sizeValues.X, sizeValues.Y, sizeValues.Z)
    part.Anchored = true
    part.CanCollide = true
    part.Material = Enum.Material.SmoothPlastic
    part.Color = CONFIG.PartColor
    part.Transparency = CONFIG.PartTransparency
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    -- CFrame: posisi di depan + rotasi sejajar arah karakter + slider rotasi
    part.CFrame = CFrame.new(spawnPos) * CFrame.Angles(
        math.rad(rotValues.X),
        math.rad(rotValues.Y) + math.atan2(lookVector.X, lookVector.Z),
        math.rad(rotValues.Z)
    )

    part.Parent = workspace

    -- Texture logo di permukaan atas
    local topTexture = Instance.new("Texture")
    topTexture.Texture = CONFIG.LogoId
    topTexture.Face = Enum.NormalId.Top
    topTexture.StudsPerTileU = math.max(sizeValues.X, 2)
    topTexture.StudsPerTileV = math.max(sizeValues.Z, 2)
    topTexture.Parent = part

    -- Texture di sisi-sisi
    for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right}) do
        local decal = Instance.new("Texture")
        decal.Texture = CONFIG.LogoId
        decal.Face = face
        decal.StudsPerTileU = math.max(sizeValues.X, 2)
        decal.StudsPerTileV = math.max(sizeValues.Y, 2)
        decal.Parent = part
    end

    statusLabel.Text = "✅ Part spawned di depan kamu"
    statusLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
end

local function deletePart()
    local existing = workspace:FindFirstChild("LuxxysPrivatePart")
    if existing then
        existing:Destroy()
        statusLabel.Text = "🗑️ Part dihapus"
        statusLabel.TextColor3 = CONFIG.ColorPrimary
    else
        statusLabel.Text = "Tidak ada part"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    end
end

SpawnBtn.MouseButton1Click:Connect(spawnPart)
DeleteBtn.MouseButton1Click:Connect(deletePart)
