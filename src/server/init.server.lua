--[[
    Arab City - Server Entry Point (v2.0)
    Clean rebuild from scratch.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chat = game:GetService("Chat")
local TextChatService = game:GetService("TextChatService")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))

-- Disable all default chat systems
pcall(function() Chat.LoadDefaultChat = false end)
pcall(function() TextChatService.ChatVersion = Enum.ChatVersion.LegacyChatService end)
pcall(function() TextChatService.CreateDefaultTextChannels = false end)
pcall(function() TextChatService.CreateDefaultCommands = false end)
pcall(function()
    local cw = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
    if cw then cw.Enabled = false end
end)
pcall(function()
    local bc = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
    if bc then bc.Enabled = false end
end)

print("[ArabCity] Server initialized - " .. Shared.Constants.VERSION)
