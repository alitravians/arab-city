--[[
    Arab City - Map Controller
    Midnight Metropolis style: dark navy with neon cyan outlines,
    warm amber building windows, and colored landmark markers
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = Constants.COLORS

local MapController = {}
MapController._isOpen = false

-- Map world bounds (adjust to your actual map size)
local MAP_BOUNDS = {
    minX = -500, maxX = 500,
    minZ = -500, maxZ = 500,
}

function MapController:Init()
    self._gui = self:_buildMapUI()
    self._gui.Enabled = false
    self._gui.Parent = playerGui
end

function MapController:Toggle()
    if self._isOpen then
        self:Close()
    else
        self:Open()
    end
end

function MapController:Open()
    if self._isOpen then
        return
    end
    self._isOpen = true
    self._gui.Enabled = true

    -- Fade in
    self._mainFrame.BackgroundTransparency = 1
    TweenService:Create(self._mainFrame, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.05,
    }):Play()

    self:_startPlayerTracking()
end

function MapController:Close()
    if not self._isOpen then
        return
    end

    TweenService:Create(self._mainFrame, TweenInfo.new(0.2), {
        BackgroundTransparency = 1,
    }):Play()

    task.delay(0.2, function()
        self._isOpen = false
        self._gui.Enabled = false
    end)
end

function MapController:_buildMapUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_Map"
    gui.DisplayOrder = 75
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false

    -- Fullscreen map frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MapFrame"
    mainFrame.Size = UDim2.new(0.7, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(12, 18, 32)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 60
    mainFrame.Parent = gui
    self._mainFrame = mainFrame

    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

    local mapStroke = Instance.new("UIStroke")
    mapStroke.Color = Color3.fromRGB(0, 200, 255)
    mapStroke.Thickness = 2
    mapStroke.Transparency = 0.3
    mapStroke.Parent = mainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(8, 12, 25)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 61
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🗺️ خريطة Arab City"
    titleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 62
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.ZIndex = 62
    closeBtn.Parent = titleBar

    closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)

    -- Map canvas (where markers appear)
    local mapCanvas = Instance.new("Frame")
    mapCanvas.Name = "MapCanvas"
    mapCanvas.Size = UDim2.new(1, -20, 1, -55)
    mapCanvas.Position = UDim2.new(0.5, 0, 0, 45)
    mapCanvas.AnchorPoint = Vector2.new(0.5, 0)
    mapCanvas.BackgroundColor3 = Color3.fromRGB(15, 22, 38)
    mapCanvas.BorderSizePixel = 0
    mapCanvas.ClipsDescendants = true
    mapCanvas.ZIndex = 61
    mapCanvas.Parent = mainFrame
    self._mapCanvas = mapCanvas

    Instance.new("UICorner", mapCanvas).CornerRadius = UDim.new(0, 8)

    -- Grid lines
    for i = 0, 10 do
        local hLine = Instance.new("Frame")
        hLine.Size = UDim2.new(1, 0, 0, 1)
        hLine.Position = UDim2.new(0, 0, i / 10, 0)
        hLine.BackgroundColor3 = Color3.fromRGB(30, 45, 65)
        hLine.BackgroundTransparency = 0.5
        hLine.BorderSizePixel = 0
        hLine.ZIndex = 62
        hLine.Parent = mapCanvas

        local vLine = Instance.new("Frame")
        vLine.Size = UDim2.new(0, 1, 1, 0)
        vLine.Position = UDim2.new(i / 10, 0, 0, 0)
        vLine.BackgroundColor3 = Color3.fromRGB(30, 45, 65)
        vLine.BackgroundTransparency = 0.5
        vLine.BorderSizePixel = 0
        vLine.ZIndex = 62
        vLine.Parent = mapCanvas
    end

    -- Location markers
    self._markers = {}
    for _, loc in ipairs(Constants.MAP_LOCATIONS) do
        local marker = Instance.new("Frame")
        marker.Name = "Marker_" .. loc.id
        marker.Size = UDim2.new(0, 24, 0, 24)
        marker.AnchorPoint = Vector2.new(0.5, 0.5)
        marker.BackgroundColor3 = COLORS.Accent
        marker.BorderSizePixel = 0
        marker.ZIndex = 64
        marker.Parent = mapCanvas

        Instance.new("UICorner", marker).CornerRadius = UDim.new(1, 0)

        local markerIcon = Instance.new("TextLabel")
        markerIcon.Size = UDim2.new(1, 0, 1, 0)
        markerIcon.BackgroundTransparency = 1
        markerIcon.Text = loc.icon
        markerIcon.TextSize = 12
        markerIcon.ZIndex = 65
        markerIcon.Parent = marker

        local markerLabel = Instance.new("TextLabel")
        markerLabel.Size = UDim2.new(0, 80, 0, 15)
        markerLabel.Position = UDim2.new(0.5, 0, 1, 2)
        markerLabel.AnchorPoint = Vector2.new(0.5, 0)
        markerLabel.BackgroundTransparency = 1
        markerLabel.Text = loc.nameAr
        markerLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
        markerLabel.Font = Enum.Font.GothamBold
        markerLabel.TextSize = 9
        markerLabel.ZIndex = 65
        markerLabel.Parent = marker

        -- Distribute markers across the map (deterministic per location)
        local hash = 0
        for c = 1, #loc.id do
            hash = hash + string.byte(loc.id, c)
        end
        local rng = Random.new(hash)
        marker.Position = UDim2.new(rng:NextInteger(10, 90) / 100, 0, rng:NextInteger(10, 90) / 100, 0)

        self._markers[loc.id] = marker
    end

    -- Player marker
    local playerMarker = Instance.new("Frame")
    playerMarker.Name = "PlayerMarker"
    playerMarker.Size = UDim2.new(0, 14, 0, 14)
    playerMarker.AnchorPoint = Vector2.new(0.5, 0.5)
    playerMarker.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    playerMarker.BorderSizePixel = 0
    playerMarker.ZIndex = 66
    playerMarker.Parent = mapCanvas

    Instance.new("UICorner", playerMarker).CornerRadius = UDim.new(1, 0)

    local playerDot = Instance.new("Frame")
    playerDot.Size = UDim2.new(0.5, 0, 0.5, 0)
    playerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    playerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    playerDot.BorderSizePixel = 0
    playerDot.ZIndex = 67
    playerDot.Parent = playerMarker

    Instance.new("UICorner", playerDot).CornerRadius = UDim.new(1, 0)

    local youLabel = Instance.new("TextLabel")
    youLabel.Size = UDim2.new(0, 30, 0, 12)
    youLabel.Position = UDim2.new(0.5, 0, 1, 2)
    youLabel.AnchorPoint = Vector2.new(0.5, 0)
    youLabel.BackgroundTransparency = 1
    youLabel.Text = "أنت"
    youLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    youLabel.Font = Enum.Font.GothamBold
    youLabel.TextSize = 9
    youLabel.ZIndex = 67
    youLabel.Parent = playerMarker

    self._playerMarker = playerMarker

    -- Legend (bottom)
    local legend = Instance.new("Frame")
    legend.Size = UDim2.new(1, -20, 0, 25)
    legend.Position = UDim2.new(0.5, 0, 1, -5)
    legend.AnchorPoint = Vector2.new(0.5, 1)
    legend.BackgroundTransparency = 1
    legend.ZIndex = 63
    legend.Parent = mapCanvas

    local legendLabel = Instance.new("TextLabel")
    legendLabel.Size = UDim2.new(1, 0, 1, 0)
    legendLabel.BackgroundTransparency = 1
    legendLabel.Text = "🔵 موقعك | 📍 معالم المدينة"
    legendLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    legendLabel.Font = Enum.Font.Gotham
    legendLabel.TextSize = 11
    legendLabel.ZIndex = 64
    legendLabel.Parent = legend

    return gui
end

function MapController:_worldToMap(worldPos: Vector3): UDim2
    local rangeX = MAP_BOUNDS.maxX - MAP_BOUNDS.minX
    local rangeZ = MAP_BOUNDS.maxZ - MAP_BOUNDS.minZ

    local normX = math.clamp((worldPos.X - MAP_BOUNDS.minX) / rangeX, 0, 1)
    local normZ = 1 - math.clamp((worldPos.Z - MAP_BOUNDS.minZ) / rangeZ, 0, 1)

    return UDim2.new(normX, 0, normZ, 0)
end

function MapController:_startPlayerTracking()
    if self._trackingConnection then
        self._trackingConnection:Disconnect()
    end

    self._trackingConnection = RunService.Heartbeat:Connect(function()
        if not self._isOpen then
            if self._trackingConnection then
                self._trackingConnection:Disconnect()
                self._trackingConnection = nil
            end
            return
        end

        local character = player.Character
        if not character then
            return
        end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            return
        end

        local mapPos = self:_worldToMap(rootPart.Position)
        self._playerMarker.Position = mapPos
    end)
end

return MapController
