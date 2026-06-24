local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local RemoteManager = Shared.RemoteManager

local DataManager
local EconomyService

local FameService = {}

-- Fame thresholds for income bonuses
FameService._tiers = {
    { minFame = 0,    incomeMultiplier = 1.0, title = "مجهول" },
    { minFame = 50,   incomeMultiplier = 1.1, title = "معروف" },
    { minFame = 200,  incomeMultiplier = 1.25, title = "مشهور" },
    { minFame = 500,  incomeMultiplier = 1.5, title = "نجم" },
    { minFame = 1000, incomeMultiplier = 2.0, title = "أسطورة" },
}

function FameService:Init(dataManager, economyService)
    DataManager = dataManager
    EconomyService = economyService

    -- Fame income loop (every 10 minutes)
    task.spawn(function()
        while true do
            task.wait(600)
            self:_distributeFameIncome()
        end
    end)
end

function FameService:GetFameTier(fame: number)
    local currentTier = self._tiers[1]
    for _, tier in ipairs(self._tiers) do
        if fame >= tier.minFame then
            currentTier = tier
        end
    end
    return currentTier
end

function FameService:_distributeFameIncome()
    for _, player in ipairs(Players:GetPlayers()) do
        local fame = DataManager:GetValue(player, "fame") or 0
        local tier = self:GetFameTier(fame)
        local followers = DataManager:GetValue(player, "followers") or {}

        -- Base fame income based on follower count
        local income = #followers * 2
        if income > 0 then
            income = math.floor(income * tier.incomeMultiplier)
            EconomyService:AddMoney(player, income, "دخل الشهرة")
            RemoteManager:FireClient("FameUpdate", player, fame, tier.title, income)
        end
    end
end

function FameService:AddFame(player: Player, amount: number)
    DataManager:IncrementValue(player, "fame", amount)
    local fame = DataManager:GetValue(player, "fame") or 0
    local tier = self:GetFameTier(fame)
    RemoteManager:FireClient("FameUpdate", player, fame, tier.title, 0)
end

return FameService
