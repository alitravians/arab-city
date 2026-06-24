--[[
    Arab City v2.0 - AdminService
    Admin panel backend — PIN access (3131), give money, ban, mute, promote.
    Bans persist in DataStore.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminService = {}

local Shared, Constants, Remotes, DataService, EconomyService
local banStore = nil
local ADMIN_PIN = "3131"

local _authenticatedPlayers = {}
local _mutedPlayers = {}

pcall(function()
    banStore = DataStoreService:GetDataStore("ArabCity_Bans_v2")
end)

function AdminService:Init(dataService, economyService)
    DataService = dataService
    EconomyService = economyService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    -- PIN login
    Remotes:OnServerEvent("AdminLogin", function(player, pin)
        if pin == ADMIN_PIN then
            _authenticatedPlayers[player.UserId] = true
            Remotes:FireClient("AdminResult", player, {
                success = true, message = "تم تسجيل الدخول بنجاح"
            })
        else
            Remotes:FireClient("AdminResult", player, {
                success = false, message = "رمز الدخول غير صحيح"
            })
        end
    end)

    -- Admin actions
    Remotes:OnServerEvent("AdminAction", function(player, action, payload)
        if not self:_isAuthenticated(player) then
            Remotes:FireClient("AdminResult", player, {
                success = false, message = "يجب تسجيل الدخول أولاً"
            })
            return
        end
        if type(payload) ~= "table" then payload = {} end
        self:_handleAction(player, action, payload)
    end)

    -- Ban check on join
    Players.PlayerAdded:Connect(function(p)
        self:_checkBan(p)
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        task.spawn(function() self:_checkBan(p) end)
    end

    -- Clean up on leave
    Players.PlayerRemoving:Connect(function(p)
        _authenticatedPlayers[p.UserId] = nil
        _mutedPlayers[p.UserId] = nil
    end)
end

function AdminService:_isAuthenticated(player)
    return _authenticatedPlayers[player.UserId] == true
end

function AdminService:IsMuted(player)
    return _mutedPlayers[player.UserId] == true
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
    elseif action == "mutePlayer" then
        self:_mutePlayer(admin, payload)
    elseif action == "unmutePlayer" then
        self:_unmutePlayer(admin, payload)
    elseif action == "banPlayer" then
        self:_banPlayer(admin, payload)
    elseif action == "unbanPlayer" then
        self:_unbanPlayer(admin, payload)
    elseif action == "promoteAdmin" then
        self:_promoteAdmin(admin, payload)
    elseif action == "removeAdmin" then
        self:_removeAdmin(admin, payload)
    else
        Remotes:FireClient("AdminResult", admin, {
            success = false, message = "إجراء غير معروف: " .. tostring(action)
        })
    end
end

function AdminService:_findPlayer(name)
    if type(name) ~= "string" or name == "" then return nil end
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
        Remotes:FireClient("AdminResult", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    if not amount or amount <= 0 or amount > 10000000 then
        Remotes:FireClient("AdminResult", admin, { success = false, message = "مبلغ غير صالح (1 - 10,000,000)" })
        return
    end
    EconomyService:AddCash(target, amount)
    Remotes:FireClient("ShowNotification", target, {
        title = "مكافأة من الأدمن",
        message = "حصلت على $" .. tostring(math.floor(amount)) .. " من " .. admin.DisplayName,
        icon = "💰", duration = 5,
    })
    Remotes:FireClient("AdminResult", admin, {
        success = true, message = "تم إعطاء $" .. tostring(math.floor(amount)) .. " لـ " .. target.DisplayName
    })
end

function AdminService:_kickPlayer(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResult", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    target:Kick("تم طردك من قبل الأدمن")
    Remotes:FireClient("AdminResult", admin, {
        success = true, message = "تم طرد " .. target.DisplayName
    })
end

function AdminService:_mutePlayer(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResult", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    _mutedPlayers[target.UserId] = true
    Remotes:FireClient("ShowNotification", target, {
        title = "تم كتمك",
        message = "تم كتمك من الدردشة من قبل الأدمن",
        icon = "🔇", duration = 5,
    })
    Remotes:FireClient("AdminResult", admin, {
        success = true, message = "تم كتم " .. target.DisplayName .. " من الدردشة"
    })
end

function AdminService:_unmutePlayer(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResult", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    _mutedPlayers[target.UserId] = nil
    Remotes:FireClient("ShowNotification", target, {
        title = "تم إلغاء الكتم",
        message = "تم إلغاء كتمك من الدردشة",
        icon = "🔊", duration = 5,
    })
    Remotes:FireClient("AdminResult", admin, {
        success = true, message = "تم إلغاء كتم " .. target.DisplayName
    })
end

function AdminService:_banPlayer(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResult", admin, { success = false, message = "اللاعب غير موجود" })
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

    Remotes:FireClient("AdminResult", admin, {
        success = true,
        message = "تم حظر " .. target.DisplayName .. (if duration == -1 then " بشكل دائم" else " لمدة " .. tostring(math.ceil(duration / 60)) .. " دقيقة")
    })
end

function AdminService:_unbanPlayer(admin, payload)
    local userId = tonumber(payload.userId)
    if not userId then
        Remotes:FireClient("AdminResult", admin, { success = false, message = "أدخل UserId صالح (رقم)" })
        return
    end
    pcall(function()
        if banStore then
            banStore:RemoveAsync(tostring(userId))
        end
    end)
    Remotes:FireClient("AdminResult", admin, {
        success = true, message = "تم رفع الحظر عن اللاعب #" .. tostring(userId)
    })
end

function AdminService:_promoteAdmin(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResult", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    DataService:Set(target, "isAdmin", true)
    Remotes:FireClient("ShowNotification", target, {
        title = "ترقية أدمن!",
        message = "تمت ترقيتك إلى أدمن من قبل " .. admin.DisplayName,
        icon = "⭐", duration = 5,
    })
    Remotes:FireClient("AdminResult", admin, {
        success = true, message = "تم ترقية " .. target.DisplayName .. " إلى أدمن"
    })
end

function AdminService:_removeAdmin(admin, payload)
    local target = self:_findPlayer(payload.playerName or "")
    if not target then
        Remotes:FireClient("AdminResult", admin, { success = false, message = "اللاعب غير موجود" })
        return
    end
    DataService:Set(target, "isAdmin", false)
    Remotes:FireClient("AdminResult", admin, {
        success = true, message = "تم إزالة صلاحيات الأدمن من " .. target.DisplayName
    })
end

return AdminService
