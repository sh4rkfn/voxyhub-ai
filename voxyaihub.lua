
-- ============================================================
-- SERVICES & DEPENDENCIES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ============================================================
-- KEY SYSTEM
-- ============================================================
local KeySystem = {
    Enabled = true,
    CorrectKey = "voxyhubai12",
    Authenticated = false,
}

-- ============================================================
-- CORE REFERENCES
-- ============================================================
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- CONFIGURATION SYSTEM
-- ============================================================
local Config = {
    -- System Settings
    Version = "2.2",
    Name = "Voxy AI",
    
    -- Camera Settings
    Smoothness = 0.35,
    FOVRadius = 120,
    ShowFOV = true,
    
    -- Target Filtering
    IgnoreDead = true,
    IgnoreTeam = true,
    CheckWalls = false,
    
    -- Aim Mode Settings
    AimMode = "Specific Part",
    TargetPart = "Head",
    
    -- Prediction Settings
    PredictionEnabled = false,
    PredictionAmount = 0.125, -- Time in seconds to predict ahead
    PredictionMultiplier = 1.0, -- Velocity multiplier for fine-tuning
    
    -- ESP Settings
    ESPEnabled = false,
    ESPBoxes = true,
    ESPNames = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPTracers = false,
    ESPMaxDistance = 1000,
    ESPTeamColor = true,
    ESPBoxColor = Color3.fromRGB(255, 255, 255),
    ESPNameColor = Color3.fromRGB(255, 255, 255),
    ESPTracerColor = Color3.fromRGB(255, 255, 255),
    ESPThickness = 1.5,
    
    -- Infinite Jump Settings
    InfiniteJumpEnabled = false,
    
    -- Visual Settings
    FOVColor = Color3.fromRGB(120, 160, 255),
    FOVThickness = 2.5,
    FOVTransparency = 0.3,
    
    -- UI Theme
    Theme = {
        Primary = Color3.fromRGB(25, 27, 35),
        Secondary = Color3.fromRGB(35, 37, 45),
        Accent = Color3.fromRGB(88, 101, 242),
        Success = Color3.fromRGB(67, 181, 129),
        Danger = Color3.fromRGB(237, 66, 69),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(180, 185, 200),
        Border = Color3.fromRGB(45, 47, 55),
        Shadow = Color3.fromRGB(0, 0, 0),
    },
    
    -- System State
    Active = false,
    UIVisible = true,
}

-- ============================================================
-- STATE MANAGEMENT
-- ============================================================
local State = {
    Connections = {},
    CurrentTarget = nil,
    FOVCircle = nil,
    TargetIndicator = nil,
    LastUpdate = tick(),
    OpenDropdowns = {},
    ESPObjects = {},
    Performance = {
        FPS = 60,
        TargetCount = 0,
    }
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local Utils = {}

function Utils.CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

function Utils.CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.Theme.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

function Utils.CreateGradient(parent, rotation, colors)
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = rotation or 90
    if colors then
        gradient.Color = ColorSequence.new(colors)
    end
    gradient.Parent = parent
    return gradient
end

function Utils.TweenProperty(instance, property, value, duration)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {[property] = value}
    )
    tween:Play()
    return tween
end

function Utils.IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

function Utils.IsVisible(position)
    if not Config.CheckWalls then return true end
    
    local ray = Ray.new(Camera.CFrame.Position, (position - Camera.CFrame.Position).Unit * 500)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    
    return not hit or hit.Parent:FindFirstChild("Humanoid")
end

function Utils.GetPartFromPlayer(player)
    if not player.Character then return nil end
    
    if Config.AimMode == "Closest Part" then
        local closestPart = nil
        local closestDistance = math.huge
        local cameraPosition = Camera.CFrame.Position
        
        local bodyParts = {
            "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
            "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
            "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg",
            "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot",
            "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"
        }
        
        for _, partName in ipairs(bodyParts) do
            local part = player.Character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                local distance = (part.Position - cameraPosition).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPart = part
                end
            end
        end
        
        return closestPart or player.Character:FindFirstChild("Head")
    else
        return player.Character:FindFirstChild(Config.TargetPart) or 
               player.Character:FindFirstChild("Head")
    end
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================
local ESP = {}

function ESP.CreateESP(player)
    if State.ESPObjects[player] then
        ESP.RemoveESP(player)
    end
    
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP_" .. player.Name
    
    local drawings = {
        Box = {
            TopLeft = Drawing.new("Line"),
            TopRight = Drawing.new("Line"),
            BottomLeft = Drawing.new("Line"),
            BottomRight = Drawing.new("Line"),
            LeftSide = Drawing.new("Line"),
            RightSide = Drawing.new("Line"),
            TopSide = Drawing.new("Line"),
            BottomSide = Drawing.new("Line"),
        },
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        HealthBar = {
            Outline = Drawing.new("Line"),
            Bar = Drawing.new("Line"),
        },
        Tracer = Drawing.new("Line"),
    }
    
    -- Configure box lines
    for _, line in pairs(drawings.Box) do
        line.Thickness = Config.ESPThickness
        line.Color = Config.ESPBoxColor
        line.Transparency = 1
        line.Visible = false
    end
    
    -- Configure name text
    drawings.Name.Size = 14
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.Name.Color = Config.ESPNameColor
    drawings.Name.Visible = false
    
    -- Configure distance text
    drawings.Distance.Size = 12
    drawings.Distance.Center = true
    drawings.Distance.Outline = true
    drawings.Distance.Color = Config.ESPNameColor
    drawings.Distance.Visible = false
    
    -- Configure health text
    drawings.Health.Size = 12
    drawings.Health.Center = false
    drawings.Health.Outline = true
    drawings.Health.Visible = false
    
    -- Configure health bar
    drawings.HealthBar.Outline.Thickness = 3
    drawings.HealthBar.Outline.Color = Color3.new(0, 0, 0)
    drawings.HealthBar.Outline.Transparency = 1
    drawings.HealthBar.Outline.Visible = false
    
    drawings.HealthBar.Bar.Thickness = 1
    drawings.HealthBar.Bar.Transparency = 1
    drawings.HealthBar.Bar.Visible = false
    
    -- Configure tracer
    drawings.Tracer.Thickness = Config.ESPThickness
    drawings.Tracer.Color = Config.ESPTracerColor
    drawings.Tracer.Transparency = 1
    drawings.Tracer.Visible = false
    
    State.ESPObjects[player] = drawings
end

function ESP.RemoveESP(player)
    if not State.ESPObjects[player] then return end
    
    local drawings = State.ESPObjects[player]
    
    -- Remove box lines
    for _, line in pairs(drawings.Box) do
        line:Remove()
    end
    
    -- Remove texts
    drawings.Name:Remove()
    drawings.Distance:Remove()
    drawings.Health:Remove()
    
    -- Remove health bar
    drawings.HealthBar.Outline:Remove()
    drawings.HealthBar.Bar:Remove()
    
    -- Remove tracer
    drawings.Tracer:Remove()
    
    State.ESPObjects[player] = nil
end

function ESP.UpdateESP(player)
    if not Config.ESPEnabled then return end
    if not State.ESPObjects[player] then return end
    if not Utils.IsAlive(player) then
        ESP.HideESP(player)
        return
    end
    
    local character = player.Character
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not rootPart or not humanoid then
        ESP.HideESP(player)
        return
    end
    
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    
    if distance > Config.ESPMaxDistance then
        ESP.HideESP(player)
        return
    end
    
    local drawings = State.ESPObjects[player]
    
    -- Get bounding box
    local head = character:FindFirstChild("Head")
    if not head then
        ESP.HideESP(player)
        return
    end
    
    local headPos = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
    local legPos = rootPart.Position - Vector3.new(0, 3, 0)
    
    local topLeft, topLeftVis = Camera:WorldToViewportPoint(headPos + Vector3.new(-2, 0, 0))
    local topRight, topRightVis = Camera:WorldToViewportPoint(headPos + Vector3.new(2, 0, 0))
    local bottomLeft, bottomLeftVis = Camera:WorldToViewportPoint(legPos + Vector3.new(-2, 0, 0))
    local bottomRight, bottomRightVis = Camera:WorldToViewportPoint(legPos + Vector3.new(2, 0, 0))
    
    if not (topLeftVis or topRightVis or bottomLeftVis or bottomRightVis) then
        ESP.HideESP(player)
        return
    end
    
    -- Get team color
    local espColor = Config.ESPBoxColor
    if Config.ESPTeamColor and player.Team then
        espColor = player.Team.TeamColor.Color
    end
    
    -- Update box
    if Config.ESPBoxes then
        local topLeftV2 = Vector2.new(topLeft.X, topLeft.Y)
        local topRightV2 = Vector2.new(topRight.X, topRight.Y)
        local bottomLeftV2 = Vector2.new(bottomLeft.X, bottomLeft.Y)
        local bottomRightV2 = Vector2.new(bottomRight.X, bottomRight.Y)
        
        -- Update all box lines
        drawings.Box.TopSide.From = topLeftV2
        drawings.Box.TopSide.To = topRightV2
        drawings.Box.TopSide.Color = espColor
        drawings.Box.TopSide.Visible = true
        
        drawings.Box.BottomSide.From = bottomLeftV2
        drawings.Box.BottomSide.To = bottomRightV2
        drawings.Box.BottomSide.Color = espColor
        drawings.Box.BottomSide.Visible = true
        
        drawings.Box.LeftSide.From = topLeftV2
        drawings.Box.LeftSide.To = bottomLeftV2
        drawings.Box.LeftSide.Color = espColor
        drawings.Box.LeftSide.Visible = true
        
        drawings.Box.RightSide.From = topRightV2
        drawings.Box.RightSide.To = bottomRightV2
        drawings.Box.RightSide.Color = espColor
        drawings.Box.RightSide.Visible = true
    else
        for _, line in pairs(drawings.Box) do
            line.Visible = false
        end
    end
    
    -- Update name
    if Config.ESPNames then
        drawings.Name.Position = Vector2.new(topLeft.X, topLeft.Y - 20)
        drawings.Name.Text = player.Name
        drawings.Name.Color = espColor
        drawings.Name.Visible = true
    else
        drawings.Name.Visible = false
    end
    
    -- Update distance
    if Config.ESPDistance then
        drawings.Distance.Position = Vector2.new(topLeft.X, topLeft.Y - 35)
        drawings.Distance.Text = string.format("%.0f studs", distance)
        drawings.Distance.Color = espColor
        drawings.Distance.Visible = true
    else
        drawings.Distance.Visible = false
    end
    
    -- Update health bar and text
    if Config.ESPHealth then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local healthColor = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )
        
        drawings.Health.Position = Vector2.new(bottomLeft.X - 30, bottomLeft.Y)
        drawings.Health.Text = string.format("%.0f", humanoid.Health)
        drawings.Health.Color = healthColor
        drawings.Health.Visible = true
        
        -- Health bar
        local barHeight = bottomLeft.Y - topLeft.Y
        drawings.HealthBar.Outline.From = Vector2.new(topLeft.X - 7, topLeft.Y)
        drawings.HealthBar.Outline.To = Vector2.new(topLeft.X - 7, bottomLeft.Y)
        drawings.HealthBar.Outline.Visible = true
        
        drawings.HealthBar.Bar.From = Vector2.new(topLeft.X - 7, bottomLeft.Y)
        drawings.HealthBar.Bar.To = Vector2.new(topLeft.X - 7, bottomLeft.Y - (barHeight * healthPercent))
        drawings.HealthBar.Bar.Color = healthColor
        drawings.HealthBar.Bar.Visible = true
    else
        drawings.Health.Visible = false
        drawings.HealthBar.Outline.Visible = false
        drawings.HealthBar.Bar.Visible = false
    end
    
    -- Update tracer
    if Config.ESPTracers then
        local screenCenter = Camera.ViewportSize / 2
        drawings.Tracer.From = Vector2.new(screenCenter.X, Camera.ViewportSize.Y)
        drawings.Tracer.To = Vector2.new(bottomLeft.X, bottomLeft.Y)
        drawings.Tracer.Color = espColor
        drawings.Tracer.Visible = true
    else
        drawings.Tracer.Visible = false
    end
end

function ESP.HideESP(player)
    if not State.ESPObjects[player] then return end
    
    local drawings = State.ESPObjects[player]
    
    for _, line in pairs(drawings.Box) do
        line.Visible = false
    end
    
    drawings.Name.Visible = false
    drawings.Distance.Visible = false
    drawings.Health.Visible = false
    drawings.HealthBar.Outline.Visible = false
    drawings.HealthBar.Bar.Visible = false
    drawings.Tracer.Visible = false
end

function ESP.Initialize()
    -- Create ESP for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESP.CreateESP(player)
        end
    end
    
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        ESP.CreateESP(player)
    end)
    
    -- Handle players leaving
    Players.PlayerRemoving:Connect(function(player)
        ESP.RemoveESP(player)
    end)
    
    print("[ESP] System initialized")
end

function ESP.Cleanup()
    for player, _ in pairs(State.ESPObjects) do
        ESP.RemoveESP(player)
    end
    print("[ESP] Cleanup complete")
end

-- ============================================================
-- INFINITE JUMP SYSTEM
-- ============================================================
local InfiniteJump = {}

function InfiniteJump.Initialize()
    local connection = UserInputService.JumpRequest:Connect(function()
        if not Config.InfiniteJumpEnabled then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    
    table.insert(State.Connections, connection)
    print("[Infinite Jump] System initialized")
end

-- ============================================================
-- DRAWING SYSTEM
-- ============================================================
local DrawingManager = {}

function DrawingManager.CreateFOVCircle()
    if State.FOVCircle then
        State.FOVCircle:Remove()
    end
    
    local circle = Drawing.new("Circle")
    circle.Radius = Config.FOVRadius
    circle.Thickness = Config.FOVThickness
    circle.Color = Config.FOVColor
    circle.Transparency = Config.FOVTransparency
    circle.Filled = false
    circle.NumSides = 64
    circle.Visible = true
    circle.Position = Camera.ViewportSize / 2
    
    State.FOVCircle = circle
    return circle
end

function DrawingManager.CreateTargetIndicator()
    if State.TargetIndicator then
        State.TargetIndicator:Remove()
    end
    
    local indicator = Drawing.new("Circle")
    indicator.Radius = 8
    indicator.Thickness = 2
    indicator.Color = Config.Theme.Success
    indicator.Transparency = 1
    indicator.Filled = false
    indicator.NumSides = 32
    indicator.Visible = false
    
    State.TargetIndicator = indicator
    return indicator
end

function DrawingManager.UpdateFOV()
    if not State.FOVCircle then 
        if Config.Active then
            DrawingManager.CreateFOVCircle()
        else
            return
        end
    end
    
    local viewportCenter = Camera.ViewportSize / 2
    State.FOVCircle.Position = viewportCenter
    State.FOVCircle.Visible = Config.ShowFOV and Config.Active
    State.FOVCircle.Radius = Config.FOVRadius
    State.FOVCircle.Color = Config.FOVColor
end

function DrawingManager.UpdateTargetIndicator(screenPosition)
    if not State.TargetIndicator then return end
    
    if screenPosition then
        State.TargetIndicator.Position = screenPosition
        State.TargetIndicator.Visible = true
        
        local pulseSize = 8 + math.sin(tick() * 5) * 2
        State.TargetIndicator.Radius = pulseSize
    else
        State.TargetIndicator.Visible = false
    end
end

function DrawingManager.Cleanup()
    if State.FOVCircle then
        State.FOVCircle:Remove()
        State.FOVCircle = nil
    end
    if State.TargetIndicator then
        State.TargetIndicator:Remove()
        State.TargetIndicator = nil
    end
end

-- ============================================================
-- TARGET SYSTEM
-- ============================================================
local TargetSystem = {}

function TargetSystem.GetClosestTarget()
    local closestTarget = nil
    local closestDistance = math.huge
    local viewportCenter = Camera.ViewportSize / 2

    State.Performance.TargetCount = 0

    for _, player in ipairs(Players:GetPlayers()) do
        local valid = true

        if player == LocalPlayer then
            valid = false
        elseif not Utils.IsAlive(player) and Config.IgnoreDead then
            valid = false
        elseif player.Team == LocalPlayer.Team and Config.IgnoreTeam then
            valid = false
        end

        if valid then
            local targetPart = Utils.GetPartFromPlayer(player)
            if not targetPart then
                valid = false
            end

            if valid then
                State.Performance.TargetCount = State.Performance.TargetCount + 1

                local screenPosition, onScreen =
                    Camera:WorldToViewportPoint(targetPart.Position)

                if onScreen then
                    local screenPos2D = Vector2.new(screenPosition.X, screenPosition.Y)
                    local distanceFromCenter =
                        (screenPos2D - viewportCenter).Magnitude

                    if distanceFromCenter <= Config.FOVRadius then
                        if Utils.IsVisible(targetPart.Position) then
                            if distanceFromCenter < closestDistance then
                                closestDistance = distanceFromCenter
                                closestTarget = {
                                    Part = targetPart,
                                    Player = player,
                                    ScreenPosition = screenPos2D,
                                    Distance = distanceFromCenter
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    return closestTarget
end

function TargetSystem.AimAtTarget(target)
    if not target or not target.Part then return end
    
    local targetPosition = target.Part.Position
    
    -- Apply prediction if enabled
    if Config.PredictionEnabled then
        local targetVelocity = Vector3.new(0, 0, 0)
        
        -- Try to get velocity from the target part
        if target.Part:IsA("BasePart") then
            targetVelocity = target.Part.AssemblyLinearVelocity or target.Part.Velocity or Vector3.new(0, 0, 0)
        end
        
        -- Calculate predicted position
        local predictionTime = Config.PredictionAmount * Config.PredictionMultiplier
        local predictedOffset = targetVelocity * predictionTime
        targetPosition = targetPosition + predictedOffset
    end
    
    local cameraPosition = Camera.CFrame.Position
    local direction = (targetPosition - cameraPosition).Unit
    
    -- Smooth interpolation
    local currentLook = Camera.CFrame.LookVector
    local newLook = currentLook:Lerp(direction, Config.Smoothness)
    
    Camera.CFrame = CFrame.new(cameraPosition, cameraPosition + newLook)
end

-- ============================================================
-- GUI SYSTEM
-- ============================================================
local GUI = {}

function GUI.CreateKeySystem()
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "KeySystemGui"
    keyGui.ResetOnSpawn = false
    keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    keyGui.Parent = game.CoreGui
    
    -- Background blur
    local blur = Instance.new("Frame")
    blur.Name = "BlurBackground"
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blur.BackgroundTransparency = 0.3
    blur.BorderSizePixel = 0
    blur.Parent = keyGui
    
    -- Key window
    local keyWindow = Instance.new("Frame")
    keyWindow.Name = "KeyWindow"
    keyWindow.Size = UDim2.new(0, 420, 0, 320)
    keyWindow.Position = UDim2.new(0.5, -210, 0.5, -160)
    keyWindow.BackgroundColor3 = Config.Theme.Primary
    keyWindow.BorderSizePixel = 0
    keyWindow.Parent = keyGui
    
    Utils.CreateCorner(keyWindow, 16)
    Utils.CreateStroke(keyWindow, Config.Theme.Border, 2)
    
    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 50, 1, 50)
    shadow.Position = UDim2.new(0, -25, 0, -25)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Config.Theme.Shadow
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = 0
    shadow.Parent = keyWindow
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = Config.Theme.Secondary
    header.BorderSizePixel = 0
    header.Parent = keyWindow
    
    Utils.CreateCorner(header, 16)
    
    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 48, 0, 48)
    icon.Position = UDim2.new(0.5, -24, 0.5, -24)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://7733955511" -- Lock icon
    icon.ImageColor3 = Config.Theme.Accent
    icon.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 90)
    title.BackgroundTransparency = 1
    title.Text = "🔐 KEY VERIFICATION"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = Config.Theme.Text
    title.Parent = keyWindow
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 20)
    subtitle.Position = UDim2.new(0, 20, 0, 125)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter your key to access Camera Assist Pro"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
    subtitle.TextColor3 = Config.Theme.TextDark
    subtitle.Parent = keyWindow
    
    -- Get Key Button
    local getKeyButton = Instance.new("TextButton")
    getKeyButton.Size = UDim2.new(1, -40, 0, 35)
    getKeyButton.Position = UDim2.new(0, 20, 0, 150)
    getKeyButton.BackgroundColor3 = Config.Theme.Secondary
    getKeyButton.BorderSizePixel = 0
    getKeyButton.Text = "🔗 Get key here"
    getKeyButton.Font = Enum.Font.GothamBold
    getKeyButton.TextSize = 13
    getKeyButton.TextColor3 = Config.Theme.Accent
    getKeyButton.AutoButtonColor = false
    getKeyButton.Parent = keyWindow
    
    Utils.CreateCorner(getKeyButton, 8)
    Utils.CreateStroke(getKeyButton, Config.Theme.Accent, 1.5)
    
    -- Get Key Button hover effects
    getKeyButton.MouseEnter:Connect(function()
        Utils.TweenProperty(getKeyButton, "BackgroundColor3", Config.Theme.Border, 0.2)
        getKeyButton.TextColor3 = Color3.fromRGB(120, 140, 255)
    end)
    
    getKeyButton.MouseLeave:Connect(function()
        Utils.TweenProperty(getKeyButton, "BackgroundColor3", Config.Theme.Secondary, 0.2)
        getKeyButton.TextColor3 = Config.Theme.Accent
    end)
    
    -- Get Key Button click - copies Discord link to clipboard
    getKeyButton.MouseButton1Click:Connect(function()
        -- Visual feedback
        getKeyButton.Text = "✅ Link copied to clipboard!"
        getKeyButton.TextColor3 = Config.Theme.Success
        
        -- Copy to clipboard using setclipboard if available
        if setclipboard then
            setclipboard("https://discord.gg/v89MSdzjtE")
        end
        
        -- Try to open the link in browser
        if request then
            request({
                Url = "https://discord.gg/v89MSdzjtE",
                Method = "GET"
            })
        end
        
        wait(2)
        getKeyButton.Text = "🔗 Get key here"
        getKeyButton.TextColor3 = Config.Theme.Accent
    end)
    
    -- Key input frame
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -40, 0, 45)
    inputFrame.Position = UDim2.new(0, 20, 0, 195)
    inputFrame.BackgroundColor3 = Config.Theme.Secondary
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = keyWindow
    
    Utils.CreateCorner(inputFrame, 10)
    Utils.CreateStroke(inputFrame, Config.Theme.Border, 1.5)
    
    -- Key input box
    local keyInput = Instance.new("TextBox")
    keyInput.Size = UDim2.new(1, -20, 1, -10)
    keyInput.Position = UDim2.new(0, 10, 0, 5)
    keyInput.BackgroundTransparency = 1
    keyInput.Text = ""
    keyInput.PlaceholderText = "Enter your key..."
    keyInput.Font = Enum.Font.GothamMedium
    keyInput.TextSize = 14
    keyInput.TextColor3 = Config.Theme.Text
    keyInput.PlaceholderColor3 = Config.Theme.TextDark
    keyInput.ClearTextOnFocus = false
    keyInput.Parent = inputFrame
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -40, 0, 15)
    statusLabel.Position = UDim2.new(0, 20, 0, 250)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 11
    statusLabel.TextColor3 = Config.Theme.Danger
    statusLabel.Visible = false
    statusLabel.Parent = keyWindow
    
    -- Submit button
    local submitButton = Instance.new("TextButton")
    submitButton.Size = UDim2.new(1, -40, 0, 45)
    submitButton.Position = UDim2.new(0, 20, 1, -65)
    submitButton.BackgroundColor3 = Config.Theme.Accent
    submitButton.BorderSizePixel = 0
    submitButton.Text = "VERIFY KEY"
    submitButton.Font = Enum.Font.GothamBold
    submitButton.TextSize = 15
    submitButton.TextColor3 = Config.Theme.Text
    submitButton.AutoButtonColor = false
    submitButton.Parent = keyWindow
    
    Utils.CreateCorner(submitButton, 10)
    
    -- Button hover effects
    submitButton.MouseEnter:Connect(function()
        Utils.TweenProperty(submitButton, "BackgroundColor3", Color3.fromRGB(108, 121, 255), 0.2)
    end)
    
    submitButton.MouseLeave:Connect(function()
        Utils.TweenProperty(submitButton, "BackgroundColor3", Config.Theme.Accent, 0.2)
    end)
    
    -- Verification function
    local function verifyKey()
        local enteredKey = keyInput.Text
        
        if enteredKey == "" then
            statusLabel.Text = "⚠️ Please enter a key"
            statusLabel.TextColor3 = Config.Theme.Danger
            statusLabel.Visible = true
            
            -- Shake animation
            local originalPos = keyWindow.Position
            keyWindow:TweenPosition(
                UDim2.new(0.5, -220, 0.5, -160),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.1,
                true,
                function()
                    keyWindow:TweenPosition(
                        UDim2.new(0.5, -200, 0.5, -160),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quad,
                        0.1,
                        true,
                        function()
                            keyWindow.Position = originalPos
                        end
                    )
                end
            )
            return
        end
        
        if enteredKey == KeySystem.CorrectKey then
            -- Success!
            KeySystem.Authenticated = true
            statusLabel.Text = "✅ Key verified successfully!"
            statusLabel.TextColor3 = Config.Theme.Success
            statusLabel.Visible = true
            
            submitButton.Text = "SUCCESS!"
            submitButton.BackgroundColor3 = Config.Theme.Success
            
            -- Fade out and destroy
            wait(1)
            
            for i = 0, 1, 0.1 do
                blur.BackgroundTransparency = 0.3 + (0.7 * i)
                keyWindow.BackgroundTransparency = i
                header.BackgroundTransparency = i
                title.TextTransparency = i
                subtitle.TextTransparency = i
                getKeyButton.BackgroundTransparency = i
                getKeyButton.TextTransparency = i
                inputFrame.BackgroundTransparency = i
                keyInput.TextTransparency = i
                statusLabel.TextTransparency = i
                submitButton.BackgroundTransparency = i
                submitButton.TextTransparency = i
                icon.ImageTransparency = i
                wait(0.03)
            end
            
            keyGui:Destroy()
            
            -- Initialize the main system after successful authentication
            print("[Key System] Authentication successful! Loading main system...")
            
            -- Initialize main components
            ESP.Initialize()
            InfiniteJump.Initialize()
            GUI.Create()
            
            -- Start main loops
            local renderConnection = RunService.RenderStepped:Connect(function()
                if Config.Active then
                    DrawingManager.UpdateFOV()
                    
                    local target = TargetSystem.GetClosestTarget()
                    State.CurrentTarget = target
                    
                    if target then
                        TargetSystem.AimAtTarget(target)
                        DrawingManager.UpdateTargetIndicator(target.ScreenPosition)
                    else
                        DrawingManager.UpdateTargetIndicator(nil)
                    end
                end
                
                if Config.ESPEnabled then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            ESP.UpdateESP(player)
                        end
                    end
                end
            end)
            
            table.insert(State.Connections, renderConnection)
            
            local perfConnection = RunService.Heartbeat:Connect(function()
                GUI.UpdatePerformance()
            end)
            
            table.insert(State.Connections, perfConnection)
            
            print("[Camera Assist] System initialized successfully")
            print("[Camera Assist] Version: " .. Config.Version)
            print("[Camera Assist] Features: Prediction + ESP + Infinite Jump")
            
        else
            -- Wrong key
            statusLabel.Text = "❌ Invalid key! Please try again."
            statusLabel.TextColor3 = Config.Theme.Danger
            statusLabel.Visible = true
            
            keyInput.Text = ""
            
            -- Shake animation
            local originalPos = keyWindow.Position
            keyWindow:TweenPosition(
                UDim2.new(0.5, -220, 0.5, -160),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.1,
                true,
                function()
                    keyWindow:TweenPosition(
                        UDim2.new(0.5, -200, 0.5, -160),
                        Enum.EasingDirection.Out,
                        Enum.EasingStyle.Quad,
                        0.1,
                        true,
                        function()
                            keyWindow.Position = originalPos
                        end
                    )
                end
            )
        end
    end
    
    -- Button click
    submitButton.MouseButton1Click:Connect(verifyKey)
    
    -- Enter key press
    keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            verifyKey()
        end
    end)
    
    return keyGui
end

function GUI.Create()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CameraAssistPro"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game.CoreGui
    
    GUI.ScreenGui = screenGui
    GUI.CreateMainWindow()
    
    return screenGui
end

function GUI.CreateMainWindow()
    local container = Instance.new("Frame")
    container.Name = "MainWindow"
    container.Size = UDim2.new(0, 400, 0, 700)
    container.Position = UDim2.new(0.5, -200, 0.5, -350)
    container.BackgroundColor3 = Config.Theme.Primary
    container.BorderSizePixel = 0
    container.Active = true
    container.Draggable = true
    container.Parent = GUI.ScreenGui
    
    Utils.CreateCorner(container, 12)
    Utils.CreateStroke(container, Config.Theme.Border, 1.5)
    
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Config.Theme.Shadow
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = 0
    shadow.Parent = container
    
    GUI.Container = container
    
    GUI.CreateHeader(container)
    GUI.CreateContent(container)
    GUI.CreateFooter(container)
end

function GUI.CreateHeader(parent)
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Config.Theme.Secondary
    header.BorderSizePixel = 0
    header.Parent = parent
    
    Utils.CreateCorner(header, 12)
    
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(1, -20, 1, 0)
    titleFrame.Position = UDim2.new(0, 10, 0, 0)
    titleFrame.BackgroundTransparency = 1
    titleFrame.Parent = header
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 32, 0, 32)
    icon.Position = UDim2.new(0, 0, 0.5, -16)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://7733964719"
    icon.ImageColor3 = Config.Theme.Accent
    icon.Parent = titleFrame
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 24)
    title.Position = UDim2.new(0, 42, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = Config.Name
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Config.Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleFrame
    
    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(1, -40, 0, 16)
    version.Position = UDim2.new(0, 42, 0, 32)
    version.BackgroundTransparency = 1
    version.Text = "Version " .. Config.Version .. " • ESP + Prediction + Infinite Jump"
    version.Font = Enum.Font.Gotham
    version.TextSize = 11
    version.TextColor3 = Config.Theme.TextDark
    version.TextXAlignment = Enum.TextXAlignment.Left
    version.Parent = titleFrame
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 36, 0, 36)
    closeButton.Position = UDim2.new(1, -46, 0.5, -18)
    closeButton.BackgroundColor3 = Config.Theme.Danger
    closeButton.BorderSizePixel = 0
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 24
    closeButton.TextColor3 = Config.Theme.Text
    closeButton.AutoButtonColor = false
    closeButton.Parent = header
    
    Utils.CreateCorner(closeButton, 8)
    
    closeButton.MouseEnter:Connect(function()
        Utils.TweenProperty(closeButton, "BackgroundColor3", Color3.fromRGB(255, 80, 80), 0.15)
    end)
    
    closeButton.MouseLeave:Connect(function()
        Utils.TweenProperty(closeButton, "BackgroundColor3", Config.Theme.Danger, 0.15)
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        GUI.Destroy()
    end)
end

function GUI.CreateContent(parent)
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -120)
    content.Position = UDim2.new(0, 0, 0, 60)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Config.Theme.Accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ZIndex = 1
    content.Parent = parent
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.Parent = content
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content
    
    GUI.Content = content
    
    GUI.CreateSystemControls(content)
    GUI.CreateCameraSettings(content)
    GUI.CreateAimModeSettings(content)
    GUI.CreatePredictionSettings(content)
    GUI.CreateFilterSettings(content)
    GUI.CreateESPSettings(content)
    GUI.CreateMiscSettings(content)
    GUI.CreateVisualSettings(content)
    GUI.CreatePerformanceDisplay(content)
end

function GUI.CreateSection(parent, title, layoutOrder)
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Size = UDim2.new(1, 0, 0, 0)
    section.BackgroundColor3 = Config.Theme.Secondary
    section.BorderSizePixel = 0
    section.LayoutOrder = layoutOrder
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.ZIndex = 1
    section.Parent = parent
    
    Utils.CreateCorner(section, 8)
    
    local sectionPadding = Instance.new("UIPadding")
    sectionPadding.PaddingTop = UDim.new(0, 12)
    sectionPadding.PaddingBottom = UDim.new(0, 12)
    sectionPadding.PaddingLeft = UDim.new(0, 12)
    sectionPadding.PaddingRight = UDim.new(0, 12)
    sectionPadding.Parent = section
    
    local sectionLayout = Instance.new("UIListLayout")
    sectionLayout.Padding = UDim.new(0, 8)
    sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sectionLayout.Parent = section
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "SectionTitle"
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Config.Theme.Accent
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.LayoutOrder = 0
    titleLabel.ZIndex = 2
    titleLabel.Parent = section
    
    return section
end

function GUI.CreateToggle(parent, label, defaultValue, callback, layoutOrder)
    local toggle = Instance.new("Frame")
    toggle.Name = label .. "Toggle"
    toggle.Size = UDim2.new(1, 0, 0, 36)
    toggle.BackgroundTransparency = 1
    toggle.LayoutOrder = layoutOrder
    toggle.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, -50, 1, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 13
    labelText.TextColor3 = Config.Theme.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = toggle
    
    local switch = Instance.new("TextButton")
    switch.Name = "Switch"
    switch.Size = UDim2.new(0, 44, 0, 24)
    switch.Position = UDim2.new(1, -44, 0.5, -12)
    switch.BackgroundColor3 = defaultValue and Config.Theme.Success or Config.Theme.Border
    switch.BorderSizePixel = 0
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.Parent = toggle
    
    Utils.CreateCorner(switch, 12)
    
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = defaultValue and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Config.Theme.Text
    knob.BorderSizePixel = 0
    knob.Parent = switch
    
    Utils.CreateCorner(knob, 9)
    
    local state = defaultValue
    
    switch.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        
        Utils.TweenProperty(switch, "BackgroundColor3", 
            state and Config.Theme.Success or Config.Theme.Border, 0.2)
        Utils.TweenProperty(knob, "Position", 
            state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9), 0.2)
    end)
    
    return toggle
end

function GUI.CreateSlider(parent, label, min, max, default, callback, layoutOrder, decimals)
    local slider = Instance.new("Frame")
    slider.Name = label .. "Slider"
    slider.Size = UDim2.new(1, 0, 0, 50)
    slider.BackgroundTransparency = 1
    slider.LayoutOrder = layoutOrder
    slider.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.7, 0, 0, 20)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 13
    labelText.TextColor3 = Config.Theme.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = slider
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = decimals and string.format("%." .. decimals .. "f", default) or string.format("%.0f", default)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextColor3 = Config.Theme.Accent
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = slider
    
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 1, -10)
    track.BackgroundColor3 = Config.Theme.Border
    track.BorderSizePixel = 0
    track.Parent = slider
    
    Utils.CreateCorner(track, 3)
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Config.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    Utils.CreateCorner(fill, 3)
    
    local handle = Instance.new("Frame")
    handle.Name = "Handle"
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    handle.BackgroundColor3 = Config.Theme.Accent
    handle.BorderSizePixel = 0
    handle.Parent = track
    
    Utils.CreateCorner(handle, 8)
    Utils.CreateStroke(handle, Config.Theme.Text, 2)
    
    local dragging = false
    local currentValue = default
    
    local function updateValue(input)
        local relativeX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        currentValue = min + (max - min) * relativeX
        
        valueLabel.Text = decimals and string.format("%." .. decimals .. "f", currentValue) or string.format("%.0f", currentValue)
        fill.Size = UDim2.new(relativeX, 0, 1, 0)
        handle.Position = UDim2.new(relativeX, -8, 0.5, -8)
        
        callback(currentValue)
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Utils.TweenProperty(handle, "Size", UDim2.new(0, 20, 0, 20), 0.1)
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            Utils.TweenProperty(handle, "Size", UDim2.new(0, 16, 0, 16), 0.1)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            updateValue(input)
        end
    end)
    
    return slider
end

function GUI.CreateDropdown(parent, label, options, default, callback, layoutOrder)
    local dropdown = Instance.new("Frame")
    dropdown.Name = label .. "Dropdown"
    dropdown.Size = UDim2.new(1, 0, 0, 36)
    dropdown.BackgroundTransparency = 1
    dropdown.LayoutOrder = layoutOrder
    dropdown.ZIndex = 2
    dropdown.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.5, 0, 1, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 13
    labelText.TextColor3 = Config.Theme.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.ZIndex = 2
    labelText.Parent = dropdown
    
    local currentValue = default
    local expanded = false
    
    local button = Instance.new("TextButton")
    button.Name = "DropdownButton"
    button.Size = UDim2.new(0.5, -5, 1, 0)
    button.Position = UDim2.new(0.5, 5, 0, 0)
    button.BackgroundColor3 = Config.Theme.Secondary
    button.BorderSizePixel = 0
    button.Text = currentValue .. " ▼"
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 12
    button.TextColor3 = Config.Theme.Text
    button.AutoButtonColor = false
    button.ZIndex = 2
    button.Parent = dropdown
    
    Utils.CreateCorner(button, 6)
    Utils.CreateStroke(button, Config.Theme.Border, 1)
    
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name = "OptionsFrame_" .. label
    optionsFrame.Size = UDim2.new(0, button.AbsoluteSize.X, 0, #options * 32)
    optionsFrame.BackgroundColor3 = Config.Theme.Secondary
    optionsFrame.BorderSizePixel = 0
    optionsFrame.Visible = false
    optionsFrame.ZIndex = 1000
    optionsFrame.Parent = GUI.ScreenGui
    
    Utils.CreateCorner(optionsFrame, 6)
    Utils.CreateStroke(optionsFrame, Config.Theme.Accent, 1.5)
    
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Parent = optionsFrame
    
    local function updatePosition()
        local buttonPos = button.AbsolutePosition
        local buttonSize = button.AbsoluteSize
        optionsFrame.Position = UDim2.new(0, buttonPos.X, 0, buttonPos.Y + buttonSize.Y + 5)
        optionsFrame.Size = UDim2.new(0, buttonSize.X, 0, #options * 32)
    end
    
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = option
        optionButton.Size = UDim2.new(1, 0, 0, 32)
        optionButton.BackgroundColor3 = option == currentValue and Config.Theme.Accent or Config.Theme.Secondary
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.Font = Enum.Font.Gotham
        optionButton.TextSize = 11
        optionButton.TextColor3 = Config.Theme.Text
        optionButton.AutoButtonColor = false
        optionButton.LayoutOrder = i
        optionButton.ZIndex = 1001
        optionButton.Parent = optionsFrame
        
        if i == 1 or i == #options then
            Utils.CreateCorner(optionButton, 6)
        end
        
        optionButton.MouseEnter:Connect(function()
            if option ~= currentValue then
                Utils.TweenProperty(optionButton, "BackgroundColor3", Config.Theme.Border, 0.1)
            end
        end)
        
        optionButton.MouseLeave:Connect(function()
            if option ~= currentValue then
                Utils.TweenProperty(optionButton, "BackgroundColor3", Config.Theme.Secondary, 0.1)
            end
        end)
        
        optionButton.MouseButton1Click:Connect(function()
            for _, child in ipairs(optionsFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = Config.Theme.Secondary
                end
            end
            
            currentValue = option
            button.Text = option .. " ▼"
            optionButton.BackgroundColor3 = Config.Theme.Accent
            optionsFrame.Visible = false
            expanded = false
            
            for i, dd in ipairs(State.OpenDropdowns) do
                if dd == optionsFrame then
                    table.remove(State.OpenDropdowns, i)
                    break
                end
            end
            
            callback(option)
        end)
    end
    
    local function closeDropdown()
        optionsFrame.Visible = false
        expanded = false
        button.Text = currentValue .. " ▼"
        
        for i, dd in ipairs(State.OpenDropdowns) do
            if dd == optionsFrame then
                table.remove(State.OpenDropdowns, i)
                break
            end
        end
    end
    
    button.MouseButton1Click:Connect(function()
        for _, dd in ipairs(State.OpenDropdowns) do
            if dd ~= optionsFrame then
                dd.Visible = false
                local ddName = dd.Name:gsub("OptionsFrame_", "")
                for _, frame in ipairs(GUI.Content:GetDescendants()) do
                    if frame:IsA("TextButton") and frame.Name == "DropdownButton" and frame.Parent.Name:find(ddName) then
                        local value = frame.Text:gsub(" ▲", ""):gsub(" ▼", "")
                        frame.Text = value .. " ▼"
                    end
                end
            end
        end
        
        State.OpenDropdowns = {}
        
        expanded = not expanded
        
        if expanded then
            updatePosition()
        end
        
        optionsFrame.Visible = expanded
        button.Text = currentValue .. (expanded and " ▲" or " ▼")
        
        if expanded then
            table.insert(State.OpenDropdowns, optionsFrame)
        end
    end)
    
    local updateConnection = RunService.Heartbeat:Connect(function()
        if expanded then
            updatePosition()
        end
    end)
    
    table.insert(State.Connections, updateConnection)
    
    return dropdown
end

function GUI.CreateButton(parent, text, color, callback, layoutOrder)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Size = UDim2.new(1, 0, 0, 38)
    button.BackgroundColor3 = color or Config.Theme.Accent
    button.BorderSizePixel = 0
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Config.Theme.Text
    button.AutoButtonColor = false
    button.LayoutOrder = layoutOrder
    button.Parent = parent
    
    Utils.CreateCorner(button, 8)
    
    local originalColor = button.BackgroundColor3
    
    button.MouseEnter:Connect(function()
        Utils.TweenProperty(button, "BackgroundColor3", 
            Color3.fromRGB(
                math.min(originalColor.R * 255 + 20, 255),
                math.min(originalColor.G * 255 + 20, 255),
                math.min(originalColor.B * 255 + 20, 255)
            ), 0.15)
    end)
    
    button.MouseLeave:Connect(function()
        Utils.TweenProperty(button, "BackgroundColor3", originalColor, 0.15)
    end)
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

function GUI.CreateSystemControls(parent)
    local section = GUI.CreateSection(parent, "⚡ System Controls", 1)
    
    local activateButton = GUI.CreateButton(section, "ACTIVATE SYSTEM", Config.Theme.Success, function()
        Config.Active = not Config.Active
        
        if Config.Active then
            activateButton.Text = "DEACTIVATE SYSTEM"
            activateButton.BackgroundColor3 = Config.Theme.Danger
            
            task.wait()
            DrawingManager.CreateFOVCircle()
            DrawingManager.CreateTargetIndicator()
            
            print("[Camera Assist] System activated")
        else
            activateButton.Text = "ACTIVATE SYSTEM"
            activateButton.BackgroundColor3 = Config.Theme.Success
            DrawingManager.Cleanup()
            State.CurrentTarget = nil
            
            print("[Camera Assist] System deactivated")
        end
    end, 1)
    
    GUI.ActivateButton = activateButton
end

function GUI.CreateCameraSettings(parent)
    local section = GUI.CreateSection(parent, "🎯 Camera Settings", 2)
    
    GUI.CreateSlider(section, "Smoothness", 0.05, 1.0, Config.Smoothness, function(value)
        Config.Smoothness = value
    end, 1, 2)  -- 2 decimal places
    
    GUI.CreateSlider(section, "FOV Radius", 50, 300, Config.FOVRadius, function(value)
        Config.FOVRadius = value
        if State.FOVCircle then
            State.FOVCircle.Radius = value
        end
    end, 2)
end

function GUI.CreateAimModeSettings(parent)
    local section = GUI.CreateSection(parent, "🎮 Aim Mode", 3)
    
    GUI.CreateDropdown(section, "Aim Mode", 
        {"Specific Part", "Closest Part"}, 
        Config.AimMode, 
        function(value)
            Config.AimMode = value
            print("[Camera Assist] Aim mode changed to: " .. value)
        end, 
    1)
    
    local partDropdown = GUI.CreateDropdown(section, "Target Part", 
        {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, 
        Config.TargetPart, 
        function(value)
            Config.TargetPart = value
            print("[Camera Assist] Target part changed to: " .. value)
        end, 
    2)
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 40)
    infoLabel.BackgroundColor3 = Config.Theme.Primary
    infoLabel.BorderSizePixel = 0
    infoLabel.Text = "ℹ️ Closest Part: Aims at the nearest body part to camera"
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 10
    infoLabel.TextColor3 = Config.Theme.TextDark
    infoLabel.TextWrapped = true
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.LayoutOrder = 3
    infoLabel.Parent = section
    
    Utils.CreateCorner(infoLabel, 6)
    
    local infoPadding = Instance.new("UIPadding")
    infoPadding.PaddingTop = UDim.new(0, 6)
    infoPadding.PaddingBottom = UDim.new(0, 6)
    infoPadding.PaddingLeft = UDim.new(0, 6)
    infoPadding.PaddingRight = UDim.new(0, 6)
    infoPadding.Parent = infoLabel
end

function GUI.CreatePredictionSettings(parent)
    local section = GUI.CreateSection(parent, "🎯 Prediction Settings", 4)
    
    GUI.CreateToggle(section, "Enable Prediction", Config.PredictionEnabled, function(value)
        Config.PredictionEnabled = value
        print("[Prediction] " .. (value and "Enabled" or "Disabled"))
    end, 1)
    
    GUI.CreateSlider(section, "Prediction Time", 0.05, 0.5, Config.PredictionAmount, function(value)
        Config.PredictionAmount = value
    end, 2, 3)  -- 3 decimal places
    
    GUI.CreateSlider(section, "Velocity Multiplier", 0.1, 3.0, Config.PredictionMultiplier, function(value)
        Config.PredictionMultiplier = value
    end, 3, 2)  -- 2 decimal places
    
    local predInfo = Instance.new("TextLabel")
    predInfo.Size = UDim2.new(1, 0, 0, 55)
    predInfo.BackgroundColor3 = Config.Theme.Primary
    predInfo.BorderSizePixel = 0
    predInfo.Text = "ℹ️ Prediction compensates for moving targets by aiming ahead based on their velocity. Adjust time and multiplier for different movement speeds."
    predInfo.Font = Enum.Font.Gotham
    predInfo.TextSize = 10
    predInfo.TextColor3 = Config.Theme.TextDark
    predInfo.TextWrapped = true
    predInfo.TextYAlignment = Enum.TextYAlignment.Top
    predInfo.LayoutOrder = 4
    predInfo.Parent = section
    
    Utils.CreateCorner(predInfo, 6)
    
    local predPadding = Instance.new("UIPadding")
    predPadding.PaddingTop = UDim.new(0, 6)
    predPadding.PaddingBottom = UDim.new(0, 6)
    predPadding.PaddingLeft = UDim.new(0, 6)
    predPadding.PaddingRight = UDim.new(0, 6)
    predPadding.Parent = predInfo
end

function GUI.CreateFilterSettings(parent)
    local section = GUI.CreateSection(parent, "🔍 Target Filters", 5)
    
    GUI.CreateToggle(section, "Ignore Dead Players", Config.IgnoreDead, function(value)
        Config.IgnoreDead = value
    end, 1)
    
    GUI.CreateToggle(section, "Ignore Team", Config.IgnoreTeam, function(value)
        Config.IgnoreTeam = value
    end, 2)
    
    GUI.CreateToggle(section, "Wall Check", Config.CheckWalls, function(value)
        Config.CheckWalls = value
    end, 3)
end

function GUI.CreateESPSettings(parent)
    local section = GUI.CreateSection(parent, "👁️ ESP Settings", 6)
    
    GUI.CreateToggle(section, "Enable ESP", Config.ESPEnabled, function(value)
        Config.ESPEnabled = value
        if not value then
            for player, _ in pairs(State.ESPObjects) do
                ESP.HideESP(player)
            end
        end
        print("[ESP] " .. (value and "Enabled" or "Disabled"))
    end, 1)
    
    GUI.CreateToggle(section, "Show Boxes", Config.ESPBoxes, function(value)
        Config.ESPBoxes = value
    end, 2)
    
    GUI.CreateToggle(section, "Show Names", Config.ESPNames, function(value)
        Config.ESPNames = value
    end, 3)
    
    GUI.CreateToggle(section, "Show Distance", Config.ESPDistance, function(value)
        Config.ESPDistance = value
    end, 4)
    
    GUI.CreateToggle(section, "Show Health", Config.ESPHealth, function(value)
        Config.ESPHealth = value
    end, 5)
    
    GUI.CreateToggle(section, "Show Tracers", Config.ESPTracers, function(value)
        Config.ESPTracers = value
    end, 6)
    
    GUI.CreateToggle(section, "Team Colors", Config.ESPTeamColor, function(value)
        Config.ESPTeamColor = value
    end, 7)
    
    GUI.CreateSlider(section, "Max Distance", 100, 3000, Config.ESPMaxDistance, function(value)
        Config.ESPMaxDistance = value
    end, 8)
end

function GUI.CreateMiscSettings(parent)
    local section = GUI.CreateSection(parent, "⚙️ Misc Settings", 7)
    
    GUI.CreateToggle(section, "Infinite Jump", Config.InfiniteJumpEnabled, function(value)
        Config.InfiniteJumpEnabled = value
        print("[Infinite Jump] " .. (value and "Enabled" or "Disabled"))
    end, 1)
end

function GUI.CreateVisualSettings(parent)
    local section = GUI.CreateSection(parent, "🎨 Visual Settings", 8)
    
    GUI.CreateToggle(section, "Show FOV Circle", Config.ShowFOV, function(value)
        Config.ShowFOV = value
        if State.FOVCircle then
            State.FOVCircle.Visible = value and Config.Active
        end
    end, 1)
end

function GUI.CreatePerformanceDisplay(parent)
    local section = GUI.CreateSection(parent, "📊 Performance", 9)
    
    local perfFrame = Instance.new("Frame")
    perfFrame.Size = UDim2.new(1, 0, 0, 60)
    perfFrame.BackgroundColor3 = Config.Theme.Primary
    perfFrame.BorderSizePixel = 0
    perfFrame.LayoutOrder = 1
    perfFrame.Parent = section
    
    Utils.CreateCorner(perfFrame, 6)
    
    local perfLayout = Instance.new("UIListLayout")
    perfLayout.Padding = UDim.new(0, 4)
    perfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    perfLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    perfLayout.Parent = perfFrame
    
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, -10, 0, 18)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 60"
    fpsLabel.Font = Enum.Font.GothamMedium
    fpsLabel.TextSize = 12
    fpsLabel.TextColor3 = Config.Theme.TextDark
    fpsLabel.Parent = perfFrame
    
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(1, -10, 0, 18)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "Targets: 0"
    targetLabel.Font = Enum.Font.GothamMedium
    targetLabel.TextSize = 12
    targetLabel.TextColor3 = Config.Theme.TextDark
    targetLabel.Parent = perfFrame
    
    GUI.PerformanceLabels = {
        FPS = fpsLabel,
        Targets = targetLabel
    }
end

function GUI.CreateFooter(parent)
    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 60)
    footer.Position = UDim2.new(0, 0, 1, -60)
    footer.BackgroundColor3 = Config.Theme.Secondary
    footer.BorderSizePixel = 0
    footer.Parent = parent
    
    Utils.CreateCorner(footer, 12)
    
    local warning = Instance.new("TextLabel")
    warning.Size = UDim2.new(1, -20, 1, -10)
    warning.Position = UDim2.new(0, 10, 0, 5)
    warning.BackgroundTransparency = 1
    warning.Text = "⚠️ Educational Use Only\nDo not use to violate ToS or harm others"
    warning.Font = Enum.Font.Gotham
    warning.TextSize = 10
    warning.TextColor3 = Config.Theme.TextDark
    warning.TextWrapped = true
    warning.Parent = footer
end

function GUI.UpdatePerformance()
    if not GUI.PerformanceLabels then return end
    
    local fps = math.floor(1 / (tick() - State.LastUpdate))
    State.Performance.FPS = fps
    State.LastUpdate = tick()
    
    GUI.PerformanceLabels.FPS.Text = "FPS: " .. fps
    GUI.PerformanceLabels.Targets.Text = "Targets: " .. State.Performance.TargetCount
end

function GUI.Destroy()
    for _, connection in ipairs(State.Connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    
    DrawingManager.Cleanup()
    ESP.Cleanup()
    
    if GUI.ScreenGui then
        GUI.ScreenGui:Destroy()
    end
    
    print("[Camera Assist] System shutdown complete")
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local MainLoop = {}

function MainLoop.Initialize()
    -- Check if key system is enabled
    if KeySystem.Enabled and not KeySystem.Authenticated then
        print("[Key System] Authentication required")
        GUI.CreateKeySystem()
        return
    end
    
    -- Only initialize if authenticated or key system disabled
    GUI.Create()
    ESP.Initialize()
    InfiniteJump.Initialize()
    
    local renderConnection = RunService.RenderStepped:Connect(function()
        if Config.Active then
            DrawingManager.UpdateFOV()
            
            local target = TargetSystem.GetClosestTarget()
            State.CurrentTarget = target
            
            if target then
                TargetSystem.AimAtTarget(target)
                DrawingManager.UpdateTargetIndicator(target.ScreenPosition)
            else
                DrawingManager.UpdateTargetIndicator(nil)
            end
        end
        
        if Config.ESPEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    ESP.UpdateESP(player)
                end
            end
        end
    end)
    
    table.insert(State.Connections, renderConnection)
    
    local perfConnection = RunService.Heartbeat:Connect(function()
        GUI.UpdatePerformance()
    end)
    
    table.insert(State.Connections, perfConnection)
    
    print("[Camera Assist] System initialized successfully")
    print("[Camera Assist] Version: " .. Config.Version)
    print("[Camera Assist] Features: Prediction + ESP + Infinite Jump")
end

-- ============================================================
-- STARTUP
-- ============================================================
print("═══════════════════════════════════════════════════════════")
print("  CAMERA ASSIST FRAMEWORK - PROFESSIONAL EDITION")
print("  Version: " .. Config.Version)
print("  Features: Key System + Prediction + ESP + Infinite Jump")
print("═══════════════════════════════════════════════════════════")

if KeySystem.Enabled then
    print("[Key System] Please enter your key to continue")
end

MainLoop.Initialize()
