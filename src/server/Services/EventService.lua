local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Utils = Shared.Utils
local RemoteManager = Shared.RemoteManager

local _DataManager
local EconomyService

local EventService = {}
EventService._activeEvent = nil
EventService._participants = {}

local EVENT_TEMPLATES = {
    {
        id = "race",
        nameAr = "سباق سيارات",
        description = "تسابق مع اللاعبين الآخرين!",
        durationSeconds = 300,
        minPlayers = 2,
        rewards = { first = 10000, second = 5000, third = 2500 },
    },
    {
        id = "photo_contest",
        nameAr = "مسابقة تصوير",
        description = "التقط أفضل صورة للفوز!",
        durationSeconds = 600,
        minPlayers = 2,
        rewards = { first = 15000, second = 8000, third = 4000 },
    },
    {
        id = "treasure_hunt",
        nameAr = "البحث عن الكنز",
        description = "ابحث عن الكنوز المخفية في المدينة!",
        durationSeconds = 420,
        minPlayers = 1,
        rewards = { first = 20000, second = 10000, third = 5000 },
    },
}

function EventService:Init(dataManager, economyService)
    _DataManager = dataManager
    EconomyService = economyService

    RemoteManager:OnServerEvent("EventJoin", function(player)
        self:JoinEvent(player)
    end)

    -- Start event cycle
    task.spawn(function()
        while true do
            -- Wait 15-30 minutes between events
            task.wait(math.random(900, 1800))
            self:_startRandomEvent()
        end
    end)
end

function EventService:_startRandomEvent()
    if self._activeEvent then
        return
    end

    local template = EVENT_TEMPLATES[math.random(1, #EVENT_TEMPLATES)]
    self._activeEvent = {
        id = template.id,
        nameAr = template.nameAr,
        description = template.description,
        startTime = Utils.getTimestamp(),
        endTime = Utils.getTimestamp() + template.durationSeconds,
        rewards = template.rewards,
        scores = {},
    }
    self._participants = {}

    RemoteManager:FireAllClients("EventStart", {
        id = self._activeEvent.id,
        nameAr = self._activeEvent.nameAr,
        description = self._activeEvent.description,
        durationSeconds = template.durationSeconds,
    })

    -- End event after duration
    task.delay(template.durationSeconds, function()
        self:_endEvent()
    end)
end

function EventService:_endEvent()
    if not self._activeEvent then
        return
    end

    -- Sort scores and award prizes
    local sortedScores = {}
    for userId, score in pairs(self._activeEvent.scores) do
        table.insert(sortedScores, { userId = userId, score = score })
    end
    table.sort(sortedScores, function(a, b)
        return a.score > b.score
    end)

    local rewardKeys = { "first", "second", "third" }
    local winners = {}

    for i = 1, math.min(3, #sortedScores) do
        local entry = sortedScores[i]
        local player = Players:GetPlayerByUserId(entry.userId)
        local rewardKey = rewardKeys[i]
        local reward = self._activeEvent.rewards[rewardKey] or 0

        if player and reward > 0 then
            EconomyService:AddMoney(player, reward, `جائزة {self._activeEvent.nameAr} - المركز {i}`)
        end

        table.insert(winners, {
            position = i,
            userId = entry.userId,
            displayName = player and player.DisplayName or "Unknown",
            score = entry.score,
            reward = reward,
        })
    end

    RemoteManager:FireAllClients("EventEnd", {
        id = self._activeEvent.id,
        nameAr = self._activeEvent.nameAr,
        winners = winners,
    })

    self._activeEvent = nil
    self._participants = {}
end

function EventService:JoinEvent(player: Player)
    if not self._activeEvent then
        RemoteManager:FireClient("CodeResult", player, false, "لا يوجد حدث نشط حالياً!")
        return
    end

    if self._participants[player.UserId] then
        RemoteManager:FireClient("CodeResult", player, false, "أنت مشارك بالفعل!")
        return
    end

    self._participants[player.UserId] = true
    self._activeEvent.scores[player.UserId] = 0

    RemoteManager:FireClient("CodeResult", player, true, `انضممت إلى {self._activeEvent.nameAr}!`)
end

function EventService:AddScore(player: Player, amount: number)
    if not self._activeEvent then
        return
    end
    if not self._participants[player.UserId] then
        return
    end

    self._activeEvent.scores[player.UserId] = (self._activeEvent.scores[player.UserId] or 0) + amount
end

function EventService:GetActiveEvent()
    return self._activeEvent
end

return EventService
