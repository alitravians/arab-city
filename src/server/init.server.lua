--[[
    Arab City - Server Entry Point (v2.0)
    Clean rebuild from scratch.
    Loads all services in dependency order.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chat = game:GetService("Chat")
local TextChatService = game:GetService("TextChatService")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))

-- ── Disable all default chat systems ──
pcall(function() Chat.LoadDefaultChat = false end)
pcall(function() TextChatService.ChatVersion = Enum.ChatVersion.LegacyChatService end)
pcall(function() TextChatService.CreateDefaultTextChannels = false end)
pcall(function() TextChatService.CreateDefaultCommands = false end)
pcall(function()
    local cw = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
    if cw then cw.Enabled = false end
end)
pcall(function()
    local bc = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
    if bc then bc.Enabled = false end
end)

-- ── Load Services ──
local servicesFolder = script:WaitForChild("Services")

local DataService        = require(servicesFolder:WaitForChild("DataService"))
local EconomyService     = require(servicesFolder:WaitForChild("EconomyService"))
local ChatService        = require(servicesFolder:WaitForChild("ChatService"))
local AdminService       = require(servicesFolder:WaitForChild("AdminService"))
local ShopService        = require(servicesFolder:WaitForChild("ShopService"))
local CodeService        = require(servicesFolder:WaitForChild("CodeService"))
local MissionService     = require(servicesFolder:WaitForChild("MissionService"))
local JobService         = require(servicesFolder:WaitForChild("JobService"))
local VehicleService     = require(servicesFolder:WaitForChild("VehicleService"))
local RealEstateService  = require(servicesFolder:WaitForChild("RealEstateService"))
local XPService          = require(servicesFolder:WaitForChild("XPService"))
local BadgeService       = require(servicesFolder:WaitForChild("BadgeService"))
local GamePassService    = require(servicesFolder:WaitForChild("GamePassService"))
local WeatherService     = require(servicesFolder:WaitForChild("WeatherService"))
local TrafficService     = require(servicesFolder:WaitForChild("TrafficService"))
local FriendService      = require(servicesFolder:WaitForChild("FriendService"))
local TradeService       = require(servicesFolder:WaitForChild("TradeService"))
local PetService         = require(servicesFolder:WaitForChild("PetService"))
local LeaderboardService = require(servicesFolder:WaitForChild("LeaderboardService"))
local DailyChallengeService = require(servicesFolder:WaitForChild("DailyChallengeService"))
local BuildingService    = require(servicesFolder:WaitForChild("BuildingService"))
local MapBuilder         = require(servicesFolder:WaitForChild("MapBuilder"))

-- ── Init in dependency order ──
DataService:Init()
EconomyService:Init(DataService)
XPService:Init(DataService)
AdminService:Init(DataService, EconomyService)
ChatService:Init(AdminService)
ShopService:Init(DataService, EconomyService)
CodeService:Init(DataService, EconomyService)
MissionService:Init(DataService, EconomyService, XPService)
JobService:Init(DataService, EconomyService, XPService)
VehicleService:Init(DataService, EconomyService)
RealEstateService:Init(DataService, EconomyService)
BadgeService:Init(DataService)
GamePassService:Init()
WeatherService:Init()
TrafficService:Init()
FriendService:Init(DataService)
TradeService:Init(DataService)
PetService:Init(DataService, EconomyService)
LeaderboardService:Init(DataService)
DailyChallengeService:Init(DataService)
BuildingService:Init(DataService, EconomyService, JobService, XPService)
MapBuilder:Init()

-- ── Welcome reward for new players ──
Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        task.wait(3)
        local data = DataService:Get(player)
        if data and (data.cash == 0 or data.cash == nil) and not data._welcomed then
            EconomyService:AddCash(player, Shared.Constants.WELCOME_REWARD)
            data._welcomed = true
            Shared.Remotes:FireClient("ShowNotification", player, {
                title = "مرحباً بك في Arab City!",
                message = "حصلت على $" .. tostring(Shared.Constants.WELCOME_REWARD) .. " كمكافأة ترحيبية!",
                icon = "🎉",
                duration = 6,
            })
        end
    end)
end)

print("[ArabCity] Server initialized — all " .. tostring(22) .. " services loaded — " .. Shared.Constants.VERSION)
