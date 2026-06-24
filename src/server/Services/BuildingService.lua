--[[
    Arab City - Building Interaction Service
    Handles all building ProximityPrompt interactions
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local RemoteManager = Shared.RemoteManager

local DataManager
local EconomyService
local RankService

local BuildingService = {}

function BuildingService:Init(dataManager, economyService, rankService)
    DataManager = dataManager
    EconomyService = economyService
    RankService = rankService

    -- Connect all existing interactive buildings
    for _, door in ipairs(CollectionService:GetTagged("InteractiveBuilding")) do
        self:_connectPrompt(door)
    end

    -- Connect future interactive buildings
    CollectionService:GetInstanceAddedSignal("InteractiveBuilding"):Connect(function(door)
        self:_connectPrompt(door)
    end)

    -- Connect all property markers
    for _, marker in ipairs(CollectionService:GetTagged("Property")) do
        self:_connectPropertyPrompt(marker)
    end

    CollectionService:GetInstanceAddedSignal("Property"):Connect(function(marker)
        self:_connectPropertyPrompt(marker)
    end)

    -- Track landmark visits
    self:_setupLandmarkTracking()
end

function BuildingService:_connectPrompt(door: BasePart)
    local prompt = door:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        return
    end

    prompt.Triggered:Connect(function(player)
        local buildingType = door:GetAttribute("BuildingType")
        if not buildingType then
            return
        end
        self:_handleBuildingAction(player, buildingType)
    end)
end

function BuildingService:_connectPropertyPrompt(marker: BasePart)
    local prompt = marker:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        return
    end

    prompt.Triggered:Connect(function(player)
        local cfg = marker:FindFirstChild("PropertyConfig")
        if not cfg then
            return
        end

        local propId = cfg:GetAttribute("PropertyId")
        local nameAr = cfg:GetAttribute("NameAr")
        local price = cfg:GetAttribute("Price")
        local rooms = cfg:GetAttribute("Rooms")
        local area = cfg:GetAttribute("Area")
        local owner = cfg:GetAttribute("Owner")

        RemoteManager:FireClient("BuildingAction", player, {
            type = "property_info",
            propId = propId,
            nameAr = nameAr,
            price = price,
            rooms = rooms,
            area = area,
            owned = owner ~= 0,
            ownedByPlayer = owner == player.UserId,
        })
    end)
end

function BuildingService:_handleBuildingAction(player: Player, buildingType: string)
    if buildingType == "Hospital" then
        -- Heal player to full health
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
            end
        end
        RemoteManager:FireClient("BuildingAction", player, {
            type = "notification",
            title = "مستشفى",
            message = "تم علاجك بالكامل!",
            icon = "health",
        })

    elseif buildingType == "Bank" then
        local balance = EconomyService:GetBalance(player)
        local totalEarned = DataManager:GetValue(player, "totalEarned") or 0
        RemoteManager:FireClient("BuildingAction", player, {
            type = "bank_info",
            balance = balance,
            totalEarned = totalEarned,
        })

    elseif buildingType == "Mall" then
        -- Open shop panel on client
        RemoteManager:FireClient("BuildingAction", player, {
            type = "open_panel",
            panel = "ShopPanel",
        })

    elseif buildingType == "CarDealership" then
        -- Open shop panel focused on vehicles
        RemoteManager:FireClient("BuildingAction", player, {
            type = "open_panel",
            panel = "ShopPanel",
            section = "vehicles",
        })

    elseif buildingType == "PoliceStation" then
        RemoteManager:FireClient("BuildingAction", player, {
            type = "job_offer",
            jobId = "police",
            jobName = "شرطي",
            salary = 300,
            description = "حماية المدينة والحفاظ على النظام",
        })

    elseif buildingType == "FireStation" then
        RemoteManager:FireClient("BuildingAction", player, {
            type = "job_offer",
            jobId = "firefighter",
            jobName = "رجل إطفاء",
            salary = 350,
            description = "إخماد الحرائق وإنقاذ الأرواح",
        })

    elseif buildingType == "VIPLounge" then
        local hasVIP = RankService:HasRank(player, "VIP")
        if hasVIP then
            RemoteManager:FireClient("BuildingAction", player, {
                type = "notification",
                title = "VIP",
                message = "مرحباً بك في منطقة VIP!",
                icon = "vip",
            })
        else
            RemoteManager:FireClient("BuildingAction", player, {
                type = "notification",
                title = "VIP",
                message = "تحتاج رتبة VIP أو أعلى للدخول!",
                icon = "locked",
            })
        end

    elseif buildingType == "Airport" then
        RemoteManager:FireClient("BuildingAction", player, {
            type = "notification",
            title = "المطار",
            message = "مرحباً بك في مطار Arab City الدولي!",
            icon = "airport",
        })

    elseif buildingType == "Property" then
        -- Handled by _connectPropertyPrompt
        return
    end

    -- Track landmark visit
    self:_trackLandmarkVisit(player, buildingType)
end

function BuildingService:_trackLandmarkVisit(player: Player, buildingType: string)
    local data = DataManager:GetData(player)
    if not data then
        return
    end

    if not self._visitedCache then
        self._visitedCache = {}
    end
    local userId = player.UserId
    if not self._visitedCache[userId] then
        self._visitedCache[userId] = {}
    end

    if not self._visitedCache[userId][buildingType] then
        self._visitedCache[userId][buildingType] = true
        local count = 0
        for _ in pairs(self._visitedCache[userId]) do
            count += 1
        end
        DataManager:SetValue(player, "landmarksVisited", count)
    end
end

function BuildingService:_setupLandmarkTracking()
    -- Landmark tracking is handled per-interaction in _handleBuildingAction
end

return BuildingService
