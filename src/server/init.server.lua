--[[
    Arab City - Server Entry Point
    Initializes all server-side services
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared module
local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local RemoteManager = Shared.RemoteManager

-- Initialize remotes first
RemoteManager:Init()
print("[ArabCity] Remote events initialized")

-- Load services
local Services = script.Services

-- FIRST: Disable all default chat systems before anything else loads
local DisableDefaultChat = require(Services.DisableDefaultChat)
DisableDefaultChat:Init()

local MapBuilder = require(Services.MapBuilder)
local DataManager = require(Services.DataManager)
local EconomyService = require(Services.EconomyService)
local RankService = require(Services.RankService)
local RealEstateService = require(Services.RealEstateService)
local VehicleService = require(Services.VehicleService)
local JobService = require(Services.JobService)
local MissionService = require(Services.MissionService)
local CodeService = require(Services.CodeService)
local SocialNetworkService = require(Services.SocialNetworkService)
local WeatherService = require(Services.WeatherService)
local AchievementService = require(Services.AchievementService)
local FameService = require(Services.FameService)
local PalaceService = require(Services.PalaceService)
local EventService = require(Services.EventService)
local ComputerService = require(Services.ComputerService)
local BuildingService = require(Services.BuildingService)
local BadgeService = require(Services.BadgeService)
local GamePassService = require(Services.GamePassService)
local AdminService = require(Services.AdminService)
local ChatService = require(Services.ChatService)
local XPService = require(Services.XPService)
local FriendService = require(Services.FriendService)
local LeaderboardService = require(Services.LeaderboardService)
local TradeService = require(Services.TradeService)
local PetService = require(Services.PetService)
local DailyChallengeService = require(Services.DailyChallengeService)
local TrafficService = require(Services.TrafficService)

-- Build the city map first (before services that need workspace objects)
MapBuilder:Init()
print("[ArabCity] Map built")

-- Initialize services in dependency order
DataManager:Init()
print("[ArabCity] DataManager initialized")

EconomyService:Init(DataManager)
print("[ArabCity] EconomyService initialized")

RankService:Init(DataManager)
print("[ArabCity] RankService initialized")

RealEstateService:Init(DataManager, EconomyService)
print("[ArabCity] RealEstateService initialized")

VehicleService:Init(DataManager)
print("[ArabCity] VehicleService initialized")

JobService:Init(DataManager, EconomyService)
print("[ArabCity] JobService initialized")

MissionService:Init(DataManager, EconomyService)
print("[ArabCity] MissionService initialized")

CodeService:Init(DataManager, EconomyService)
print("[ArabCity] CodeService initialized")

SocialNetworkService:Init(DataManager)
print("[ArabCity] SocialNetworkService initialized")

WeatherService:Init()
print("[ArabCity] WeatherService initialized")

AchievementService:Init(DataManager, EconomyService)
print("[ArabCity] AchievementService initialized")

FameService:Init(DataManager, EconomyService)
print("[ArabCity] FameService initialized")

PalaceService:Init(RankService)
print("[ArabCity] PalaceService initialized")

EventService:Init(DataManager, EconomyService)
print("[ArabCity] EventService initialized")

ComputerService:Init(DataManager, SocialNetworkService)
print("[ArabCity] ComputerService initialized")

BuildingService:Init(DataManager, EconomyService, RankService)
print("[ArabCity] BuildingService initialized")

BadgeService:Init(DataManager)
print("[ArabCity] BadgeService initialized")

GamePassService:Init(DataManager)
print("[ArabCity] GamePassService initialized")

AdminService:Init(DataManager, EconomyService)
print("[ArabCity] AdminService initialized")

ChatService:Init(DataManager)
print("[ArabCity] ChatService initialized")

XPService:Init(DataManager)
print("[ArabCity] XPService initialized")

FriendService:Init(DataManager)
print("[ArabCity] FriendService initialized")

LeaderboardService:Init(DataManager)
print("[ArabCity] LeaderboardService initialized")

TradeService:Init(DataManager, XPService)
print("[ArabCity] TradeService initialized")

PetService:Init(DataManager)
print("[ArabCity] PetService initialized")

DailyChallengeService:Init(DataManager, XPService)
print("[ArabCity] DailyChallengeService initialized")

TrafficService:Init()
print("[ArabCity] TrafficService initialized")

-- Create workspace folders
local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

ensureFolder(workspace, "Vehicles")
ensureFolder(workspace, "Properties")
ensureFolder(workspace, "SpawnPoints")
ensureFolder(workspace, "TrafficCars")

print("[ArabCity] Server fully initialized! Version: " .. Shared.Constants.VERSION)
