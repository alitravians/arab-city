--[[
    Arab City v2.0 - VehicleController
    Vehicle HUD: speedometer, RPM, gear display.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VehicleController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer

function VehicleController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "VehicleGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 30
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Speed display (hidden until driving)
    local speedFrame = Instance.new("Frame")
    speedFrame.Name = "SpeedFrame"
    speedFrame.Size = UDim2.new(0, 180, 0, 80)
    speedFrame.Position = UDim2.new(1, -200, 1, -100)
    speedFrame.BackgroundColor3 = colors.background
    speedFrame.BackgroundTransparency = 0.2
    speedFrame.BorderSizePixel = 0
    speedFrame.Visible = false
    speedFrame.Parent = gui
    Instance.new("UICorner", speedFrame).CornerRadius = UDim.new(0, 10)

    self._speedLabel = Instance.new("TextLabel")
    self._speedLabel.Size = UDim2.new(1, 0, 0, 40)
    self._speedLabel.Position = UDim2.new(0, 0, 0, 5)
    self._speedLabel.BackgroundTransparency = 1
    self._speedLabel.Text = "0 km/h"
    self._speedLabel.TextSize = 24
    self._speedLabel.Font = Enum.Font.GothamBold
    self._speedLabel.TextColor3 = Color3.new(1, 1, 1)
    self._speedLabel.Parent = speedFrame

    self._gearLabel = Instance.new("TextLabel")
    self._gearLabel.Size = UDim2.new(1, 0, 0, 20)
    self._gearLabel.Position = UDim2.new(0, 0, 0, 48)
    self._gearLabel.BackgroundTransparency = 1
    self._gearLabel.Text = "P"
    self._gearLabel.TextSize = 16
    self._gearLabel.Font = Enum.Font.GothamBold
    self._gearLabel.TextColor3 = colors.accent
    self._gearLabel.Parent = speedFrame

    self._speedFrame = speedFrame

    Remotes:OnClientEvent("VehicleState", function(data)
        if type(data) == "table" then
            speedFrame.Visible = data.driving or false
            if data.speed then
                local kmh = math.floor(data.speed * 3.6)
                self._speedLabel.Text = tostring(kmh) .. " km/h"
            end
            if data.gear then
                self._gearLabel.Text = "G" .. tostring(data.gear)
            end
        end
    end)
end

return VehicleController
