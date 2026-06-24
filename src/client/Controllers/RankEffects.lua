--[[
    Arab City v2.0 - RankEffects
    VIP/Premium/Elite/Legend rank visual effects on player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RankEffects = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer

local RANK_COLORS = {
    VIP = Color3.fromRGB(255, 215, 0),
    Premium = Color3.fromRGB(0, 200, 255),
    Elite = Color3.fromRGB(180, 0, 255),
    Legend = Color3.fromRGB(255, 50, 50),
}

function RankEffects:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants

    Remotes:OnClientEvent("RankEffect", function(data)
        if type(data) == "table" then
            self:_applyEffect(data)
        end
    end)
end

function RankEffects:_applyEffect(data)
    local targetPlayer = Players:FindFirstChild(data.playerName or "")
    if not targetPlayer then return end
    local char = targetPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local rankName = data.rank or "VIP"
    local color = RANK_COLORS[rankName] or RANK_COLORS.VIP

    -- Billboard rank tag
    local existing = char:FindFirstChild("RankBillboard")
    if existing then existing:Destroy() end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RankBillboard"
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char
    billboard.Adornee = hrp

    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(1, 0, 1, 0)
    rankLabel.BackgroundColor3 = color
    rankLabel.BackgroundTransparency = 0.3
    rankLabel.Text = rankName
    rankLabel.TextSize = 14
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.TextColor3 = Color3.new(1, 1, 1)
    rankLabel.BorderSizePixel = 0
    rankLabel.Parent = billboard
    Instance.new("UICorner", rankLabel).CornerRadius = UDim.new(0, 6)

    -- Sparkle effect for Elite+
    if rankName == "Elite" or rankName == "Legend" then
        local sparkle = Instance.new("ParticleEmitter")
        sparkle.Name = "RankSparkle"
        sparkle.Color = ColorSequence.new(color)
        sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
        sparkle.Lifetime = NumberRange.new(0.5, 1)
        sparkle.Rate = 10
        sparkle.Speed = NumberRange.new(1, 3)
        sparkle.SpreadAngle = Vector2.new(360, 360)
        sparkle.Parent = hrp
    end
end

return RankEffects
