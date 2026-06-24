--[[
    Arab City - Leaderboard Service
    Tracks top players by cash, fame, level, totalEarned
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local LeaderboardService = {}
LeaderboardService._dataManager = nil
LeaderboardService._cache = {}
LeaderboardService._lastUpdate = 0

local UPDATE_INTERVAL = 30

function LeaderboardService:Init(dataManager)
    self._dataManager = dataManager

    RemoteManager:RegisterFunction("GetLeaderboardData", function(_player, category)
        return self:_getLeaderboard(category)
    end)

    task.spawn(function()
        while true do
            task.wait(UPDATE_INTERVAL)
            self:_refreshAll()
        end
    end)
end

function LeaderboardService:_refreshAll()
    for _, cat in ipairs(Constants.LEADERBOARD_CATEGORIES) do
        self:_refreshCategory(cat.id, cat.key)
    end
    self._lastUpdate = os.clock()
end

function LeaderboardService:_refreshCategory(catId: string, dataKey: string)
    local entries = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local data = self._dataManager:GetPlayerData(player)
        if data then
            table.insert(entries, {
                userId = player.UserId,
                name = player.DisplayName or player.Name,
                value = data[dataKey] or 0,
            })
        end
    end

    table.sort(entries, function(a, b) return a.value > b.value end)

    local top = {}
    for i = 1, math.min(10, #entries) do
        top[i] = entries[i]
        top[i].rank = i
    end

    self._cache[catId] = top
end

function LeaderboardService:_getLeaderboard(category: string): { any }
    if not self._cache[category] then
        for _, cat in ipairs(Constants.LEADERBOARD_CATEGORIES) do
            if cat.id == category then
                self:_refreshCategory(cat.id, cat.key)
                break
            end
        end
    end
    return self._cache[category] or {}
end

return LeaderboardService
