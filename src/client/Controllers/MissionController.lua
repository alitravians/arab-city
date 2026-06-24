--[[
    Arab City v2.0 - MissionController
    Missions / quests panel UI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MissionController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function MissionController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "MissionGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 68
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Toggle
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 46, 0, 46)
    toggleBtn.Position = UDim2.new(0, 235, 1, -60)
    toggleBtn.AnchorPoint = Vector2.new(0, 1)
    toggleBtn.BackgroundColor3 = colors.secondary
    toggleBtn.Text = "📋"
    toggleBtn.TextSize = 20
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = gui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 23)

    -- Panel
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 380, 0, 450)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = colors.background
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", panel).Color = colors.accent

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = colors.accent
    title.Text = "📋 المهمات"
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BorderSizePixel = 0
    title.Parent = panel
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Parent = panel

    self._scroll = Instance.new("ScrollingFrame")
    self._scroll.Size = UDim2.new(1, -20, 1, -55)
    self._scroll.Position = UDim2.new(0, 10, 0, 50)
    self._scroll.BackgroundTransparency = 1
    self._scroll.ScrollBarThickness = 4
    self._scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self._scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self._scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = self._scroll

    self._panel = panel

    Remotes:OnClientEvent("MissionsUpdate", function(data)
        self:_refresh(data)
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        _isOpen = not _isOpen
        panel.Visible = _isOpen
        if _isOpen then
            Remotes:FireServer("RequestMissions")
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)
end

function MissionController:_refresh(data)
    if type(data) ~= "table" then return end
    local colors = Constants.UI_COLORS

    for _, child in ipairs(self._scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local missions = data.missions or {}
    for i, m in ipairs(missions) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -5, 0, 60)
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = self._scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local mName = Instance.new("TextLabel")
        mName.Size = UDim2.new(0.7, 0, 0, 22)
        mName.Position = UDim2.new(0, 10, 0, 5)
        mName.BackgroundTransparency = 1
        mName.Text = m.name or "مهمة"
        mName.TextSize = 14
        mName.Font = Enum.Font.GothamBold
        mName.TextColor3 = colors.text
        mName.TextXAlignment = Enum.TextXAlignment.Left
        mName.Parent = row

        local mDesc = Instance.new("TextLabel")
        mDesc.Size = UDim2.new(0.7, 0, 0, 16)
        mDesc.Position = UDim2.new(0, 10, 0, 28)
        mDesc.BackgroundTransparency = 1
        mDesc.Text = m.description or ""
        mDesc.TextSize = 11
        mDesc.Font = Enum.Font.Gotham
        mDesc.TextColor3 = colors.textDim
        mDesc.TextXAlignment = Enum.TextXAlignment.Left
        mDesc.Parent = row

        local progress = Instance.new("TextLabel")
        progress.Size = UDim2.new(0, 80, 0, 20)
        progress.Position = UDim2.new(1, -90, 0, 5)
        progress.BackgroundTransparency = 1
        progress.Text = tostring(m.current or 0) .. "/" .. tostring(m.target or 1)
        progress.TextSize = 12
        progress.Font = Enum.Font.GothamBold
        progress.TextColor3 = if (m.current or 0) >= (m.target or 1) then colors.success else colors.textDim
        progress.TextXAlignment = Enum.TextXAlignment.Right
        progress.Parent = row

        local reward = Instance.new("TextLabel")
        reward.Size = UDim2.new(0, 80, 0, 16)
        reward.Position = UDim2.new(1, -90, 0, 30)
        reward.BackgroundTransparency = 1
        reward.Text = "$" .. tostring(m.reward or 0)
        reward.TextSize = 11
        reward.Font = Enum.Font.Gotham
        reward.TextColor3 = Color3.fromRGB(0, 255, 100)
        reward.TextXAlignment = Enum.TextXAlignment.Right
        reward.Parent = row
    end
end

return MissionController
