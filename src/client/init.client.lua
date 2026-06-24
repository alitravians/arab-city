--[[
    Arab City - Client Entry Point (v2.0)
    Clean rebuild from scratch.
    Loads all client controllers in order.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))

-- ── Disable default chat on client ──
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false) end)
pcall(function() StarterGui:SetCore("ChatActive", false) end)
pcall(function() StarterGui:SetCore("ChatBarDisabled", true) end)

-- ── Load Controllers ──
local controllersFolder = script:WaitForChild("Controllers")

local LoadingScreen            = require(controllersFolder:WaitForChild("LoadingScreen"))
local NotificationController   = require(controllersFolder:WaitForChild("NotificationController"))
local HUDController            = require(controllersFolder:WaitForChild("HUDController"))
local ChatController           = require(controllersFolder:WaitForChild("ChatController"))
local AdminController          = require(controllersFolder:WaitForChild("AdminController"))
local TutorialController       = require(controllersFolder:WaitForChild("TutorialController"))
local MapController            = require(controllersFolder:WaitForChild("MapController"))
local PhoneController          = require(controllersFolder:WaitForChild("PhoneController"))
local ShopController           = require(controllersFolder:WaitForChild("ShopController"))
local InventoryController      = require(controllersFolder:WaitForChild("InventoryController"))
local CodeController           = require(controllersFolder:WaitForChild("CodeController"))
local MissionController        = require(controllersFolder:WaitForChild("MissionController"))
local CameraSystem             = require(controllersFolder:WaitForChild("CameraSystem"))
local PlaneEntry               = require(controllersFolder:WaitForChild("PlaneEntry"))
local VehicleController        = require(controllersFolder:WaitForChild("VehicleController"))
local SocialNetworkUI          = require(controllersFolder:WaitForChild("SocialNetworkUI"))
local FriendController         = require(controllersFolder:WaitForChild("FriendController"))
local TradeController          = require(controllersFolder:WaitForChild("TradeController"))
local PetController            = require(controllersFolder:WaitForChild("PetController"))
local LeaderboardController    = require(controllersFolder:WaitForChild("LeaderboardController"))
local DailyChallengeController = require(controllersFolder:WaitForChild("DailyChallengeController"))
local RankEffects              = require(controllersFolder:WaitForChild("RankEffects"))
local LODController            = require(controllersFolder:WaitForChild("LODController"))

-- ── Init in order (loading screen first) ──
LoadingScreen:Init()
NotificationController:Init()
HUDController:Init()
ChatController:Init()
AdminController:Init()
ShopController:Init()
InventoryController:Init()
CodeController:Init()
MissionController:Init()
MapController:Init()
PhoneController:Init()
VehicleController:Init()
SocialNetworkUI:Init()
FriendController:Init()
TradeController:Init()
PetController:Init()
LeaderboardController:Init()
DailyChallengeController:Init()
CameraSystem:Init()
PlaneEntry:Init()
RankEffects:Init()
LODController:Init()
TutorialController:Init()

print("[ArabCity] Client initialized — all 22 controllers loaded — " .. Shared.Constants.VERSION)
