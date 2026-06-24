--[[
    Arab City v2.0 - ChatService
    Custom chat system — public + private messaging.
    Text filtering via TextService for Roblox compliance.
]]

local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChatService = {}

local Shared, Remotes

function ChatService:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes

    Remotes:OnServerEvent("SendChatMessage", function(player, message)
        self:_handlePublicMessage(player, message)
    end)

    Remotes:OnServerEvent("SendPrivateMessage", function(player, targetName, message)
        self:_handlePrivateMessage(player, targetName, message)
    end)
end

function ChatService:_filterText(text, fromUserId, toUserId)
    local ok, filtered = pcall(function()
        local result = TextService:FilterStringAsync(text, fromUserId, Enum.TextFilterContext.PublicChat)
        if toUserId then
            return result:GetChatForUserAsync(toUserId)
        else
            return result:GetNonChatStringForBroadcastAsync()
        end
    end)
    if ok then
        return filtered
    end
    return "***"
end

function ChatService:_handlePublicMessage(player, rawMessage)
    if type(rawMessage) ~= "string" then return end
    rawMessage = string.sub(rawMessage, 1, 200)
    if #rawMessage == 0 then return end

    local filtered = self:_filterText(rawMessage, player.UserId)

    local msgData = {
        sender = player.Name,
        senderDisplayName = player.DisplayName,
        senderId = player.UserId,
        message = filtered,
        timestamp = os.time(),
        channel = "public",
    }

    Remotes:FireAllClients("ReceiveChatMessage", msgData)
end

function ChatService:_handlePrivateMessage(player, targetName, rawMessage)
    if type(rawMessage) ~= "string" or type(targetName) ~= "string" then return end
    rawMessage = string.sub(rawMessage, 1, 200)
    if #rawMessage == 0 then return end

    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == targetName or p.DisplayName == targetName then
            target = p
            break
        end
    end
    if not target or target == player then return end

    local filtered = self:_filterText(rawMessage, player.UserId, target.UserId)

    local msgData = {
        sender = player.Name,
        senderDisplayName = player.DisplayName,
        senderId = player.UserId,
        targetName = target.Name,
        targetDisplayName = target.DisplayName,
        message = filtered,
        timestamp = os.time(),
        channel = "private",
    }

    Remotes:FireClient("ReceivePrivateMessage", player, msgData)
    Remotes:FireClient("ReceivePrivateMessage", target, msgData)
end

return ChatService
