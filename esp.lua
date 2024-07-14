local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CircleRadius = 5 -- Default circle size
local CircleThickness = 1
local CircleNumSides = 30 -- More sides = smoother circle
local CircleCache = {}
local LineCache = {}
local TextCache = {}

local IsCircleFilled = true -- Default to filled circles
local IsTeamCheckEnabled = true -- Default to team check enabled
local IsShowToolEnabled = false -- Default to not showing tool
local ShowFootLine = true -- Default to showing foot line

local TeamColor = Color3.new(0, 1, 0) -- Default team color (green)
local EnemyColor = Color3.new(1, 0, 0) -- Default enemy color (red)
local TextColor = Color3.new(1, 1, 1) -- Default text color (white)
local NonVisibleColor = Color3.new(1, 1, 0) -- Yellow color for non-visible players

-- Create Window
local Window = OrionLib:MakeWindow({Name = "Yazz ESP", HidePremium = false, SaveConfig = true, ConfigFolder = "YazzEsp"})

-- Create Tabs
local ESPTab = Window:MakeTab({
    Name = "ESP Options",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local HeadDotTab = Window:MakeTab({
    Name = "Head Dot",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- ESP Options Tab
ESPTab:AddToggle({
    Name = "Filled Circles",
    Default = IsCircleFilled,
    Callback = function(Value)
        IsCircleFilled = Value
        for _, circle in pairs(CircleCache) do
            circle.Filled = IsCircleFilled
        end
    end
})

ESPTab:AddToggle({
    Name = "Team Check",
    Default = IsTeamCheckEnabled,
    Callback = function(Value)
        IsTeamCheckEnabled = Value
    end
})

ESPTab:AddToggle({
    Name = "Show Tool",
    Default = IsShowToolEnabled,
    Callback = function(Value)
        IsShowToolEnabled = Value
    end
})

ESPTab:AddToggle({
    Name = "Show Foot Line",
    Default = ShowFootLine,
    Callback = function(Value)
        ShowFootLine = Value
    end
})

ESPTab:AddButton({
    Name = "Unload ESP",
    Callback = function()
        for _, circle in pairs(CircleCache) do
            circle:Remove()
        end
        for _, line in pairs(LineCache) do
            line:Remove()
        end
        for _, text in pairs(TextCache) do
            text:Remove()
        end
        CircleCache = {}
        LineCache = {}
        TextCache = {}
        if RenderSteppedConnection then
            RenderSteppedConnection:Disconnect()
        end
        OrionLib:Destroy()
    end
})

-- Head Dot Tab
HeadDotTab:AddSlider({
    Name = "Circle Size",
    Min = 1,
    Max = 20,
    Default = 5,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "pixels",
    Callback = function(Value)
        CircleRadius = Value
        for _, circle in pairs(CircleCache) do
            circle.Radius = CircleRadius
        end
    end
})

HeadDotTab:AddColorpicker({
    Name = "Team Color",
    Default = TeamColor,
    Callback = function(Value)
        TeamColor = Value
    end
})

HeadDotTab:AddColorpicker({
    Name = "Enemy Color",
    Default = EnemyColor,
    Callback = function(Value)
        EnemyColor = Value
    end
})

local function IsOnScreen(position)
    local screenPosition, onScreen = Camera:WorldToViewportPoint(position)
    return onScreen and screenPosition.Z > 0
end

local function CreateCircle()
    local circle = Drawing.new("Circle")
    circle.Thickness = CircleThickness
    circle.Filled = IsCircleFilled
    circle.NumSides = CircleNumSides
    circle.Radius = CircleRadius
    circle.Visible = false
    circle.Transparency = 1 -- Full opacity by default
    return circle
end

local function CreateLine()
    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.new(1, 1, 1)
    line.Visible = false
    return line
end

local function CreateText()
    local text = Drawing.new("Text")
    text.Size = 18
    text.Center = true
    text.Outline = true
    text.Color = TextColor
    text.Visible = false
    return text
end

local function GetPlayerTool(player)
    local character = player.Character
    if character then
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Tool") then
                return child.Name
            end
        end
    end
    return "None"
end

RenderSteppedConnection = RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("Head") and character:FindFirstChild("HumanoidRootPart") then
                local head = character.Head
                local humanoidRootPart = character.HumanoidRootPart
                local humanoid = character:FindFirstChild("Humanoid")
                
                local headPosition = head.Position
                local isVisible = IsOnScreen(headPosition)
                local shouldDraw = not IsTeamCheckEnabled or player.Team ~= LocalPlayer.Team

                if shouldDraw then
                    local circle = CircleCache[player] or CreateCircle()
                    CircleCache[player] = circle

                    local screenPosition = Camera:WorldToViewportPoint(headPosition)
                    circle.Position = Vector2.new(screenPosition.X, screenPosition.Y)
                    circle.Visible = true
                    circle.Filled = IsCircleFilled
                    circle.Radius = CircleRadius

                    if isVisible then
                        if IsTeamCheckEnabled and player.Team == LocalPlayer.Team then
                            circle.Color = TeamColor
                        else
                            circle.Color = EnemyColor
                        end
                        circle.Transparency = 1 -- Fully opaque when visible

                        -- Foot Line
                        if ShowFootLine then
                            local line = LineCache[player] or CreateLine()
                            LineCache[player] = line
                            local feetPosition = Camera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 3, 0))
                            line.From = Vector2.new(screenPosition.X, screenPosition.Y)
                            line.To = Vector2.new(feetPosition.X, feetPosition.Y)
                            line.Visible = true
                        else
                            if LineCache[player] then
                                LineCache[player].Visible = false
                            end
                        end

                        -- Text
                        local text = TextCache[player] or CreateText()
                        TextCache[player] = text
                        text.Position = Vector2.new(screenPosition.X, screenPosition.Y - 40)
                        
                        local toolName = IsShowToolEnabled and GetPlayerTool(player) or ""
                        local health = humanoid and math.floor(humanoid.Health) or 0
                        local distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude)
                        
                        text.Text = string.format("%s\n%s: %d HP: %d studs", toolName, player.Name, health, distance)
                        text.Visible = true
                    else
                        -- Player is not on screen, set yellow color and reduced opacity
                        circle.Color = NonVisibleColor
                        circle.Transparency = 0.25 -- 75% opacity when not visible
                        if LineCache[player] then LineCache[player].Visible = false end
                        if TextCache[player] then TextCache[player].Visible = false end
                    end
                else
                    if CircleCache[player] then CircleCache[player].Visible = false end
                    if LineCache[player] then LineCache[player].Visible = false end
                    if TextCache[player] then TextCache[player].Visible = false end
                end
            else
                if CircleCache[player] then CircleCache[player].Visible = false end
                if LineCache[player] then LineCache[player].Visible = false end
                if TextCache[player] then TextCache[player].Visible = false end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if CircleCache[player] then
        CircleCache[player]:Remove()
        CircleCache[player] = nil
    end
    if LineCache[player] then
        LineCache[player]:Remove()
        LineCache[player] = nil
    end
    if TextCache[player] then
        TextCache[player]:Remove()
        TextCache[player] = nil
    end
end)

OrionLib:Init()
