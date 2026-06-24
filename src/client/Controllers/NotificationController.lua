--[[
    Arab City v2.0 - NotificationController
    Toast-style notifications with auto-dismiss.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NotificationController = {}

local Shared, Remotes, Utils
local player = Players.LocalPlayer
local _queue = {}
local _active = 0
local MAX_VISIBLE = 3

function NotificationController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Utils = Shared.Utils

    self._gui = Instance.new("ScreenGui")
    self._gui.Name = "NotificationGui"
    self._gui.ResetOnSpawn = false
    self._gui.DisplayOrder = 100
    self._gui.Parent = player:WaitForChild("PlayerGui")

    self._container = Instance.new("Frame")
    self._container.Name = "Container"
    self._container.Size = UDim2.new(0, 320, 1, 0)
    self._container.Position = UDim2.new(1, -330, 0, 10)
    self._container.BackgroundTransparency = 1
    self._container.Parent = self._gui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = self._container

    Remotes:OnClientEvent("ShowNotification", function(data)
        self:_show(data)
    end)
end

function NotificationController:_show(data)
    if type(data) ~= "table" then return end

    local title = data.title or ""
    local message = data.message or ""
    local icon = data.icon or ""
    local duration = data.duration or 4
    local colors = Shared.Constants.UI_COLORS

    local card = Instance.new("Frame")
    card.Name = "Notification"
    card.Size = UDim2.new(1, 0, 0, 70)
    card.BackgroundColor3 = colors.card
    card.BorderSizePixel = 0
    card.BackgroundTransparency = 1
    card.Parent = self._container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = colors.accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = card

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 40, 0, 40)
    iconLabel.Position = UDim2.new(0, 10, 0.5, -20)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 24
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextColor3 = Color3.new(1, 1, 1)
    iconLabel.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -65, 0, 22)
    titleLabel.Position = UDim2.new(0, 55, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = colors.text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = card

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -65, 0, 28)
    msgLabel.Position = UDim2.new(0, 55, 0, 34)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextSize = 13
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextColor3 = colors.textDim
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
    msgLabel.Parent = card

    -- Slide in
    local tweenIn = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
    })
    tweenIn:Play()

    -- Auto dismiss
    task.delay(duration, function()
        if card and card.Parent then
            local tweenOut = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
            })
            tweenOut:Play()
            tweenOut.Completed:Wait()
            if card and card.Parent then card:Destroy() end
        end
    end)
end

return NotificationController
