--[[
    Arab City v2.0 - JobService
    Job application and salary collection.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JobService = {}

local Shared, Constants, Remotes, DataService, EconomyService, XPService
local SALARY_COOLDOWN = 300

local _lastSalary = {}

function JobService:Init(dataService, economyService, xpService)
    DataService = dataService
    EconomyService = economyService
    XPService = xpService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("ApplyForJob", function(player, jobId)
        self:_apply(player, jobId)
    end)

    Remotes:OnServerEvent("CollectSalary", function(player)
        self:_collectSalary(player)
    end)
end

function JobService:_apply(player, jobId)
    if type(jobId) ~= "string" then return end

    local job = nil
    for _, j in ipairs(Constants.JOBS) do
        if j.id == jobId then job = j break end
    end
    if not job then
        Remotes:FireClient("JobResult", player, { success = false, message = "وظيفة غير صالحة" })
        return
    end

    DataService:Set(player, "job", jobId)
    Remotes:FireClient("JobResult", player, {
        success = true,
        message = "تم تعيينك كـ " .. job.name,
        jobId = jobId,
    })
    Remotes:FireClient("ShowNotification", player, {
        title = "وظيفة جديدة!",
        message = "أصبحت " .. job.name .. " — الراتب: $" .. tostring(job.salary),
        icon = job.icon, duration = 4,
    })
end

function JobService:_collectSalary(player)
    local data = DataService:Get(player)
    if not data or data.job == "" then
        Remotes:FireClient("JobResult", player, { success = false, message = "ليس لديك وظيفة" })
        return
    end

    local now = os.time()
    local userId = player.UserId
    if _lastSalary[userId] and (now - _lastSalary[userId]) < SALARY_COOLDOWN then
        local remaining = SALARY_COOLDOWN - (now - _lastSalary[userId])
        Remotes:FireClient("JobResult", player, {
            success = false,
            message = "انتظر " .. tostring(math.ceil(remaining / 60)) .. " دقيقة لجمع الراتب",
        })
        return
    end

    local job = nil
    for _, j in ipairs(Constants.JOBS) do
        if j.id == data.job then job = j break end
    end
    if not job then return end

    _lastSalary[userId] = now
    EconomyService:AddCash(player, job.salary)
    if XPService then
        XPService:AddXP(player, Constants.XP_SOURCES.job_complete)
    end

    Remotes:FireClient("JobResult", player, {
        success = true,
        message = "تم جمع الراتب: $" .. tostring(job.salary),
    })
end

return JobService
