--[[
    Arab City v2.0 - PetController
    Pet shop + equipped pet display.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function PetController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "PetGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 57
    gui.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
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
    title.Text = "🐾 الحيوانات الأليفة"
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

    for i, pet in ipairs(Constants.PETS) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -5, 0, 55)
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = self._scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 40, 1, 0)
        icon.Position = UDim2.new(0, 5, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Text = pet.icon or "🐶"
        icon.TextSize = 24
        icon.Font = Enum.Font.GothamBold
        icon.Parent = row

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0, 120, 0, 20)
        name.Position = UDim2.new(0, 48, 0, 5)
        name.BackgroundTransparency = 1
        name.Text = pet.name
        name.TextSize = 14
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = colors.text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row

        local price = Instance.new("TextLabel")
        price.Size = UDim2.new(0, 120, 0, 16)
        price.Position = UDim2.new(0, 48, 0, 27)
        price.BackgroundTransparency = 1
        price.Text = "$" .. tostring(pet.price)
        price.TextSize = 12
        price.Font = Enum.Font.Gotham
        price.TextColor3 = Color3.fromRGB(0, 255, 100)
        price.TextXAlignment = Enum.TextXAlignment.Left
        price.Parent = row

        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0, 60, 0, 28)
        buyBtn.Position = UDim2.new(1, -70, 0.5, -14)
        buyBtn.BackgroundColor3 = colors.accent
        buyBtn.Text = "شراء"
        buyBtn.TextSize = 12
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.TextColor3 = Color3.new(1, 1, 1)
        buyBtn.BorderSizePixel = 0
        buyBtn.Parent = row
        Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)

        buyBtn.MouseButton1Click:Connect(function()
            Remotes:FireServer("PurchasePet", pet.id)
        end)
    end

    self._panel = panel

    Remotes:OnClientEvent("OpenPets", function()
        _isOpen = true
        panel.Visible = true
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)
end

return PetController
