--[[
    Arab City v2.0 - ChatController
    Custom chat with toggle icon, public + private messages.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local ChatController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false
local _mode = "public"

function ChatController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    -- Kill default chat on client
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false) end)
    pcall(function() StarterGui:SetCore("ChatActive", false) end)
    pcall(function() StarterGui:SetCore("ChatBarDisabled", true) end)

    task.spawn(function()
        while true do
            pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false) end)
            task.wait(2)
        end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "ChatGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 50
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ChatToggle"
    toggleBtn.Size = UDim2.new(0, 46, 0, 46)
    toggleBtn.Position = UDim2.new(0, 15, 1, -60)
    toggleBtn.AnchorPoint = Vector2.new(0, 1)
    toggleBtn.BackgroundColor3 = colors.accent
    toggleBtn.Text = "💬"
    toggleBtn.TextSize = 22
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = gui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 23)

    -- Chat window
    local chatWindow = Instance.new("Frame")
    chatWindow.Name = "ChatWindow"
    chatWindow.Size = UDim2.new(0, 360, 0, 400)
    chatWindow.Position = UDim2.new(0, 15, 1, -115)
    chatWindow.AnchorPoint = Vector2.new(0, 1)
    chatWindow.BackgroundColor3 = colors.background
    chatWindow.BackgroundTransparency = 0.05
    chatWindow.BorderSizePixel = 0
    chatWindow.Visible = false
    chatWindow.Parent = gui
    Instance.new("UICorner", chatWindow).CornerRadius = UDim.new(0, 10)
    local windowStroke = Instance.new("UIStroke")
    windowStroke.Color = colors.accent
    windowStroke.Thickness = 1
    windowStroke.Parent = chatWindow

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = colors.card
    header.BorderSizePixel = 0
    header.Parent = chatWindow
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

    -- Tab: Public
    local publicTab = Instance.new("TextButton")
    publicTab.Size = UDim2.new(0.5, 0, 1, 0)
    publicTab.BackgroundColor3 = colors.accent
    publicTab.BackgroundTransparency = 0
    publicTab.Text = "عام"
    publicTab.TextSize = 14
    publicTab.Font = Enum.Font.GothamBold
    publicTab.TextColor3 = colors.text
    publicTab.BorderSizePixel = 0
    publicTab.Parent = header

    -- Tab: Private
    local privateTab = Instance.new("TextButton")
    privateTab.Size = UDim2.new(0.5, 0, 1, 0)
    privateTab.Position = UDim2.new(0.5, 0, 0, 0)
    privateTab.BackgroundColor3 = colors.card
    privateTab.BackgroundTransparency = 0
    privateTab.Text = "خاص"
    privateTab.TextSize = 14
    privateTab.Font = Enum.Font.GothamBold
    privateTab.TextColor3 = colors.textDim
    privateTab.BorderSizePixel = 0
    privateTab.Parent = header

    -- Messages scroll
    local msgScroll = Instance.new("ScrollingFrame")
    msgScroll.Name = "Messages"
    msgScroll.Size = UDim2.new(1, -10, 1, -90)
    msgScroll.Position = UDim2.new(0, 5, 0, 42)
    msgScroll.BackgroundTransparency = 1
    msgScroll.ScrollBarThickness = 4
    msgScroll.ScrollBarImageColor3 = colors.accent
    msgScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    msgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    msgScroll.Parent = chatWindow

    local msgLayout = Instance.new("UIListLayout")
    msgLayout.SortOrder = Enum.SortOrder.LayoutOrder
    msgLayout.Padding = UDim.new(0, 4)
    msgLayout.Parent = msgScroll

    -- Input bar
    local inputBar = Instance.new("Frame")
    inputBar.Size = UDim2.new(1, -10, 0, 40)
    inputBar.Position = UDim2.new(0, 5, 1, -45)
    inputBar.BackgroundColor3 = colors.card
    inputBar.BorderSizePixel = 0
    inputBar.Parent = chatWindow
    Instance.new("UICorner", inputBar).CornerRadius = UDim.new(0, 8)

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -55, 1, -6)
    textBox.Position = UDim2.new(0, 8, 0, 3)
    textBox.BackgroundTransparency = 1
    textBox.PlaceholderText = "اكتب رسالة..."
    textBox.Text = ""
    textBox.TextSize = 14
    textBox.Font = Enum.Font.Gotham
    textBox.TextColor3 = colors.text
    textBox.PlaceholderColor3 = colors.textDim
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputBar

    local sendBtn = Instance.new("TextButton")
    sendBtn.Size = UDim2.new(0, 40, 0, 30)
    sendBtn.Position = UDim2.new(1, -45, 0.5, -15)
    sendBtn.BackgroundColor3 = colors.accent
    sendBtn.Text = "→"
    sendBtn.TextSize = 18
    sendBtn.Font = Enum.Font.GothamBold
    sendBtn.TextColor3 = Color3.new(1, 1, 1)
    sendBtn.BorderSizePixel = 0
    sendBtn.Parent = inputBar
    Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 6)

    -- Store refs
    self._chatWindow = chatWindow
    self._msgScroll = msgScroll
    self._textBox = textBox
    self._publicTab = publicTab
    self._privateTab = privateTab
    self._msgOrder = 0

    -- Toggle
    toggleBtn.MouseButton1Click:Connect(function()
        _isOpen = not _isOpen
        chatWindow.Visible = _isOpen
    end)

    -- Tab switching
    publicTab.MouseButton1Click:Connect(function()
        _mode = "public"
        publicTab.BackgroundColor3 = colors.accent
        publicTab.TextColor3 = colors.text
        privateTab.BackgroundColor3 = colors.card
        privateTab.TextColor3 = colors.textDim
        textBox.PlaceholderText = "اكتب رسالة..."
    end)

    privateTab.MouseButton1Click:Connect(function()
        _mode = "private"
        publicTab.BackgroundColor3 = colors.card
        publicTab.TextColor3 = colors.textDim
        privateTab.BackgroundColor3 = colors.accent
        privateTab.TextColor3 = colors.text
        textBox.PlaceholderText = "اكتب: @اسم رسالتك"
    end)

    -- Send
    local function sendMessage()
        local text = textBox.Text
        if text == "" then return end
        textBox.Text = ""

        if _mode == "private" then
            local at, msg = string.match(text, "^@(%S+)%s(.+)")
            if at and msg then
                Remotes:FireServer("SendPrivateMessage", at, msg)
            end
        else
            Remotes:FireServer("SendChatMessage", text)
        end
    end

    sendBtn.MouseButton1Click:Connect(sendMessage)
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then sendMessage() end
    end)

    -- Receive public
    Remotes:OnClientEvent("ReceiveChatMessage", function(data)
        self:_addMessage(data)
    end)

    -- Receive private
    Remotes:OnClientEvent("ReceivePrivateMessage", function(data)
        if type(data) == "table" then
            data.type = "private"
            self:_addMessage(data)
        end
    end)
end

function ChatController:_addMessage(data)
    if type(data) ~= "table" then return end
    local colors = Constants.UI_COLORS

    self._msgOrder = self._msgOrder + 1

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -4, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = self._msgOrder
    frame.Parent = self._msgScroll

    local isPrivate = data.type == "private" or data.channel == "private"
    local prefix = if isPrivate then "[خاص] " else ""
    local nameColor = if isPrivate then Color3.fromRGB(255, 140, 200) else colors.accent

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = prefix .. (data.senderDisplayName or data.sender or "???")
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = nameColor
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = frame

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, 0, 0, 0)
    msgLabel.AutomaticSize = Enum.AutomaticSize.Y
    msgLabel.Position = UDim2.new(0, 0, 0, 16)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = data.message or ""
    msgLabel.TextSize = 13
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextColor3 = colors.text
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = frame

    task.defer(function()
        self._msgScroll.CanvasPosition = Vector2.new(0, self._msgScroll.AbsoluteCanvasSize.Y)
    end)
end

return ChatController
