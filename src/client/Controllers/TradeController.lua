--[[
    Arab City - Trade Controller
    UI for player-to-player trading
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

local TradeController = {}
TradeController._isOpen = false

function TradeController:Init()
    self._gui = self:_buildUI()
    self._gui.Enabled = false
    self._gui.Parent = playerGui

    RemoteManager:OnClientEvent("TradeUpdate", function(action, data)
        if action == "incoming" then
            self:_showIncomingTrade(data)
        end
    end)
end

function TradeController:Toggle()
    if self._isOpen then self:Close() else self:Open() end
end

function TradeController:Open()
    if self._isOpen then return end
    self._isOpen = true
    self._gui.Enabled = true
    self:_refreshPlayerList()
end

function TradeController:Close()
    if not self._isOpen then return end
    self._isOpen = false
    self._gui.Enabled = false
end

function TradeController:_buildUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_Trade"
    gui.DisplayOrder = 85
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false

    -- Backdrop
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
    main.Size = UDim2.new(0, 360, 0, 450)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = COLORS.Primary
    main.BorderSizePixel = 0
    main.ZIndex = 51
    main.Parent = gui
    self._mainFrame = main

    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Accent
    stroke.Thickness = 1.5
    stroke.Parent = main

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 40)
    title.Position = UDim2.new(0, 15, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🔄 نظام التبادل"
    title.TextColor3 = COLORS.Accent
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

    -- Cash input
    local cashFrame = Instance.new("Frame")
    cashFrame.Size = UDim2.new(1, -20, 0, 40)
    cashFrame.Position = UDim2.new(0.5, 0, 0, 50)
    cashFrame.AnchorPoint = Vector2.new(0.5, 0)
    cashFrame.BackgroundTransparency = 1
    cashFrame.ZIndex = 52
    cashFrame.Parent = main

    local cashLabel = Instance.new("TextLabel")
    cashLabel.Size = UDim2.new(0, 100, 1, 0)
    cashLabel.BackgroundTransparency = 1
    cashLabel.Text = "المبلغ: $"
    cashLabel.TextColor3 = COLORS.Text
    cashLabel.Font = Enum.Font.GothamBold
    cashLabel.TextSize = 14
    cashLabel.TextXAlignment = Enum.TextXAlignment.Right
    cashLabel.ZIndex = 53
    cashLabel.Parent = cashFrame

    local cashInput = Instance.new("TextBox")
    cashInput.Name = "CashInput"
    cashInput.Size = UDim2.new(1, -110, 1, 0)
    cashInput.Position = UDim2.new(0, 105, 0, 0)
    cashInput.BackgroundColor3 = COLORS.CardBg
    cashInput.BorderSizePixel = 0
    cashInput.PlaceholderText = "0"
    cashInput.PlaceholderColor3 = COLORS.TextDim
    cashInput.Text = ""
    cashInput.TextColor3 = COLORS.Text
    cashInput.Font = Enum.Font.GothamMedium
    cashInput.TextSize = 14
    cashInput.ZIndex = 53
    cashInput.Parent = cashFrame
    self._cashInput = cashInput
    Instance.new("UICorner", cashInput).CornerRadius = UDim.new(0, 8)
    local inputPad = Instance.new("UIPadding")
    inputPad.PaddingLeft = UDim.new(0, 10)
    inputPad.Parent = cashInput

    -- Player list
    local listLabel = Instance.new("TextLabel")
    listLabel.Size = UDim2.new(1, -20, 0, 25)
    listLabel.Position = UDim2.new(0.5, 0, 0, 98)
    listLabel.AnchorPoint = Vector2.new(0.5, 0)
    listLabel.BackgroundTransparency = 1
    listLabel.Text = "اختر لاعب للتبادل:"
    listLabel.TextColor3 = COLORS.TextDim
    listLabel.Font = Enum.Font.GothamMedium
    listLabel.TextSize = 13
    listLabel.TextXAlignment = Enum.TextXAlignment.Right
    listLabel.ZIndex = 52
    listLabel.Parent = main

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "PlayerList"
    scroll.Size = UDim2.new(1, -20, 1, -135)
    scroll.Position = UDim2.new(0.5, 0, 0, 125)
    scroll.AnchorPoint = Vector2.new(0.5, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = COLORS.Accent
    scroll.ZIndex = 52
    scroll.Parent = main
    self._scroll = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    return gui
end

function TradeController:_refreshPlayerList()
    for _, child in ipairs(self._scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 44)
            row.BackgroundColor3 = COLORS.CardBg
            row.BackgroundTransparency = 0.4
            row.BorderSizePixel = 0
            row.ZIndex = 53
            row.Parent = self._scroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, 12, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = otherPlayer.DisplayName or otherPlayer.Name
            nameLabel.TextColor3 = COLORS.Text
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextSize = 14
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.ZIndex = 54
            nameLabel.Parent = row

            local tradeBtn = Instance.new("TextButton")
            tradeBtn.Size = UDim2.new(0, 80, 0, 30)
            tradeBtn.Position = UDim2.new(1, -10, 0.5, 0)
            tradeBtn.AnchorPoint = Vector2.new(1, 0.5)
            tradeBtn.BackgroundColor3 = COLORS.Accent
            tradeBtn.BorderSizePixel = 0
            tradeBtn.Text = "تبادل"
            tradeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            tradeBtn.Font = Enum.Font.GothamBold
            tradeBtn.TextSize = 13
            tradeBtn.ZIndex = 54
            tradeBtn.Parent = row
            Instance.new("UICorner", tradeBtn).CornerRadius = UDim.new(0, 8)

            tradeBtn.MouseButton1Click:Connect(function()
                local cashAmount = tonumber(self._cashInput.Text) or 0
                RemoteManager:FireServer("TradeRequest", otherPlayer.UserId, cashAmount, "")
                tradeBtn.Text = "..."
                task.delay(2, function()
                    if tradeBtn.Parent then tradeBtn.Text = "تبادل" end
                end)
            end)
        end
    end

    local totalPlayers = #Players:GetPlayers() - 1
    self._scroll.CanvasSize = UDim2.new(0, 0, 0, totalPlayers * 50 + 10)
end

function TradeController:_showIncomingTrade(data: { [string]: any })
    local popup = Instance.new("ScreenGui")
    popup.Name = "TradePopup"
    popup.DisplayOrder = 200
    popup.IgnoreGuiInset = true
    popup.Parent = playerGui

    local overlay = Instance.new("TextButton")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.6
    overlay.BorderSizePixel = 0
    overlay.Text = ""
    overlay.ZIndex = 100
    overlay.Parent = popup

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 340, 0, 200)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = COLORS.Primary
    card.BorderSizePixel = 0
    card.ZIndex = 101
    card.Parent = popup
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local s = Instance.new("UIStroke")
    s.Color = COLORS.Accent
    s.Thickness = 2
    s.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, 0, 0, 35)
    titleLbl.Position = UDim2.new(0, 0, 0, 10)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "🔄 عرض تبادل من " .. (data.fromName or "لاعب")
    titleLbl.TextColor3 = COLORS.Accent
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 16
    titleLbl.ZIndex = 102
    titleLbl.Parent = card

    local offerLbl = Instance.new("TextLabel")
    offerLbl.Size = UDim2.new(1, 0, 0, 30)
    offerLbl.Position = UDim2.new(0, 0, 0, 55)
    offerLbl.BackgroundTransparency = 1
    offerLbl.Text = "يعرض عليك: " .. Utils.formatCurrency(data.offerCash or 0)
    offerLbl.TextColor3 = COLORS.Gold
    offerLbl.Font = Enum.Font.GothamMedium
    offerLbl.TextSize = 15
    offerLbl.ZIndex = 102
    offerLbl.Parent = card

    -- Accept / Decline buttons
    local acceptBtn = Instance.new("TextButton")
    acceptBtn.Size = UDim2.new(0, 120, 0, 40)
    acceptBtn.Position = UDim2.new(0.3, 0, 1, -30)
    acceptBtn.AnchorPoint = Vector2.new(0.5, 1)
    acceptBtn.BackgroundColor3 = COLORS.Success
    acceptBtn.BorderSizePixel = 0
    acceptBtn.Text = "قبول"
    acceptBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    acceptBtn.Font = Enum.Font.GothamBold
    acceptBtn.TextSize = 15
    acceptBtn.ZIndex = 102
    acceptBtn.Parent = card
    Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 10)

    local declineBtn = Instance.new("TextButton")
    declineBtn.Size = UDim2.new(0, 120, 0, 40)
    declineBtn.Position = UDim2.new(0.7, 0, 1, -30)
    declineBtn.AnchorPoint = Vector2.new(0.5, 1)
    declineBtn.BackgroundColor3 = COLORS.Danger
    declineBtn.BorderSizePixel = 0
    declineBtn.Text = "رفض"
    declineBtn.TextColor3 = COLORS.Text
    declineBtn.Font = Enum.Font.GothamBold
    declineBtn.TextSize = 15
    declineBtn.ZIndex = 102
    declineBtn.Parent = card
    Instance.new("UICorner", declineBtn).CornerRadius = UDim.new(0, 10)

    acceptBtn.MouseButton1Click:Connect(function()
        RemoteManager:FireServer("TradeResponse", data.tradeId, true)
        popup:Destroy()
    end)

    declineBtn.MouseButton1Click:Connect(function()
        RemoteManager:FireServer("TradeResponse", data.tradeId, false)
        popup:Destroy()
    end)

    -- Auto-dismiss after 30s
    task.delay(30, function()
        if popup.Parent then popup:Destroy() end
    end)
end

return TradeController
