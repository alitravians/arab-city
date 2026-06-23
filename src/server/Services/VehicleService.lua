local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DataManager

local VehicleService = {}
VehicleService._spawnedVehicles = {} -- { [userId] = vehicleModel }

function VehicleService:Init(dataManager)
    DataManager = dataManager

    RemoteManager:OnServerEvent("SpawnVehicle", function(player, vehicleId)
        self:SpawnVehicle(player, vehicleId)
    end)

    RemoteManager:OnServerEvent("DespawnVehicle", function(player)
        self:DespawnVehicle(player)
    end)

    RemoteManager:SetServerCallback("GetVehicleList", function(player)
        return self:GetPlayerVehicles(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:DespawnVehicle(player)
    end)
end

function VehicleService:GetVehicleData(vehicleId: string)
    for _, v in ipairs(Constants.VEHICLES) do
        if v.id == vehicleId then
            return v
        end
    end
    return nil
end

function VehicleService:GetPlayerVehicles(player: Player)
    local owned = DataManager:GetValue(player, "ownedVehicles") or {}
    local vehicles = {}
    for _, vehicleId in ipairs(owned) do
        local data = self:GetVehicleData(vehicleId)
        if data then
            table.insert(vehicles, data)
        end
    end
    return vehicles
end

function VehicleService:OwnsVehicle(player: Player, vehicleId: string): boolean
    local owned = DataManager:GetValue(player, "ownedVehicles") or {}
    for _, id in ipairs(owned) do
        if id == vehicleId then
            return true
        end
    end
    return false
end

function VehicleService:SpawnVehicle(player: Player, vehicleId: string)
    if not self:OwnsVehicle(player, vehicleId) then
        RemoteManager:FireClient("CodeResult", player, false, "أنت لا تملك هذه السيارة!")
        return
    end

    -- Despawn existing vehicle first
    self:DespawnVehicle(player)

    local vehicleData = self:GetVehicleData(vehicleId)
    if not vehicleData then
        return
    end

    local character = player.Character
    if not character then
        return
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    -- Look for vehicle template in ReplicatedStorage
    local vehicleTemplates = ReplicatedStorage:FindFirstChild("VehicleTemplates")
    local template = vehicleTemplates and vehicleTemplates:FindFirstChild(vehicleId)

    local vehicleModel
    if template then
        vehicleModel = template:Clone()
    else
        -- Create a placeholder vehicle
        vehicleModel = self:_createPlaceholderVehicle(vehicleData)
    end

    vehicleModel.Name = "Vehicle_" .. player.UserId
    -- Position the vehicle near the player
    local spawnPos = rootPart.Position + rootPart.CFrame.LookVector * 10 + Vector3.new(0, 2, 0)

    if vehicleModel.PrimaryPart then
        vehicleModel:SetPrimaryPartCFrame(CFrame.new(spawnPos))
    else
        local primaryPart = vehicleModel:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            vehicleModel.PrimaryPart = primaryPart
            vehicleModel:SetPrimaryPartCFrame(CFrame.new(spawnPos))
        end
    end

    vehicleModel.Parent = workspace:FindFirstChild("Vehicles") or workspace

    -- Create VehicleSeat if needed
    local seat = vehicleModel:FindFirstChildWhichIsA("VehicleSeat")
    if seat then
        seat.MaxSpeed = vehicleData.maxSpeed
    end

    self._spawnedVehicles[player.UserId] = vehicleModel
    DataManager:SetValue(player, "currentVehicle", vehicleId)

    RemoteManager:FireClient("VehicleUpdate", player, "spawned", vehicleId)
    RemoteManager:FireClient("CodeResult", player, true, `تم استدعاء {vehicleData.nameAr}!`)
end

function VehicleService:DespawnVehicle(player: Player)
    local existing = self._spawnedVehicles[player.UserId]
    if existing then
        existing:Destroy()
        self._spawnedVehicles[player.UserId] = nil
    end
    DataManager:SetValue(player, "currentVehicle", "")
    RemoteManager:FireClient("VehicleUpdate", player, "despawned", "")
end

function VehicleService:_createPlaceholderVehicle(vehicleData)
    local model = Instance.new("Model")
    model.Name = vehicleData.id

    -- Body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(6, 2, 10)
    body.Color = Color3.fromRGB(math.random(50, 255), math.random(50, 255), math.random(50, 255))
    body.Anchored = false
    body.Parent = model

    -- Roof
    local roof = Instance.new("Part")
    roof.Name = "Roof"
    roof.Size = Vector3.new(5, 1.5, 5)
    roof.Position = body.Position + Vector3.new(0, 1.75, -1)
    roof.Color = body.Color
    roof.Anchored = false
    roof.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = body
    weld.Part1 = roof
    weld.Parent = roof

    -- VehicleSeat
    local seat = Instance.new("VehicleSeat")
    seat.Name = "DrivingSeat"
    seat.Size = Vector3.new(2, 0.5, 2)
    seat.Position = body.Position + Vector3.new(0, 1.25, 1)
    seat.MaxSpeed = vehicleData.maxSpeed
    seat.Torque = 5000
    seat.TurnSpeed = 3
    seat.Anchored = false
    seat.Parent = model

    local seatWeld = Instance.new("WeldConstraint")
    seatWeld.Part0 = body
    seatWeld.Part1 = seat
    seatWeld.Parent = seat

    -- Wheels
    local wheelPositions = {
        Vector3.new(-2.5, -1, 3.5),
        Vector3.new(2.5, -1, 3.5),
        Vector3.new(-2.5, -1, -3.5),
        Vector3.new(2.5, -1, -3.5),
    }

    for i, offset in ipairs(wheelPositions) do
        local wheel = Instance.new("Part")
        wheel.Name = "Wheel_" .. i
        wheel.Shape = Enum.PartType.Cylinder
        wheel.Size = Vector3.new(1.5, 1.5, 1.5)
        wheel.Position = body.Position + offset
        wheel.Color = Color3.fromRGB(30, 30, 30)
        wheel.Anchored = false
        wheel.Parent = model

        local wheelWeld = Instance.new("WeldConstraint")
        wheelWeld.Part0 = body
        wheelWeld.Part1 = wheel
        wheelWeld.Parent = wheel
    end

    -- Headlights
    local headlightPositions = {
        Vector3.new(-2, 0.5, 5),
        Vector3.new(2, 0.5, 5),
    }

    for i, offset in ipairs(headlightPositions) do
        local light = Instance.new("Part")
        light.Name = "Headlight_" .. i
        light.Size = Vector3.new(0.8, 0.8, 0.2)
        light.Position = body.Position + offset
        light.Color = Color3.fromRGB(255, 255, 200)
        light.Material = Enum.Material.Neon
        light.Anchored = false
        light.Parent = model

        local spotlight = Instance.new("SpotLight")
        spotlight.Brightness = 3
        spotlight.Range = 30
        spotlight.Angle = 45
        spotlight.Face = Enum.NormalId.Front
        spotlight.Parent = light

        local lightWeld = Instance.new("WeldConstraint")
        lightWeld.Part0 = body
        lightWeld.Part1 = light
        lightWeld.Parent = light
    end

    -- Taillights
    for i, xOffset in ipairs({ -2, 2 }) do
        local taillight = Instance.new("Part")
        taillight.Name = "Taillight_" .. i
        taillight.Size = Vector3.new(0.8, 0.5, 0.2)
        taillight.Position = body.Position + Vector3.new(xOffset, 0.5, -5)
        taillight.Color = Color3.fromRGB(255, 0, 0)
        taillight.Material = Enum.Material.Neon
        taillight.Anchored = false
        taillight.Parent = model

        local tailWeld = Instance.new("WeldConstraint")
        tailWeld.Part0 = body
        tailWeld.Part1 = taillight
        tailWeld.Parent = taillight
    end

    -- Name display
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(4, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = false
    billboard.Parent = body

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = vehicleData.nameAr
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = billboard

    model.PrimaryPart = body
    return model
end

return VehicleService
