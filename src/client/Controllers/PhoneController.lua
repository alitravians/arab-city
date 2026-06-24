--[[
    Arab City v2.0 - PhoneController
    In-game phone with 9 fully functional apps.
    Each app opens the corresponding system panel or a built-in sub-page.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PhoneController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local playerGui
local _isOpen = false
local _currentPage = "home"

function PhoneController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS
    playerGui = player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "PhoneGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 70
    gui.Parent = playerGui

    -- Phone toggle
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 46, 0, 46)
    toggleBtn.Position = UDim2.new(0, 125, 1, -60)
    toggleBtn.AnchorPoint = Vector2.new(0, 1)
    toggleBtn.BackgroundColor3 = colors.secondary
    toggleBtn.Text = "📱"
    toggleBtn.TextSize = 20
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = gui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 23)

    -- Phone frame
    local phone = Instance.new("Frame")
    phone.Name = "Phone"
    phone.Size = UDim2.new(0, 260, 0, 460)
    phone.Position = UDim2.new(1, -280, 0.5, 0)
    phone.AnchorPoint = Vector2.new(0, 0.5)
    phone.BackgroundColor3 = colors.background
    phone.BorderSizePixel = 0
    phone.Visible = false
    phone.Parent = gui
    Instance.new("UICorner", phone).CornerRadius = UDim.new(0, 20)
    local pStroke = Instance.new("UIStroke")
    pStroke.Color = colors.accent
    pStroke.Thickness = 2
    pStroke.Parent = phone

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = colors.card
    header.BorderSizePixel = 0
    header.Parent = phone
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 20)

    local headerTitle = Instance.new("TextLabel")
    headerTitle.Name = "Title"
    headerTitle.Size = UDim2.new(1, -50, 1, 0)
    headerTitle.Position = UDim2.new(0, 12, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "📱 الهاتف"
    headerTitle.TextSize = 15
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextColor3 = colors.text
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header

    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackBtn"
    backBtn.Size = UDim2.new(0, 36, 0, 36)
    backBtn.Position = UDim2.new(1, -40, 0, 4)
    backBtn.BackgroundColor3 = colors.accent
    backBtn.Text = "←"
    backBtn.TextSize = 18
    backBtn.Font = Enum.Font.GothamBold
    backBtn.TextColor3 = Color3.new(1, 1, 1)
    backBtn.BorderSizePixel = 0
    backBtn.Visible = false
    backBtn.Parent = header
    Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 8)

    -- Home (app grid)
    local homePage = Instance.new("Frame")
    homePage.Name = "HomePage"
    homePage.Size = UDim2.new(1, -16, 1, -54)
    homePage.Position = UDim2.new(0, 8, 0, 48)
    homePage.BackgroundTransparency = 1
    homePage.Parent = phone

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 70, 0, 82)
    gridLayout.CellPadding = UDim2.new(0, 6, 0, 8)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.Parent = homePage

    local apps = {
        { icon = "📸", name = "كاميرا", action = "camera", color = Color3.fromRGB(60, 60, 90) },
        { icon = "🗺️", name = "خريطة", action = "map", color = Color3.fromRGB(40, 70, 50) },
        { icon = "💬", name = "دردشة", action = "messages", color = Color3.fromRGB(30, 60, 90) },
        { icon = "🛒", name = "متجر", action = "shop", color = Color3.fromRGB(80, 50, 30) },
        { icon = "💼", name = "وظائف", action = "jobs", color = Color3.fromRGB(50, 50, 80) },
        { icon = "🏠", name = "عقارات", action = "realestate", color = Color3.fromRGB(50, 70, 50) },
        { icon = "🚗", name = "سيارات", action = "vehicles", color = Color3.fromRGB(70, 40, 40) },
        { icon = "🐾", name = "حيوانات", action = "pets", color = Color3.fromRGB(70, 55, 30) },
        { icon = "🎫", name = "أكواد", action = "codes", color = Color3.fromRGB(40, 60, 70) },
    }

    for i, app in ipairs(apps) do
        local appBtn = Instance.new("TextButton")
        appBtn.Size = UDim2.new(0, 70, 0, 82)
        appBtn.BackgroundColor3 = app.color
        appBtn.Text = ""
        appBtn.BorderSizePixel = 0
        appBtn.LayoutOrder = i
        appBtn.Parent = homePage
        Instance.new("UICorner", appBtn).CornerRadius = UDim.new(0, 14)

        local iconLbl = Instance.new("TextLabel")
        iconLbl.Size = UDim2.new(1, 0, 0, 44)
        iconLbl.Position = UDim2.new(0, 0, 0, 4)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text = app.icon
        iconLbl.TextSize = 30
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.Parent = appBtn

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0, 22)
        nameLbl.Position = UDim2.new(0, 0, 0, 50)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = app.name
        nameLbl.TextSize = 11
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextColor3 = colors.text
        nameLbl.Parent = appBtn

        appBtn.MouseButton1Click:Connect(function()
            self:_openApp(app.action)
        end)
    end

    -- ── Sub-pages (built-in) ──

    -- Jobs page
    local jobsPage = self:_buildJobsPage(phone, colors)
    -- Real Estate page
    local realEstatePage = self:_buildRealEstatePage(phone, colors)
    -- Vehicles page
    local vehiclesPage = self:_buildVehiclesPage(phone, colors)
    -- Camera page
    local cameraPage = self:_buildCameraPage(phone, colors)

    self._gui = gui
    self._phone = phone
    self._homePage = homePage
    self._backBtn = backBtn
    self._headerTitle = headerTitle
    self._pages = {
        jobs = jobsPage,
        realestate = realEstatePage,
        vehicles = vehiclesPage,
        camera = cameraPage,
    }

    -- Toggle phone
    toggleBtn.MouseButton1Click:Connect(function()
        _isOpen = not _isOpen
        phone.Visible = _isOpen
        if _isOpen then
            self:_goHome()
        end
    end)

    -- Back button
    backBtn.MouseButton1Click:Connect(function()
        self:_goHome()
    end)

    -- Listen for server results
    Remotes:OnClientEvent("JobResult", function(data)
        if type(data) == "table" then
            self:_showStatus(data.message or "", data.success)
        end
    end)
    Remotes:OnClientEvent("VehicleResult", function(data)
        if type(data) == "table" then
            self:_showStatus(data.message or "", data.success)
        end
    end)
    Remotes:OnClientEvent("PropertyResult", function(data)
        if type(data) == "table" then
            self:_showStatus(data.message or "", data.success)
        end
    end)
end

function PhoneController:_showStatus(msg, success)
    if self._statusLabel then
        self._statusLabel.Text = msg
        self._statusLabel.TextColor3 = if success
            then Constants.UI_COLORS.success
            else Constants.UI_COLORS.danger
        task.delay(3, function()
            if self._statusLabel then
                self._statusLabel.Text = ""
            end
        end)
    end
end

function PhoneController:_goHome()
    _currentPage = "home"
    self._homePage.Visible = true
    self._backBtn.Visible = false
    self._headerTitle.Text = "📱 الهاتف"
    for _, page in pairs(self._pages) do
        page.Visible = false
    end
end

function PhoneController:_showPage(pageName, title)
    _currentPage = pageName
    self._homePage.Visible = false
    self._backBtn.Visible = true
    self._headerTitle.Text = title
    for name, page in pairs(self._pages) do
        page.Visible = (name == pageName)
    end
end

function PhoneController:_openApp(action)
    if action == "camera" then
        self:_showPage("camera", "📸 الكاميرا")

    elseif action == "map" then
        -- Open MapController panel directly
        self:_toggleExternalPanel("MapGui", "MapPanel", true)

    elseif action == "messages" then
        -- Open ChatController window directly
        self:_toggleExternalPanel("ChatGui", "ChatWindow", true)

    elseif action == "shop" then
        -- Open ShopController panel directly
        self:_toggleExternalPanel("ShopGui", "ShopPanel", true)

    elseif action == "jobs" then
        self:_showPage("jobs", "💼 الوظائف")

    elseif action == "realestate" then
        self:_showPage("realestate", "🏠 العقارات")

    elseif action == "vehicles" then
        self:_showPage("vehicles", "🚗 السيارات")

    elseif action == "pets" then
        -- Open PetController panel directly
        local petGui = playerGui:FindFirstChild("PetGui")
        if petGui then
            for _, child in ipairs(petGui:GetChildren()) do
                if child:IsA("Frame") then
                    child.Visible = true
                    break
                end
            end
        end

    elseif action == "codes" then
        -- Open CodeController panel directly
        local codeGui = playerGui:FindFirstChild("CodeGui")
        if codeGui then
            for _, child in ipairs(codeGui:GetChildren()) do
                if child:IsA("Frame") then
                    child.Visible = true
                    break
                end
            end
        end
    end
end

function PhoneController:_toggleExternalPanel(guiName, panelName, show)
    local gui = playerGui:FindFirstChild(guiName)
    if not gui then return end
    local panel = gui:FindFirstChild(panelName)
    if not panel then
        -- Try first Frame child
        for _, child in ipairs(gui:GetChildren()) do
            if child:IsA("Frame") then
                panel = child
                break
            end
        end
    end
    if panel then
        panel.Visible = show
    end
end

-- ── Jobs Sub-Page ──
function PhoneController:_buildJobsPage(phone, colors)
    local page = Instance.new("ScrollingFrame")
    page.Name = "JobsPage"
    page.Size = UDim2.new(1, -16, 1, -54)
    page.Position = UDim2.new(0, 8, 0, 48)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = phone

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = page

    -- Collect salary button
    local salaryBtn = Instance.new("TextButton")
    salaryBtn.Size = UDim2.new(1, -4, 0, 42)
    salaryBtn.BackgroundColor3 = colors.success
    salaryBtn.Text = "💰 جمع الراتب"
    salaryBtn.TextSize = 14
    salaryBtn.Font = Enum.Font.GothamBold
    salaryBtn.TextColor3 = Color3.new(1, 1, 1)
    salaryBtn.BorderSizePixel = 0
    salaryBtn.LayoutOrder = 0
    salaryBtn.Parent = page
    Instance.new("UICorner", salaryBtn).CornerRadius = UDim.new(0, 8)

    salaryBtn.MouseButton1Click:Connect(function()
        Remotes:FireServer("CollectSalary")
    end)

    -- Status label
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -4, 0, 22)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.TextColor3 = colors.success
    status.LayoutOrder = 1
    status.Parent = page
    self._statusLabel = status

    -- Job list
    for i, job in ipairs(Constants.JOBS) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 58)
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i + 1
        row.Parent = page
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 36, 0, 36)
        icon.Position = UDim2.new(0, 6, 0, 4)
        icon.BackgroundTransparency = 1
        icon.Text = job.icon
        icon.TextSize = 22
        icon.Font = Enum.Font.GothamBold
        icon.Parent = row

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0, 120, 0, 18)
        name.Position = UDim2.new(0, 44, 0, 4)
        name.BackgroundTransparency = 1
        name.Text = job.name
        name.TextSize = 12
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = colors.text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row

        local salary = Instance.new("TextLabel")
        salary.Size = UDim2.new(0, 120, 0, 14)
        salary.Position = UDim2.new(0, 44, 0, 24)
        salary.BackgroundTransparency = 1
        salary.Text = "الراتب: $" .. tostring(job.salary)
        salary.TextSize = 10
        salary.Font = Enum.Font.Gotham
        salary.TextColor3 = Color3.fromRGB(0, 220, 80)
        salary.TextXAlignment = Enum.TextXAlignment.Left
        salary.Parent = row

        local applyBtn = Instance.new("TextButton")
        applyBtn.Size = UDim2.new(0, 55, 0, 26)
        applyBtn.Position = UDim2.new(1, -62, 0, 16)
        applyBtn.BackgroundColor3 = colors.accent
        applyBtn.Text = "تقدم"
        applyBtn.TextSize = 11
        applyBtn.Font = Enum.Font.GothamBold
        applyBtn.TextColor3 = Color3.new(1, 1, 1)
        applyBtn.BorderSizePixel = 0
        applyBtn.Parent = row
        Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 6)

        applyBtn.MouseButton1Click:Connect(function()
            Remotes:FireServer("ApplyForJob", job.id)
        end)
    end

    return page
end

-- ── Real Estate Sub-Page ──
function PhoneController:_buildRealEstatePage(phone, colors)
    local page = Instance.new("ScrollingFrame")
    page.Name = "RealEstatePage"
    page.Size = UDim2.new(1, -16, 1, -54)
    page.Position = UDim2.new(0, 8, 0, 48)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = phone

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = page

    local propertyIcons = {
        small_house = "🏡",
        apartment = "🏢",
        villa = "🏘️",
        mansion = "🏰",
        penthouse = "🌆",
    }

    for i, prop in ipairs(Constants.PROPERTIES) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 58)
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = page
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 36, 0, 36)
        icon.Position = UDim2.new(0, 6, 0, 4)
        icon.BackgroundTransparency = 1
        icon.Text = propertyIcons[prop.id] or "🏠"
        icon.TextSize = 22
        icon.Font = Enum.Font.GothamBold
        icon.Parent = row

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0, 100, 0, 18)
        name.Position = UDim2.new(0, 44, 0, 4)
        name.BackgroundTransparency = 1
        name.Text = prop.name
        name.TextSize = 12
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = colors.text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row

        local price = Instance.new("TextLabel")
        price.Size = UDim2.new(0, 100, 0, 14)
        price.Position = UDim2.new(0, 44, 0, 24)
        price.BackgroundTransparency = 1
        price.Text = "$" .. tostring(prop.price)
        price.TextSize = 10
        price.Font = Enum.Font.Gotham
        price.TextColor3 = Color3.fromRGB(0, 220, 80)
        price.TextXAlignment = Enum.TextXAlignment.Left
        price.Parent = row

        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0, 55, 0, 26)
        buyBtn.Position = UDim2.new(1, -62, 0, 16)
        buyBtn.BackgroundColor3 = colors.accent
        buyBtn.Text = "شراء"
        buyBtn.TextSize = 11
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.TextColor3 = Color3.new(1, 1, 1)
        buyBtn.BorderSizePixel = 0
        buyBtn.Parent = row
        Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)

        buyBtn.MouseButton1Click:Connect(function()
            Remotes:FireServer("PurchaseProperty", prop.id)
        end)
    end

    return page
end

-- ── Vehicles Sub-Page ──
function PhoneController:_buildVehiclesPage(phone, colors)
    local page = Instance.new("ScrollingFrame")
    page.Name = "VehiclesPage"
    page.Size = UDim2.new(1, -16, 1, -54)
    page.Position = UDim2.new(0, 8, 0, 48)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = phone

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = page

    local vehicleIcons = {
        sedan = "🚗",
        sport = "🏎️",
        suv = "🚙",
        luxury = "🚘",
        truck = "🚛",
        motorcycle = "🏍️",
        bus = "🚌",
    }

    for i, veh in ipairs(Constants.VEHICLES) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 64)
        row.BackgroundColor3 = colors.card
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = page
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 36, 0, 36)
        icon.Position = UDim2.new(0, 6, 0, 4)
        icon.BackgroundTransparency = 1
        icon.Text = vehicleIcons[veh.id] or "🚗"
        icon.TextSize = 22
        icon.Font = Enum.Font.GothamBold
        icon.Parent = row

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0, 100, 0, 18)
        name.Position = UDim2.new(0, 44, 0, 2)
        name.BackgroundTransparency = 1
        name.Text = veh.name
        name.TextSize = 12
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = colors.text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = row

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(0, 120, 0, 14)
        info.Position = UDim2.new(0, 44, 0, 22)
        info.BackgroundTransparency = 1
        info.Text = "$" .. tostring(veh.price) .. " | سرعة: " .. tostring(veh.speed)
        info.TextSize = 9
        info.Font = Enum.Font.Gotham
        info.TextColor3 = Color3.fromRGB(0, 220, 80)
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.Parent = row

        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0, 48, 0, 22)
        buyBtn.Position = UDim2.new(1, -106, 0, 38)
        buyBtn.BackgroundColor3 = colors.accent
        buyBtn.Text = "شراء"
        buyBtn.TextSize = 10
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.TextColor3 = Color3.new(1, 1, 1)
        buyBtn.BorderSizePixel = 0
        buyBtn.Parent = row
        Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 5)

        local spawnBtn = Instance.new("TextButton")
        spawnBtn.Size = UDim2.new(0, 48, 0, 22)
        spawnBtn.Position = UDim2.new(1, -54, 0, 38)
        spawnBtn.BackgroundColor3 = colors.success
        spawnBtn.Text = "استدعاء"
        spawnBtn.TextSize = 9
        spawnBtn.Font = Enum.Font.GothamBold
        spawnBtn.TextColor3 = Color3.new(1, 1, 1)
        spawnBtn.BorderSizePixel = 0
        spawnBtn.Parent = row
        Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 5)

        buyBtn.MouseButton1Click:Connect(function()
            Remotes:FireServer("PurchaseVehicle", veh.id)
        end)
        spawnBtn.MouseButton1Click:Connect(function()
            Remotes:FireServer("SpawnVehicle", veh.id)
        end)
    end

    return page
end

-- ── Camera Sub-Page ──
function PhoneController:_buildCameraPage(phone, colors)
    local page = Instance.new("Frame")
    page.Name = "CameraPage"
    page.Size = UDim2.new(1, -16, 1, -54)
    page.Position = UDim2.new(0, 8, 0, 48)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = phone

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = page

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, 0, 0, 30)
    hint.BackgroundTransparency = 1
    hint.Text = "اختر وضع الكاميرا (أو اضغط V)"
    hint.TextSize = 12
    hint.Font = Enum.Font.Gotham
    hint.TextColor3 = colors.textDim
    hint.LayoutOrder = 0
    hint.Parent = page

    local modes = {
        { name = "default", label = "عادي", icon = "🎥", fov = 70 },
        { name = "cinematic", label = "سينمائي", icon = "🎬", fov = 55 },
        { name = "selfie", label = "سيلفي", icon = "🤳", fov = 50 },
        { name = "firstperson", label = "شخص أول", icon = "👁️", fov = 90 },
    }

    local camera = workspace.CurrentCamera

    for i, mode in ipairs(modes) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 50)
        btn.BackgroundColor3 = colors.card
        btn.Text = mode.icon .. "  " .. mode.label
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = colors.text
        btn.BorderSizePixel = 0
        btn.LayoutOrder = i
        btn.Parent = page
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

        btn.MouseButton1Click:Connect(function()
            camera.FieldOfView = mode.fov
            if mode.name == "firstperson" then
                player.CameraMode = Enum.CameraMode.LockFirstPerson
            else
                player.CameraMode = Enum.CameraMode.Classic
            end
            Remotes:FireServer("ShowNotification")
            -- Update button visuals
            for _, child in ipairs(page:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = colors.card
                end
            end
            btn.BackgroundColor3 = colors.accent
        end)
    end

    return page
end

return PhoneController
