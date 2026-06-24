--[[
    Arab City v2.0 - PhoneController
    In-game phone: camera, messages, map, social network.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhoneController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function PhoneController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "PhoneGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 70
    gui.Parent = player:WaitForChild("PlayerGui")

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
    phone.Size = UDim2.new(0, 240, 0, 420)
    phone.Position = UDim2.new(1, -260, 0.5, 0)
    phone.AnchorPoint = Vector2.new(0, 0.5)
    phone.BackgroundColor3 = colors.background
    phone.BorderSizePixel = 0
    phone.Visible = false
    phone.Parent = gui
    Instance.new("UICorner", phone).CornerRadius = UDim.new(0, 18)
    local pStroke = Instance.new("UIStroke")
    pStroke.Color = colors.accent
    pStroke.Thickness = 2
    pStroke.Parent = phone

    -- Header
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = colors.card
    header.Text = "📱 الهاتف"
    header.TextSize = 15
    header.Font = Enum.Font.GothamBold
    header.TextColor3 = colors.text
    header.BorderSizePixel = 0
    header.Parent = phone
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 18)

    -- App grid
    local appGrid = Instance.new("Frame")
    appGrid.Size = UDim2.new(1, -20, 1, -50)
    appGrid.Position = UDim2.new(0, 10, 0, 45)
    appGrid.BackgroundTransparency = 1
    appGrid.Parent = phone

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 60, 0, 75)
    gridLayout.CellPadding = UDim2.new(0, 15, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = appGrid

    local apps = {
        { icon = "📸", name = "كاميرا", action = "camera" },
        { icon = "🗺️", name = "خريطة", action = "map" },
        { icon = "💬", name = "رسائل", action = "messages" },
        { icon = "🛒", name = "متجر", action = "shop" },
        { icon = "💼", name = "وظائف", action = "jobs" },
        { icon = "🏠", name = "عقارات", action = "realestate" },
        { icon = "🚗", name = "سيارات", action = "vehicles" },
        { icon = "🐾", name = "حيوانات", action = "pets" },
        { icon = "🎫", name = "أكواد", action = "codes" },
    }

    for i, app in ipairs(apps) do
        local appBtn = Instance.new("TextButton")
        appBtn.Size = UDim2.new(0, 60, 0, 75)
        appBtn.BackgroundColor3 = colors.card
        appBtn.Text = ""
        appBtn.BorderSizePixel = 0
        appBtn.LayoutOrder = i
        appBtn.Parent = appGrid
        Instance.new("UICorner", appBtn).CornerRadius = UDim.new(0, 12)

        local iconLbl = Instance.new("TextLabel")
        iconLbl.Size = UDim2.new(1, 0, 0, 40)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text = app.icon
        iconLbl.TextSize = 28
        iconLbl.Font = Enum.Font.GothamBold
        iconLbl.Parent = appBtn

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0, 20)
        nameLbl.Position = UDim2.new(0, 0, 0, 42)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = app.name
        nameLbl.TextSize = 10
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextColor3 = colors.textDim
        nameLbl.Parent = appBtn

        appBtn.MouseButton1Click:Connect(function()
            self:_openApp(app.action)
        end)
    end

    toggleBtn.MouseButton1Click:Connect(function()
        _isOpen = not _isOpen
        phone.Visible = _isOpen
    end)
end

function PhoneController:_openApp(action)
    local Remotes = Shared.Remotes
    if action == "shop" then
        Remotes:FireServer("RequestShop")
    elseif action == "codes" then
        Remotes:FireServer("RequestCodes")
    elseif action == "jobs" then
        Remotes:FireServer("RequestJobs")
    elseif action == "vehicles" then
        Remotes:FireServer("RequestVehicles")
    end
    Remotes:FireClient("ShowNotification", player, {
        title = "تم",
        message = "جاري فتح التطبيق...",
        duration = 2,
    })
end

return PhoneController
