--[[
    Arab City v2.0 - RemoteManager
    Creates and caches RemoteEvents / RemoteFunctions under ReplicatedStorage.Remotes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteManager = {}
local _cache = {}

local REMOTE_NAMES = {
    -- Economy
    "GetPlayerData",
    "UpdateCash",
    "WelcomeReward",

    -- Chat
    "SendChatMessage",
    "ReceiveChatMessage",
    "SendPrivateMessage",
    "ReceivePrivateMessage",

    -- Admin
    "AdminAction",
    "AdminResponse",
    "AdminPanelAccess",
    "AdminResult",

    -- Shop
    "PurchaseItem",
    "PurchaseResult",
    "OpenShop",
    "RequestShop",

    -- Codes
    "RedeemCode",
    "RedeemResult",
    "CodeResult",
    "OpenCodes",
    "RequestCodes",

    -- Missions
    "MissionUpdate",
    "CompleteMission",
    "MissionsUpdate",
    "RequestMissions",

    -- Jobs
    "ApplyForJob",
    "JobResult",
    "CollectSalary",
    "JobUpdate",
    "RequestJobs",

    -- Real Estate
    "PurchaseProperty",
    "PropertyResult",

    -- Vehicles
    "PurchaseVehicle",
    "SpawnVehicle",
    "VehicleResult",
    "VehicleState",
    "RequestVehicles",

    -- XP / Level
    "XPUpdate",

    -- Friends
    "SendFriendRequest",
    "FriendRequestResult",
    "FriendUpdate",
    "FriendListUpdate",
    "RequestFriendList",
    "OpenFriends",

    -- Trade
    "InitiateTrade",
    "TradeAction",
    "TradeUpdate",
    "TradeRequest",

    -- Pets
    "PurchasePet",
    "EquipPet",
    "PetResult",
    "OpenPets",

    -- Leaderboard
    "GetLeaderboard",
    "LeaderboardData",

    -- Daily Challenge
    "DailyChallengeUpdate",
    "ClaimDailyReward",
    "DailyChallenges",
    "OpenDailyChallenges",
    "RequestDailyChallenges",
    "ClaimDailyChallenge",

    -- Notifications
    "ShowNotification",

    -- Badge
    "BadgeAwarded",

    -- Buildings
    "BuildingInteract",
    "BuildingResponse",

    -- Social Network
    "SocialPost",
    "SocialFeed",
    "SocialLike",
    "RequestSocialFeed",
    "OpenSocial",

    -- Inventory
    "InventoryUpdate",
    "RequestInventory",

    -- Rank
    "RankEffect",
}

local function getFolder()
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if not folder then
        if RunService:IsServer() then
            folder = Instance.new("Folder")
            folder.Name = "Remotes"
            folder.Parent = ReplicatedStorage
        else
            folder = ReplicatedStorage:WaitForChild("Remotes", 10)
        end
    end
    return folder
end

function RemoteManager:Init()
    if not RunService:IsServer() then return end
    local folder = getFolder()
    for _, name in ipairs(REMOTE_NAMES) do
        if not folder:FindFirstChild(name) then
            local remote
            if name == "GetPlayerData" or name == "GetLeaderboard" then
                remote = Instance.new("RemoteFunction")
            else
                remote = Instance.new("RemoteEvent")
            end
            remote.Name = name
            remote.Parent = folder
        end
    end
end

function RemoteManager:Get(name)
    if _cache[name] then return _cache[name] end
    local folder = getFolder()
    if not folder then
        warn("[RemoteManager] Remotes folder not found")
        return nil
    end
    local remote = folder:FindFirstChild(name)
    if not remote then
        if not RunService:IsServer() then
            remote = folder:WaitForChild(name, 10)
        end
    end
    if remote then
        _cache[name] = remote
    end
    return remote
end

function RemoteManager:FireClient(name, player, ...)
    local remote = self:Get(name)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireClient(player, ...)
    end
end

function RemoteManager:FireAllClients(name, ...)
    local remote = self:Get(name)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireAllClients(...)
    end
end

function RemoteManager:FireServer(name, ...)
    local remote = self:Get(name)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
    end
end

function RemoteManager:OnServerEvent(name, callback)
    local remote = self:Get(name)
    if remote and remote:IsA("RemoteEvent") then
        remote.OnServerEvent:Connect(callback)
    end
end

function RemoteManager:OnClientEvent(name, callback)
    local remote = self:Get(name)
    if remote and remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(callback)
    end
end

function RemoteManager:SetServerCallback(name, callback)
    local remote = self:Get(name)
    if remote and remote:IsA("RemoteFunction") then
        remote.OnServerInvoke = callback
    end
end

function RemoteManager:InvokeServer(name, ...)
    local remote = self:Get(name)
    if remote and remote:IsA("RemoteFunction") then
        return remote:InvokeServer(...)
    end
    return nil
end

return RemoteManager
