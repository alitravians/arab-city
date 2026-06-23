local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local _RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DataManager = {}
DataManager._playerData = {}
DataManager._lastSaveTime = {}
DataManager._dataStore = DataStoreService:GetDataStore("ArabCity_PlayerData_v1")

local DATA_SAVE_INTERVAL = 120 -- seconds

local DEFAULT_DATA = {
    cash = Constants.STARTING_CASH,
    level = 1,
    xp = 0,
    rank = "None",
    job = "None",
    ownedProperties = {},
    ownedVehicles = {},
    currentVehicle = "",
    cameraType = "Beginner",
    photos = {},
    followers = {},
    following = {},
    posts = {},
    achievements = {},
    completedMissions = {},
    activeMissions = {},
    fame = 0,
    totalEarned = 0,
    photosTaken = 0,
    housesBought = 0,
    housesSold = 0,
    carsBought = 0,
    landmarksVisited = 0,
    messages = {},
    redeemedCodes = {},
    lastDailyReward = 0,
    lastLogin = 0,
    joinDate = 0,
    playTime = 0,
    settings = {
        musicVolume = 0.5,
        sfxVolume = 0.7,
        notifications = true,
    },
}

function DataManager:Init()
    Players.PlayerAdded:Connect(function(player)
        self:_loadPlayerData(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_savePlayerData(player)
        self._playerData[player.UserId] = nil
        self._lastSaveTime[player.UserId] = nil
    end)

    game:BindToClose(function()
        for _, player in ipairs(Players:GetPlayers()) do
            self:_savePlayerData(player)
        end
    end)

    -- Auto-save loop
    task.spawn(function()
        while true do
            task.wait(DATA_SAVE_INTERVAL)
            for _, player in ipairs(Players:GetPlayers()) do
                task.spawn(function()
                    self:_savePlayerData(player)
                end)
            end
        end
    end)

    -- Remote function handlers
    RemoteManager:SetServerCallback("GetPlayerData", function(player)
        return self:GetData(player)
    end)
end

function DataManager:_loadPlayerData(player: Player)
    local success, data = pcall(function()
        return self._dataStore:GetAsync("Player_" .. player.UserId)
    end)

    if success and data then
        -- Merge with defaults for any missing keys
        local merged = self:_mergeDefaults(data)
        merged.lastLogin = DateTime.now().UnixTimestamp
        if merged.joinDate == 0 then
            merged.joinDate = DateTime.now().UnixTimestamp
        end
        self._playerData[player.UserId] = merged
    else
        if not success then
            warn(`[DataManager] Failed to load data for {player.Name}: {data}`)
        end
        local fresh = self:_deepCopy(DEFAULT_DATA)
        fresh.joinDate = DateTime.now().UnixTimestamp
        fresh.lastLogin = DateTime.now().UnixTimestamp
        self._playerData[player.UserId] = fresh
    end

    self._lastSaveTime[player.UserId] = os.clock()

    -- Notify client
    RemoteManager:FireClient("PlayerDataLoaded", player, self._playerData[player.UserId])
end

function DataManager:_savePlayerData(player: Player)
    local data = self._playerData[player.UserId]
    if not data then
        return
    end

    local now = os.clock()
    local lastSave = self._lastSaveTime[player.UserId] or now
    local elapsed = math.floor(now - lastSave)
    data.playTime += math.max(elapsed, 0)
    self._lastSaveTime[player.UserId] = now

    local success, err = pcall(function()
        self._dataStore:SetAsync("Player_" .. player.UserId, data)
    end)

    if not success then
        warn(`[DataManager] Failed to save data for {player.Name}: {err}`)
    end
end

function DataManager:_mergeDefaults(data: { [string]: any }): { [string]: any }
    local merged = self:_deepCopy(DEFAULT_DATA)
    for key, value in pairs(data) do
        if type(value) == "table" and type(merged[key]) == "table" then
            for subKey, subValue in pairs(value) do
                merged[key][subKey] = subValue
            end
        else
            merged[key] = value
        end
    end
    return merged
end

function DataManager:_deepCopy(tbl: { [any]: any }): { [any]: any }
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = self:_deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function DataManager:GetData(player: Player): { [string]: any }?
    return self._playerData[player.UserId]
end

function DataManager:SetValue(player: Player, key: string, value: any)
    local data = self._playerData[player.UserId]
    if data then
        data[key] = value
        RemoteManager:FireClient("PlayerDataUpdate", player, key, value)
    end
end

function DataManager:IncrementValue(player: Player, key: string, amount: number)
    local data = self._playerData[player.UserId]
    if data and type(data[key]) == "number" then
        data[key] += amount
        RemoteManager:FireClient("PlayerDataUpdate", player, key, data[key])
    end
end

function DataManager:GetValue(player: Player, key: string): any
    local data = self._playerData[player.UserId]
    if data then
        return data[key]
    end
    return nil
end

function DataManager:AddToTable(player: Player, key: string, value: any)
    local data = self._playerData[player.UserId]
    if data and type(data[key]) == "table" then
        table.insert(data[key], value)
        RemoteManager:FireClient("PlayerDataUpdate", player, key, data[key])
    end
end

function DataManager:RemoveFromTable(player: Player, key: string, value: any)
    local data = self._playerData[player.UserId]
    if data and type(data[key]) == "table" then
        for i, v in ipairs(data[key]) do
            if v == value then
                table.remove(data[key], i)
                break
            end
        end
        RemoteManager:FireClient("PlayerDataUpdate", player, key, data[key])
    end
end

return DataManager
