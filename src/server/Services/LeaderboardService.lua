--[[
    Arab City v2.0 - LeaderboardService
    Ranked leaderboards: cash, fame, level.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardService = {}

local Shared, Remotes, DataService
local UPDATE_INTERVAL = 30

function LeaderboardService:Init(dataService)
    DataService = dataService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("RequestLeaderboard", function(player, category)
        self:_sendBoard(player, category)
    end)

    task.spawn(function()
        while true do
            task.wait(UPDATE_INTERVAL)
            self:_broadcastAll()
        end
    end)
end

function LeaderboardService:_collect(category)
    local entries = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local data = DataService:Get(player)
        if data then
            local value = 0
            if category == "cash" then
                value = data.cash or 0
            elseif category == "fame" then
                value = data.fame or 0
            elseif category == "level" then
                value = data.level or 1
            end
            table.insert(entries, {
                name = player.DisplayName,
                userId = player.UserId,
                value = value,
            })
        end
    end
    table.sort(entries, function(a, b) return a.value > b.value end)
    local top = {}
    for i = 1, math.min(10, #entries) do
        top[i] = entries[i]
    end
    return top
end

function LeaderboardService:_sendBoard(player, category)
    if type(category) ~= "string" then return end
    if category ~= "cash" and category ~= "fame" and category ~= "level" then return end
    local board = self:_collect(category)
    Remotes:FireClient("LeaderboardData", player, { category = category, entries = board })
end

function LeaderboardService:_broadcastAll()
    for _, category in ipairs({ "cash", "fame", "level" }) do
        local board = self:_collect(category)
        Remotes:FireAllClients("LeaderboardData", { category = category, entries = board })
    end
end

return LeaderboardService
