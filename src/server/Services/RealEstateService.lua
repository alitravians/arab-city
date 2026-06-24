--[[
    Arab City v2.0 - RealEstateService
    Property purchase system.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RealEstateService = {}

local Shared, Constants, Remotes, DataService, EconomyService

function RealEstateService:Init(dataService, economyService)
    DataService = dataService
    EconomyService = economyService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("PurchaseProperty", function(player, propertyId)
        self:_purchase(player, propertyId)
    end)
end

function RealEstateService:_purchase(player, propertyId)
    if type(propertyId) ~= "string" then return end

    local property = nil
    for _, p in ipairs(Constants.PROPERTIES) do
        if p.id == propertyId then property = p break end
    end
    if not property then
        Remotes:FireClient("PropertyResult", player, { success = false, message = "العقار غير موجود" })
        return
    end

    local data = DataService:Get(player)
    if not data then return end

    for _, owned in ipairs(data.properties) do
        if owned == propertyId then
            Remotes:FireClient("PropertyResult", player, { success = false, message = "تملك هذا العقار بالفعل" })
            return
        end
    end

    if not EconomyService:RemoveCash(player, property.price) then
        Remotes:FireClient("PropertyResult", player, { success = false, message = "رصيدك غير كافٍ" })
        return
    end

    table.insert(data.properties, propertyId)
    Remotes:FireClient("PropertyResult", player, {
        success = true,
        message = "تم شراء " .. property.name,
        propertyId = propertyId,
    })
    Remotes:FireClient("ShowNotification", player, {
        title = "عقار جديد!",
        message = "اشتريت " .. property.name,
        icon = "🏠", duration = 4,
    })
end

return RealEstateService
