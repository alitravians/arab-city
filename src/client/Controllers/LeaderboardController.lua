--[[
    Arab City v2.0 - LeaderboardController
    Top-10 leaderboards: cash, fame, level.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function LeaderboardController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "LeaderboardGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 58
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Toggle
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 46, 0, 46)
    toggleBtn.Position = UDim2.new(1, -60, 0, 60)
    toggleBtn.AnchorPoint = Vector2.new(1, 0)
    toggleBtn.BackgroundColor3 = colors.secondary
    toggleBtn.Text = "🏆"
    toggleBtn.TextSize = 20
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = gui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 23)

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 320, 0, 400)
    panel.Position = UDim2.new(1, -70, 0, 115)
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.BackgroundColor3 = colors.background
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", panel).Color = colors.accent

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = colors.accent
    title.Text = "🏆 المتصدرين"
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BorderSizePixel = 0
    title.Parent = panel
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    -- Tabs
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -10, 0, 30)
    tabFrame.Position = UDim2.new(0, 5, 0, 45)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = panel

    local tabs = { "💰 نقود", "⭐ شهرة", "📈 مستوى" }
    local tabButtons = {}
    for i, t in ipairs(tabs) do
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.new(1 / #tabs, -4, 1, 0)
        tb.Position = UDim2.new((i - 1) / #tabs, 2, 0, 0)
        tb.BackgroundColor3 = if i == 1 then colors.accent else colors.card
        tb.Text = t
        tb.TextSize = 11
        tb.Font = Enum.Font.GothamBold
        tb.TextColor3 = colors.text
        tb.BorderSizePixel = 0
        tb.Parent = tabFrame
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
        tabButtons[i] = tb
    end

    self._scroll = Instance.new("ScrollingFrame")
    self._scroll.Size = UDim2.new(1, -20, 1, -90)
    self._scroll.Position = UDim2.new(0, 10, 0, 82)
    self._scroll.BackgroundTransparency = 1
    self._scroll.ScrollBarThickness = 4
    self._scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self._scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self._scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = self._scroll

    self._panel = panel
    self._currentTab = "cash"
    self._data = {}

    local tabKeys = { "cash", "fame", "level" }
    for i, btn in ipairs(tabButtons) do
        btn.MouseButton1Click:Connect(function()
            self._currentTab = tabKeys[i]
            for j, b in ipairs(tabButtons) do
                b.BackgroundColor3 = if j == i then colors.accent else colors.card
            end
            self:_render()
        end)
    end

    Remotes:OnClientEvent("LeaderboardData", function(data)
        if type(data) == "table" then
            self._data = data
            self:_render()
        end
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        _isOpen = not _isOpen
        panel.Visible = _isOpen
    end)
end

function LeaderboardController:_render()
    local colors = Constants.UI_COLORS

    for _, child in ipairs(self._scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local list = self._data[self._currentTab] or {}
    local medals = { "🥇", "🥈", "🥉" }
    for i, entry in ipairs(list) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -5, 0, 34)
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = self._scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local rank = Instance.new("TextLabel")
        rank.Size = UDim2.new(0, 30, 1, 0)
        rank.Position = UDim2.new(0, 5, 0, 0)
        rank.BackgroundTransparency = 1
        rank.Text = medals[i] or tostring(i)
        rank.TextSize = 14
        rank.Font = Enum.Font.GothamBold
        rank.TextColor3 = colors.accent
        rank.Parent = row

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.5, 0, 1, 0)
        name.Position = UDim2.new(0, 38, 0, 0)
        name.BackgroundTransparency = 1
        name.Text = entry.name or "???"
        name.TextSize = 13
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = colors.text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 80, 1, 0)
        val.Position = UDim2.new(1, -85, 0, 0)
        val.BackgroundTransparency = 1
        val.Text = tostring(entry.value or 0)
        val.TextSize = 13
        val.Font = Enum.Font.GothamBold
        val.TextColor3 = Color3.fromRGB(0, 255, 100)
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = row
    end
end

return LeaderboardController
