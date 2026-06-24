--[[
    Arab City v2.0 - DailyChallengeController
    Daily/weekly challenge UI with claim buttons.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DailyChallengeController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function DailyChallengeController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "DailyChallengeGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 59
    gui.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 380, 0, 420)
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
    title.Text = "📅 التحديات اليومية"
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

    Remotes:OnClientEvent("DailyChallenges", function(data)
        self:_refresh(data)
    end)

    Remotes:OnClientEvent("OpenDailyChallenges", function()
        _isOpen = true
        panel.Visible = true
        Remotes:FireServer("RequestDailyChallenges")
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)
end

function DailyChallengeController:_refresh(data)
    if type(data) ~= "table" then return end
    local colors = Constants.UI_COLORS

    for _, child in ipairs(self._scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local challenges = data.challenges or {}
    for i, ch in ipairs(challenges) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -5, 0, 65)
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = self._scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 30, 0, 30)
        icon.Position = UDim2.new(0, 8, 0, 5)
        icon.BackgroundTransparency = 1
        icon.Text = ch.icon or "🎯"
        icon.TextSize = 20
        icon.Font = Enum.Font.GothamBold
        icon.Parent = row

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.6, -50, 0, 20)
        name.Position = UDim2.new(0, 42, 0, 5)
        name.BackgroundTransparency = 1
        name.Text = ch.name or "تحدي"
        name.TextSize = 13
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = colors.text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0.6, -50, 0, 16)
        desc.Position = UDim2.new(0, 42, 0, 26)
        desc.BackgroundTransparency = 1
        desc.Text = ch.description or ""
        desc.TextSize = 11
        desc.Font = Enum.Font.Gotham
        desc.TextColor3 = colors.textDim
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = row

        local reward = Instance.new("TextLabel")
        reward.Size = UDim2.new(0, 70, 0, 16)
        reward.Position = UDim2.new(0, 42, 0, 44)
        reward.BackgroundTransparency = 1
        reward.Text = "$" .. tostring(ch.reward or 0)
        reward.TextSize = 11
        reward.Font = Enum.Font.Gotham
        reward.TextColor3 = Color3.fromRGB(0, 255, 100)
        reward.TextXAlignment = Enum.TextXAlignment.Left
        reward.Parent = row

        local claimed = ch.claimed or false
        local completed = (ch.current or 0) >= (ch.target or 1)

        local claimBtn = Instance.new("TextButton")
        claimBtn.Size = UDim2.new(0, 70, 0, 28)
        claimBtn.Position = UDim2.new(1, -80, 0.5, -14)
        claimBtn.BorderSizePixel = 0
        claimBtn.TextSize = 12
        claimBtn.Font = Enum.Font.GothamBold
        claimBtn.TextColor3 = Color3.new(1, 1, 1)
        claimBtn.Parent = row
        Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 6)

        if claimed then
            claimBtn.Text = "✅"
            claimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        elseif completed then
            claimBtn.Text = "استلام"
            claimBtn.BackgroundColor3 = colors.success
            local challengeId = ch.id
            claimBtn.MouseButton1Click:Connect(function()
                Remotes:FireServer("ClaimDailyChallenge", challengeId)
            end)
        else
            claimBtn.Text = tostring(ch.current or 0) .. "/" .. tostring(ch.target or 1)
            claimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        end
    end
end

return DailyChallengeController
