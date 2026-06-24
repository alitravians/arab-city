--[[
    Arab City - GUI Definitions
    Creates all ScreenGui panels (Codes, Shop, Inventory, Missions)
    Theme: Midnight Blue Neon
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager
local Utils = Shared.Utils

local COLORS = Constants.COLORS

local GUIModule = {}

-- ═══════════════════════════════════════════════
-- UTILITY: Create panel window (reusable)
-- ═══════════════════════════════════════════════
local function createPanel(name: string, titleAr: string, titleIcon: string): (ScreenGui, Frame, Frame)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.DisplayOrder = 80
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = true

    -- Backdrop overlay
    local backdrop = Instance.new("TextButton")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0
    backdrop.Text = ""
    backdrop.ZIndex = 50
    backdrop.Parent = gui

    -- Main panel
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0.45, 0, 0.7, 0)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = COLORS.Primary
    panel.BorderSizePixel = 0
    panel.ZIndex = 51
    panel.Parent = gui

    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = COLORS.Accent
    panelStroke.Thickness = 1.5
    panelStroke.Transparency = 0.4
    panelStroke.Parent = panel

    local panelGradient = Instance.new("UIGradient")
    panelGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 14, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 6, 18)),
    })
    panelGradient.Rotation = 180
    panelGradient.Parent = panel

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = COLORS.Secondary
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 52
    titleBar.Parent = panel

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 14)
    titleCorner.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 16, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = titleIcon .. "  " .. titleAr
    titleLabel.TextColor3 = COLORS.Accent
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 53
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -42, 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundColor3 = COLORS.Danger
    closeBtn.BackgroundTransparency = 0.7
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = COLORS.Text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.ZIndex = 53
    closeBtn.Parent = titleBar

    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

    -- Close handlers
    local function closePanel()
        TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0.4, 0, 0.65, 0),
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(backdrop, TweenInfo.new(0.2), {
            BackgroundTransparency = 1,
        }):Play()
        task.delay(0.22, function()
            gui.Enabled = false
            panel.Size = UDim2.new(0.45, 0, 0.7, 0)
            panel.BackgroundTransparency = 0
        end)
    end

    closeBtn.MouseButton1Click:Connect(closePanel)
    backdrop.MouseButton1Click:Connect(closePanel)

    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -24, 1, -64)
    contentFrame.Position = UDim2.new(0.5, 0, 0, 56)
    contentFrame.AnchorPoint = Vector2.new(0.5, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ZIndex = 52
    contentFrame.Parent = panel

    gui.Enabled = false
    return gui, panel, contentFrame
end

-- ═══════════════════════════════════════════════
-- CODES PANEL
-- ═══════════════════════════════════════════════
local function buildCodesPanel(): ScreenGui
    local gui, _panel, content = createPanel("CodesPanel", "الأكواد", "🎁")

    -- Code input box
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, 0, 0, 50)
    inputFrame.BackgroundTransparency = 1
    inputFrame.ZIndex = 53
    inputFrame.Parent = content

    local codeInput = Instance.new("TextBox")
    codeInput.Name = "CodeInput"
    codeInput.Size = UDim2.new(0.65, 0, 1, 0)
    codeInput.BackgroundColor3 = COLORS.CardBg
    codeInput.BorderSizePixel = 0
    codeInput.PlaceholderText = "أدخل الكود هنا..."
    codeInput.PlaceholderColor3 = COLORS.TextDim
    codeInput.Text = ""
    codeInput.TextColor3 = COLORS.Text
    codeInput.Font = Enum.Font.GothamMedium
    codeInput.TextSize = 16
    codeInput.ClearTextOnFocus = false
    codeInput.ZIndex = 54
    codeInput.Parent = inputFrame

    Instance.new("UICorner", codeInput).CornerRadius = UDim.new(0, 10)

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = COLORS.Accent
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.6
    inputStroke.Parent = codeInput

    local inputPadding = Instance.new("UIPadding")
    inputPadding.PaddingLeft = UDim.new(0, 12)
    inputPadding.PaddingRight = UDim.new(0, 12)
    inputPadding.Parent = codeInput

    local redeemBtn = Instance.new("TextButton")
    redeemBtn.Name = "RedeemBtn"
    redeemBtn.Size = UDim2.new(0.32, 0, 1, 0)
    redeemBtn.Position = UDim2.new(0.68, 0, 0, 0)
    redeemBtn.BackgroundColor3 = COLORS.Accent
    redeemBtn.BorderSizePixel = 0
    redeemBtn.Text = "استخدم"
    redeemBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    redeemBtn.Font = Enum.Font.GothamBold
    redeemBtn.TextSize = 16
    redeemBtn.ZIndex = 54
    redeemBtn.Parent = inputFrame

    Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 10)

    -- Result message
    local resultLabel = Instance.new("TextLabel")
    resultLabel.Name = "ResultLabel"
    resultLabel.Size = UDim2.new(1, 0, 0, 30)
    resultLabel.Position = UDim2.new(0, 0, 0, 58)
    resultLabel.BackgroundTransparency = 1
    resultLabel.Text = ""
    resultLabel.TextColor3 = COLORS.Success
    resultLabel.Font = Enum.Font.GothamMedium
    resultLabel.TextSize = 14
    resultLabel.ZIndex = 54
    resultLabel.Parent = content

    -- Listen for code redemption results
    RemoteManager:OnClientEvent("CodeResult", function(success, message)
        if success then
            resultLabel.Text = "تم استخدام الكود بنجاح! " .. (message or "")
            resultLabel.TextColor3 = COLORS.Success
        else
            resultLabel.Text = message or "كود غير صالح"
            resultLabel.TextColor3 = COLORS.Danger
        end
        redeemBtn.Text = "استخدم"
        codeInput.Text = ""
        task.delay(4, function()
            resultLabel.Text = ""
        end)
    end)

    -- Redeem action
    redeemBtn.MouseButton1Click:Connect(function()
        local code = codeInput.Text
        if code == "" then
            return
        end
        redeemBtn.Text = "..."
        RemoteManager:FireServer("RedeemCode", code)
    end)

    -- Available codes list area
    local codesListTitle = Instance.new("TextLabel")
    codesListTitle.Size = UDim2.new(1, 0, 0, 30)
    codesListTitle.Position = UDim2.new(0, 0, 0, 100)
    codesListTitle.BackgroundTransparency = 1
    codesListTitle.Text = "الأكواد المتاحة"
    codesListTitle.TextColor3 = COLORS.Gold
    codesListTitle.Font = Enum.Font.GothamBold
    codesListTitle.TextSize = 16
    codesListTitle.TextXAlignment = Enum.TextXAlignment.Right
    codesListTitle.ZIndex = 54
    codesListTitle.Parent = content

    local codesScroll = Instance.new("ScrollingFrame")
    codesScroll.Name = "CodesList"
    codesScroll.Size = UDim2.new(1, 0, 1, -140)
    codesScroll.Position = UDim2.new(0, 0, 0, 135)
    codesScroll.BackgroundTransparency = 1
    codesScroll.ScrollBarThickness = 4
    codesScroll.ScrollBarImageColor3 = COLORS.Accent
    codesScroll.ZIndex = 54
    codesScroll.Parent = content

    local codesLayout = Instance.new("UIListLayout")
    codesLayout.Padding = UDim.new(0, 6)
    codesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    codesLayout.Parent = codesScroll

    return gui
end

-- ═══════════════════════════════════════════════
-- SHOP PANEL
-- ═══════════════════════════════════════════════
local function buildShopPanel(): ScreenGui
    local gui, _panel, content = createPanel("ShopPanel", "المتجر", "🛒")

    -- Category tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 40)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 53
    tabBar.Parent = content

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabBar

    local categories = {
        { name = "vehicles", labelAr = "سيارات", icon = "🚗" },
        { name = "cameras",  labelAr = "كاميرات", icon = "📷" },
        { name = "ranks",    labelAr = "رتب", icon = "👑" },
    }

    for i, cat in ipairs(categories) do
        local tab = Instance.new("TextButton")
        tab.Name = "Tab_" .. cat.name
        tab.Size = UDim2.new(0, 100, 1, 0)
        tab.BackgroundColor3 = i == 1 and COLORS.Accent or COLORS.CardBg
        tab.BackgroundTransparency = i == 1 and 0.2 or 0.5
        tab.BorderSizePixel = 0
        tab.Text = cat.icon .. " " .. cat.labelAr
        tab.TextColor3 = COLORS.Text
        tab.Font = Enum.Font.GothamBold
        tab.TextSize = 13
        tab.LayoutOrder = i
        tab.ZIndex = 54
        tab.Parent = tabBar

        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 8)
    end

    -- Items scrolling area
    local itemsScroll = Instance.new("ScrollingFrame")
    itemsScroll.Name = "ItemsList"
    itemsScroll.Size = UDim2.new(1, 0, 1, -52)
    itemsScroll.Position = UDim2.new(0, 0, 0, 48)
    itemsScroll.BackgroundTransparency = 1
    itemsScroll.ScrollBarThickness = 4
    itemsScroll.ScrollBarImageColor3 = COLORS.Accent
    itemsScroll.ZIndex = 53
    itemsScroll.Parent = content

    local itemsGrid = Instance.new("UIGridLayout")
    itemsGrid.CellSize = UDim2.new(0, 180, 0, 200)
    itemsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    itemsGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    itemsGrid.SortOrder = Enum.SortOrder.LayoutOrder
    itemsGrid.Parent = itemsScroll

    -- Populate with vehicle items
    for i, vehicle in ipairs(Constants.VEHICLES) do
        local card = Instance.new("Frame")
        card.Name = "Item_" .. vehicle.id
        card.BackgroundColor3 = COLORS.CardBg
        card.BorderSizePixel = 0
        card.LayoutOrder = i
        card.ZIndex = 54
        card.Parent = itemsScroll

        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = COLORS.Accent
        cardStroke.Thickness = 1
        cardStroke.Transparency = 0.7
        cardStroke.Parent = card

        -- Vehicle icon area
        local iconArea = Instance.new("Frame")
        iconArea.Size = UDim2.new(1, 0, 0.5, 0)
        iconArea.BackgroundColor3 = COLORS.Secondary
        iconArea.BackgroundTransparency = 0.5
        iconArea.BorderSizePixel = 0
        iconArea.ZIndex = 55
        iconArea.Parent = card

        Instance.new("UICorner", iconArea).CornerRadius = UDim.new(0, 10)

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = "🚗"
        iconLabel.TextSize = 40
        iconLabel.ZIndex = 56
        iconLabel.Parent = iconArea

        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -12, 0, 22)
        nameLabel.Position = UDim2.new(0, 6, 0.52, 4)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = vehicle.nameAr
        nameLabel.TextColor3 = COLORS.Text
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Right
        nameLabel.ZIndex = 55
        nameLabel.Parent = card

        -- Price
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(1, -12, 0, 18)
        priceLabel.Position = UDim2.new(0, 6, 0.52, 28)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = Utils.formatCurrency(vehicle.price)
        priceLabel.TextColor3 = COLORS.Gold
        priceLabel.Font = Enum.Font.GothamMedium
        priceLabel.TextSize = 13
        priceLabel.TextXAlignment = Enum.TextXAlignment.Right
        priceLabel.ZIndex = 55
        priceLabel.Parent = card

        -- Buy button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0.8, 0, 0, 32)
        buyBtn.Position = UDim2.new(0.5, 0, 1, -40)
        buyBtn.AnchorPoint = Vector2.new(0.5, 0)
        buyBtn.BackgroundColor3 = COLORS.Success
        buyBtn.BackgroundTransparency = 0.1
        buyBtn.BorderSizePixel = 0
        buyBtn.Text = "شراء"
        buyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.TextSize = 14
        buyBtn.ZIndex = 55
        buyBtn.Parent = card

        Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

        buyBtn.MouseButton1Click:Connect(function()
            RemoteManager:FireServer("RequestPurchase", "vehicle", vehicle.id)
        end)
    end

    return gui
end

-- ═══════════════════════════════════════════════
-- INVENTORY PANEL
-- ═══════════════════════════════════════════════
local function buildInventoryPanel(): ScreenGui
    local gui, _panel, content = createPanel("InventoryPanel", "الحقيبة", "🎒")

    -- Category tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 36)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 53
    tabBar.Parent = content

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabBar

    local invCategories = {
        { name = "vehicles",   labelAr = "سياراتي", icon = "🚗" },
        { name = "properties", labelAr = "عقاراتي", icon = "🏠" },
        { name = "cameras",    labelAr = "كاميراتي", icon = "📷" },
    }

    for i, cat in ipairs(invCategories) do
        local tab = Instance.new("TextButton")
        tab.Name = "Tab_" .. cat.name
        tab.Size = UDim2.new(0, 100, 1, 0)
        tab.BackgroundColor3 = i == 1 and COLORS.Accent or COLORS.CardBg
        tab.BackgroundTransparency = i == 1 and 0.2 or 0.5
        tab.BorderSizePixel = 0
        tab.Text = cat.icon .. " " .. cat.labelAr
        tab.TextColor3 = COLORS.Text
        tab.Font = Enum.Font.GothamBold
        tab.TextSize = 12
        tab.LayoutOrder = i
        tab.ZIndex = 54
        tab.Parent = tabBar

        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 8)
    end

    -- Items scrolling area
    local itemsScroll = Instance.new("ScrollingFrame")
    itemsScroll.Name = "InventoryItems"
    itemsScroll.Size = UDim2.new(1, 0, 1, -44)
    itemsScroll.Position = UDim2.new(0, 0, 0, 42)
    itemsScroll.BackgroundTransparency = 1
    itemsScroll.ScrollBarThickness = 4
    itemsScroll.ScrollBarImageColor3 = COLORS.Accent
    itemsScroll.ZIndex = 53
    itemsScroll.Parent = content

    local itemsGrid = Instance.new("UIGridLayout")
    itemsGrid.CellSize = UDim2.new(0, 140, 0, 140)
    itemsGrid.CellPadding = UDim2.new(0, 8, 0, 8)
    itemsGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    itemsGrid.SortOrder = Enum.SortOrder.LayoutOrder
    itemsGrid.Parent = itemsScroll

    -- Empty state
    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Name = "EmptyLabel"
    emptyLabel.Size = UDim2.new(1, 0, 1, 0)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "حقيبتك فارغة\nابدأ بشراء سيارات وعقارات!"
    emptyLabel.TextColor3 = COLORS.TextDim
    emptyLabel.Font = Enum.Font.GothamMedium
    emptyLabel.TextSize = 16
    emptyLabel.ZIndex = 54
    emptyLabel.Parent = itemsScroll

    return gui
end

-- ═══════════════════════════════════════════════
-- MISSIONS PANEL
-- ═══════════════════════════════════════════════
local function buildMissionsPanel(): ScreenGui
    local gui, _panel, content = createPanel("MissionsPanel", "المهمات", "📋")

    -- Missions scroll
    local missionsScroll = Instance.new("ScrollingFrame")
    missionsScroll.Name = "MissionsList"
    missionsScroll.Size = UDim2.new(1, 0, 1, 0)
    missionsScroll.BackgroundTransparency = 1
    missionsScroll.ScrollBarThickness = 4
    missionsScroll.ScrollBarImageColor3 = COLORS.Accent
    missionsScroll.ZIndex = 53
    missionsScroll.Parent = content

    local missionsLayout = Instance.new("UIListLayout")
    missionsLayout.Padding = UDim.new(0, 8)
    missionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    missionsLayout.Parent = missionsScroll

    -- Populate with mission cards
    for i, mission in ipairs(Constants.MISSIONS) do
        local card = Instance.new("Frame")
        card.Name = "Mission_" .. mission.id
        card.Size = UDim2.new(1, 0, 0, 80)
        card.BackgroundColor3 = COLORS.CardBg
        card.BorderSizePixel = 0
        card.LayoutOrder = i
        card.ZIndex = 54
        card.Parent = missionsScroll

        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = COLORS.Accent
        cardStroke.Thickness = 1
        cardStroke.Transparency = 0.7
        cardStroke.Parent = card

        -- Mission name
        local missionName = Instance.new("TextLabel")
        missionName.Size = UDim2.new(0.7, -10, 0, 24)
        missionName.Position = UDim2.new(0, 12, 0, 8)
        missionName.BackgroundTransparency = 1
        missionName.Text = mission.nameAr
        missionName.TextColor3 = COLORS.Text
        missionName.Font = Enum.Font.GothamBold
        missionName.TextSize = 15
        missionName.TextXAlignment = Enum.TextXAlignment.Left
        missionName.ZIndex = 55
        missionName.Parent = card

        -- Description
        local missionDesc = Instance.new("TextLabel")
        missionDesc.Size = UDim2.new(0.7, -10, 0, 18)
        missionDesc.Position = UDim2.new(0, 12, 0, 34)
        missionDesc.BackgroundTransparency = 1
        missionDesc.Text = mission.description
        missionDesc.TextColor3 = COLORS.TextDim
        missionDesc.Font = Enum.Font.Gotham
        missionDesc.TextSize = 12
        missionDesc.TextXAlignment = Enum.TextXAlignment.Left
        missionDesc.ZIndex = 55
        missionDesc.Parent = card

        -- Progress bar
        local progressBg = Instance.new("Frame")
        progressBg.Size = UDim2.new(0.7, -20, 0, 6)
        progressBg.Position = UDim2.new(0, 12, 0, 58)
        progressBg.BackgroundColor3 = COLORS.Secondary
        progressBg.BorderSizePixel = 0
        progressBg.ZIndex = 55
        progressBg.Parent = card

        Instance.new("UICorner", progressBg).CornerRadius = UDim.new(0, 3)

        local progressFill = Instance.new("Frame")
        progressFill.Name = "Fill"
        progressFill.Size = UDim2.new(0, 0, 1, 0)
        progressFill.BackgroundColor3 = COLORS.Accent
        progressFill.BorderSizePixel = 0
        progressFill.ZIndex = 56
        progressFill.Parent = progressBg

        Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 3)

        -- Reward badge
        local rewardBadge = Instance.new("Frame")
        rewardBadge.Size = UDim2.new(0.25, 0, 0.7, 0)
        rewardBadge.Position = UDim2.new(0.97, 0, 0.5, 0)
        rewardBadge.AnchorPoint = Vector2.new(1, 0.5)
        rewardBadge.BackgroundColor3 = COLORS.Success
        rewardBadge.BackgroundTransparency = 0.8
        rewardBadge.BorderSizePixel = 0
        rewardBadge.ZIndex = 55
        rewardBadge.Parent = card

        Instance.new("UICorner", rewardBadge).CornerRadius = UDim.new(0, 8)

        local rewardLabel = Instance.new("TextLabel")
        rewardLabel.Size = UDim2.new(1, 0, 1, 0)
        rewardLabel.BackgroundTransparency = 1
        rewardLabel.Text = "💰 " .. Utils.formatCurrency(mission.reward)
        rewardLabel.TextColor3 = COLORS.Success
        rewardLabel.Font = Enum.Font.GothamBold
        rewardLabel.TextSize = 13
        rewardLabel.ZIndex = 56
        rewardLabel.Parent = rewardBadge
    end

    return gui
end

-- ═══════════════════════════════════════════════
-- ADMIN PANEL (only visible to admins)
-- ═══════════════════════════════════════════════
local function buildAdminPanel(): ScreenGui
    local gui, _panel, content = createPanel("AdminPanel", "لوحة التحكم", "🛡️")

    -- Player selector dropdown
    local selectorFrame = Instance.new("Frame")
    selectorFrame.Size = UDim2.new(1, 0, 0, 40)
    selectorFrame.BackgroundTransparency = 1
    selectorFrame.ZIndex = 53
    selectorFrame.Parent = content

    local playerDropdown = Instance.new("TextButton")
    playerDropdown.Name = "PlayerDropdown"
    playerDropdown.Size = UDim2.new(1, 0, 1, 0)
    playerDropdown.BackgroundColor3 = COLORS.CardBg
    playerDropdown.BorderSizePixel = 0
    playerDropdown.Text = "اختر لاعب..."
    playerDropdown.TextColor3 = COLORS.TextDim
    playerDropdown.Font = Enum.Font.GothamMedium
    playerDropdown.TextSize = 14
    playerDropdown.ZIndex = 54
    playerDropdown.Parent = selectorFrame

    Instance.new("UICorner", playerDropdown).CornerRadius = UDim.new(0, 10)

    local selectedUserId = nil

    -- Player list (hidden by default)
    local playerListFrame = Instance.new("ScrollingFrame")
    playerListFrame.Name = "PlayerList"
    playerListFrame.Size = UDim2.new(1, 0, 0, 120)
    playerListFrame.Position = UDim2.new(0, 0, 0, 44)
    playerListFrame.BackgroundColor3 = COLORS.CardBg
    playerListFrame.BorderSizePixel = 0
    playerListFrame.ScrollBarThickness = 3
    playerListFrame.Visible = false
    playerListFrame.ZIndex = 60
    playerListFrame.Parent = content

    Instance.new("UICorner", playerListFrame).CornerRadius = UDim.new(0, 8)

    local playerListLayout = Instance.new("UIListLayout")
    playerListLayout.Padding = UDim.new(0, 2)
    playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playerListLayout.Parent = playerListFrame

    local function refreshPlayerList()
        for _, child in ipairs(playerListFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        local list = RemoteManager:InvokeServer("GetPlayerList")
        if not list then
            return
        end
        for i, p in ipairs(list) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = COLORS.Secondary
            btn.BackgroundTransparency = 0.5
            btn.BorderSizePixel = 0
            btn.Text = p.displayName .. " (@" .. p.name .. ") - $" .. tostring(p.cash)
            btn.TextColor3 = p.isAdmin and COLORS.Gold or COLORS.Text
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 12
            btn.LayoutOrder = i
            btn.ZIndex = 61
            btn.Parent = playerListFrame

            btn.MouseButton1Click:Connect(function()
                selectedUserId = p.userId
                playerDropdown.Text = p.displayName .. " (@" .. p.name .. ")"
                playerDropdown.TextColor3 = COLORS.Text
                playerListFrame.Visible = false
            end)
        end
        playerListFrame.CanvasSize = UDim2.new(0, 0, 0, #list * 30)
    end

    playerDropdown.MouseButton1Click:Connect(function()
        playerListFrame.Visible = not playerListFrame.Visible
        if playerListFrame.Visible then
            refreshPlayerList()
        end
    end)

    -- Money amount input
    local amountInput = Instance.new("TextBox")
    amountInput.Name = "AmountInput"
    amountInput.Size = UDim2.new(0.48, 0, 0, 30)
    amountInput.Position = UDim2.new(0, 0, 0, 140)
    amountInput.BackgroundColor3 = COLORS.Secondary
    amountInput.BackgroundTransparency = 0.3
    amountInput.BorderSizePixel = 0
    amountInput.PlaceholderText = "المبلغ (مثال: 5000)"
    amountInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    amountInput.Text = ""
    amountInput.TextColor3 = COLORS.Text
    amountInput.Font = Enum.Font.GothamMedium
    amountInput.TextSize = 13
    amountInput.ZIndex = 54
    amountInput.ClearTextOnFocus = false
    amountInput.Parent = content
    Instance.new("UICorner", amountInput).CornerRadius = UDim.new(0, 8)

    -- Action buttons area
    local actionsY = 180

    -- Result label
    local resultLabel = Instance.new("TextLabel")
    resultLabel.Name = "AdminResult"
    resultLabel.Size = UDim2.new(1, 0, 0, 24)
    resultLabel.Position = UDim2.new(0, 0, 0, actionsY - 30)
    resultLabel.BackgroundTransparency = 1
    resultLabel.Text = ""
    resultLabel.TextColor3 = COLORS.Success
    resultLabel.Font = Enum.Font.GothamMedium
    resultLabel.TextSize = 13
    resultLabel.ZIndex = 54
    resultLabel.Parent = content

    RemoteManager:OnClientEvent("AdminResponse", function(data)
        if data.success then
            resultLabel.Text = data.message
            resultLabel.TextColor3 = COLORS.Success
        else
            resultLabel.Text = data.message
            resultLabel.TextColor3 = COLORS.Danger
        end
        task.delay(4, function()
            resultLabel.Text = ""
        end)
    end)

    local function makeActionBtn(text, yPos, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.48, 0, 0, 36)
        btn.Position = yPos
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.2
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = COLORS.Text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.ZIndex = 54
        btn.Parent = content
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Row 1: Give Money + Kick
    makeActionBtn("💰 إعطاء نقود", UDim2.new(0, 0, 0, actionsY), COLORS.Success, function()
        if not selectedUserId then
            resultLabel.Text = "اختر لاعب أولاً"
            resultLabel.TextColor3 = COLORS.Danger
            return
        end
        local amount = tonumber(amountInput.Text)
        if not amount or amount <= 0 then
            resultLabel.Text = "أدخل مبلغ صحيح!"
            resultLabel.TextColor3 = COLORS.Danger
            return
        end
        RemoteManager:FireServer("AdminAction", "giveMoney", {
            targetUserId = selectedUserId,
            amount = amount,
        })
    end)

    makeActionBtn("🚪 طرد", UDim2.new(0.52, 0, 0, actionsY), COLORS.Danger, function()
        if not selectedUserId then
            return
        end
        RemoteManager:FireServer("AdminAction", "kick", {
            targetUserId = selectedUserId,
            reason = "طرد بواسطة الإدارة",
        })
    end)

    -- Row 2: Temp Ban + Perm Ban
    makeActionBtn("⏱️ حظر مؤقت (30 دقيقة)", UDim2.new(0, 0, 0, actionsY + 44), Color3.fromRGB(200, 120, 0), function()
        if not selectedUserId then
            return
        end
        RemoteManager:FireServer("AdminAction", "ban", {
            targetUserId = selectedUserId,
            reason = "مخالفة القوانين",
            duration = 1800, -- 30 minutes
        })
    end)

    makeActionBtn("🚫 حظر دائم", UDim2.new(0.52, 0, 0, actionsY + 44), COLORS.Danger, function()
        if not selectedUserId then
            return
        end
        RemoteManager:FireServer("AdminAction", "ban", {
            targetUserId = selectedUserId,
            reason = "حظر دائم",
            duration = 0,
        })
    end)

    -- Row 3: Promote Job + Unban
    makeActionBtn("💼 ترقية وظيفة (شرطي)", UDim2.new(0, 0, 0, actionsY + 88), COLORS.Accent, function()
        if not selectedUserId then
            return
        end
        RemoteManager:FireServer("AdminAction", "promoteJob", {
            targetUserId = selectedUserId,
            jobId = "police",
        })
    end)

    makeActionBtn("✅ رفع الحظر", UDim2.new(0.52, 0, 0, actionsY + 88), COLORS.Success, function()
        if not selectedUserId then
            return
        end
        RemoteManager:FireServer("AdminAction", "unban", {
            targetUserId = selectedUserId,
        })
    end)

    -- Row 4: Promote Admin + Demote Admin
    makeActionBtn("👑 ترقية أدمن", UDim2.new(0, 0, 0, actionsY + 132), COLORS.Gold, function()
        if not selectedUserId then
            return
        end
        RemoteManager:FireServer("AdminAction", "promoteAdmin", {
            targetUserId = selectedUserId,
        })
    end)

    makeActionBtn("⬇️ إزالة أدمن", UDim2.new(0.52, 0, 0, actionsY + 132), Color3.fromRGB(120, 80, 80), function()
        if not selectedUserId then
            return
        end
        RemoteManager:FireServer("AdminAction", "demoteAdmin", {
            targetUserId = selectedUserId,
        })
    end)

    return gui
end

-- ═══════════════════════════════════════════════
-- CHAT PANEL (public + private messaging)
-- ═══════════════════════════════════════════════
local function buildChatPanel(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ChatPanel"
    gui.DisplayOrder = 85
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = true

    -- Chat container (bottom-left)
    local chatFrame = Instance.new("Frame")
    chatFrame.Name = "ChatFrame"
    chatFrame.Size = UDim2.new(0.3, 0, 0.4, 0)
    chatFrame.Position = UDim2.new(0, 10, 1, -10)
    chatFrame.AnchorPoint = Vector2.new(0, 1)
    chatFrame.BackgroundColor3 = COLORS.Primary
    chatFrame.BackgroundTransparency = 0.15
    chatFrame.BorderSizePixel = 0
    chatFrame.ZIndex = 40
    chatFrame.Parent = gui

    Instance.new("UICorner", chatFrame).CornerRadius = UDim.new(0, 12)

    local chatStroke = Instance.new("UIStroke")
    chatStroke.Color = COLORS.Accent
    chatStroke.Thickness = 1
    chatStroke.Transparency = 0.5
    chatStroke.Parent = chatFrame

    -- Tab bar (public / private)
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 32)
    tabBar.BackgroundColor3 = COLORS.Secondary
    tabBar.BackgroundTransparency = 0.3
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex = 41
    tabBar.Parent = chatFrame

    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 12)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Parent = tabBar

    local activeTab = "public"

    local publicTab = Instance.new("TextButton")
    publicTab.Size = UDim2.new(0.5, 0, 1, 0)
    publicTab.BackgroundColor3 = COLORS.Accent
    publicTab.BackgroundTransparency = 0.3
    publicTab.BorderSizePixel = 0
    publicTab.Text = "💬 عام"
    publicTab.TextColor3 = COLORS.Text
    publicTab.Font = Enum.Font.GothamBold
    publicTab.TextSize = 13
    publicTab.ZIndex = 42
    publicTab.Parent = tabBar

    local privateTab = Instance.new("TextButton")
    privateTab.Size = UDim2.new(0.5, 0, 1, 0)
    privateTab.BackgroundColor3 = COLORS.CardBg
    privateTab.BackgroundTransparency = 0.5
    privateTab.BorderSizePixel = 0
    privateTab.Text = "📩 خاص"
    privateTab.TextColor3 = COLORS.TextDim
    privateTab.Font = Enum.Font.GothamBold
    privateTab.TextSize = 13
    privateTab.ZIndex = 42
    privateTab.Parent = tabBar

    -- Messages scroll
    local messagesScroll = Instance.new("ScrollingFrame")
    messagesScroll.Name = "Messages"
    messagesScroll.Size = UDim2.new(1, -8, 1, -74)
    messagesScroll.Position = UDim2.new(0, 4, 0, 34)
    messagesScroll.BackgroundTransparency = 1
    messagesScroll.ScrollBarThickness = 3
    messagesScroll.ScrollBarImageColor3 = COLORS.Accent
    messagesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    messagesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    messagesScroll.ZIndex = 41
    messagesScroll.Parent = chatFrame

    local messagesLayout = Instance.new("UIListLayout")
    messagesLayout.Padding = UDim.new(0, 3)
    messagesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    messagesLayout.Parent = messagesScroll

    -- Private player selector (hidden by default)
    local privateSelector = Instance.new("Frame")
    privateSelector.Name = "PrivateSelector"
    privateSelector.Size = UDim2.new(1, -8, 0, 28)
    privateSelector.Position = UDim2.new(0, 4, 0, 34)
    privateSelector.BackgroundColor3 = COLORS.CardBg
    privateSelector.BorderSizePixel = 0
    privateSelector.Visible = false
    privateSelector.ZIndex = 43
    privateSelector.Parent = chatFrame

    Instance.new("UICorner", privateSelector).CornerRadius = UDim.new(0, 6)

    local privateTo = Instance.new("TextButton")
    privateTo.Size = UDim2.new(1, 0, 1, 0)
    privateTo.BackgroundTransparency = 1
    privateTo.Text = "اختر لاعب للمراسلة..."
    privateTo.TextColor3 = COLORS.TextDim
    privateTo.Font = Enum.Font.GothamMedium
    privateTo.TextSize = 12
    privateTo.ZIndex = 44
    privateTo.Parent = privateSelector

    local privateTargetId = nil

    -- Input area
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -8, 0, 34)
    inputFrame.Position = UDim2.new(0, 4, 1, -38)
    inputFrame.BackgroundTransparency = 1
    inputFrame.ZIndex = 41
    inputFrame.Parent = chatFrame

    local chatInput = Instance.new("TextBox")
    chatInput.Size = UDim2.new(0.78, 0, 1, 0)
    chatInput.BackgroundColor3 = COLORS.CardBg
    chatInput.BorderSizePixel = 0
    chatInput.PlaceholderText = "اكتب رسالتك..."
    chatInput.PlaceholderColor3 = COLORS.TextDim
    chatInput.Text = ""
    chatInput.TextColor3 = COLORS.Text
    chatInput.Font = Enum.Font.GothamMedium
    chatInput.TextSize = 13
    chatInput.ClearTextOnFocus = false
    chatInput.ZIndex = 42
    chatInput.Parent = inputFrame

    Instance.new("UICorner", chatInput).CornerRadius = UDim.new(0, 8)
    local chatPadding = Instance.new("UIPadding")
    chatPadding.PaddingLeft = UDim.new(0, 8)
    chatPadding.PaddingRight = UDim.new(0, 8)
    chatPadding.Parent = chatInput

    local sendBtn = Instance.new("TextButton")
    sendBtn.Size = UDim2.new(0.2, 0, 1, 0)
    sendBtn.Position = UDim2.new(0.8, 0, 0, 0)
    sendBtn.BackgroundColor3 = COLORS.Accent
    sendBtn.BorderSizePixel = 0
    sendBtn.Text = "إرسال"
    sendBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    sendBtn.Font = Enum.Font.GothamBold
    sendBtn.TextSize = 13
    sendBtn.ZIndex = 42
    sendBtn.Parent = inputFrame

    Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 8)

    local _messageOrder = 0

    local function addMessageBubble(entry)
        _messageOrder += 1
        local bubble = Instance.new("TextLabel")
        bubble.Size = UDim2.new(1, 0, 0, 0)
        bubble.AutomaticSize = Enum.AutomaticSize.Y
        bubble.BackgroundTransparency = 1
        bubble.TextWrapped = true
        bubble.RichText = true
        bubble.TextXAlignment = Enum.TextXAlignment.Left
        bubble.Font = Enum.Font.Gotham
        bubble.TextSize = 12
        bubble.ZIndex = 42
        bubble.LayoutOrder = _messageOrder
        bubble.Parent = messagesScroll

        local senderColor = "rgb(100,200,255)"
        if entry.isAdmin then
            senderColor = "rgb(255,215,0)"
        elseif entry.isSystem then
            senderColor = "rgb(200,200,200)"
        end

        bubble.Text = '<font color="' .. senderColor .. '"><b>' .. (entry.senderDisplay or entry.sender or "???") .. ':</b></font> ' .. (entry.message or "")
        bubble.TextColor3 = COLORS.Text

        -- Auto-scroll to bottom
        task.defer(function()
            messagesScroll.CanvasPosition = Vector2.new(0, messagesScroll.AbsoluteCanvasSize.Y)
        end)
    end

    -- Send message
    local function sendMessage()
        local msg = chatInput.Text
        if msg == "" then
            return
        end
        chatInput.Text = ""

        if activeTab == "public" then
            RemoteManager:FireServer("ChatSendPublic", msg)
        else
            if privateTargetId then
                RemoteManager:FireServer("ChatSendPrivate", privateTargetId, msg)
            end
        end
    end

    sendBtn.MouseButton1Click:Connect(sendMessage)
    chatInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            sendMessage()
        end
    end)

    -- Tab switching
    publicTab.MouseButton1Click:Connect(function()
        activeTab = "public"
        publicTab.BackgroundTransparency = 0.3
        publicTab.TextColor3 = COLORS.Text
        privateTab.BackgroundTransparency = 0.7
        privateTab.TextColor3 = COLORS.TextDim
        privateSelector.Visible = false
        messagesScroll.Position = UDim2.new(0, 4, 0, 34)
        messagesScroll.Size = UDim2.new(1, -8, 1, -74)

        -- Clear and reload public history
        for _, child in ipairs(messagesScroll:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        _messageOrder = 0
        local history = RemoteManager:InvokeServer("GetChatHistory")
        if history then
            for _, entry in ipairs(history) do
                addMessageBubble(entry)
            end
        end
    end)

    privateTab.MouseButton1Click:Connect(function()
        activeTab = "private"
        privateTab.BackgroundTransparency = 0.3
        privateTab.TextColor3 = COLORS.Text
        publicTab.BackgroundTransparency = 0.7
        publicTab.TextColor3 = COLORS.TextDim
        privateSelector.Visible = true
        messagesScroll.Position = UDim2.new(0, 4, 0, 64)
        messagesScroll.Size = UDim2.new(1, -8, 1, -104)

        -- Clear messages
        for _, child in ipairs(messagesScroll:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        _messageOrder = 0
    end)

    -- Private player selector
    privateTo.MouseButton1Click:Connect(function()
        local onlinePlayers = RemoteManager:InvokeServer("GetOnlinePlayers")
        if not onlinePlayers or #onlinePlayers == 0 then
            privateTo.Text = "لا يوجد لاعبين متصلين"
            return
        end

        -- Cycle through players
        local current = nil
        for idx, p in ipairs(onlinePlayers) do
            if p.userId == privateTargetId then
                current = idx
                break
            end
        end

        local nextIdx = (current or 0) % #onlinePlayers + 1
        local nextPlayer = onlinePlayers[nextIdx]
        privateTargetId = nextPlayer.userId
        privateTo.Text = "إلى: " .. nextPlayer.displayName .. " (@" .. nextPlayer.name .. ")"
        privateTo.TextColor3 = COLORS.Accent

        -- Load private chat history
        for _, child in ipairs(messagesScroll:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        _messageOrder = 0
        local history = RemoteManager:InvokeServer("GetPrivateChat", privateTargetId)
        if history then
            for _, entry in ipairs(history) do
                addMessageBubble(entry)
            end
        end
    end)

    -- Listen for public messages
    RemoteManager:OnClientEvent("ChatPublicMessage", function(entry)
        if activeTab == "public" then
            addMessageBubble(entry)
        end
    end)

    -- Listen for private messages
    RemoteManager:OnClientEvent("ChatPrivateMessage", function(entry)
        if activeTab == "private" then
            addMessageBubble(entry)
        end
    end)

    return gui
end

-- ═══════════════════════════════════════════════
-- NOTIFICATION SYSTEM (toasts)
-- ═══════════════════════════════════════════════
local function buildNotificationSystem(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "NotificationSystem"
    gui.DisplayOrder = 100
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = true

    local notifContainer = Instance.new("Frame")
    notifContainer.Name = "Notifications"
    notifContainer.Size = UDim2.new(0.3, 0, 0.5, 0)
    notifContainer.Position = UDim2.new(1, -10, 0, 80)
    notifContainer.AnchorPoint = Vector2.new(1, 0)
    notifContainer.BackgroundTransparency = 1
    notifContainer.ZIndex = 200
    notifContainer.Parent = gui

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.Padding = UDim.new(0, 6)
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    notifLayout.Parent = notifContainer

    local _notifOrder = 0

    local function showNotification(title, message, color, duration)
        _notifOrder += 1
        color = color or COLORS.Accent
        duration = duration or 4

        local toast = Instance.new("Frame")
        toast.Size = UDim2.new(1, 0, 0, 60)
        toast.BackgroundColor3 = COLORS.Primary
        toast.BorderSizePixel = 0
        toast.LayoutOrder = _notifOrder
        toast.ZIndex = 201
        toast.Parent = notifContainer

        Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 10)

        local toastStroke = Instance.new("UIStroke")
        toastStroke.Color = color
        toastStroke.Thickness = 1.5
        toastStroke.Parent = toast

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -16, 0, 22)
        titleLabel.Position = UDim2.new(0, 8, 0, 6)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = color
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 14
        titleLabel.TextXAlignment = Enum.TextXAlignment.Right
        titleLabel.ZIndex = 202
        titleLabel.Parent = toast

        local msgLabel = Instance.new("TextLabel")
        msgLabel.Size = UDim2.new(1, -16, 0, 22)
        msgLabel.Position = UDim2.new(0, 8, 0, 30)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = message
        msgLabel.TextColor3 = COLORS.Text
        msgLabel.Font = Enum.Font.GothamMedium
        msgLabel.TextSize = 12
        msgLabel.TextXAlignment = Enum.TextXAlignment.Right
        msgLabel.ZIndex = 202
        msgLabel.Parent = toast

        -- Slide in
        toast.Position = UDim2.new(1, 0, 0, 0)
        TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()

        -- Auto remove
        task.delay(duration, function()
            TweenService:Create(toast, TweenInfo.new(0.3), {
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
            }):Play()
            task.delay(0.35, function()
                toast:Destroy()
            end)
        end)
    end

    -- Welcome bonus notification
    RemoteManager:OnClientEvent("WelcomeBonus", function(amount)
        showNotification(
            "🎉 مرحباً بك في Arab City!",
            "حصلت على مكافأة ترحيبية: $" .. tostring(amount),
            COLORS.Gold,
            6
        )
    end)

    -- Badge awarded notification
    RemoteManager:OnClientEvent("BadgeAwarded", function(data)
        showNotification(
            "🏆 إنجاز جديد!",
            data.nameAr .. " - " .. data.description,
            COLORS.Gold,
            5
        )
    end)

    -- Building action notifications
    RemoteManager:OnClientEvent("BuildingAction", function(data)
        if data.type == "notification" then
            showNotification(data.title, data.message, COLORS.Accent, 4)
        elseif data.type == "bank_info" then
            showNotification(
                "🏦 البنك المركزي",
                "رصيدك: $" .. tostring(data.balance) .. " | إجمالي: $" .. tostring(data.totalEarned),
                COLORS.Gold,
                5
            )
        elseif data.type == "job_offer" then
            showNotification(
                "💼 " .. data.jobName,
                data.description .. " - الراتب: $" .. tostring(data.salary),
                COLORS.Accent,
                5
            )
        elseif data.type == "property_info" then
            local msg = data.nameAr .. "\nالسعر: $" .. tostring(data.price) .. " | غرف: " .. tostring(data.rooms)
            if data.ownedByPlayer then
                msg = msg .. "\n(ملكك)"
            elseif data.owned then
                msg = msg .. "\n(مباع)"
            end
            showNotification("🏠 عقار", msg, COLORS.Gold, 5)
        elseif data.type == "open_panel" then
            local panel = player.PlayerGui:FindFirstChild(data.panel)
            if panel then
                panel.Enabled = true
            end
        end
    end)

    -- Admin status notification
    RemoteManager:OnClientEvent("AdminStatus", function(isAdmin)
        if isAdmin then
            showNotification("🛡️ أدمن", "تم تفعيل صلاحيات الأدمن!", COLORS.Gold, 5)
        end
    end)

    return gui, showNotification
end

-- ═══════════════════════════════════════════════
-- INITIALIZE ALL PANELS
-- ═══════════════════════════════════════════════
local codesGui = buildCodesPanel()
codesGui.Parent = playerGui

local shopGui = buildShopPanel()
shopGui.Parent = playerGui

local inventoryGui = buildInventoryPanel()
inventoryGui.Parent = playerGui

local missionsGui = buildMissionsPanel()
missionsGui.Parent = playerGui

local adminGui = buildAdminPanel()
adminGui.Enabled = false
adminGui.Parent = playerGui

local chatGui = buildChatPanel()
chatGui.Parent = playerGui

local notifGui = buildNotificationSystem()
notifGui.Parent = playerGui

-- Listen for mission progress updates
RemoteManager:OnClientEvent("MissionProgress", function(missionId, current, target)
    local missionsPanel = missionsGui:FindFirstChild("Panel")
    if not missionsPanel then
        return
    end
    local contentFrame = missionsPanel:FindFirstChild("Content")
    if not contentFrame then
        return
    end
    local scroll = contentFrame:FindFirstChild("MissionsList")
    if not scroll then
        return
    end
    local card = scroll:FindFirstChild("Mission_" .. missionId)
    if not card then
        return
    end

    -- Find progress bar fill
    for _, desc in ipairs(card:GetDescendants()) do
        if desc.Name == "Fill" and desc:IsA("Frame") then
            local ratio = math.clamp(current / math.max(target, 1), 0, 1)
            TweenService:Create(desc, TweenInfo.new(0.4), {
                Size = UDim2.new(ratio, 0, 1, 0),
            }):Play()

            if ratio >= 1 then
                desc.BackgroundColor3 = COLORS.Success
            end
            break
        end
    end
end)

-- Check admin status and enable admin panel button
task.spawn(function()
    task.wait(3)
    local isAdmin = RemoteManager:InvokeServer("IsAdmin")
    if isAdmin then
        adminGui.Enabled = false -- Start hidden, toggle from HUD
    end
end)

return GUIModule
