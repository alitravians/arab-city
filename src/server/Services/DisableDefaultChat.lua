--[[
    DisableDefaultChat - Server-side enforcement
    Ensures all Roblox default chat systems are disabled at the server level.
    This runs early on the server to prevent any default chat from loading.
]]

local TextChatService = game:GetService("TextChatService")
local Chat = game:GetService("Chat")

local DisableDefaultChat = {}

function DisableDefaultChat:Init()
    -- Force Chat service to not load default chat
    pcall(function()
        Chat.LoadDefaultChat = false
    end)

    -- Disable ChatWindowConfiguration (new TextChatService UI)
    pcall(function()
        local chatWindow = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
        if chatWindow then
            chatWindow.Enabled = false
        end
    end)

    -- Disable BubbleChatConfiguration
    pcall(function()
        local bubbleChat = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
        if bubbleChat then
            bubbleChat.Enabled = false
        end
    end)

    -- Monitor for any future chat configuration changes
    TextChatService.ChildAdded:Connect(function(child)
        if child:IsA("ChatWindowConfiguration") or child:IsA("BubbleChatConfiguration") then
            pcall(function()
                child.Enabled = false
            end)
        end
    end)

    -- Watch for property changes on existing configs
    task.spawn(function()
        for _ = 1, 60 do
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

    print("[ArabCity] Default chat disabled (server)")
end

return DisableDefaultChat
