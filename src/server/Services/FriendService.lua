--[[
    Arab City - Friend Service
    Send/accept/decline friend requests, online status
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local RemoteManager = Shared.RemoteManager

local FriendService = {}
FriendService._dataManager = nil

function FriendService:Init(dataManager)
    self._dataManager = dataManager

    RemoteManager:OnServerEvent("SendFriendRequest", function(player, targetUserId)
        self:_sendRequest(player, targetUserId)
    end)

    RemoteManager:OnServerEvent("AcceptFriendRequest", function(player, fromUserId)
        self:_acceptRequest(player, fromUserId)
    end)

    RemoteManager:OnServerEvent("DeclineFriendRequest", function(player, fromUserId)
        self:_declineRequest(player, fromUserId)
    end)

    RemoteManager:OnServerEvent("RemoveFriend", function(player, friendUserId)
        self:_removeFriend(player, friendUserId)
    end)

    RemoteManager:RegisterFunction("GetFriendsList", function(player)
        return self:_getFriendsList(player)
    end)

    RemoteManager:RegisterFunction("GetFriendRequests", function(player)
        local data = self._dataManager:GetPlayerData(player)
        if not data then return {} end
        return data.friendRequests or {}
    end)
end

function FriendService:_sendRequest(player: Player, targetUserId: number)
    local myData = self._dataManager:GetPlayerData(player)
    if not myData then return end

    -- Check if already friends
    for _, fid in ipairs(myData.friends or {}) do
        if fid == targetUserId then
            RemoteManager:FireClient(player, "ShowNotification", "error", "هذا اللاعب صديقك بالفعل")
            return
        end
    end

    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then
        RemoteManager:FireClient(player, "ShowNotification", "error", "اللاعب غير متصل")
        return
    end

    local targetData = self._dataManager:GetPlayerData(targetPlayer)
    if not targetData then return end

    -- Check for duplicate request
    for _, req in ipairs(targetData.friendRequests or {}) do
        if req.fromUserId == player.UserId then
            RemoteManager:FireClient(player, "ShowNotification", "info", "طلب الصداقة مرسل مسبقاً")
            return
        end
    end

    table.insert(targetData.friendRequests, {
        fromUserId = player.UserId,
        fromName = player.Name,
        timestamp = DateTime.now().UnixTimestamp,
    })

    RemoteManager:FireClient(targetPlayer, "FriendRequestReceived", player.Name, player.UserId)
    RemoteManager:FireClient(targetPlayer, "ShowNotification", "friend", player.Name .. " أرسل لك طلب صداقة")
    RemoteManager:FireClient(player, "ShowNotification", "success", "تم إرسال طلب الصداقة")
end

function FriendService:_acceptRequest(player: Player, fromUserId: number)
    local myData = self._dataManager:GetPlayerData(player)
    if not myData then return end

    local foundIdx = nil
    for i, req in ipairs(myData.friendRequests or {}) do
        if req.fromUserId == fromUserId then
            foundIdx = i
            break
        end
    end

    if not foundIdx then return end

    table.remove(myData.friendRequests, foundIdx)
    table.insert(myData.friends, fromUserId)

    -- Add to other player's friends too if online
    local fromPlayer = Players:GetPlayerByUserId(fromUserId)
    if fromPlayer then
        local fromData = self._dataManager:GetPlayerData(fromPlayer)
        if fromData then
            table.insert(fromData.friends, player.UserId)
            RemoteManager:FireClient(fromPlayer, "FriendUpdate", "accepted", player.Name)
            RemoteManager:FireClient(fromPlayer, "ShowNotification", "friend", player.Name .. " قبل طلب صداقتك!")
        end
    end

    RemoteManager:FireClient(player, "FriendUpdate", "added", fromUserId)
    RemoteManager:FireClient(player, "ShowNotification", "success", "تم قبول طلب الصداقة")
end

function FriendService:_declineRequest(player: Player, fromUserId: number)
    local myData = self._dataManager:GetPlayerData(player)
    if not myData then return end

    for i, req in ipairs(myData.friendRequests or {}) do
        if req.fromUserId == fromUserId then
            table.remove(myData.friendRequests, i)
            break
        end
    end
end

function FriendService:_removeFriend(player: Player, friendUserId: number)
    local myData = self._dataManager:GetPlayerData(player)
    if not myData then return end

    for i, fid in ipairs(myData.friends or {}) do
        if fid == friendUserId then
            table.remove(myData.friends, i)
            break
        end
    end

    local friendPlayer = Players:GetPlayerByUserId(friendUserId)
    if friendPlayer then
        local friendData = self._dataManager:GetPlayerData(friendPlayer)
        if friendData then
            for i, fid in ipairs(friendData.friends or {}) do
                if fid == player.UserId then
                    table.remove(friendData.friends, i)
                    break
                end
            end
        end
    end

    RemoteManager:FireClient(player, "FriendUpdate", "removed", friendUserId)
end

function FriendService:_getFriendsList(player: Player): { any }
    local data = self._dataManager:GetPlayerData(player)
    if not data then return {} end

    local result = {}
    for _, fid in ipairs(data.friends or {}) do
        local friendPlayer = Players:GetPlayerByUserId(fid)
        table.insert(result, {
            userId = fid,
            online = friendPlayer ~= nil,
            name = friendPlayer and friendPlayer.Name or ("Player_" .. fid),
        })
    end
    return result
end

return FriendService
