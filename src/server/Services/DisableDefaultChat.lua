--[[
    DisableDefaultChat - Server-side enforcement
    Ensures all Roblox default chat systems are disabled at the server level.
    This runs early on the server to prevent any default chat from loading.
]]

local TextChatService = game:GetService("TextChatService")
local Chat = game:GetService("Chat")

local DisableDefaultChat = {}

function DisableDefaultChat:Init()
    -- 1. Force Chat service to not load default chat
    pcall(function()
        Chat.LoadDefaultChat = false
    end)

    -- 2. Force TextChatService to legacy mode (no built-in UI)
    pcall(function()
        TextChatService.ChatVersion = Enum.ChatVersion.LegacyChatService
    end)

    -- 3. Prevent creation of default text channels and commands
    pcall(function()
        TextChatService.CreateDefaultTextChannels = false
    end)
    pcall(function()
        TextChatService.CreateDefaultCommands = false
    end)

    -- 4. Disable ChatWindowConfiguration
    pcall(function()
        local chatWindow = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
        if chatWindow then
            chatWindow.Enabled = false
        end
    end)

    -- 5. Disable BubbleChatConfiguration
    pcall(function()
        local bubbleChat = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
        if bubbleChat then
            bubbleChat.Enabled = false
        end
    end)

    -- 6. Destroy any default TextChannels that Roblox may have created
    pcall(function()
        for _, child in ipairs(TextChatService:GetChildren()) do
            if child:IsA("TextChannel") then
                child:Destroy()
            end
        end
    end)

    -- 7. Monitor for any future chat configuration changes
    TextChatService.ChildAdded:Connect(function(child)
        if child:IsA("ChatWindowConfiguration") or child:IsA("BubbleChatConfiguration") then
            pcall(function()
                child.Enabled = false
            end)
        end
        if child:IsA("TextChannel") then
            pcall(function()
                child:Destroy()
            end)
        end
    end)

    -- 8. Persistent monitoring loop
    task.spawn(function()
        for _ = 1, 120 do
            pcall(function()
                Chat.LoadDefaultChat = false
            end)
            pcall(function()
                local cw = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
                if cw and cw.Enabled then
                    cw.Enabled = false
                end
                local bc = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
                if bc and bc.Enabled then
                    bc.Enabled = false
                end
            end)
            task.wait(1)
        end
    end)

    print("[ArabCity] Default chat disabled (server) - LegacyChatService mode enforced")
end

return DisableDefaultChat
