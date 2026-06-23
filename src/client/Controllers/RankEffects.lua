--[[
    Arab City - Rank Entry Effects
    Visual effects when ranked players join the game
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RankEffects = {}

local EFFECT_CONFIGS = {
    VIP = {
        color = Color3.fromRGB(255, 215, 0),
        particleCount = 20,
        duration = 3,
        titleSize = 36,
        sound = "rbxassetid://9125360862",
    },
    Premium = {
        color = Color3.fromRGB(0, 191, 255),
        particleCount = 30,
        duration = 4,
        titleSize = 40,
        sound = "rbxassetid://9125360862",
    },
    Elite = {
        color = Color3.fromRGB(148, 0, 211),
        particleCount = 40,
        duration = 5,
        titleSize = 44,
        sound = "rbxassetid://9125360862",
    },
    Legend = {
        color = Color3.fromRGB(255, 69, 0),
        particleCount = 60,
        duration = 6,
        titleSize = 48,
        sound = "rbxassetid://9125360862",
    },
}

function RankEffects:Init()
    RemoteManager:OnClientEvent("RankEffectTrigger", function(userId, rankName)
        self:PlayEntryEffect(userId, rankName)
    end)
end

function RankEffects:PlayEntryEffect(userId: number, rankName: string)
    local config = EFFECT_CONFIGS[rankName]
    if not config then
        return
    end

    local targetPlayer = Players:GetPlayerByUserId(userId)
    if not targetPlayer then
        return
    end

    local rankData = Constants.RANKS[rankName]

    -- Play entry sound
    self:_playEntrySound(config.sound)

    -- Show screen announcement
    self:_showAnnouncement(targetPlayer, rankName, rankData, config)

    -- Create 3D particle effect on player
    self:_create3DEffect(targetPlayer, config)
end

function RankEffects:_playEntrySound(soundId: string)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.4
    sound.Parent = player.PlayerGui
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

function RankEffects:_showAnnouncement(targetPlayer: Player, rankName: string, rankData, config)
    local gui = Instance.new("ScreenGui")
    gui.Name = "RankAnnouncement"
    gui.DisplayOrder = 200
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.5, 0, 0, 80)
    frame.Position = UDim2.new(0.5, 0, 0.15, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = gui

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = config.color
    frameStroke.Thickness = 2
    frameStroke.Transparency = 0.3
    frameStroke.Parent = frame

    -- Rank badge
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 50, 0, 50)
    badge.Position = UDim2.new(0, 15, 0.5, 0)
    badge.AnchorPoint = Vector2.new(0, 0.5)
    badge.BackgroundColor3 = config.color
    badge.BackgroundTransparency = 0.2
    badge.Text = "👑"
    badge.TextSize = 24
    badge.ZIndex = 201
    badge.Parent = frame

    Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)

    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -80, 0, 25)
    nameLabel.Position = UDim2.new(0, 75, 0, 12)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlayer.DisplayName
    nameLabel.TextColor3 = config.color
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.TextSize = 20
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 201
    nameLabel.Parent = frame

    -- Rank label
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(1, -80, 0, 20)
    rankLabel.Position = UDim2.new(0, 75, 0, 40)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = `دخل بتصنيف {rankData and rankData.labelAr or rankName}`
    rankLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    rankLabel.Font = Enum.Font.GothamMedium
    rankLabel.TextSize = 14
    rankLabel.TextXAlignment = Enum.TextXAlignment.Left
    rankLabel.ZIndex = 201
    rankLabel.Parent = frame

    -- Entrance animation
    frame.Position = UDim2.new(0.5, 0, -0.1, 0)
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.15, 0),
    }):Play()

    -- Shimmer effect on the border
    task.spawn(function()
        for _ = 1, 3 do
            TweenService:Create(frameStroke, TweenInfo.new(0.3), { Transparency = 0 }):Play()
            task.wait(0.3)
            TweenService:Create(frameStroke, TweenInfo.new(0.3), { Transparency = 0.5 }):Play()
            task.wait(0.3)
        end
    end)

    -- Dismiss after duration
    task.delay(config.duration, function()
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, -0.2, 0),
        }):Play()
        task.delay(0.5, function()
            gui:Destroy()
        end)
    end)
end

function RankEffects:_create3DEffect(targetPlayer: Player, config)
    local character = targetPlayer.Character
    if not character then
        return
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    -- Create particle emitter attachment
    local attachment = Instance.new("Attachment")
    attachment.Name = "RankEffectAttachment"
    attachment.Parent = rootPart

    -- Sparkle particles
    local sparkle = Instance.new("ParticleEmitter")
    sparkle.Color = ColorSequence.new(config.color)
    sparkle.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparkle.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    sparkle.Lifetime = NumberRange.new(1, 2)
    sparkle.Rate = config.particleCount
    sparkle.Speed = NumberRange.new(5, 15)
    sparkle.SpreadAngle = Vector2.new(180, 180)
    sparkle.LightEmission = 1
    sparkle.LightInfluence = 0
    sparkle.Parent = attachment

    -- Point light
    local light = Instance.new("PointLight")
    light.Color = config.color
    light.Brightness = 3
    light.Range = 20
    light.Parent = rootPart

    -- Fade out and clean up
    task.delay(config.duration, function()
        sparkle.Rate = 0
        TweenService:Create(light, TweenInfo.new(1), { Brightness = 0 }):Play()
        task.delay(2, function()
            attachment:Destroy()
            light:Destroy()
        end)
    end)
end

return RankEffects
