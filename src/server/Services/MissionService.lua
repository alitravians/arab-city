local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DataManager
local EconomyService

local MissionService = {}

function MissionService:Init(dataManager, economyService)
    DataManager = dataManager
    EconomyService = economyService

    RemoteManager:OnServerEvent("ClaimMission", function(player, missionId)
        self:ClaimMission(player, missionId)
    end)

    RemoteManager:SetServerCallback("GetMissions", function(player)
        return self:GetPlayerMissions(player)
    end)

    -- Assign missions to new players
    Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            self:_assignDailyMissions(player)
        end)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:_assignDailyMissions(player)
        end)
    end
end

function MissionService:_assignDailyMissions(player: Player)
    -- Wait for data
    local attempts = 0
    while not DataManager:GetData(player) and attempts < 50 do
        task.wait(0.1)
        attempts += 1
    end

    local activeMissions = DataManager:GetValue(player, "activeMissions") or {}
    if #activeMissions > 0 then
        return -- already has missions
    end

    -- Assign all missions
    local newMissions = {}
    for _, mission in ipairs(Constants.MISSIONS) do
        table.insert(newMissions, {
            id = mission.id,
            progress = 0,
            target = mission.target,
            completed = false,
            claimed = false,
        })
    end

    DataManager:SetValue(player, "activeMissions", newMissions)
end

function MissionService:GetPlayerMissions(player: Player)
    local activeMissions = DataManager:GetValue(player, "activeMissions") or {}
    local result = {}

    for _, active in ipairs(activeMissions) do
        local missionDef = nil
        for _, def in ipairs(Constants.MISSIONS) do
            if def.id == active.id then
                missionDef = def
                break
            end
        end

        if missionDef then
            -- Update progress from player data
            local currentProgress = DataManager:GetValue(player, missionDef.trackKey) or 0
            active.progress = math.min(currentProgress, active.target)
            active.completed = active.progress >= active.target

            table.insert(result, {
                id = active.id,
                nameAr = missionDef.nameAr,
                description = missionDef.description,
                progress = active.progress,
                target = active.target,
                reward = missionDef.reward,
                completed = active.completed,
                claimed = active.claimed,
            })
        end
    end

    return result
end

function MissionService:UpdateProgress(player: Player, trackKey: string, amount: number)
    DataManager:IncrementValue(player, trackKey, amount)

    local activeMissions = DataManager:GetValue(player, "activeMissions") or {}
    for _, active in ipairs(activeMissions) do
        local missionDef = nil
        for _, def in ipairs(Constants.MISSIONS) do
            if def.id == active.id then
                missionDef = def
                break
            end
        end

        if missionDef and missionDef.trackKey == trackKey then
            local currentProgress = DataManager:GetValue(player, trackKey) or 0
            active.progress = math.min(currentProgress, active.target)
            if active.progress >= active.target and not active.completed then
                active.completed = true
                RemoteManager:FireClient("MissionProgress", player, active.id, active.progress, active.target, true)
            else
                RemoteManager:FireClient("MissionProgress", player, active.id, active.progress, active.target, false)
            end
        end
    end
    DataManager:SetValue(player, "activeMissions", activeMissions)
end

function MissionService:ClaimMission(player: Player, missionId: string)
    local activeMissions = DataManager:GetValue(player, "activeMissions") or {}

    for _, active in ipairs(activeMissions) do
        if active.id == missionId then
            if not active.completed then
                RemoteManager:FireClient("CodeResult", player, false, "لم تكمل المهمة بعد!")
                return
            end
            if active.claimed then
                RemoteManager:FireClient("CodeResult", player, false, "لقد استلمت المكافأة بالفعل!")
                return
            end

            local missionDef = nil
            for _, def in ipairs(Constants.MISSIONS) do
                if def.id == missionId then
                    missionDef = def
                    break
                end
            end

            if missionDef then
                active.claimed = true
                EconomyService:AddMoney(player, missionDef.reward, "مكافأة مهمة: " .. missionDef.nameAr)
                DataManager:SetValue(player, "activeMissions", activeMissions)
                DataManager:AddToTable(player, "completedMissions", missionId)
                RemoteManager:FireClient("CodeResult", player, true, `حصلت على {missionDef.reward}$ من مهمة {missionDef.nameAr}!`)
            end
            return
        end
    end
end

return MissionService
