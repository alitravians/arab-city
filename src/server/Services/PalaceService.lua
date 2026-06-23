local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local _RankService

local PalaceService = {}

-- Allowed UserIds for palace access (Owner + special permissions)
PalaceService._allowedUsers = {}

function PalaceService:Init(rankService)
    _RankService = rankService

    -- Owner always has access
    if Constants.OWNER_USER_ID > 0 then
        self._allowedUsers[Constants.OWNER_USER_ID] = true
    end

    RemoteManager:OnServerEvent("PalaceAccess", function(player, action)
        if action == "request_entry" then
            self:RequestEntry(player)
        elseif action == "grant_access" then
            -- Only owner can grant
            if self:IsOwner(player) then
                self._pendingGrant = true
            end
        end
    end)

    -- Set up palace barriers in workspace
    self:_setupPalaceBarriers()
end

function PalaceService:_setupPalaceBarriers()
    local palace = workspace:FindFirstChild("OwnerPalace")
    if not palace then
        -- Create palace placeholder structure
        palace = self:_createPalaceStructure()
    end

    -- Set up touch detection on entrance
    local entrance = palace:FindFirstChild("Entrance")
    if entrance then
        entrance.Touched:Connect(function(hit)
            local character = hit.Parent
            local player = Players:GetPlayerFromCharacter(character)
            if player and not self:HasAccess(player) then
                -- Teleport player away
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local outsidePos = entrance.Position + entrance.CFrame.LookVector * -15
                    rootPart.CFrame = CFrame.new(outsidePos)
                end
                RemoteManager:FireClient("CodeResult", player, false, "لا يمكنك دخول قصر الأونر! تحتاج صلاحيات خاصة.")
            end
        end)
    end
end

function PalaceService:_createPalaceStructure(): Model
    local palace = Instance.new("Model")
    palace.Name = "OwnerPalace"

    -- Main building base
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(80, 1, 80)
    base.Position = Vector3.new(500, 0.5, 500)
    base.Anchored = true
    base.Material = Enum.Material.Marble
    base.Color = Color3.fromRGB(245, 245, 240)
    base.Parent = palace

    -- Walls
    local wallData = {
        { size = Vector3.new(80, 15, 2), pos = Vector3.new(500, 8, 540) },
        { size = Vector3.new(80, 15, 2), pos = Vector3.new(500, 8, 460) },
        { size = Vector3.new(2, 15, 80), pos = Vector3.new(540, 8, 500) },
        { size = Vector3.new(2, 15, 80), pos = Vector3.new(460, 8, 500) },
    }

    for i, wd in ipairs(wallData) do
        local wall = Instance.new("Part")
        wall.Name = "Wall_" .. i
        wall.Size = wd.size
        wall.Position = wd.pos
        wall.Anchored = true
        wall.Material = Enum.Material.Marble
        wall.Color = Color3.fromRGB(240, 235, 225)
        wall.Parent = palace
    end

    -- Entrance barrier (invisible, used for access check)
    local entrance = Instance.new("Part")
    entrance.Name = "Entrance"
    entrance.Size = Vector3.new(10, 10, 2)
    entrance.Position = Vector3.new(500, 5, 460)
    entrance.Anchored = true
    entrance.Transparency = 0.9
    entrance.CanCollide = false
    entrance.Parent = palace

    -- Office desk
    local desk = Instance.new("Part")
    desk.Name = "OfficDesk"
    desk.Size = Vector3.new(6, 1, 3)
    desk.Position = Vector3.new(500, 1.5, 530)
    desk.Anchored = true
    desk.Material = Enum.Material.WoodPlanks
    desk.Color = Color3.fromRGB(101, 67, 33)
    desk.Parent = palace

    -- Meeting table
    local table_ = Instance.new("Part")
    table_.Name = "MeetingTable"
    table_.Size = Vector3.new(10, 1, 4)
    table_.Position = Vector3.new(520, 1.5, 510)
    table_.Anchored = true
    table_.Material = Enum.Material.WoodPlanks
    table_.Color = Color3.fromRGB(120, 80, 40)
    table_.Parent = palace

    -- Garage area
    local garagePad = Instance.new("Part")
    garagePad.Name = "GaragePad"
    garagePad.Size = Vector3.new(25, 0.2, 20)
    garagePad.Position = Vector3.new(480, 0.6, 480)
    garagePad.Anchored = true
    garagePad.Material = Enum.Material.Concrete
    garagePad.Color = Color3.fromRGB(100, 100, 100)
    garagePad.Parent = palace

    -- Garden area
    local garden = Instance.new("Part")
    garden.Name = "Garden"
    garden.Size = Vector3.new(30, 0.2, 30)
    garden.Position = Vector3.new(520, 0.6, 480)
    garden.Anchored = true
    garden.Material = Enum.Material.Grass
    garden.Color = Color3.fromRGB(50, 150, 50)
    garden.Parent = palace

    -- VIP lounge platform
    local vipPlatform = Instance.new("Part")
    vipPlatform.Name = "VIPLounge"
    vipPlatform.Size = Vector3.new(15, 0.5, 15)
    vipPlatform.Position = Vector3.new(530, 0.75, 530)
    vipPlatform.Anchored = true
    vipPlatform.Material = Enum.Material.Marble
    vipPlatform.Color = Color3.fromRGB(255, 215, 0)
    vipPlatform.Parent = palace

    -- Palace label
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(10, 0, 2, 0)
    billboard.StudsOffset = Vector3.new(0, 20, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = base

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "قصر الأونر 👑"
    label.TextColor3 = Color3.fromRGB(255, 215, 0)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard

    palace.Parent = workspace
    return palace
end

function PalaceService:IsOwner(player: Player): boolean
    return player.UserId == Constants.OWNER_USER_ID
end

function PalaceService:HasAccess(player: Player): boolean
    if self:IsOwner(player) then
        return true
    end
    return self._allowedUsers[player.UserId] == true
end

function PalaceService:GrantAccess(ownerPlayer: Player, targetUserId: number)
    if not self:IsOwner(ownerPlayer) then
        RemoteManager:FireClient("CodeResult", ownerPlayer, false, "فقط الأونر يستطيع منح الصلاحيات!")
        return
    end
    self._allowedUsers[targetUserId] = true
    RemoteManager:FireClient("CodeResult", ownerPlayer, true, "تم منح الصلاحية!")

    local target = Players:GetPlayerByUserId(targetUserId)
    if target then
        RemoteManager:FireClient("CodeResult", target, true, "تم منحك صلاحية دخول قصر الأونر!")
    end
end

function PalaceService:RevokeAccess(ownerPlayer: Player, targetUserId: number)
    if not self:IsOwner(ownerPlayer) then
        return
    end
    self._allowedUsers[targetUserId] = nil
end

function PalaceService:RequestEntry(player: Player)
    if self:HasAccess(player) then
        RemoteManager:FireClient("CodeResult", player, true, "مرحباً بك في القصر!")
    else
        RemoteManager:FireClient("CodeResult", player, false, "ليس لديك صلاحية الدخول!")
    end
end

return PalaceService
