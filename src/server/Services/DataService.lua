--[[
    Arab City v2.0 - DataService
    Player data persistence using DataStoreService.
    Handles save/load/autosave with retry logic.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = {}
DataService._data = {}
DataService._saving = {}

local STORE_KEY = "ArabCity_PlayerData_v2"
local AUTOSAVE_INTERVAL = 120
local MAX_RETRIES = 3

local store = nil
pcall(function()
    store = DataStoreService:GetDataStore(STORE_KEY)
end)

local DEFAULT_DATA = {
    cash = 10000,
    xp = 0,
    level = 1,
    job = "restaurant_worker",
    vehicles = {},
    properties = {},
    inventory = {},
    pets = {},
    equippedPet = "",
    friends = {},
    completedMissions = {},
    redeemedCodes = {},
    dailyChallenges = {},
    lastDailyReset = 0,
    lastLogin = 0,
    totalPlayTime = 0,
    isNewPlayer = true,
    isAdmin = false,
    fame = 0,
    settings = {
        musicVolume = 0.5,
        sfxVolume = 0.8,
    },
}

local function mergeDefaults(saved, defaults)
    local result = {}
    for k, v in pairs(defaults) do
        if saved[k] == nil then
            if type(v) == "table" then
                result[k] = {}
                for dk, dv in pairs(v) do
                    result[k][dk] = dv
                end
            else
                result[k] = v
            end
        elseif type(v) == "table" and type(saved[k]) == "table" and v[1] == nil and saved[k][1] == nil then
            result[k] = mergeDefaults(saved[k], v)
        else
            result[k] = saved[k]
        end
    end
    for k, v in pairs(saved) do
        if defaults[k] == nil then
            result[k] = v
        end
    end
    return result
end

function DataService:Load(player)
    local userId = player.UserId
    local data = nil

    for attempt = 1, MAX_RETRIES do
        local ok, result = pcall(function()
            if store then
                return store:GetAsync(tostring(userId))
            end
            return nil
        end)
        if ok then
            data = result
            break
        end
        if attempt < MAX_RETRIES then
            task.wait(1)
        end
    end

    local playerData
    if data and type(data) == "table" then
        playerData = mergeDefaults(data, DEFAULT_DATA)
    else
        playerData = {}
        for k, v in pairs(DEFAULT_DATA) do
            if type(v) == "table" then
                playerData[k] = {}
                for dk, dv in pairs(v) do
                    playerData[k][dk] = dv
                end
            else
                playerData[k] = v
            end
        end
    end

    playerData.lastLogin = os.time()
    self._data[userId] = playerData
    return playerData
end

function DataService:Save(player)
    local userId
    if type(player) == "number" then
        userId = player
    else
        userId = player.UserId
    end

    local data = self._data[userId]
    if not data then return false end
    if self._saving[userId] then return false end

    self._saving[userId] = true

    local ok = false
    for attempt = 1, MAX_RETRIES do
        local success = pcall(function()
            if store then
                store:SetAsync(tostring(userId), data)
            end
        end)
        if success then
            ok = true
            break
        end
        if attempt < MAX_RETRIES then
            task.wait(1)
        end
    end

    self._saving[userId] = nil
    return ok
end

function DataService:Get(player, key)
    local userId
    if type(player) == "number" then
        userId = player
    else
        userId = player.UserId
    end
    local data = self._data[userId]
    if not data then return nil end
    if key then return data[key] end
    return data
end

function DataService:Set(player, key, value)
    local userId
    if type(player) == "number" then
        userId = player
    else
        userId = player.UserId
    end
    local data = self._data[userId]
    if not data then return end
    data[key] = value
end

function DataService:Update(player, key, updateFunc)
    local userId
    if type(player) == "number" then
        userId = player
    else
        userId = player.UserId
    end
    local data = self._data[userId]
    if not data then return end
    data[key] = updateFunc(data[key])
end

function DataService:Remove(player)
    local userId
    if type(player) == "number" then
        userId = player
    else
        userId = player.UserId
    end
    self._data[userId] = nil
end

function DataService:Init()
    Players.PlayerRemoving:Connect(function(player)
        self:Save(player)
        task.delay(5, function()
            self:Remove(player)
        end)
    end)

    game:BindToClose(function()
        for userId in pairs(self._data) do
            self:Save(userId)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(AUTOSAVE_INTERVAL)
            for _, player in ipairs(Players:GetPlayers()) do
                task.spawn(function()
                    self:Save(player)
                end)
            end
        end
    end)
end

return DataService
