--[[
    Arab City - Client Entry Point (v2.0)
    Clean rebuild from scratch.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))

-- Disable default chat on client
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false) end)
pcall(function() StarterGui:SetCore("ChatActive", false) end)
pcall(function() StarterGui:SetCore("ChatBarDisabled", true) end)

print("[ArabCity] Client initialized - " .. Shared.Constants.VERSION)
