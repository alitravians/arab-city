--[[
    Arab City v2.0 - AdminController
    Professional admin panel with PIN access (3131).
    Features: give money, kick, ban temp/perm, unban, mute/unmute from chat.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false
local _authenticated = false

function AdminController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "AdminGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 90
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Admin toggle (subtle gear icon, bottom-right)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 36, 0, 36)
    toggleBtn.Position = UDim2.new(1, -50, 1, -50)
    toggleBtn.AnchorPoint = Vector2.new(1, 1)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    toggleBtn.BackgroundTransparency = 0.5
    toggleBtn.Text = "⚙"
    toggleBtn.TextSize = 16
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = gui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 18)

    -- Main panel
    local panel = Instance.new("Frame")
    panel.Name = "AdminPanel"
    panel.Size = UDim2.new(0, 420, 0, 520)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = colors.background
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
    local pStroke = Instance.new("UIStroke")
    pStroke.Color = colors.danger
    pStroke.Thickness = 2
    pStroke.Parent = panel

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = panel
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 14, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "لوحة تحكم الأدمن"
    titleLabel.TextSize = 17
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0, 8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Parent = titleBar

    -- ── PIN Screen ──
    local pinScreen = Instance.new("Frame")
    pinScreen.Name = "PinScreen"
    pinScreen.Size = UDim2.new(1, -20, 1, -58)
    pinScreen.Position = UDim2.new(0, 10, 0, 52)
    pinScreen.BackgroundTransparency = 1
    pinScreen.Parent = panel

    local pinTitle = Instance.new("TextLabel")
    pinTitle.Size = UDim2.new(1, 0, 0, 40)
    pinTitle.Position = UDim2.new(0, 0, 0, 60)
    pinTitle.BackgroundTransparency = 1
    pinTitle.Text = "🔒 أدخل رمز الدخول"
    pinTitle.TextSize = 16
    pinTitle.Font = Enum.Font.GothamBold
    pinTitle.TextColor3 = colors.textDim
    pinTitle.Parent = pinScreen

    local pinInputBg = Instance.new("Frame")
    pinInputBg.Size = UDim2.new(0, 200, 0, 50)
    pinInputBg.Position = UDim2.new(0.5, -100, 0, 120)
    pinInputBg.BackgroundColor3 = colors.card
    pinInputBg.BorderSizePixel = 0
    pinInputBg.Parent = pinScreen
    Instance.new("UICorner", pinInputBg).CornerRadius = UDim.new(0, 10)

    local pinBox = Instance.new("TextBox")
    pinBox.Size = UDim2.new(1, -16, 1, 0)
    pinBox.Position = UDim2.new(0, 8, 0, 0)
    pinBox.BackgroundTransparency = 1
    pinBox.PlaceholderText = "****"
    pinBox.Text = ""
    pinBox.TextSize = 24
    pinBox.Font = Enum.Font.GothamBold
    pinBox.TextColor3 = colors.text
    pinBox.PlaceholderColor3 = colors.textDim
    pinBox.ClearTextOnFocus = true
    pinBox.Parent = pinInputBg

    local pinBtn = Instance.new("TextButton")
    pinBtn.Size = UDim2.new(0, 200, 0, 44)
    pinBtn.Position = UDim2.new(0.5, -100, 0, 190)
    pinBtn.BackgroundColor3 = colors.danger
    pinBtn.Text = "دخول"
    pinBtn.TextSize = 16
    pinBtn.Font = Enum.Font.GothamBold
    pinBtn.TextColor3 = Color3.new(1, 1, 1)
    pinBtn.BorderSizePixel = 0
    pinBtn.Parent = pinScreen
    Instance.new("UICorner", pinBtn).CornerRadius = UDim.new(0, 10)

    local pinError = Instance.new("TextLabel")
    pinError.Size = UDim2.new(1, 0, 0, 24)
    pinError.Position = UDim2.new(0, 0, 0, 245)
    pinError.BackgroundTransparency = 1
    pinError.Text = ""
    pinError.TextSize = 13
    pinError.Font = Enum.Font.Gotham
    pinError.TextColor3 = colors.danger
    pinError.Parent = pinScreen

    -- ── Admin Content ──
    local adminContent = Instance.new("Frame")
    adminContent.Name = "AdminContent"
    adminContent.Size = UDim2.new(1, -20, 1, -58)
    adminContent.Position = UDim2.new(0, 10, 0, 52)
    adminContent.BackgroundTransparency = 1
    adminContent.Visible = false
    adminContent.Parent = panel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = adminContent

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    -- Player name input
    local playerInput = self:_makeInput(scroll, "اسم اللاعب", 1, colors)
    -- Amount input
    local amountInput = self:_makeInput(scroll, "المبلغ", 2, colors)

    -- Section: Money
    self:_makeSectionLabel(scroll, "💰 النقود", 3, colors)

    local moneyActions = {
        { text = "💰 إعطاء نقود للاعب", order = 4, action = "giveMoney" },
        { text = "💰 إعطاء نقود لنفسي", order = 5, action = "giveMoneyToSelf" },
    }
    for _, a in ipairs(moneyActions) do
        self:_makeActionButton(scroll, a, playerInput, amountInput, colors)
    end

    -- Section: Moderation
    self:_makeSectionLabel(scroll, "🛡️ الإدارة", 6, colors)

    local modActions = {
        { text = "🚪 طرد لاعب", order = 7, action = "kickPlayer" },
        { text = "🔇 كتم لاعب من الدردشة", order = 8, action = "mutePlayer" },
        { text = "🔊 إلغاء كتم لاعب", order = 9, action = "unmutePlayer" },
    }
    for _, a in ipairs(modActions) do
        self:_makeActionButton(scroll, a, playerInput, amountInput, colors)
    end

    -- Section: Banning
    self:_makeSectionLabel(scroll, "🚫 الحظر", 10, colors)

    local banActions = {
        { text = "⏱️ حظر 15 دقيقة", order = 11, action = "banPlayer", duration = 900 },
        { text = "⏱️ حظر ساعة", order = 12, action = "banPlayer", duration = 3600 },
        { text = "⏱️ حظر 24 ساعة", order = 13, action = "banPlayer", duration = 86400 },
        { text = "🚫 حظر دائم", order = 14, action = "banPlayer", duration = -1 },
        { text = "✅ رفع الحظر (اكتب UserId)", order = 15, action = "unbanPlayer" },
    }
    for _, a in ipairs(banActions) do
        self:_makeActionButton(scroll, a, playerInput, amountInput, colors)
    end

    -- Section: Admin management
    self:_makeSectionLabel(scroll, "⭐ صلاحيات", 16, colors)

    local adminActions = {
        { text = "⭐ ترقية لأدمن", order = 17, action = "promoteAdmin" },
        { text = "❌ إزالة أدمن", order = 18, action = "removeAdmin" },
    }
    for _, a in ipairs(adminActions) do
        self:_makeActionButton(scroll, a, playerInput, amountInput, colors)
    end

    -- Status label
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -4, 0, 30)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextSize = 12
    status.Font = Enum.Font.GothamBold
    status.TextColor3 = colors.success
    status.LayoutOrder = 30
    status.TextWrapped = true
    status.Parent = scroll

    -- Store refs
    self._panel = panel
    self._pinScreen = pinScreen
    self._adminContent = adminContent
    self._statusLabel = status

    -- ── Event handlers ──

    toggleBtn.MouseButton1Click:Connect(function()
        _isOpen = not _isOpen
        panel.Visible = _isOpen
        if _isOpen and not _authenticated then
            pinScreen.Visible = true
            adminContent.Visible = false
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)

    -- PIN verification (client-side check + server verification)
    local function tryLogin()
        local pin = pinBox.Text
        if pin == "3131" then
            _authenticated = true
            pinScreen.Visible = false
            adminContent.Visible = true
            pinError.Text = ""
            Remotes:FireServer("AdminLogin", pin)
        else
            pinError.Text = "رمز الدخول غير صحيح"
            pinBox.Text = ""
        end
    end

    pinBtn.MouseButton1Click:Connect(tryLogin)
    pinBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then tryLogin() end
    end)

    -- Server responses
    Remotes:OnClientEvent("AdminResult", function(data)
        if type(data) == "table" then
            status.Text = data.message or ""
            status.TextColor3 = if data.success then colors.success else colors.danger
        end
    end)

    Remotes:OnClientEvent("AdminResponse", function(data)
        if type(data) == "table" then
            status.Text = data.message or ""
            status.TextColor3 = if data.success then colors.success else colors.danger
        end
    end)
end

function AdminController:_makeSectionLabel(parent, text, order, colors)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, 28)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = colors.warning
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = order
    label.Parent = parent
end

function AdminController:_makeInput(parent, placeholder, order, colors)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -4, 0, 38)
    frame.BackgroundColor3 = colors.card
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -12, 1, 0)
    box.Position = UDim2.new(0, 6, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextSize = 14
    box.Font = Enum.Font.Gotham
    box.TextColor3 = colors.text
    box.PlaceholderColor3 = colors.textDim
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = frame

    return box
end

function AdminController:_makeActionButton(parent, actionData, playerInput, amountInput, colors)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 36)
    btn.BackgroundColor3 = colors.card
    btn.Text = actionData.text
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = colors.text
    btn.BorderSizePixel = 0
    btn.LayoutOrder = actionData.order
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        local targetName = playerInput.Text
        local amount = tonumber(amountInput.Text) or 0

        if actionData.action == "giveMoneyToSelf" then
            Remotes:FireServer("AdminAction", "giveMoney", {
                playerName = player.Name,
                amount = amount,
            })
        elseif actionData.action == "unbanPlayer" then
            local userId = tonumber(playerInput.Text)
            Remotes:FireServer("AdminAction", "unbanPlayer", {
                userId = userId,
            })
        elseif actionData.action == "banPlayer" then
            Remotes:FireServer("AdminAction", "banPlayer", {
                playerName = targetName,
                duration = actionData.duration,
                reason = "حظر من الأدمن",
            })
        else
            Remotes:FireServer("AdminAction", actionData.action, {
                playerName = targetName,
                amount = amount,
            })
        end
    end)
end

return AdminController
