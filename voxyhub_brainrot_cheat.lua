--[[
    ═══════════════════════════════════════════════════════════
    VOXYHUB - STEAL BRAIN ROT ULTIMATE CHEAT
    Version: 1.0
    Game: Steal Brain Rot
    
    Features: Auto Steal, Auto Deposit, ESP, Teleports, 
              Auto Farm, Modern UI, Troll Features
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
    CorrectKey = "voxyhub",
    Authenticated = false,
}

-- ============================================================
-- CORE REFERENCES
-- ============================================================
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
-- GAME DETECTION & SETUP
-- ============================================================
local GameSetup = {
    BrainRotFolder = nil,
    PlayerBase = nil,
    SpawnLocation = nil,
    BrainRots = {},
}

function GameSetup.DetectGame()
    print("[Game Setup] Detecting game structures...")
    
    -- Find BrainRot folder (common locations)
    GameSetup.BrainRotFolder = Workspace:FindFirstChild("BrainRots") 
        or Workspace:FindFirstChild("Items")
        or Workspace:FindFirstChild("Collectibles")
        or Workspace:FindFirstChild("Map")
    
    -- Find player's base
    GameSetup.PlayerBase = Workspace:FindFirstChild("Bases")
        or Workspace:FindFirstChild("PlayerBases")
    
    -- Find spawn location
    GameSetup.SpawnLocation = Workspace:FindFirstChild("SpawnLocation")
    
    print("[Game Setup] BrainRot Folder:", GameSetup.BrainRotFolder)
    print("[Game Setup] Player Base:", GameSetup.PlayerBase)
    print("[Game Setup] Spawn Location:", GameSetup.SpawnLocation)
end

function GameSetup.FindBrainRots()
    GameSetup.BrainRots = {}
    
    if not GameSetup.BrainRotFolder then
        -- Search entire workspace
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Part") then
                local name = obj.Name:lower()
                if name:find("brain") or name:find("rot") or name:find("item") or name:find("collect") then
                    table.insert(GameSetup.BrainRots, obj)
                end
            end
        end
    else
        for _, obj in pairs(GameSetup.BrainRotFolder:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Part") then
                table.insert(GameSetup.BrainRots, obj)
            end
        end
    end
    
    return GameSetup.BrainRots
end

function GameSetup.FindPlayerBase()
    if not LocalPlayer.Character then return nil end
    
    -- Try to find base by player name
    if GameSetup.PlayerBase then
        for _, base in pairs(GameSetup.PlayerBase:GetChildren()) do
            if base.Name:find(LocalPlayer.Name) or base:FindFirstChild(LocalPlayer.Name) then
                return base
            end
        end
    end
    
    -- Search for any object with player's name
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:find(LocalPlayer.Name) and (obj:IsA("Model") or obj:IsA("Part")) then
            return obj
        end
    end
    
    return nil
end

-- ============================================================
-- CONFIGURATION
-- ============================================================
local Config = {
    Version = "1.0",
    Name = "VoxyHub",
    
    -- Auto Farm Settings
    AutoSteal = false,
    AutoDeposit = false,
    AutoFarm = false,
    FarmDelay = 0.5,
    TeleportSpeed = 1,
    
    -- ESP Settings
    BrainRotESP = false,
    PlayerESP = false,
    BaseESP = false,
    ESPColor = Color3.fromRGB(0, 255, 255),
    ESPDistance = true,
    ESPMaxDistance = 1000,
    
    -- Teleport Settings
    TeleportToBase = false,
    TeleportToBrainRot = false,
    SelectedPlayer = nil,
    
    -- Player Settings
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    NoClip = false,
    Flight = false,
    FlightSpeed = 50,
    
    -- Troll Settings
    TrollPlayer = nil,
    
    -- UI Theme (Modern Cyan/Blue)
    Theme = {
        Background = Color3.fromRGB(15, 15, 20),
        Surface = Color3.fromRGB(20, 20, 28),
        Primary = Color3.fromRGB(0, 200, 255),
        Secondary = Color3.fromRGB(100, 100, 255),
        Success = Color3.fromRGB(0, 255, 150),
        Danger = Color3.fromRGB(255, 50, 100),
        Warning = Color3.fromRGB(255, 200, 0),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(150, 150, 160),
        Border = Color3.fromRGB(40, 40, 50),
        Accent = Color3.fromRGB(0, 255, 200),
    },
}

-- ============================================================
-- STATE MANAGEMENT
-- ============================================================
local State = {
    Connections = {},
    ESPObjects = {},
    AutoFarmRunning = false,
    CurrentBrainRot = nil,
    NoClipConnection = nil,
    FlightConnection = nil,
    LastStealTime = 0,
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

function Utils.CreateGradient(parent, colors)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colors)
    gradient.Rotation = 90
    gradient.Parent = parent
    return gradient
end

function Utils.TweenProperty(instance, property, value, duration)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
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

function Utils.GetCharacter()
    return LocalPlayer.Character
end

function Utils.GetRootPart()
    local char = Utils.GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Utils.Teleport(position)
    local root = Utils.GetRootPart()
    if root then
        root.CFrame = CFrame.new(position)
    end
end

function Utils.TeleportSmooth(targetCFrame, speed)
    local root = Utils.GetRootPart()
    if not root then return end
    
    local tween = TweenService:Create(
        root,
        TweenInfo.new(speed or Config.TeleportSpeed, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()
    tween.Completed:Wait()
end

-- ============================================================
-- AUTO FARM SYSTEM
-- ============================================================
local AutoFarm = {}

function AutoFarm.GetNearestBrainRot()
    local rootPart = Utils.GetRootPart()
    if not rootPart then return nil end
    
    local brainRots = GameSetup.FindBrainRots()
    local nearest = nil
    local shortestDistance = math.huge
    
    for _, brainRot in pairs(brainRots) do
        if brainRot and brainRot.Parent then
            local brainRotPos = brainRot:IsA("Model") and brainRot:GetModelCFrame().Position or brainRot.Position
            local distance = (rootPart.Position - brainRotPos).Magnitude
            
            if distance < shortestDistance then
                shortestDistance = distance
                nearest = brainRot
            end
        end
    end
    
    return nearest, shortestDistance
end

function AutoFarm.StealBrainRot(brainRot)
    if not brainRot or not brainRot.Parent then return false end
    
    local rootPart = Utils.GetRootPart()
    if not rootPart then return false end
    
    -- Teleport to brain rot
    local brainRotPos = brainRot:IsA("Model") and brainRot:GetModelCFrame().Position or brainRot.Position
    Utils.TeleportSmooth(CFrame.new(brainRotPos), 0.5)
    
    wait(0.3)
    
    -- Try to collect/touch it
    if brainRot:IsA("Model") then
        local primaryPart = brainRot.PrimaryPart or brainRot:FindFirstChildWhichIsA("Part")
        if primaryPart then
            Utils.Teleport(primaryPart.Position)
        end
    else
        Utils.Teleport(brainRotPos)
    end
    
    -- Fire proximity prompts if they exist
    for _, obj in pairs(brainRot:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            fireproximityprompt(obj)
        elseif obj:IsA("ClickDetector") then
            fireclickdetector(obj)
        end
    end
    
    wait(0.2)
    return true
end

function AutoFarm.DepositAtBase()
    local base = GameSetup.FindPlayerBase()
    if not base then
        print("[Auto Farm] Could not find player base")
        return false
    end
    
    local basePos = base:IsA("Model") and base:GetModelCFrame().Position or base.Position
    Utils.TeleportSmooth(CFrame.new(basePos), 0.5)
    
    wait(0.5)
    
    -- Try to trigger deposit
    for _, obj in pairs(base:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            fireproximityprompt(obj)
        elseif obj:IsA("ClickDetector") then
            fireclickdetector(obj)
        end
    end
    
    wait(0.3)
    return true
end

function AutoFarm.Start()
    if State.AutoFarmRunning then return end
    State.AutoFarmRunning = true
    
    print("[Auto Farm] Starting...")
    
    spawn(function()
        while Config.AutoFarm and State.AutoFarmRunning do
            if Config.AutoSteal then
                local brainRot, distance = AutoFarm.GetNearestBrainRot()
                
                if brainRot then
                    print("[Auto Farm] Stealing brain rot...")
                    AutoFarm.StealBrainRot(brainRot)
                    State.LastStealTime = tick()
                    wait(Config.FarmDelay)
                end
            end
            
            if Config.AutoDeposit then
                -- Check if we have items (you may need to adjust this logic)
                print("[Auto Farm] Depositing at base...")
                AutoFarm.DepositAtBase()
                wait(Config.FarmDelay)
            end
            
            wait(0.1)
        end
    end)
end

function AutoFarm.Stop()
    State.AutoFarmRunning = false
    print("[Auto Farm] Stopped")
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================
local ESP = {}

function ESP.CreateBrainRotESP()
    ESP.ClearBrainRotESP()
    
    local brainRots = GameSetup.FindBrainRots()
    
    for _, brainRot in pairs(brainRots) do
        if brainRot and brainRot:IsA("BasePart") or brainRot:IsA("Model") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "VoxyESP"
            highlight.FillColor = Config.ESPColor
            highlight.OutlineColor = Config.ESPColor
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = brainRot
            
            table.insert(State.ESPObjects, highlight)
        end
    end
end

function ESP.ClearBrainRotESP()
    for _, espObj in pairs(State.ESPObjects) do
        if espObj and espObj.Parent then
            espObj:Destroy()
        end
    end
    State.ESPObjects = {}
end

function ESP.CreatePlayerESP(player)
    if not player.Character then return end
    
    local highlight = player.Character:FindFirstChild("VoxyPlayerESP")
    if highlight then return end
    
    highlight = Instance.new("Highlight")
    highlight.Name = "VoxyPlayerESP"
    highlight.FillColor = Color3.fromRGB(255, 100, 100)
    highlight.OutlineColor = Color3.fromRGB(255, 100, 100)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character
end

function ESP.RemovePlayerESP(player)
    if not player.Character then return end
    
    local highlight = player.Character:FindFirstChild("VoxyPlayerESP")
    if highlight then
        highlight:Destroy()
    end
end

function ESP.UpdatePlayerESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Config.PlayerESP then
                ESP.CreatePlayerESP(player)
            else
                ESP.RemovePlayerESP(player)
            end
        end
    end
end

function ESP.CreateBaseESP()
    local base = GameSetup.FindPlayerBase()
    if not base then return end
    
    local highlight = base:FindFirstChild("VoxyBaseESP")
    if highlight then return end
    
    highlight = Instance.new("Highlight")
    highlight.Name = "VoxyBaseESP"
    highlight.FillColor = Config.Theme.Success
    highlight.OutlineColor = Config.Theme.Success
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.Parent = base
end

function ESP.Initialize()
    if Config.BrainRotESP then
        ESP.CreateBrainRotESP()
    end
    
    if Config.PlayerESP then
        ESP.UpdatePlayerESP()
    end
    
    if Config.BaseESP then
        ESP.CreateBaseESP()
    end
end

-- ============================================================
-- MOVEMENT FEATURES
-- ============================================================
local Movement = {}

function Movement.SetWalkSpeed()
    local char = Utils.GetCharacter()
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = Config.WalkSpeed
        end
    end
end

function Movement.SetJumpPower()
    local char = Utils.GetCharacter()
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.JumpPower = Config.JumpPower
        end
    end
end

function Movement.EnableNoClip()
    if Config.NoClip then
        if State.NoClipConnection then
            State.NoClipConnection:Disconnect()
        end
        
        State.NoClipConnection = RunService.Stepped:Connect(function()
            if Config.NoClip and Utils.GetCharacter() then
                for _, part in pairs(Utils.GetCharacter():GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if State.NoClipConnection then
            State.NoClipConnection:Disconnect()
            State.NoClipConnection = nil
        end
    end
end

function Movement.EnableFlight()
    if Config.Flight then
        if State.FlightConnection then
            State.FlightConnection:Disconnect()
        end
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "VoxyFlight"
        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        
        local root = Utils.GetRootPart()
        if root then
            bodyVelocity.Parent = root
        end
        
        State.FlightConnection = RunService.Heartbeat:Connect(function()
            if Config.Flight and Utils.GetRootPart() then
                local hrp = Utils.GetRootPart()
                local bv = hrp:FindFirstChild("VoxyFlight")
                
                if not bv then
                    bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.Name = "VoxyFlight"
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
    else
        if State.FlightConnection then
            State.FlightConnection:Disconnect()
            State.FlightConnection = nil
        end
        
        local root = Utils.GetRootPart()
        if root then
            local bv = root:FindFirstChild("VoxyFlight")
            if bv then
                bv:Destroy()
            end
        end
    end
end

function Movement.EnableInfiniteJump()
    local connection = UserInputService.JumpRequest:Connect(function()
        if not Config.InfiniteJump then return end
        
        local char = Utils.GetCharacter()
        if not char then return end
        
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    
    table.insert(State.Connections, connection)
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
    
    wait(3)
    bodyAngularVelocity:Destroy()
    
    print("[Troll] Spun " .. playerName)
end

function Troll.TeleportToPlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    Utils.Teleport(targetRoot.Position)
    print("[Troll] Teleported to " .. playerName)
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
    
    -- Background blur
    local blur = Instance.new("Frame")
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blur.BackgroundTransparency = 0.2
    blur.BorderSizePixel = 0
    blur.Parent = keyGui
    
    -- Animated particles background
    local particles = Instance.new("Frame")
    particles.Size = UDim2.new(1, 0, 1, 0)
    particles.BackgroundTransparency = 1
    particles.Parent = blur
    
    -- Key window
    local keyWindow = Instance.new("Frame")
    keyWindow.Size = UDim2.new(0, 450, 0, 350)
    keyWindow.Position = UDim2.new(0.5, -225, 0.5, -175)
    keyWindow.BackgroundColor3 = Config.Theme.Background
    keyWindow.BorderSizePixel = 0
    keyWindow.Parent = keyGui
    
    Utils.CreateCorner(keyWindow, 20)
    Utils.CreateStroke(keyWindow, Config.Theme.Primary, 2)
    
    -- Glowing effect
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1, 60, 1, 60)
    glow.Position = UDim2.new(0, -30, 0, -30)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://1316045217"
    glow.ImageColor3 = Config.Theme.Primary
    glow.ImageTransparency = 0.7
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(10, 10, 118, 118)
    glow.ZIndex = 0
    glow.Parent = keyWindow
    
    -- Gradient background
    Utils.CreateGradient(keyWindow, {
        Config.Theme.Background,
        Config.Theme.Surface
    })
    
    -- Logo
    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 80, 0, 80)
    logo.Position = UDim2.new(0.5, -40, 0, 30)
    logo.BackgroundColor3 = Config.Theme.Primary
    logo.BorderSizePixel = 0
    logo.Parent = keyWindow
    
    Utils.CreateCorner(logo, 40)
    
    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Text = "V"
    logoText.Font = Enum.Font.GothamBold
    logoText.TextSize = 48
    logoText.TextColor3 = Config.Theme.Background
    logoText.Parent = logo
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 40)
    title.Position = UDim2.new(0, 20, 0, 125)
    title.BackgroundTransparency = 1
    title.Text = "VOXYHUB"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 32
    title.TextColor3 = Config.Theme.Text
    title.Parent = keyWindow
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 20)
    subtitle.Position = UDim2.new(0, 20, 0, 165)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Steal Brain Rot • Premium Access"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 13
    subtitle.TextColor3 = Config.Theme.TextDark
    subtitle.Parent = keyWindow
    
    -- Get key button
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(1, -40, 0, 40)
    getKeyBtn.Position = UDim2.new(0, 20, 0, 195)
    getKeyBtn.BackgroundColor3 = Config.Theme.Surface
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "🔗 Get Key (Discord)"
    getKeyBtn.Font = Enum.Font.GothamBold
    getKeyBtn.TextSize = 14
    getKeyBtn.TextColor3 = Config.Theme.Primary
    getKeyBtn.AutoButtonColor = false
    getKeyBtn.Parent = keyWindow
    
    Utils.CreateCorner(getKeyBtn, 10)
    Utils.CreateStroke(getKeyBtn, Config.Theme.Primary, 1.5)
    
    getKeyBtn.MouseEnter:Connect(function()
        Utils.TweenProperty(getKeyBtn, "BackgroundColor3", Config.Theme.Border, 0.2)
    end)
    
    getKeyBtn.MouseLeave:Connect(function()
        Utils.TweenProperty(getKeyBtn, "BackgroundColor3", Config.Theme.Surface, 0.2)
    end)
    
    getKeyBtn.MouseButton1Click:Connect(function()
        getKeyBtn.Text = "✅ Link Copied!"
        if setclipboard then
            setclipboard("https://discord.gg/v89MSdzjtE")
        end
        wait(2)
        getKeyBtn.Text = "🔗 Get Key (Discord)"
    end)
    
    -- Key input
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -40, 0, 50)
    inputFrame.Position = UDim2.new(0, 20, 0, 245)
    inputFrame.BackgroundColor3 = Config.Theme.Surface
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = keyWindow
    
    Utils.CreateCorner(inputFrame, 10)
    Utils.CreateStroke(inputFrame, Config.Theme.Border, 1.5)
    
    local keyInput = Instance.new("TextBox")
    keyInput.Size = UDim2.new(1, -20, 1, 0)
    keyInput.Position = UDim2.new(0, 10, 0, 0)
    keyInput.BackgroundTransparency = 1
    keyInput.Text = ""
    keyInput.PlaceholderText = "Enter key here..."
    keyInput.Font = Enum.Font.GothamMedium
    keyInput.TextSize = 15
    keyInput.TextColor3 = Config.Theme.Text
    keyInput.PlaceholderColor3 = Config.Theme.TextDark
    keyInput.ClearTextOnFocus = false
    keyInput.Parent = inputFrame
    
    -- Submit button
    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(1, -40, 0, 45)
    submitBtn.Position = UDim2.new(0, 20, 1, -65)
    submitBtn.BackgroundColor3 = Config.Theme.Primary
    submitBtn.BorderSizePixel = 0
    submitBtn.Text = "VERIFY KEY"
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextSize = 16
    submitBtn.TextColor3 = Config.Theme.Background
    submitBtn.AutoButtonColor = false
    submitBtn.Parent = keyWindow
    
    Utils.CreateCorner(submitBtn, 10)
    
    Utils.CreateGradient(submitBtn, {
        Config.Theme.Primary,
        Config.Theme.Secondary
    })
    
    submitBtn.MouseEnter:Connect(function()
        Utils.TweenProperty(submitBtn, "BackgroundColor3", Config.Theme.Accent, 0.2)
    end)
    
    submitBtn.MouseLeave:Connect(function()
        Utils.TweenProperty(submitBtn, "BackgroundColor3", Config.Theme.Primary, 0.2)
    end)
    
    local function verifyKey()
        local enteredKey = keyInput.Text
        
        if enteredKey == KeySystem.CorrectKey then
            KeySystem.Authenticated = true
            
            submitBtn.Text = "✅ ACCESS GRANTED"
            submitBtn.BackgroundColor3 = Config.Theme.Success
            
            wait(1)
            
            -- Fade out animation
            for i = 0, 1, 0.1 do
                blur.BackgroundTransparency = 0.2 + (0.8 * i)
                keyWindow.BackgroundTransparency = i
                title.TextTransparency = i
                subtitle.TextTransparency = i
                logo.BackgroundTransparency = i
                logoText.TextTransparency = i
                getKeyBtn.BackgroundTransparency = i
                getKeyBtn.TextTransparency = i
                inputFrame.BackgroundTransparency = i
                keyInput.TextTransparency = i
                submitBtn.BackgroundTransparency = i
                submitBtn.TextTransparency = i
                wait(0.03)
            end
            
            keyGui:Destroy()
            
            print("[VoxyHub] Access granted! Loading...")
            
            -- Initialize game
            GameSetup.DetectGame()
            Movement.EnableInfiniteJump()
            GUI.Create()
            
            -- Start main loop
            local mainLoop = RunService.RenderStepped:Connect(function()
                if Config.BrainRotESP then
                    ESP.CreateBrainRotESP()
                end
                
                if Config.PlayerESP then
                    ESP.UpdatePlayerESP()
                end
            end)
            
            table.insert(State.Connections, mainLoop)
            
            print("[VoxyHub] Ready!")
            
        else
            -- Wrong key
            submitBtn.Text = "❌ INVALID KEY"
            submitBtn.BackgroundColor3 = Config.Theme.Danger
            keyInput.Text = ""
            
            wait(1.5)
            submitBtn.Text = "VERIFY KEY"
            submitBtn.BackgroundColor3 = Config.Theme.Primary
        end
    end
    
    submitBtn.MouseButton1Click:Connect(verifyKey)
    keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            verifyKey()
        end
    end)
    
    return keyGui
end

function GUI.Create()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VoxyHub"
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
    container.Size = UDim2.new(0, 550, 0, 650)
    container.Position = UDim2.new(0.5, -275, 0.5, -325)
    container.BackgroundColor3 = Config.Theme.Background
    container.BorderSizePixel = 0
    container.Active = true
    container.Draggable = true
    container.Parent = GUI.ScreenGui
    
    Utils.CreateCorner(container, 15)
    Utils.CreateStroke(container, Config.Theme.Primary, 2)
    
    -- Glow effect
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1, 50, 1, 50)
    glow.Position = UDim2.new(0, -25, 0, -25)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://1316045217"
    glow.ImageColor3 = Config.Theme.Primary
    glow.ImageTransparency = 0.7
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(10, 10, 118, 118)
    glow.ZIndex = 0
    glow.Parent = container
    
    GUI.Container = container
    
    GUI.CreateHeader(container)
    GUI.CreateNavigation(container)
    GUI.CreateContent(container)
end

function GUI.CreateHeader(parent)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundColor3 = Config.Theme.Surface
    header.BorderSizePixel = 0
    header.Parent = parent
    
    Utils.CreateCorner(header, 15)
    Utils.CreateGradient(header, {Config.Theme.Surface, Config.Theme.Background})
    
    -- Logo
    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 50, 0, 50)
    logo.Position = UDim2.new(0, 15, 0, 10)
    logo.BackgroundColor3 = Config.Theme.Primary
    logo.BorderSizePixel = 0
    logo.Parent = header
    
    Utils.CreateCorner(logo, 25)
    
    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Text = "V"
    logoText.Font = Enum.Font.GothamBold
    logoText.TextSize = 30
    logoText.TextColor3 = Config.Theme.Background
    logoText.Parent = logo
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 0, 30)
    title.Position = UDim2.new(0, 75, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "VOXYHUB"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = Config.Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 200, 0, 20)
    subtitle.Position = UDim2.new(0, 75, 0, 38)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Steal Brain Rot v" .. Config.Version
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
    subtitle.TextColor3 = Config.Theme.TextDark
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -55, 0, 15)
    closeBtn.BackgroundColor3 = Config.Theme.Danger
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 28
    closeBtn.TextColor3 = Config.Theme.Text
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = header
    
    Utils.CreateCorner(closeBtn, 10)
    
    closeBtn.MouseButton1Click:Connect(function()
        GUI.Destroy()
    end)
end

function GUI.CreateNavigation(parent)
    local nav = Instance.new("Frame")
    nav.Size = UDim2.new(1, 0, 0, 60)
    nav.Position = UDim2.new(0, 0, 0, 70)
    nav.BackgroundColor3 = Config.Theme.Surface
    nav.BorderSizePixel = 0
    nav.Parent = parent
    
    local navLayout = Instance.new("UIListLayout")
    navLayout.FillDirection = Enum.FillDirection.Horizontal
    navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    navLayout.Padding = UDim.new(0, 8)
    navLayout.Parent = nav
    
    local navPadding = Instance.new("UIPadding")
    navPadding.PaddingLeft = UDim.new(0, 15)
    navPadding.PaddingTop = UDim.new(0, 10)
    navPadding.Parent = nav
    
    local tabs = {
        {Name = "Home", Icon = "🏠"},
        {Name = "Auto Farm", Icon = "🤖"},
        {Name = "ESP", Icon = "👁️"},
        {Name = "Teleport", Icon = "📍"},
        {Name = "Player", Icon = "🏃"},
        {Name = "Troll", Icon = "😈"},
    }
    
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -130)
    contentFrame.Position = UDim2.new(0, 0, 0, 130)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 6
    contentFrame.ScrollBarImageColor3 = Config.Theme.Primary
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Parent = parent
    
    local currentTab = nil
    
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 85, 0, 40)
        tabBtn.BackgroundColor3 = i == 1 and Config.Theme.Primary or Config.Theme.Background
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tab.Icon .. " " .. tab.Name
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 11
        tabBtn.TextColor3 = Config.Theme.Text
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = nav
        
        Utils.CreateCorner(tabBtn, 8)
        
        if i == 1 then
            Utils.CreateGradient(tabBtn, {Config.Theme.Primary, Config.Theme.Secondary})
        end
        
        local tabContent = GUI.CreateTabContent(tab.Name)
        tabContent.Parent = contentFrame
        tabContent.Visible = (i == 1)
        
        if i == 1 then
            currentTab = tabContent
        end
        
        tabBtn.MouseButton1Click:Connect(function()
            for _, child in pairs(contentFrame:GetChildren()) do
                if child:IsA("Frame") then
                    child.Visible = false
                end
            end
            
            for _, button in pairs(nav:GetChildren()) do
                if button:IsA("TextButton") then
                    button.BackgroundColor3 = Config.Theme.Background
                    local grad = button:FindFirstChild("UIGradient")
                    if grad then
                        grad:Destroy()
                    end
                end
            end
            
            tabContent.Visible = true
            tabBtn.BackgroundColor3 = Config.Theme.Primary
            Utils.CreateGradient(tabBtn, {Config.Theme.Primary, Config.Theme.Secondary})
            currentTab = tabContent
        end)
    end
end

function GUI.CreateTabContent(tabName)
    local frame = Instance.new("Frame")
    frame.Name = tabName .. "Content"
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.AutomaticSize = Enum.AutomaticSize.Y
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 15)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = frame
    
    if tabName == "Home" then
        GUI.CreateHomeTab(frame)
    elseif tabName == "Auto Farm" then
        GUI.CreateAutoFarmTab(frame)
    elseif tabName == "ESP" then
        GUI.CreateESPTab(frame)
    elseif tabName == "Teleport" then
        GUI.CreateTeleportTab(frame)
    elseif tabName == "Player" then
        GUI.CreatePlayerTab(frame)
    elseif tabName == "Troll" then
        GUI.CreateTrollTab(frame)
    end
    
    return frame
end

function GUI.CreateSection(parent, title, layoutOrder)
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Size = UDim2.new(1, 0, 0, 0)
    section.BackgroundColor3 = Config.Theme.Surface
    section.BorderSizePixel = 0
    section.LayoutOrder = layoutOrder
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Parent = parent
    
    Utils.CreateCorner(section, 12)
    Utils.CreateStroke(section, Config.Theme.Border, 1)
    
    local sectionPadding = Instance.new("UIPadding")
    sectionPadding.PaddingTop = UDim.new(0, 15)
    sectionPadding.PaddingBottom = UDim.new(0, 15)
    sectionPadding.PaddingLeft = UDim.new(0, 15)
    sectionPadding.PaddingRight = UDim.new(0, 15)
    sectionPadding.Parent = section
    
    local sectionLayout = Instance.new("UIListLayout")
    sectionLayout.Padding = UDim.new(0, 10)
    sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sectionLayout.Parent = section
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "SectionTitle"
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Config.Theme.Primary
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.LayoutOrder = 0
    titleLabel.Parent = section
    
    return section
end

function GUI.CreateToggle(parent, label, defaultValue, callback, layoutOrder)
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(1, 0, 0, 40)
    toggle.BackgroundTransparency = 1
    toggle.LayoutOrder = layoutOrder
    toggle.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, -60, 1, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 14
    labelText.TextColor3 = Config.Theme.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = toggle
    
    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 50, 0, 26)
    switch.Position = UDim2.new(1, -50, 0.5, -13)
    switch.BackgroundColor3 = defaultValue and Config.Theme.Success or Config.Theme.Border
    switch.BorderSizePixel = 0
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.Parent = toggle
    
    Utils.CreateCorner(switch, 13)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = defaultValue and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Config.Theme.Text
    knob.BorderSizePixel = 0
    knob.Parent = switch
    
    Utils.CreateCorner(knob, 10)
    
    local state = defaultValue
    
    switch.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        
        Utils.TweenProperty(switch, "BackgroundColor3", 
            state and Config.Theme.Success or Config.Theme.Border, 0.2)
        Utils.TweenProperty(knob, "Position", 
            state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10), 0.2)
    end)
    
    return toggle
end

function GUI.CreateButton(parent, text, color, callback, layoutOrder)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 45)
    button.BackgroundColor3 = color or Config.Theme.Primary
    button.BorderSizePixel = 0
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 15
    button.TextColor3 = Config.Theme.Text
    button.AutoButtonColor = false
    button.LayoutOrder = layoutOrder
    button.Parent = parent
    
    Utils.CreateCorner(button, 10)
    Utils.CreateGradient(button, {color, Config.Theme.Secondary})
    
    button.MouseEnter:Connect(function()
        Utils.TweenProperty(button, "BackgroundColor3", Config.Theme.Accent, 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        Utils.TweenProperty(button, "BackgroundColor3", color, 0.2)
    end)
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

function GUI.CreateSlider(parent, label, min, max, default, callback, layoutOrder)
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, 0, 0, 55)
    slider.BackgroundTransparency = 1
    slider.LayoutOrder = layoutOrder
    slider.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.7, 0, 0, 25)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 14
    labelText.TextColor3 = Config.Theme.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = slider
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, 0, 0, 25)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = string.format("%.1f", default)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 14
    valueLabel.TextColor3 = Config.Theme.Primary
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = slider
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 8)
    track.Position = UDim2.new(0, 0, 1, -12)
    track.BackgroundColor3 = Config.Theme.Border
    track.BorderSizePixel = 0
    track.Parent = slider
    
    Utils.CreateCorner(track, 4)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Config.Theme.Primary
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    Utils.CreateCorner(fill, 4)
    Utils.CreateGradient(fill, {Config.Theme.Primary, Config.Theme.Secondary})
    
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 20, 0, 20)
    handle.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
    handle.BackgroundColor3 = Config.Theme.Primary
    handle.BorderSizePixel = 0
    handle.Parent = track
    
    Utils.CreateCorner(handle, 10)
    Utils.CreateStroke(handle, Config.Theme.Text, 2)
    
    local dragging = false
    local currentValue = default
    
    local function updateValue(input)
        local relativeX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        currentValue = min + (max - min) * relativeX
        
        valueLabel.Text = string.format("%.1f", currentValue)
        fill.Size = UDim2.new(relativeX, 0, 1, 0)
        handle.Position = UDim2.new(relativeX, -10, 0.5, -10)
        
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

function GUI.CreateHomeTab(parent)
    -- Welcome section
    local welcomeSection = GUI.CreateSection(parent, "👋 Welcome to VoxyHub", 1)
    
    local welcomeText = Instance.new("TextLabel")
    welcomeText.Size = UDim2.new(1, 0, 0, 60)
    welcomeText.BackgroundTransparency = 1
    welcomeText.Text = "Premium Steal Brain Rot exploit loaded successfully!\nAll features are ready to use. Start by enabling Auto Farm."
    welcomeText.Font = Enum.Font.Gotham
    welcomeText.TextSize = 13
    welcomeText.TextColor3 = Config.Theme.TextDark
    welcomeText.TextWrapped = true
    welcomeText.TextYAlignment = Enum.TextYAlignment.Top
    welcomeText.LayoutOrder = 1
    welcomeText.Parent = welcomeSection
    
    -- Status section
    local statusSection = GUI.CreateSection(parent, "📊 Status", 2)
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, 0, 0, 80)
    statusText.BackgroundTransparency = 1
    statusText.Text = string.format(
        "🎮 Game: Steal Brain Rot\n" ..
        "✅ Status: Ready\n" ..
        "🔑 License: Premium\n" ..
        "⚡ Version: %s", Config.Version
    )
    statusText.Font = Enum.Font.GothamMedium
    statusText.TextSize = 13
    statusText.TextColor3 = Config.Theme.Text
    statusText.TextWrapped = true
    statusText.TextYAlignment = Enum.TextYAlignment.Top
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.LayoutOrder = 1
    statusText.Parent = statusSection
    
    -- Quick Actions
    local actionsSection = GUI.CreateSection(parent, "⚡ Quick Actions", 3)
    
    GUI.CreateButton(actionsSection, "🤖 Start Auto Farm", Config.Theme.Success, function()
        Config.AutoFarm = true
        Config.AutoSteal = true
        Config.AutoDeposit = true
        AutoFarm.Start()
    end, 1)
    
    GUI.CreateButton(actionsSection, "👁️ Enable All ESP", Config.Theme.Primary, function()
        Config.BrainRotESP = true
        Config.PlayerESP = true
        Config.BaseESP = true
        ESP.Initialize()
    end, 2)
    
    GUI.CreateButton(actionsSection, "📍 Teleport to Base", Config.Theme.Secondary, function()
        local base = GameSetup.FindPlayerBase()
        if base then
            local basePos = base:IsA("Model") and base:GetModelCFrame().Position or base.Position
            Utils.Teleport(basePos)
        end
    end, 3)
end

function GUI.CreateAutoFarmTab(parent)
    local farmSection = GUI.CreateSection(parent, "🤖 Auto Farm Settings", 1)
    
    GUI.CreateToggle(farmSection, "Enable Auto Farm", Config.AutoFarm, function(value)
        Config.AutoFarm = value
        if value then
            AutoFarm.Start()
        else
            AutoFarm.Stop()
        end
    end, 1)
    
    GUI.CreateToggle(farmSection, "Auto Steal Brain Rot", Config.AutoSteal, function(value)
        Config.AutoSteal = value
    end, 2)
    
    GUI.CreateToggle(farmSection, "Auto Deposit at Base", Config.AutoDeposit, function(value)
        Config.AutoDeposit = value
    end, 3)
    
    GUI.CreateSlider(farmSection, "Farm Speed", 0.1, 2.0, Config.FarmDelay, function(value)
        Config.FarmDelay = value
    end, 4)
    
    GUI.CreateSlider(farmSection, "Teleport Speed", 0.1, 3.0, Config.TeleportSpeed, function(value)
        Config.TeleportSpeed = value
    end, 5)
    
    -- Manual controls
    local manualSection = GUI.CreateSection(parent, "🎮 Manual Controls", 2)
    
    GUI.CreateButton(manualSection, "Collect Nearest Brain Rot", Config.Theme.Primary, function()
        local brainRot = AutoFarm.GetNearestBrainRot()
        if brainRot then
            AutoFarm.StealBrainRot(brainRot)
        end
    end, 1)
    
    GUI.CreateButton(manualSection, "Deposit at Base", Config.Theme.Secondary, function()
        AutoFarm.DepositAtBase()
    end, 2)
end

function GUI.CreateESPTab(parent)
    local espSection = GUI.CreateSection(parent, "👁️ ESP Settings", 1)
    
    GUI.CreateToggle(espSection, "Brain Rot ESP", Config.BrainRotESP, function(value)
        Config.BrainRotESP = value
        if value then
            ESP.CreateBrainRotESP()
        else
            ESP.ClearBrainRotESP()
        end
    end, 1)
    
    GUI.CreateToggle(espSection, "Player ESP", Config.PlayerESP, function(value)
        Config.PlayerESP = value
        ESP.UpdatePlayerESP()
    end, 2)
    
    GUI.CreateToggle(espSection, "Base ESP", Config.BaseESP, function(value)
        Config.BaseESP = value
        if value then
            ESP.CreateBaseESP()
        end
    end, 3)
    
    GUI.CreateToggle(espSection, "Show Distance", Config.ESPDistance, function(value)
        Config.ESPDistance = value
    end, 4)
    
    GUI.CreateSlider(espSection, "Max Distance", 100, 3000, Config.ESPMaxDistance, function(value)
        Config.ESPMaxDistance = value
    end, 5)
end

function GUI.CreateTeleportTab(parent)
    local tpSection = GUI.CreateSection(parent, "📍 Teleport Options", 1)
    
    GUI.CreateButton(tpSection, "Teleport to Your Base", Config.Theme.Success, function()
        local base = GameSetup.FindPlayerBase()
        if base then
            local basePos = base:IsA("Model") and base:GetModelCFrame().Position or base.Position
            Utils.Teleport(basePos)
        else
            print("[Teleport] Base not found!")
        end
    end, 1)
    
    GUI.CreateButton(tpSection, "Teleport to Spawn", Config.Theme.Primary, function()
        if GameSetup.SpawnLocation then
            Utils.Teleport(GameSetup.SpawnLocation.Position)
        end
    end, 2)
    
    GUI.CreateButton(tpSection, "Teleport to Nearest Brain Rot", Config.Theme.Secondary, function()
        local brainRot = AutoFarm.GetNearestBrainRot()
        if brainRot then
            local pos = brainRot:IsA("Model") and brainRot:GetModelCFrame().Position or brainRot.Position
            Utils.Teleport(pos)
        end
    end, 3)
end

function GUI.CreatePlayerTab(parent)
    local moveSection = GUI.CreateSection(parent, "🏃 Movement", 1)
    
    GUI.CreateSlider(moveSection, "Walk Speed", 16, 200, Config.WalkSpeed, function(value)
        Config.WalkSpeed = value
        Movement.SetWalkSpeed()
    end, 1)
    
    GUI.CreateSlider(moveSection, "Jump Power", 50, 300, Config.JumpPower, function(value)
        Config.JumpPower = value
        Movement.SetJumpPower()
    end, 2)
    
    GUI.CreateToggle(moveSection, "Infinite Jump", Config.InfiniteJump, function(value)
        Config.InfiniteJump = value
    end, 3)
    
    GUI.CreateToggle(moveSection, "NoClip", Config.NoClip, function(value)
        Config.NoClip = value
        Movement.EnableNoClip()
    end, 4)
    
    GUI.CreateToggle(moveSection, "Flight (WASD + Space/Shift)", Config.Flight, function(value)
        Config.Flight = value
        Movement.EnableFlight()
    end, 5)
    
    GUI.CreateSlider(moveSection, "Flight Speed", 10, 200, Config.FlightSpeed, function(value)
        Config.FlightSpeed = value
    end, 6)
end

function GUI.CreateTrollTab(parent)
    local trollSection = GUI.CreateSection(parent, "😈 Troll Features", 1)
    
    local playerInput = Instance.new("Frame")
    playerInput.Size = UDim2.new(1, 0, 0, 40)
    playerInput.BackgroundTransparency = 1
    playerInput.LayoutOrder = 1
    playerInput.Parent = trollSection
    
    local inputLabel = Instance.new("TextLabel")
    inputLabel.Size = UDim2.new(0, 100, 1, 0)
    inputLabel.BackgroundTransparency = 1
    inputLabel.Text = "Target Player:"
    inputLabel.Font = Enum.Font.Gotham
    inputLabel.TextSize = 14
    inputLabel.TextColor3 = Config.Theme.Text
    inputLabel.TextXAlignment = Enum.TextXAlignment.Left
    inputLabel.Parent = playerInput
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -110, 1, 0)
    inputBox.Position = UDim2.new(0, 110, 0, 0)
    inputBox.BackgroundColor3 = Config.Theme.Surface
    inputBox.BorderSizePixel = 0
    inputBox.PlaceholderText = "Enter player name..."
    inputBox.Text = ""
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 13
    inputBox.TextColor3 = Config.Theme.Text
    inputBox.PlaceholderColor3 = Config.Theme.TextDark
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = playerInput
    
    Utils.CreateCorner(inputBox, 8)
    
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
    
    GUI.CreateButton(trollSection, "📍 Teleport to Player", Config.Theme.Primary, function()
        if Config.TrollPlayer and Config.TrollPlayer ~= "" then
            Troll.TeleportToPlayer(Config.TrollPlayer)
        end
    end, 4)
end

function GUI.Destroy()
    -- Cleanup
    for _, connection in ipairs(State.Connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    
    ESP.ClearBrainRotESP()
    
    if State.NoClipConnection then
        State.NoClipConnection:Disconnect()
    end
    
    if State.FlightConnection then
        State.FlightConnection:Disconnect()
    end
    
    if GUI.ScreenGui then
        GUI.ScreenGui:Destroy()
    end
    
    print("[VoxyHub] Shutdown complete")
end

-- ============================================================
-- INITIALIZATION
-- ============================================================
print("═══════════════════════════════════════════════════════════")
print("  VOXYHUB - STEAL BRAIN ROT ULTIMATE")
print("  Version: " .. Config.Version)
print("═══════════════════════════════════════════════════════════")

if KeySystem.Enabled then
    GUI.CreateKeySystem()
else
    GameSetup.DetectGame()
    Movement.EnableInfiniteJump()
    GUI.Create()
end
