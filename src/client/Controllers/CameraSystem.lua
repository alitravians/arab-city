--[[
    Arab City v2.0 - CameraSystem
    Camera modes: default follow, cinematic, selfie, first person.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CameraSystem = {}

local Shared, Constants
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local _currentMode = "default"

local MODES = {
    { name = "default", label = "عادي", fov = 70 },
    { name = "cinematic", label = "سينمائي", fov = 55 },
    { name = "selfie", label = "سيلفي", fov = 50 },
    { name = "firstperson", label = "شخص أول", fov = 90 },
}

function CameraSystem:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.V then
            self:_cycleMode()
        end
    end)
end

function CameraSystem:_cycleMode()
    local currentIndex = 1
    for i, m in ipairs(MODES) do
        if m.name == _currentMode then
            currentIndex = i
            break
        end
    end

    local nextIndex = (currentIndex % #MODES) + 1
    local mode = MODES[nextIndex]
    _currentMode = mode.name

    camera.FieldOfView = mode.fov

    if mode.name == "firstperson" then
        player.CameraMode = Enum.CameraMode.LockFirstPerson
    else
        player.CameraMode = Enum.CameraMode.Classic
    end
end

return CameraSystem
