--[[
    Arab City - Chat Service
    Full chat system: public chat + private messaging between players.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local RemoteManager = Shared.RemoteManager

local DataManager

local ChatService = {}
ChatService._chatHistory = {}  -- public chat history (last 50 messages)
ChatService._privateChats = {} -- [minId_maxId] = { messages }

local MAX_PUBLIC_HISTORY = 50
local MAX_PRIVATE_HISTORY = 30
local MAX_MESSAGE_LENGTH = 200
local COOLDOWN_SECONDS = 1
local _lastMessageTime = {} -- [userId] = timestamp

function ChatService:Init(dataManager)
    DataManager = dataManager

    -- Public chat
    RemoteManager:OnServerEvent("ChatSendPublic", function(player, message)
        self:_handlePublicMessage(player, message)
    end)

    -- Private message
    RemoteManager:OnServerEvent("ChatSendPrivate", function(player, targetUserId, message)
        self:_handlePrivateMessage(player, targetUserId, message)
    end)

    -- Request chat history
    RemoteManager:SetServerCallback("GetChatHistory", function(_player)
        return self._chatHistory
    end)

    -- Request private chat history
    RemoteManager:SetServerCallback("GetPrivateChat", function(player, targetUserId)
        if type(targetUserId) ~= "number" then
            return {}
        end
        local key = self:_chatKey(player.UserId, targetUserId)
        return self._privateChats[key] or {}
    end)

    -- Get online players list for private chat
    RemoteManager:SetServerCallback("GetOnlinePlayers", function(player)
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId ~= player.UserId then
                table.insert(list, {
                    userId = p.UserId,
                    name = p.Name,
                    displayName = p.DisplayName,
                })
            end
        end
        return list
    end)

    Players.PlayerRemoving:Connect(function(player)
        _lastMessageTime[player.UserId] = nil
    end)
end

function ChatService:_handlePublicMessage(player: Player, message: string)
    if type(message) ~= "string" then
        return
    end

    -- Rate limit
    local now = os.clock()
    if _lastMessageTime[player.UserId] and (now - _lastMessageTime[player.UserId]) < COOLDOWN_SECONDS then
        return
    end
    _lastMessageTime[player.UserId] = now

    -- Trim and limit
    message = string.sub(message, 1, MAX_MESSAGE_LENGTH)
    if #message == 0 then
        return
    end

    -- Filter text
    local filtered = self:_filterText(player, message)
    if not filtered then
        return
    end

    local data = DataManager:GetData(player)

    local entry = {
        sender = player.Name,
        senderDisplay = player.DisplayName,
        senderId = player.UserId,
        message = filtered,
        timestamp = DateTime.now().UnixTimestamp,
        rank = data and data.rank or "None",
        isAdmin = data and data.isAdmin or false,
    }

    table.insert(self._chatHistory, entry)
    if #self._chatHistory > MAX_PUBLIC_HISTORY then
        table.remove(self._chatHistory, 1)
    end

    -- Broadcast to all players
    RemoteManager:FireAllClients("ChatPublicMessage", entry)
end

function ChatService:_handlePrivateMessage(player: Player, targetUserId: number, message: string)
    if type(message) ~= "string" or type(targetUserId) ~= "number" then
        return
    end

    -- Rate limit
    local now = os.clock()
    if _lastMessageTime[player.UserId] and (now - _lastMessageTime[player.UserId]) < COOLDOWN_SECONDS then
        return
    end
    _lastMessageTime[player.UserId] = now

    -- Trim and limit
    message = string.sub(message, 1, MAX_MESSAGE_LENGTH)
    if #message == 0 then
        return
    end

    -- Filter text
    local filtered = self:_filterText(player, message)
    if not filtered then
        return
    end

    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == targetUserId then
            target = p
            break
        end
    end

    if not target then
        RemoteManager:FireClient("ChatPrivateMessage", player, {
            sender = "النظام",
            senderDisplay = "النظام",
            senderId = 0,
            message = "اللاعب غير متصل",
            timestamp = DateTime.now().UnixTimestamp,
            isSystem = true,
        })
        return
    end

    local entry = {
        sender = player.Name,
        senderDisplay = player.DisplayName,
        senderId = player.UserId,
        targetId = targetUserId,
        message = filtered,
        timestamp = DateTime.now().UnixTimestamp,
    }

    -- Store in history
    local key = self:_chatKey(player.UserId, targetUserId)
    if not self._privateChats[key] then
        self._privateChats[key] = {}
    end
    table.insert(self._privateChats[key], entry)
    if #self._privateChats[key] > MAX_PRIVATE_HISTORY then
        table.remove(self._privateChats[key], 1)
    end

    -- Send to both parties
    RemoteManager:FireClient("ChatPrivateMessage", player, entry)
    RemoteManager:FireClient("ChatPrivateMessage", target, entry)
end

function ChatService:_filterText(player: Player, message: string): string?
    local success, result = pcall(function()
        local textObject = TextService:FilterStringAsync(message, player.UserId)
        return textObject:GetNonChatStringForBroadcastAsync()
    end)
    if success then
        return result
    end
    -- Fallback: return original if filter fails (dev environment)
    return message
end

function ChatService:_chatKey(userId1: number, userId2: number): string
    local minId = math.min(userId1, userId2)
    local maxId = math.max(userId1, userId2)
    return tostring(minId) .. "_" .. tostring(maxId)
end

return ChatService
