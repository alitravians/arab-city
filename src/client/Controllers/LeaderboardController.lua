--[[
    Arab City - Leaderboard Controller
    Shows top players by cash, fame, level, jobs
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager
local Utils = Shared.Utils

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = Constants.COLORS

local LeaderboardController = {}
LeaderboardController._isOpen = false
LeaderboardController._currentCategory = "richest"

function LeaderboardController:Init()
    self._gui = self:_buildUI()
    self._gui.Enabled = false
    self._gui.Parent = playerGui
end

function LeaderboardController:Toggle()
    if self._isOpen then self:Close() else self:Open() end
end

function LeaderboardController:Open()
    if self._isOpen then return end
    self._isOpen = true
    self._gui.Enabled = true
    self:_refreshData()
    TweenService:Create(self._mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
    }):Play()
end

function LeaderboardController:Close()
    if not self._isOpen then return end
    self._isOpen = false
    TweenService:Create(self._mainFrame, TweenInfo.new(0.2), {
        BackgroundTransparency = 1,
    }):Play()
    task.delay(0.2, function()
        if not self._isOpen then self._gui.Enabled = false end
    end)
end

function LeaderboardController:_buildUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_Leaderboard"
    gui.DisplayOrder = 85
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 380, 0, 500)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = COLORS.Primary
    main.BorderSizePixel = 0
    main.Parent = gui
    self._mainFrame = main

    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Gold
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = main

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 0, 40)
    title.Position = UDim2.new(0, 15, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🏆 لوحة المتصدرين"
    title.TextColor3 = COLORS.Gold
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = COLORS.TextDim
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = main
    closeBtn.MouseButton1Click:Connect(function() self:Close() end)

    -- Category tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 36)
    tabBar.Position = UDim2.new(0.5, 0, 0, 48)
    tabBar.AnchorPoint = Vector2.new(0.5, 0)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabBar

    self._tabs = {}
    for i, cat in ipairs(Constants.LEADERBOARD_CATEGORIES) do
        local tab = Instance.new("TextButton")
        tab.Name = "Tab_" .. cat.id
        tab.Size = UDim2.new(0, 82, 1, 0)
        tab.BackgroundColor3 = i == 1 and COLORS.Gold or COLORS.CardBg
        tab.BackgroundTransparency = i == 1 and 0.2 or 0.6
        tab.BorderSizePixel = 0
        tab.Text = cat.icon .. " " .. cat.nameAr
        tab.TextColor3 = COLORS.Text
        tab.Font = Enum.Font.GothamBold
        tab.TextSize = 11
        tab.LayoutOrder = i
        tab.Parent = tabBar
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 8)

        self._tabs[cat.id] = tab
        tab.MouseButton1Click:Connect(function()
            self._currentCategory = cat.id
            for cid, t in pairs(self._tabs) do
                t.BackgroundColor3 = cid == cat.id and COLORS.Gold or COLORS.CardBg
                t.BackgroundTransparency = cid == cat.id and 0.2 or 0.6
            end
            self:_refreshData()
        end)
    end

    -- Entries scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Entries"
    scroll.Size = UDim2.new(1, -20, 1, -100)
    scroll.Position = UDim2.new(0.5, 0, 0, 92)
    scroll.AnchorPoint = Vector2.new(0.5, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = COLORS.Gold
    scroll.Parent = main
    self._scroll = scroll

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scroll

    return gui
end

function LeaderboardController:_refreshData()
    -- Clear old entries
    for _, child in ipairs(self._scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local data = RemoteManager:InvokeServer("GetLeaderboardData", self._currentCategory)
    if not data then return end

    local cat = nil
    for _, c in ipairs(Constants.LEADERBOARD_CATEGORIES) do
        if c.id == self._currentCategory then cat = c break end
    end

    for _, entry in ipairs(data) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundColor3 = entry.rank <= 3 and COLORS.Secondary or COLORS.CardBg
        row.BackgroundTransparency = 0.3
        row.BorderSizePixel = 0
        row.LayoutOrder = entry.rank
        row.Parent = self._scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        -- Rank medal
        local rankColors = { [1] = COLORS.Gold, [2] = Color3.fromRGB(192, 192, 192), [3] = Color3.fromRGB(205, 127, 50) }
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0, 36, 1, 0)
        rankLabel.Position = UDim2.new(0, 6, 0, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = entry.rank <= 3 and ({"🥇","🥈","🥉"})[entry.rank] or ("#" .. entry.rank)
        rankLabel.TextColor3 = rankColors[entry.rank] or COLORS.TextDim
        rankLabel.Font = Enum.Font.GothamBold
        rankLabel.TextSize = entry.rank <= 3 and 20 or 14
        rankLabel.Parent = row

        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, -50, 1, 0)
        nameLabel.Position = UDim2.new(0, 44, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = entry.name
        nameLabel.TextColor3 = COLORS.Text
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row

        -- Value
        local valLabel = Instance.new("TextLabel")
        valLabel.Size = UDim2.new(0.35, 0, 1, 0)
        valLabel.Position = UDim2.new(0.65, 0, 0, 0)
        valLabel.BackgroundTransparency = 1
        valLabel.Text = (cat and cat.icon or "") .. " " .. Utils.formatNumber(entry.value)
        valLabel.TextColor3 = COLORS.Gold
        valLabel.Font = Enum.Font.GothamBold
        valLabel.TextSize = 14
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.Parent = row
    end

    -- Update canvas size
    self._scroll.CanvasSize = UDim2.new(0, 0, 0, #data * 50 + 10)
end

return LeaderboardController
