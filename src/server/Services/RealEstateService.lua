local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local RemoteManager = Shared.RemoteManager

local DataManager
local EconomyService

local RealEstateService = {}
RealEstateService._properties = {} -- { [propertyId] = propertyData }

function RealEstateService:Init(dataManager, economyService)
    DataManager = dataManager
    EconomyService = economyService

    self:_initProperties()

    RemoteManager:OnServerEvent("BuyProperty", function(player, propertyId)
        self:BuyProperty(player, propertyId)
    end)

    RemoteManager:OnServerEvent("SellProperty", function(player, propertyId)
        self:SellProperty(player, propertyId)
    end)

    RemoteManager:OnServerEvent("ListPropertyForSale", function(player, propertyId, price)
        self:ListForSale(player, propertyId, price)
    end)

    RemoteManager:SetServerCallback("GetPropertyList", function(_player)
        return self:GetAllProperties()
    end)
end

function RealEstateService:_initProperties()
    -- Initialize properties from workspace tagged parts
    for _, part in ipairs(CollectionService:GetTagged("Property")) do
        local config = part:FindFirstChild("PropertyConfig")
        if config then
            local propertyId = config:GetAttribute("PropertyId") or part.Name
            self._properties[propertyId] = {
                id = propertyId,
                name = config:GetAttribute("Name") or part.Name,
                nameAr = config:GetAttribute("NameAr") or part.Name,
                price = config:GetAttribute("Price") or 10000,
                rooms = config:GetAttribute("Rooms") or 2,
                area = config:GetAttribute("Area") or 100,
                owner = config:GetAttribute("Owner") or 0, -- UserId, 0 = unowned
                forSale = true,
                askingPrice = config:GetAttribute("Price") or 10000,
                position = part.Position,
                part = part,
            }
        end
    end

    -- If no workspace properties found, create sample properties
    if next(self._properties) == nil then
        local sampleProperties = {
            {
                id = "house_001", nameAr = "فيلا الشاطئ", price = 50000,
                rooms = 4, area = 250, owner = 0,
            },
            {
                id = "house_002", nameAr = "شقة وسط المدينة", price = 20000,
                rooms = 2, area = 100, owner = 0,
            },
            {
                id = "house_003", nameAr = "قصر الحي الراقي", price = 150000,
                rooms = 8, area = 600, owner = 0,
            },
            {
                id = "house_004", nameAr = "بيت الضاحية", price = 30000,
                rooms = 3, area = 150, owner = 0,
            },
            {
                id = "house_005", nameAr = "بنتهاوس فاخر", price = 100000,
                rooms = 5, area = 350, owner = 0,
            },
            {
                id = "apartment_001", nameAr = "استوديو اقتصادي", price = 8000,
                rooms = 1, area = 50, owner = 0,
            },
            {
                id = "mansion_001", nameAr = "قصر المارينا", price = 250000,
                rooms = 10, area = 800, owner = 0,
            },
        }
        for _, prop in ipairs(sampleProperties) do
            prop.forSale = true
            prop.askingPrice = prop.price
            self._properties[prop.id] = prop
        end
    end
end

function RealEstateService:GetAllProperties(): { [string]: any }
    local list = {}
    for id, prop in pairs(self._properties) do
        list[id] = {
            id = prop.id,
            name = prop.name,
            nameAr = prop.nameAr,
            price = prop.price,
            rooms = prop.rooms,
            area = prop.area,
            owner = prop.owner,
            forSale = prop.forSale,
            askingPrice = prop.askingPrice,
        }
    end
    return list
end

function RealEstateService:BuyProperty(player: Player, propertyId: string)
    local property = self._properties[propertyId]
    if not property then
        RemoteManager:FireClient("CodeResult", player, false, "العقار غير موجود!")
        return
    end

    if property.owner == player.UserId then
        RemoteManager:FireClient("CodeResult", player, false, "أنت تملك هذا العقار بالفعل!")
        return
    end

    if not property.forSale then
        RemoteManager:FireClient("CodeResult", player, false, "هذا العقار غير معروض للبيع!")
        return
    end

    local price = property.askingPrice
    if not EconomyService:RemoveMoney(player, price, "شراء " .. property.nameAr) then
        RemoteManager:FireClient("CodeResult", player, false, "رصيدك غير كافٍ!")
        return
    end

    -- Pay previous owner if any
    if property.owner > 0 then
        local ownerPlayer = Players:GetPlayerByUserId(property.owner)
        if ownerPlayer then
            EconomyService:AddMoney(ownerPlayer, price, "بيع " .. property.nameAr)
            DataManager:RemoveFromTable(ownerPlayer, "ownedProperties", propertyId)
            DataManager:IncrementValue(ownerPlayer, "housesSold", 1)
        end
    end

    property.owner = player.UserId
    property.forSale = false
    DataManager:AddToTable(player, "ownedProperties", propertyId)
    DataManager:IncrementValue(player, "housesBought", 1)

    RemoteManager:FireClient("CodeResult", player, true, `تم شراء {property.nameAr} بنجاح!`)
    RemoteManager:FireAllClients("PropertyUpdate", propertyId, {
        owner = player.UserId,
        ownerName = player.Name,
        forSale = false,
    })
end

function RealEstateService:SellProperty(player: Player, propertyId: string)
    local property = self._properties[propertyId]
    if not property then
        return
    end

    if property.owner ~= player.UserId then
        RemoteManager:FireClient("CodeResult", player, false, "أنت لا تملك هذا العقار!")
        return
    end

    -- Sell back to the city at 70% of original price
    local sellPrice = math.floor(property.price * 0.7)
    EconomyService:AddMoney(player, sellPrice, "بيع " .. property.nameAr)
    DataManager:RemoveFromTable(player, "ownedProperties", propertyId)
    DataManager:IncrementValue(player, "housesSold", 1)

    property.owner = 0
    property.forSale = true
    property.askingPrice = property.price

    RemoteManager:FireClient("CodeResult", player, true, `تم بيع {property.nameAr} مقابل {sellPrice}$!`)
    RemoteManager:FireAllClients("PropertyUpdate", propertyId, {
        owner = 0,
        ownerName = "",
        forSale = true,
        askingPrice = property.price,
    })
end

function RealEstateService:ListForSale(player: Player, propertyId: string, price: number)
    local property = self._properties[propertyId]
    if not property then
        return
    end

    if property.owner ~= player.UserId then
        RemoteManager:FireClient("CodeResult", player, false, "أنت لا تملك هذا العقار!")
        return
    end

    if price < 1000 then
        RemoteManager:FireClient("CodeResult", player, false, "الحد الأدنى للسعر 1,000$!")
        return
    end

    property.forSale = true
    property.askingPrice = price

    RemoteManager:FireClient("CodeResult", player, true, `تم عرض {property.nameAr} للبيع بسعر {price}$!`)
    RemoteManager:FireAllClients("PropertyUpdate", propertyId, {
        forSale = true,
        askingPrice = price,
    })
end

function RealEstateService:IsOwner(player: Player, propertyId: string): boolean
    local property = self._properties[propertyId]
    return property and property.owner == player.UserId
end

return RealEstateService
