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
DataManager._saving = {} -- per-player lock to prevent concurrent saves
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

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:_loadPlayerData(player)
        end)
    end

    Players.PlayerRemoving:Connect(function(player)
        -- Defer save so other services' PlayerRemoving handlers run first
        -- (VehicleService, JobService clean up player state before we save)
        task.defer(function()
            self:_savePlayerData(player)
            self._playerData[player.UserId] = nil
            self._lastSaveTime[player.UserId] = nil
        end)
    end)

    game:BindToClose(function()
        local players = Players:GetPlayers()
        local remaining = #players
        if remaining == 0 then
            return
        end
        for _, plr in ipairs(players) do
            task.spawn(function()
                self:_savePlayerData(plr)
                remaining -= 1
            end)
        end
        -- Wait until all saves complete or 25s timeout (Roblox allows 30s)
        local elapsed = 0
        while remaining > 0 and elapsed < 25 do
            task.wait(0.5)
            elapsed += 0.5
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

    RemoteManager:SetServerCallback("GetInventory", function(player)
        local data = self:GetData(player)
        if not data then
            return { vehicles = {}, properties = {}, cameras = {} }
        end
        return {
            vehicles = data.ownedVehicles or {},
            properties = data.ownedProperties or {},
            cameras = { data.cameraType or "Beginner" },
        }
    end)
end

function DataManager:_loadPlayerData(player: Player)
    local success, data = pcall(function()
        return self._dataStore:GetAsync("Player_" .. player.UserId)
    end)

    local isNewPlayer = false

    if success and data then
        -- Merge with defaults for any missing keys
        local merged = self:_mergeDefaults(data)
        merged.lastLogin = DateTime.now().UnixTimestamp
        if merged.joinDate == 0 then
            merged.joinDate = DateTime.now().UnixTimestamp
            isNewPlayer = true
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
        isNewPlayer = true
    end

    self._lastSaveTime[player.UserId] = os.clock()

    -- Welcome bonus for new players
    if isNewPlayer then
        local playerData = self._playerData[player.UserId]
        playerData.cash = Constants.STARTING_CASH + Constants.WELCOME_BONUS
        playerData.totalEarned = Constants.WELCOME_BONUS
        task.defer(function()
            RemoteManager:FireClient("WelcomeBonus", player, Constants.WELCOME_BONUS)
        end)
    end

    -- Notify client
    RemoteManager:FireClient("PlayerDataLoaded", player, self._playerData[player.UserId])
end

function DataManager:_savePlayerData(player: Player)
    local userId = player.UserId
    local data = self._playerData[userId]
    if not data then
        return
    end

    if self._saving[userId] then
        return
    end
    self._saving[userId] = true

    local now = os.clock()
    local lastSave = self._lastSaveTime[userId] or now
    local elapsed = math.floor(now - lastSave)
    data.playTime += math.max(elapsed, 0)
    self._lastSaveTime[userId] = now

    local success, err = pcall(function()
        self._dataStore:SetAsync("Player_" .. userId, data)
    end)

    if not success then
        warn(`[DataManager] Failed to save data for {player.Name}: {err}`)
    end

    self._saving[userId] = nil
end

function DataManager:_isArray(tbl: { [any]: any }): boolean
    local count = 0
    for _ in pairs(tbl) do
        count += 1
    end
    if count == 0 then
        return true -- empty tables treated as arrays (list fields default to {})
    end
    return tbl[1] ~= nil
end

function DataManager:_mergeDefaults(data: { [string]: any }): { [string]: any }
    local merged = self:_deepCopy(DEFAULT_DATA)
    for key, value in pairs(data) do
        if type(value) == "table" and type(merged[key]) == "table" then
            if self:_isArray(value) or self:_isArray(merged[key]) then
                -- Array fields: full replacement (posts, vehicles, followers, etc.)
                merged[key] = self:_deepCopy(value)
            else
                -- Dict fields: sub-key merge (settings, etc.)
                for subKey, subValue in pairs(value) do
                    merged[key][subKey] = subValue
                end
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
