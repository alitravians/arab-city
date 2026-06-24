--[[
    Arab City v2.0 - MapBuilder
    Procedurally builds the entire 3D city: buildings, streets, furniture, landmarks.
    All geometry is created via code (equivalent to Blender-designed meshes).
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapBuilder = {}

local Shared, Constants

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function makePart(parent, name, size, position, color, material, anchored)
    local p = Instance.new("Part")
    p.Name = name or "Part"
    p.Size = size or Vector3.new(4, 4, 4)
    p.Position = position or Vector3.new(0, 0, 0)
    p.BrickColor = BrickColor.new(color or "Medium stone grey")
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = if anchored == nil then true else anchored
    p.CanCollide = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function makeModel(parent, name, primaryPart)
    local m = Instance.new("Model")
    m.Name = name or "Model"
    m.Parent = parent
    if primaryPart then m.PrimaryPart = primaryPart end
    return m
end

local function addLabel(parent, text, offset)
    local bb = Instance.new("BillboardGui")
    bb.Name = "Label"
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = offset or Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = parent

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = text
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.TextStrokeTransparency = 0.3
    tl.TextScaled = true
    tl.Font = Enum.Font.GothamBold
    tl.Parent = bb
end

local function addProximityPrompt(parent, actionText, objectText, distance)
    local pp = Instance.new("ProximityPrompt")
    pp.ActionText = actionText or "تفاعل"
    pp.ObjectText = objectText or ""
    pp.MaxActivationDistance = distance or 10
    pp.HoldDuration = 0.3
    pp.Parent = parent
    return pp
end

------------------------------------------------------------
-- Furniture helpers
------------------------------------------------------------

local function addDesk(parent, pos)
    local desk = makePart(parent, "Desk", Vector3.new(4, 0.3, 2), pos, "Nougat", Enum.Material.Wood)
    makePart(parent, "DeskLeg1", Vector3.new(0.3, 2, 0.3), pos + Vector3.new(-1.7, -1.15, -0.7), "Nougat", Enum.Material.Wood)
    makePart(parent, "DeskLeg2", Vector3.new(0.3, 2, 0.3), pos + Vector3.new(1.7, -1.15, -0.7), "Nougat", Enum.Material.Wood)
    makePart(parent, "DeskLeg3", Vector3.new(0.3, 2, 0.3), pos + Vector3.new(-1.7, -1.15, 0.7), "Nougat", Enum.Material.Wood)
    makePart(parent, "DeskLeg4", Vector3.new(0.3, 2, 0.3), pos + Vector3.new(1.7, -1.15, 0.7), "Nougat", Enum.Material.Wood)
    return desk
end

local function addChair(parent, pos)
    local seat = makePart(parent, "ChairSeat", Vector3.new(2, 0.3, 2), pos, "Dark stone grey", Enum.Material.SmoothPlastic)
    makePart(parent, "ChairBack", Vector3.new(2, 2, 0.3), pos + Vector3.new(0, 1, -0.85), "Dark stone grey", Enum.Material.SmoothPlastic)
    makePart(parent, "ChairLeg1", Vector3.new(0.2, 1.5, 0.2), pos + Vector3.new(-0.8, -0.9, -0.8), "Dark stone grey")
    makePart(parent, "ChairLeg2", Vector3.new(0.2, 1.5, 0.2), pos + Vector3.new(0.8, -0.9, -0.8), "Dark stone grey")
    makePart(parent, "ChairLeg3", Vector3.new(0.2, 1.5, 0.2), pos + Vector3.new(-0.8, -0.9, 0.8), "Dark stone grey")
    makePart(parent, "ChairLeg4", Vector3.new(0.2, 1.5, 0.2), pos + Vector3.new(0.8, -0.9, 0.8), "Dark stone grey")
    return seat
end

local function addBed(parent, pos)
    local frame = makePart(parent, "BedFrame", Vector3.new(4, 0.5, 6), pos, "Nougat", Enum.Material.Wood)
    makePart(parent, "Mattress", Vector3.new(3.8, 0.6, 5.5), pos + Vector3.new(0, 0.55, 0), "Pastel Blue", Enum.Material.Fabric)
    makePart(parent, "Pillow", Vector3.new(2, 0.4, 1), pos + Vector3.new(0, 0.95, -2), "White", Enum.Material.Fabric)
    makePart(parent, "Headboard", Vector3.new(4, 2, 0.3), pos + Vector3.new(0, 1.25, -2.85), "Nougat", Enum.Material.Wood)
    return frame
end

local function addSofa(parent, pos)
    local base = makePart(parent, "SofaBase", Vector3.new(6, 1, 2.5), pos, "Maroon", Enum.Material.Fabric)
    makePart(parent, "SofaBack", Vector3.new(6, 2, 0.5), pos + Vector3.new(0, 1.25, -1), "Maroon", Enum.Material.Fabric)
    makePart(parent, "SofaArmL", Vector3.new(0.5, 1.5, 2.5), pos + Vector3.new(-2.75, 0.75, 0), "Maroon", Enum.Material.Fabric)
    makePart(parent, "SofaArmR", Vector3.new(0.5, 1.5, 2.5), pos + Vector3.new(2.75, 0.75, 0), "Maroon", Enum.Material.Fabric)
    return base
end

local function addTV(parent, pos)
    makePart(parent, "TVStand", Vector3.new(3, 1.5, 1), pos + Vector3.new(0, -0.75, 0), "Dark stone grey", Enum.Material.SmoothPlastic)
    local screen = makePart(parent, "TVScreen", Vector3.new(5, 3, 0.2), pos + Vector3.new(0, 1.5, 0), "Really black", Enum.Material.Glass)
    return screen
end

local function addKitchenCounter(parent, pos)
    makePart(parent, "Counter", Vector3.new(6, 3, 2), pos, "Institutional white", Enum.Material.Marble)
    makePart(parent, "Sink", Vector3.new(1.5, 0.3, 1), pos + Vector3.new(-1.5, 1.65, 0), "Medium stone grey", Enum.Material.Metal)
    makePart(parent, "Stove", Vector3.new(1.5, 0.1, 1.2), pos + Vector3.new(1.5, 1.55, 0), "Really black", Enum.Material.Metal)
end

local function addTable(parent, pos, tableColor)
    makePart(parent, "Table", Vector3.new(5, 0.3, 3), pos, tableColor or "Brown", Enum.Material.Wood)
    makePart(parent, "TLeg1", Vector3.new(0.3, 2, 0.3), pos + Vector3.new(-2.2, -1.15, -1.2), "Brown", Enum.Material.Wood)
    makePart(parent, "TLeg2", Vector3.new(0.3, 2, 0.3), pos + Vector3.new(2.2, -1.15, -1.2), "Brown", Enum.Material.Wood)
    makePart(parent, "TLeg3", Vector3.new(0.3, 2, 0.3), pos + Vector3.new(-2.2, -1.15, 1.2), "Brown", Enum.Material.Wood)
    makePart(parent, "TLeg4", Vector3.new(0.3, 2, 0.3), pos + Vector3.new(2.2, -1.15, 1.2), "Brown", Enum.Material.Wood)
end

------------------------------------------------------------
-- Building creation
------------------------------------------------------------

local function createBuilding(parent, config)
    local model = Instance.new("Model")
    model.Name = config.name or "Building"
    model:SetAttribute("BuildingType", config.type or config.name)

    local w = config.width or 30
    local h = config.height or 20
    local d = config.depth or 30
    local pos = config.position or Vector3.new(0, 0, 0)
    local wallColor = config.wallColor or "Institutional white"
    local roofColor = config.roofColor or "Dark stone grey"

    -- Floor
    makePart(model, "Floor", Vector3.new(w, 0.5, d), pos + Vector3.new(0, 0.25, 0), "Flint", Enum.Material.Concrete)

    -- Walls (4 sides with door opening on front)
    -- Back wall
    makePart(model, "WallBack", Vector3.new(w, h, 0.5), pos + Vector3.new(0, h / 2, -d / 2), wallColor, Enum.Material.Concrete)
    -- Left wall
    makePart(model, "WallLeft", Vector3.new(0.5, h, d), pos + Vector3.new(-w / 2, h / 2, 0), wallColor, Enum.Material.Concrete)
    -- Right wall
    makePart(model, "WallRight", Vector3.new(0.5, h, d), pos + Vector3.new(w / 2, h / 2, 0), wallColor, Enum.Material.Concrete)
    -- Front wall left side
    makePart(model, "WallFrontL", Vector3.new(w / 2 - 3, h, 0.5), pos + Vector3.new(-w / 4 - 1.5, h / 2, d / 2), wallColor, Enum.Material.Concrete)
    -- Front wall right side
    makePart(model, "WallFrontR", Vector3.new(w / 2 - 3, h, 0.5), pos + Vector3.new(w / 4 + 1.5, h / 2, d / 2), wallColor, Enum.Material.Concrete)
    -- Front wall top (above door)
    makePart(model, "WallFrontTop", Vector3.new(6, h - 8, 0.5), pos + Vector3.new(0, h - (h - 8) / 2, d / 2), wallColor, Enum.Material.Concrete)

    -- Roof
    makePart(model, "Roof", Vector3.new(w + 2, 0.5, d + 2), pos + Vector3.new(0, h + 0.25, 0), roofColor, Enum.Material.Concrete)

    -- Door frame
    local doorPart = makePart(model, "Door", Vector3.new(5, 0.5, 0.5), pos + Vector3.new(0, 0.25, d / 2 + 0.5), "Bright green", Enum.Material.Neon)
    doorPart.Transparency = 0.8
    doorPart.CanCollide = false
    model:SetAttribute("Entrance", "Door")

    -- Label
    local primary = model:FindFirstChild("Floor")
    if primary then model.PrimaryPart = primary end
    addLabel(doorPart, config.label or config.name, Vector3.new(0, 6, 0))

    model.Parent = parent
    return model, doorPart
end

------------------------------------------------------------
-- Street creation
------------------------------------------------------------

local function createStreet(parent, startPos, endPos, width)
    width = width or 12
    local direction = (endPos - startPos)
    local length = direction.Magnitude
    local midPoint = (startPos + endPos) / 2
    local lookAt = CFrame.lookAt(startPos, endPos)

    local road = Instance.new("Part")
    road.Name = "Road"
    road.Size = Vector3.new(width, 0.3, length)
    road.CFrame = CFrame.lookAt(midPoint, endPos) * CFrame.new(0, 0.15, 0)
    road.BrickColor = BrickColor.new("Dark stone grey")
    road.Material = Enum.Material.Asphalt
    road.Anchored = true
    road.TopSurface = Enum.SurfaceType.Smooth
    road.BottomSurface = Enum.SurfaceType.Smooth
    road.Parent = parent

    -- Center line
    local line = Instance.new("Part")
    line.Name = "CenterLine"
    line.Size = Vector3.new(0.5, 0.05, length - 4)
    line.CFrame = road.CFrame * CFrame.new(0, 0.18, 0)
    line.BrickColor = BrickColor.new("Bright yellow")
    line.Material = Enum.Material.SmoothPlastic
    line.Anchored = true
    line.CanCollide = false
    line.Parent = parent

    -- Sidewalks
    local sideOffset = width / 2 + 2
    for _, side in ipairs({ -1, 1 }) do
        local sw = Instance.new("Part")
        sw.Name = "Sidewalk"
        sw.Size = Vector3.new(4, 0.5, length)
        sw.CFrame = road.CFrame * CFrame.new(side * sideOffset, 0.1, 0)
        sw.BrickColor = BrickColor.new("Medium stone grey")
        sw.Material = Enum.Material.Concrete
        sw.Anchored = true
        sw.TopSurface = Enum.SurfaceType.Smooth
        sw.BottomSurface = Enum.SurfaceType.Smooth
        sw.Parent = parent
    end

    return road
end

local function createIntersection(parent, position, size)
    size = size or 20
    local inter = makePart(parent, "Intersection", Vector3.new(size, 0.3, size), position + Vector3.new(0, 0.15, 0), "Dark stone grey", Enum.Material.Asphalt)
    return inter
end

------------------------------------------------------------
-- Traffic light
------------------------------------------------------------

local function createTrafficLight(parent, position)
    local model = Instance.new("Model")
    model.Name = "TrafficLight"

    local pole = makePart(model, "Pole", Vector3.new(0.4, 12, 0.4), position + Vector3.new(0, 6, 0), "Dark stone grey", Enum.Material.Metal)
    model.PrimaryPart = pole

    local box = makePart(model, "LightBox", Vector3.new(1.2, 3, 1.2), position + Vector3.new(0, 12, 0), "Really black", Enum.Material.Metal)

    local red = makePart(model, "RedLight", Vector3.new(0.8, 0.8, 0.2), position + Vector3.new(0, 13, 0.6), "Bright red", Enum.Material.Neon)
    local yellow = makePart(model, "YellowLight", Vector3.new(0.8, 0.8, 0.2), position + Vector3.new(0, 12, 0.6), "Bright yellow", Enum.Material.Neon)
    local green = makePart(model, "GreenLight", Vector3.new(0.8, 0.8, 0.2), position + Vector3.new(0, 11, 0.6), "Bright green", Enum.Material.Neon)

    model.Parent = parent
    return model
end

------------------------------------------------------------
-- Specific buildings
------------------------------------------------------------

local function furnishHospital(model, basePos)
    local interior = Instance.new("Folder")
    interior.Name = "Interior"
    interior.Parent = model
    addDesk(interior, basePos + Vector3.new(-8, 2, -8))
    addChair(interior, basePos + Vector3.new(-8, 2, -5))
    addBed(interior, basePos + Vector3.new(5, 1, -5))
    addBed(interior, basePos + Vector3.new(5, 1, 5))
    -- Medical cabinet
    makePart(interior, "Cabinet", Vector3.new(2, 5, 1), basePos + Vector3.new(-12, 3, -12), "Institutional white", Enum.Material.SmoothPlastic)
end

local function furnishBank(model, basePos)
    local interior = Instance.new("Folder")
    interior.Name = "Interior"
    interior.Parent = model
    addDesk(interior, basePos + Vector3.new(-5, 2, -5))
    addDesk(interior, basePos + Vector3.new(5, 2, -5))
    addChair(interior, basePos + Vector3.new(-5, 2, -2))
    addChair(interior, basePos + Vector3.new(5, 2, -2))
    -- Vault door
    makePart(interior, "VaultDoor", Vector3.new(5, 7, 1), basePos + Vector3.new(0, 4, -13), "Dark stone grey", Enum.Material.DiamondPlate)
    -- Safe boxes
    for i = 0, 3 do
        makePart(interior, "SafeBox" .. i, Vector3.new(1, 1, 1), basePos + Vector3.new(-10 + i * 2, 1.5, -12), "Medium stone grey", Enum.Material.Metal)
    end
end

local function furnishMall(model, basePos)
    local interior = Instance.new("Folder")
    interior.Name = "Interior"
    interior.Parent = model
    -- Display shelves
    for i = 0, 2 do
        makePart(interior, "Shelf" .. i, Vector3.new(6, 4, 1), basePos + Vector3.new(-8 + i * 8, 2.5, -5), "Brown", Enum.Material.Wood)
    end
    addTable(interior, basePos + Vector3.new(0, 2, 5))
    -- Checkout counter
    makePart(interior, "Checkout", Vector3.new(8, 3, 2), basePos + Vector3.new(0, 2, 10), "Institutional white", Enum.Material.SmoothPlastic)
end

local function furnishPoliceStation(model, basePos)
    local interior = Instance.new("Folder")
    interior.Name = "Interior"
    interior.Parent = model
    addDesk(interior, basePos + Vector3.new(-5, 2, -5))
    addDesk(interior, basePos + Vector3.new(5, 2, -5))
    addChair(interior, basePos + Vector3.new(-5, 2, -2))
    addChair(interior, basePos + Vector3.new(5, 2, -2))
    -- Jail cell
    makePart(interior, "CellWall1", Vector3.new(0.3, 8, 8), basePos + Vector3.new(10, 4, -8), "Medium stone grey", Enum.Material.Metal)
    makePart(interior, "CellBars", Vector3.new(8, 8, 0.3), basePos + Vector3.new(6, 4, -4), "Medium stone grey", Enum.Material.DiamondPlate)
end

local function furnishFireStation(model, basePos)
    local interior = Instance.new("Folder")
    interior.Name = "Interior"
    interior.Parent = model
    -- Fire truck bay
    makePart(interior, "TruckBay", Vector3.new(8, 0.2, 12), basePos + Vector3.new(0, 0.6, 0), "Flint", Enum.Material.Concrete)
    -- Lockers
    for i = 0, 3 do
        makePart(interior, "Locker" .. i, Vector3.new(1.5, 5, 1), basePos + Vector3.new(-10 + i * 3, 3, -12), "Dark stone grey", Enum.Material.Metal)
    end
    addBed(interior, basePos + Vector3.new(8, 1, -8))
end

local function furnishAirport(model, basePos)
    local interior = Instance.new("Folder")
    interior.Name = "Interior"
    interior.Parent = model
    -- Check-in counters
    for i = 0, 2 do
        makePart(interior, "CheckIn" .. i, Vector3.new(4, 3, 2), basePos + Vector3.new(-10 + i * 10, 2, 5), "Institutional white", Enum.Material.SmoothPlastic)
    end
    -- Seating
    for i = 0, 4 do
        addChair(interior, basePos + Vector3.new(-8 + i * 4, 1.5, -5))
    end
    -- Conveyor belt
    makePart(interior, "Conveyor", Vector3.new(20, 1, 2), basePos + Vector3.new(0, 1, -10), "Dark stone grey", Enum.Material.Metal)
end

local function furnishDealership(model, basePos)
    local interior = Instance.new("Folder")
    interior.Name = "Interior"
    interior.Parent = model
    -- Display platforms
    local carColors = {"Bright red", "Bright blue", "White", "Black", "Bright yellow"}
    for i = 0, 4 do
        local platPos = basePos + Vector3.new(-12 + i * 6, 0.6, -3)
        makePart(interior, "Platform" .. i, Vector3.new(5, 0.3, 8), platPos, "Institutional white", Enum.Material.Marble)
        -- Display car
        local car = makePart(interior, "DisplayCar" .. i, Vector3.new(4, 2, 7), platPos + Vector3.new(0, 1.4, 0), carColors[(i % #carColors) + 1], Enum.Material.SmoothPlastic)
        makePart(interior, "CarRoof" .. i, Vector3.new(3.5, 1.2, 3.5), platPos + Vector3.new(0, 2.9, -0.5), carColors[(i % #carColors) + 1], Enum.Material.SmoothPlastic)
    end
    addDesk(interior, basePos + Vector3.new(0, 2, 10))
end

local function furnishRestaurant(model, basePos)
    local interior = Instance.new("Folder")
    interior.Name = "Interior"
    interior.Parent = model
    -- Tables and chairs
    for i = 0, 2 do
        for j = 0, 1 do
            local tPos = basePos + Vector3.new(-6 + i * 6, 2, -4 + j * 8)
            addTable(interior, tPos, "Reddish brown")
            addChair(interior, tPos + Vector3.new(-2, 0, 0))
            addChair(interior, tPos + Vector3.new(2, 0, 0))
        end
    end
    addKitchenCounter(interior, basePos + Vector3.new(0, 2, -12))
end

local function furnishHouse(model, basePos)
    local interior = Instance.new("Folder")
    interior.Name = "Interior"
    interior.Parent = model
    -- Bedroom
    addBed(interior, basePos + Vector3.new(-5, 1, -5))
    -- Living room
    addSofa(interior, basePos + Vector3.new(5, 1, -3))
    addTV(interior, basePos + Vector3.new(5, 3, -8))
    -- Kitchen
    addKitchenCounter(interior, basePos + Vector3.new(-5, 1.5, 5))
    addTable(interior, basePos + Vector3.new(3, 2, 5))
    addChair(interior, basePos + Vector3.new(1, 1.5, 5))
    addChair(interior, basePos + Vector3.new(5, 1.5, 5))
end

local function furnishGasStation(model, basePos)
    local interior = Instance.new("Folder")
    interior.Name = "Interior"
    interior.Parent = model
    -- Fuel pumps
    for i = 0, 2 do
        local pumpPos = basePos + Vector3.new(-6 + i * 6, 0, 5)
        makePart(interior, "Pump" .. i, Vector3.new(1, 4, 1), pumpPos + Vector3.new(0, 2.5, 0), "Bright red", Enum.Material.Metal)
        makePart(interior, "PumpBase" .. i, Vector3.new(2, 0.5, 2), pumpPos + Vector3.new(0, 0.5, 0), "Medium stone grey", Enum.Material.Concrete)
    end
    -- Canopy
    makePart(interior, "Canopy", Vector3.new(22, 0.3, 14), basePos + Vector3.new(0, 8, 5), "Institutional white", Enum.Material.Metal)
    makePart(interior, "CanopyPole1", Vector3.new(0.5, 8, 0.5), basePos + Vector3.new(-10, 4, 0), "Medium stone grey", Enum.Material.Metal)
    makePart(interior, "CanopyPole2", Vector3.new(0.5, 8, 0.5), basePos + Vector3.new(10, 4, 0), "Medium stone grey", Enum.Material.Metal)
    makePart(interior, "CanopyPole3", Vector3.new(0.5, 8, 0.5), basePos + Vector3.new(-10, 4, 10), "Medium stone grey", Enum.Material.Metal)
    makePart(interior, "CanopyPole4", Vector3.new(0.5, 8, 0.5), basePos + Vector3.new(10, 4, 10), "Medium stone grey", Enum.Material.Metal)
end

------------------------------------------------------------
-- Main city build
------------------------------------------------------------

function MapBuilder:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants

    task.spawn(function()
        self:_buildCity()
    end)
end

function MapBuilder:_buildCity()
    -- Ground / terrain base
    local ground = makePart(Workspace, "CityGround", Vector3.new(800, 1, 800), Vector3.new(0, -0.5, 0), "Bright green", Enum.Material.Grass)
    ground.Name = "CityGround"

    -- Folders
    local buildingsFolder = Instance.new("Folder")
    buildingsFolder.Name = "Buildings"
    buildingsFolder.Parent = Workspace

    local streetsFolder = Instance.new("Folder")
    streetsFolder.Name = "Streets"
    streetsFolder.Parent = Workspace

    local decorFolder = Instance.new("Folder")
    decorFolder.Name = "Decorations"
    decorFolder.Parent = Workspace

    -- =============================================
    -- STREETS — Grid-based road network
    -- =============================================
    -- Main horizontal roads
    createStreet(streetsFolder, Vector3.new(-350, 0, 0), Vector3.new(350, 0, 0), 14)
    createStreet(streetsFolder, Vector3.new(-350, 0, 120), Vector3.new(350, 0, 120), 14)
    createStreet(streetsFolder, Vector3.new(-350, 0, -120), Vector3.new(350, 0, -120), 14)

    -- Main vertical roads
    createStreet(streetsFolder, Vector3.new(0, 0, -350), Vector3.new(0, 0, 350), 14)
    createStreet(streetsFolder, Vector3.new(120, 0, -350), Vector3.new(120, 0, 350), 14)
    createStreet(streetsFolder, Vector3.new(-120, 0, -350), Vector3.new(-120, 0, 350), 14)

    -- Intersections
    for _, ix in ipairs({-120, 0, 120}) do
        for _, iz in ipairs({-120, 0, 120}) do
            createIntersection(streetsFolder, Vector3.new(ix, 0, iz), 20)
        end
    end

    -- Traffic lights at major intersections
    createTrafficLight(decorFolder, Vector3.new(12, 0, 12))
    createTrafficLight(decorFolder, Vector3.new(-12, 0, -12))
    createTrafficLight(decorFolder, Vector3.new(12, 0, -12))
    createTrafficLight(decorFolder, Vector3.new(-12, 0, 12))
    createTrafficLight(decorFolder, Vector3.new(132, 0, 12))
    createTrafficLight(decorFolder, Vector3.new(-132, 0, 12))

    -- Street lights along main road
    for x = -300, 300, 40 do
        local pole = makePart(decorFolder, "StreetLight", Vector3.new(0.3, 8, 0.3), Vector3.new(x, 4, 10), "Dark stone grey", Enum.Material.Metal)
        local lamp = makePart(decorFolder, "Lamp", Vector3.new(1, 0.5, 1), Vector3.new(x, 8.5, 10), "Cool yellow", Enum.Material.Neon)
        local light = Instance.new("PointLight")
        light.Range = 30
        light.Brightness = 0.8
        light.Color = Color3.fromRGB(255, 230, 180)
        light.Parent = lamp
    end

    -- =============================================
    -- BUILDINGS
    -- =============================================

    -- Hospital
    local hospital, hospitalDoor = createBuilding(buildingsFolder, {
        name = "Hospital",
        type = "مستشفى",
        label = "🏥 المستشفى",
        position = Vector3.new(-60, 0, -60),
        width = 35,
        height = 25,
        depth = 35,
        wallColor = "Institutional white",
        roofColor = "Bright red",
    })
    furnishHospital(hospital, Vector3.new(-60, 0, -60))

    -- Bank
    local bank, bankDoor = createBuilding(buildingsFolder, {
        name = "Bank",
        type = "بنك",
        label = "🏦 البنك",
        position = Vector3.new(60, 0, -60),
        width = 30,
        height = 22,
        depth = 30,
        wallColor = "Sand blue",
        roofColor = "Dark stone grey",
    })
    furnishBank(bank, Vector3.new(60, 0, -60))

    -- Mall
    local mall, mallDoor = createBuilding(buildingsFolder, {
        name = "Mall",
        type = "مول",
        label = "🏬 المول",
        position = Vector3.new(-60, 0, 60),
        width = 40,
        height = 20,
        depth = 35,
        wallColor = "Pastel Blue",
        roofColor = "Medium stone grey",
    })
    furnishMall(mall, Vector3.new(-60, 0, 60))

    -- Police Station
    local police, policeDoor = createBuilding(buildingsFolder, {
        name = "PoliceStation",
        type = "شرطة",
        label = "🚔 مركز الشرطة",
        position = Vector3.new(60, 0, 60),
        width = 30,
        height = 18,
        depth = 30,
        wallColor = "Medium blue",
        roofColor = "Dark stone grey",
    })
    furnishPoliceStation(police, Vector3.new(60, 0, 60))

    -- Fire Station
    local fire, fireDoor = createBuilding(buildingsFolder, {
        name = "FireStation",
        type = "إطفاء",
        label = "🚒 محطة الإطفاء",
        position = Vector3.new(-60, 0, -180),
        width = 35,
        height = 20,
        depth = 30,
        wallColor = "Bright red",
        roofColor = "Dark stone grey",
    })
    furnishFireStation(fire, Vector3.new(-60, 0, -180))

    -- Airport
    local airport, airportDoor = createBuilding(buildingsFolder, {
        name = "Airport",
        type = "مطار",
        label = "✈️ المطار",
        position = Vector3.new(200, 0, -180),
        width = 60,
        height = 25,
        depth = 40,
        wallColor = "Institutional white",
        roofColor = "Medium stone grey",
    })
    furnishAirport(airport, Vector3.new(200, 0, -180))

    -- Car Dealership
    local dealer, dealerDoor = createBuilding(buildingsFolder, {
        name = "CarDealership",
        type = "معرض سيارات",
        label = "🚗 معرض السيارات",
        position = Vector3.new(200, 0, 60),
        width = 40,
        height = 15,
        depth = 30,
        wallColor = "Institutional white",
        roofColor = "Bright blue",
    })
    furnishDealership(dealer, Vector3.new(200, 0, 60))

    -- Restaurant
    local restaurant, restDoor = createBuilding(buildingsFolder, {
        name = "Restaurant",
        type = "مطعم",
        label = "🍽️ المطعم",
        position = Vector3.new(-200, 0, 60),
        width = 25,
        height = 15,
        depth = 25,
        wallColor = "Pastel orange",
        roofColor = "Nougat",
    })
    furnishRestaurant(restaurant, Vector3.new(-200, 0, 60))

    -- Houses
    local housePositions = {
        Vector3.new(-200, 0, -60),
        Vector3.new(-200, 0, -180),
        Vector3.new(200, 0, -60),
        Vector3.new(-60, 0, 180),
        Vector3.new(60, 0, 180),
    }
    for i, hPos in ipairs(housePositions) do
        local house, houseDoor = createBuilding(buildingsFolder, {
            name = "House_" .. i,
            type = "بيت",
            label = "🏠 بيت " .. i,
            position = hPos,
            width = 20,
            height = 12,
            depth = 20,
            wallColor = if i % 2 == 0 then "Pastel brown" else "Light stone grey",
            roofColor = "Nougat",
        })
        furnishHouse(house, hPos)
    end

    -- Gas Station
    local gas, gasDoor = createBuilding(buildingsFolder, {
        name = "GasStation",
        type = "محطة وقود",
        label = "⛽ محطة الوقود",
        position = Vector3.new(200, 0, 180),
        width = 25,
        height = 10,
        depth = 20,
        wallColor = "Institutional white",
        roofColor = "Bright red",
    })
    furnishGasStation(gas, Vector3.new(200, 0, 180))

    -- =============================================
    -- DECORATIONS: Trees, benches, fountains
    -- =============================================

    -- Trees
    local rng = Random.new()
    local treePositions = {}
    for x = -300, 300, 60 do
        for z = -300, 300, 60 do
            local tp = Vector3.new(x + rng:NextInteger(-10, 10), 0, z + rng:NextInteger(-10, 10))
            -- skip if too close to road or building
            local onRoad = (math.abs(tp.X) < 10 or math.abs(tp.X - 120) < 10 or math.abs(tp.X + 120) < 10) or
                           (math.abs(tp.Z) < 10 or math.abs(tp.Z - 120) < 10 or math.abs(tp.Z + 120) < 10)
            if not onRoad then
                table.insert(treePositions, tp)
            end
        end
    end

    for i, tp in ipairs(treePositions) do
        local trunkH = rng:NextInteger(6, 10)
        local trunk = makePart(decorFolder, "Trunk", Vector3.new(1, trunkH, 1), tp + Vector3.new(0, trunkH / 2, 0), "Nougat", Enum.Material.Wood)
        local leaves = makePart(decorFolder, "Leaves", Vector3.new(6, 5, 6), tp + Vector3.new(0, trunkH + 2.5, 0), "Forest green", Enum.Material.Grass)
        leaves.Shape = Enum.PartType.Ball
    end

    -- Benches at intervals
    for _, benchPos in ipairs({
        Vector3.new(20, 0, 15), Vector3.new(-20, 0, 15),
        Vector3.new(140, 0, 15), Vector3.new(-140, 0, 15),
        Vector3.new(20, 0, 135), Vector3.new(-20, 0, 135),
    }) do
        local seat = makePart(decorFolder, "BenchSeat", Vector3.new(4, 0.3, 1.5), benchPos + Vector3.new(0, 1.5, 0), "Nougat", Enum.Material.Wood)
        makePart(decorFolder, "BenchBack", Vector3.new(4, 1.5, 0.3), benchPos + Vector3.new(0, 2.5, -0.6), "Nougat", Enum.Material.Wood)
        makePart(decorFolder, "BenchLeg1", Vector3.new(0.3, 1.5, 0.3), benchPos + Vector3.new(-1.5, 0.75, 0), "Dark stone grey", Enum.Material.Metal)
        makePart(decorFolder, "BenchLeg2", Vector3.new(0.3, 1.5, 0.3), benchPos + Vector3.new(1.5, 0.75, 0), "Dark stone grey", Enum.Material.Metal)
    end

    -- Central fountain
    local fountainPos = Vector3.new(0, 0, 0)
    makePart(decorFolder, "FountainBase", Vector3.new(12, 1, 12), fountainPos + Vector3.new(0, 0.5, 0), "Medium stone grey", Enum.Material.Marble)
    makePart(decorFolder, "FountainPool", Vector3.new(10, 1.5, 10), fountainPos + Vector3.new(0, 1.25, 0), "Pastel light blue", Enum.Material.Glass)
    makePart(decorFolder, "FountainPillar", Vector3.new(1, 5, 1), fountainPos + Vector3.new(0, 3.5, 0), "Medium stone grey", Enum.Material.Marble)
    local spout = makePart(decorFolder, "FountainSpout", Vector3.new(2, 0.5, 2), fountainPos + Vector3.new(0, 6, 0), "Pastel light blue", Enum.Material.Neon)
    local pLight = Instance.new("PointLight")
    pLight.Range = 20
    pLight.Brightness = 1
    pLight.Color = Color3.fromRGB(100, 180, 255)
    pLight.Parent = spout

    print("[ArabCity] MapBuilder: City built successfully — " .. tostring(#buildingsFolder:GetChildren()) .. " buildings")
end

return MapBuilder
