--[[
    Arab City v2.0 - FriendService
    In-game friend requests and online status.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FriendService = {}

local Shared, Remotes, DataService
local _pendingRequests = {}

function FriendService:Init(dataService)
    DataService = dataService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("SendFriendRequest", function(player, action, targetName)
        if action == "send" then
            self:_sendRequest(player, targetName)
        elseif action == "accept" then
            self:_acceptRequest(player, targetName)
        elseif action == "reject" then
            self:_rejectRequest(player, targetName)
        elseif action == "remove" then
            self:_removeFriend(player, targetName)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        _pendingRequests[player.UserId] = nil
    end)
end

function FriendService:_findPlayer(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == name or p.DisplayName == name then return p end
    end
    return nil
end

function FriendService:_sendRequest(player, targetName)
    if type(targetName) ~= "string" then return end
    local target = self:_findPlayer(targetName)
    if not target or target == player then
        Remotes:FireClient("FriendRequestResult", player, { success = false, message = "اللاعب غير موجود" })
        return
    end

    local data = DataService:Get(player)
    if data then
        for _, fId in ipairs(data.friends) do
            if fId == target.UserId then
                Remotes:FireClient("FriendRequestResult", player, { success = false, message = "هذا اللاعب صديقك بالفعل" })
                return
            end
        end
    end

    if not _pendingRequests[target.UserId] then
        _pendingRequests[target.UserId] = {}
    end
    _pendingRequests[target.UserId][player.UserId] = true

    Remotes:FireClient("FriendUpdate", target, {
        type = "request",
        fromName = player.DisplayName,
        fromId = player.UserId,
    })
    Remotes:FireClient("FriendRequestResult", player, {
        success = true,
        message = "تم إرسال طلب صداقة إلى " .. target.DisplayName,
    })
end

function FriendService:_acceptRequest(player, fromName)
    if type(fromName) ~= "string" then return end
    local from = self:_findPlayer(fromName)
    if not from then return end

    local pending = _pendingRequests[player.UserId]
    if not pending or not pending[from.UserId] then return end
    pending[from.UserId] = nil

    local myData = DataService:Get(player)
    local theirData = DataService:Get(from)
    if myData then table.insert(myData.friends, from.UserId) end
    if theirData then table.insert(theirData.friends, player.UserId) end

    Remotes:FireClient("FriendUpdate", player, { type = "accepted", friendName = from.DisplayName })
    Remotes:FireClient("FriendUpdate", from, { type = "accepted", friendName = player.DisplayName })
end

function FriendService:_rejectRequest(player, fromName)
    if type(fromName) ~= "string" then return end
    local from = self:_findPlayer(fromName)
    if not from then return end
    local pending = _pendingRequests[player.UserId]
    if pending then pending[from.UserId] = nil end
end

function FriendService:_removeFriend(player, friendName)
    if type(friendName) ~= "string" then return end
    local friend = self:_findPlayer(friendName)
    if not friend then return end

    local myData = DataService:Get(player)
    if myData then
        for i, fId in ipairs(myData.friends) do
            if fId == friend.UserId then
                table.remove(myData.friends, i)
                break
            end
        end
    end

    local theirData = DataService:Get(friend)
    if theirData then
        for i, fId in ipairs(theirData.friends) do
            if fId == player.UserId then
                table.remove(theirData.friends, i)
                break
            end
        end
    end

    Remotes:FireClient("FriendUpdate", player, { type = "removed", friendName = friend.DisplayName })
end

return FriendService
