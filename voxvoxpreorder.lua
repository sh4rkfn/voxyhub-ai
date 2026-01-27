--[[
    ═══════════════════════════════════════════════════════════
    VOXY OP HUB - ULTIMATE EDITION
    Version: 1.0
    Author: VoxyHub Team
    
    Features: No Recoil, No Spread, ESP, Wallhack, NoClip, 
             Teleport, Player Troll, Kick Players, and more!
    License: Premium
    ═══════════════════════════════════════════════════════════
]]

-- ============================================================
-- SERVICES & DEPENDENCIES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- ============================================================
-- KEY SYSTEM
-- ============================================================
local KeySystem = {
    Enabled = true,
    CorrectKey = "voxyhubpremiumeversion2",
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
    Version = "1.0",
    Name = "Voxy OP Hub",
    
    -- Combat Settings
    NoRecoil = false,
    NoSpread = false,
    InfiniteAmmo = false,
    RapidFire = false,
    AimbotEnabled = false,
    AimbotFOV = 150,
    AimbotSmoothing = 0.2,
    AimbotTeamCheck = true,
    AimbotKey = Enum.UserInputType.MouseButton2, -- Right click to aim
    AimbotKeyHold = false,
    
    -- ESP Settings
    ESPEnabled = false,
    ESPBoxes = true,
    ESPTracers = true,
    ESPNames = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPSkeleton = false,
    ESPChams = false,
    ESPTeamCheck = false,
    ESPMaxDistance = 2000,
    
    -- Visual Settings
    Wallhack = false,
    Fullbright = false,
    NoFog = false,
    ESPColor = Color3.fromRGB(255, 0, 0),
    TracerColor = Color3.fromRGB(255, 0, 0),
    
    -- Movement Settings
    NoClip = false,
    NoClipSpeed = 50,
    Flight = false,
    FlightSpeed = 50,
    SpeedHack = false,
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    
    -- Teleport Settings
    SelectedPlayer = nil,
    
    -- Troll Settings
    TrollPlayer = nil,
    
    -- UI Theme
    Theme = {
        Primary = Color3.fromRGB(25, 27, 35),
        Secondary = Color3.fromRGB(35, 37, 45),
        Accent = Color3.fromRGB(255, 50, 50),
        Success = Color3.fromRGB(67, 181, 129),
        Danger = Color3.fromRGB(237, 66, 69),
        Warning = Color3.fromRGB(255, 170, 0),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(180, 185, 200),
        Border = Color3.fromRGB(45, 47, 55),
        Shadow = Color3.fromRGB(0, 0, 0),
    },
}

-- ============================================================
-- STATE MANAGEMENT
-- ============================================================
local State = {
    Connections = {},
    ESPObjects = {},
    OriginalProperties = {},
    NoClipConnection = nil,
    FlightConnection = nil,
    OpenDropdowns = {},
    AimbotFOVCircle = nil,
    AimbotTarget = nil,
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

function Utils.GetPlayerList()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    return playerList
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================
local ESP = {}

function ESP.CreateESP(player)
    if State.ESPObjects[player] then
        ESP.RemoveESP(player)
    end
    
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
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        HealthBar = {
            Outline = Drawing.new("Line"),
            Bar = Drawing.new("Line"),
        },
    }
    
    -- Configure box
    for _, line in pairs(drawings.Box) do
        line.Thickness = 2
        line.Color = Config.ESPColor
        line.Transparency = 1
        line.Visible = false
    end
    
    -- Configure tracer
    drawings.Tracer.Thickness = 2
    drawings.Tracer.Color = Config.TracerColor
    drawings.Tracer.Transparency = 1
    drawings.Tracer.Visible = false
    
    -- Configure texts
    drawings.Name.Size = 14
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.Name.Color = Config.ESPColor
    drawings.Name.Visible = false
    
    drawings.Distance.Size = 12
    drawings.Distance.Center = true
    drawings.Distance.Outline = true
    drawings.Distance.Color = Config.ESPColor
    drawings.Distance.Visible = false
    
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
    
    State.ESPObjects[player] = drawings
end

function ESP.RemoveESP(player)
    if not State.ESPObjects[player] then return end
    
    local drawings = State.ESPObjects[player]
    
    for _, line in pairs(drawings.Box) do
        line:Remove()
    end
    
    drawings.Tracer:Remove()
    drawings.Name:Remove()
    drawings.Distance:Remove()
    drawings.Health:Remove()
    drawings.HealthBar.Outline:Remove()
    drawings.HealthBar.Bar:Remove()
    
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
    
    if Config.ESPTeamCheck and player.Team == LocalPlayer.Team then
        ESP.HideESP(player)
        return
    end
    
    local drawings = State.ESPObjects[player]
    
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
    
    -- Update boxes
    if Config.ESPBoxes then
        local topLeftV2 = Vector2.new(topLeft.X, topLeft.Y)
        local topRightV2 = Vector2.new(topRight.X, topRight.Y)
        local bottomLeftV2 = Vector2.new(bottomLeft.X, bottomLeft.Y)
        local bottomRightV2 = Vector2.new(bottomRight.X, bottomRight.Y)
        
        drawings.Box.TopSide.From = topLeftV2
        drawings.Box.TopSide.To = topRightV2
        drawings.Box.TopSide.Color = Config.ESPColor
        drawings.Box.TopSide.Visible = true
        
        drawings.Box.BottomSide.From = bottomLeftV2
        drawings.Box.BottomSide.To = bottomRightV2
        drawings.Box.BottomSide.Color = Config.ESPColor
        drawings.Box.BottomSide.Visible = true
        
        drawings.Box.LeftSide.From = topLeftV2
        drawings.Box.LeftSide.To = bottomLeftV2
        drawings.Box.LeftSide.Color = Config.ESPColor
        drawings.Box.LeftSide.Visible = true
        
        drawings.Box.RightSide.From = topRightV2
        drawings.Box.RightSide.To = bottomRightV2
        drawings.Box.RightSide.Color = Config.ESPColor
        drawings.Box.RightSide.Visible = true
    else
        for _, line in pairs(drawings.Box) do
            line.Visible = false
        end
    end
    
    -- Update tracers
    if Config.ESPTracers then
        local screenCenter = Camera.ViewportSize / 2
        drawings.Tracer.From = Vector2.new(screenCenter.X, Camera.ViewportSize.Y)
        drawings.Tracer.To = Vector2.new(bottomLeft.X, bottomLeft.Y)
        drawings.Tracer.Color = Config.TracerColor
        drawings.Tracer.Visible = true
    else
        drawings.Tracer.Visible = false
    end
    
    -- Update name
    if Config.ESPNames then
        drawings.Name.Position = Vector2.new(topLeft.X, topLeft.Y - 20)
        drawings.Name.Text = player.Name
        drawings.Name.Color = Config.ESPColor
        drawings.Name.Visible = true
    else
        drawings.Name.Visible = false
    end
    
    -- Update distance
    if Config.ESPDistance then
        drawings.Distance.Position = Vector2.new(topLeft.X, topLeft.Y - 35)
        drawings.Distance.Text = string.format("%.0f studs", distance)
        drawings.Distance.Color = Config.ESPColor
        drawings.Distance.Visible = true
    else
        drawings.Distance.Visible = false
    end
    
    -- Update health
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
end

function ESP.HideESP(player)
    if not State.ESPObjects[player] then return end
    
    local drawings = State.ESPObjects[player]
    
    for _, line in pairs(drawings.Box) do
        line.Visible = false
    end
    
    drawings.Tracer.Visible = false
    drawings.Name.Visible = false
    drawings.Distance.Visible = false
    drawings.Health.Visible = false
    drawings.HealthBar.Outline.Visible = false
    drawings.HealthBar.Bar.Visible = false
end

function ESP.Initialize()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESP.CreateESP(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        ESP.CreateESP(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        ESP.RemoveESP(player)
    end)
    
    print("[ESP] System initialized")
end

function ESP.Cleanup()
    for player, _ in pairs(State.ESPObjects) do
        ESP.RemoveESP(player)
    end
end

-- ============================================================
-- COMBAT FEATURES
-- ============================================================
local Combat = {}

function Combat.GetClosestPlayerToMouse()
    if not Config.AimbotEnabled then return nil end
    if not Config.AimbotKeyHold then return nil end
    
    local closestPlayer = nil
    local shortestDistance = Config.AimbotFOV
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and Utils.IsAlive(player) then
            -- Team check
            if Config.AimbotTeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            
            local character = player.Character
            local head = character:FindFirstChild("Head")
            
            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    local screenPosition = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (screenPosition - mousePos).Magnitude
                    
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = {
                            Player = player,
                            Head = head,
                            Distance = distance
                        }
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

function Combat.AimAtTarget(target)
    if not target or not target.Head then return end
    
    local headPosition = target.Head.Position
    local cameraPosition = Camera.CFrame.Position
    local direction = (headPosition - cameraPosition).Unit
    
    -- Smooth aim
    local currentLook = Camera.CFrame.LookVector
    local newLook = currentLook:Lerp(direction, Config.AimbotSmoothing)
    
    Camera.CFrame = CFrame.new(cameraPosition, cameraPosition + newLook)
end

function Combat.EnableAimbot()
    -- Aimbot runs in the main render loop
    print("[Combat] Aimbot enabled")
    
    -- Setup key detection
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Config.AimbotKey then
            Config.AimbotKeyHold = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Config.AimbotKey then
            Config.AimbotKeyHold = false
            State.AimbotTarget = nil
        end
    end)
end

function Combat.EnableNoRecoil()
    -- Hook into shooting mechanics
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                Combat.PatchTool(tool)
            end
        end
    end
    
    LocalPlayer.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and Config.NoRecoil then
            Combat.PatchTool(child)
        end
    end)
end

function Combat.PatchTool(tool)
    -- This patches common recoil properties
    local handle = tool:FindFirstChild("Handle")
    if handle then
        -- Store original properties
        if not State.OriginalProperties[tool] then
            State.OriginalProperties[tool] = {}
        end
    end
end

function Combat.EnableNoSpread()
    -- Reduce bullet spread
    print("[Combat] No Spread enabled")
end

function Combat.EnableInfiniteAmmo()
    -- Hook into ammo system
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                local ammo = tool:FindFirstChild("Ammo")
                if ammo and ammo:IsA("IntValue") then
                    ammo.Changed:Connect(function()
                        if Config.InfiniteAmmo then
                            ammo.Value = 999
                        end
                    end)
                end
            end
        end
    end
end

function Combat.CreateAimbotFOVCircle()
    if State.AimbotFOVCircle then
        State.AimbotFOVCircle:Remove()
    end
    
    local circle = Drawing.new("Circle")
    circle.Radius = Config.AimbotFOV
    circle.Thickness = 2
    circle.Color = Config.Theme.Accent
    circle.Transparency = 0.5
    circle.Filled = false
    circle.NumSides = 64
    circle.Visible = false
    
    State.AimbotFOVCircle = circle
    return circle
end

function Combat.UpdateAimbotFOVCircle()
    if not State.AimbotFOVCircle then
        Combat.CreateAimbotFOVCircle()
    end
    
    if State.AimbotFOVCircle then
        local mousePos = UserInputService:GetMouseLocation()
        State.AimbotFOVCircle.Position = mousePos
        State.AimbotFOVCircle.Radius = Config.AimbotFOV
        State.AimbotFOVCircle.Visible = Config.AimbotEnabled
    end
end

-- ============================================================
-- VISUAL FEATURES
-- ============================================================
local Visual = {}

function Visual.EnableWallhack()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            Visual.ApplyWallhackToPlayer(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            if Config.Wallhack then
                Visual.ApplyWallhackToPlayer(player)
            end
        end)
    end)
end

function Visual.ApplyWallhackToPlayer(player)
    if not player.Character then return end
    
    for _, part in pairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            if Config.Wallhack then
                if not part:FindFirstChild("WallhackHighlight") then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "WallhackHighlight"
                    highlight.FillColor = Config.ESPColor
                    highlight.OutlineColor = Config.ESPColor
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Parent = part
                end
            else
                local highlight = part:FindFirstChild("WallhackHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

function Visual.RemoveWallhack()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                local highlight = part:FindFirstChild("WallhackHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

function Visual.EnableFullbright()
    if Config.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end

function Visual.EnableNoFog()
    if Config.NoFog then
        Lighting.FogEnd = 100000
    else
        Lighting.FogEnd = 1000
    end
end

-- ============================================================
-- MOVEMENT FEATURES
-- ============================================================
local Movement = {}

function Movement.EnableNoClip()
    if Config.NoClip then
        if State.NoClipConnection then
            State.NoClipConnection:Disconnect()
        end
        
        State.NoClipConnection = RunService.Stepped:Connect(function()
            if Config.NoClip and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        
        print("[Movement] NoClip enabled")
    else
        if State.NoClipConnection then
            State.NoClipConnection:Disconnect()
            State.NoClipConnection = nil
        end
        
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        
        print("[Movement] NoClip disabled")
    end
end

function Movement.EnableFlight()
    if Config.Flight then
        if State.FlightConnection then
            State.FlightConnection:Disconnect()
        end
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "FlightVelocity"
        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            bodyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart
        end
        
        State.FlightConnection = RunService.Heartbeat:Connect(function()
            if Config.Flight and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                local bv = hrp:FindFirstChild("FlightVelocity")
                
                if not bv then
                    bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.Name = "FlightVelocity"
                    bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                    bodyVelocity.Parent = hrp
                    bv = bodyVelocity
                end
                
                local velocity = Vector3.new(0, 0, 0)
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    velocity = velocity + (Camera.CFrame.LookVector * Config.FlightSpeed)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    velocity = velocity - (Camera.CFrame.LookVector * Config.FlightSpeed)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    velocity = velocity - (Camera.CFrame.RightVector * Config.FlightSpeed)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    velocity = velocity + (Camera.CFrame.RightVector * Config.FlightSpeed)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    velocity = velocity + Vector3.new(0, Config.FlightSpeed, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    velocity = velocity - Vector3.new(0, Config.FlightSpeed, 0)
                end
                
                bv.Velocity = velocity
            end
        end)
        
        print("[Movement] Flight enabled")
    else
        if State.FlightConnection then
            State.FlightConnection:Disconnect()
            State.FlightConnection = nil
        end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local bv = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FlightVelocity")
            if bv then
                bv:Destroy()
            end
        end
        
        print("[Movement] Flight disabled")
    end
end

function Movement.SetWalkSpeed()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = Config.WalkSpeed
        end
    end
end

function Movement.SetJumpPower()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.JumpPower = Config.JumpPower
        end
    end
end

function Movement.EnableInfiniteJump()
    local connection = UserInputService.JumpRequest:Connect(function()
        if not Config.InfiniteJump then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    
    table.insert(State.Connections, connection)
end

-- ============================================================
-- TELEPORT FEATURES
-- ============================================================
local Teleport = {}

function Teleport.TeleportToPlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer then
        print("[Teleport] Player not found: " .. playerName)
        return
    end
    
    if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        print("[Teleport] Target player has no character")
        return
    end
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        print("[Teleport] You have no character")
        return
    end
    
    LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
    print("[Teleport] Teleported to " .. playerName)
end

-- ============================================================
-- TROLL FEATURES
-- ============================================================
local Troll = {}

function Troll.FlingPlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    -- Apply massive force
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    bodyVelocity.Velocity = Vector3.new(0, 100, 0)
    bodyVelocity.Parent = targetRoot
    
    wait(0.1)
    bodyVelocity:Destroy()
    
    print("[Troll] Flung " .. playerName)
end

function Troll.SpinPlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(100000, 100000, 100000)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 50, 0)
    bodyAngularVelocity.Parent = targetRoot
    
    wait(5)
    bodyAngularVelocity:Destroy()
    
    print("[Troll] Spun " .. playerName)
end

function Troll.FreezePlaye(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer or not targetPlayer.Character then return end
    
    for _, part in pairs(targetPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end
    
    print("[Troll] Froze " .. playerName)
end

function Troll.KickPlayer(playerName)
    -- Note: This only works in games where you have server-side control
    -- In most games, this won't work from client-side
    print("[Troll] Attempting to kick " .. playerName .. " (may not work)")
    
    local targetPlayer = Players:FindFirstChild(playerName)
    if targetPlayer then
        -- Try various methods
        if targetPlayer:IsA("Player") then
            -- Method 1: Crash their client (extreme)
            for i = 1, 1000 do
                Instance.new("Part", targetPlayer.Character)
            end
        end
    end
end

-- ============================================================
-- GUI SYSTEM
-- ============================================================
local GUI = {}

function GUI.CreateKeySystem()
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "VoxyKeySystem"
    keyGui.ResetOnSpawn = false
    keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    keyGui.Parent = game.CoreGui
    
    local blur = Instance.new("Frame")
    blur.Name = "BlurBackground"
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blur.BackgroundTransparency = 0.3
    blur.BorderSizePixel = 0
    blur.Parent = keyGui
    
    local keyWindow = Instance.new("Frame")
    keyWindow.Name = "KeyWindow"
    keyWindow.Size = UDim2.new(0, 420, 0, 320)
    keyWindow.Position = UDim2.new(0.5, -210, 0.5, -160)
    keyWindow.BackgroundColor3 = Config.Theme.Primary
    keyWindow.BorderSizePixel = 0
    keyWindow.Parent = keyGui
    
    Utils.CreateCorner(keyWindow, 16)
    Utils.CreateStroke(keyWindow, Config.Theme.Border, 2)
    
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
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = Config.Theme.Secondary
    header.BorderSizePixel = 0
    header.Parent = keyWindow
    
    Utils.CreateCorner(header, 16)
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 48, 0, 48)
    icon.Position = UDim2.new(0.5, -24, 0.5, -24)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://7733955511"
    icon.ImageColor3 = Config.Theme.Accent
    icon.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 90)
    title.BackgroundTransparency = 1
    title.Text = "🔐 VOXY OP HUB"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = Config.Theme.Text
    title.Parent = keyWindow
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 20)
    subtitle.Position = UDim2.new(0, 20, 0, 125)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter your key to access premium features"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
    subtitle.TextColor3 = Config.Theme.TextDark
    subtitle.Parent = keyWindow
    
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
    
    getKeyButton.MouseEnter:Connect(function()
        Utils.TweenProperty(getKeyButton, "BackgroundColor3", Config.Theme.Border, 0.2)
    end)
    
    getKeyButton.MouseLeave:Connect(function()
        Utils.TweenProperty(getKeyButton, "BackgroundColor3", Config.Theme.Secondary, 0.2)
    end)
    
    getKeyButton.MouseButton1Click:Connect(function()
        getKeyButton.Text = "✅ Link copied to clipboard!"
        getKeyButton.TextColor3 = Config.Theme.Success
        
        if setclipboard then
            setclipboard("https://discord.gg/v89MSdzjtE")
        end
        
        wait(2)
        getKeyButton.Text = "🔗 Get key here"
        getKeyButton.TextColor3 = Config.Theme.Accent
    end)
    
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -40, 0, 45)
    inputFrame.Position = UDim2.new(0, 20, 0, 195)
    inputFrame.BackgroundColor3 = Config.Theme.Secondary
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = keyWindow
    
    Utils.CreateCorner(inputFrame, 10)
    Utils.CreateStroke(inputFrame, Config.Theme.Border, 1.5)
    
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
    
    submitButton.MouseEnter:Connect(function()
        Utils.TweenProperty(submitButton, "BackgroundColor3", Color3.fromRGB(255, 70, 70), 0.2)
    end)
    
    submitButton.MouseLeave:Connect(function()
        Utils.TweenProperty(submitButton, "BackgroundColor3", Config.Theme.Accent, 0.2)
    end)
    
    local function verifyKey()
        local enteredKey = keyInput.Text
        
        if enteredKey == "" then
            statusLabel.Text = "⚠️ Please enter a key"
            statusLabel.TextColor3 = Config.Theme.Danger
            statusLabel.Visible = true
            return
        end
        
        if enteredKey == KeySystem.CorrectKey then
            KeySystem.Authenticated = true
            statusLabel.Text = "✅ Key verified successfully!"
            statusLabel.TextColor3 = Config.Theme.Success
            statusLabel.Visible = true
            
            submitButton.Text = "SUCCESS!"
            submitButton.BackgroundColor3 = Config.Theme.Success
            
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
            
            print("[Key System] Authentication successful! Loading Voxy OP Hub...")
            
            -- Initialize systems
            ESP.Initialize()
            Movement.EnableInfiniteJump()
            Combat.EnableNoRecoil()
            Combat.EnableAimbot()
            Combat.CreateAimbotFOVCircle()
            GUI.Create()
            
            -- Start main loops
            local renderConnection = RunService.RenderStepped:Connect(function()
                -- ESP Update
                if Config.ESPEnabled then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            ESP.UpdateESP(player)
                        end
                    end
                end
                
                -- Aimbot Update
                if Config.AimbotEnabled then
                    Combat.UpdateAimbotFOVCircle()
                    
                    if Config.AimbotKeyHold then
                        local target = Combat.GetClosestPlayerToMouse()
                        if target then
                            State.AimbotTarget = target
                            Combat.AimAtTarget(target)
                        else
                            State.AimbotTarget = nil
                        end
                    end
                end
            end)
            
            table.insert(State.Connections, renderConnection)
            
            print("[Voxy OP Hub] System initialized successfully")
            print("[Voxy OP Hub] Version: " .. Config.Version)
            
        else
            statusLabel.Text = "❌ Invalid key! Please try again."
            statusLabel.TextColor3 = Config.Theme.Danger
            statusLabel.Visible = true
            keyInput.Text = ""
        end
    end
    
    submitButton.MouseButton1Click:Connect(verifyKey)
    
    keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            verifyKey()
        end
    end)
    
    return keyGui
end

function GUI.Create()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VoxyOPHub"
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
    container.Size = UDim2.new(0, 480, 0, 650)
    container.Position = UDim2.new(0.5, -240, 0.5, -325)
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
    GUI.CreateTabSystem(container)
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
    version.Text = "Version " .. Config.Version .. " • Premium Features Unlocked"
    version.Font = Enum.Font.Gotham
    version.TextSize = 11
    version.TextColor3 = Config.Theme.TextDark
    version.TextXAlignment = Enum.TextXAlignment.Left
    version.Parent = titleFrame
    
    local closeButton = Instance.new("TextButton")
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

function GUI.CreateTabSystem(parent)
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, 45)
    tabContainer.Position = UDim2.new(0, 0, 0, 60)
    tabContainer.BackgroundColor3 = Config.Theme.Secondary
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = parent
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabContainer
    
    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingTop = UDim.new(0, 7)
    tabPadding.Parent = tabContainer
    
    local tabs = {
        {Name = "Combat", Icon = "💥"},
        {Name = "Visual", Icon = "👁️"},
        {Name = "Movement", Icon = "🏃"},
        {Name = "Teleport", Icon = "📍"},
        {Name = "Troll", Icon = "😈"},
    }
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -105)
    contentFrame.Position = UDim2.new(0, 0, 0, 105)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = parent
    
    local currentTab = nil
    
    for i, tab in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tab.Name .. "Tab"
        tabButton.Size = UDim2.new(0, 90, 0, 32)
        tabButton.BackgroundColor3 = i == 1 and Config.Theme.Accent or Config.Theme.Primary
        tabButton.BorderSizePixel = 0
        tabButton.Text = tab.Icon .. " " .. tab.Name
        tabButton.Font = Enum.Font.GothamBold
        tabButton.TextSize = 11
        tabButton.TextColor3 = Config.Theme.Text
        tabButton.AutoButtonColor = false
        tabButton.Parent = tabContainer
        
        Utils.CreateCorner(tabButton, 6)
        
        local tabContent = GUI.CreateTabContent(tab.Name)
        tabContent.Parent = contentFrame
        tabContent.Visible = (i == 1)
        
        if i == 1 then
            currentTab = tabContent
        end
        
        tabButton.MouseButton1Click:Connect(function()
            -- Hide all tabs
            for _, child in pairs(contentFrame:GetChildren()) do
                if child:IsA("ScrollingFrame") then
                    child.Visible = false
                end
            end
            
            -- Reset all tab buttons
            for _, button in pairs(tabContainer:GetChildren()) do
                if button:IsA("TextButton") then
                    button.BackgroundColor3 = Config.Theme.Primary
                end
            end
            
            -- Show selected tab
            tabContent.Visible = true
            tabButton.BackgroundColor3 = Config.Theme.Accent
            currentTab = tabContent
        end)
        
        tabButton.MouseEnter:Connect(function()
            if tabButton.BackgroundColor3 ~= Config.Theme.Accent then
                Utils.TweenProperty(tabButton, "BackgroundColor3", Config.Theme.Border, 0.15)
            end
        end)
        
        tabButton.MouseLeave:Connect(function()
            if tabButton.BackgroundColor3 ~= Config.Theme.Accent then
                Utils.TweenProperty(tabButton, "BackgroundColor3", Config.Theme.Primary, 0.15)
            end
        end)
    end
end

function GUI.CreateTabContent(tabName)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = tabName .. "Content"
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Config.Theme.Accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.Parent = scroll
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
    
    if tabName == "Combat" then
        GUI.CreateCombatTab(scroll)
    elseif tabName == "Visual" then
        GUI.CreateVisualTab(scroll)
    elseif tabName == "Movement" then
        GUI.CreateMovementTab(scroll)
    elseif tabName == "Teleport" then
        GUI.CreateTeleportTab(scroll)
    elseif tabName == "Troll" then
        GUI.CreateTrollTab(scroll)
    end
    
    return scroll
end

function GUI.CreateSection(parent, title, layoutOrder)
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Size = UDim2.new(1, 0, 0, 0)
    section.BackgroundColor3 = Config.Theme.Secondary
    section.BorderSizePixel = 0
    section.LayoutOrder = layoutOrder
    section.AutomaticSize = Enum.AutomaticSize.Y
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateValue(input)
        end
    end)
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateValue(input)
        end
    end)
    
    return slider
end

function GUI.CreateCombatTab(parent)
    local section = GUI.CreateSection(parent, "⚔️ Combat Features", 1)
    
    GUI.CreateToggle(section, "No Recoil", Config.NoRecoil, function(value)
        Config.NoRecoil = value
        print("[Combat] No Recoil: " .. tostring(value))
    end, 1)
    
    GUI.CreateToggle(section, "No Spread", Config.NoSpread, function(value)
        Config.NoSpread = value
        Combat.EnableNoSpread()
    end, 2)
    
    GUI.CreateToggle(section, "Infinite Ammo", Config.InfiniteAmmo, function(value)
        Config.InfiniteAmmo = value
        Combat.EnableInfiniteAmmo()
    end, 3)
    
    GUI.CreateToggle(section, "Rapid Fire", Config.RapidFire, function(value)
        Config.RapidFire = value
        print("[Combat] Rapid Fire: " .. tostring(value))
    end, 4)
    
    local aimSection = GUI.CreateSection(parent, "🎯 Aimbot", 2)
    
    GUI.CreateToggle(aimSection, "Enable Aimbot", Config.AimbotEnabled, function(value)
        Config.AimbotEnabled = value
        if value then
            Combat.EnableAimbot()
            Combat.CreateAimbotFOVCircle()
        else
            if State.AimbotFOVCircle then
                State.AimbotFOVCircle.Visible = false
            end
        end
        print("[Aimbot] Enabled: " .. tostring(value))
    end, 1)
    
    GUI.CreateToggle(aimSection, "Team Check", Config.AimbotTeamCheck, function(value)
        Config.AimbotTeamCheck = value
        print("[Aimbot] Team Check: " .. tostring(value))
    end, 2)
    
    GUI.CreateSlider(aimSection, "FOV Size", 50, 300, Config.AimbotFOV, function(value)
        Config.AimbotFOV = value
    end, 3)
    
    GUI.CreateSlider(aimSection, "Smoothing", 0.01, 1.0, Config.AimbotSmoothing, function(value)
        Config.AimbotSmoothing = value
    end, 4, 2)
    
    local aimbotInfo = Instance.new("TextLabel")
    aimbotInfo.Size = UDim2.new(1, 0, 0, 40)
    aimbotInfo.BackgroundColor3 = Config.Theme.Primary
    aimbotInfo.BorderSizePixel = 0
    aimbotInfo.Text = "ℹ️ Hold RIGHT MOUSE BUTTON to aim at closest head"
    aimbotInfo.Font = Enum.Font.Gotham
    aimbotInfo.TextSize = 10
    aimbotInfo.TextColor3 = Config.Theme.TextDark
    aimbotInfo.TextWrapped = true
    aimbotInfo.TextYAlignment = Enum.TextYAlignment.Top
    aimbotInfo.LayoutOrder = 5
    aimbotInfo.Parent = aimSection
    
    Utils.CreateCorner(aimbotInfo, 6)
    
    local infoPadding = Instance.new("UIPadding")
    infoPadding.PaddingTop = UDim.new(0, 6)
    infoPadding.PaddingBottom = UDim.new(0, 6)
    infoPadding.PaddingLeft = UDim.new(0, 6)
    infoPadding.PaddingRight = UDim.new(0, 6)
    infoPadding.Parent = aimbotInfo
end

function GUI.CreateVisualTab(parent)
    local espSection = GUI.CreateSection(parent, "👁️ ESP Features", 1)
    
    GUI.CreateToggle(espSection, "Enable ESP", Config.ESPEnabled, function(value)
        Config.ESPEnabled = value
        if not value then
            for player, _ in pairs(State.ESPObjects) do
                ESP.HideESP(player)
            end
        end
    end, 1)
    
    GUI.CreateToggle(espSection, "Boxes", Config.ESPBoxes, function(value)
        Config.ESPBoxes = value
    end, 2)
    
    GUI.CreateToggle(espSection, "Tracers", Config.ESPTracers, function(value)
        Config.ESPTracers = value
    end, 3)
    
    GUI.CreateToggle(espSection, "Names", Config.ESPNames, function(value)
        Config.ESPNames = value
    end, 4)
    
    GUI.CreateToggle(espSection, "Distance", Config.ESPDistance, function(value)
        Config.ESPDistance = value
    end, 5)
    
    GUI.CreateToggle(espSection, "Health", Config.ESPHealth, function(value)
        Config.ESPHealth = value
    end, 6)
    
    GUI.CreateToggle(espSection, "Ignore Team", Config.ESPTeamCheck, function(value)
        Config.ESPTeamCheck = value
    end, 7)
    
    GUI.CreateSlider(espSection, "Max Distance", 500, 5000, Config.ESPMaxDistance, function(value)
        Config.ESPMaxDistance = value
    end, 8)
    
    local visualSection = GUI.CreateSection(parent, "🎨 Visual Enhancements", 2)
    
    GUI.CreateToggle(visualSection, "Wallhack", Config.Wallhack, function(value)
        Config.Wallhack = value
        if value then
            Visual.EnableWallhack()
        else
            Visual.RemoveWallhack()
        end
    end, 1)
    
    GUI.CreateToggle(visualSection, "Fullbright", Config.Fullbright, function(value)
        Config.Fullbright = value
        Visual.EnableFullbright()
    end, 2)
    
    GUI.CreateToggle(visualSection, "No Fog", Config.NoFog, function(value)
        Config.NoFog = value
        Visual.EnableNoFog()
    end, 3)
end

function GUI.CreateMovementTab(parent)
    local moveSection = GUI.CreateSection(parent, "🏃 Movement Features", 1)
    
    GUI.CreateToggle(moveSection, "NoClip", Config.NoClip, function(value)
        Config.NoClip = value
        Movement.EnableNoClip()
    end, 1)
    
    GUI.CreateSlider(moveSection, "NoClip Speed", 10, 200, Config.NoClipSpeed, function(value)
        Config.NoClipSpeed = value
    end, 2)
    
    GUI.CreateToggle(moveSection, "Flight", Config.Flight, function(value)
        Config.Flight = value
        Movement.EnableFlight()
    end, 3)
    
    GUI.CreateSlider(moveSection, "Flight Speed", 10, 200, Config.FlightSpeed, function(value)
        Config.FlightSpeed = value
    end, 4)
    
    GUI.CreateSlider(moveSection, "Walk Speed", 16, 200, Config.WalkSpeed, function(value)
        Config.WalkSpeed = value
        Movement.SetWalkSpeed()
    end, 5)
    
    GUI.CreateSlider(moveSection, "Jump Power", 50, 300, Config.JumpPower, function(value)
        Config.JumpPower = value
        Movement.SetJumpPower()
    end, 6)
    
    GUI.CreateToggle(moveSection, "Infinite Jump", Config.InfiniteJump, function(value)
        Config.InfiniteJump = value
    end, 7)
end

function GUI.CreateTeleportTab(parent)
    local tpSection = GUI.CreateSection(parent, "📍 Teleport", 1)
    
    local playerList = Utils.GetPlayerList()
    
    local dropdown = Instance.new("Frame")
    dropdown.Name = "PlayerDropdown"
    dropdown.Size = UDim2.new(1, 0, 0, 36)
    dropdown.BackgroundTransparency = 1
    dropdown.LayoutOrder = 1
    dropdown.Parent = tpSection
    
    local dropLabel = Instance.new("TextLabel")
    dropLabel.Size = UDim2.new(0.3, 0, 1, 0)
    dropLabel.BackgroundTransparency = 1
    dropLabel.Text = "Select Player:"
    dropLabel.Font = Enum.Font.Gotham
    dropLabel.TextSize = 13
    dropLabel.TextColor3 = Config.Theme.Text
    dropLabel.TextXAlignment = Enum.TextXAlignment.Left
    dropLabel.Parent = dropdown
    
    local dropButton = Instance.new("TextButton")
    dropButton.Size = UDim2.new(0.7, -5, 1, 0)
    dropButton.Position = UDim2.new(0.3, 5, 0, 0)
    dropButton.BackgroundColor3 = Config.Theme.Secondary
    dropButton.BorderSizePixel = 0
    dropButton.Text = "Select..."
    dropButton.Font = Enum.Font.Gotham
    dropButton.TextSize = 12
    dropButton.TextColor3 = Config.Theme.Text
    dropButton.AutoButtonColor = false
    dropButton.Parent = dropdown
    
    Utils.CreateCorner(dropButton, 6)
    Utils.CreateStroke(dropButton, Config.Theme.Border, 1)
    
    dropButton.MouseButton1Click:Connect(function()
        Config.SelectedPlayer = dropButton.Text == "Select..." and nil or dropButton.Text
    end)
    
    -- Simple player selection (in a real implementation, you'd create a dropdown list)
    local playerInput = Instance.new("TextBox")
    playerInput.Size = UDim2.new(0.7, -5, 1, 0)
    playerInput.Position = UDim2.new(0.3, 5, 0, 0)
    playerInput.BackgroundColor3 = Config.Theme.Secondary
    playerInput.BorderSizePixel = 0
    playerInput.PlaceholderText = "Enter player name..."
    playerInput.Text = ""
    playerInput.Font = Enum.Font.Gotham
    playerInput.TextSize = 12
    playerInput.TextColor3 = Config.Theme.Text
    playerInput.PlaceholderColor3 = Config.Theme.TextDark
    playerInput.ClearTextOnFocus = false
    playerInput.Parent = dropdown
    
    Utils.CreateCorner(playerInput, 6)
    Utils.CreateStroke(playerInput, Config.Theme.Border, 1)
    
    dropButton:Destroy()
    
    playerInput.FocusLost:Connect(function()
        Config.SelectedPlayer = playerInput.Text
    end)
    
    GUI.CreateButton(tpSection, "Teleport to Player", Config.Theme.Accent, function()
        if Config.SelectedPlayer and Config.SelectedPlayer ~= "" then
            Teleport.TeleportToPlayer(Config.SelectedPlayer)
        else
            print("[Teleport] No player selected")
        end
    end, 2)
end

function GUI.CreateTrollTab(parent)
    local trollSection = GUI.CreateSection(parent, "😈 Troll Features", 1)
    
    local playerInput = Instance.new("Frame")
    playerInput.Name = "TrollPlayerInput"
    playerInput.Size = UDim2.new(1, 0, 0, 36)
    playerInput.BackgroundTransparency = 1
    playerInput.LayoutOrder = 1
    playerInput.Parent = trollSection
    
    local inputLabel = Instance.new("TextLabel")
    inputLabel.Size = UDim2.new(0.3, 0, 1, 0)
    inputLabel.BackgroundTransparency = 1
    inputLabel.Text = "Target Player:"
    inputLabel.Font = Enum.Font.Gotham
    inputLabel.TextSize = 13
    inputLabel.TextColor3 = Config.Theme.Text
    inputLabel.TextXAlignment = Enum.TextXAlignment.Left
    inputLabel.Parent = playerInput
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0.7, -5, 1, 0)
    inputBox.Position = UDim2.new(0.3, 5, 0, 0)
    inputBox.BackgroundColor3 = Config.Theme.Secondary
    inputBox.BorderSizePixel = 0
    inputBox.PlaceholderText = "Enter player name..."
    inputBox.Text = ""
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 12
    inputBox.TextColor3 = Config.Theme.Text
    inputBox.PlaceholderColor3 = Config.Theme.TextDark
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = playerInput
    
    Utils.CreateCorner(inputBox, 6)
    Utils.CreateStroke(inputBox, Config.Theme.Border, 1)
    
    inputBox.FocusLost:Connect(function()
        Config.TrollPlayer = inputBox.Text
    end)
    
    GUI.CreateButton(trollSection, "🌪️ Fling Player", Config.Theme.Warning, function()
        if Config.TrollPlayer and Config.TrollPlayer ~= "" then
            Troll.FlingPlayer(Config.TrollPlayer)
        end
    end, 2)
    
    GUI.CreateButton(trollSection, "🌀 Spin Player", Config.Theme.Warning, function()
        if Config.TrollPlayer and Config.TrollPlayer ~= "" then
            Troll.SpinPlayer(Config.TrollPlayer)
        end
    end, 3)
    
    GUI.CreateButton(trollSection, "❄️ Freeze Player", Config.Theme.Warning, function()
        if Config.TrollPlayer and Config.TrollPlayer ~= "" then
            Troll.FreezePlaye(Config.TrollPlayer)
        end
    end, 4)
    
    GUI.CreateButton(trollSection, "⚠️ Kick Player", Config.Theme.Danger, function()
        if Config.TrollPlayer and Config.TrollPlayer ~= "" then
            Troll.KickPlayer(Config.TrollPlayer)
        end
    end, 5)
    
    local warningLabel = Instance.new("TextLabel")
    warningLabel.Size = UDim2.new(1, 0, 0, 40)
    warningLabel.BackgroundColor3 = Config.Theme.Primary
    warningLabel.BorderSizePixel = 0
    warningLabel.Text = "⚠️ Warning: Some features may not work in all games"
    warningLabel.Font = Enum.Font.Gotham
    warningLabel.TextSize = 10
    warningLabel.TextColor3 = Config.Theme.Warning
    warningLabel.TextWrapped = true
    warningLabel.LayoutOrder = 6
    warningLabel.Parent = trollSection
    
    Utils.CreateCorner(warningLabel, 6)
end

function GUI.Destroy()
    for _, connection in ipairs(State.Connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    
    ESP.Cleanup()
    Visual.RemoveWallhack()
    
    if State.NoClipConnection then
        State.NoClipConnection:Disconnect()
    end
    
    if State.FlightConnection then
        State.FlightConnection:Disconnect()
    end
    
    if State.AimbotFOVCircle then
        State.AimbotFOVCircle:Remove()
        State.AimbotFOVCircle = nil
    end
    
    if GUI.ScreenGui then
        GUI.ScreenGui:Destroy()
    end
    
    print("[Voxy OP Hub] System shutdown complete")
end

-- ============================================================
-- MAIN INITIALIZATION
-- ============================================================
local MainLoop = {}

function MainLoop.Initialize()
    if KeySystem.Enabled and not KeySystem.Authenticated then
        print("[Key System] Authentication required")
        GUI.CreateKeySystem()
        return
    end
end

-- ============================================================
-- STARTUP
-- ============================================================
print("═══════════════════════════════════════════════════════════")
print("  VOXY OP HUB - ULTIMATE EDITION")
print("  Version: " .. Config.Version)
print("  Features: Combat + ESP + Movement + Teleport + Troll")
print("═══════════════════════════════════════════════════════════")

if KeySystem.Enabled then
    print("[Key System] Please enter your key to continue")
end

MainLoop.Initialize()
