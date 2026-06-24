--[[
    Arab City - Chat Controller
    Client-side chat UI with toggle icon button.
    Features: public chat, private messaging tabs, smooth open/close animation.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ChatController = {}
ChatController._isOpen = false
ChatController._activeTab = "public"
ChatController._privateTarget = nil
ChatController._messages = {}
ChatController._privateMessages = {}

local COLORS = Constants.COLORS
local ANIM_DURATION = 0.25

local CHAT_GUI_NAMES = {
    Chat = true,
    BubbleChat = true,
    ExperienceChat = true,
    RBXchatBubble = true,
}

local function isChatGui(inst)
    return inst:IsA("ScreenGui") and CHAT_GUI_NAMES[inst.Name]
end

local function nukeChatGui(gui)
    pcall(function()
        gui.Enabled = false
    end)
    pcall(function()
        gui:Destroy()
    end)
end

local function disableDefaultChat()
    -- 1. CoreGui chat toggle
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    end)

    -- 2. SetCore chat controls
    pcall(function()
        StarterGui:SetCore("ChatActive", false)
    end)
    pcall(function()
        StarterGui:SetCore("ChatBarDisabled", true)
    end)

    -- 3. TextChatService configurations
    pcall(function()
        local cw = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
        if cw then
            cw.Enabled = false
        end
    end)
    pcall(function()
        local bc = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
        if bc then
            bc.Enabled = false
        end
    end)

    -- 4. Destroy any default chat GUIs in PlayerGui
    pcall(function()
        for _, gui in ipairs(playerGui:GetChildren()) do
            if isChatGui(gui) then
                nukeChatGui(gui)
            end
        end
    end)

    -- 5. Try to reach CoreGui chat elements
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        for _, gui in ipairs(coreGui:GetChildren()) do
            if isChatGui(gui) then
                nukeChatGui(gui)
            end
        end
    end)

end

function ChatController:Init()
    -- Immediately disable CoreGui chat before anything else
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    end)

    -- Persistent background task: keeps disabling default chat aggressively
    task.spawn(function()
        local chatActiveOk = false
        local chatBarOk = false
        -- Phase 1: rapid-fire disabling (15 seconds)
        for _ = 1, 30 do
            if not chatActiveOk then
                chatActiveOk = pcall(function()
                    StarterGui:SetCore("ChatActive", false)
                end)
            end
            if not chatBarOk then
                chatBarOk = pcall(function()
                    StarterGui:SetCore("ChatBarDisabled", true)
                end)
            end
            disableDefaultChat()
            task.wait(0.5)
        end
        -- Phase 2: keep monitoring for 2 minutes (chat can load very late)
        for _ = 1, 60 do
            task.wait(2)
            disableDefaultChat()
        end
    end)

    -- Watch PlayerGui for any default chat GUIs being added
    playerGui.ChildAdded:Connect(function(child)
        if isChatGui(child) then
            task.defer(function()
                nukeChatGui(child)
            end)
        end
    end)

    -- Watch TextChatService for config children being re-enabled
    TextChatService.ChildAdded:Connect(function(child)
        if child:IsA("ChatWindowConfiguration") or child:IsA("BubbleChatConfiguration") then
            task.defer(function()
                pcall(function()
                    child.Enabled = false
                end)
            end)
        end
    end)

    -- Watch existing ChatWindowConfiguration for property changes
    task.spawn(function()
        local cw = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
        if cw then
            cw:GetPropertyChangedSignal("Enabled"):Connect(function()
                if cw.Enabled then
                    pcall(function()
                        cw.Enabled = false
                    end)
                end
            end)
        end
    end)

    self._gui = self:_buildUI()
    self._gui.Parent = playerGui

    -- Listen for public messages
    RemoteManager:OnClientEvent("ChatPublicMessage", function(entry)
        self:_addPublicMessage(entry)
    end)

    -- Listen for private messages
    RemoteManager:OnClientEvent("ChatPrivateMessage", function(entry)
        self:_addPrivateMessage(entry)
    end)

    -- Load history on join
    task.spawn(function()
        local history = RemoteManager:InvokeServer("GetChatHistory")
        if history then
            for _, entry in ipairs(history) do
                self:_addPublicMessage(entry)
            end
        end
    end)
end

function ChatController:Toggle()
    if self._isOpen then
        self:_close()
    else
        self:_open()
    end
end

function ChatController:_open()
    self._isOpen = true
    local panel = self._gui:FindFirstChild("ChatPanel")
    if not panel then return end

    panel.Visible = true
    local tween = TweenService:Create(panel, TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 12, 0.3, 0),
        GroupTransparency = 0,
    })
    tween:Play()

    -- Update icon appearance
    local icon = self._gui:FindFirstChild("ChatToggleBtn")
    if icon then
        icon.BackgroundColor3 = COLORS.Accent or Color3.fromRGB(0, 230, 255)
    end

    -- Focus input
    task.delay(ANIM_DURATION, function()
        local input = panel:FindFirstChild("InputBox", true)
        if input then
            input:CaptureFocus()
        end
    end)
end

function ChatController:_close()
    self._isOpen = false
    local panel = self._gui:FindFirstChild("ChatPanel")
    if not panel then return end

    local icon = self._gui:FindFirstChild("ChatToggleBtn")
    if icon then
        icon.BackgroundColor3 = COLORS.Primary or Color3.fromRGB(20, 25, 40)
    end

    local tween = TweenService:Create(panel, TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(-0.35, 0, 0.3, 0),
        GroupTransparency = 1,
    })
    tween:Play()
    tween.Completed:Wait()
    panel.Visible = false
end

function ChatController:_buildUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_Chat"
    gui.DisplayOrder = 25
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- ═══════════════════════════════════
    -- TOGGLE ICON (always visible)
    -- ═══════════════════════════════════
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ChatToggleBtn"
    toggleBtn.Size = UDim2.new(0, 44, 0, 44)
    toggleBtn.Position = UDim2.new(0, 12, 0.5, -22)
    toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
    toggleBtn.BackgroundColor3 = COLORS.Primary or Color3.fromRGB(20, 25, 40)
    toggleBtn.BackgroundTransparency = 0.1
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 30
    toggleBtn.Parent = gui

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 12)
    toggleCorner.Parent = toggleBtn

    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Color = COLORS.Accent or Color3.fromRGB(0, 230, 255)
    toggleStroke.Thickness = 1.5
    toggleStroke.Transparency = 0.3
    toggleStroke.Parent = toggleBtn

    -- Chat icon (speech bubble shape using text)
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "💬"
    iconLabel.TextSize = 22
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.ZIndex = 31
    iconLabel.Parent = toggleBtn

    -- Unread badge
    local badge = Instance.new("Frame")
    badge.Name = "UnreadBadge"
    badge.Size = UDim2.new(0, 14, 0, 14)
    badge.Position = UDim2.new(1, -8, 0, -4)
    badge.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    badge.Visible = false
    badge.ZIndex = 32
    badge.Parent = toggleBtn
    Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)

    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Text = "0"
    badgeText.TextSize = 9
    badgeText.Font = Enum.Font.GothamBold
    badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    badgeText.ZIndex = 33
    badgeText.Parent = badge
    self._badgeLabel = badgeText
    self._badge = badge
    self._unreadCount = 0

    toggleBtn.MouseButton1Click:Connect(function()
        self:Toggle()
        -- Reset unread when opening
        if self._isOpen then
            self._unreadCount = 0
            self._badge.Visible = false
        end
    end)

    -- ═══════════════════════════════════
    -- CHAT PANEL (hidden by default)
    -- ═══════════════════════════════════
    local panel = Instance.new("CanvasGroup")
    panel.Name = "ChatPanel"
    panel.Size = UDim2.new(0.3, 0, 0.4, 0)
    panel.Position = UDim2.new(-0.35, 0, 0.3, 0)
    panel.BackgroundColor3 = COLORS.Primary or Color3.fromRGB(20, 25, 40)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.GroupTransparency = 1
    panel.Visible = false
    panel.ZIndex = 25
    panel.Parent = gui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = COLORS.Accent or Color3.fromRGB(0, 230, 255)
    panelStroke.Thickness = 1
    panelStroke.Transparency = 0.5
    panelStroke.Parent = panel

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
    header.BackgroundTransparency = 0.3
    header.BorderSizePixel = 0
    header.ZIndex = 26
    header.Parent = panel
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

    local headerTitle = Instance.new("TextLabel")
    headerTitle.Size = UDim2.new(0.6, 0, 1, 0)
    headerTitle.Position = UDim2.new(0, 10, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "الدردشة"
    headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    headerTitle.TextSize = 14
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.ZIndex = 27
    headerTitle.Parent = header

    -- Tab buttons (public / private)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "Tabs"
    tabFrame.Size = UDim2.new(0.45, 0, 0, 28)
    tabFrame.Position = UDim2.new(0.53, 0, 0, 4)
    tabFrame.BackgroundTransparency = 1
    tabFrame.ZIndex = 27
    tabFrame.Parent = header

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = tabFrame

    local function makeTab(name, text)
        local tab = Instance.new("TextButton")
        tab.Name = name
        tab.Size = UDim2.new(0, 55, 1, 0)
        tab.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
        tab.BackgroundTransparency = 0.5
        tab.BorderSizePixel = 0
        tab.Text = text
        tab.TextSize = 11
        tab.Font = Enum.Font.GothamMedium
        tab.TextColor3 = Color3.fromRGB(200, 200, 200)
        tab.ZIndex = 28
        tab.Parent = tabFrame
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 6)
        return tab
    end

    local publicTab = makeTab("PublicTab", "عام")
    local privateTab = makeTab("PrivateTab", "خاص")

    publicTab.MouseButton1Click:Connect(function()
        self:_switchTab("public")
    end)
    privateTab.MouseButton1Click:Connect(function()
        self:_switchTab("private")
    end)
    self._publicTab = publicTab
    self._privateTab = privateTab

    -- Messages scroll area
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "Messages"
    scrollFrame.Size = UDim2.new(1, -16, 1, -82)
    scrollFrame.Position = UDim2.new(0, 8, 0, 38)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 3
    scrollFrame.ScrollBarImageColor3 = COLORS.Accent or Color3.fromRGB(0, 230, 255)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.ZIndex = 26
    scrollFrame.Parent = panel

    local msgLayout = Instance.new("UIListLayout")
    msgLayout.SortOrder = Enum.SortOrder.LayoutOrder
    msgLayout.Padding = UDim.new(0, 4)
    msgLayout.Parent = scrollFrame
    self._scrollFrame = scrollFrame

    -- Input area
    local inputFrame = Instance.new("Frame")
    inputFrame.Name = "InputFrame"
    inputFrame.Size = UDim2.new(1, -16, 0, 34)
    inputFrame.Position = UDim2.new(0, 8, 1, -40)
    inputFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
    inputFrame.BackgroundTransparency = 0.3
    inputFrame.BorderSizePixel = 0
    inputFrame.ZIndex = 26
    inputFrame.Parent = panel
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 8)

    local inputBox = Instance.new("TextBox")
    inputBox.Name = "InputBox"
    inputBox.Size = UDim2.new(1, -50, 1, -6)
    inputBox.Position = UDim2.new(0, 8, 0, 3)
    inputBox.BackgroundTransparency = 1
    inputBox.PlaceholderText = "اكتب رسالة..."
    inputBox.PlaceholderColor3 = Color3.fromRGB(120, 125, 140)
    inputBox.Text = ""
    inputBox.TextColor3 = Color3.fromRGB(240, 240, 240)
    inputBox.TextSize = 13
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.ZIndex = 27
    inputBox.Parent = inputFrame

    local sendBtn = Instance.new("TextButton")
    sendBtn.Name = "SendBtn"
    sendBtn.Size = UDim2.new(0, 34, 0, 28)
    sendBtn.Position = UDim2.new(1, -38, 0, 3)
    sendBtn.BackgroundColor3 = COLORS.Accent or Color3.fromRGB(0, 230, 255)
    sendBtn.BackgroundTransparency = 0.2
    sendBtn.BorderSizePixel = 0
    sendBtn.Text = "➤"
    sendBtn.TextSize = 16
    sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sendBtn.Font = Enum.Font.GothamBold
    sendBtn.ZIndex = 28
    sendBtn.Parent = inputFrame
    Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 6)

    -- Send message
    local function sendMessage()
        local text = inputBox.Text
        if #text == 0 then return end
        inputBox.Text = ""

        if self._activeTab == "public" then
            RemoteManager:FireServer("ChatSendPublic", text)
        elseif self._activeTab == "private" and self._privateTarget then
            RemoteManager:FireServer("ChatSendPrivate", self._privateTarget, text)
        end
    end

    sendBtn.MouseButton1Click:Connect(sendMessage)
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            sendMessage()
        end
    end)

    -- Close with Escape
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Escape and self._isOpen then
            self:_close()
        end
    end)

    self._publicTab.BackgroundTransparency = 0.1
    return gui
end

function ChatController:_switchTab(tab: string)
    self._activeTab = tab
    if tab == "public" then
        self._publicTab.BackgroundTransparency = 0.1
        self._privateTab.BackgroundTransparency = 0.5
        self:_renderPublicMessages()
    else
        self._publicTab.BackgroundTransparency = 0.5
        self._privateTab.BackgroundTransparency = 0.1
        self:_renderPrivateList()
    end
end

function ChatController:_addPublicMessage(entry)
    table.insert(self._messages, entry)
    if #self._messages > 50 then
        table.remove(self._messages, 1)
    end

    -- Show unread badge if closed
    if not self._isOpen then
        self._unreadCount += 1
        self._badge.Visible = true
        self._badgeLabel.Text = tostring(math.min(self._unreadCount, 99))
    end

    if self._activeTab == "public" and self._isOpen then
        self:_renderPublicMessages()
    end
end

function ChatController:_addPrivateMessage(entry)
    local key = tostring(math.min(entry.senderId, entry.targetId or player.UserId)) .. "_" .. tostring(math.max(entry.senderId, entry.targetId or player.UserId))
    if not self._privateMessages[key] then
        self._privateMessages[key] = {}
    end
    table.insert(self._privateMessages[key], entry)

    if not self._isOpen then
        self._unreadCount += 1
        self._badge.Visible = true
        self._badgeLabel.Text = tostring(math.min(self._unreadCount, 99))
    end
end

function ChatController:_renderPublicMessages()
    -- Clear existing
    for _, child in ipairs(self._scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for i, entry in ipairs(self._messages) do
        local msgFrame = Instance.new("Frame")
        msgFrame.Name = "Msg_" .. i
        msgFrame.Size = UDim2.new(1, -4, 0, 28)
        msgFrame.BackgroundTransparency = 1
        msgFrame.LayoutOrder = i
        msgFrame.ZIndex = 26
        msgFrame.Parent = self._scrollFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.3, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = entry.senderDisplay or entry.sender or "?"
        nameLabel.TextColor3 = entry.isAdmin and Color3.fromRGB(255, 80, 80) or (COLORS.Accent or Color3.fromRGB(0, 230, 255))
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.ZIndex = 27
        nameLabel.Parent = msgFrame

        local msgLabel = Instance.new("TextLabel")
        msgLabel.Size = UDim2.new(0.68, 0, 1, 0)
        msgLabel.Position = UDim2.new(0.32, 0, 0, 0)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = entry.message or ""
        msgLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
        msgLabel.TextSize = 12
        msgLabel.Font = Enum.Font.Gotham
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
        msgLabel.TextWrapped = true
        msgLabel.ZIndex = 27
        msgLabel.Parent = msgFrame
    end

    -- Scroll to bottom
    task.defer(function()
        self._scrollFrame.CanvasPosition = Vector2.new(0, self._scrollFrame.AbsoluteCanvasSize.Y)
    end)
end

function ChatController:_renderPrivateList()
    for _, child in ipairs(self._scrollFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Show online players list
    task.spawn(function()
        local playersList = RemoteManager:InvokeServer("GetOnlinePlayers")
        if not playersList then return end

        for i, pInfo in ipairs(playersList) do
            local btn = Instance.new("TextButton")
            btn.Name = "Player_" .. pInfo.userId
            btn.Size = UDim2.new(1, -4, 0, 32)
            btn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            btn.BackgroundTransparency = 0.4
            btn.BorderSizePixel = 0
            btn.Text = "  " .. pInfo.displayName .. " (@" .. pInfo.name .. ")"
            btn.TextSize = 12
            btn.Font = Enum.Font.Gotham
            btn.TextColor3 = Color3.fromRGB(220, 220, 225)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = i
            btn.ZIndex = 27
            btn.Parent = self._scrollFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            btn.MouseButton1Click:Connect(function()
                self._privateTarget = pInfo.userId
                self._activeTab = "private_chat"
                self:_renderPrivateChat(pInfo.userId, pInfo.displayName)
            end)
        end
    end)
end

function ChatController:_renderPrivateChat(targetId: number, targetName: string)
    for _, child in ipairs(self._scrollFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Back button
    local backBtn = Instance.new("TextButton")
    backBtn.Size = UDim2.new(0.3, 0, 0, 24)
    backBtn.BackgroundColor3 = Color3.fromRGB(60, 65, 80)
    backBtn.BackgroundTransparency = 0.3
    backBtn.BorderSizePixel = 0
    backBtn.Text = "← رجوع"
    backBtn.TextSize = 11
    backBtn.Font = Enum.Font.GothamMedium
    backBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    backBtn.LayoutOrder = 0
    backBtn.ZIndex = 27
    backBtn.Parent = self._scrollFrame
    Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 6)

    backBtn.MouseButton1Click:Connect(function()
        self._privateTarget = nil
        self:_renderPrivateList()
    end)

    -- Load private history
    task.spawn(function()
        local history = RemoteManager:InvokeServer("GetPrivateChat", targetId)
        if history then
            for i, entry in ipairs(history) do
                local msgFrame = Instance.new("Frame")
                msgFrame.Size = UDim2.new(1, -4, 0, 28)
                msgFrame.BackgroundTransparency = 1
                msgFrame.LayoutOrder = i
                msgFrame.ZIndex = 26
                msgFrame.Parent = self._scrollFrame

                local isMine = entry.senderId == player.UserId
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.25, 0, 1, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = isMine and "أنت" or targetName
                nameLabel.TextColor3 = isMine and Color3.fromRGB(100, 200, 100) or (COLORS.Accent or Color3.fromRGB(0, 230, 255))
                nameLabel.TextSize = 11
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.ZIndex = 27
                nameLabel.Parent = msgFrame

                local msgLabel = Instance.new("TextLabel")
                msgLabel.Size = UDim2.new(0.73, 0, 1, 0)
                msgLabel.Position = UDim2.new(0.27, 0, 0, 0)
                msgLabel.BackgroundTransparency = 1
                msgLabel.Text = entry.message or ""
                msgLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
                msgLabel.TextSize = 12
                msgLabel.Font = Enum.Font.Gotham
                msgLabel.TextXAlignment = Enum.TextXAlignment.Left
                msgLabel.TextWrapped = true
                msgLabel.ZIndex = 27
                msgLabel.Parent = msgFrame
            end
        end
    end)
end

return ChatController
