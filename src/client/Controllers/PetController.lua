--[[
    Arab City - Pet Controller
    Pet shop UI and equip management
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

local PetController = {}
PetController._isOpen = false

function PetController:Init()
    self._gui = self:_buildUI()
    self._gui.Enabled = false
    self._gui.Parent = playerGui
end

function PetController:Toggle()
    if self._isOpen then self:Close() else self:Open() end
end

function PetController:Open()
    if self._isOpen then return end
    self._isOpen = true
    self._gui.Enabled = true
    self:_refresh()
end

function PetController:Close()
    if not self._isOpen then return end
    self._isOpen = false
    self._gui.Enabled = false
end

function PetController:_buildUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_Pets"
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
    main.Size = UDim2.new(0, 400, 0, 480)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = COLORS.Primary
    main.BorderSizePixel = 0
    main.ZIndex = 51
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 180, 100)
    stroke.Thickness = 1.5
    stroke.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 40)
    title.Position = UDim2.new(0, 15, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🐾 حيوانات أليفة"
    title.TextColor3 = Color3.fromRGB(255, 180, 100)
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
    scroll.Name = "PetList"
    scroll.Size = UDim2.new(1, -20, 1, -60)
    scroll.Position = UDim2.new(0.5, 0, 0, 50)
    scroll.AnchorPoint = Vector2.new(0.5, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 180, 100)
    scroll.ZIndex = 52
    scroll.Parent = main
    self._scroll = scroll

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 170, 0, 190)
    grid.CellPadding = UDim2.new(0, 10, 0, 10)
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = scroll

    return gui
end

function PetController:_refresh()
    for _, child in ipairs(self._scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local inventory = RemoteManager:InvokeServer("GetPetInventory")
    local ownedSet = {}
    if inventory and inventory.owned then
        for _, pid in ipairs(inventory.owned) do ownedSet[pid] = true end
    end
    local activePet = inventory and inventory.active or ""

    for i, pet in ipairs(Constants.PET_TYPES) do
        local owned = ownedSet[pet.id] or false
        local active = activePet == pet.id

        local card = Instance.new("Frame")
        card.BackgroundColor3 = active and COLORS.Secondary or COLORS.CardBg
        card.BackgroundTransparency = active and 0.1 or 0.3
        card.BorderSizePixel = 0
        card.LayoutOrder = i
        card.ZIndex = 53
        card.Parent = self._scroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

        if active then
            local cs = Instance.new("UIStroke")
            cs.Color = Color3.fromRGB(255, 180, 100)
            cs.Thickness = 2
            cs.Parent = card
        end

        -- Icon
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 0, 60)
        iconLabel.Position = UDim2.new(0, 0, 0, 10)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = pet.icon
        iconLabel.TextSize = 44
        iconLabel.ZIndex = 54
        iconLabel.Parent = card

        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0, 22)
        nameLabel.Position = UDim2.new(0, 0, 0, 72)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = pet.nameAr
        nameLabel.TextColor3 = COLORS.Text
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 15
        nameLabel.ZIndex = 54
        nameLabel.Parent = card

        -- Price / Status
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(1, 0, 0, 18)
        priceLabel.Position = UDim2.new(0, 0, 0, 96)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = owned and (active and "مُفعّل" or "مملوك") or Utils.formatCurrency(pet.price)
        priceLabel.TextColor3 = owned and COLORS.Success or COLORS.Gold
        priceLabel.Font = Enum.Font.GothamMedium
        priceLabel.TextSize = 12
        priceLabel.ZIndex = 54
        priceLabel.Parent = card

        -- Action button
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.8, 0, 0, 34)
        btn.Position = UDim2.new(0.5, 0, 1, -14)
        btn.AnchorPoint = Vector2.new(0.5, 1)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.ZIndex = 54
        btn.Parent = card
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        if active then
            btn.BackgroundColor3 = COLORS.Danger
            btn.Text = "إلغاء التفعيل"
            btn.TextColor3 = COLORS.Text
            btn.MouseButton1Click:Connect(function()
                RemoteManager:FireServer("UnequipPet")
                task.wait(0.5)
                self:_refresh()
            end)
        elseif owned then
            btn.BackgroundColor3 = COLORS.Accent
            btn.Text = "تفعيل"
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            btn.MouseButton1Click:Connect(function()
                RemoteManager:FireServer("EquipPet", pet.id)
                task.wait(0.5)
                self:_refresh()
            end)
        else
            btn.BackgroundColor3 = COLORS.Success
            btn.Text = "شراء"
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            btn.MouseButton1Click:Connect(function()
                RemoteManager:FireServer("BuyPet", pet.id)
                task.wait(0.5)
                self:_refresh()
            end)
        end
    end

    local rows = math.ceil(#Constants.PET_TYPES / 2)
    self._scroll.CanvasSize = UDim2.new(0, 0, 0, rows * 200 + 20)
end

return PetController
