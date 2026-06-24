--[[
    Arab City - Badge Service
    Awards badges for player achievements.
    Badge IDs are placeholders (0) — replace with actual IDs from Creator Hub.
]]

local BadgeServiceRoblox = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DataManager

local BadgeService = {}
BadgeService._awardedCache = {} -- [userId][badgeName] = true

function BadgeService:Init(dataManager)
    DataManager = dataManager

    Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            self:_onPlayerJoined(player)
        end)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:_onPlayerJoined(player)
        end)
    end

    Players.PlayerRemoving:Connect(function(player)
        self._awardedCache[player.UserId] = nil
    end)

    -- Periodic badge check
    task.spawn(function()
        while true do
            task.wait(15)
            for _, player in ipairs(Players:GetPlayers()) do
                task.spawn(function()
                    self:_checkBadges(player)
                end)
            end
        end
    end)
end

function BadgeService:_onPlayerJoined(player: Player)
    self._awardedCache[player.UserId] = {}

    -- Wait for data
    local attempts = 0
    while not DataManager:GetData(player) and attempts < 50 do
        task.wait(0.2)
        attempts += 1
    end

    -- Load already-awarded badges from data
    local data = DataManager:GetData(player)
    if data and data.achievements then
        for _, badgeName in ipairs(data.achievements) do
            self._awardedCache[player.UserId][badgeName] = true
        end
    end

    -- Award welcome badge for first-time players
    local joinDate = data and data.joinDate or 0
    local now = DateTime.now().UnixTimestamp
    if now - joinDate < 60 then
        self:AwardBadge(player, "welcome")
    end

    self:_checkBadges(player)
end

function BadgeService:_checkBadges(player: Player)
    local data = DataManager:GetData(player)
    if not data then
        return
    end

    for _, badge in ipairs(Constants.BADGES) do
        if badge.trigger == "firstJoin" then
            continue
        end

        local cache = self._awardedCache[player.UserId]
        if cache and cache[badge.name] then
            continue
        end

        local currentValue = data[badge.trigger] or 0
        if type(currentValue) == "table" then
            currentValue = #currentValue
        end

        if currentValue >= (badge.target or 1) then
            self:AwardBadge(player, badge.name)
        end
    end
end

function BadgeService:AwardBadge(player: Player, badgeName: string)
    local cache = self._awardedCache[player.UserId]
    if not cache then
        return
    end
    if cache[badgeName] then
        return
    end
    cache[badgeName] = true

    -- Find badge data
    local badgeData = nil
    for _, b in ipairs(Constants.BADGES) do
        if b.name == badgeName then
            badgeData = b
            break
        end
    end
    if not badgeData then
        return
    end

    -- Try to award Roblox badge (only if ID is set)
    if badgeData.id > 0 then
        pcall(function()
            BadgeServiceRoblox:AwardBadge(player.UserId, badgeData.id)
        end)
    end

    -- Track in player data
    DataManager:AddToTable(player, "achievements", badgeName)

    -- Notify client
    RemoteManager:FireClient("BadgeAwarded", player, {
        name = badgeData.name,
        nameAr = badgeData.nameAr,
        description = badgeData.description,
    })

    print(`[BadgeService] Awarded "{badgeName}" to {player.Name}`)
end

function BadgeService:HasBadge(player: Player, badgeName: string): boolean
    local cache = self._awardedCache[player.UserId]
    if cache then
        return cache[badgeName] == true
    end
    return false
end

return BadgeService
