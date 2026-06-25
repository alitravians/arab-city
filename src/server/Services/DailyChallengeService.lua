--[[
    Arab City v2.0 - DailyChallengeService
    Daily and weekly challenges with rewards.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DailyChallengeService = {}

local Shared, Constants, Remotes, DataService

function DailyChallengeService:Init(dataService)
    DataService = dataService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("ClaimDailyChallenge", function(player, challengeId)
        self:_claim(player, challengeId)
    end)
end

function DailyChallengeService:_claim(player, challengeId)
    if type(challengeId) ~= "string" then return end
    local data = DataService:Get(player)
    if not data then return end

    local challenge = nil
    for _, c in ipairs(Constants.DAILY_CHALLENGES) do
        if c.id == challengeId then
            challenge = c
            break
        end
    end
    if not challenge then return end

    if not data.dailyChallenges then
        data.dailyChallenges = {}
    end

    for _, claimed in ipairs(data.dailyChallenges) do
        if claimed == challengeId then
            Remotes:FireClient("ShowNotification", player, {
                title = "خطأ",
                message = "تم استلام المكافأة مسبقاً",
                duration = 3,
            })
            return
        end
    end

    data.cash = (data.cash or 0) + (challenge.reward or 0)
    table.insert(data.dailyChallenges, challengeId)

    Remotes:FireClient("UpdateCash", player, data.cash)
    Remotes:FireClient("ShowNotification", player, {
        title = "تحدي مكتمل!",
        message = challenge.name .. " — +" .. tostring(challenge.reward) .. "$",
        icon = "🏆",
        duration = 4,
    })
end

return DailyChallengeService
