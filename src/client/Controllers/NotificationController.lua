--[[
    Arab City - Notification Controller
    Toast notifications for events, messages, achievements
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = Constants.COLORS

local NOTIFICATION_ICONS = {
    success = { icon = "✅", color = COLORS.Success },
    error = { icon = "❌", color = COLORS.Danger },
    info = { icon = "ℹ️", color = COLORS.Accent },
    friend = { icon = "👥", color = Color3.fromRGB(100, 200, 255) },
    challenge = { icon = "🎯", color = COLORS.Gold },
    levelUp = { icon = "⬆️", color = Color3.fromRGB(0, 255, 150) },
    trade = { icon = "🔄", color = Color3.fromRGB(200, 150, 255) },
    pet = { icon = "🐾", color = Color3.fromRGB(255, 180, 100) },
    achievement = { icon = "🏆", color = COLORS.Gold },
    welcome = { icon = "🎉", color = COLORS.Accent },
}

local NotificationController = {}
NotificationController._queue = {}
NotificationController._activeCount = 0
local MAX_VISIBLE = 4

function NotificationController:Init()
    self._gui = Instance.new("ScreenGui")
    self._gui.Name = "ArabCity_Notifications"
    self._gui.DisplayOrder = 150
    self._gui.IgnoreGuiInset = true
    self._gui.ResetOnSpawn = false
    self._gui.Parent = playerGui

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 320, 1, 0)
    container.Position = UDim2.new(1, -10, 0, 80)
    container.AnchorPoint = Vector2.new(1, 0)
    container.BackgroundTransparency = 1
    container.Parent = self._gui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = container

    self._container = container

    RemoteManager:OnClientEvent("ShowNotification", function(notifType, message)
        self:Show(notifType, message)
    end)
end

function NotificationController:Show(notifType: string, message: string, duration: number?)
    if self._activeCount >= MAX_VISIBLE then
        table.insert(self._queue, { notifType = notifType, message = message, duration = duration })
        return
    end

    self._activeCount = self._activeCount + 1
    local config = NOTIFICATION_ICONS[notifType] or NOTIFICATION_ICONS.info
    local displayDuration = duration or 4

    local card = Instance.new("Frame")
    card.Name = "Notif"
    card.Size = UDim2.new(1, 0, 0, 56)
    card.BackgroundColor3 = COLORS.Primary
    card.BorderSizePixel = 0
    card.LayoutOrder = os.clock() * 1000
    card.BackgroundTransparency = 1
    card.Parent = self._container

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = config.color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.4
    stroke.Parent = card

    -- Accent bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 0.7, 0)
    bar.Position = UDim2.new(0, 4, 0.5, 0)
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.BackgroundColor3 = config.color
    bar.BorderSizePixel = 0
    bar.Parent = card
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 14, 0.5, 0)
    iconLabel.AnchorPoint = Vector2.new(0, 0.5)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = config.icon
    iconLabel.TextSize = 20
    iconLabel.Parent = card

    -- Message
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -55, 1, -10)
    msgLabel.Position = UDim2.new(0, 48, 0, 5)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = COLORS.Text
    msgLabel.Font = Enum.Font.GothamMedium
    msgLabel.TextSize = 13
    msgLabel.TextWrapped = true
    msgLabel.TextXAlignment = Enum.TextXAlignment.Right
    msgLabel.Parent = card

    -- Slide in
    card.Position = UDim2.new(1, 50, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.05,
    }):Play()

    -- Auto dismiss
    task.delay(displayDuration, function()
        TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 50, 0, 0),
            BackgroundTransparency = 1,
        }):Play()
        task.delay(0.3, function()
            card:Destroy()
            self._activeCount = self._activeCount - 1
            self:_processQueue()
        end)
    end)
end

function NotificationController:_processQueue()
    if #self._queue > 0 and self._activeCount < MAX_VISIBLE then
        local next = table.remove(self._queue, 1)
        self:Show(next.notifType, next.message, next.duration)
    end
end

return NotificationController
