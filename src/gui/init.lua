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

    -- Redeem action
    redeemBtn.MouseButton1Click:Connect(function()
        local code = codeInput.Text
        if code == "" then
            return
        end
        redeemBtn.Text = "..."
        local result = RemoteManager:InvokeServer("RedeemCode", code)
        if result and result.success then
            resultLabel.Text = "تم استخدام الكود بنجاح! " .. (result.rewardText or "")
            resultLabel.TextColor3 = COLORS.Success
        else
            resultLabel.Text = result and result.message or "كود غير صالح"
            resultLabel.TextColor3 = COLORS.Danger
        end
        redeemBtn.Text = "استخدم"
        codeInput.Text = ""
        task.delay(4, function()
            resultLabel.Text = ""
        end)
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
            RemoteManager:FireServer("BuyVehicle", vehicle.id)
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

return GUIModule
