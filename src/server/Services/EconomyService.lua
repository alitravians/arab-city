--[[
    Arab City v2.0 - EconomyService
    Manages player cash, welcome rewards, salary payments.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyService = {}

local Shared, Constants, Remotes, DataService

function EconomyService:Init(dataService)
    DataService = dataService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("UpdateCash", function(player, action, amount)
        -- clients cannot directly set cash; ignored for security
    end)

    Remotes:SetServerCallback("GetPlayerData", function(player)
        return DataService:Get(player)
    end)
end

function EconomyService:GiveWelcomeReward(player)
    local data = DataService:Get(player)
    if not data then return end
    if data.isNewPlayer then
        data.isNewPlayer = false
        self:AddCash(player, Constants.WELCOME_REWARD)
        Remotes:FireClient("ShowNotification", player, {
            title = "مرحباً بك!",
            message = "حصلت على " .. tostring(Constants.WELCOME_REWARD) .. "$ كمكافأة ترحيبية!",
            icon = "💰",
            duration = 5,
        })
    end
end

function EconomyService:GetCash(player)
    local data = DataService:Get(player)
    return data and data.cash or 0
end

function EconomyService:AddCash(player, amount)
    if type(amount) ~= "number" or amount ~= amount or amount <= 0 then return false end
    local data = DataService:Get(player)
    if not data then return false end
    local maxCash = Constants.MAX_CASH
    data.cash = math.min(data.cash + math.floor(amount), maxCash)
    Remotes:FireClient("UpdateCash", player, data.cash)
    return true
end

function EconomyService:RemoveCash(player, amount)
    if type(amount) ~= "number" or amount ~= amount or amount <= 0 then return false end
    local data = DataService:Get(player)
    if not data then return false end
    amount = math.floor(amount)
    if data.cash < amount then return false end
    data.cash = data.cash - amount
    Remotes:FireClient("UpdateCash", player, data.cash)
    return true
end

function EconomyService:SetCash(player, amount)
    if type(amount) ~= "number" or amount ~= amount then return false end
    local data = DataService:Get(player)
    if not data then return false end
    data.cash = math.clamp(math.floor(amount), 0, Constants.MAX_CASH)
    Remotes:FireClient("UpdateCash", player, data.cash)
    return true
end

function EconomyService:TransferCash(fromPlayer, toPlayer, amount)
    if not self:RemoveCash(fromPlayer, amount) then return false end
    if not self:AddCash(toPlayer, amount) then
        self:AddCash(fromPlayer, amount)
        return false
    end
    return true
end

return EconomyService
