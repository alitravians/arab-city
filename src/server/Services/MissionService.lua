--[[
    Arab City v2.0 - MissionService
    Quest / mission tracking and rewards.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MissionService = {}

local Shared, Constants, Remotes, DataService, EconomyService, XPService

function MissionService:Init(dataService, economyService, xpService)
    DataService = dataService
    EconomyService = economyService
    XPService = xpService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("CompleteMission", function(player, missionId)
        self:_complete(player, missionId)
    end)
end

function MissionService:_complete(player, missionId)
    if type(missionId) ~= "string" then return end

    local mission = nil
    for _, m in ipairs(Constants.MISSIONS) do
        if m.id == missionId then
            mission = m
            break
        end
    end
    if not mission then return end

    local data = DataService:Get(player)
    if not data then return end

    for _, completed in ipairs(data.completedMissions) do
        if completed == missionId then return end
    end

    table.insert(data.completedMissions, missionId)
    EconomyService:AddCash(player, mission.reward)
    if XPService then
        XPService:AddXP(player, Constants.XP_SOURCES.mission_complete)
    end

    Remotes:FireClient("MissionUpdate", player, {
        missionId = missionId,
        completed = true,
        reward = mission.reward,
    })
    Remotes:FireClient("ShowNotification", player, {
        title = "مهمة مكتملة!",
        message = mission.name .. " — +" .. tostring(mission.reward) .. "$",
        icon = "✅", duration = 4,
    })
end

function MissionService:IsMissionCompleted(player, missionId)
    local data = DataService:Get(player)
    if not data then return false end
    for _, completed in ipairs(data.completedMissions) do
        if completed == missionId then return true end
    end
    return false
end

return MissionService
