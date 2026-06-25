--[[
    Arab City v2.0 - MapBuilder (Blender 3D Design Edition)
    All buildings, vehicles, streets, furniture, and decorations are
    designed in Blender and translated into detailed Part-based assemblies.
    Each model uses dozens of Parts with realistic materials and colors.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapBuilder = {}

local Shared, Constants

------------------------------------------------------------
-- Core helpers
------------------------------------------------------------

local function makePart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?, transparency: number?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if transparency then
        p.Transparency = transparency
    end
    p.Parent = parent
    return p
end

local function makeCylinder(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?, rotation: Vector3?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Shape = Enum.PartType.Cylinder
    p.Size = size
    p.Position = position
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if rotation then
        p.Orientation = rotation
    end
    p.Parent = parent
    return p
end

local function makeBall(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Shape = Enum.PartType.Ball
    p.Size = size
    p.Position = position
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = true
    p.Parent = parent
    return p
end

local function makeWedge(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): WedgePart
    local w = Instance.new("WedgePart")
    w.Name = name
    w.Size = size
    w.CFrame = cframe
    w.Color = color
    w.Material = material or Enum.Material.SmoothPlastic
    w.Anchored = true
    w.CanCollide = true
    w.TopSurface = Enum.SurfaceType.Smooth
    w.BottomSurface = Enum.SurfaceType.Smooth
    w.Parent = parent
    return w
end

local function makeModel(parent: Instance, name: string): Model
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent
    return m
end

local function addLight(parent: Instance, lightColor: Color3, range: number, brightness: number)
    local pl = Instance.new("PointLight")
    pl.Color = lightColor
    pl.Range = range
    pl.Brightness = brightness
    pl.Parent = parent
end

local function addSpotLight(parent: Instance, lightColor: Color3, range: number, brightness: number, face: Enum.NormalId?)
    local sl = Instance.new("SpotLight")
    sl.Color = lightColor
    sl.Range = range
    sl.Brightness = brightness
    sl.Angle = 90
    sl.Face = face or Enum.NormalId.Bottom
    sl.Parent = parent
end

local function addLabel(parent: Instance, text: string, offset: Vector3?)
    local bb = Instance.new("BillboardGui")
    bb.Name = "Label"
    bb.Size = UDim2.new(0, 220, 0, 50)
    bb.StudsOffset = offset or Vector3.new(0, 4, 0)
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

local function addProximityPrompt(parent: Instance, actionText: string, objectText: string?, distance: number?): ProximityPrompt
    local pp = Instance.new("ProximityPrompt")
    pp.ActionText = actionText
    pp.ObjectText = objectText or ""
    pp.MaxActivationDistance = distance or 12
    pp.HoldDuration = 0.3
    pp.Parent = parent
    return pp
end

------------------------------------------------------------
-- Blender-accurate color palette (RGB from Blender materials)
------------------------------------------------------------
local C = {
    whiteWall    = Color3.fromRGB(235, 230, 219),
    creamWall    = Color3.fromRGB(230, 217, 191),
    beigeWall    = Color3.fromRGB(217, 199, 166),
    darkWall     = Color3.fromRGB(64, 64, 71),
    concrete     = Color3.fromRGB(153, 148, 140),
    asphalt      = Color3.fromRGB(46, 46, 51),
    glass        = Color3.fromRGB(128, 179, 217),
    darkGlass    = Color3.fromRGB(38, 64, 89),
    woodLight    = Color3.fromRGB(166, 115, 64),
    woodDark     = Color3.fromRGB(89, 56, 31),
    metalGrey    = Color3.fromRGB(128, 128, 133),
    metalDark    = Color3.fromRGB(38, 38, 43),
    red          = Color3.fromRGB(204, 26, 26),
    brightRed    = Color3.fromRGB(230, 38, 26),
    blue         = Color3.fromRGB(26, 77, 179),
    green        = Color3.fromRGB(38, 140, 51),
    darkGreen    = Color3.fromRGB(26, 89, 31),
    gold         = Color3.fromRGB(217, 179, 51),
    yellow       = Color3.fromRGB(242, 217, 26),
    brown        = Color3.fromRGB(102, 64, 31),
    marble       = Color3.fromRGB(235, 230, 224),
    roofTile     = Color3.fromRGB(153, 77, 38),
    roofFlat     = Color3.fromRGB(102, 97, 92),
    sand         = Color3.fromRGB(217, 199, 153),
    grassGreen   = Color3.fromRGB(64, 128, 38),
    water        = Color3.fromRGB(38, 102, 166),
    fabricRed    = Color3.fromRGB(140, 31, 26),
    fabricBlue   = Color3.fromRGB(38, 51, 128),
    white        = Color3.fromRGB(242, 242, 242),
    black        = Color3.fromRGB(13, 13, 13),
    neonGreen    = Color3.fromRGB(26, 230, 77),
    neonRed      = Color3.fromRGB(230, 26, 26),
    neonYellow   = Color3.fromRGB(242, 217, 26),
    tire         = Color3.fromRGB(20, 20, 20),
    sidewalk     = Color3.fromRGB(179, 173, 166),
    cyan         = Color3.fromRGB(0, 179, 217),
    pastelOrange = Color3.fromRGB(230, 170, 100),
    lightBlue    = Color3.fromRGB(150, 200, 240),
}

------------------------------------------------------------
-- BUILDING: Hospital (Blender 3D design)
------------------------------------------------------------
local function buildHospital(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "Hospital")
    model:SetAttribute("BuildingType", "hospital")

    local bp = basePos

    -- Main body (white walls, 2 stories)
    local mainBody = makePart(model, "MainBody", Vector3.new(30, 20, 24), bp + Vector3.new(0, 10, 0), C.whiteWall, Enum.Material.Concrete)
    model.PrimaryPart = mainBody

    -- Upper section (slightly narrower)
    makePart(model, "UpperSection", Vector3.new(24, 4, 20), bp + Vector3.new(0, 22, 0), C.whiteWall, Enum.Material.Concrete)

    -- Roof
    makePart(model, "Roof", Vector3.new(32, 1, 26), bp + Vector3.new(0, 25, 0), C.roofFlat, Enum.Material.Concrete)

    -- Red cross (vertical + horizontal)
    makePart(model, "CrossV", Vector3.new(3, 6, 0.5), bp + Vector3.new(0, 22, 12.3), C.brightRed, Enum.Material.Neon)
    makePart(model, "CrossH", Vector3.new(6, 3, 0.5), bp + Vector3.new(0, 22, 12.3), C.brightRed, Enum.Material.Neon)

    -- Windows (front, 2 rows x 4 columns)
    for row = 0, 1 do
        for col = 0, 3 do
            local x = -10.5 + col * 7
            local y = 6 + row * 8
            makePart(model, "WinF_" .. row .. "_" .. col, Vector3.new(2.4, 3.6, 0.3), bp + Vector3.new(x, y, 12.2), C.glass, Enum.Material.Glass, 0.3)
        end
    end

    -- Windows (left side)
    for row = 0, 1 do
        for col = 0, 2 do
            local z = -7 + col * 7
            local y = 6 + row * 8
            makePart(model, "WinL_" .. row .. "_" .. col, Vector3.new(0.3, 3.6, 2.4), bp + Vector3.new(-15.2, y, z), C.glass, Enum.Material.Glass, 0.3)
            makePart(model, "WinR_" .. row .. "_" .. col, Vector3.new(0.3, 3.6, 2.4), bp + Vector3.new(15.2, y, z), C.glass, Enum.Material.Glass, 0.3)
        end
    end

    -- Main door (dark glass double door)
    local door = makePart(model, "Door", Vector3.new(6, 8, 0.3), bp + Vector3.new(0, 4, 12.2), C.darkGlass, Enum.Material.Glass, 0.2)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل المستشفى", "المستشفى", 12)

    -- Door frame (metal)
    makePart(model, "DoorFrame", Vector3.new(6.8, 8.8, 0.2), bp + Vector3.new(0, 4, 12.3), C.metalGrey, Enum.Material.Metal)

    -- Entrance canopy
    makePart(model, "Canopy", Vector3.new(10, 0.4, 6), bp + Vector3.new(0, 9, 15), C.metalGrey, Enum.Material.Metal)
    makeCylinder(model, "CanopyPole1", Vector3.new(9, 0.3, 0.3), bp + Vector3.new(-4, 4.5, 17), C.metalGrey, Enum.Material.Metal, Vector3.new(0, 0, 90))
    makeCylinder(model, "CanopyPole2", Vector3.new(9, 0.3, 0.3), bp + Vector3.new(4, 4.5, 17), C.metalGrey, Enum.Material.Metal, Vector3.new(0, 0, 90))

    -- Floor tile
    makePart(model, "Floor", Vector3.new(36, 0.4, 28), bp + Vector3.new(0, -0.2, 0), C.concrete, Enum.Material.Concrete)

    -- Interior: Reception desk
    makePart(model, "Reception", Vector3.new(8, 3, 2), bp + Vector3.new(0, 1.5, 8), C.whiteWall, Enum.Material.SmoothPlastic)
    makePart(model, "ReceptionTop", Vector3.new(8.2, 0.2, 2.2), bp + Vector3.new(0, 3.1, 8), C.marble, Enum.Material.Marble)

    -- Interior: Hospital beds
    for i = 0, 2 do
        local bx = -8 + i * 8
        makePart(model, "BedFrame_" .. i, Vector3.new(4, 0.4, 6), bp + Vector3.new(bx, 2, -4), C.metalGrey, Enum.Material.Metal)
        makePart(model, "Mattress_" .. i, Vector3.new(3.8, 0.5, 5.5), bp + Vector3.new(bx, 2.45, -4), C.white, Enum.Material.Fabric)
        makePart(model, "Pillow_" .. i, Vector3.new(2.4, 0.4, 1), bp + Vector3.new(bx, 2.9, -6.5), C.white, Enum.Material.Fabric)
    end

    -- Interior: Medical cabinet
    makePart(model, "Cabinet", Vector3.new(2, 5, 1), bp + Vector3.new(-12, 2.5, -10), C.whiteWall, Enum.Material.SmoothPlastic)

    -- Ambulance parking spot
    makePart(model, "AmbuSpot", Vector3.new(6, 0.1, 8), bp + Vector3.new(14, 0.05, 16), C.asphalt, Enum.Material.Concrete)

    addLabel(door, "المستشفى", Vector3.new(0, 10, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Bank (Blender 3D - classical pillars)
------------------------------------------------------------
local function buildBank(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "Bank")
    model:SetAttribute("BuildingType", "bank")
    local bp = basePos

    -- Main body
    local body = makePart(model, "MainBody", Vector3.new(28, 20, 20), bp + Vector3.new(0, 10, 0), C.creamWall, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Classical pillars (front)
    for i = 0, 3 do
        local x = -9 + i * 6
        makeCylinder(model, "Pillar_" .. i, Vector3.new(20, 0.8, 0.8), bp + Vector3.new(x, 10, 10.4), C.marble, Enum.Material.Marble, Vector3.new(0, 0, 90))
        makePart(model, "PillarCap_" .. i, Vector3.new(2.4, 0.6, 2.4), bp + Vector3.new(x, 20.4, 10.4), C.marble, Enum.Material.Marble)
        makePart(model, "PillarBase_" .. i, Vector3.new(2.4, 0.6, 2.4), bp + Vector3.new(x, -0.2, 10.4), C.marble, Enum.Material.Marble)
    end

    -- Roof
    makePart(model, "Roof", Vector3.new(30, 0.8, 22), bp + Vector3.new(0, 21, 0), C.roofFlat, Enum.Material.Concrete)

    -- Pediment (triangular) - approximated with wedge parts
    makeWedge(model, "PedimentL", Vector3.new(0.6, 5, 14), CFrame.new(bp + Vector3.new(-7, 23, 10.4)) * CFrame.Angles(0, 0, 0), C.creamWall, Enum.Material.Concrete)
    makeWedge(model, "PedimentR", Vector3.new(0.6, 5, 14), CFrame.new(bp + Vector3.new(7, 23, 10.4)) * CFrame.Angles(0, math.rad(180), 0), C.creamWall, Enum.Material.Concrete)

    -- Windows
    for col = 0, 2 do
        local x = -6 + col * 6
        makePart(model, "BankWin_" .. col, Vector3.new(2.4, 5, 0.3), bp + Vector3.new(x, 11, 10.2), C.darkGlass, Enum.Material.Glass, 0.2)
    end

    -- Vault door
    local door = makePart(model, "VaultDoor", Vector3.new(5, 8.8, 0.3), bp + Vector3.new(0, 4.4, 10.2), C.metalDark, Enum.Material.DiamondPlate)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل البنك", "البنك", 12)

    -- Vault symbol (gold circle)
    makeCylinder(model, "VaultCircle", Vector3.new(0.2, 1.6, 1.6), bp + Vector3.new(0, 6, 10.4), C.gold, Enum.Material.Metal, Vector3.new(0, 90, 0))

    -- Steps (marble)
    for step = 0, 2 do
        makePart(model, "Step_" .. step, Vector3.new(20, 0.5, 1.2), bp + Vector3.new(0, -0.2 + step * 0.5, 11.6 + step * 1.2), C.marble, Enum.Material.Marble)
    end

    -- Floor
    makePart(model, "Floor", Vector3.new(32, 0.4, 24), bp + Vector3.new(0, -0.5, 0), C.marble, Enum.Material.Marble)

    -- Interior: Teller desks
    for i = 0, 1 do
        local dx = -5 + i * 10
        makePart(model, "TellerDesk_" .. i, Vector3.new(4, 3, 2), bp + Vector3.new(dx, 1.5, 0), C.woodDark, Enum.Material.Wood)
        makePart(model, "TellerTop_" .. i, Vector3.new(4.2, 0.2, 2.2), bp + Vector3.new(dx, 3.1, 0), C.marble, Enum.Material.Marble)
    end

    -- Interior: Vault
    makePart(model, "VaultWall", Vector3.new(10, 10, 1), bp + Vector3.new(0, 5, -8), C.metalGrey, Enum.Material.DiamondPlate)
    for i = 0, 3 do
        makePart(model, "SafeBox_" .. i, Vector3.new(2, 2, 2), bp + Vector3.new(-4 + i * 3, 2, -9), C.metalGrey, Enum.Material.Metal)
    end

    addLabel(door, "البنك", Vector3.new(0, 10, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Mosque (Blender 3D - dome + minarets)
------------------------------------------------------------
local function buildMosque(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "Mosque")
    model:SetAttribute("BuildingType", "mosque")
    local bp = basePos

    -- Main body
    local body = makePart(model, "MainBody", Vector3.new(32, 20, 28), bp + Vector3.new(0, 10, 0), C.beigeWall, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Dome (sphere on top)
    makeBall(model, "Dome", Vector3.new(16, 16, 16), bp + Vector3.new(0, 23, 0), C.beigeWall, Enum.Material.Concrete)

    -- Crescent on dome pole
    makeCylinder(model, "CrescentPole", Vector3.new(4, 0.16, 0.16), bp + Vector3.new(0, 29, 0), C.gold, Enum.Material.Metal, Vector3.new(0, 0, 90))

    -- Minarets (left and right)
    for _, side in ipairs({-1, 1}) do
        local mx = side * 18
        makeCylinder(model, "Minaret_" .. side, Vector3.new(28, 1.6, 1.6), bp + Vector3.new(mx, 14, 0), C.beigeWall, Enum.Material.Concrete, Vector3.new(0, 0, 90))
        -- Minaret top (cone-like using ball)
        makeBall(model, "MinaretTop_" .. side, Vector3.new(3, 5, 3), bp + Vector3.new(mx, 29, 0), C.beigeWall, Enum.Material.Concrete)
        -- Minaret railing
        makeCylinder(model, "MinaretRail_" .. side, Vector3.new(0.6, 2.2, 2.2), bp + Vector3.new(mx, 20, 0), C.creamWall, Enum.Material.Concrete, Vector3.new(0, 0, 90))
        -- Gold finial
        makeCylinder(model, "MinaretFinial_" .. side, Vector3.new(2, 0.12, 0.12), bp + Vector3.new(mx, 31, 0), C.gold, Enum.Material.Metal, Vector3.new(0, 0, 90))
    end

    -- Arched windows (front)
    for col = 0, 4 do
        local x = -12 + col * 6
        makePart(model, "MosqueWin_" .. col, Vector3.new(2, 6, 0.3), bp + Vector3.new(x, 8, 14.2), C.glass, Enum.Material.Glass, 0.3)
        -- Arch top (ball)
        makeBall(model, "MosqueArch_" .. col, Vector3.new(2, 2, 0.4), bp + Vector3.new(x, 11.5, 14.2), C.glass, Enum.Material.Glass)
    end

    -- Main door (arched wooden)
    local door = makePart(model, "MosqueDoor", Vector3.new(5, 10, 0.3), bp + Vector3.new(0, 5, 14.2), C.woodDark, Enum.Material.Wood)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل المسجد", "المسجد", 14)

    -- Roof edge ornament
    makePart(model, "RoofEdge", Vector3.new(33, 0.6, 29), bp + Vector3.new(0, 20.4, 0), C.creamWall, Enum.Material.Concrete)

    -- Marble floor
    makePart(model, "Floor", Vector3.new(36, 0.4, 32), bp + Vector3.new(0, -0.2, 0), C.marble, Enum.Material.Marble)

    -- Courtyard fountain
    makeCylinder(model, "Fountain", Vector3.new(2, 4, 4), bp + Vector3.new(0, 1, 20), C.marble, Enum.Material.Marble, Vector3.new(0, 0, 90))
    makeCylinder(model, "FountainWater", Vector3.new(1.2, 3, 3), bp + Vector3.new(0, 1.6, 20), C.water, Enum.Material.Glass, Vector3.new(0, 0, 90))

    -- Interior: Prayer carpet pattern (strip along floor)
    makePart(model, "PrayerCarpet", Vector3.new(28, 0.1, 24), bp + Vector3.new(0, 0.1, 0), C.darkGreen, Enum.Material.Fabric)

    addLabel(door, "المسجد", Vector3.new(0, 12, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Mall (Blender 3D - modern glass facade)
------------------------------------------------------------
local function buildMall(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "Mall")
    model:SetAttribute("BuildingType", "mall")
    local bp = basePos

    -- Main body (large)
    local body = makePart(model, "MainBody", Vector3.new(50, 24, 32), bp + Vector3.new(0, 12, 0), C.whiteWall, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Glass curtain wall (front)
    for col = 0, 7 do
        local x = -21 + col * 6
        makePart(model, "GlassFacade_" .. col, Vector3.new(5, 16, 0.3), bp + Vector3.new(x, 10, 16.2), C.glass, Enum.Material.Glass, 0.3)
    end

    -- Upper glass strip
    makePart(model, "GlassStrip", Vector3.new(48, 3, 0.3), bp + Vector3.new(0, 21, 16.2), C.darkGlass, Enum.Material.Glass, 0.2)

    -- Sign bar
    makePart(model, "SignBar", Vector3.new(40, 3, 0.6), bp + Vector3.new(0, 24.4, 16.6), C.darkWall, Enum.Material.SmoothPlastic)

    -- Entrance (double glass doors)
    local door1 = makePart(model, "Door1", Vector3.new(3.6, 8, 0.3), bp + Vector3.new(-4, 4, 16.3), C.darkGlass, Enum.Material.Glass, 0.15)
    door1.CanCollide = false
    local door2 = makePart(model, "Door2", Vector3.new(3.6, 8, 0.3), bp + Vector3.new(4, 4, 16.3), C.darkGlass, Enum.Material.Glass, 0.15)
    door2.CanCollide = false
    addProximityPrompt(door1, "ادخل المول", "المول", 12)

    -- Canopy over entrance
    makePart(model, "Canopy", Vector3.new(16, 0.3, 5), bp + Vector3.new(0, 9, 19), C.metalGrey, Enum.Material.Metal)

    -- Roof
    makePart(model, "Roof", Vector3.new(52, 0.8, 34), bp + Vector3.new(0, 25, 0), C.roofFlat, Enum.Material.Concrete)

    -- Side windows
    for row = 0, 1 do
        for col = 0, 3 do
            local z = -10 + col * 7
            local y = 8 + row * 9
            makePart(model, "SideWinL_" .. row .. "_" .. col, Vector3.new(0.3, 4, 3), bp + Vector3.new(-25.2, y, z), C.glass, Enum.Material.Glass, 0.3)
            makePart(model, "SideWinR_" .. row .. "_" .. col, Vector3.new(0.3, 4, 3), bp + Vector3.new(25.2, y, z), C.glass, Enum.Material.Glass, 0.3)
        end
    end

    -- Floor
    makePart(model, "Floor", Vector3.new(56, 0.4, 36), bp + Vector3.new(0, -0.2, 0), C.marble, Enum.Material.Marble)

    -- Interior: Shop display shelves
    for i = 0, 2 do
        makePart(model, "Shelf_" .. i, Vector3.new(6, 8, 1), bp + Vector3.new(-16 + i * 16, 4, -6), C.woodLight, Enum.Material.Wood)
    end

    -- Interior: Checkout counter
    makePart(model, "Checkout", Vector3.new(12, 3, 2), bp + Vector3.new(0, 1.5, 10), C.whiteWall, Enum.Material.SmoothPlastic)
    makePart(model, "CheckoutTop", Vector3.new(12.2, 0.2, 2.2), bp + Vector3.new(0, 3.1, 10), C.marble, Enum.Material.Marble)

    -- Parking lines
    for i = 0, 5 do
        local x = -16 + i * 6.4
        makePart(model, "ParkLine_" .. i, Vector3.new(0.2, 0.1, 8), bp + Vector3.new(x, 0.05, 24), C.yellow, Enum.Material.SmoothPlastic)
    end

    addLabel(door1, "المول", Vector3.new(0, 14, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Police Station (Blender 3D)
------------------------------------------------------------
local function buildPoliceStation(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "PoliceStation")
    model:SetAttribute("BuildingType", "police")
    local bp = basePos

    -- Main body
    local body = makePart(model, "MainBody", Vector3.new(28, 18, 22), bp + Vector3.new(0, 9, 0), C.concrete, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Blue stripe
    makePart(model, "BlueStripe", Vector3.new(28.2, 2, 0.3), bp + Vector3.new(0, 16, 11.2), C.blue, Enum.Material.Neon)

    -- Windows
    for col = 0, 3 do
        local x = -10 + col * 6.6
        makePart(model, "PoliceWin_" .. col, Vector3.new(3, 4, 0.3), bp + Vector3.new(x, 10, 11.2), C.glass, Enum.Material.Glass, 0.3)
    end

    -- Door
    local door = makePart(model, "Door", Vector3.new(5, 8.8, 0.3), bp + Vector3.new(0, 4.4, 11.2), C.metalGrey, Enum.Material.Metal)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل مركز الشرطة", "مركز الشرطة", 12)

    -- Roof
    makePart(model, "Roof", Vector3.new(30, 0.8, 24), bp + Vector3.new(0, 18.4, 0), C.roofFlat, Enum.Material.Concrete)

    -- Antenna
    makeCylinder(model, "Antenna", Vector3.new(10, 0.16, 0.16), bp + Vector3.new(10, 23, -6), C.metalGrey, Enum.Material.Metal, Vector3.new(0, 0, 90))

    -- Flag pole
    makeCylinder(model, "FlagPole", Vector3.new(20, 0.16, 0.16), bp + Vector3.new(-12, 10, 13), C.metalGrey, Enum.Material.Metal, Vector3.new(0, 0, 90))

    -- Floor
    makePart(model, "Floor", Vector3.new(32, 0.4, 26), bp + Vector3.new(0, -0.2, 0), C.concrete, Enum.Material.Concrete)

    -- Interior: desks
    for i = 0, 1 do
        local dx = -5 + i * 10
        makePart(model, "Desk_" .. i, Vector3.new(4, 2.5, 2), bp + Vector3.new(dx, 1.25, -3), C.woodDark, Enum.Material.Wood)
    end

    -- Interior: jail cell
    makePart(model, "CellWall", Vector3.new(0.5, 10, 8), bp + Vector3.new(10, 5, -6), C.metalGrey, Enum.Material.DiamondPlate)
    makePart(model, "CellBars", Vector3.new(8, 10, 0.5), bp + Vector3.new(6, 5, -2), C.metalGrey, Enum.Material.DiamondPlate)

    addLabel(door, "مركز الشرطة", Vector3.new(0, 10, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Fire Station (Blender 3D)
------------------------------------------------------------
local function buildFireStation(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "FireStation")
    model:SetAttribute("BuildingType", "fire")
    local bp = basePos

    -- Main body
    local body = makePart(model, "MainBody", Vector3.new(28, 18, 24), bp + Vector3.new(0, 9, 0), C.creamWall, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Red stripe
    makePart(model, "RedStripe", Vector3.new(28.2, 3, 0.3), bp + Vector3.new(0, 16, 12.2), C.brightRed, Enum.Material.Neon)

    -- Garage door (large)
    local garageDoor = makePart(model, "GarageDoor", Vector3.new(10, 12, 0.3), bp + Vector3.new(-6, 6, 12.2), C.metalGrey, Enum.Material.Metal)
    garageDoor.CanCollide = false

    -- Regular door
    local door = makePart(model, "Door", Vector3.new(4, 8, 0.3), bp + Vector3.new(8, 4, 12.2), C.metalDark, Enum.Material.Metal)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل محطة الإطفاء", "محطة الإطفاء", 12)

    -- Windows
    for col = 0, 1 do
        local x = 5 + col * 6
        makePart(model, "FireWin_" .. col, Vector3.new(2.4, 3, 0.3), bp + Vector3.new(x, 13, 12.2), C.glass, Enum.Material.Glass, 0.3)
    end

    -- Roof
    makePart(model, "Roof", Vector3.new(30, 0.8, 26), bp + Vector3.new(0, 18.4, 0), C.roofFlat, Enum.Material.Concrete)

    -- Drill tower
    makePart(model, "Tower", Vector3.new(6, 14, 6), bp + Vector3.new(12, 16, -8), C.concrete, Enum.Material.Concrete)
    makePart(model, "TowerRoof", Vector3.new(7, 0.6, 7), bp + Vector3.new(12, 23.6, -8), C.roofFlat, Enum.Material.Concrete)

    -- Floor
    makePart(model, "Floor", Vector3.new(32, 0.4, 28), bp + Vector3.new(0, -0.2, 0), C.concrete, Enum.Material.Concrete)

    -- Interior: Lockers
    for i = 0, 3 do
        makePart(model, "Locker_" .. i, Vector3.new(1.5, 5, 1), bp + Vector3.new(-10 + i * 3, 2.5, -10), C.metalGrey, Enum.Material.Metal)
    end

    addLabel(door, "محطة الإطفاء", Vector3.new(0, 10, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Restaurant (Blender 3D - player starting job)
------------------------------------------------------------
local function buildRestaurant(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "Restaurant")
    model:SetAttribute("BuildingType", "restaurant")
    local bp = basePos

    -- Main body
    local body = makePart(model, "MainBody", Vector3.new(20, 14, 16), bp + Vector3.new(0, 7, 0), C.creamWall, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Roof (terracotta tile look)
    makePart(model, "Roof", Vector3.new(22, 0.8, 18), bp + Vector3.new(0, 14.4, 0), C.roofTile, Enum.Material.Brick)

    -- Red awning
    makePart(model, "Awning", Vector3.new(16, 0.2, 4), bp + Vector3.new(0, 10, 9), C.brightRed, Enum.Material.Fabric)
    makePart(model, "AwningFront", Vector3.new(16, 2, 0.2), bp + Vector3.new(0, 9, 10.9), C.brightRed, Enum.Material.Fabric)

    -- Large front windows
    for col = 0, 1 do
        local x = -5 + col * 10
        makePart(model, "RestWin_" .. col, Vector3.new(4, 5, 0.3), bp + Vector3.new(x, 7, 8.2), C.glass, Enum.Material.Glass, 0.25)
    end

    -- Door (wooden)
    local door = makePart(model, "Door", Vector3.new(4, 8, 0.3), bp + Vector3.new(0, 4, 8.2), C.woodDark, Enum.Material.Wood)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل المطعم", "المطعم (وظيفتك المبدئية)", 12)

    -- Outdoor dining tables
    for i = 0, 1 do
        local ox = -6 + i * 12
        makePart(model, "OutTable_" .. i, Vector3.new(4, 0.2, 4), bp + Vector3.new(ox, 3, 13), C.woodLight, Enum.Material.Wood)
        makeCylinder(model, "OutTableLeg_" .. i, Vector3.new(3, 0.3, 0.3), bp + Vector3.new(ox, 1.5, 13), C.metalGrey, Enum.Material.Metal, Vector3.new(0, 0, 90))
        -- Chairs at each table
        for j = 0, 1 do
            local cx = ox + (-2.6 + j * 5.2)
            makePart(model, "OutChair_" .. i .. "_" .. j, Vector3.new(1.6, 0.2, 1.6), bp + Vector3.new(cx, 2.4, 13), C.metalGrey, Enum.Material.Metal)
        end
    end

    -- Floor
    makePart(model, "Floor", Vector3.new(24, 0.4, 20), bp + Vector3.new(0, -0.2, 0), C.concrete, Enum.Material.Concrete)

    -- Interior: Kitchen counter
    makePart(model, "KitchenCounter", Vector3.new(12, 3, 2), bp + Vector3.new(0, 1.5, -6), C.whiteWall, Enum.Material.SmoothPlastic)
    makePart(model, "KitchenTop", Vector3.new(12.2, 0.2, 2.2), bp + Vector3.new(0, 3.1, -6), C.marble, Enum.Material.Marble)

    -- Interior: Stove
    makePart(model, "Stove", Vector3.new(3, 3, 1.5), bp + Vector3.new(6, 1.5, -6.5), C.metalDark, Enum.Material.Metal)

    -- Interior: Dining tables
    for i = 0, 1 do
        for j = 0, 1 do
            local tx = -4 + i * 8
            local tz = -1 + j * 5
            makePart(model, "DinTable_" .. i .. "_" .. j, Vector3.new(3, 0.2, 2), bp + Vector3.new(tx, 3, tz), C.woodDark, Enum.Material.Wood)
            makeCylinder(model, "DinTableLeg_" .. i .. "_" .. j, Vector3.new(3, 0.15, 0.15), bp + Vector3.new(tx, 1.5, tz), C.metalGrey, Enum.Material.Metal, Vector3.new(0, 0, 90))
        end
    end

    -- Work prompt
    local workZone = makePart(model, "WorkZone", Vector3.new(8, 0.2, 4), bp + Vector3.new(0, 0.1, -6), C.yellow, Enum.Material.Neon, 0.8)
    workZone.CanCollide = false
    addProximityPrompt(workZone, "اشتغل بالمطعم", "منطقة العمل", 8)

    addLabel(door, "المطعم", Vector3.new(0, 8, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Villa / House (Blender 3D)
------------------------------------------------------------
local function buildVilla(parent: Instance, basePos: Vector3, index: number): Model
    local name = "Villa_" .. index
    local model = makeModel(parent, name)
    model:SetAttribute("BuildingType", "villa")
    local bp = basePos

    -- Choose alternating wall colors
    local wallC = if index % 2 == 0 then C.beigeWall else C.creamWall

    -- Main body (ground floor)
    local body = makePart(model, "MainBody", Vector3.new(24, 12, 20), bp + Vector3.new(0, 6, 0), wallC, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Second floor section (offset)
    makePart(model, "UpperBody", Vector3.new(16, 6, 16), bp + Vector3.new(-2, 15, 0), C.creamWall, Enum.Material.Concrete)

    -- Ground floor roof
    makePart(model, "RoofMain", Vector3.new(26, 0.6, 22), bp + Vector3.new(0, 12.6, 0), C.roofTile, Enum.Material.Brick)

    -- Upper roof
    makePart(model, "RoofUpper", Vector3.new(18, 0.6, 18), bp + Vector3.new(-2, 18.4, 0), C.roofTile, Enum.Material.Brick)

    -- Ground floor windows
    for col = 0, 2 do
        local x = -8 + col * 8
        makePart(model, "WinG_" .. col, Vector3.new(3, 4, 0.3), bp + Vector3.new(x, 6, 10.2), C.glass, Enum.Material.Glass, 0.3)
    end

    -- Upper floor windows
    for col = 0, 1 do
        local x = -6 + col * 8
        makePart(model, "WinU_" .. col, Vector3.new(2.4, 3, 0.3), bp + Vector3.new(x, 15, 8.2), C.glass, Enum.Material.Glass, 0.3)
    end

    -- Front door
    local door = makePart(model, "Door", Vector3.new(4, 6, 0.3), bp + Vector3.new(0, 3, 10.2), C.woodDark, Enum.Material.Wood)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل البيت", "بيت " .. index, 10)

    -- Garage
    makePart(model, "GarageBody", Vector3.new(8, 10, 12), bp + Vector3.new(14, 5, 0), C.creamWall, Enum.Material.Concrete)
    local garageDoor = makePart(model, "GarageDoor", Vector3.new(6, 7.2, 0.3), bp + Vector3.new(14, 3.6, 6.2), C.metalGrey, Enum.Material.Metal)
    garageDoor.CanCollide = false
    makePart(model, "GarageRoof", Vector3.new(10, 0.6, 14), bp + Vector3.new(14, 10.4, 0), C.roofTile, Enum.Material.Brick)

    -- Garden wall / fence
    makePart(model, "GardenWall", Vector3.new(32, 2, 0.6), bp + Vector3.new(0, 1, 14), C.beigeWall, Enum.Material.Concrete)

    -- Floor / ground
    makePart(model, "Ground", Vector3.new(36, 0.4, 28), bp + Vector3.new(0, -0.2, 0), C.sand, Enum.Material.Sand)
    makePart(model, "GardenGrass", Vector3.new(28, 0.2, 4), bp + Vector3.new(0, -0.05, 12), C.grassGreen, Enum.Material.Grass)

    -- Interior: Bedroom
    makePart(model, "BedFrame", Vector3.new(4, 0.4, 6), bp + Vector3.new(-6, 2, -5), C.woodLight, Enum.Material.Wood)
    makePart(model, "Mattress", Vector3.new(3.8, 0.5, 5.5), bp + Vector3.new(-6, 2.45, -5), C.white, Enum.Material.Fabric)
    makePart(model, "Headboard", Vector3.new(4, 3, 0.3), bp + Vector3.new(-6, 3.5, -7.85), C.woodDark, Enum.Material.Wood)

    -- Interior: Living room
    makePart(model, "Sofa", Vector3.new(6, 2, 2.5), bp + Vector3.new(5, 1.5, -3), C.fabricRed, Enum.Material.Fabric)
    makePart(model, "SofaBack", Vector3.new(6, 3, 0.5), bp + Vector3.new(5, 3, -4.25), C.fabricRed, Enum.Material.Fabric)
    makePart(model, "TVStand", Vector3.new(3, 1.5, 1), bp + Vector3.new(5, 0.75, -8), C.woodDark, Enum.Material.Wood)
    makePart(model, "TVScreen", Vector3.new(4, 2.5, 0.2), bp + Vector3.new(5, 3.25, -8), C.black, Enum.Material.Glass)

    -- Interior: Kitchen
    makePart(model, "KCounter", Vector3.new(6, 3, 1.5), bp + Vector3.new(-5, 1.5, 5), C.whiteWall, Enum.Material.SmoothPlastic)
    makePart(model, "KTop", Vector3.new(6.2, 0.2, 1.7), bp + Vector3.new(-5, 3.1, 5), C.marble, Enum.Material.Marble)

    addLabel(door, "بيت " .. index, Vector3.new(0, 6, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Airport (Blender 3D - large terminal)
------------------------------------------------------------
local function buildAirport(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "Airport")
    model:SetAttribute("BuildingType", "airport")
    local bp = basePos

    -- Main terminal building
    local body = makePart(model, "Terminal", Vector3.new(60, 16, 28), bp + Vector3.new(0, 8, 0), C.whiteWall, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Glass curtain wall (front)
    for col = 0, 9 do
        local x = -27 + col * 6
        makePart(model, "TermGlass_" .. col, Vector3.new(5, 12, 0.3), bp + Vector3.new(x, 9, 14.2), C.glass, Enum.Material.Glass, 0.3)
    end

    -- Control tower
    makeCylinder(model, "ControlTower", Vector3.new(24, 4, 4), bp + Vector3.new(24, 20, -10), C.whiteWall, Enum.Material.Concrete, Vector3.new(0, 0, 90))
    makeCylinder(model, "ControlCab", Vector3.new(5, 5.6, 5.6), bp + Vector3.new(24, 33, -10), C.darkGlass, Enum.Material.Glass, Vector3.new(0, 0, 90))
    makePart(model, "ControlRoof", Vector3.new(12, 0.6, 12), bp + Vector3.new(24, 36, -10), C.roofFlat, Enum.Material.Concrete)

    -- Roof
    makePart(model, "Roof", Vector3.new(62, 1, 30), bp + Vector3.new(0, 16.6, 0), C.roofFlat, Enum.Material.Concrete)

    -- Entrance
    local door = makePart(model, "Door", Vector3.new(8, 8, 0.3), bp + Vector3.new(0, 4, 14.3), C.darkGlass, Enum.Material.Glass, 0.15)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل المطار", "المطار", 14)

    -- Canopy
    makePart(model, "Canopy", Vector3.new(24, 0.4, 7), bp + Vector3.new(0, 10, 18), C.metalGrey, Enum.Material.Metal)

    -- Runway
    makePart(model, "Runway", Vector3.new(12, 0.1, 60), bp + Vector3.new(0, 0.02, -40), C.asphalt, Enum.Material.Asphalt)
    for i = 0, 7 do
        local z = -24 + i * 7.5
        makePart(model, "RunwayLine_" .. i, Vector3.new(1.6, 0.06, 4.5), bp + Vector3.new(0, 0.08, z - 40), C.white, Enum.Material.SmoothPlastic)
    end

    -- Floor
    makePart(model, "Floor", Vector3.new(68, 0.4, 32), bp + Vector3.new(0, -0.2, 0), C.concrete, Enum.Material.Concrete)

    -- Interior: Check-in counters
    for i = 0, 2 do
        makePart(model, "CheckIn_" .. i, Vector3.new(4, 3, 2), bp + Vector3.new(-10 + i * 10, 1.5, 5), C.whiteWall, Enum.Material.SmoothPlastic)
    end

    -- Interior: Seating
    for i = 0, 4 do
        makePart(model, "Seat_" .. i, Vector3.new(2, 1.5, 2), bp + Vector3.new(-8 + i * 4, 0.75, -5), C.metalGrey, Enum.Material.Metal)
    end

    addLabel(door, "المطار", Vector3.new(0, 10, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Car Dealership (Blender 3D - glass showroom)
------------------------------------------------------------
local function buildDealership(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "CarDealership")
    model:SetAttribute("BuildingType", "dealership")
    local bp = basePos

    -- Showroom body
    local body = makePart(model, "Showroom", Vector3.new(36, 16, 24), bp + Vector3.new(0, 8, 0), C.whiteWall, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Glass front
    for col = 0, 5 do
        local x = -15 + col * 6
        makePart(model, "ShowGlass_" .. col, Vector3.new(5, 13, 0.3), bp + Vector3.new(x, 8, 12.2), C.glass, Enum.Material.Glass, 0.3)
    end

    -- Roof
    makePart(model, "Roof", Vector3.new(38, 0.8, 26), bp + Vector3.new(0, 16.6, 0), C.roofFlat, Enum.Material.Concrete)

    -- Display platforms
    local carColors = {C.brightRed, C.blue, C.white, C.black, C.gold}
    for i = 0, 2 do
        local x = -10 + i * 10
        makePart(model, "Platform_" .. i, Vector3.new(8, 0.8, 12), bp + Vector3.new(x, 0.4, 0), C.marble, Enum.Material.Marble)
        -- Display car body
        local cc = carColors[(i % #carColors) + 1]
        makePart(model, "CarBody_" .. i, Vector3.new(4, 1.6, 8), bp + Vector3.new(x, 1.6, 0), cc, Enum.Material.SmoothPlastic)
        makePart(model, "CarCabin_" .. i, Vector3.new(3.5, 1.4, 4.5), bp + Vector3.new(x, 3, -0.4), cc, Enum.Material.SmoothPlastic)
        makePart(model, "CarWindshield_" .. i, Vector3.new(3.2, 1.2, 0.2), bp + Vector3.new(x, 3, 1.7), C.darkGlass, Enum.Material.Glass, 0.2)
    end

    -- Door
    local door = makePart(model, "Door", Vector3.new(6, 8, 0.3), bp + Vector3.new(0, 4, 12.3), C.darkGlass, Enum.Material.Glass, 0.15)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل معرض السيارات", "معرض السيارات", 12)

    -- Sign
    makePart(model, "Sign", Vector3.new(20, 3, 0.4), bp + Vector3.new(0, 17, 12.6), C.darkWall, Enum.Material.SmoothPlastic)

    -- Floor
    makePart(model, "Floor", Vector3.new(40, 0.4, 28), bp + Vector3.new(0, -0.2, 0), C.marble, Enum.Material.Marble)

    addLabel(door, "معرض السيارات", Vector3.new(0, 10, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Gas Station (Blender 3D)
------------------------------------------------------------
local function buildGasStation(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "GasStation")
    model:SetAttribute("BuildingType", "gas_station")
    local bp = basePos

    -- Shop building
    makePart(model, "Shop", Vector3.new(12, 10, 12), bp + Vector3.new(-10, 5, 0), C.whiteWall, Enum.Material.Concrete)
    makePart(model, "ShopRoof", Vector3.new(14, 0.6, 14), bp + Vector3.new(-10, 10.4, 0), C.roofFlat, Enum.Material.Concrete)
    makePart(model, "ShopWin", Vector3.new(6, 5, 0.3), bp + Vector3.new(-10, 6, 6.2), C.glass, Enum.Material.Glass, 0.3)
    local door = makePart(model, "ShopDoor", Vector3.new(3, 6, 0.3), bp + Vector3.new(-6, 3, 6.2), C.darkGlass, Enum.Material.Glass, 0.15)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل محطة الوقود", "محطة الوقود", 10)

    local body = makePart(model, "CanopyStructure", Vector3.new(1, 1, 1), bp + Vector3.new(0, 0.5, 0), C.whiteWall, Enum.Material.SmoothPlastic, 1)
    model.PrimaryPart = body

    -- Canopy
    makePart(model, "Canopy", Vector3.new(24, 0.6, 16), bp + Vector3.new(6, 10, 0), C.white, Enum.Material.Metal)

    -- Canopy poles
    local polePositions = {{-4, 7}, {16, 7}, {-4, -7}, {16, -7}}
    for i, pp in ipairs(polePositions) do
        makeCylinder(model, "Pole_" .. i, Vector3.new(10, 0.4, 0.4), bp + Vector3.new(pp[1], 5, pp[2]), C.metalGrey, Enum.Material.Metal, Vector3.new(0, 0, 90))
    end

    -- Fuel pumps
    for i = 0, 2 do
        local px = 2 + i * 7
        makePart(model, "Pump_" .. i, Vector3.new(1.6, 6, 1), bp + Vector3.new(px, 3, 0), C.brightRed, Enum.Material.Metal)
        makePart(model, "PumpScreen_" .. i, Vector3.new(1.2, 1, 0.1), bp + Vector3.new(px, 4.4, 0.6), C.darkGlass, Enum.Material.Glass)
        makePart(model, "PumpBase_" .. i, Vector3.new(2.4, 0.4, 1.6), bp + Vector3.new(px, 0.2, 0), C.concrete, Enum.Material.Concrete)
    end

    -- Floor
    makePart(model, "Floor", Vector3.new(40, 0.4, 20), bp + Vector3.new(0, -0.2, 0), C.concrete, Enum.Material.Concrete)

    addLabel(door, "محطة الوقود", Vector3.new(0, 8, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: Hotel (Blender 3D - tall with balconies)
------------------------------------------------------------
local function buildHotel(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "Hotel")
    model:SetAttribute("BuildingType", "hotel")
    local bp = basePos

    -- Main tower
    local body = makePart(model, "MainBody", Vector3.new(28, 40, 24), bp + Vector3.new(0, 20, 0), C.creamWall, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Windows (front, 5 floors x 4 columns)
    for row = 0, 4 do
        for col = 0, 3 do
            local x = -10 + col * 6.6
            local y = 6 + row * 7.6
            makePart(model, "HotelWin_" .. row .. "_" .. col, Vector3.new(3, 4, 0.3), bp + Vector3.new(x, y, 12.2), C.glass, Enum.Material.Glass, 0.3)
        end
    end

    -- Balconies (front)
    for row = 0, 4 do
        for col = 0, 1 do
            local x = -6 + col * 12
            local y = 4 + row * 7.6
            makePart(model, "Balcony_" .. row .. "_" .. col, Vector3.new(5, 0.3, 2), bp + Vector3.new(x, y, 13), C.concrete, Enum.Material.Concrete)
            makePart(model, "BalconyRail_" .. row .. "_" .. col, Vector3.new(5, 2, 0.16), bp + Vector3.new(x, y + 1, 13.8), C.metalGrey, Enum.Material.Metal)
        end
    end

    -- Entrance portico
    makePart(model, "Portico", Vector3.new(16, 0.6, 4), bp + Vector3.new(0, 6, 14), C.marble, Enum.Material.Marble)
    makeCylinder(model, "PorticoPole1", Vector3.new(6, 0.6, 0.6), bp + Vector3.new(-6, 3, 15), C.marble, Enum.Material.Marble, Vector3.new(0, 0, 90))
    makeCylinder(model, "PorticoPole2", Vector3.new(6, 0.6, 0.6), bp + Vector3.new(6, 3, 15), C.marble, Enum.Material.Marble, Vector3.new(0, 0, 90))

    -- Door
    local door = makePart(model, "Door", Vector3.new(6, 6, 0.3), bp + Vector3.new(0, 3, 12.3), C.darkGlass, Enum.Material.Glass, 0.15)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل الفندق", "الفندق", 12)

    -- Roof
    makePart(model, "Roof", Vector3.new(30, 0.8, 26), bp + Vector3.new(0, 40.6, 0), C.roofFlat, Enum.Material.Concrete)

    -- Penthouse
    makePart(model, "Penthouse", Vector3.new(16, 4, 16), bp + Vector3.new(0, 43, 0), C.darkWall, Enum.Material.Concrete)
    makePart(model, "PenthouseGlass", Vector3.new(14, 3, 0.3), bp + Vector3.new(0, 43, 8.2), C.darkGlass, Enum.Material.Glass, 0.2)

    -- Floor
    makePart(model, "Floor", Vector3.new(32, 0.4, 28), bp + Vector3.new(0, -0.2, 0), C.marble, Enum.Material.Marble)

    addLabel(door, "الفندق", Vector3.new(0, 14, 0))
    return model
end

------------------------------------------------------------
-- BUILDING: School (Blender 3D)
------------------------------------------------------------
local function buildSchool(parent: Instance, basePos: Vector3): Model
    local model = makeModel(parent, "School")
    model:SetAttribute("BuildingType", "school")
    local bp = basePos

    -- Main body
    local body = makePart(model, "MainBody", Vector3.new(32, 16, 24), bp + Vector3.new(0, 8, 0), C.creamWall, Enum.Material.Concrete)
    model.PrimaryPart = body

    -- Windows (2 rows x 5)
    for row = 0, 1 do
        for col = 0, 4 do
            local x = -12 + col * 6
            local y = 6 + row * 7
            makePart(model, "SchWin_" .. row .. "_" .. col, Vector3.new(3, 4, 0.3), bp + Vector3.new(x, y, 12.2), C.glass, Enum.Material.Glass, 0.3)
        end
    end

    -- Door
    local door = makePart(model, "Door", Vector3.new(5, 8, 0.3), bp + Vector3.new(0, 4, 12.3), C.woodDark, Enum.Material.Wood)
    door.CanCollide = false
    addProximityPrompt(door, "ادخل المدرسة", "المدرسة", 12)

    -- School sign (blue)
    makePart(model, "SchoolSign", Vector3.new(16, 2, 0.4), bp + Vector3.new(0, 15, 12.4), C.blue, Enum.Material.SmoothPlastic)

    -- Roof
    makePart(model, "Roof", Vector3.new(34, 0.8, 26), bp + Vector3.new(0, 16.6, 0), C.roofFlat, Enum.Material.Concrete)

    -- Playground
    makePart(model, "Playground", Vector3.new(24, 0.2, 8), bp + Vector3.new(0, -0.05, 18), C.green, Enum.Material.Grass)

    -- Flag pole
    makeCylinder(model, "FlagPole", Vector3.new(20, 0.12, 0.12), bp + Vector3.new(-14, 10, 14), C.metalGrey, Enum.Material.Metal, Vector3.new(0, 0, 90))

    -- Floor
    makePart(model, "Floor", Vector3.new(36, 0.4, 28), bp + Vector3.new(0, -0.2, 0), C.concrete, Enum.Material.Concrete)

    addLabel(door, "المدرسة", Vector3.new(0, 10, 0))
    return model
end

------------------------------------------------------------
-- Street creation (Blender 3D style - detailed road)
------------------------------------------------------------
local function createRoad(parent: Instance, startPos: Vector3, endPos: Vector3, width: number)
    width = width or 14
    local direction = (endPos - startPos)
    local length = direction.Magnitude
    local midPoint = (startPos + endPos) / 2

    local cf = CFrame.lookAt(startPos, endPos)
    local roadCF = CFrame.lookAt(midPoint, endPos) * CFrame.new(0, 0.15, 0)

    -- Road surface (asphalt)
    local road = makePart(parent, "Road", Vector3.new(width, 0.3, length), Vector3.new(0, 0, 0), C.asphalt, Enum.Material.Asphalt)
    road.CFrame = roadCF

    -- Center dashed line
    local lineCount = math.floor(length / 6)
    for i = 0, lineCount - 1 do
        local offset = -length / 2 + i * 6 + 2
        local lp = makePart(parent, "CLine_" .. i, Vector3.new(0.3, 0.06, 3.5), Vector3.new(0, 0, 0), C.yellow, Enum.Material.SmoothPlastic)
        lp.CFrame = roadCF * CFrame.new(0, 0.18, offset)
        lp.CanCollide = false
    end

    -- Edge lines (solid white)
    local edgeL = makePart(parent, "EdgeL", Vector3.new(0.2, 0.04, length), Vector3.new(0, 0, 0), C.white, Enum.Material.SmoothPlastic)
    edgeL.CFrame = roadCF * CFrame.new(-width / 2 + 0.4, 0.18, 0)
    edgeL.CanCollide = false

    local edgeR = makePart(parent, "EdgeR", Vector3.new(0.2, 0.04, length), Vector3.new(0, 0, 0), C.white, Enum.Material.SmoothPlastic)
    edgeR.CFrame = roadCF * CFrame.new(width / 2 - 0.4, 0.18, 0)
    edgeR.CanCollide = false

    -- Sidewalks
    for _, side in ipairs({-1, 1}) do
        local sideOffset = width / 2 + 2
        local sw = makePart(parent, "Sidewalk", Vector3.new(4, 0.5, length), Vector3.new(0, 0, 0), C.sidewalk, Enum.Material.Concrete)
        sw.CFrame = roadCF * CFrame.new(side * sideOffset, 0.1, 0)

        -- Curb
        local curb = makePart(parent, "Curb", Vector3.new(0.3, 0.5, length), Vector3.new(0, 0, 0), C.concrete, Enum.Material.Concrete)
        curb.CFrame = roadCF * CFrame.new(side * (width / 2 + 0.15), 0.08, 0)
    end

    return road
end

local function createIntersection(parent: Instance, position: Vector3, size: number)
    size = size or 20
    -- Main surface
    makePart(parent, "InterSurface", Vector3.new(size, 0.3, size), position + Vector3.new(0, 0.15, 0), C.asphalt, Enum.Material.Asphalt)

    -- Crosswalk stripes (4 directions)
    for i = 0, 3 do
        local x = -size / 4 + i * (size / 6)
        makePart(parent, "CrossN_" .. i, Vector3.new(1.6, 0.04, 2), position + Vector3.new(x, 0.32, size / 2 - 1.5), C.white, Enum.Material.SmoothPlastic)
        makePart(parent, "CrossS_" .. i, Vector3.new(1.6, 0.04, 2), position + Vector3.new(x, 0.32, -size / 2 + 1.5), C.white, Enum.Material.SmoothPlastic)
    end
    for i = 0, 3 do
        local z = -size / 4 + i * (size / 6)
        makePart(parent, "CrossE_" .. i, Vector3.new(2, 0.04, 1.6), position + Vector3.new(size / 2 - 1.5, 0.32, z), C.white, Enum.Material.SmoothPlastic)
        makePart(parent, "CrossW_" .. i, Vector3.new(2, 0.04, 1.6), position + Vector3.new(-size / 2 + 1.5, 0.32, z), C.white, Enum.Material.SmoothPlastic)
    end

    -- Corner sidewalks
    for _, sx in ipairs({-1, 1}) do
        for _, sz in ipairs({-1, 1}) do
            makePart(parent, "CornerSW_" .. sx .. "_" .. sz, Vector3.new(4, 0.5, 4), position + Vector3.new(sx * (size / 2 + 2), 0.25, sz * (size / 2 + 2)), C.sidewalk, Enum.Material.Concrete)
        end
    end
end

------------------------------------------------------------
-- DECORATION: Traffic Light (Blender 3D)
------------------------------------------------------------
local function createTrafficLight(parent: Instance, position: Vector3)
    local model = makeModel(parent, "TrafficLight")

    -- Pole
    makeCylinder(model, "Pole", Vector3.new(12, 0.24, 0.24), position + Vector3.new(0, 6, 0), C.metalDark, Enum.Material.Metal, Vector3.new(0, 0, 90))

    -- Light housing
    makePart(model, "LightBox", Vector3.new(1, 3, 0.7), position + Vector3.new(0, 11, 0.4), C.metalDark, Enum.Material.Metal)

    -- Red light
    local redLight = makeCylinder(model, "RedLight", Vector3.new(0.16, 0.3, 0.3), position + Vector3.new(0, 12, 0.8), C.neonRed, Enum.Material.Neon, Vector3.new(0, 90, 0))
    addLight(redLight, Color3.fromRGB(255, 0, 0), 8, 0.5)

    -- Yellow light
    makeCylinder(model, "YellowLight", Vector3.new(0.16, 0.3, 0.3), position + Vector3.new(0, 11, 0.8), C.neonYellow, Enum.Material.Neon, Vector3.new(0, 90, 0))

    -- Green light
    makeCylinder(model, "GreenLight", Vector3.new(0.16, 0.3, 0.3), position + Vector3.new(0, 10, 0.8), C.neonGreen, Enum.Material.Neon, Vector3.new(0, 90, 0))

    -- Visors
    for _, y in ipairs({12, 11, 10}) do
        makePart(model, "Visor_" .. y, Vector3.new(1, 0.4, 0.3), position + Vector3.new(0, y, 0.9), C.metalDark, Enum.Material.Metal)
    end

    model.Parent = parent
    return model
end

------------------------------------------------------------
-- DECORATION: Street Lamp (Blender 3D)
------------------------------------------------------------
local function createStreetLamp(parent: Instance, position: Vector3)
    -- Pole
    makeCylinder(parent, "LampPole", Vector3.new(10, 0.2, 0.2), position + Vector3.new(0, 5, 0), C.metalDark, Enum.Material.Metal, Vector3.new(0, 0, 90))

    -- Arm
    makePart(parent, "LampArm", Vector3.new(2.4, 0.16, 0.16), position + Vector3.new(1.2, 10, 0), C.metalDark, Enum.Material.Metal)

    -- Light fixture
    local lampHead = makePart(parent, "LampHead", Vector3.new(1.2, 0.3, 0.8), position + Vector3.new(2.2, 9.7, 0), C.metalDark, Enum.Material.Metal)
    local lampGlow = makePart(parent, "LampGlow", Vector3.new(1, 0.1, 0.7), position + Vector3.new(2.2, 9.5, 0), C.neonYellow, Enum.Material.Neon)
    addSpotLight(lampGlow, Color3.fromRGB(255, 230, 180), 35, 1)

    -- Base
    makeCylinder(parent, "LampBase", Vector3.new(0.6, 0.5, 0.5), position + Vector3.new(0, 0.3, 0), C.metalDark, Enum.Material.Metal, Vector3.new(0, 0, 90))
end

------------------------------------------------------------
-- DECORATION: Palm Tree (Blender 3D)
------------------------------------------------------------
local function createPalmTree(parent: Instance, position: Vector3)
    local rng = Random.new(math.floor(position.X * 100 + position.Z))
    local trunkH = rng:NextInteger(8, 14)

    -- Trunk segments (tapered)
    for i = 0, 4 do
        local r = 0.5 - i * 0.06
        local y = i * (trunkH / 5) + (trunkH / 10)
        makeCylinder(parent, "Trunk_" .. i, Vector3.new(trunkH / 5, r * 2, r * 2), position + Vector3.new(0, y, 0), C.brown, Enum.Material.Wood, Vector3.new(0, 0, 90))
    end

    -- Leaf crown (ball)
    local crownY = trunkH + 1
    makeBall(parent, "LeafCrown", Vector3.new(8, 4, 8), position + Vector3.new(0, crownY, 0), C.darkGreen, Enum.Material.Grass)

    -- Extra leaves (extending out)
    for i = 0, 3 do
        local angle = i * 90
        local rad = math.rad(angle)
        local lx = math.cos(rad) * 3
        local lz = math.sin(rad) * 3
        makePart(parent, "Leaf_" .. i, Vector3.new(1, 0.2, 5), position + Vector3.new(lx, crownY - 1, lz), C.green, Enum.Material.Grass)
    end
end

------------------------------------------------------------
-- DECORATION: Bench (Blender 3D)
------------------------------------------------------------
local function createBench(parent: Instance, position: Vector3)
    makePart(parent, "BenchSeat", Vector3.new(3.6, 0.16, 1), position + Vector3.new(0, 0.9, 0), C.woodLight, Enum.Material.Wood)
    makePart(parent, "BenchBack", Vector3.new(3.6, 1, 0.12), position + Vector3.new(0, 1.6, -0.44), C.woodLight, Enum.Material.Wood)
    makePart(parent, "BenchLegL", Vector3.new(0.16, 0.9, 1), position + Vector3.new(-1.4, 0.45, 0), C.metalDark, Enum.Material.Metal)
    makePart(parent, "BenchLegR", Vector3.new(0.16, 0.9, 1), position + Vector3.new(1.4, 0.45, 0), C.metalDark, Enum.Material.Metal)
end

------------------------------------------------------------
-- DECORATION: Trash Can (Blender 3D)
------------------------------------------------------------
local function createTrashCan(parent: Instance, position: Vector3)
    makeCylinder(parent, "TrashBody", Vector3.new(2, 0.6, 0.6), position + Vector3.new(0, 1, 0), C.darkGreen, Enum.Material.Metal, Vector3.new(0, 0, 90))
    makeCylinder(parent, "TrashLid", Vector3.new(0.16, 0.64, 0.64), position + Vector3.new(0, 2.1, 0), C.darkGreen, Enum.Material.Metal, Vector3.new(0, 0, 90))
end

------------------------------------------------------------
-- DECORATION: Fire Hydrant (Blender 3D)
------------------------------------------------------------
local function createHydrant(parent: Instance, position: Vector3)
    makeCylinder(parent, "HydrantBody", Vector3.new(1.4, 0.3, 0.3), position + Vector3.new(0, 0.7, 0), C.brightRed, Enum.Material.Metal, Vector3.new(0, 0, 90))
    makeBall(parent, "HydrantTop", Vector3.new(0.34, 0.34, 0.34), position + Vector3.new(0, 1.5, 0), C.brightRed, Enum.Material.Metal)
end

------------------------------------------------------------
-- DECORATION: Bus Stop (Blender 3D)
------------------------------------------------------------
local function createBusStop(parent: Instance, position: Vector3)
    -- Poles
    makeCylinder(parent, "BSPole1", Vector3.new(6, 0.12, 0.12), position + Vector3.new(-2.4, 3, 0), C.metalGrey, Enum.Material.Metal, Vector3.new(0, 0, 90))
    makeCylinder(parent, "BSPole2", Vector3.new(6, 0.12, 0.12), position + Vector3.new(2.4, 3, 0), C.metalGrey, Enum.Material.Metal, Vector3.new(0, 0, 90))

    -- Glass roof
    makePart(parent, "BSRoof", Vector3.new(5.6, 0.16, 2.4), position + Vector3.new(0, 6, 0), C.glass, Enum.Material.Glass, 0.4)

    -- Back panel (glass)
    makePart(parent, "BSBack", Vector3.new(5.6, 6, 0.12), position + Vector3.new(0, 3, -1.1), C.glass, Enum.Material.Glass, 0.5)

    -- Bench
    makePart(parent, "BSBench", Vector3.new(4, 0.16, 1), position + Vector3.new(0, 1, 0), C.metalGrey, Enum.Material.Metal)

    -- Sign
    makePart(parent, "BSSign", Vector3.new(0.8, 0.8, 0.08), position + Vector3.new(-2.4, 6.6, 0), C.blue, Enum.Material.SmoothPlastic)
end

------------------------------------------------------------
-- AREA: Park (Blender 3D - central park)
------------------------------------------------------------
local function buildPark(parent: Instance, basePos: Vector3)
    local model = makeModel(parent, "CityPark")
    local bp = basePos

    -- Grass ground
    makePart(model, "ParkGround", Vector3.new(40, 0.2, 30), bp + Vector3.new(0, -0.05, 0), C.grassGreen, Enum.Material.Grass)

    -- Paths
    makePart(model, "PathNS", Vector3.new(4, 0.1, 30), bp + Vector3.new(0, 0.02, 0), C.sand, Enum.Material.Sand)
    makePart(model, "PathEW", Vector3.new(30, 0.1, 4), bp + Vector3.new(0, 0.02, 0), C.sand, Enum.Material.Sand)

    -- Central fountain
    makeCylinder(model, "FountainBase", Vector3.new(1.6, 6, 6), bp + Vector3.new(0, 0.8, 0), C.marble, Enum.Material.Marble, Vector3.new(0, 0, 90))
    makeCylinder(model, "FountainWater", Vector3.new(1.2, 4.5, 4.5), bp + Vector3.new(0, 1, 0), C.water, Enum.Material.Glass, Vector3.new(0, 0, 90))
    makeCylinder(model, "FountainPillar", Vector3.new(3, 0.3, 0.3), bp + Vector3.new(0, 2.4, 0), C.marble, Enum.Material.Marble, Vector3.new(0, 0, 90))
    local spout = makePart(model, "FountainSpout", Vector3.new(1, 0.5, 1), bp + Vector3.new(0, 4, 0), C.water, Enum.Material.Neon, 0.3)
    addLight(spout, Color3.fromRGB(100, 180, 255), 15, 0.8)

    -- Flower beds (4 corners)
    for _, offset in ipairs({{10, 8}, {-10, 8}, {10, -8}, {-10, -8}}) do
        makeCylinder(model, "FlowerBed", Vector3.new(0.6, 3, 3), bp + Vector3.new(offset[1], 0.3, offset[2]), C.brown, Enum.Material.Sand, Vector3.new(0, 0, 90))
        -- Colorful flowers (small balls)
        for j = 0, 4 do
            local angle = j * 72
            local fx = offset[1] + math.cos(math.rad(angle)) * 1
            local fz = offset[2] + math.sin(math.rad(angle)) * 1
            local flowerColors = {C.brightRed, C.yellow, C.pastelOrange, C.cyan, C.white}
            makeBall(model, "Flower", Vector3.new(0.5, 0.5, 0.5), bp + Vector3.new(fx, 0.8, fz), flowerColors[(j % 5) + 1], Enum.Material.Grass)
        end
    end

    model.Parent = parent
    return model
end

------------------------------------------------------------
-- AREA: Beach (Blender 3D)
------------------------------------------------------------
local function buildBeach(parent: Instance, basePos: Vector3)
    local model = makeModel(parent, "Beach")
    local bp = basePos

    -- Sand
    makePart(model, "Sand", Vector3.new(60, 0.3, 20), bp + Vector3.new(0, -0.1, 0), C.sand, Enum.Material.Sand)

    -- Water
    local water = makePart(model, "Water", Vector3.new(60, 0.2, 20), bp + Vector3.new(0, -0.3, -15), C.water, Enum.Material.Glass, 0.3)
    water.CanCollide = false

    -- Beach umbrellas
    local umbrellaColors = {C.brightRed, C.blue, C.yellow, C.green}
    for i = 0, 3 do
        local ux = -20 + i * 14
        makeCylinder(model, "UmbPole_" .. i, Vector3.new(5, 0.12, 0.12), bp + Vector3.new(ux, 2.5, 4), C.woodLight, Enum.Material.Wood, Vector3.new(0, 0, 90))
        makeBall(model, "UmbTop_" .. i, Vector3.new(5, 2, 5), bp + Vector3.new(ux, 5.2, 4), umbrellaColors[(i % 4) + 1], Enum.Material.Fabric)
        -- Towels
        makePart(model, "Towel_" .. i, Vector3.new(3, 0.04, 4), bp + Vector3.new(ux, 0.02, 4), umbrellaColors[((i + 1) % 4) + 1], Enum.Material.Fabric)
    end

    -- Lifeguard chair
    makePart(model, "LGSeat", Vector3.new(3, 0.2, 2), bp + Vector3.new(0, 4, -4), C.woodLight, Enum.Material.Wood)
    makePart(model, "LGBack", Vector3.new(3, 1.6, 0.16), bp + Vector3.new(0, 5.2, -4.8), C.woodLight, Enum.Material.Wood)
    makePart(model, "LGLeg1", Vector3.new(0.2, 4, 0.2), bp + Vector3.new(-1.2, 2, -3.2), C.woodLight, Enum.Material.Wood)
    makePart(model, "LGLeg2", Vector3.new(0.2, 4, 0.2), bp + Vector3.new(1.2, 2, -3.2), C.woodLight, Enum.Material.Wood)
    makePart(model, "LGLeg3", Vector3.new(0.2, 4, 0.2), bp + Vector3.new(-1.2, 2, -4.8), C.woodLight, Enum.Material.Wood)
    makePart(model, "LGLeg4", Vector3.new(0.2, 4, 0.2), bp + Vector3.new(1.2, 2, -4.8), C.woodLight, Enum.Material.Wood)

    model.Parent = parent
    return model
end

------------------------------------------------------------
-- NPC Traffic car (simple model)
------------------------------------------------------------
local function createNPCCar(parent: Instance, position: Vector3, color: Color3): Model
    local model = makeModel(parent, "NPCCar")

    local body = makePart(model, "Body", Vector3.new(4, 1.6, 9), position + Vector3.new(0, 1, 0), color, Enum.Material.SmoothPlastic)
    model.PrimaryPart = body

    makePart(model, "Cabin", Vector3.new(3.6, 1.4, 5), position + Vector3.new(0, 2.2, -0.4), color, Enum.Material.SmoothPlastic)
    makePart(model, "Windshield", Vector3.new(3.2, 1.2, 0.16), position + Vector3.new(0, 2.2, 2), C.darkGlass, Enum.Material.Glass, 0.2)
    makePart(model, "RearWin", Vector3.new(3.2, 1, 0.16), position + Vector3.new(0, 2.2, -2.6), C.darkGlass, Enum.Material.Glass, 0.2)

    -- Headlights
    makePart(model, "HeadL", Vector3.new(0.8, 0.4, 0.2), position + Vector3.new(-1.4, 1, 4.6), C.neonYellow, Enum.Material.Neon)
    makePart(model, "HeadR", Vector3.new(0.8, 0.4, 0.2), position + Vector3.new(1.4, 1, 4.6), C.neonYellow, Enum.Material.Neon)

    -- Taillights
    makePart(model, "TailL", Vector3.new(0.8, 0.4, 0.2), position + Vector3.new(-1.4, 1, -4.6), C.neonRed, Enum.Material.Neon)
    makePart(model, "TailR", Vector3.new(0.8, 0.4, 0.2), position + Vector3.new(1.4, 1, -4.6), C.neonRed, Enum.Material.Neon)

    -- Wheels
    for _, wp in ipairs({{-2, 0, 2.6}, {2, 0, 2.6}, {-2, 0, -2.6}, {2, 0, -2.6}}) do
        makeCylinder(model, "Wheel", Vector3.new(0.5, 0.7, 0.7), position + Vector3.new(wp[1], wp[2], wp[3]), C.tire, Enum.Material.SmoothPlastic, Vector3.new(0, 0, 0))
    end

    model.Parent = parent
    return model
end

------------------------------------------------------------
-- DECORATION: Plaza / Seating Area
------------------------------------------------------------
local function createPlaza(parent: Instance, position: Vector3, size: number)
    size = size or 20
    local model = makeModel(parent, "Plaza")

    -- Brick/stone ground
    makePart(model, "PlazaGround", Vector3.new(size, 0.15, size), position + Vector3.new(0, 0.02, 0), C.sidewalk, Enum.Material.Brick)

    -- Border stones
    for _, side in ipairs({-1, 1}) do
        makePart(model, "BorderX", Vector3.new(size + 1, 0.4, 0.6), position + Vector3.new(0, 0.2, side * size / 2), C.concrete, Enum.Material.Concrete)
        makePart(model, "BorderZ", Vector3.new(0.6, 0.4, size + 1), position + Vector3.new(side * size / 2, 0.2, 0), C.concrete, Enum.Material.Concrete)
    end

    -- Center decorative circle
    makeCylinder(model, "CenterCircle", Vector3.new(0.12, size / 3, size / 3), position + Vector3.new(0, 0.1, 0), Color3.fromRGB(180, 160, 130), Enum.Material.Cobblestone, Vector3.new(0, 0, 90))

    -- Corner planters with flowers
    for _, sx in ipairs({-1, 1}) do
        for _, sz in ipairs({-1, 1}) do
            local cx = sx * (size / 2 - 3)
            local cz = sz * (size / 2 - 3)
            makePart(model, "Planter", Vector3.new(4, 1.2, 4), position + Vector3.new(cx, 0.6, cz), C.concrete, Enum.Material.Concrete)
            makePart(model, "Soil", Vector3.new(3.6, 0.2, 3.6), position + Vector3.new(cx, 1.3, cz), C.brown, Enum.Material.Sand)
            -- Flowers
            for f = 0, 2 do
                local fx = cx + (f - 1) * 1.2
                local flowerC = ({C.brightRed, C.yellow, C.pastelOrange})[f + 1]
                makeBall(model, "Flower", Vector3.new(0.6, 0.6, 0.6), position + Vector3.new(fx, 1.7, cz), flowerC, Enum.Material.Grass)
            end
        end
    end

    -- Benches around the plaza
    for _, side in ipairs({-1, 1}) do
        createBench(model, position + Vector3.new(side * (size / 2 - 2), 0, 0))
        createBench(model, position + Vector3.new(0, 0, side * (size / 2 - 2)))
    end

    model.Parent = parent
    return model
end

------------------------------------------------------------
-- DECORATION: Parking Lot
------------------------------------------------------------
local function createParkingLot(parent: Instance, position: Vector3, spots: number, horizontal: boolean)
    spots = spots or 4
    for i = 0, spots - 1 do
        local ox, oz
        if horizontal then
            ox = -((spots - 1) * 4) / 2 + i * 4
            oz = 0
        else
            ox = 0
            oz = -((spots - 1) * 4) / 2 + i * 4
        end
        -- Parking spot outline
        local w, d = 3.5, 6
        makePart(parent, "ParkSpot", Vector3.new(w, 0.06, d), position + Vector3.new(ox, 0.03, oz), C.asphalt, Enum.Material.Asphalt)
        -- White line borders
        makePart(parent, "ParkLine", Vector3.new(0.12, 0.04, d), position + Vector3.new(ox - w / 2, 0.07, oz), C.white, Enum.Material.SmoothPlastic)
        makePart(parent, "ParkLine", Vector3.new(0.12, 0.04, d), position + Vector3.new(ox + w / 2, 0.07, oz), C.white, Enum.Material.SmoothPlastic)
    end
end

------------------------------------------------------------
-- DECORATION: Flower Bed Row (sidewalk accent)
------------------------------------------------------------
local function createFlowerRow(parent: Instance, position: Vector3, length: number, axis: string)
    local count = math.floor(length / 3)
    for i = 0, count - 1 do
        local offset = -(count - 1) * 1.5 + i * 3
        local pos
        if axis == "x" then
            pos = position + Vector3.new(offset, 0, 0)
        else
            pos = position + Vector3.new(0, 0, offset)
        end
        -- Planter box
        makePart(parent, "FlowerBox", Vector3.new(2.4, 0.8, 1.2), pos + Vector3.new(0, 0.4, 0), C.concrete, Enum.Material.Concrete)
        makePart(parent, "FlowerSoil", Vector3.new(2, 0.15, 0.8), pos + Vector3.new(0, 0.85, 0), C.brown, Enum.Material.Sand)
        -- Flowers
        local flowerColors = {C.brightRed, C.yellow, C.pastelOrange, C.cyan, C.white}
        makeBall(parent, "Flower", Vector3.new(0.5, 0.5, 0.5), pos + Vector3.new(-0.5, 1.1, 0), flowerColors[(i % 5) + 1], Enum.Material.Grass)
        makeBall(parent, "Flower", Vector3.new(0.5, 0.5, 0.5), pos + Vector3.new(0.5, 1.1, 0), flowerColors[((i + 2) % 5) + 1], Enum.Material.Grass)
    end
end

------------------------------------------------------------
-- DECORATION: Roundabout with Fountain
------------------------------------------------------------
local function createRoundabout(parent: Instance, position: Vector3, radius: number)
    radius = radius or 16
    local model = makeModel(parent, "Roundabout")

    -- Road ring
    makeCylinder(model, "RoadRing", Vector3.new(0.3, radius * 2 + 12, radius * 2 + 12), position + Vector3.new(0, 0.15, 0), C.asphalt, Enum.Material.Asphalt, Vector3.new(0, 0, 90))

    -- Inner island (grass + brick)
    makeCylinder(model, "Island", Vector3.new(0.2, radius * 2, radius * 2), position + Vector3.new(0, 0.12, 0), C.grassGreen, Enum.Material.Grass, Vector3.new(0, 0, 90))
    makeCylinder(model, "IslandBorder", Vector3.new(0.5, radius * 2 + 0.6, radius * 2 + 0.6), position + Vector3.new(0, 0.25, 0), C.concrete, Enum.Material.Concrete, Vector3.new(0, 0, 90))

    -- Central fountain (grand)
    makeCylinder(model, "FountainPool", Vector3.new(1.5, 8, 8), position + Vector3.new(0, 0.75, 0), C.marble, Enum.Material.Marble, Vector3.new(0, 0, 90))
    makeCylinder(model, "FountainWater", Vector3.new(1, 6.5, 6.5), position + Vector3.new(0, 1.2, 0), C.water, Enum.Material.Glass, Vector3.new(0, 0, 90))
    makeCylinder(model, "FountainPillar", Vector3.new(6, 0.6, 0.6), position + Vector3.new(0, 4, 0), C.marble, Enum.Material.Marble, Vector3.new(0, 0, 90))

    -- Tiered bowls
    makeCylinder(model, "Bowl1", Vector3.new(0.3, 3, 3), position + Vector3.new(0, 3, 0), C.marble, Enum.Material.Marble, Vector3.new(0, 0, 90))
    makeCylinder(model, "Bowl2", Vector3.new(0.3, 2, 2), position + Vector3.new(0, 5.5, 0), C.marble, Enum.Material.Marble, Vector3.new(0, 0, 90))

    -- Top spout with light
    local spout = makePart(model, "Spout", Vector3.new(1, 0.6, 1), position + Vector3.new(0, 7.5, 0), C.water, Enum.Material.Neon, 0.3)
    addLight(spout, Color3.fromRGB(100, 200, 255), 30, 1.2)

    -- Accent lights around fountain base
    for i = 0, 5 do
        local angle = math.rad(i * 60)
        local lx = math.cos(angle) * 3.5
        local lz = math.sin(angle) * 3.5
        local uplighter = makePart(model, "Uplighter", Vector3.new(0.4, 0.3, 0.4), position + Vector3.new(lx, 0.15, lz), C.gold, Enum.Material.Neon, 0.5)
        addLight(uplighter, Color3.fromRGB(255, 220, 150), 12, 0.6)
    end

    -- Decorative palm trees on island
    for i = 0, 3 do
        local angle = math.rad(i * 90 + 45)
        local tx = math.cos(angle) * (radius - 3)
        local tz = math.sin(angle) * (radius - 3)
        createPalmTree(model, position + Vector3.new(tx, 0, tz))
    end

    model.Parent = parent
    return model
end

------------------------------------------------------------
-- GROUND ZONE: Urban ground patch (concrete/brick/grass)
------------------------------------------------------------
local function createGroundZone(parent: Instance, position: Vector3, sizeX: number, sizeZ: number, material: Enum.Material, color: Color3)
    local zone = makePart(parent, "GroundZone", Vector3.new(sizeX, 0.12, sizeZ), position + Vector3.new(0, 0.01, 0), color, material)
    zone.CanCollide = true
    return zone
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
    -- =============================================
    -- GROUND LAYERS
    -- =============================================

    -- City ground (warm sand base — desert city feel)
    local ground = makePart(Workspace, "CityGround", Vector3.new(700, 1, 700), Vector3.new(0, -0.5, 0), C.sand, Enum.Material.Sand)
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

    local groundFolder = Instance.new("Folder")
    groundFolder.Name = "GroundZones"
    groundFolder.Parent = Workspace

    -- Urban concrete zones (under building districts)
    -- Commercial district (top-left)
    createGroundZone(groundFolder, Vector3.new(-130, 0, -130), 120, 120, Enum.Material.Concrete, C.sidewalk)
    -- Government district (top-center)
    createGroundZone(groundFolder, Vector3.new(0, 0, -130), 100, 120, Enum.Material.Concrete, Color3.fromRGB(170, 165, 158))
    -- Residential area (top-right)
    createGroundZone(groundFolder, Vector3.new(130, 0, -130), 120, 120, Enum.Material.Brick, Color3.fromRGB(185, 175, 160))
    -- City center (center)
    createGroundZone(groundFolder, Vector3.new(0, 0, 0), 100, 100, Enum.Material.Cobblestone, Color3.fromRGB(175, 168, 155))
    -- Entertainment (mid-left)
    createGroundZone(groundFolder, Vector3.new(-130, 0, 0), 120, 100, Enum.Material.Concrete, Color3.fromRGB(165, 160, 152))
    -- Business (mid-right)
    createGroundZone(groundFolder, Vector3.new(130, 0, 0), 120, 100, Enum.Material.Concrete, C.sidewalk)
    -- Education & parks (bottom-center) — grass
    createGroundZone(groundFolder, Vector3.new(0, 0, 130), 100, 120, Enum.Material.Grass, Color3.fromRGB(80, 140, 50))
    -- Industrial (bottom-left)
    createGroundZone(groundFolder, Vector3.new(-130, 0, 130), 120, 120, Enum.Material.Concrete, C.concrete)
    -- Beach (bottom-right)
    createGroundZone(groundFolder, Vector3.new(130, 0, 130), 120, 120, Enum.Material.Sand, Color3.fromRGB(210, 195, 155))

    -- =============================================
    -- STREETS — Professional grid layout
    -- =============================================

    -- Main boulevards (wider, 16 studs)
    createRoad(streetsFolder, Vector3.new(-320, 0, 0), Vector3.new(320, 0, 0), 16)
    createRoad(streetsFolder, Vector3.new(0, 0, -320), Vector3.new(0, 0, 320), 16)

    -- Secondary roads (12 studs)
    createRoad(streetsFolder, Vector3.new(-320, 0, -130), Vector3.new(320, 0, -130), 12)
    createRoad(streetsFolder, Vector3.new(-320, 0, 130), Vector3.new(320, 0, 130), 12)
    createRoad(streetsFolder, Vector3.new(-130, 0, -320), Vector3.new(-130, 0, 320), 12)
    createRoad(streetsFolder, Vector3.new(130, 0, -320), Vector3.new(130, 0, 320), 12)

    -- Intersections (where roads cross)
    local interPts = {
        {0, 0}, {-130, 0}, {130, 0}, {0, -130}, {0, 130},
        {-130, -130}, {130, -130}, {-130, 130}, {130, 130},
    }
    for _, ip in ipairs(interPts) do
        createIntersection(streetsFolder, Vector3.new(ip[1], 0, ip[2]), 22)
    end

    -- Central roundabout (replaces the main intersection)
    createRoundabout(streetsFolder, Vector3.new(0, 0, 0), 16)

    -- Traffic lights at all intersections except center (roundabout)
    local tlCorners = {
        -- NW intersection
        {-142, 0, -12}, {-118, 0, 12},
        -- NE intersection
        {118, 0, -12}, {142, 0, 12},
        -- SW intersection
        {-142, 0, 118}, {-118, 0, 142},
        -- SE intersection
        {118, 0, 118}, {142, 0, 142},
        -- N center
        {-12, 0, -142}, {12, 0, -118},
        -- S center
        {-12, 0, 118}, {12, 0, 142},
        -- W center
        {-142, 0, -12}, {-118, 0, 12},
        -- E center
        {118, 0, -12}, {142, 0, 12},
    }
    for _, tp in ipairs(tlCorners) do
        createTrafficLight(decorFolder, Vector3.new(tp[1], tp[2], tp[3]))
    end

    -- =============================================
    -- STREET LAMPS — Along all roads, evenly spaced
    -- =============================================

    -- Along main horizontal boulevard
    for x = -280, 280, 30 do
        if math.abs(x) > 20 then
            createStreetLamp(decorFolder, Vector3.new(x, 0, 12))
            createStreetLamp(decorFolder, Vector3.new(x, 0, -12))
        end
    end
    -- Along main vertical boulevard
    for z = -280, 280, 30 do
        if math.abs(z) > 20 then
            createStreetLamp(decorFolder, Vector3.new(12, 0, z))
            createStreetLamp(decorFolder, Vector3.new(-12, 0, z))
        end
    end
    -- Along secondary horizontal roads
    for _, rz in ipairs({-130, 130}) do
        for x = -280, 280, 40 do
            createStreetLamp(decorFolder, Vector3.new(x, 0, rz + 10))
        end
    end
    -- Along secondary vertical roads
    for _, rx in ipairs({-130, 130}) do
        for z = -280, 280, 40 do
            createStreetLamp(decorFolder, Vector3.new(rx + 10, 0, z))
        end
    end

    -- =============================================
    -- BUILDINGS (organized by district)
    -- =============================================

    -- ---- COMMERCIAL DISTRICT (NW quadrant) ----
    buildMall(buildingsFolder, Vector3.new(-170, 0, -190))
    buildRestaurant(buildingsFolder, Vector3.new(-100, 0, -190))
    buildHotel(buildingsFolder, Vector3.new(-170, 0, -100))
    buildDealership(buildingsFolder, Vector3.new(-100, 0, -90))

    -- ---- GOVERNMENT DISTRICT (N center) ----
    buildPoliceStation(buildingsFolder, Vector3.new(-30, 0, -190))
    buildFireStation(buildingsFolder, Vector3.new(30, 0, -190))
    buildHospital(buildingsFolder, Vector3.new(-10, 0, -100))

    -- ---- RESIDENTIAL AREA (NE quadrant) ----
    local villaPositions = {
        Vector3.new(90, 0, -190),
        Vector3.new(140, 0, -190),
        Vector3.new(190, 0, -170),
        Vector3.new(90, 0, -120),
        Vector3.new(140, 0, -120),
    }
    for i, vp in ipairs(villaPositions) do
        buildVilla(buildingsFolder, vp, i)
    end

    -- ---- CITY CENTER (center) ----
    buildMosque(buildingsFolder, Vector3.new(-35, 0, 15))
    buildBank(buildingsFolder, Vector3.new(30, 0, 15))

    -- ---- BUSINESS DISTRICT (E center) ----
    buildGasStation(buildingsFolder, Vector3.new(90, 0, -30))

    -- ---- SOUTH ZONE ----
    -- Industrial (SW)
    buildAirport(buildingsFolder, Vector3.new(-180, 0, 60))
    -- Education & parks (S center)
    buildSchool(buildingsFolder, Vector3.new(-20, 0, 60))
    -- Beach & leisure (SE)
    buildBeach(decorFolder, Vector3.new(130, 0, 180))

    -- =============================================
    -- PLAZAS & SEATING AREAS
    -- =============================================

    -- Commercial plaza (near mall)
    createPlaza(decorFolder, Vector3.new(-135, 0, -155), 18)
    -- Government plaza (in front of hospital)
    createPlaza(decorFolder, Vector3.new(0, 0, -75), 16)
    -- City center plaza (near mosque)
    createPlaza(decorFolder, Vector3.new(0, 0, 50), 22)
    -- Residential mini-plaza
    createPlaza(decorFolder, Vector3.new(120, 0, -155), 14)

    -- =============================================
    -- PARKING LOTS
    -- =============================================

    -- Hospital parking
    createParkingLot(decorFolder, Vector3.new(30, 0, -80), 5, true)
    -- Mall parking
    createParkingLot(decorFolder, Vector3.new(-135, 0, -215), 6, true)
    -- Police parking
    createParkingLot(decorFolder, Vector3.new(-30, 0, -215), 3, true)
    -- Airport parking
    createParkingLot(decorFolder, Vector3.new(-180, 0, 100), 5, true)
    -- Dealership parking
    createParkingLot(decorFolder, Vector3.new(-65, 0, -80), 4, true)

    -- =============================================
    -- CENTRAL PARK (larger, south-center)
    -- =============================================

    buildPark(decorFolder, Vector3.new(30, 0, 80))

    -- =============================================
    -- FLOWER ROWS along major sidewalks
    -- =============================================

    -- Main boulevard flower accents
    createFlowerRow(decorFolder, Vector3.new(-60, 0, 15), 30, "x")
    createFlowerRow(decorFolder, Vector3.new(60, 0, 15), 30, "x")
    createFlowerRow(decorFolder, Vector3.new(15, 0, -60), 30, "z")
    createFlowerRow(decorFolder, Vector3.new(15, 0, 60), 30, "z")
    -- Near mosque
    createFlowerRow(decorFolder, Vector3.new(-35, 0, 50), 20, "x")
    -- Near hospital
    createFlowerRow(decorFolder, Vector3.new(-10, 0, -80), 20, "x")

    -- =============================================
    -- PALM TREES (denser, avoid roads + buildings)
    -- =============================================

    local rng = Random.new(42)
    for x = -280, 280, 35 do
        for z = -280, 280, 35 do
            local tx = x + rng:NextInteger(-10, 10)
            local tz = z + rng:NextInteger(-10, 10)
            -- Skip if on road
            local onRoad = false
            for _, ro in ipairs({0, -130, 130}) do
                if math.abs(tx - ro) < 14 or math.abs(tz - ro) < 14 then
                    onRoad = true
                    break
                end
            end
            if not onRoad then
                createPalmTree(decorFolder, Vector3.new(tx, 0, tz))
            end
        end
    end

    -- =============================================
    -- BENCHES along all roads
    -- =============================================

    local benchSpots = {
        -- Main boulevard benches
        {30, 0, 14}, {-30, 0, 14}, {60, 0, 14}, {-60, 0, 14},
        {90, 0, 14}, {-90, 0, 14},
        {14, 0, 30}, {14, 0, -30}, {14, 0, 60}, {14, 0, -60},
        {14, 0, 90}, {14, 0, -90},
        -- Secondary road benches
        {30, 0, 143}, {-30, 0, 143}, {60, 0, 143}, {-60, 0, 143},
        {30, 0, -143}, {-30, 0, -143}, {60, 0, -143},
        {143, 0, 30}, {143, 0, -30}, {143, 0, 60},
        {-143, 0, 30}, {-143, 0, -30}, {-143, 0, 60},
    }
    for _, bp in ipairs(benchSpots) do
        createBench(decorFolder, Vector3.new(bp[1], bp[2], bp[3]))
    end

    -- Trash cans near every bench
    for _, bp in ipairs(benchSpots) do
        createTrashCan(decorFolder, Vector3.new(bp[1] + 3, bp[2], bp[3]))
    end

    -- =============================================
    -- FIRE HYDRANTS along streets
    -- =============================================

    for x = -260, 260, 60 do
        createHydrant(decorFolder, Vector3.new(x, 0, 14))
    end
    for z = -260, 260, 60 do
        if math.abs(z) > 20 then
            createHydrant(decorFolder, Vector3.new(14, 0, z))
        end
    end

    -- =============================================
    -- BUS STOPS
    -- =============================================

    createBusStop(decorFolder, Vector3.new(40, 0, 13))
    createBusStop(decorFolder, Vector3.new(-40, 0, -13))
    createBusStop(decorFolder, Vector3.new(140, 0, 13))
    createBusStop(decorFolder, Vector3.new(-140, 0, -13))
    createBusStop(decorFolder, Vector3.new(13, 0, 140))
    createBusStop(decorFolder, Vector3.new(-13, 0, -140))

    -- =============================================
    -- NPC TRAFFIC CARS (parked in realistic spots)
    -- =============================================

    local npcCarColors = {C.brightRed, C.blue, C.white, C.metalGrey, C.gold, C.black, C.darkGreen, C.creamWall}
    local npcCarPositions = {
        -- Near mall
        {-145, 0, -218}, {-135, 0, -218}, {-125, 0, -218},
        -- Near police
        {-20, 0, -218},
        -- Near hospital
        {35, 0, -83}, {40, 0, -83},
        -- Near airport
        {-175, 0, 103}, {-170, 0, 103},
        -- Main boulevard parked
        {50, 0, 18}, {-70, 0, 18},
        -- Residential area
        {100, 0, -215}, {150, 0, -215},
    }
    for i, ncp in ipairs(npcCarPositions) do
        createNPCCar(decorFolder, Vector3.new(ncp[1], ncp[2], ncp[3]), npcCarColors[(i % #npcCarColors) + 1])
    end

    print("[ArabCity] MapBuilder: City built (Professional Layout) - " .. tostring(#buildingsFolder:GetChildren()) .. " buildings, " .. tostring(#decorFolder:GetChildren()) .. " decorations")
end

return MapBuilder
