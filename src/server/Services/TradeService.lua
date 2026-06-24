--[[
    Arab City - Trade Service
    Player-to-player trading of cash and vehicles
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local RemoteManager = Shared.RemoteManager

local TradeService = {}
TradeService._dataManager = nil
TradeService._xpService = nil
TradeService._activeTrades = {}

function TradeService:Init(dataManager, xpService)
    self._dataManager = dataManager
    self._xpService = xpService

    RemoteManager:OnServerEvent("TradeRequest", function(player, targetUserId, offerCash, offerVehicleId)
        self:_sendTradeRequest(player, targetUserId, offerCash or 0, offerVehicleId or "")
    end)

    RemoteManager:OnServerEvent("TradeResponse", function(player, tradeId, accepted)
        self:_handleResponse(player, tradeId, accepted)
    end)
end

function TradeService:_sendTradeRequest(player: Player, targetUserId: number, offerCash: number, offerVehicleId: string)
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then
        RemoteManager:FireClient(player, "ShowNotification", "error", "اللاعب غير متصل")
        return
    end

    if targetPlayer == player then return end

    local myData = self._dataManager:GetPlayerData(player)
    if not myData then return end

    if offerCash > 0 and myData.cash < offerCash then
        RemoteManager:FireClient(player, "ShowNotification", "error", "رصيدك غير كافي")
        return
    end

    local tradeId = player.UserId .. "_" .. targetUserId .. "_" .. os.clock()
    self._activeTrades[tradeId] = {
        fromPlayer = player,
        toPlayer = targetPlayer,
        offerCash = offerCash,
        offerVehicleId = offerVehicleId,
        timestamp = os.clock(),
    }

    RemoteManager:FireClient(targetPlayer, "TradeUpdate", "incoming", {
        tradeId = tradeId,
        fromName = player.Name,
        fromUserId = player.UserId,
        offerCash = offerCash,
        offerVehicleId = offerVehicleId,
    })

    RemoteManager:FireClient(player, "ShowNotification", "info", "تم إرسال عرض التبادل لـ " .. targetPlayer.Name)

    -- Auto-expire after 60 seconds
    task.delay(60, function()
        if self._activeTrades[tradeId] then
            self._activeTrades[tradeId] = nil
            pcall(function()
                RemoteManager:FireClient(player, "TradeUpdate", "expired", tradeId)
            end)
        end
    end)
end

function TradeService:_handleResponse(player: Player, tradeId: string, accepted: boolean)
    local trade = self._activeTrades[tradeId]
    if not trade then return end
    if trade.toPlayer ~= player then return end

    self._activeTrades[tradeId] = nil

    if not accepted then
        RemoteManager:FireClient(trade.fromPlayer, "TradeUpdate", "declined", tradeId)
        RemoteManager:FireClient(player, "ShowNotification", "info", "رفضت عرض التبادل")
        return
    end

    local fromData = self._dataManager:GetPlayerData(trade.fromPlayer)
    local toData = self._dataManager:GetPlayerData(player)
    if not fromData or not toData then return end

    -- Transfer cash
    if trade.offerCash > 0 then
        if fromData.cash < trade.offerCash then
            RemoteManager:FireClient(trade.fromPlayer, "ShowNotification", "error", "رصيدك غير كافي")
            return
        end
        fromData.cash = fromData.cash - trade.offerCash
        toData.cash = toData.cash + trade.offerCash
        RemoteManager:FireClient(trade.fromPlayer, "MoneyUpdate", fromData.cash)
        RemoteManager:FireClient(player, "MoneyUpdate", toData.cash)
    end

    -- Transfer vehicle
    if trade.offerVehicleId ~= "" then
        local vehicleIdx = nil
        for i, vid in ipairs(fromData.ownedVehicles or {}) do
            if vid == trade.offerVehicleId then
                vehicleIdx = i
                break
            end
        end
        if vehicleIdx then
            table.remove(fromData.ownedVehicles, vehicleIdx)
            table.insert(toData.ownedVehicles, trade.offerVehicleId)
        end
    end

    if self._xpService then
        self._xpService:AwardXP(trade.fromPlayer, "trade_complete")
        self._xpService:AwardXP(player, "trade_complete")
    end

    RemoteManager:FireClient(trade.fromPlayer, "TradeUpdate", "completed", tradeId)
    RemoteManager:FireClient(player, "TradeUpdate", "completed", tradeId)
    RemoteManager:FireClient(trade.fromPlayer, "ShowNotification", "success", "تم التبادل بنجاح!")
    RemoteManager:FireClient(player, "ShowNotification", "success", "تم التبادل بنجاح!")
end

return TradeService
