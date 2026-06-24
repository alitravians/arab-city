--[[
    Arab City - Client Entry Point
    Initializes all client-side controllers in order:
    1. Loading Screen (first - shown during load)
    2. Plane Entry (after loading completes)
    3. HUD + Phone + Map + Camera + Vehicle + Social + Rank Effects
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Wait for shared module to load before controllers
local _Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))

-- Load controllers
local Controllers = script.Controllers
local LoadingScreen = require(Controllers.LoadingScreen)
local PlaneEntry = require(Controllers.PlaneEntry)
local HUDController = require(Controllers.HUDController)
local PhoneController = require(Controllers.PhoneController)
local MapController = require(Controllers.MapController)
local CameraSystem = require(Controllers.CameraSystem)
local VehicleController = require(Controllers.VehicleController)
local SocialNetworkUI = require(Controllers.SocialNetworkUI)
local RankEffects = require(Controllers.RankEffects)
local ChatController = require(Controllers.ChatController)
local TutorialController = require(Controllers.TutorialController)
local NotificationController = require(Controllers.NotificationController)
local LeaderboardController = require(Controllers.LeaderboardController)
local TradeController = require(Controllers.TradeController)
local PetController = require(Controllers.PetController)
local FriendController = require(Controllers.FriendController)
local DailyChallengeController = require(Controllers.DailyChallengeController)
local LODController = require(Controllers.LODController)

-- Phase 1: Show loading screen immediately
LoadingScreen:Show()
print("[ArabCity Client] Loading screen shown")

-- Initialize GUI panels (ModuleScript under StarterGui, needs require to execute)
local guiModule = player.PlayerGui:WaitForChild("ArabCity_GUI")
require(guiModule)
print("[ArabCity Client] GUI panels created")

-- Phase 2: Initialize background systems while loading
MapController:Init()
CameraSystem:Init()
VehicleController:Init()
SocialNetworkUI:Init()
RankEffects:Init()
PhoneController:Init()
ChatController:Init()
NotificationController:Init()
LeaderboardController:Init()
TradeController:Init()
PetController:Init()
FriendController:Init()
DailyChallengeController:Init()
TutorialController:Init()
LODController:Init()
print("[ArabCity Client] Background controllers initialized")

-- Phase 3: HUD initializes but stays behind loading screen
HUDController:Init()
print("[ArabCity Client] HUD initialized")

-- Wire HUD button actions to controllers
HUDController:RegisterPanelCallback(function(action: string)
    if action == "phone" then
        PhoneController:Toggle()
    elseif action == "map" then
        MapController:Toggle()
    elseif action == "codes" then
        local panel = player.PlayerGui:FindFirstChild("CodesPanel")
        if panel then
            panel.Enabled = not panel.Enabled
        end
    elseif action == "shop" then
        local panel = player.PlayerGui:FindFirstChild("ShopPanel")
        if panel then
            panel.Enabled = not panel.Enabled
        end
    elseif action == "inventory" then
        local panel = player.PlayerGui:FindFirstChild("InventoryPanel")
        if panel then
            panel.Enabled = not panel.Enabled
        end
    elseif action == "missions" then
        local panel = player.PlayerGui:FindFirstChild("MissionsPanel")
        if panel then
            panel.Enabled = not panel.Enabled
        end
    elseif action == "admin" then
        local panel = player.PlayerGui:FindFirstChild("AdminPanel")
        if panel then
            panel.Enabled = not panel.Enabled
        end
    elseif action == "chat" then
        ChatController:Toggle()
    elseif action == "friends" then
        FriendController:Toggle()
    elseif action == "leaderboard" then
        LeaderboardController:Toggle()
    elseif action == "challenges" then
        DailyChallengeController:Toggle()
    elseif action == "pets" then
        PetController:Toggle()
    elseif action == "trade" then
        TradeController:Toggle()
    end
end)

-- Phase 4: After loading screen dismisses, start plane entry
task.spawn(function()
    -- Wait for loading to finish
    repeat
        task.wait(0.5)
    until LoadingScreen._gui == nil

    print("[ArabCity Client] Loading complete, starting plane entry")
    PlaneEntry:Start()

    -- Start tutorial for new players after plane entry
    task.delay(3, function()
        TutorialController:Start()
    end)
end)

-- Rank entry effects are handled via the "RankEffectTrigger" remote event
-- fired by the server in RankService and received in RankEffects:Init()

print("[ArabCity Client] Client fully initialized!")
