--[[
    Arab City v2.0 - ShopController
    In-game shop UI for purchasing items.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function ShopController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "ShopGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 75
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Shop panel
    local panel = Instance.new("Frame")
    panel.Name = "ShopPanel"
    panel.Size = UDim2.new(0, 450, 0, 500)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = colors.background
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", panel).Color = colors.accent

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.BackgroundColor3 = colors.accent
    title.Text = "🛒 المتجر"
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BorderSizePixel = 0
    title.Parent = panel
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    -- Close
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Parent = panel

    -- Items scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -55)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scroll

    for i, item in ipairs(Constants.SHOP_ITEMS) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -5, 0, 50)
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.5, 0, 1, 0)
        name.Position = UDim2.new(0, 10, 0, 0)
        name.BackgroundTransparency = 1
        name.Text = item.name
        name.TextSize = 14
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = colors.text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row

        local price = Instance.new("TextLabel")
        price.Size = UDim2.new(0, 80, 1, 0)
        price.Position = UDim2.new(0.5, 0, 0, 0)
        price.BackgroundTransparency = 1
        price.Text = "$" .. tostring(item.price)
        price.TextSize = 13
        price.Font = Enum.Font.Gotham
        price.TextColor3 = Color3.fromRGB(0, 255, 100)
        price.Parent = row

        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0, 70, 0, 30)
        buyBtn.Position = UDim2.new(1, -80, 0.5, -15)
        buyBtn.BackgroundColor3 = colors.accent
        buyBtn.Text = "شراء"
        buyBtn.TextSize = 13
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.TextColor3 = Color3.new(1, 1, 1)
        buyBtn.BorderSizePixel = 0
        buyBtn.Parent = row
        Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)

        buyBtn.MouseButton1Click:Connect(function()
            Remotes:FireServer("PurchaseItem", item.id)
        end)
    end

    self._panel = panel

    -- Open shop via remote or building
    Remotes:OnClientEvent("OpenShop", function()
        _isOpen = true
        panel.Visible = true
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)
end

return ShopController
