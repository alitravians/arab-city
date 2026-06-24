--[[
    Arab City v2.0 - FriendController
    Friend list UI: add/remove friends, online status.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FriendController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function FriendController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "FriendGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 56
    gui.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 300, 0, 400)
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
    title.BackgroundColor3 = colors.card
    title.Text = "👥 الأصدقاء"
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = colors.text
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
    closeBtn.TextColor3 = colors.text
    closeBtn.Parent = panel

    self._scroll = Instance.new("ScrollingFrame")
    self._scroll.Size = UDim2.new(1, -20, 1, -55)
    self._scroll.Position = UDim2.new(0, 10, 0, 48)
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

    Remotes:OnClientEvent("FriendListUpdate", function(data)
        self:_refresh(data)
    end)

    Remotes:OnClientEvent("OpenFriends", function()
        _isOpen = true
        panel.Visible = true
        Remotes:FireServer("RequestFriendList")
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)
end

function FriendController:_refresh(data)
    if type(data) ~= "table" then return end
    local colors = Constants.UI_COLORS

    for _, child in ipairs(self._scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local friends = data.friends or {}
    for i, f in ipairs(friends) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -5, 0, 40)
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = self._scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local status = Instance.new("Frame")
        status.Size = UDim2.new(0, 10, 0, 10)
        status.Position = UDim2.new(0, 10, 0.5, -5)
        status.BackgroundColor3 = if f.online then colors.success else Color3.fromRGB(120, 120, 120)
        status.BorderSizePixel = 0
        status.Parent = row
        Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -60, 1, 0)
        name.Position = UDim2.new(0, 28, 0, 0)
        name.BackgroundTransparency = 1
        name.Text = f.name or "???"
        name.TextSize = 14
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = colors.text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row
    end
end

return FriendController
