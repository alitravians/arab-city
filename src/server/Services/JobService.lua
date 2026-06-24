local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DataManager
local EconomyService

local JobService = {}
JobService._activeJobs = {} -- { [userId] = { jobId, startTime, nextPay } }

function JobService:Init(dataManager, economyService)
    DataManager = dataManager
    EconomyService = economyService

    RemoteManager:OnServerEvent("JoinJob", function(player, jobId)
        self:JoinJob(player, jobId)
    end)

    RemoteManager:OnServerEvent("LeaveJob", function(player)
        self:LeaveJob(player)
    end)

    RemoteManager:SetServerCallback("GetJobList", function(_player)
        return Constants.JOBS
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:LeaveJob(player)
    end)

    -- Payment loop
    task.spawn(function()
        while true do
            task.wait(1)
            self:_processPayments()
        end
    end)
end

function JobService:JoinJob(player: Player, jobId: string)
    -- Validate job exists
    local jobData = nil
    for _, job in ipairs(Constants.JOBS) do
        if job.id == jobId then
            jobData = job
            break
        end
    end

    if not jobData then
        RemoteManager:FireClient("CodeResult", player, false, "الوظيفة غير موجودة!")
        return
    end

    -- Leave current job if any
    if self._activeJobs[player.UserId] then
        self:LeaveJob(player)
    end

    local now = os.clock()
    self._activeJobs[player.UserId] = {
        jobId = jobId,
        startTime = now,
        nextPay = now + jobData.payInterval,
    }

    DataManager:SetValue(player, "job", jobId)
    RemoteManager:FireClient("JobUpdate", player, "joined", jobData)
    RemoteManager:FireClient("CodeResult", player, true, `انضممت إلى وظيفة {jobData.nameAr}!`)
end

function JobService:LeaveJob(player: Player)
    local activeJob = self._activeJobs[player.UserId]
    if not activeJob then
        return
    end

    self._activeJobs[player.UserId] = nil
    DataManager:SetValue(player, "job", "None")
    RemoteManager:FireClient("JobUpdate", player, "left", nil)
end

function JobService:_processPayments()
    local now = os.clock()
    for userId, jobInfo in pairs(self._activeJobs) do
        if now >= jobInfo.nextPay then
            local player = Players:GetPlayerByUserId(userId)
            if player then
                local jobData = nil
                for _, job in ipairs(Constants.JOBS) do
                    if job.id == jobInfo.jobId then
                        jobData = job
                        break
                    end
                end

                if jobData then
                    EconomyService:AddMoney(player, jobData.salary, "راتب " .. jobData.nameAr)
                    RemoteManager:FireClient("JobPayment", player, jobData.salary, jobData.nameAr)
                    jobInfo.nextPay = now + jobData.payInterval
                end
            else
                self._activeJobs[userId] = nil
            end
        end
    end
end

function JobService:GetPlayerJob(player: Player): string
    local active = self._activeJobs[player.UserId]
    return active and active.jobId or "None"
end

return JobService
