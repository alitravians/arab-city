local _Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DataManager -- forward reference, set in Init

local EconomyService = {}

function EconomyService:Init(dataManager)
    DataManager = dataManager

    RemoteManager:OnServerEvent("DailyReward", function(player)
        self:ClaimDailyReward(player)
    end)

    RemoteManager:OnServerEvent("RequestPurchase", function(player, itemType, itemId)
        self:ProcessPurchase(player, itemType, itemId)
    end)
end

function EconomyService:GetBalance(player: Player): number
    return DataManager:GetValue(player, "cash") or 0
end

function EconomyService:AddMoney(player: Player, amount: number, reason: string?)
    if amount <= 0 then
        return false
    end
    DataManager:IncrementValue(player, "cash", amount)
    DataManager:IncrementValue(player, "totalEarned", amount)
    RemoteManager:FireClient("UpdateMoney", player, self:GetBalance(player), amount, reason or "")
    return true
end

function EconomyService:RemoveMoney(player: Player, amount: number, reason: string?): boolean
    local balance = self:GetBalance(player)
    if balance < amount then
        return false
    end
    DataManager:IncrementValue(player, "cash", -amount)
    RemoteManager:FireClient("UpdateMoney", player, self:GetBalance(player), -amount, reason or "")
    return true
end

function EconomyService:CanAfford(player: Player, amount: number): boolean
    return self:GetBalance(player) >= amount
end

function EconomyService:Transfer(fromPlayer: Player, toPlayer: Player, amount: number): boolean
    if not self:CanAfford(fromPlayer, amount) then
        return false
    end
    self:RemoveMoney(fromPlayer, amount, "تحويل إلى " .. toPlayer.Name)
    self:AddMoney(toPlayer, amount, "تحويل من " .. fromPlayer.Name)
    return true
end

function EconomyService:ClaimDailyReward(player: Player)
    local lastClaim = DataManager:GetValue(player, "lastDailyReward") or 0
    local now = DateTime.now().UnixTimestamp
    local timeSinceLast = now - lastClaim

    if timeSinceLast < 86400 then -- 24 hours
        RemoteManager:FireClient("CodeResult", player, false, "لقد استلمت المكافأة اليومية بالفعل!")
        return
    end

    local rank = DataManager:GetValue(player, "rank") or "None"
    local bonus = 0
    if rank ~= "None" and Constants.RANKS[rank] then
        bonus = Constants.RANKS[rank].dailyBonus
    end

    local total = Constants.DAILY_REWARD + bonus
    self:AddMoney(player, total, "مكافأة يومية")
    DataManager:SetValue(player, "lastDailyReward", now)
    RemoteManager:FireClient("CodeResult", player, true, `حصلت على {total}$ مكافأة يومية!`)
end

function EconomyService:ProcessPurchase(player: Player, itemType: string, itemId: string)
    if itemType == "vehicle" then
        self:_purchaseVehicle(player, itemId)
    elseif itemType == "camera" then
        self:_purchaseCamera(player, itemId)
    end
end

function EconomyService:_purchaseVehicle(player: Player, vehicleId: string)
    local vehicleData = nil
    for _, v in ipairs(Constants.VEHICLES) do
        if v.id == vehicleId then
            vehicleData = v
            break
        end
    end

    if not vehicleData then
        return
    end

    local owned = DataManager:GetValue(player, "ownedVehicles") or {}
    for _, id in ipairs(owned) do
        if id == vehicleId then
            RemoteManager:FireClient("CodeResult", player, false, "أنت تملك هذه السيارة بالفعل!")
            return
        end
    end

    if not self:RemoveMoney(player, vehicleData.price, "شراء " .. vehicleData.nameAr) then
        RemoteManager:FireClient("CodeResult", player, false, "رصيدك غير كافٍ!")
        return
    end

    DataManager:AddToTable(player, "ownedVehicles", vehicleId)
    DataManager:IncrementValue(player, "carsBought", 1)
    RemoteManager:FireClient("CodeResult", player, true, `تم شراء {vehicleData.nameAr} بنجاح!`)
end

function EconomyService:_purchaseCamera(player: Player, cameraId: string)
    local cameraName = nil
    local cameraPrice = 0
    local cameraNameAr = ""
    for name, cam in pairs(Constants.CAMERAS) do
        if cam.id == cameraId then
            cameraName = name
            cameraPrice = cam.price
            cameraNameAr = cam.nameAr
            break
        end
    end

    if not cameraName then
        return
    end

    -- Prevent duplicate purchase (server-side validation)
    local currentCamera = DataManager:GetValue(player, "cameraType") or "Beginner"
    if currentCamera == cameraName then
        RemoteManager:FireClient("CodeResult", player, false, "أنت تملك هذه الكاميرا بالفعل!")
        return
    end

    if not self:RemoveMoney(player, cameraPrice, "شراء " .. cameraNameAr) then
        RemoteManager:FireClient("CodeResult", player, false, "رصيدك غير كافٍ!")
        return
    end

    DataManager:SetValue(player, "cameraType", cameraName)
    RemoteManager:FireClient("CodeResult", player, true, `تم ترقية الكاميرا إلى {cameraNameAr}!`)
end

return EconomyService
