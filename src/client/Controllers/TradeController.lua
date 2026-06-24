--[[
    Arab City v2.0 - TradeController
    Player-to-player trade UI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TradeController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function TradeController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "TradeGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 80
    gui.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 450, 0, 350)
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
    title.Text = "🤝 تبادل"
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

    -- My offer side
    local myLabel = Instance.new("TextLabel")
    myLabel.Size = UDim2.new(0.5, -15, 0, 25)
    myLabel.Position = UDim2.new(0, 10, 0, 48)
    myLabel.BackgroundTransparency = 1
    myLabel.Text = "عرضي"
    myLabel.TextSize = 14
    myLabel.Font = Enum.Font.GothamBold
    myLabel.TextColor3 = colors.accent
    myLabel.TextXAlignment = Enum.TextXAlignment.Center
    myLabel.Parent = panel

    self._myOfferScroll = Instance.new("ScrollingFrame")
    self._myOfferScroll.Size = UDim2.new(0.5, -15, 0, 160)
    self._myOfferScroll.Position = UDim2.new(0, 10, 0, 75)
    self._myOfferScroll.BackgroundColor3 = colors.card
    self._myOfferScroll.BorderSizePixel = 0
    self._myOfferScroll.ScrollBarThickness = 3
    self._myOfferScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self._myOfferScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self._myOfferScroll.Parent = panel
    Instance.new("UICorner", self._myOfferScroll).CornerRadius = UDim.new(0, 6)
    Instance.new("UIListLayout", self._myOfferScroll).Padding = UDim.new(0, 4)

    -- Their offer side
    local theirLabel = Instance.new("TextLabel")
    theirLabel.Size = UDim2.new(0.5, -15, 0, 25)
    theirLabel.Position = UDim2.new(0.5, 5, 0, 48)
    theirLabel.BackgroundTransparency = 1
    theirLabel.Text = "عرضهم"
    theirLabel.TextSize = 14
    theirLabel.Font = Enum.Font.GothamBold
    theirLabel.TextColor3 = colors.accent
    theirLabel.TextXAlignment = Enum.TextXAlignment.Center
    theirLabel.Parent = panel

    self._theirOfferScroll = Instance.new("ScrollingFrame")
    self._theirOfferScroll.Size = UDim2.new(0.5, -15, 0, 160)
    self._theirOfferScroll.Position = UDim2.new(0.5, 5, 0, 75)
    self._theirOfferScroll.BackgroundColor3 = colors.card
    self._theirOfferScroll.BorderSizePixel = 0
    self._theirOfferScroll.ScrollBarThickness = 3
    self._theirOfferScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self._theirOfferScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self._theirOfferScroll.Parent = panel
    Instance.new("UICorner", self._theirOfferScroll).CornerRadius = UDim.new(0, 6)
    Instance.new("UIListLayout", self._theirOfferScroll).Padding = UDim.new(0, 4)

    -- Cash input
    local cashFrame = Instance.new("Frame")
    cashFrame.Size = UDim2.new(0.5, -15, 0, 36)
    cashFrame.Position = UDim2.new(0, 10, 0, 245)
    cashFrame.BackgroundColor3 = colors.card
    cashFrame.BorderSizePixel = 0
    cashFrame.Parent = panel
    Instance.new("UICorner", cashFrame).CornerRadius = UDim.new(0, 6)

    local cashBox = Instance.new("TextBox")
    cashBox.Size = UDim2.new(1, -10, 1, 0)
    cashBox.Position = UDim2.new(0, 5, 0, 0)
    cashBox.BackgroundTransparency = 1
    cashBox.PlaceholderText = "المبلغ $"
    cashBox.Text = ""
    cashBox.TextSize = 14
    cashBox.Font = Enum.Font.Gotham
    cashBox.TextColor3 = colors.text
    cashBox.PlaceholderColor3 = colors.textDim
    cashBox.Parent = cashFrame

    -- Accept / Decline
    local acceptBtn = Instance.new("TextButton")
    acceptBtn.Size = UDim2.new(0, 120, 0, 36)
    acceptBtn.Position = UDim2.new(0.5, -130, 1, -50)
    acceptBtn.BackgroundColor3 = colors.success
    acceptBtn.Text = "✅ قبول"
    acceptBtn.TextSize = 15
    acceptBtn.Font = Enum.Font.GothamBold
    acceptBtn.TextColor3 = Color3.new(1, 1, 1)
    acceptBtn.BorderSizePixel = 0
    acceptBtn.Parent = panel
    Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 8)

    local declineBtn = Instance.new("TextButton")
    declineBtn.Size = UDim2.new(0, 120, 0, 36)
    declineBtn.Position = UDim2.new(0.5, 10, 1, -50)
    declineBtn.BackgroundColor3 = colors.danger
    declineBtn.Text = "❌ رفض"
    declineBtn.TextSize = 15
    declineBtn.Font = Enum.Font.GothamBold
    declineBtn.TextColor3 = Color3.new(1, 1, 1)
    declineBtn.BorderSizePixel = 0
    declineBtn.Parent = panel
    Instance.new("UICorner", declineBtn).CornerRadius = UDim.new(0, 8)

    self._panel = panel
    self._cashBox = cashBox

    acceptBtn.MouseButton1Click:Connect(function()
        local amount = tonumber(cashBox.Text) or 0
        Remotes:FireServer("TradeAction", { action = "accept", cashOffer = amount })
    end)

    declineBtn.MouseButton1Click:Connect(function()
        Remotes:FireServer("TradeAction", { action = "decline" })
        _isOpen = false
        panel.Visible = false
    end)

    Remotes:OnClientEvent("TradeRequest", function(data)
        _isOpen = true
        panel.Visible = true
        self:_showTrade(data)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)
end

function TradeController:_showTrade(data)
    if type(data) ~= "table" then return end
    local colors = Constants.UI_COLORS

    -- Clear scrolls
    for _, child in ipairs(self._myOfferScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for _, child in ipairs(self._theirOfferScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local function addItem(parent, name, order)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 28)
        row.BackgroundColor3 = colors.background
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -6, 1, 0)
        lbl.Position = UDim2.new(0, 3, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextColor3 = colors.text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
    end

    local myItems = data.myOffer or {}
    for i, item in ipairs(myItems) do
        addItem(self._myOfferScroll, item, i)
    end

    local theirItems = data.theirOffer or {}
    for i, item in ipairs(theirItems) do
        addItem(self._theirOfferScroll, item, i)
    end
end

return TradeController
