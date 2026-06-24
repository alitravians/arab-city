--[[
    Arab City v2.0 - VehicleService
    Vehicle purchase and spawning.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local VehicleService = {}

local Shared, Constants, Remotes, DataService, EconomyService

function VehicleService:Init(dataService, economyService)
    DataService = dataService
    EconomyService = economyService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("PurchaseVehicle", function(player, vehicleId)
        self:_purchase(player, vehicleId)
    end)

    Remotes:OnServerEvent("SpawnVehicle", function(player, vehicleId)
        self:_spawn(player, vehicleId)
    end)
end

function VehicleService:_purchase(player, vehicleId)
    if type(vehicleId) ~= "string" then return end

    local vehicle = nil
    for _, v in ipairs(Constants.VEHICLES) do
        if v.id == vehicleId then vehicle = v break end
    end
    if not vehicle then
        Remotes:FireClient("VehicleResult", player, { success = false, message = "مركبة غير موجودة" })
        return
    end

    local data = DataService:Get(player)
    if not data then return end

    for _, owned in ipairs(data.vehicles) do
        if owned == vehicleId then
            Remotes:FireClient("VehicleResult", player, { success = false, message = "تملك هذه المركبة بالفعل" })
            return
        end
    end

    if not EconomyService:RemoveCash(player, vehicle.price) then
        Remotes:FireClient("VehicleResult", player, { success = false, message = "رصيدك غير كافٍ" })
        return
    end

    table.insert(data.vehicles, vehicleId)
    Remotes:FireClient("VehicleResult", player, {
        success = true,
        message = "تم شراء " .. vehicle.name,
        vehicleId = vehicleId,
    })
    Remotes:FireClient("ShowNotification", player, {
        title = "مركبة جديدة!",
        message = "اشتريت " .. vehicle.name,
        icon = "🚗", duration = 4,
    })
end

function VehicleService:_spawn(player, vehicleId)
    if type(vehicleId) ~= "string" then return end
    local data = DataService:Get(player)
    if not data then return end

    local owns = false
    for _, owned in ipairs(data.vehicles) do
        if owned == vehicleId then owns = true break end
    end
    if not owns then
        Remotes:FireClient("VehicleResult", player, { success = false, message = "لا تملك هذه المركبة" })
        return
    end

    local vehicle = nil
    for _, v in ipairs(Constants.VEHICLES) do
        if v.id == vehicleId then vehicle = v break end
    end
    if not vehicle then return end

    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local existingFolder = Workspace:FindFirstChild("PlayerVehicles")
    if not existingFolder then
        existingFolder = Instance.new("Folder")
        existingFolder.Name = "PlayerVehicles"
        existingFolder.Parent = Workspace
    end

    for _, child in ipairs(existingFolder:GetChildren()) do
        if child:GetAttribute("OwnerId") == player.UserId then
            child:Destroy()
        end
    end

    local spawnPos = root.CFrame * CFrame.new(0, 0, -10)

    local body = Instance.new("Part")
    body.Name = vehicle.name
    body.Size = Vector3.new(6, 3, 12)
    body.CFrame = spawnPos * CFrame.new(0, 2, 0)
    body.Anchored = false
    body.CanCollide = true
    body.BrickColor = BrickColor.random()
    body.Material = Enum.Material.SmoothPlastic
    body.TopSurface = Enum.SurfaceType.Smooth
    body.BottomSurface = Enum.SurfaceType.Smooth

    local seat = Instance.new("VehicleSeat")
    seat.Name = "DriverSeat"
    seat.Size = Vector3.new(2, 1, 2)
    seat.CFrame = body.CFrame * CFrame.new(0, -0.5, 2)
    seat.Anchored = false
    seat.MaxSpeed = vehicle.speed
    seat.Torque = vehicle.speed * 2
    seat.TurnSpeed = 2
    seat.Parent = body

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = body
    weld.Part1 = seat
    weld.Parent = body

    body:SetAttribute("OwnerId", player.UserId)
    body:SetAttribute("VehicleId", vehicleId)
    body.Parent = existingFolder

    Remotes:FireClient("VehicleResult", player, {
        success = true,
        message = "تم استدعاء " .. vehicle.name,
    })
end

return VehicleService
