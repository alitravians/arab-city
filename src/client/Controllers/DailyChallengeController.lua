--[[
    Arab City - Daily Challenge Controller
    Shows daily challenges progress and claim UI
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

local DailyChallengeController = {}
DailyChallengeController._isOpen = false

function DailyChallengeController:Init()
    self._gui = self:_buildUI()
    self._gui.Enabled = false
    self._gui.Parent = playerGui

    RemoteManager:OnClientEvent("DailyChallengeUpdate", function()
        if self._isOpen then self:_refresh() end
    end)
end

function DailyChallengeController:Toggle()
    if self._isOpen then self:Close() else self:Open() end
end

function DailyChallengeController:Open()
    if self._isOpen then return end
    self._isOpen = true
    self._gui.Enabled = true
    self:_refresh()
end

function DailyChallengeController:Close()
    if not self._isOpen then return end
    self._isOpen = false
    self._gui.Enabled = false
end

function DailyChallengeController:_buildUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_DailyChallenges"
    gui.DisplayOrder = 85
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false

    local backdrop = Instance.new("TextButton")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0
    backdrop.Text = ""
    backdrop.ZIndex = 50
    backdrop.Parent = gui
    backdrop.MouseButton1Click:Connect(function() self:Close() end)

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 380, 0, 460)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = COLORS.Primary
    main.BorderSizePixel = 0
    main.ZIndex = 51
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Gold
    stroke.Thickness = 1.5
    stroke.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 40)
    title.Position = UDim2.new(0, 15, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🎯 تحديات يومية"
    title.TextColor3 = COLORS.Gold
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 52
    title.Parent = main

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = COLORS.TextDim
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.ZIndex = 52
    closeBtn.Parent = main
    closeBtn.MouseButton1Click:Connect(function() self:Close() end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "ChallengeList"
    scroll.Size = UDim2.new(1, -20, 1, -60)
    scroll.Position = UDim2.new(0.5, 0, 0, 50)
    scroll.AnchorPoint = Vector2.new(0.5, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = COLORS.Gold
    scroll.ZIndex = 52
    scroll.Parent = main
    self._scroll = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    return gui
end

function DailyChallengeController:_refresh()
    for _, child in ipairs(self._scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local challenges = RemoteManager:InvokeServer("GetDailyChallenges")
    if not challenges then return end

    for i, ch in ipairs(challenges) do
        local dcDef = nil
        for _, dc in ipairs(Constants.DAILY_CHALLENGES) do
            if dc.id == ch.id then dcDef = dc break end
        end
        if not dcDef then continue end

        local completed = ch.progress >= ch.target
        local claimed = ch.claimed

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 80)
        card.BackgroundColor3 = claimed and COLORS.Secondary or COLORS.CardBg
        card.BackgroundTransparency = claimed and 0.2 or 0.4
        card.BorderSizePixel = 0
        card.LayoutOrder = claimed and (100 + i) or i
        card.ZIndex = 53
        card.Parent = self._scroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

        if completed and not claimed then
            local cs = Instance.new("UIStroke")
            cs.Color = COLORS.Gold
            cs.Thickness = 2
            cs.Parent = card
        end

        -- Challenge name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, -10, 0, 22)
        nameLabel.Position = UDim2.new(0, 12, 0, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = dcDef.nameAr
        nameLabel.TextColor3 = COLORS.Text
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 54
        nameLabel.Parent = card

        -- Reward
        local rewardLabel = Instance.new("TextLabel")
        rewardLabel.Size = UDim2.new(0.3, -10, 0, 22)
        rewardLabel.Position = UDim2.new(0.7, 0, 0, 8)
        rewardLabel.BackgroundTransparency = 1
        rewardLabel.Text = "💰 " .. Utils.formatCurrency(dcDef.reward)
        rewardLabel.TextColor3 = COLORS.Gold
        rewardLabel.Font = Enum.Font.GothamBold
        rewardLabel.TextSize = 12
        rewardLabel.TextXAlignment = Enum.TextXAlignment.Right
        rewardLabel.ZIndex = 54
        rewardLabel.Parent = card

        -- Progress bar
        local barBg = Instance.new("Frame")
        barBg.Size = UDim2.new(1, -24, 0, 10)
        barBg.Position = UDim2.new(0.5, 0, 0, 36)
        barBg.AnchorPoint = Vector2.new(0.5, 0)
        barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        barBg.BorderSizePixel = 0
        barBg.ZIndex = 54
        barBg.Parent = card
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local progress = math.clamp(ch.progress / ch.target, 0, 1)
        local barFill = Instance.new("Frame")
        barFill.Size = UDim2.new(progress, 0, 1, 0)
        barFill.BackgroundColor3 = completed and COLORS.Success or COLORS.Accent
        barFill.BorderSizePixel = 0
        barFill.ZIndex = 55
        barFill.Parent = barBg
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

        -- Progress text
        local progressLabel = Instance.new("TextLabel")
        progressLabel.Size = UDim2.new(1, -24, 0, 16)
        progressLabel.Position = UDim2.new(0.5, 0, 0, 50)
        progressLabel.AnchorPoint = Vector2.new(0.5, 0)
        progressLabel.BackgroundTransparency = 1
        progressLabel.Text = ch.progress .. " / " .. ch.target
        progressLabel.TextColor3 = COLORS.TextDim
        progressLabel.Font = Enum.Font.GothamMedium
        progressLabel.TextSize = 11
        progressLabel.ZIndex = 54
        progressLabel.Parent = card

        -- Claim button
        if completed and not claimed then
            local claimBtn = Instance.new("TextButton")
            claimBtn.Size = UDim2.new(0, 80, 0, 26)
            claimBtn.Position = UDim2.new(1, -12, 1, -8)
            claimBtn.AnchorPoint = Vector2.new(1, 1)
            claimBtn.BackgroundColor3 = COLORS.Gold
            claimBtn.BorderSizePixel = 0
            claimBtn.Text = "اجمع!"
            claimBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            claimBtn.Font = Enum.Font.GothamBold
            claimBtn.TextSize = 12
            claimBtn.ZIndex = 54
            claimBtn.Parent = card
            Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 8)

            claimBtn.MouseButton1Click:Connect(function()
                RemoteManager:FireServer("ClaimDailyChallenge", ch.id)
                task.wait(0.5)
                self:_refresh()
            end)
        elseif claimed then
            local doneLabel = Instance.new("TextLabel")
            doneLabel.Size = UDim2.new(0, 80, 0, 26)
            doneLabel.Position = UDim2.new(1, -12, 1, -8)
            doneLabel.AnchorPoint = Vector2.new(1, 1)
            doneLabel.BackgroundTransparency = 1
            doneLabel.Text = "تم الجمع ✓"
            doneLabel.TextColor3 = COLORS.Success
            doneLabel.Font = Enum.Font.GothamMedium
            doneLabel.TextSize = 11
            doneLabel.ZIndex = 54
            doneLabel.Parent = card
        end
    end

    self._scroll.CanvasSize = UDim2.new(0, 0, 0, #challenges * 88 + 10)
end

return DailyChallengeController
