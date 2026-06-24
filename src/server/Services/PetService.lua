--[[
    Arab City v2.0 - PetService
    Pet ownership, spawning, and following behaviour.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetService = {}

local Shared, Constants, Remotes, DataService
local _activePets = {}

function PetService:Init(dataService)
    DataService = dataService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("PetAction", function(player, action, petId)
        if action == "purchase" then
            self:_purchase(player, petId)
        elseif action == "equip" then
            self:_equip(player, petId)
        elseif action == "unequip" then
            self:_unequip(player)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_cleanup(player)
    end)
end

function PetService:_findPetConfig(petId)
    for _, pet in ipairs(Constants.PETS) do
        if pet.id == petId then return pet end
    end
    return nil
end

function PetService:_purchase(player, petId)
    if type(petId) ~= "string" then return end
    local config = self:_findPetConfig(petId)
    if not config then
        Remotes:FireClient("ShowNotification", player, { title = "خطأ", message = "حيوان غير موجود", duration = 3 })
        return
    end

    local data = DataService:Get(player)
    if not data then return end

    for _, ownedId in ipairs(data.pets) do
        if ownedId == petId then
            Remotes:FireClient("ShowNotification", player, { title = "خطأ", message = "تملك هذا الحيوان بالفعل", duration = 3 })
            return
        end
    end

    if data.cash < config.price then
        Remotes:FireClient("ShowNotification", player, { title = "خطأ", message = "رصيدك غير كافٍ", duration = 3 })
        return
    end

    data.cash = data.cash - config.price
    table.insert(data.pets, petId)

    Remotes:FireClient("UpdateCash", player, data.cash)
    Remotes:FireClient("ShowNotification", player, {
        title = "حيوان جديد!",
        message = "اشتريت " .. config.name,
        icon = "🐾",
        duration = 4,
    })
end

function PetService:_equip(player, petId)
    if type(petId) ~= "string" then return end
    local data = DataService:Get(player)
    if not data then return end

    local owned = false
    for _, ownedId in ipairs(data.pets) do
        if ownedId == petId then owned = true break end
    end
    if not owned then return end

    local config = self:_findPetConfig(petId)
    if not config then return end

    self:_cleanup(player)

    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pet = Instance.new("Part")
    pet.Name = "Pet_" .. petId
    pet.Size = Vector3.new(2, 2, 2)
    pet.Shape = Enum.PartType.Ball
    pet.BrickColor = BrickColor.new(config.color or "Bright yellow")
    pet.Material = Enum.Material.SmoothPlastic
    pet.CanCollide = false
    pet.Anchored = true
    pet.CFrame = hrp.CFrame * CFrame.new(3, 0, 0)

    local label = Instance.new("BillboardGui")
    label.Name = "PetLabel"
    label.Size = UDim2.new(0, 100, 0, 30)
    label.StudsOffset = Vector3.new(0, 2, 0)
    label.AlwaysOnTop = true
    label.Parent = pet

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = config.name
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextStrokeTransparency = 0.5
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = label

    local folder = Workspace:FindFirstChild("ActivePets")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ActivePets"
        folder.Parent = Workspace
    end
    pet.Parent = folder

    _activePets[player.UserId] = pet

    task.spawn(function()
        self:_followLoop(player, pet)
    end)
end

function PetService:_followLoop(player, pet)
    while pet and pet.Parent and player and player.Parent do
        local character = player.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local target = hrp.CFrame * CFrame.new(3, 1, 2)
                local current = pet.CFrame
                pet.CFrame = current:Lerp(target, 0.1)
            end
        end
        task.wait(0.05)
    end
end

function PetService:_unequip(player)
    self:_cleanup(player)
end

function PetService:_cleanup(player)
    local pet = _activePets[player.UserId]
    if pet and pet.Parent then
        pet:Destroy()
    end
    _activePets[player.UserId] = nil
end

return PetService
