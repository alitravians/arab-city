--[[
    Arab City v2.0 - ShopService
    Handles in-game shop purchases and inventory management.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopService = {}

local Shared, Constants, Remotes, DataService, EconomyService

function ShopService:Init(dataService, economyService)
    DataService = dataService
    EconomyService = economyService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("PurchaseItem", function(player, itemId)
        self:_purchase(player, itemId)
    end)
end

function ShopService:_purchase(player, itemId)
    if type(itemId) ~= "string" then return end

    local item = nil
    for _, shopItem in ipairs(Constants.SHOP_ITEMS) do
        if shopItem.id == itemId then
            item = shopItem
            break
        end
    end

    if not item then
        Remotes:FireClient("PurchaseResult", player, { success = false, message = "المنتج غير موجود" })
        return
    end

    local data = DataService:Get(player)
    if not data then return end

    for _, owned in ipairs(data.inventory) do
        if owned == itemId then
            Remotes:FireClient("PurchaseResult", player, { success = false, message = "تملك هذا المنتج بالفعل" })
            return
        end
    end

    if not EconomyService:RemoveCash(player, item.price) then
        Remotes:FireClient("PurchaseResult", player, { success = false, message = "رصيدك غير كافٍ" })
        return
    end

    table.insert(data.inventory, itemId)
    Remotes:FireClient("PurchaseResult", player, {
        success = true,
        message = "تم شراء " .. item.name,
        itemId = itemId,
    })
    Remotes:FireClient("ShowNotification", player, {
        title = "عملية شراء ناجحة!",
        message = "اشتريت " .. item.name,
        icon = "🛒", duration = 3,
    })
end

return ShopService
