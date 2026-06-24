--[[
    Arab City - Traffic Service
    Spawns NPC cars that drive along road waypoints
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants

local TrafficService = {}
TrafficService._cars = {}
TrafficService._routes = {}

-- Car colors for variety
local CAR_COLORS = {
    Color3.fromRGB(200, 30, 30),   -- Red
    Color3.fromRGB(30, 30, 200),   -- Blue
    Color3.fromRGB(240, 240, 240), -- White
    Color3.fromRGB(30, 30, 30),    -- Black
    Color3.fromRGB(200, 180, 0),   -- Yellow
    Color3.fromRGB(0, 180, 80),    -- Green
    Color3.fromRGB(120, 120, 130), -- Silver
    Color3.fromRGB(180, 100, 30),  -- Orange
}

local MAT = { Metal = Enum.Material.Metal, Smooth = Enum.Material.SmoothPlastic, Glass = Enum.Material.Glass, Neon = Enum.Material.Neon }

function TrafficService:Init()
    self:_defineRoutes()
    task.defer(function()
        task.wait(5) -- wait for map to build
        self:_spawnAllCars()
        self:_startDriving()
    end)
end

function TrafficService:_defineRoutes()
    local H = 400 -- half city size (CITY_SIZE/2)
    -- Main road N-S (along X=0) both directions
    self._routes = {
        -- Main NS road northbound (right lane)
        { name = "NS_north", waypoints = {
            Vector3.new(4, 1.2, -H+40), Vector3.new(4, 1.2, -200), Vector3.new(4, 1.2, -80),
            Vector3.new(4, 1.2, 0), Vector3.new(4, 1.2, 100), Vector3.new(4, 1.2, 200),
            Vector3.new(4, 1.2, H-40),
        }},
        -- Main NS road southbound (left lane)
        { name = "NS_south", waypoints = {
            Vector3.new(-4, 1.2, H-40), Vector3.new(-4, 1.2, 200), Vector3.new(-4, 1.2, 100),
            Vector3.new(-4, 1.2, 0), Vector3.new(-4, 1.2, -80), Vector3.new(-4, 1.2, -200),
            Vector3.new(-4, 1.2, -H+40),
        }},
        -- Main EW road eastbound
        { name = "EW_east", waypoints = {
            Vector3.new(-H+40, 1.2, 4), Vector3.new(-200, 1.2, 4), Vector3.new(-80, 1.2, 4),
            Vector3.new(0, 1.2, 4), Vector3.new(100, 1.2, 4), Vector3.new(200, 1.2, 4),
            Vector3.new(H-40, 1.2, 4),
        }},
        -- Main EW road westbound
        { name = "EW_west", waypoints = {
            Vector3.new(H-40, 1.2, -4), Vector3.new(200, 1.2, -4), Vector3.new(100, 1.2, -4),
            Vector3.new(0, 1.2, -4), Vector3.new(-80, 1.2, -4), Vector3.new(-200, 1.2, -4),
            Vector3.new(-H+40, 1.2, -4),
        }},
        -- Ring road north (eastbound)
        { name = "Ring_N", waypoints = {
            Vector3.new(-H+60, 1.2, 324), Vector3.new(-100, 1.2, 324), Vector3.new(0, 1.2, 324),
            Vector3.new(100, 1.2, 324), Vector3.new(H-60, 1.2, 324),
        }},
        -- Ring road south (westbound)
        { name = "Ring_S", waypoints = {
            Vector3.new(H-60, 1.2, -324), Vector3.new(100, 1.2, -324), Vector3.new(0, 1.2, -324),
            Vector3.new(-100, 1.2, -324), Vector3.new(-H+60, 1.2, -324),
        }},
    }
end

function TrafficService:_createCarModel(color: Color3): Model
    local car = Instance.new("Model")
    car.Name = "TrafficCar"

    -- Body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(4.5, 1.8, 9)
    body.Color = color
    body.Material = MAT.Smooth
    body.Anchored = true
    body.CanCollide = false
    body.CastShadow = true
    body.Parent = car

    -- Cabin
    local cabin = Instance.new("Part")
    cabin.Name = "Cabin"
    cabin.Size = Vector3.new(3.8, 1.4, 4.5)
    cabin.Position = body.Position + Vector3.new(0, 1.6, -0.5)
    cabin.Color = color
    cabin.Material = MAT.Smooth
    cabin.Anchored = true
    cabin.CanCollide = false
    cabin.Parent = car

    -- Windshield
    local windshield = Instance.new("Part")
    windshield.Name = "Windshield"
    windshield.Size = Vector3.new(3.5, 1.2, 0.2)
    windshield.Color = Color3.fromRGB(150, 200, 240)
    windshield.Material = MAT.Glass
    windshield.Transparency = 0.4
    windshield.Anchored = true
    windshield.CanCollide = false
    windshield.Parent = car

    -- Rear window
    local rearWin = Instance.new("Part")
    rearWin.Name = "RearWindow"
    rearWin.Size = Vector3.new(3.5, 1.2, 0.2)
    rearWin.Color = Color3.fromRGB(150, 200, 240)
    rearWin.Material = MAT.Glass
    rearWin.Transparency = 0.4
    rearWin.Anchored = true
    rearWin.CanCollide = false
    rearWin.Parent = car

    -- Headlights
    for _, side in ipairs({-1.4, 1.4}) do
        local hl = Instance.new("Part")
        hl.Name = "Headlight"
        hl.Size = Vector3.new(0.8, 0.5, 0.2)
        hl.Color = Color3.fromRGB(255, 255, 220)
        hl.Material = MAT.Neon
        hl.Anchored = true
        hl.CanCollide = false
        hl.Parent = car
    end

    -- Taillights
    for _, side in ipairs({-1.4, 1.4}) do
        local tl = Instance.new("Part")
        tl.Name = "Taillight"
        tl.Size = Vector3.new(0.6, 0.4, 0.2)
        tl.Color = Color3.fromRGB(255, 0, 0)
        tl.Material = MAT.Neon
        tl.Anchored = true
        tl.CanCollide = false
        tl.Parent = car
    end

    -- Wheels (visual only)
    for _, offset in ipairs({
        Vector3.new(-2.3, -0.6, 2.8), Vector3.new(2.3, -0.6, 2.8),
        Vector3.new(-2.3, -0.6, -2.8), Vector3.new(2.3, -0.6, -2.8),
    }) do
        local wheel = Instance.new("Part")
        wheel.Name = "Wheel"
        wheel.Shape = Enum.PartType.Cylinder
        wheel.Size = Vector3.new(0.5, 1.6, 1.6)
        wheel.Color = Color3.fromRGB(30, 30, 30)
        wheel.Material = MAT.Smooth
        wheel.Anchored = true
        wheel.CanCollide = false
        wheel.Parent = car
    end

    car.PrimaryPart = body
    return car
end

function TrafficService:_updateCarParts(car: Model, position: Vector3, lookTarget: Vector3)
    local body = car.PrimaryPart
    if not body then return end

    local cf = CFrame.lookAt(position, lookTarget)
    body.CFrame = cf

    -- Update cabin
    local cabin = car:FindFirstChild("Cabin")
    if cabin then
        cabin.CFrame = cf * CFrame.new(0, 1.6, -0.5)
    end

    -- Windshield
    local ws = car:FindFirstChild("Windshield")
    if ws then
        ws.CFrame = cf * CFrame.new(0, 1.6, 1.8)
    end

    -- Rear window
    local rw = car:FindFirstChild("RearWindow")
    if rw then
        rw.CFrame = cf * CFrame.new(0, 1.6, -2.8)
    end

    -- Headlights
    local hlIdx = 0
    for _, child in ipairs(car:GetChildren()) do
        if child.Name == "Headlight" then
            local side = hlIdx == 0 and -1.4 or 1.4
            child.CFrame = cf * CFrame.new(side, 0.3, 4.6)
            hlIdx = hlIdx + 1
        end
    end

    -- Taillights
    local tlIdx = 0
    for _, child in ipairs(car:GetChildren()) do
        if child.Name == "Taillight" then
            local side = tlIdx == 0 and -1.4 or 1.4
            child.CFrame = cf * CFrame.new(side, 0.3, -4.6)
            tlIdx = tlIdx + 1
        end
    end

    -- Wheels
    local wheelOffsets = {
        CFrame.new(-2.3, -0.6, 2.8) * CFrame.Angles(0, 0, math.rad(90)),
        CFrame.new(2.3, -0.6, 2.8) * CFrame.Angles(0, 0, math.rad(90)),
        CFrame.new(-2.3, -0.6, -2.8) * CFrame.Angles(0, 0, math.rad(90)),
        CFrame.new(2.3, -0.6, -2.8) * CFrame.Angles(0, 0, math.rad(90)),
    }
    local wIdx = 1
    for _, child in ipairs(car:GetChildren()) do
        if child.Name == "Wheel" and wIdx <= 4 then
            child.CFrame = cf * wheelOffsets[wIdx]
            wIdx = wIdx + 1
        end
    end
end

function TrafficService:_spawnAllCars()
    local trafficFolder = workspace:FindFirstChild("TrafficCars")
    if not trafficFolder then
        trafficFolder = Instance.new("Folder")
        trafficFolder.Name = "TrafficCars"
        trafficFolder.Parent = workspace
    end

    local rng = Random.new(42)
    local carCount = Constants.TRAFFIC_CAR_COUNT or 12

    for i = 1, carCount do
        local routeIdx = ((i - 1) % #self._routes) + 1
        local route = self._routes[routeIdx]
        local color = CAR_COLORS[rng:NextInteger(1, #CAR_COLORS)]
        local speed = rng:NextInteger(Constants.TRAFFIC_SPEED_MIN or 25, Constants.TRAFFIC_SPEED_MAX or 45)

        local car = self:_createCarModel(color)
        car.Name = "TrafficCar_" .. i
        car.Parent = trafficFolder

        -- Start at beginning of route
        local startPos = route.waypoints[1]
        local lookPos = route.waypoints[2] or (startPos + Vector3.new(0, 0, 1))
        self:_updateCarParts(car, startPos, lookPos)

        table.insert(self._cars, {
            model = car,
            route = route,
            waypointIdx = 1,
            progress = 0,
            speed = speed,
        })
    end
end

function TrafficService:_startDriving()
    RunService.Heartbeat:Connect(function(dt)
        for _, carData in ipairs(self._cars) do
            self:_updateCar(carData, dt)
        end
    end)
end

function TrafficService:_updateCar(carData: { [string]: any }, dt: number)
    local route = carData.route
    local waypoints = route.waypoints
    local idx = carData.waypointIdx

    if idx >= #waypoints then
        -- Loop back to start
        carData.waypointIdx = 1
        carData.progress = 0
        return
    end

    local from = waypoints[idx]
    local to = waypoints[idx + 1]
    local segmentLength = (to - from).Magnitude

    if segmentLength < 0.1 then
        carData.waypointIdx = idx + 1
        carData.progress = 0
        return
    end

    carData.progress = carData.progress + (carData.speed * dt) / segmentLength

    if carData.progress >= 1 then
        carData.waypointIdx = idx + 1
        carData.progress = 0
        return
    end

    local pos = from:Lerp(to, carData.progress)
    local lookTarget = to
    if idx + 1 < #waypoints then
        -- Smooth look-ahead
        local nextSeg = waypoints[idx + 2] or to
        lookTarget = to:Lerp(nextSeg, 0.3)
    end

    self:_updateCarParts(carData.model, pos, lookTarget)
end

return TrafficService
