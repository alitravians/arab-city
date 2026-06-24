--[[
    Arab City - Daily Challenge Service
    Assigns daily challenges and tracks progress
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DailyChallengeService = {}
DailyChallengeService._dataManager = nil
DailyChallengeService._xpService = nil

function DailyChallengeService:Init(dataManager, xpService)
    self._dataManager = dataManager
    self._xpService = xpService

    RemoteManager:OnServerEvent("ClaimDailyChallenge", function(player, challengeId)
        self:_claimChallenge(player, challengeId)
    end)

    RemoteManager:RegisterFunction("GetDailyChallenges", function(player)
        return self:_getChallenges(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function() self:_setupPlayer(player) end)
    end
    Players.PlayerAdded:Connect(function(player)
        task.spawn(function() self:_setupPlayer(player) end)
    end)
end

function DailyChallengeService:_setupPlayer(player: Player)
    local data = self._dataManager:WaitForData(player)
    if not data then return end
    self:_ensureDailyChallenges(data)
end

function DailyChallengeService:_getTodayKey(): string
    local dt = DateTime.now()
    local utc = dt:ToUniversalTime()
    return string.format("%04d-%02d-%02d", utc.Year, utc.Month, utc.Day)
end

function DailyChallengeService:_ensureDailyChallenges(data: { [string]: any })
    local today = self:_getTodayKey()
    if data.dailyChallengeDate == today then return end

    -- Reset daily counters
    data.dailyChallengeDate = today
    data.totalEarnedToday = 0
    data.dailyPhotos = 0
    data.dailyMessages = 0
    data.dailyVisits = 0
    data.walkDistance = 0

    -- Assign today's challenges
    local challenges = {}
    for _, dc in ipairs(Constants.DAILY_CHALLENGES) do
        table.insert(challenges, {
            id = dc.id,
            progress = 0,
            target = dc.target,
            reward = dc.reward,
            claimed = false,
        })
    end
    data.dailyChallenges = challenges
end

function DailyChallengeService:UpdateProgress(player: Player, trackKey: string, amount: number)
    local data = self._dataManager:GetPlayerData(player)
    if not data then return end

    self:_ensureDailyChallenges(data)

    -- Update the tracking key
    data[trackKey] = (data[trackKey] or 0) + amount

    -- Update challenge progress
    for _, challenge in ipairs(data.dailyChallenges or {}) do
        for _, dc in ipairs(Constants.DAILY_CHALLENGES) do
            if dc.id == challenge.id and dc.trackKey == trackKey then
                challenge.progress = data[trackKey]
                if challenge.progress >= challenge.target and not challenge.claimed then
                    RemoteManager:FireClient(player, "DailyChallengeUpdate", challenge.id, challenge.progress, true)
                    RemoteManager:FireClient(player, "ShowNotification", "challenge", "تحدي مكتمل! اجمع مكافأتك")
                end
                break
            end
        end
    end
end

function DailyChallengeService:_claimChallenge(player: Player, challengeId: string)
    local data = self._dataManager:GetPlayerData(player)
    if not data then return end

    for _, challenge in ipairs(data.dailyChallenges or {}) do
        if challenge.id == challengeId then
            if challenge.claimed then
                RemoteManager:FireClient(player, "ShowNotification", "error", "جمعت هالمكافأة مسبقاً")
                return
            end
            if challenge.progress < challenge.target then
                RemoteManager:FireClient(player, "ShowNotification", "error", "التحدي غير مكتمل بعد")
                return
            end

            challenge.claimed = true
            data.cash = data.cash + challenge.reward
            RemoteManager:FireClient(player, "MoneyUpdate", data.cash)
            RemoteManager:FireClient(player, "ShowNotification", "success", "+" .. challenge.reward .. "$ مكافأة تحدي!")

            if self._xpService then
                self._xpService:AwardXP(player, "mission_complete")
            end
            return
        end
    end
end

function DailyChallengeService:_getChallenges(player: Player): { any }
    local data = self._dataManager:GetPlayerData(player)
    if not data then return {} end
    self:_ensureDailyChallenges(data)
    return data.dailyChallenges or {}
end

return DailyChallengeService
