local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteManager = {}
RemoteManager._cache = {}

local REMOTES_FOLDER_NAME = "ArabCity_Remotes"

local REMOTE_EVENTS = {
    -- Economy
    "UpdateMoney",
    "RequestPurchase",
    "DailyReward",
    -- Real Estate
    "BuyProperty",
    "SellProperty",
    "ListPropertyForSale",
    "PropertyUpdate",
    -- Vehicles
    "SpawnVehicle",
    "DespawnVehicle",
    "VehicleUpdate",
    -- Jobs
    "JoinJob",
    "LeaveJob",
    "JobPayment",
    "JobUpdate",
    -- Missions
    "MissionProgress",
    "ClaimMission",
    "MissionUpdate",
    -- Codes
    "RedeemCode",
    "CodeResult",
    -- Social Network
    "CreatePost",
    "LikePost",
    "CommentOnPost",
    "FollowPlayer",
    "UnfollowPlayer",
    "SocialFeedUpdate",
    "SocialProfileUpdate",
    -- Photography
    "TakePhoto",
    "PhotoTaken",
    "UpgradeCamera",
    -- Ranks
    "RankUpdate",
    "RankEffectTrigger",
    -- Achievements
    "AchievementUnlocked",
    "AchievementProgress",
    -- Weather
    "WeatherChange",
    -- Plane/Entry
    "RequestJump",
    "PlayerLanded",
    -- Fame
    "FameUpdate",
    -- Events
    "EventStart",
    "EventEnd",
    "EventJoin",
    -- Data
    "PlayerDataLoaded",
    "PlayerDataUpdate",
    -- Phone
    "SendMessage",
    "ReceiveMessage",
    -- Computer
    "ComputerInteract",
    -- Palace
    "PalaceAccess",
}

local REMOTE_FUNCTIONS = {
    "GetPlayerData",
    "GetPropertyList",
    "GetSocialFeed",
    "GetPlayerProfile",
    "GetLeaderboard",
    "GetMissions",
    "GetAchievements",
    "GetVehicleList",
    "GetJobList",
    "GetAvailableCodes",
    "GetMessages",
    "GetPhotos",
}

function RemoteManager:_getOrCreateFolder(): Folder
    if RunService:IsServer() then
        local folder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = REMOTES_FOLDER_NAME
            folder.Parent = ReplicatedStorage
        end
        return folder
    else
        return ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME, 30)
    end
end

function RemoteManager:Init()
    local folder = self:_getOrCreateFolder()
    if not folder then
        warn("[RemoteManager] Could not find or create remotes folder")
        return
    end

    if RunService:IsServer() then
        for _, name in ipairs(REMOTE_EVENTS) do
            if not folder:FindFirstChild(name) then
                local remote = Instance.new("RemoteEvent")
                remote.Name = name
                remote.Parent = folder
            end
        end
        for _, name in ipairs(REMOTE_FUNCTIONS) do
            if not folder:FindFirstChild(name) then
                local remote = Instance.new("RemoteFunction")
                remote.Name = name
                remote.Parent = folder
            end
        end
    end
end

function RemoteManager:GetEvent(name: string): RemoteEvent?
    if self._cache[name] then
        return self._cache[name]
    end
    local folder = self:_getOrCreateFolder()
    if not folder then
        return nil
    end
    local remote = folder:FindFirstChild(name)
    if not remote then
        if RunService:IsClient() then
            remote = folder:WaitForChild(name, 10)
        end
    end
    if remote then
        self._cache[name] = remote
    end
    return remote
end

function RemoteManager:GetFunction(name: string): RemoteFunction?
    if self._cache[name] then
        return self._cache[name]
    end
    local folder = self:_getOrCreateFolder()
    if not folder then
        return nil
    end
    local remote = folder:FindFirstChild(name)
    if not remote then
        if RunService:IsClient() then
            remote = folder:WaitForChild(name, 10)
        end
    end
    if remote then
        self._cache[name] = remote
    end
    return remote
end

function RemoteManager:FireClient(eventName: string, player: Player, ...)
    local remote = self:GetEvent(eventName)
    if remote then
        remote:FireClient(player, ...)
    end
end

function RemoteManager:FireAllClients(eventName: string, ...)
    local remote = self:GetEvent(eventName)
    if remote then
        remote:FireAllClients(...)
    end
end

function RemoteManager:FireServer(eventName: string, ...)
    local remote = self:GetEvent(eventName)
    if remote then
        remote:FireServer(...)
    end
end

function RemoteManager:OnServerEvent(eventName: string, callback: (...any) -> ())
    local remote = self:GetEvent(eventName)
    if remote then
        remote.OnServerEvent:Connect(callback)
    end
end

function RemoteManager:OnClientEvent(eventName: string, callback: (...any) -> ())
    local remote = self:GetEvent(eventName)
    if remote then
        remote.OnClientEvent:Connect(callback)
    end
end

function RemoteManager:SetServerCallback(funcName: string, callback: (...any) -> ...any)
    local remote = self:GetFunction(funcName)
    if remote then
        remote.OnServerInvoke = callback
    end
end

function RemoteManager:InvokeServer(funcName: string, ...): ...any
    local remote = self:GetFunction(funcName)
    if remote then
        return remote:InvokeServer(...)
    end
    return nil
end

return RemoteManager
