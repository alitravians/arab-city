--[[
    Arab City - Starter Character Script
    Runs when the player's character spawns/respawns.
    Handles character-level setup (nametag colors, health regen, etc.)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local RemoteManager = Shared.RemoteManager

-- Disable default health regen so we control it
local healthScript = character:FindFirstChild("Health")
if healthScript then
    healthScript:Destroy()
end

-- Set walk speed
humanoid.WalkSpeed = 16
humanoid.JumpPower = 50

-- Request rank data for nametag coloring
task.spawn(function()
    local rankData = RemoteManager:InvokeServer("GetPlayerRank")
    if rankData and rankData.nameColor then
        -- Apply name color via BillboardGui if needed
        local head = character:WaitForChild("Head", 5)
        if not head then
            return
        end

        local existingTag = head:FindFirstChild("NameTag")
        if existingTag then
            existingTag:Destroy()
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NameTag"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = false
        billboard.MaxDistance = 60
        billboard.Parent = head

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.DisplayName
        nameLabel.TextColor3 = rankData.nameColor
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 16
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Parent = billboard

        if rankData.label and rankData.label ~= "" then
            local rankLabel = Instance.new("TextLabel")
            rankLabel.Size = UDim2.new(1, 0, 0.4, 0)
            rankLabel.Position = UDim2.new(0, 0, 0.6, 0)
            rankLabel.BackgroundTransparency = 1
            rankLabel.Text = rankData.label
            rankLabel.TextColor3 = rankData.nameColor
            rankLabel.Font = Enum.Font.GothamMedium
            rankLabel.TextSize = 12
            rankLabel.TextStrokeTransparency = 0.6
            rankLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            rankLabel.Parent = billboard
        end
    end
end)
