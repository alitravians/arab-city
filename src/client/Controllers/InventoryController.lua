--[[
    Arab City v2.0 - InventoryController
    Player backpack / inventory display.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function InventoryController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "InventoryGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 65
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Toggle
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 46, 0, 46)
    toggleBtn.Position = UDim2.new(0, 180, 1, -60)
    toggleBtn.AnchorPoint = Vector2.new(0, 1)
    toggleBtn.BackgroundColor3 = colors.secondary
    toggleBtn.Text = "🎒"
    toggleBtn.TextSize = 20
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = gui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 23)

    -- Panel
    local panel = Instance.new("Frame")
    panel.Name = "InventoryPanel"
    panel.Size = UDim2.new(0, 350, 0, 400)
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
    title.Text = "🎒 الحقيبة"
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
    self._scroll.Size = UDim2.new(1, -20, 1, -50)
    self._scroll.Position = UDim2.new(0, 10, 0, 45)
    self._scroll.BackgroundTransparency = 1
    self._scroll.ScrollBarThickness = 4
    self._scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self._scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self._scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = self._scroll

    self._emptyLabel = Instance.new("TextLabel")
    self._emptyLabel.Size = UDim2.new(1, 0, 0, 40)
    self._emptyLabel.BackgroundTransparency = 1
    self._emptyLabel.Text = "الحقيبة فاضية"
    self._emptyLabel.TextSize = 14
    self._emptyLabel.Font = Enum.Font.Gotham
    self._emptyLabel.TextColor3 = colors.textDim
    self._emptyLabel.Parent = self._scroll

    self._panel = panel

    Remotes:OnClientEvent("InventoryUpdate", function(data)
        self:_refresh(data)
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        _isOpen = not _isOpen
        panel.Visible = _isOpen
        if _isOpen then
            Remotes:FireServer("RequestInventory")
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)
end

function InventoryController:_refresh(data)
    if type(data) ~= "table" then return end
    local colors = Constants.UI_COLORS

    -- Clear old items
    for _, child in ipairs(self._scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local items = data.inventory or {}
    self._emptyLabel.Visible = (#items == 0)

    for i, itemId in ipairs(items) do
        local itemConfig = nil
        for _, shopItem in ipairs(Constants.SHOP_ITEMS) do
            if shopItem.id == itemId then
                itemConfig = shopItem
                break
            end
        end

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -5, 0, 40)
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = self._scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -10, 1, 0)
        name.Position = UDim2.new(0, 10, 0, 0)
        name.BackgroundTransparency = 1
        name.Text = if itemConfig then itemConfig.name else itemId
        name.TextSize = 14
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = colors.text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row
    end
end

return InventoryController
