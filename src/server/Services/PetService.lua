--[[
    Arab City - Pet Service
    Buy, equip, and manage pets that follow the player
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local PetService = {}
PetService._dataManager = nil
PetService._activePets = {} -- userId -> pet model

function PetService:Init(dataManager)
    self._dataManager = dataManager

    RemoteManager:OnServerEvent("BuyPet", function(player, petId)
        self:_buyPet(player, petId)
    end)

    RemoteManager:OnServerEvent("EquipPet", function(player, petId)
        self:_equipPet(player, petId)
    end)

    RemoteManager:OnServerEvent("UnequipPet", function(player)
        self:_unequipPet(player)
    end)

    RemoteManager:RegisterFunction("GetPetInventory", function(player)
        local data = self._dataManager:GetPlayerData(player)
        if not data then return {} end
        return { owned = data.pets or {}, active = data.activePet or "" }
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_destroyPetModel(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:_restorePet(player)
        end)
    end
    Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            self:_restorePet(player)
        end)
    end)
end

function PetService:_restorePet(player: Player)
    local data = self._dataManager:WaitForData(player)
    if not data then return end
    if data.activePet and data.activePet ~= "" then
        self:_spawnPetModel(player, data.activePet)
    end
end

function PetService:_buyPet(player: Player, petId: string)
    local data = self._dataManager:GetPlayerData(player)
    if not data then return end

    -- Check if already owned
    for _, pid in ipairs(data.pets or {}) do
        if pid == petId then
            RemoteManager:FireClient(player, "ShowNotification", "error", "تملك هذا الحيوان بالفعل")
            return
        end
    end

    local petInfo = nil
    for _, pt in ipairs(Constants.PET_TYPES) do
        if pt.id == petId then
            petInfo = pt
            break
        end
    end
    if not petInfo then return end

    if data.cash < petInfo.price then
        RemoteManager:FireClient(player, "ShowNotification", "error", "رصيدك غير كافي")
        return
    end

    data.cash = data.cash - petInfo.price
    table.insert(data.pets, petId)
    data.activePet = petId

    RemoteManager:FireClient(player, "MoneyUpdate", data.cash)
    RemoteManager:FireClient(player, "PetUpdate", "bought", petId)
    RemoteManager:FireClient(player, "ShowNotification", "success", "اشتريت " .. petInfo.nameAr .. "!")

    self:_spawnPetModel(player, petId)
end

function PetService:_equipPet(player: Player, petId: string)
    local data = self._dataManager:GetPlayerData(player)
    if not data then return end

    local owned = false
    for _, pid in ipairs(data.pets or {}) do
        if pid == petId then owned = true break end
    end
    if not owned then return end

    data.activePet = petId
    self:_destroyPetModel(player)
    self:_spawnPetModel(player, petId)
    RemoteManager:FireClient(player, "PetUpdate", "equipped", petId)
end

function PetService:_unequipPet(player: Player)
    local data = self._dataManager:GetPlayerData(player)
    if not data then return end

    data.activePet = ""
    self:_destroyPetModel(player)
    RemoteManager:FireClient(player, "PetUpdate", "unequipped", "")
end

function PetService:_spawnPetModel(player: Player, petId: string)
    self:_destroyPetModel(player)

    local character = player.Character
    if not character then
        player.CharacterAdded:Wait()
        character = player.Character
    end
    if not character then return end

    local petInfo = nil
    for _, pt in ipairs(Constants.PET_TYPES) do
        if pt.id == petId then petInfo = pt break end
    end
    if not petInfo then return end

    local petModel = Instance.new("Model")
    petModel.Name = "Pet_" .. petId

    -- Pet body (sphere)
    local body = Instance.new("Part")
    body.Name = "PetBody"
    body.Shape = Enum.PartType.Ball
    body.Size = Vector3.new(2.5, 2.5, 2.5)
    body.Color = Color3.fromRGB(0, 180, 255)
    body.Material = Enum.Material.SmoothPlastic
    body.Anchored = false
    body.CanCollide = false
    body.Massless = true
    body.Parent = petModel

    -- Pet name billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 80, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = body

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = petInfo.icon .. " " .. petInfo.nameAr
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Parent = billboard

    -- Attach to character with AlignPosition
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not rootPart then
        petModel:Destroy()
        return
    end

    local attachment0 = Instance.new("Attachment")
    attachment0.Parent = body

    local attachment1 = Instance.new("Attachment")
    attachment1.Position = Vector3.new(3, 0, -2)
    attachment1.Parent = rootPart

    local alignPos = Instance.new("AlignPosition")
    alignPos.Attachment0 = attachment0
    alignPos.Attachment1 = attachment1
    alignPos.MaxForce = 5000
    alignPos.Responsiveness = 8
    alignPos.Parent = body

    local alignOrient = Instance.new("AlignOrientation")
    alignOrient.Attachment0 = attachment0
    alignOrient.Attachment1 = attachment1
    alignOrient.Responsiveness = 5
    alignOrient.Parent = body

    petModel.PrimaryPart = body
    petModel.Parent = workspace

    self._activePets[player.UserId] = petModel

    -- Re-spawn pet on character respawn
    player.CharacterAdded:Connect(function()
        task.wait(2)
        local data = self._dataManager:GetPlayerData(player)
        if data and data.activePet == petId then
            self:_spawnPetModel(player, petId)
        end
    end)
end

function PetService:_destroyPetModel(player: Player)
    local model = self._activePets[player.UserId]
    if model and model.Parent then
        model:Destroy()
    end
    self._activePets[player.UserId] = nil
end

return PetService
