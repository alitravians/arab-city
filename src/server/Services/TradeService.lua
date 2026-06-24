--[[
    Arab City v2.0 - TradeService
    Player-to-player trading of vehicles and properties.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TradeService = {}

local Shared, Remotes, DataService
local _activeTrades = {}

function TradeService:Init(dataService)
    DataService = dataService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("InitiateTrade", function(player, targetName)
        self:_initiate(player, targetName)
    end)

    Remotes:OnServerEvent("TradeAction", function(player, action, data)
        if action == "accept" then
            self:_accept(player, data)
        elseif action == "reject" then
            self:_reject(player, data)
        elseif action == "offer" then
            self:_setOffer(player, data)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        _activeTrades[player.UserId] = nil
    end)
end

function TradeService:_findPlayer(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == name or p.DisplayName == name then return p end
    end
    return nil
end

function TradeService:_initiate(player, targetName)
    if type(targetName) ~= "string" then return end
    local target = self:_findPlayer(targetName)
    if not target or target == player then
        Remotes:FireClient("TradeUpdate", player, { type = "error", message = "اللاعب غير موجود" })
        return
    end

    local tradeId = player.UserId .. "_" .. target.UserId .. "_" .. os.time()
    local trade = {
        id = tradeId,
        player1 = player.UserId,
        player2 = target.UserId,
        offer1 = { cash = 0, items = {} },
        offer2 = { cash = 0, items = {} },
        accepted1 = false,
        accepted2 = false,
    }
    _activeTrades[player.UserId] = trade
    _activeTrades[target.UserId] = trade

    Remotes:FireClient("TradeUpdate", player, { type = "started", tradeId = tradeId, partnerName = target.DisplayName })
    Remotes:FireClient("TradeUpdate", target, { type = "request", tradeId = tradeId, partnerName = player.DisplayName })
end

function TradeService:_setOffer(player, data)
    if type(data) ~= "table" then return end
    local trade = _activeTrades[player.UserId]
    if not trade then return end

    local cash = tonumber(data.cash) or 0
    cash = math.max(0, math.floor(cash))

    if trade.player1 == player.UserId then
        trade.offer1 = { cash = cash, items = data.items or {} }
    else
        trade.offer2 = { cash = cash, items = data.items or {} }
    end

    local partner = trade.player1 == player.UserId and trade.player2 or trade.player1
    local partnerPlayer = Players:GetPlayerByUserId(partner)
    if partnerPlayer then
        Remotes:FireClient("TradeUpdate", partnerPlayer, {
            type = "offerUpdated",
            offer = { cash = cash, items = data.items or {} },
        })
    end
end

function TradeService:_accept(player, data)
    local trade = _activeTrades[player.UserId]
    if not trade then return end

    if trade.player1 == player.UserId then
        trade.accepted1 = true
    else
        trade.accepted2 = true
    end

    if trade.accepted1 and trade.accepted2 then
        self:_executeTrade(trade)
    end
end

function TradeService:_reject(player, data)
    local trade = _activeTrades[player.UserId]
    if not trade then return end

    local partnerId = trade.player1 == player.UserId and trade.player2 or trade.player1
    _activeTrades[player.UserId] = nil
    _activeTrades[partnerId] = nil

    local partnerPlayer = Players:GetPlayerByUserId(partnerId)
    Remotes:FireClient("TradeUpdate", player, { type = "cancelled" })
    if partnerPlayer then
        Remotes:FireClient("TradeUpdate", partnerPlayer, { type = "cancelled" })
    end
end

function TradeService:_executeTrade(trade)
    local p1 = Players:GetPlayerByUserId(trade.player1)
    local p2 = Players:GetPlayerByUserId(trade.player2)
    if not p1 or not p2 then return end

    local d1 = DataService:Get(p1)
    local d2 = DataService:Get(p2)
    if not d1 or not d2 then return end

    local c1 = trade.offer1.cash
    local c2 = trade.offer2.cash
    if d1.cash < c1 or d2.cash < c2 then
        Remotes:FireClient("TradeUpdate", p1, { type = "error", message = "رصيد غير كافٍ" })
        Remotes:FireClient("TradeUpdate", p2, { type = "error", message = "رصيد غير كافٍ" })
        return
    end

    d1.cash = d1.cash - c1 + c2
    d2.cash = d2.cash - c2 + c1

    _activeTrades[trade.player1] = nil
    _activeTrades[trade.player2] = nil

    Remotes:FireClient("TradeUpdate", p1, { type = "completed" })
    Remotes:FireClient("TradeUpdate", p2, { type = "completed" })
    Remotes:FireClient("ShowNotification", p1, { title = "تم التبادل!", message = "تمت الصفقة بنجاح", icon = "🤝", duration = 4 })
    Remotes:FireClient("ShowNotification", p2, { title = "تم التبادل!", message = "تمت الصفقة بنجاح", icon = "🤝", duration = 4 })
end

return TradeService
