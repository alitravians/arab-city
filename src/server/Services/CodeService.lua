--[[
    Arab City v2.0 - CodeService
    Redeemable promo codes for cash rewards.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CodeService = {}

local Shared, Constants, Remotes, DataService, EconomyService

function CodeService:Init(dataService, economyService)
    DataService = dataService
    EconomyService = economyService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("RedeemCode", function(player, code)
        self:_redeem(player, code)
    end)
end

function CodeService:_redeem(player, code)
    if type(code) ~= "string" then return end
    code = string.upper(string.gsub(code, "%s+", ""))

    local codeData = Constants.CODES[code]
    if not codeData then
        Remotes:FireClient("RedeemResult", player, { success = false, message = "الكود غير صالح" })
        return
    end

    local data = DataService:Get(player)
    if not data then return end

    for _, redeemed in ipairs(data.redeemedCodes) do
        if redeemed == code then
            Remotes:FireClient("RedeemResult", player, { success = false, message = "استخدمت هذا الكود من قبل" })
            return
        end
    end

    table.insert(data.redeemedCodes, code)
    EconomyService:AddCash(player, codeData.reward)

    Remotes:FireClient("RedeemResult", player, {
        success = true,
        message = codeData.description .. " — حصلت على $" .. tostring(codeData.reward),
    })
    Remotes:FireClient("ShowNotification", player, {
        title = "تم تفعيل الكود!",
        message = "+" .. tostring(codeData.reward) .. "$",
        icon = "🎁", duration = 4,
    })
end

return CodeService
