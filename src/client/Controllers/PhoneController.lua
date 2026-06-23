--[[
    Arab City - Virtual Phone System
    Apps: Camera, Photos, Messages, Maps, Settings, Social Network, Real Estate
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PhoneController = {}
PhoneController._isOpen = false
PhoneController._currentApp = nil

local COLORS = Constants.COLORS
local PHONE_WIDTH = 280
local PHONE_HEIGHT = 500

local APPS = {
    { id = "camera",     icon = "📷", nameAr = "الكاميرا",          color = Color3.fromRGB(80, 80, 80) },
    { id = "photos",     icon = "🖼️", nameAr = "الصور",             color = Color3.fromRGB(255, 100, 100) },
    { id = "messages",   icon = "💬", nameAr = "الرسائل",           color = Color3.fromRGB(0, 200, 83) },
    { id = "maps",       icon = "🗺️", nameAr = "الخرائط",           color = Color3.fromRGB(0, 150, 255) },
    { id = "social",     icon = "🌐", nameAr = "Social Network",   color = Color3.fromRGB(100, 0, 255) },
    { id = "realestate", icon = "🏠", nameAr = "العقارات",          color = Color3.fromRGB(255, 165, 0) },
    { id = "settings",   icon = "⚙️", nameAr = "الإعدادات",         color = Color3.fromRGB(120, 120, 130) },
    { id = "contacts",   icon = "👥", nameAr = "جهات الاتصال",     color = Color3.fromRGB(0, 200, 200) },
}

function PhoneController:Init()
    self._gui = self:_buildPhoneUI()
    self._gui.Enabled = false
    self._gui.Parent = playerGui

    RemoteManager:OnClientEvent("ReceiveMessage", function(senderName, content)
        self:_onMessageReceived(senderName, content)
    end)
end

function PhoneController:Toggle()
    if self._isOpen then
        self:Close()
    else
        self:Open()
    end
end

function PhoneController:Open()
    if self._isOpen then
        return
    end
    self._isOpen = true
    self._gui.Enabled = true

    -- Slide in animation
    self._phoneFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
    TweenService:Create(self._phoneFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0),
    }):Play()

    -- Show home screen
    self:_showHomeScreen()
end

function PhoneController:Close()
    if not self._isOpen then
        return
    end

    TweenService:Create(self._phoneFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 1.5, 0),
    }):Play()

    task.delay(0.3, function()
        self._isOpen = false
        self._gui.Enabled = false
        self._currentApp = nil
    end)
end

function PhoneController:_buildPhoneUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_Phone"
    gui.DisplayOrder = 80
    gui.ResetOnSpawn = false

    -- Dim overlay
    local overlay = Instance.new("TextButton")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Text = ""
    overlay.ZIndex = 70
    overlay.Parent = gui

    overlay.MouseButton1Click:Connect(function()
        self:Close()
    end)

    -- Phone frame
    local phoneFrame = Instance.new("Frame")
    phoneFrame.Name = "PhoneFrame"
    phoneFrame.Size = UDim2.new(0, PHONE_WIDTH, 0, PHONE_HEIGHT)
    phoneFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    phoneFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    phoneFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    phoneFrame.BorderSizePixel = 0
    phoneFrame.ZIndex = 71
    phoneFrame.Parent = gui
    self._phoneFrame = phoneFrame

    local phoneCorner = Instance.new("UICorner")
    phoneCorner.CornerRadius = UDim.new(0, 20)
    phoneCorner.Parent = phoneFrame

    local phoneStroke = Instance.new("UIStroke")
    phoneStroke.Color = Color3.fromRGB(60, 60, 70)
    phoneStroke.Thickness = 2
    phoneStroke.Parent = phoneFrame

    -- Status bar (time, battery, signal)
    local statusBar = Instance.new("Frame")
    statusBar.Name = "StatusBar"
    statusBar.Size = UDim2.new(1, 0, 0, 30)
    statusBar.BackgroundTransparency = 1
    statusBar.ZIndex = 72
    statusBar.Parent = phoneFrame

    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0.5, 0, 1, 0)
    timeLabel.Position = UDim2.new(0, 15, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "12:00"
    timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeLabel.Font = Enum.Font.GothamBold
    timeLabel.TextSize = 13
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.ZIndex = 73
    timeLabel.Parent = statusBar
    self._timeLabel = timeLabel

    local batteryLabel = Instance.new("TextLabel")
    batteryLabel.Size = UDim2.new(0.5, -15, 1, 0)
    batteryLabel.Position = UDim2.new(0.5, 0, 0, 0)
    batteryLabel.BackgroundTransparency = 1
    batteryLabel.Text = "🔋 100%"
    batteryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    batteryLabel.Font = Enum.Font.Gotham
    batteryLabel.TextSize = 12
    batteryLabel.TextXAlignment = Enum.TextXAlignment.Right
    batteryLabel.ZIndex = 73
    batteryLabel.Parent = statusBar

    -- Content area (where app screens appear)
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -80)
    contentArea.Position = UDim2.new(0.5, 0, 0, 35)
    contentArea.AnchorPoint = Vector2.new(0.5, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.ZIndex = 72
    contentArea.Parent = phoneFrame
    self._contentArea = contentArea

    -- Home button (bottom of phone)
    local homeBtn = Instance.new("TextButton")
    homeBtn.Name = "HomeButton"
    homeBtn.Size = UDim2.new(0, 40, 0, 6)
    homeBtn.Position = UDim2.new(0.5, 0, 1, -18)
    homeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    homeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
    homeBtn.BorderSizePixel = 0
    homeBtn.Text = ""
    homeBtn.ZIndex = 73
    homeBtn.Parent = phoneFrame

    Instance.new("UICorner", homeBtn).CornerRadius = UDim.new(1, 0)

    homeBtn.MouseButton1Click:Connect(function()
        self:_showHomeScreen()
    end)

    -- Update clock
    task.spawn(function()
        while gui.Parent do
            local now = os.date("*t")
            if self._timeLabel then
                self._timeLabel.Text = string.format("%02d:%02d", now.hour, now.min)
            end
            task.wait(30)
        end
    end)

    return gui
end

function PhoneController:_clearContent()
    for _, child in ipairs(self._contentArea:GetChildren()) do
        child:Destroy()
    end
end

function PhoneController:_showHomeScreen()
    self._currentApp = nil
    self:_clearContent()

    -- Greeting
    local greeting = Instance.new("TextLabel")
    greeting.Name = "Greeting"
    greeting.Size = UDim2.new(1, 0, 0, 35)
    greeting.BackgroundTransparency = 1
    greeting.Text = `مرحباً، {player.DisplayName}`
    greeting.TextColor3 = Color3.fromRGB(255, 255, 255)
    greeting.Font = Enum.Font.GothamBold
    greeting.TextSize = 16
    greeting.ZIndex = 73
    greeting.Parent = self._contentArea

    -- App grid
    local grid = Instance.new("Frame")
    grid.Name = "AppGrid"
    grid.Size = UDim2.new(1, 0, 1, -45)
    grid.Position = UDim2.new(0, 0, 0, 40)
    grid.BackgroundTransparency = 1
    grid.ZIndex = 73
    grid.Parent = self._contentArea

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 60, 0, 75)
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = grid

    for i, app in ipairs(APPS) do
        local appBtn = Instance.new("TextButton")
        appBtn.Name = "App_" .. app.id
        appBtn.BackgroundTransparency = 1
        appBtn.Text = ""
        appBtn.LayoutOrder = i
        appBtn.ZIndex = 74
        appBtn.Parent = grid

        local iconFrame = Instance.new("Frame")
        iconFrame.Size = UDim2.new(0, 48, 0, 48)
        iconFrame.Position = UDim2.new(0.5, 0, 0, 0)
        iconFrame.AnchorPoint = Vector2.new(0.5, 0)
        iconFrame.BackgroundColor3 = app.color
        iconFrame.BorderSizePixel = 0
        iconFrame.ZIndex = 75
        iconFrame.Parent = appBtn

        Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(0, 12)

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = app.icon
        iconLabel.TextSize = 24
        iconLabel.ZIndex = 76
        iconLabel.Parent = iconFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0, 20)
        nameLabel.Position = UDim2.new(0, 0, 1, -22)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = app.nameAr
        nameLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 10
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.ZIndex = 75
        nameLabel.Parent = appBtn

        appBtn.MouseButton1Click:Connect(function()
            self:_openApp(app.id)
        end)
    end
end

function PhoneController:_openApp(appId: string)
    self._currentApp = appId
    self:_clearContent()

    -- App header with back button
    local header = Instance.new("Frame")
    header.Name = "AppHeader"
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    header.BorderSizePixel = 0
    header.ZIndex = 73
    header.Parent = self._contentArea

    local backBtn = Instance.new("TextButton")
    backBtn.Size = UDim2.new(0, 30, 0, 30)
    backBtn.Position = UDim2.new(0, 5, 0.5, 0)
    backBtn.AnchorPoint = Vector2.new(0, 0.5)
    backBtn.BackgroundTransparency = 1
    backBtn.Text = "◀"
    backBtn.TextColor3 = COLORS.Accent
    backBtn.Font = Enum.Font.GothamBold
    backBtn.TextSize = 18
    backBtn.ZIndex = 74
    backBtn.Parent = header

    backBtn.MouseButton1Click:Connect(function()
        self:_showHomeScreen()
    end)

    local appName = ""
    for _, app in ipairs(APPS) do
        if app.id == appId then
            appName = app.nameAr
            break
        end
    end

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -70, 1, 0)
    titleLabel.Position = UDim2.new(0.5, 0, 0, 0)
    titleLabel.AnchorPoint = Vector2.new(0.5, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = appName
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.ZIndex = 74
    titleLabel.Parent = header

    -- App content area
    local appContent = Instance.new("ScrollingFrame")
    appContent.Name = "AppContent"
    appContent.Size = UDim2.new(1, 0, 1, -40)
    appContent.Position = UDim2.new(0, 0, 0, 38)
    appContent.BackgroundTransparency = 1
    appContent.ScrollBarThickness = 3
    appContent.ScrollBarImageColor3 = COLORS.Accent
    appContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    appContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    appContent.ZIndex = 73
    appContent.Parent = self._contentArea

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = appContent

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 5)
    contentPadding.PaddingLeft = UDim.new(0, 5)
    contentPadding.PaddingRight = UDim.new(0, 5)
    contentPadding.Parent = appContent

    -- Build app-specific content
    if appId == "camera" then
        self:_buildCameraApp(appContent)
    elseif appId == "photos" then
        self:_buildPhotosApp(appContent)
    elseif appId == "messages" then
        self:_buildMessagesApp(appContent)
    elseif appId == "maps" then
        self:_buildMapsApp(appContent)
    elseif appId == "social" then
        self:_buildSocialApp(appContent)
    elseif appId == "realestate" then
        self:_buildRealEstateApp(appContent)
    elseif appId == "settings" then
        self:_buildSettingsApp(appContent)
    elseif appId == "contacts" then
        self:_buildContactsApp(appContent)
    end
end

function PhoneController:_createInfoCard(parent: ScrollingFrame, title: string, value: string, order: number)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 40)
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 74
    card.Parent = parent

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0.5, 0, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(150, 150, 160)
    titleLbl.Font = Enum.Font.Gotham
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 75
    titleLbl.Parent = card

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0.5, -10, 1, 0)
    valueLbl.Position = UDim2.new(0.5, 0, 0, 0)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = value
    valueLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLbl.Font = Enum.Font.GothamBold
    valueLbl.TextSize = 13
    valueLbl.TextXAlignment = Enum.TextXAlignment.Right
    valueLbl.ZIndex = 75
    valueLbl.Parent = card

    return card
end

function PhoneController:_createActionButton(parent: ScrollingFrame, text: string, color: Color3, order: number, callback: () -> ())
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.LayoutOrder = order
    btn.ZIndex = 74
    btn.Parent = parent

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

function PhoneController:_buildCameraApp(parent: ScrollingFrame)
    local data = RemoteManager:InvokeServer("GetPlayerData")
    local cameraType = data and data.cameraType or "Beginner"
    local cameraData = Constants.CAMERAS[cameraType]

    self:_createInfoCard(parent, "الكاميرا الحالية", cameraData and cameraData.nameAr or "مبتدئ", 1)
    self:_createInfoCard(parent, "جودة الصور", `x{cameraData and cameraData.qualityMultiplier or 1}`, 2)
    self:_createInfoCard(parent, "معزز المشاهدات", `x{cameraData and cameraData.viewBoost or 1}`, 3)

    self:_createActionButton(parent, "📸 التقاط صورة", COLORS.Accent, 4, function()
        RemoteManager:FireServer("TakePhoto")
    end)

    -- Camera upgrade options
    local upgradeHeader = Instance.new("TextLabel")
    upgradeHeader.Size = UDim2.new(1, 0, 0, 25)
    upgradeHeader.BackgroundTransparency = 1
    upgradeHeader.Text = "ترقية الكاميرا"
    upgradeHeader.TextColor3 = COLORS.Gold
    upgradeHeader.Font = Enum.Font.GothamBold
    upgradeHeader.TextSize = 14
    upgradeHeader.LayoutOrder = 5
    upgradeHeader.ZIndex = 74
    upgradeHeader.Parent = parent

    local order = 6
    for name, cam in pairs(Constants.CAMERAS) do
        if name ~= cameraType and cam.price > 0 then
            self:_createActionButton(
                parent,
                `{cam.nameAr} - {cam.price}$`,
                Color3.fromRGB(60, 60, 80),
                order,
                function()
                    RemoteManager:FireServer("RequestPurchase", "camera", cam.id)
                end
            )
            order += 1
        end
    end
end

function PhoneController:_buildPhotosApp(parent: ScrollingFrame)
    local data = RemoteManager:InvokeServer("GetPlayerData")
    local photoCount = data and data.photosTaken or 0

    self:_createInfoCard(parent, "عدد الصور", tostring(photoCount), 1)

    local placeholder = Instance.new("TextLabel")
    placeholder.Size = UDim2.new(1, 0, 0, 60)
    placeholder.BackgroundTransparency = 1
    placeholder.Text = "📷 صورك ستظهر هنا"
    placeholder.TextColor3 = Color3.fromRGB(120, 120, 130)
    placeholder.Font = Enum.Font.Gotham
    placeholder.TextSize = 14
    placeholder.LayoutOrder = 2
    placeholder.ZIndex = 74
    placeholder.Parent = parent
end

function PhoneController:_buildMessagesApp(parent: ScrollingFrame)
    local messages = RemoteManager:InvokeServer("GetMessages") or {}

    if #messages == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = "💬 لا توجد رسائل"
        empty.TextColor3 = Color3.fromRGB(120, 120, 130)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 14
        empty.LayoutOrder = 1
        empty.ZIndex = 74
        empty.Parent = parent
    else
        for i, msg in ipairs(messages) do
            self:_createInfoCard(parent, msg.from or "مجهول", msg.content or "", i)
        end
    end
end

function PhoneController:_buildMapsApp(parent: ScrollingFrame)
    for i, loc in ipairs(Constants.MAP_LOCATIONS) do
        self:_createActionButton(
            parent,
            `{loc.icon} {loc.nameAr}`,
            Color3.fromRGB(40, 40, 55),
            i,
            function()
                -- Trigger map marker highlight
            end
        )
    end
end

function PhoneController:_buildSocialApp(parent: ScrollingFrame)
    self:_createActionButton(parent, "📰 عرض الخلاصة", COLORS.Accent, 1, function()
        -- Open social network feed
        if self._onSocialOpen then
            self._onSocialOpen()
        end
    end)

    self:_createActionButton(parent, "📝 نشر منشور جديد", Color3.fromRGB(100, 0, 200), 2, function()
        if self._onSocialPost then
            self._onSocialPost()
        end
    end)

    self:_createActionButton(parent, "👤 ملفي الشخصي", Color3.fromRGB(50, 50, 70), 3, function()
        if self._onSocialProfile then
            self._onSocialProfile()
        end
    end)

    self:_createActionButton(parent, "🏆 الأكثر شهرة", Color3.fromRGB(255, 165, 0), 4, function()
        if self._onSocialLeaderboard then
            self._onSocialLeaderboard()
        end
    end)
end

function PhoneController:_buildRealEstateApp(parent: ScrollingFrame)
    local properties = RemoteManager:InvokeServer("GetPropertyList") or {}

    self:_createActionButton(parent, "🏠 عرض العقارات المتاحة", COLORS.Accent, 0, function()
        -- Scroll to list below
    end)

    local order = 1
    for _, prop in pairs(properties) do
        local statusText = prop.forSale and "متاح" or "مباع"
        local priceText = Shared.Utils.formatCurrency(prop.askingPrice or prop.price)

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 70)
        card.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        card.BorderSizePixel = 0
        card.LayoutOrder = order
        card.ZIndex = 74
        card.Parent = parent

        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -10, 0, 20)
        nameLbl.Position = UDim2.new(0, 8, 0, 5)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = prop.nameAr or prop.id
        nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 13
        nameLbl.TextXAlignment = Enum.TextXAlignment.Right
        nameLbl.ZIndex = 75
        nameLbl.Parent = card

        local detailsLbl = Instance.new("TextLabel")
        detailsLbl.Size = UDim2.new(1, -10, 0, 15)
        detailsLbl.Position = UDim2.new(0, 8, 0, 26)
        detailsLbl.BackgroundTransparency = 1
        detailsLbl.Text = `{prop.rooms or "?"} غرف | {prop.area or "?"}م² | {priceText}`
        detailsLbl.TextColor3 = Color3.fromRGB(150, 150, 160)
        detailsLbl.Font = Enum.Font.Gotham
        detailsLbl.TextSize = 11
        detailsLbl.TextXAlignment = Enum.TextXAlignment.Right
        detailsLbl.ZIndex = 75
        detailsLbl.Parent = card

        local statusLbl = Instance.new("TextLabel")
        statusLbl.Size = UDim2.new(0, 50, 0, 18)
        statusLbl.Position = UDim2.new(0, 8, 1, -25)
        statusLbl.BackgroundColor3 = prop.forSale and COLORS.Success or COLORS.Danger
        statusLbl.BackgroundTransparency = 0.3
        statusLbl.Text = statusText
        statusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.TextSize = 10
        statusLbl.ZIndex = 75
        statusLbl.Parent = card

        Instance.new("UICorner", statusLbl).CornerRadius = UDim.new(0, 4)

        if prop.forSale then
            local buyBtn = Instance.new("TextButton")
            buyBtn.Size = UDim2.new(0, 50, 0, 18)
            buyBtn.Position = UDim2.new(1, -58, 1, -25)
            buyBtn.BackgroundColor3 = COLORS.Accent
            buyBtn.BorderSizePixel = 0
            buyBtn.Text = "شراء"
            buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            buyBtn.Font = Enum.Font.GothamBold
            buyBtn.TextSize = 10
            buyBtn.ZIndex = 75
            buyBtn.Parent = card

            Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 4)

            buyBtn.MouseButton1Click:Connect(function()
                RemoteManager:FireServer("BuyProperty", prop.id)
            end)
        end

        order += 1
    end
end

function PhoneController:_buildSettingsApp(parent: ScrollingFrame)
    self:_createInfoCard(parent, "اللاعب", player.DisplayName, 1)
    self:_createInfoCard(parent, "الإصدار", Constants.VERSION, 2)

    self:_createActionButton(parent, "🔊 الموسيقى: تشغيل", Color3.fromRGB(50, 50, 65), 3, function()
        -- Toggle music
    end)

    self:_createActionButton(parent, "🔔 الإشعارات: تشغيل", Color3.fromRGB(50, 50, 65), 4, function()
        -- Toggle notifications
    end)
end

function PhoneController:_buildContactsApp(parent: ScrollingFrame)
    local players = Players:GetPlayers()
    for i, p in ipairs(players) do
        if p ~= player then
            self:_createActionButton(
                parent,
                `👤 {p.DisplayName}`,
                Color3.fromRGB(40, 40, 55),
                i,
                function()
                    -- Open player actions (message, follow, etc.)
                end
            )
        end
    end

    if #players <= 1 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 40)
        empty.BackgroundTransparency = 1
        empty.Text = "لا يوجد لاعبون آخرون"
        empty.TextColor3 = Color3.fromRGB(120, 120, 130)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 14
        empty.LayoutOrder = 1
        empty.ZIndex = 74
        empty.Parent = parent
    end
end

function PhoneController:_onMessageReceived(_senderName: string, _content: string)
    -- Show notification badge when phone is closed or on different app
    if not self._isOpen or self._currentApp ~= "messages" then
        self._unreadMessages = (self._unreadMessages or 0) + 1
    end
end

function PhoneController:RegisterSocialCallbacks(onOpen, onPost, onProfile, onLeaderboard)
    self._onSocialOpen = onOpen
    self._onSocialPost = onPost
    self._onSocialProfile = onProfile
    self._onSocialLeaderboard = onLeaderboard
end

return PhoneController
