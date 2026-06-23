local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DataManager
local EconomyService

local AchievementService = {}

function AchievementService:Init(dataManager, economyService)
    DataManager = dataManager
    EconomyService = economyService

    RemoteManager:SetServerCallback("GetAchievements", function(player)
        return self:GetPlayerAchievements(player)
    end)

    -- Check achievements periodically
    task.spawn(function()
        while true do
            task.wait(10)
            for _, player in ipairs(Players:GetPlayers()) do
                self:_checkAchievements(player)
            end
        end
    end)
end

function AchievementService:_checkAchievements(player: Player)
    local data = DataManager:GetData(player)
    if not data then
        return
    end

    local unlocked = data.achievements or {}

    for _, achievement in ipairs(Constants.ACHIEVEMENTS) do
        -- Skip already unlocked
        local alreadyUnlocked = false
        for _, id in ipairs(unlocked) do
            if id == achievement.id then
                alreadyUnlocked = true
                break
            end
        end

        if not alreadyUnlocked then
            local currentValue = data[achievement.trackKey] or 0
            if type(currentValue) == "table" then
                currentValue = #currentValue
            end

            if currentValue >= achievement.target then
                self:_unlockAchievement(player, achievement)
            end
        end
    end
end

function AchievementService:_unlockAchievement(player: Player, achievement)
    DataManager:AddToTable(player, "achievements", achievement.id)

    if achievement.reward > 0 then
        EconomyService:AddMoney(player, achievement.reward, "إنجاز: " .. achievement.nameAr)
    end

    RemoteManager:FireClient("AchievementUnlocked", player, {
        id = achievement.id,
        nameAr = achievement.nameAr,
        description = achievement.description,
        reward = achievement.reward,
    })
end

function AchievementService:GetPlayerAchievements(player: Player)
    local data = DataManager:GetData(player)
    if not data then
        return {}
    end

    local unlocked = data.achievements or {}
    local result = {}

    for _, achievement in ipairs(Constants.ACHIEVEMENTS) do
        local isUnlocked = false
        for _, id in ipairs(unlocked) do
            if id == achievement.id then
                isUnlocked = true
                break
            end
        end

        local currentValue = data[achievement.trackKey] or 0
        if type(currentValue) == "table" then
            currentValue = #currentValue
        end

        table.insert(result, {
            id = achievement.id,
            nameAr = achievement.nameAr,
            description = achievement.description,
            target = achievement.target,
            progress = math.min(currentValue, achievement.target),
            unlocked = isUnlocked,
            reward = achievement.reward,
        })
    end

    return result
end

return AchievementService
