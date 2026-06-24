--[[
    Arab City v2.0 - BuildingService
    Interactive buildings with ProximityPrompts.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildingService = {}

local Shared, Constants, Remotes, DataService, EconomyService

function BuildingService:Init(dataService, economyService)
    DataService = dataService
    EconomyService = economyService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    task.spawn(function()
        task.wait(2)
        self:_setupBuildings()
    end)
end

function BuildingService:_setupBuildings()
    local buildings = Workspace:FindFirstChild("Buildings")
    if not buildings then return end

    for _, building in ipairs(buildings:GetChildren()) do
        local door = building:FindFirstChild("Door") or building:FindFirstChild("Entrance")
        local target = door or building.PrimaryPart or (building:IsA("BasePart") and building) or nil
        if not target then continue end

        local buildingType = building:GetAttribute("BuildingType") or building.Name
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "ادخل"
        prompt.ObjectText = buildingType
        prompt.MaxActivationDistance = 10
        prompt.HoldDuration = 0.3
        prompt.Parent = target

        prompt.Triggered:Connect(function(player)
            self:_onEnter(player, buildingType)
        end)
    end
end

function BuildingService:_onEnter(player, buildingType)
    local lower = string.lower(buildingType)

    if string.find(lower, "hospital") or string.find(lower, "مستشفى") then
        local character = player.Character
        if character then
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = hum.MaxHealth end
        end
        Remotes:FireClient("ShowNotification", player, {
            title = "المستشفى",
            message = "تم علاجك بالكامل!",
            icon = "🏥",
            duration = 3,
        })

    elseif string.find(lower, "bank") or string.find(lower, "بنك") then
        local data = DataService:Get(player)
        local cash = data and data.cash or 0
        Remotes:FireClient("ShowNotification", player, {
            title = "البنك",
            message = "رصيدك الحالي: $" .. tostring(cash),
            icon = "🏦",
            duration = 4,
        })

    elseif string.find(lower, "mall") or string.find(lower, "مول") then
        Remotes:FireClient("OpenShop", player)

    elseif string.find(lower, "police") or string.find(lower, "شرطة") then
        Remotes:FireClient("ShowNotification", player, {
            title = "مركز الشرطة",
            message = "مرحباً بك في مركز الشرطة — تقدّم لوظيفة شرطي!",
            icon = "🚔",
            duration = 4,
        })

    elseif string.find(lower, "fire") or string.find(lower, "إطفاء") then
        Remotes:FireClient("ShowNotification", player, {
            title = "الإطفاء",
            message = "مرحباً بك في محطة الإطفاء — تقدّم لوظيفة إطفائي!",
            icon = "🚒",
            duration = 4,
        })

    elseif string.find(lower, "airport") or string.find(lower, "مطار") then
        Remotes:FireClient("ShowNotification", player, {
            title = "المطار",
            message = "مرحباً بك في المطار!",
            icon = "✈️",
            duration = 3,
        })

    elseif string.find(lower, "dealer") or string.find(lower, "معرض") then
        Remotes:FireClient("ShowNotification", player, {
            title = "معرض السيارات",
            message = "تصفّح السيارات المتاحة!",
            icon = "🚗",
            duration = 3,
        })

    elseif string.find(lower, "restaurant") or string.find(lower, "مطعم") then
        Remotes:FireClient("ShowNotification", player, {
            title = "المطعم",
            message = "أهلاً وسهلاً — استمتع بوجبتك!",
            icon = "🍽️",
            duration = 3,
        })

    else
        Remotes:FireClient("ShowNotification", player, {
            title = buildingType,
            message = "مرحباً بك!",
            duration = 3,
        })
    end
end

return BuildingService
