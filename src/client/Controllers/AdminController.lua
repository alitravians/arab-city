--[[
    Arab City v2.0 - AdminController
    Admin panel UI — only visible to admins.
    Features: give money, kick, ban (temp/perm), unban, promote job, promote/remove admin.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AdminController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function AdminController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants

    Remotes:OnClientEvent("AdminPanelAccess", function(data)
        if data and data.isAdmin then
            self:_build()
        end
    end)
end

function AdminController:_build()
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "AdminGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 90
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Admin toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 46, 0, 46)
    toggleBtn.Position = UDim2.new(1, -60, 1, -60)
    toggleBtn.AnchorPoint = Vector2.new(1, 1)
    toggleBtn.BackgroundColor3 = colors.danger
    toggleBtn.Text = "⚙️"
    toggleBtn.TextSize = 20
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = gui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 23)

    -- Panel
    local panel = Instance.new("Frame")
    panel.Name = "AdminPanel"
    panel.Size = UDim2.new(0, 400, 0, 500)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = colors.background
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local pStroke = Instance.new("UIStroke")
    pStroke.Color = colors.danger
    pStroke.Thickness = 2
    pStroke.Parent = panel

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.BackgroundColor3 = colors.danger
    title.Text = "⚙️ لوحة تحكم الأدمن"
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BorderSizePixel = 0
    title.Parent = panel
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Parent = panel

    -- Scroll area
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -55)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    -- Player name input
    local playerInput = self:_makeInput(scroll, "اسم اللاعب", 1)

    -- Amount input
    local amountInput = self:_makeInput(scroll, "المبلغ", 2)

    -- Action buttons
    local actions = {
        { text = "💰 إعطاء نقود", order = 3, action = "giveMoney" },
        { text = "🚪 طرد لاعب", order = 4, action = "kickPlayer" },
        { text = "⏱️ حظر مؤقت 15 دقيقة", order = 5, action = "banTemp15m" },
        { text = "⏱️ حظر مؤقت ساعة", order = 6, action = "banTemp1h" },
        { text = "⏱️ حظر مؤقت 24 ساعة", order = 7, action = "banTemp24h" },
        { text = "🚫 حظر دائم", order = 8, action = "banPerm" },
        { text = "✅ رفع الحظر", order = 9, action = "unban" },
        { text = "💼 ترقية وظيفة", order = 10, action = "promoteJob" },
        { text = "⭐ ترقية لأدمن", order = 11, action = "promoteAdmin" },
        { text = "❌ إزالة أدمن", order = 12, action = "removeAdmin" },
    }

    for _, a in ipairs(actions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 38)
        btn.BackgroundColor3 = colors.card
        btn.Text = a.text
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = colors.text
        btn.BorderSizePixel = 0
        btn.LayoutOrder = a.order
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            local targetName = playerInput.Text
            local amount = tonumber(amountInput.Text) or 0
            Remotes:FireServer("AdminAction", {
                action = a.action,
                targetName = targetName,
                amount = amount,
            })
        end)
    end

    -- Status label
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -10, 0, 30)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.TextColor3 = colors.success
    status.LayoutOrder = 20
    status.Parent = scroll
    self._statusLabel = status

    Remotes:OnClientEvent("AdminResult", function(data)
        if type(data) == "table" then
            status.Text = data.message or ""
            status.TextColor3 = if data.success then colors.success else colors.danger
        end
    end)

    -- Toggle
    toggleBtn.MouseButton1Click:Connect(function()
        _isOpen = not _isOpen
        panel.Visible = _isOpen
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)
end

function AdminController:_makeInput(parent, placeholder, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 36)
    frame.BackgroundColor3 = Shared.Constants.UI_COLORS.card
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -10, 1, 0)
    box.Position = UDim2.new(0, 5, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextSize = 14
    box.Font = Enum.Font.Gotham
    box.TextColor3 = Shared.Constants.UI_COLORS.text
    box.PlaceholderColor3 = Shared.Constants.UI_COLORS.textDim
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = frame

    return box
end

return AdminController
