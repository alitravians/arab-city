--[[
    Arab City v2.0 - MapController
    Visual city map with building icons, roads, and player position.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapController = {}

local Shared, Constants
local player = Players.LocalPlayer
local _isOpen = false

-- Building type colors
local BUILDING_COLORS = {
    hospital   = Color3.fromRGB(220, 50, 50),
    bank       = Color3.fromRGB(220, 180, 40),
    mall       = Color3.fromRGB(0, 170, 255),
    police     = Color3.fromRGB(40, 80, 200),
    fire       = Color3.fromRGB(255, 100, 20),
    airport    = Color3.fromRGB(120, 120, 180),
    dealership = Color3.fromRGB(180, 80, 180),
    restaurant = Color3.fromRGB(200, 120, 60),
    gas_station= Color3.fromRGB(100, 160, 60),
    hotel      = Color3.fromRGB(160, 120, 200),
    school     = Color3.fromRGB(80, 180, 160),
}

local BUILDING_ICONS = {
    hospital   = "+",
    bank       = "$",
    mall       = "M",
    police     = "P",
    fire       = "F",
    airport    = "A",
    dealership = "D",
    restaurant = "R",
    gas_station= "G",
    hotel      = "H",
    school     = "S",
}

function MapController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants

    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "MapGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 60
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Map toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 46, 0, 46)
    toggleBtn.Position = UDim2.new(0, 70, 1, -60)
    toggleBtn.AnchorPoint = Vector2.new(0, 1)
    toggleBtn.BackgroundColor3 = colors.secondary
    toggleBtn.Text = "🗺️"
    toggleBtn.TextSize = 20
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = gui
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 23)

    -- Map panel
    local panel = Instance.new("Frame")
    panel.Name = "MapPanel"
    panel.Size = UDim2.new(0, 520, 0, 560)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = colors.background
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local mStroke = Instance.new("UIStroke")
    mStroke.Color = colors.accent
    mStroke.Thickness = 2
    mStroke.Parent = panel

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = colors.card
    title.Text = "🗺️ خريطة المدينة — Arab City"
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = colors.text
    title.BorderSizePixel = 0
    title.Parent = panel
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = colors.text
    closeBtn.Parent = panel

    -- Map area
    local mapArea = Instance.new("Frame")
    mapArea.Name = "MapArea"
    mapArea.Size = UDim2.new(1, -20, 0, 420)
    mapArea.Position = UDim2.new(0, 10, 0, 45)
    mapArea.BackgroundColor3 = Color3.fromRGB(35, 55, 35)
    mapArea.BorderSizePixel = 0
    mapArea.ClipsDescendants = true
    mapArea.Parent = panel
    Instance.new("UICorner", mapArea).CornerRadius = UDim.new(0, 8)

    local mapWidth = 500
    local mapHeight = 420
    local worldSize = 700
    local mapScale = mapWidth / worldSize
    local offsetX = worldSize / 2
    local offsetZ = worldSize / 2

    -- Draw roads
    for _, street in ipairs(Constants.STREETS) do
        local fromX = (street.from[1] + offsetX) * mapScale
        local fromZ = (street.from[3] + offsetZ) * mapScale
        local toX = (street.to[1] + offsetX) * mapScale
        local toZ = (street.to[3] + offsetZ) * mapScale

        local dx = toX - fromX
        local dz = toZ - fromZ
        local length = math.sqrt(dx * dx + dz * dz)
        local roadW = math.max(3, street.width * mapScale * 0.5)

        local isHorizontal = math.abs(dx) > math.abs(dz)
        local road = Instance.new("Frame")
        if isHorizontal then
            road.Size = UDim2.new(0, length, 0, roadW)
            road.Position = UDim2.new(0, math.min(fromX, toX), 0, fromZ - roadW / 2)
        else
            road.Size = UDim2.new(0, roadW, 0, length)
            road.Position = UDim2.new(0, fromX - roadW / 2, 0, math.min(fromZ, toZ))
        end
        road.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        road.BorderSizePixel = 0
        road.Parent = mapArea

        -- Center line
        local line = Instance.new("Frame")
        if isHorizontal then
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 0.5, 0)
        else
            line.Size = UDim2.new(0, 1, 1, 0)
            line.Position = UDim2.new(0.5, 0, 0, 0)
        end
        line.BackgroundColor3 = Color3.fromRGB(200, 180, 50)
        line.BackgroundTransparency = 0.5
        line.BorderSizePixel = 0
        line.Parent = road
    end

    -- Draw buildings
    for _, building in ipairs(Constants.BUILDINGS) do
        local pos = building.position
        local mapX = (pos[1] + offsetX) * mapScale
        local mapZ = (pos[3] + offsetZ) * mapScale
        local sz = building.size
        local dotW = math.max(16, sz[1] * mapScale * 0.5)
        local dotH = math.max(16, (sz[3] or sz[1]) * mapScale * 0.5)

        local baseId = string.match(building.id, "^(%a+)")
        local bColor = BUILDING_COLORS[baseId] or colors.accent
        local bIcon = BUILDING_ICONS[baseId]

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, dotW, 0, dotH)
        dot.Position = UDim2.new(0, mapX - dotW / 2, 0, mapZ - dotH / 2)
        dot.BackgroundColor3 = bColor
        dot.BackgroundTransparency = 0.15
        dot.BorderSizePixel = 0
        dot.ZIndex = 5
        dot.Parent = mapArea
        Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
        local dotStroke = Instance.new("UIStroke")
        dotStroke.Color = bColor
        dotStroke.Thickness = 1
        dotStroke.Parent = dot

        -- Icon letter inside
        if bIcon then
            local iconLabel = Instance.new("TextLabel")
            iconLabel.Size = UDim2.new(1, 0, 1, 0)
            iconLabel.BackgroundTransparency = 1
            iconLabel.Text = bIcon
            iconLabel.TextSize = math.min(dotW, dotH) * 0.6
            iconLabel.Font = Enum.Font.GothamBold
            iconLabel.TextColor3 = Color3.new(1, 1, 1)
            iconLabel.ZIndex = 6
            iconLabel.Parent = dot
        end

        -- Name below
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 90, 0, 14)
        label.Position = UDim2.new(0.5, 0, 1, 2)
        label.AnchorPoint = Vector2.new(0.5, 0)
        label.BackgroundTransparency = 1
        label.Text = building.name
        label.TextSize = 8
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.fromRGB(200, 200, 210)
        label.ZIndex = 6
        label.Parent = dot

        -- Highlight on houses/apartments
        if string.find(building.id, "house") or string.find(building.id, "apartment") then
            dot.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
            if dotStroke then dotStroke.Color = Color3.fromRGB(80, 140, 80) end
        end
    end

    -- Player dot
    local playerDot = Instance.new("Frame")
    playerDot.Size = UDim2.new(0, 12, 0, 12)
    playerDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    playerDot.BorderSizePixel = 0
    playerDot.ZIndex = 20
    playerDot.Parent = mapArea
    Instance.new("UICorner", playerDot).CornerRadius = UDim.new(1, 0)
    local playerStroke = Instance.new("UIStroke")
    playerStroke.Color = Color3.new(1, 1, 1)
    playerStroke.Thickness = 2
    playerStroke.Parent = playerDot

    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(0, 50, 0, 12)
    playerLabel.Position = UDim2.new(0.5, 0, 1, 2)
    playerLabel.AnchorPoint = Vector2.new(0.5, 0)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = "أنت"
    playerLabel.TextSize = 8
    playerLabel.Font = Enum.Font.GothamBold
    playerLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
    playerLabel.ZIndex = 20
    playerLabel.Parent = playerDot

    -- Legend
    local legendFrame = Instance.new("Frame")
    legendFrame.Size = UDim2.new(1, -20, 0, 40)
    legendFrame.Position = UDim2.new(0, 10, 1, -50)
    legendFrame.BackgroundColor3 = colors.card
    legendFrame.BorderSizePixel = 0
    legendFrame.Parent = panel
    Instance.new("UICorner", legendFrame).CornerRadius = UDim.new(0, 6)

    local legendLayout = Instance.new("UIListLayout")
    legendLayout.FillDirection = Enum.FillDirection.Horizontal
    legendLayout.SortOrder = Enum.SortOrder.LayoutOrder
    legendLayout.Padding = UDim.new(0, 8)
    legendLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    legendLayout.Parent = legendFrame
    Instance.new("UIPadding", legendFrame).PaddingLeft = UDim.new(0, 8)

    local legendItems = {
        { color = Color3.fromRGB(220, 50, 50), label = "طبي" },
        { color = Color3.fromRGB(220, 180, 40), label = "مالي" },
        { color = Color3.fromRGB(0, 170, 255), label = "تسوق" },
        { color = Color3.fromRGB(40, 80, 200), label = "أمن" },
        { color = Color3.fromRGB(80, 140, 80), label = "سكني" },
        { color = Color3.fromRGB(255, 80, 80), label = "أنت" },
    }

    for idx, item in ipairs(legendItems) do
        local legendItem = Instance.new("Frame")
        legendItem.Size = UDim2.new(0, 60, 0, 20)
        legendItem.BackgroundTransparency = 1
        legendItem.LayoutOrder = idx
        legendItem.Parent = legendFrame

        local colorBox = Instance.new("Frame")
        colorBox.Size = UDim2.new(0, 10, 0, 10)
        colorBox.Position = UDim2.new(0, 0, 0.5, -5)
        colorBox.BackgroundColor3 = item.color
        colorBox.BorderSizePixel = 0
        colorBox.Parent = legendItem
        Instance.new("UICorner", colorBox).CornerRadius = UDim.new(1, 0)

        local legendLabel = Instance.new("TextLabel")
        legendLabel.Size = UDim2.new(1, -14, 1, 0)
        legendLabel.Position = UDim2.new(0, 14, 0, 0)
        legendLabel.BackgroundTransparency = 1
        legendLabel.Text = item.label
        legendLabel.TextSize = 9
        legendLabel.Font = Enum.Font.GothamBold
        legendLabel.TextColor3 = colors.textDim
        legendLabel.TextXAlignment = Enum.TextXAlignment.Left
        legendLabel.Parent = legendItem
    end

    toggleBtn.MouseButton1Click:Connect(function()
        _isOpen = not _isOpen
        panel.Visible = _isOpen
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)

    -- Update player position
    task.spawn(function()
        while true do
            task.wait(0.3)
            local char = player.Character
            if char and _isOpen then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local px = (hrp.Position.X + offsetX) * mapScale
                    local pz = (hrp.Position.Z + offsetZ) * mapScale
                    px = math.clamp(px, 6, mapWidth - 6)
                    pz = math.clamp(pz, 6, mapHeight - 6)
                    playerDot.Position = UDim2.new(0, px - 6, 0, pz - 6)
                end
            end
        end
    end)
end

return MapController
