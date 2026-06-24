--[[
    Arab City - Admin Service
    Professional admin panel: give money, ban, promote job, promote to admin.
    Only visible/accessible to admins.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DataManager
local EconomyService

local AdminService = {}
AdminService._admins = {} -- [userId] = true
AdminService._banStore = DataStoreService:GetDataStore("ArabCity_Bans_v1")

function AdminService:Init(dataManager, economyService)
    DataManager = dataManager
    EconomyService = economyService

    -- Owner is always admin
    if Constants.OWNER_USER_ID > 0 then
        self._admins[Constants.OWNER_USER_ID] = true
    end

    -- Check if player is admin on join
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

    -- Admin actions from client
    RemoteManager:OnServerEvent("AdminAction", function(player, action, data)
        if not self:IsAdmin(player) then
            warn(`[AdminService] Non-admin {player.Name} tried action: {action}`)
            return
        end
        self:_handleAction(player, action, data)
    end)

    -- Check admin status
    RemoteManager:SetServerCallback("IsAdmin", function(player)
        return self:IsAdmin(player)
    end)

    -- Get player list for admin panel
    RemoteManager:SetServerCallback("GetPlayerList", function(player)
        if not self:IsAdmin(player) then
            return {}
        end
        return self:_getPlayerList()
    end)
end

function AdminService:_onPlayerJoined(player: Player)
    -- Wait for data
    local attempts = 0
    while not DataManager:GetData(player) and attempts < 50 do
        task.wait(0.2)
        attempts += 1
    end

    -- Check if player is banned (persisted in DataStore)
    local banInfo = self:_getBan(player.UserId)
    if banInfo then
        if banInfo.duration == 0 then
            -- Permanent ban
            player:Kick("تم حظرك نهائياً من اللعبة.\nالسبب: " .. (banInfo.reason or "غير محدد"))
            return
        else
            local elapsed = DateTime.now().UnixTimestamp - (banInfo.bannedAt or 0)
            if elapsed < banInfo.duration then
                local remaining = math.ceil((banInfo.duration - elapsed) / 60)
                player:Kick("تم حظرك مؤقتاً.\nالسبب: " .. (banInfo.reason or "غير محدد") .. "\nالمتبقي: " .. remaining .. " دقيقة")
                return
            else
                -- Ban expired, remove from DataStore
                self:_removeBan(player.UserId)
            end
        end
    end

    -- Check saved admin status
    local data = DataManager:GetData(player)
    if data and data.isAdmin then
        self._admins[player.UserId] = true
    end

    -- Notify client of admin status
    if self:IsAdmin(player) then
        RemoteManager:FireClient("AdminStatus", player, true)
    end
end

function AdminService:IsAdmin(player: Player): boolean
    return self._admins[player.UserId] == true
end

function AdminService:_handleAction(admin: Player, action: string, data: { [string]: any })
    if action == "giveMoney" then
        self:_giveMoney(admin, data)
    elseif action == "ban" then
        self:_banPlayer(admin, data)
    elseif action == "unban" then
        self:_unbanPlayer(admin, data)
    elseif action == "promoteJob" then
        self:_promoteJob(admin, data)
    elseif action == "promoteAdmin" then
        self:_promoteAdmin(admin, data)
    elseif action == "demoteAdmin" then
        self:_demoteAdmin(admin, data)
    elseif action == "kick" then
        self:_kickPlayer(admin, data)
    end
end

function AdminService:_giveMoney(admin: Player, data: { [string]: any })
    local targetId = data.targetUserId
    local amount = tonumber(data.amount)
    if not targetId or not amount or amount <= 0 then
        return
    end

    local target = self:_findPlayer(targetId)
    if not target then
        RemoteManager:FireClient("AdminResponse", admin, {
            success = false,
            message = "اللاعب غير متصل",
        })
        return
    end

    EconomyService:AddMoney(target, amount, "هدية من الأدمن")
    RemoteManager:FireClient("AdminResponse", admin, {
        success = true,
        message = "تم إعطاء " .. tostring(amount) .. "$ لـ " .. target.Name,
    })

    -- Notify target
    RemoteManager:FireClient("BuildingAction", target, {
        type = "notification",
        title = "مكافأة",
        message = "حصلت على " .. tostring(amount) .. "$ من الإدارة!",
        icon = "money",
    })
end

function AdminService:_banPlayer(admin: Player, data: { [string]: any })
    local targetId = data.targetUserId
    local reason = data.reason or "مخالفة القوانين"
    local duration = tonumber(data.duration) or 0 -- 0 = permanent, else seconds
    if not targetId then
        return
    end

    local banData = {
        reason = reason,
        duration = duration,
        bannedAt = DateTime.now().UnixTimestamp,
        bannedBy = admin.UserId,
    }
    self:_saveBan(targetId, banData)

    local target = self:_findPlayer(targetId)
    if target then
        if duration == 0 then
            target:Kick("تم حظرك نهائياً.\nالسبب: " .. reason)
        else
            local minutes = math.ceil(duration / 60)
            target:Kick("تم حظرك مؤقتاً لمدة " .. minutes .. " دقيقة.\nالسبب: " .. reason)
        end
    end

    local durationText = duration == 0 and "نهائي" or (math.ceil(duration / 60) .. " دقيقة")
    RemoteManager:FireClient("AdminResponse", admin, {
        success = true,
        message = "تم حظر اللاعب (" .. durationText .. ")",
    })
end

function AdminService:_unbanPlayer(admin: Player, data: { [string]: any })
    local targetId = data.targetUserId
    if not targetId then
        return
    end

    self:_removeBan(targetId)
    RemoteManager:FireClient("AdminResponse", admin, {
        success = true,
        message = "تم رفع الحظر عن اللاعب",
    })
end

function AdminService:_promoteJob(admin: Player, data: { [string]: any })
    local targetId = data.targetUserId
    local jobId = data.jobId
    if not targetId or not jobId then
        return
    end

    local target = self:_findPlayer(targetId)
    if not target then
        RemoteManager:FireClient("AdminResponse", admin, {
            success = false,
            message = "اللاعب غير متصل",
        })
        return
    end

    DataManager:SetValue(target, "job", jobId)
    RemoteManager:FireClient("AdminResponse", admin, {
        success = true,
        message = "تم ترقية " .. target.Name .. " إلى وظيفة: " .. jobId,
    })

    RemoteManager:FireClient("BuildingAction", target, {
        type = "notification",
        title = "ترقية",
        message = "تم ترقيتك إلى وظيفة جديدة بواسطة الإدارة!",
        icon = "job",
    })
end

function AdminService:_promoteAdmin(admin: Player, data: { [string]: any })
    local targetId = data.targetUserId
    if not targetId then
        return
    end

    self._admins[targetId] = true

    local target = self:_findPlayer(targetId)
    if target then
        DataManager:SetValue(target, "isAdmin", true)
        RemoteManager:FireClient("AdminStatus", target, true)
        RemoteManager:FireClient("BuildingAction", target, {
            type = "notification",
            title = "ترقية",
            message = "تمت ترقيتك إلى أدمن!",
            icon = "admin",
        })
    end

    RemoteManager:FireClient("AdminResponse", admin, {
        success = true,
        message = "تم ترقية اللاعب إلى أدمن",
    })
end

function AdminService:_demoteAdmin(admin: Player, data: { [string]: any })
    local targetId = data.targetUserId
    if not targetId then
        return
    end

    -- Cannot demote owner
    if targetId == Constants.OWNER_USER_ID then
        RemoteManager:FireClient("AdminResponse", admin, {
            success = false,
            message = "لا يمكن إزالة صلاحيات المالك",
        })
        return
    end

    self._admins[targetId] = nil

    local target = self:_findPlayer(targetId)
    if target then
        DataManager:SetValue(target, "isAdmin", false)
        RemoteManager:FireClient("AdminStatus", target, false)
    end

    RemoteManager:FireClient("AdminResponse", admin, {
        success = true,
        message = "تم إزالة صلاحيات الأدمن",
    })
end

function AdminService:_kickPlayer(admin: Player, data: { [string]: any })
    local targetId = data.targetUserId
    local reason = data.reason or "طرد بواسطة الإدارة"
    if not targetId then
        return
    end

    local target = self:_findPlayer(targetId)
    if target then
        target:Kick(reason)
        RemoteManager:FireClient("AdminResponse", admin, {
            success = true,
            message = "تم طرد اللاعب",
        })
    else
        RemoteManager:FireClient("AdminResponse", admin, {
            success = false,
            message = "اللاعب غير متصل",
        })
    end
end

function AdminService:_findPlayer(userId: number): Player?
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == userId then
            return player
        end
    end
    return nil
end

function AdminService:_getPlayerList(): { any }
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local data = DataManager:GetData(player)
        table.insert(list, {
            userId = player.UserId,
            name = player.Name,
            displayName = player.DisplayName,
            cash = data and data.cash or 0,
            job = data and data.job or "None",
            rank = data and data.rank or "None",
            isAdmin = self._admins[player.UserId] == true,
            level = data and data.level or 1,
        })
    end
    return list
end

-- DataStore-backed ban persistence

function AdminService:_getBan(userId: number): { [string]: any }?
    local success, result = pcall(function()
        return self._banStore:GetAsync("Ban_" .. tostring(userId))
    end)
    if success and result then
        return result
    end
    return nil
end

function AdminService:_saveBan(userId: number, banData: { [string]: any })
    local success, err = pcall(function()
        self._banStore:SetAsync("Ban_" .. tostring(userId), banData)
    end)
    if not success then
        warn("[AdminService] Failed to persist ban for " .. tostring(userId) .. ": " .. tostring(err))
    end
end

function AdminService:_removeBan(userId: number)
    local success, err = pcall(function()
        self._banStore:RemoveAsync("Ban_" .. tostring(userId))
    end)
    if not success then
        warn("[AdminService] Failed to remove ban for " .. tostring(userId) .. ": " .. tostring(err))
    end
end

return AdminService
