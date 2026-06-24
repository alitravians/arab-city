--[[
    Arab City v2.0 - AdminService
    Admin panel backend — give money, ban, promote, admin management.
    Bans persist in DataStore.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminService = {}

local Shared, Constants, Remotes, DataService, EconomyService
local banStore = nil

pcall(function()
    banStore = DataStoreService:GetDataStore("ArabCity_Bans_v2")
end)

function AdminService:Init(dataService, economyService)
    DataService = dataService
    EconomyService = economyService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("AdminAction", function(player, action, payload)
        if not self:IsAdmin(player) then
            Remotes:FireClient("AdminResponse", player, {
                success = false, message = "ليس لديك صلاحيات الأدمن"
            })
            return
        end
        self:_handleAction(player, action, payload)
    end)

    Players.PlayerAdded:Connect(function(p)
        self:_checkBan(p)
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        task.spawn(function() self:_checkBan(p) end)
    end
end

function AdminService:IsAdmin(player)
    if Constants.OWNER_USER_IDS[player.UserId] then return true end
    local data = DataService:Get(player)
    return data and data.isAdmin == true
end

function AdminService:_checkBan(player)
    local ok, banData = pcall(function()
        if banStore then
            return banStore:GetAsync(tostring(player.UserId))
        end
        return nil
    end)
    if ok and banData and type(banData) == "table" then
        if banData.duration == -1 then
            player:Kick("أنت محظور بشكل دائم.\nالسبب: " .. (banData.reason or "غير محدد"))
            return
        end
        local elapsed = os.time() - (banData.timestamp or 0)
        if elapsed < banData.duration then
            local remaining = banData.duration - elapsed
            local mins = math.ceil(remaining / 60)
            player:Kick("أنت محظور مؤقتاً.\nالسبب: " .. (banData.reason or "غير محدد") .. "\nالمدة المتبقية: " .. tostring(mins) .. " دقيقة")
        else
            pcall(function()
                if banStore then
                    banStore:RemoveAsync(tostring(player.UserId))
                end
            end)
        end
    end
end

function AdminService:_handleAction(admin, action, payload)
    if action == "giveMoney" then
        self:_giveMoney(admin, payload)
    elseif action == "kickPlayer" then
        self:_kickPlayer(admin, payload)
    elseif action == "banPlayer" then
        self:_banPlayer(admin, payload)
    elseif action == "unbanPlayer" then
        self:_unbanPlayer(admin, payload)
    elseif action == "promoteJob" then
        self:_promoteJob(admin, payload)
    elseif action == "promoteAdmin" then
        self:_promoteAdmin(admin, payload)
    elseif action == "removeAdmin" then
        self:_removeAdmin(admin, payload)
    else
        Remotes:FireClient("AdminResponse", admin, {
            success = false, message = "إجراء غير معروف"
        })
    end
end

function AdminService:_findPlayer(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if string.lower(p.Name) == string.lower(name) or
           string.lower(p.DisplayName) == string.lower(name) then
            return p
        end
    end
    return nil
end

function AdminService:_giveMoney(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    local amount = tonumber(payload.amount)
    if not target then
        Remotes:FireClient("AdminResponse", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    if not amount or amount <= 0 or amount > 10000000 then
        Remotes:FireClient("AdminResponse", admin, { success = false, message = "مبلغ غير صالح" })
        return
    end
    EconomyService:AddCash(target, amount)
    Remotes:FireClient("ShowNotification", target, {
        title = "مكافأة من الأدمن",
        message = "حصلت على $" .. tostring(math.floor(amount)) .. " من " .. admin.DisplayName,
        icon = "💰", duration = 5,
    })
    Remotes:FireClient("AdminResponse", admin, {
        success = true, message = "تم إعطاء $" .. tostring(math.floor(amount)) .. " لـ " .. target.DisplayName
    })
end

function AdminService:_kickPlayer(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResponse", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    local reason = payload.reason or "تم طردك من قبل الأدمن"
    target:Kick(reason)
    Remotes:FireClient("AdminResponse", admin, {
        success = true, message = "تم طرد " .. target.DisplayName
    })
end

function AdminService:_banPlayer(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResponse", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    local duration = payload.duration or 3600
    local reason = payload.reason or "محظور من قبل الأدمن"

    local banData = {
        bannedBy = admin.UserId,
        bannedByName = admin.DisplayName,
        reason = reason,
        duration = duration,
        timestamp = os.time(),
    }

    pcall(function()
        if banStore then
            banStore:SetAsync(tostring(target.UserId), banData)
        end
    end)

    if duration == -1 then
        target:Kick("تم حظرك بشكل دائم.\nالسبب: " .. reason)
    else
        target:Kick("تم حظرك مؤقتاً.\nالسبب: " .. reason .. "\nالمدة: " .. tostring(math.ceil(duration / 60)) .. " دقيقة")
    end

    Remotes:FireClient("AdminResponse", admin, {
        success = true,
        message = "تم حظر " .. target.DisplayName .. (duration == -1 and " بشكل دائم" or " لمدة " .. tostring(math.ceil(duration / 60)) .. " دقيقة")
    })
end

function AdminService:_unbanPlayer(admin, payload)
    local userId = tonumber(payload.userId)
    if not userId then
        Remotes:FireClient("AdminResponse", admin, { success = false, message = "معرف اللاعب غير صالح" })
        return
    end
    pcall(function()
        if banStore then
            banStore:RemoveAsync(tostring(userId))
        end
    end)
    Remotes:FireClient("AdminResponse", admin, {
        success = true, message = "تم رفع الحظر عن اللاعب #" .. tostring(userId)
    })
end

function AdminService:_promoteJob(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResponse", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    local jobId = payload.jobId or ""
    local found = false
    for _, job in ipairs(Constants.JOBS) do
        if job.id == jobId then found = true break end
    end
    if not found then
        Remotes:FireClient("AdminResponse", admin, { success = false, message = "وظيفة غير صالحة" })
        return
    end
    DataService:Set(target, "job", jobId)
    Remotes:FireClient("ShowNotification", target, {
        title = "ترقية!",
        message = "تمت ترقيتك إلى وظيفة جديدة من قبل الأدمن",
        icon = "⬆️", duration = 5,
    })
    Remotes:FireClient("AdminResponse", admin, {
        success = true, message = "تم ترقية " .. target.DisplayName .. " إلى وظيفة " .. jobId
    })
end

function AdminService:_promoteAdmin(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResponse", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    DataService:Set(target, "isAdmin", true)
    Remotes:FireClient("ShowNotification", target, {
        title = "ترقية أدمن!",
        message = "تمت ترقيتك إلى أدمن من قبل " .. admin.DisplayName,
        icon = "⭐", duration = 5,
    })
    Remotes:FireClient("AdminResponse", admin, {
        success = true, message = "تم ترقية " .. target.DisplayName .. " إلى أدمن"
    })
end

function AdminService:_removeAdmin(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResponse", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    DataService:Set(target, "isAdmin", false)
    Remotes:FireClient("AdminResponse", admin, {
        success = true, message = "تم إزالة صلاحيات الأدمن من " .. target.DisplayName
    })
end

return AdminService
