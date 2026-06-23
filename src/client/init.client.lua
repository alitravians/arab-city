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

-- Phase 1: Show loading screen immediately
LoadingScreen:Show()
print("[ArabCity Client] Loading screen shown")

-- Phase 2: Initialize background systems while loading
MapController:Init()
CameraSystem:Init()
VehicleController:Init()
SocialNetworkUI:Init()
RankEffects:Init()
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
        -- Codes panel handled by GUI
        local gui = player.PlayerGui:FindFirstChild("ArabCity_GUI")
        if gui then
            local codesPanel = gui:FindFirstChild("CodesPanel")
            if codesPanel then
                codesPanel.Visible = not codesPanel.Visible
            end
        end
    elseif action == "shop" then
        local gui = player.PlayerGui:FindFirstChild("ArabCity_GUI")
        if gui then
            local shopPanel = gui:FindFirstChild("ShopPanel")
            if shopPanel then
                shopPanel.Visible = not shopPanel.Visible
            end
        end
    elseif action == "inventory" then
        local gui = player.PlayerGui:FindFirstChild("ArabCity_GUI")
        if gui then
            local invPanel = gui:FindFirstChild("InventoryPanel")
            if invPanel then
                invPanel.Visible = not invPanel.Visible
            end
        end
    elseif action == "missions" then
        local gui = player.PlayerGui:FindFirstChild("ArabCity_GUI")
        if gui then
            local missionsPanel = gui:FindFirstChild("MissionsPanel")
            if missionsPanel then
                missionsPanel.Visible = not missionsPanel.Visible
            end
        end
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
end)

-- Phase 5: Listen for rank entry effects on other players
Players.PlayerAdded:Connect(function(otherPlayer)
    RankEffects:PlayEntryEffect(otherPlayer)
end)

print("[ArabCity Client] Client fully initialized!")
