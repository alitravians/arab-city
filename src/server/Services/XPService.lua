--[[
    Arab City - XP & Leveling Service
    Awards XP for actions and handles level-ups
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local XPService = {}
XPService._dataManager = nil

function XPService:Init(dataManager)
    self._dataManager = dataManager

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function() self:_setupPlayer(player) end)
    end
    Players.PlayerAdded:Connect(function(player)
        task.spawn(function() self:_setupPlayer(player) end)
    end)
end

function XPService:_setupPlayer(player: Player)
    local data = self._dataManager:WaitForData(player)
    if not data then return end
    RemoteManager:FireClient(player, "XPGain", 0, data.xp, data.level)
end

function XPService:AwardXP(player: Player, reason: string, amount: number?)
    local data = self._dataManager:GetPlayerData(player)
    if not data then return end

    local xpAmount = amount or (Constants.XP_REWARDS[reason] or 10)
    data.xp = (data.xp or 0) + xpAmount

    local leveledUp = false
    while data.level < Constants.MAX_LEVEL do
        local needed = Constants.getXPForLevel(data.level)
        if data.xp >= needed then
            data.xp = data.xp - needed
            data.level = data.level + 1
            leveledUp = true
        else
            break
        end
    end

    RemoteManager:FireClient(player, "XPGain", xpAmount, data.xp, data.level)

    if leveledUp then
        local bonus = data.level * 100
        data.cash = data.cash + bonus
        RemoteManager:FireClient(player, "LevelUp", data.level, bonus)
        RemoteManager:FireClient(player, "ShowNotification", "levelUp", "وصلت مستوى " .. data.level .. "! +" .. bonus .. "$")
        RemoteManager:FireClient(player, "MoneyUpdate", data.cash)
    end
end

return XPService
