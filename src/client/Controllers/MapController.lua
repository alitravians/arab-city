--[[
    Arab City v2.0 - MapController
    Minimap / full map with building waypoints.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapController = {}

local Shared, Constants
local player = Players.LocalPlayer
local _isOpen = false

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
    panel.Size = UDim2.new(0, 500, 0, 500)
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
    title.Text = "🗺️ خريطة المدينة"
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = colors.text
    title.BorderSizePixel = 0
    title.Parent = panel
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    -- Map area
    local mapArea = Instance.new("Frame")
    mapArea.Size = UDim2.new(1, -20, 1, -100)
    mapArea.Position = UDim2.new(0, 10, 0, 45)
    mapArea.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
    mapArea.BorderSizePixel = 0
    mapArea.Parent = panel
    Instance.new("UICorner", mapArea).CornerRadius = UDim.new(0, 8)

    -- Plot buildings on map
    local mapScale = 480 / 800
    for _, building in ipairs(Constants.BUILDINGS) do
        local pos = building.position
        local mapX = (pos[1] + 400) * mapScale
        local mapY = (pos[3] + 400) * mapScale
        local sz = building.size
        local dotW = math.max(10, sz[1] * mapScale * 0.6)
        local dotH = math.max(10, (sz[3] or sz[1]) * mapScale * 0.6)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, dotW, 0, dotH)
        dot.Position = UDim2.new(0, mapX - dotW / 2, 0, mapY - dotH / 2)
        dot.BackgroundColor3 = colors.accent
        dot.BorderSizePixel = 0
        dot.Parent = mapArea
        Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 3)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 80, 0, 14)
        label.Position = UDim2.new(0.5, 0, 1, 2)
        label.AnchorPoint = Vector2.new(0.5, 0)
        label.BackgroundTransparency = 1
        label.Text = building.name
        label.TextSize = 9
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = colors.text
        label.Parent = dot
    end

    -- Player dot (updates)
    local playerDot = Instance.new("Frame")
    playerDot.Size = UDim2.new(0, 10, 0, 10)
    playerDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    playerDot.BorderSizePixel = 0
    playerDot.ZIndex = 10
    playerDot.Parent = mapArea
    Instance.new("UICorner", playerDot).CornerRadius = UDim.new(1, 0)

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

    toggleBtn.MouseButton1Click:Connect(function()
        _isOpen = not _isOpen
        panel.Visible = _isOpen
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)

    -- Update player position on map
    task.spawn(function()
        while true do
            task.wait(0.5)
            local char = player.Character
            if char and _isOpen then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local px = (hrp.Position.X + 400) * mapScale
                    local pz = (hrp.Position.Z + 400) * mapScale
                    playerDot.Position = UDim2.new(0, px - 5, 0, pz - 5)
                end
            end
        end
    end)
end

return MapController
