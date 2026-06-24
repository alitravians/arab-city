local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local RemoteManager = Shared.RemoteManager

local DataManager
local EconomyService

local CodeService = {}

-- Active codes - add/modify as needed
CodeService._codes = {
    {
        code = "ARABCITY",
        reward = { type = "cash", amount = 5000 },
        messageAr = "حصلت على 5,000$ مجاناً!",
        maxUses = -1, -- unlimited
    },
    {
        code = "WELCOME",
        reward = { type = "cash", amount = 2000 },
        messageAr = "مرحباً بك! حصلت على 2,000$!",
        maxUses = -1,
    },
    {
        code = "VIP2024",
        reward = { type = "cash", amount = 10000 },
        messageAr = "كود VIP! حصلت على 10,000$!",
        maxUses = 1000,
    },
    {
        code = "SPEED",
        reward = { type = "vehicle", vehicleId = "sport_coupe" },
        messageAr = "حصلت على كوبيه رياضية مجاناً!",
        maxUses = 500,
    },
    {
        code = "CAMERA",
        reward = { type = "camera", cameraType = "Professional" },
        messageAr = "حصلت على كاميرا احترافية!",
        maxUses = -1,
    },
    {
        code = "LAUNCH",
        reward = { type = "cash", amount = 25000 },
        messageAr = "كود الإطلاق! حصلت على 25,000$!",
        maxUses = 2000,
    },
}

CodeService._useCounts = {}

function CodeService:Init(dataManager, economyService)
    DataManager = dataManager
    EconomyService = economyService

    for _, codeData in ipairs(self._codes) do
        self._useCounts[codeData.code] = 0
    end

    RemoteManager:OnServerEvent("RedeemCode", function(player, inputCode)
        self:RedeemCode(player, inputCode)
    end)
end

function CodeService:RedeemCode(player: Player, inputCode: string)
    if type(inputCode) ~= "string" then
        return
    end

    local upperCode = string.upper(string.gsub(inputCode, "%s+", ""))

    -- Find the code
    local codeData = nil
    for _, cd in ipairs(self._codes) do
        if cd.code == upperCode then
            codeData = cd
            break
        end
    end

    if not codeData then
        RemoteManager:FireClient("CodeResult", player, false, "الكود غير صالح!")
        return
    end

    -- Check if already redeemed
    local redeemed = DataManager:GetValue(player, "redeemedCodes") or {}
    for _, code in ipairs(redeemed) do
        if code == upperCode then
            RemoteManager:FireClient("CodeResult", player, false, "لقد استخدمت هذا الكود من قبل!")
            return
        end
    end

    -- Check max uses
    if codeData.maxUses > 0 and (self._useCounts[upperCode] or 0) >= codeData.maxUses then
        RemoteManager:FireClient("CodeResult", player, false, "هذا الكود وصل للحد الأقصى من الاستخدام!")
        return
    end

    -- Apply reward
    local reward = codeData.reward
    if reward.type == "cash" then
        EconomyService:AddMoney(player, reward.amount, "كود: " .. upperCode)
    elseif reward.type == "vehicle" then
        local owned = DataManager:GetValue(player, "ownedVehicles") or {}
        local alreadyOwns = false
        for _, id in ipairs(owned) do
            if id == reward.vehicleId then
                alreadyOwns = true
                break
            end
        end
        if not alreadyOwns then
            DataManager:AddToTable(player, "ownedVehicles", reward.vehicleId)
        end
    elseif reward.type == "camera" then
        DataManager:SetValue(player, "cameraType", reward.cameraType)
    end

    -- Mark as redeemed
    DataManager:AddToTable(player, "redeemedCodes", upperCode)
    self._useCounts[upperCode] = (self._useCounts[upperCode] or 0) + 1

    RemoteManager:FireClient("CodeResult", player, true, codeData.messageAr)
end

return CodeService
