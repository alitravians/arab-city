--[[
    Arab City - Map Builder Service
    Procedurally generates the entire city: terrain, roads, buildings,
    landmarks, properties, vehicle spawns, decorations, and lighting.

    City Layout (top-down):
        NW: VIP Zone          N: Residential        NE: Hospital/Police
        W:  Airport           C: Main Plaza          E:  Mall/Bank
        SW: Fire Station      S: Beach/Waterfront   SE: Car Dealership

    Palace is placed by PalaceService at (500, 0.5, 500).
    Plane flies from x=-1000 to x=1000 at altitude 500.
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local MapBuilder = {}

-- City dimensions
local CITY_SIZE = 800 -- total city footprint
local HALF = CITY_SIZE / 2
local ROAD_WIDTH = 16
local SIDEWALK_WIDTH = 4
local BLOCK_SIZE = 80

-- Material palette
local MAT = {
    Road      = Enum.Material.Asphalt,
    Sidewalk  = Enum.Material.Concrete,
    Grass     = Enum.Material.Grass,
    Sand      = Enum.Material.Sand,
    Water     = Enum.Material.Glass,
    Concrete  = Enum.Material.Concrete,
    Brick     = Enum.Material.Brick,
    Glass     = Enum.Material.Glass,
    Metal     = Enum.Material.Metal,
    Marble    = Enum.Material.Marble,
    Wood      = Enum.Material.WoodPlanks,
    Neon      = Enum.Material.Neon,
    Smooth    = Enum.Material.SmoothPlastic,
}

-- Color palette (Midnight Blue Neon theme)
local COL = {
    Road        = Color3.fromRGB(40, 40, 45),
    RoadLine    = Color3.fromRGB(255, 200, 50),
    Sidewalk    = Color3.fromRGB(130, 130, 135),
    Grass       = Color3.fromRGB(45, 130, 55),
    DarkGrass   = Color3.fromRGB(35, 100, 40),
    Sand        = Color3.fromRGB(230, 210, 160),
    Water       = Color3.fromRGB(30, 80, 160),
    WallLight   = Color3.fromRGB(200, 210, 220),
    WallDark    = Color3.fromRGB(60, 65, 75),
    WallBrick   = Color3.fromRGB(140, 70, 50),
    Roof        = Color3.fromRGB(50, 55, 65),
    Window      = Color3.fromRGB(120, 180, 230),
    NeonCyan    = Color3.fromRGB(0, 230, 255),
    NeonPink    = Color3.fromRGB(255, 0, 120),
    Gold        = Color3.fromRGB(255, 215, 0),
    TreeTrunk   = Color3.fromRGB(90, 60, 30),
    TreeLeaf    = Color3.fromRGB(40, 120, 45),
    PalmTrunk   = Color3.fromRGB(110, 80, 40),
    PalmLeaf    = Color3.fromRGB(50, 140, 50),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(20, 20, 20),
    Red         = Color3.fromRGB(200, 40, 40),
    Blue        = Color3.fromRGB(40, 80, 200),
    VIPGold     = Color3.fromRGB(180, 150, 50),
    HospWhite   = Color3.fromRGB(240, 245, 250),
    PoliceBlue  = Color3.fromRGB(30, 60, 140),
}

----------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------

local function makePart(parent, name, size, pos, color, material, extras)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = pos
    p.Anchored = true
    p.Color = color or COL.WallLight
    p.Material = material or MAT.Smooth
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if extras then
        for k, v in pairs(extras) do
            p[k] = v
        end
    end
    p.Parent = parent
    return p
end

local function makeModel(parent, name)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent
    return m
end

local function addBillboard(parent, text, color, offset)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(12, 0, 3, 0)
    bb.StudsOffset = offset or Vector3.new(0, 15, 0)
    bb.AlwaysOnTop = false
    bb.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or COL.White
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = COL.Black
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.Parent = bb
    return bb
end

local function addPointLight(parent, color, brightness, range)
    local pl = Instance.new("PointLight")
    pl.Color = color or COL.NeonCyan
    pl.Brightness = brightness or 2
    pl.Range = range or 30
    pl.Parent = parent
    return pl
end

local function makeStreetLight(parent, x, z, color)
    local pole = makePart(parent, "LightPole", Vector3.new(0.4, 12, 0.4), Vector3.new(x, 6, z), COL.WallDark, MAT.Metal)
    local arm = makePart(parent, "LightArm", Vector3.new(3, 0.3, 0.3), Vector3.new(x + 1.5, 11.5, z), COL.WallDark, MAT.Metal)
    local bulb = makePart(parent, "LightBulb", Vector3.new(1, 0.5, 1), Vector3.new(x + 3, 11.2, z), color or COL.NeonCyan, MAT.Neon)
    addPointLight(bulb, color or COL.NeonCyan, 1.5, 40)
    return pole, arm, bulb
end

local function makeTree(parent, x, z, treeType)
    treeType = treeType or "normal"
    local model = makeModel(parent, "Tree")
    if treeType == "palm" then
        makePart(model, "Trunk", Vector3.new(1, 12, 1), Vector3.new(x, 6, z), COL.PalmTrunk, MAT.Wood)
        makePart(model, "Leaves", Vector3.new(8, 2, 8), Vector3.new(x, 13, z), COL.PalmLeaf, MAT.Grass, { Shape = Enum.PartType.Ball })
    else
        makePart(model, "Trunk", Vector3.new(1.2, 8, 1.2), Vector3.new(x, 4, z), COL.TreeTrunk, MAT.Wood)
        makePart(model, "Leaves", Vector3.new(6, 6, 6), Vector3.new(x, 9, z), COL.TreeLeaf, MAT.Grass, { Shape = Enum.PartType.Ball })
    end
    return model
end

-- Property marker that RealEstateService reads via CollectionService tags
local function makePropertyMarker(parent, propId, nameAr, price, rooms, area, pos)
    local marker = makePart(parent, propId, Vector3.new(3, 4, 0.3), pos + Vector3.new(0, 2, 0), COL.Gold, MAT.Neon)
    CollectionService:AddTag(marker, "Property")
    local cfg = Instance.new("Configuration")
    cfg.Name = "PropertyConfig"
    cfg:SetAttribute("PropertyId", propId)
    cfg:SetAttribute("Name", propId)
    cfg:SetAttribute("NameAr", nameAr)
    cfg:SetAttribute("Price", price)
    cfg:SetAttribute("Rooms", rooms)
    cfg:SetAttribute("Area", area)
    cfg:SetAttribute("Owner", 0)
    cfg.Parent = marker

    addBillboard(marker, "🏠 " .. nameAr .. "\n💰 " .. tostring(price) .. "$", COL.Gold, Vector3.new(0, 4, 0))
    return marker
end

----------------------------------------------------------------------------
-- Building Generators
----------------------------------------------------------------------------

local function makeBuilding(parent, name, cx, cz, w, d, h, wallColor, roofColor, windowColor, labelText, labelColor)
    local model = makeModel(parent, name)
    wallColor = wallColor or COL.WallLight
    roofColor = roofColor or COL.Roof
    windowColor = windowColor or COL.Window

    -- Main body
    local body = makePart(model, "Body", Vector3.new(w, h, d), Vector3.new(cx, h / 2, cz), wallColor, MAT.Concrete)

    -- Roof
    makePart(model, "Roof", Vector3.new(w + 2, 1, d + 2), Vector3.new(cx, h + 0.5, cz), roofColor, MAT.Concrete)

    -- Windows (front and back)
    local windowRows = math.max(1, math.floor(h / 6))
    local windowCols = math.max(1, math.floor(w / 6))
    for row = 1, windowRows do
        for col = 1, windowCols do
            local wy = row * (h / (windowRows + 1))
            local wx = (col - (windowCols + 1) / 2) * (w / (windowCols + 1))

            -- Front windows
            makePart(model, "Win", Vector3.new(2, 2.5, 0.2),
                Vector3.new(cx + wx, wy, cz + d / 2 + 0.1), windowColor, MAT.Glass,
                { Transparency = 0.3 })

            -- Back windows
            makePart(model, "Win", Vector3.new(2, 2.5, 0.2),
                Vector3.new(cx + wx, wy, cz - d / 2 - 0.1), windowColor, MAT.Glass,
                { Transparency = 0.3 })
        end
    end

    -- Door
    makePart(model, "Door", Vector3.new(3, 5, 0.3), Vector3.new(cx, 2.5, cz + d / 2 + 0.15), COL.WallDark, MAT.Metal)

    -- Label
    if labelText then
        addBillboard(body, labelText, labelColor or COL.White, Vector3.new(0, h / 2 + 5, 0))
    end

    return model
end

local function makeHouse(parent, name, cx, cz, wallColor)
    local model = makeModel(parent, name)
    wallColor = wallColor or COL.WallLight

    makePart(model, "Body", Vector3.new(14, 6, 12), Vector3.new(cx, 3, cz), wallColor, MAT.Concrete)
    makePart(model, "Roof", Vector3.new(16, 1, 14), Vector3.new(cx, 6.5, cz), COL.Roof, MAT.Concrete)

    -- Windows
    for _, offX in ipairs({ -4, 4 }) do
        makePart(model, "Win", Vector3.new(2, 2, 0.2), Vector3.new(cx + offX, 3.5, cz + 6.1), COL.Window, MAT.Glass, { Transparency = 0.3 })
    end

    -- Door
    makePart(model, "Door", Vector3.new(2.5, 4, 0.3), Vector3.new(cx, 2, cz + 6.15), COL.WallDark, MAT.Wood)

    -- Yard
    makePart(model, "Yard", Vector3.new(18, 0.2, 8), Vector3.new(cx, 0.1, cz + 12), COL.Grass, MAT.Grass)

    return model
end

----------------------------------------------------------------------------
-- Main Build
----------------------------------------------------------------------------

function MapBuilder:Init()
    self._cityFolder = makeModel(workspace, "ArabCity_Map")
    self:_buildTerrain()
    self:_buildRoads()
    self:_buildCentralPlaza()
    self:_buildResidentialDistrict()
    self:_buildCommercialDistrict()
    self:_buildBeach()
    self:_buildAirport()
    self:_buildHospital()
    self:_buildPoliceStation()
    self:_buildFireStation()
    self:_buildVIPZone()
    self:_buildCarDealership()
    self:_buildDecorations()
    self:_buildVehicleSpawns()
    self:_setupLighting()
    print("[ArabCity] Map built successfully!")
end

function MapBuilder:_buildTerrain()
    local terrain = makeModel(self._cityFolder, "Terrain")

    -- Main ground
    makePart(terrain, "Ground", Vector3.new(CITY_SIZE + 200, 1, CITY_SIZE + 200), Vector3.new(0, -0.5, 0), COL.DarkGrass, MAT.Grass)

    -- Extended ground for airport runway
    makePart(terrain, "AirportGround", Vector3.new(300, 1, 200), Vector3.new(-HALF - 100, -0.5, 0), COL.Grass, MAT.Grass)

    -- Beach sand strip (south)
    makePart(terrain, "BeachSand", Vector3.new(CITY_SIZE + 200, 0.8, 120), Vector3.new(0, -0.6, -HALF - 20), COL.Sand, MAT.Sand)

    -- Ocean (south of beach)
    makePart(terrain, "Ocean", Vector3.new(CITY_SIZE + 400, 8, 300), Vector3.new(0, -4, -HALF - 200), COL.Water, MAT.Water, { Transparency = 0.4, CanCollide = false })

    -- Kill brick under ocean
    local killPart = makePart(terrain, "KillBrick", Vector3.new(2000, 1, 2000), Vector3.new(0, -50, 0), COL.Black, MAT.Smooth, { Transparency = 1, CanCollide = false })
    killPart.Touched:Connect(function(hit)
        local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
        end
    end)
end

function MapBuilder:_buildRoads()
    local roads = makeModel(self._cityFolder, "Roads")

    -- Main road - North/South (center)
    makePart(roads, "MainRoad_NS", Vector3.new(ROAD_WIDTH, 0.3, CITY_SIZE), Vector3.new(0, 0.15, 0), COL.Road, MAT.Road)
    -- Center line
    makePart(roads, "CenterLine_NS", Vector3.new(0.4, 0.32, CITY_SIZE), Vector3.new(0, 0.16, 0), COL.RoadLine, MAT.Smooth)

    -- Main road - East/West (center)
    makePart(roads, "MainRoad_EW", Vector3.new(CITY_SIZE, 0.3, ROAD_WIDTH), Vector3.new(0, 0.15, 0), COL.Road, MAT.Road)
    makePart(roads, "CenterLine_EW", Vector3.new(CITY_SIZE, 0.32, 0.4), Vector3.new(0, 0.16, 0), COL.RoadLine, MAT.Smooth)

    -- Ring road (outer loop)
    local ringOff = HALF - 40
    makePart(roads, "Ring_N", Vector3.new(CITY_SIZE - 60, 0.3, ROAD_WIDTH), Vector3.new(0, 0.15, ringOff), COL.Road, MAT.Road)
    makePart(roads, "Ring_S", Vector3.new(CITY_SIZE - 60, 0.3, ROAD_WIDTH), Vector3.new(0, 0.15, -ringOff), COL.Road, MAT.Road)
    makePart(roads, "Ring_E", Vector3.new(ROAD_WIDTH, 0.3, CITY_SIZE - 60), Vector3.new(ringOff, 0.15, 0), COL.Road, MAT.Road)
    makePart(roads, "Ring_W", Vector3.new(ROAD_WIDTH, 0.3, CITY_SIZE - 60), Vector3.new(-ringOff, 0.15, 0), COL.Road, MAT.Road)

    -- Secondary roads (grid)
    for i = -1, 1, 2 do
        local off = BLOCK_SIZE * 1.5 * i
        makePart(roads, "SecRoad_NS_" .. i, Vector3.new(ROAD_WIDTH * 0.7, 0.3, CITY_SIZE * 0.6),
            Vector3.new(off, 0.15, 0), COL.Road, MAT.Road)
        makePart(roads, "SecRoad_EW_" .. i, Vector3.new(CITY_SIZE * 0.6, 0.3, ROAD_WIDTH * 0.7),
            Vector3.new(0, 0.15, off), COL.Road, MAT.Road)
    end

    -- Sidewalks along main roads
    for _, side in ipairs({ -1, 1 }) do
        makePart(roads, "Sidewalk_NS", Vector3.new(SIDEWALK_WIDTH, 0.4, CITY_SIZE),
            Vector3.new(side * (ROAD_WIDTH / 2 + SIDEWALK_WIDTH / 2), 0.2, 0), COL.Sidewalk, MAT.Sidewalk)
        makePart(roads, "Sidewalk_EW", Vector3.new(CITY_SIZE, 0.4, SIDEWALK_WIDTH),
            Vector3.new(0, 0.2, side * (ROAD_WIDTH / 2 + SIDEWALK_WIDTH / 2)), COL.Sidewalk, MAT.Sidewalk)
    end
end

function MapBuilder:_buildCentralPlaza()
    local plaza = makeModel(self._cityFolder, "CentralPlaza")

    -- Plaza floor
    makePart(plaza, "Floor", Vector3.new(50, 0.5, 50), Vector3.new(0, 0.25, 0), COL.Sidewalk, MAT.Marble)

    -- Decorative border
    makePart(plaza, "Border_N", Vector3.new(52, 0.8, 2), Vector3.new(0, 0.4, 26), COL.NeonCyan, MAT.Neon)
    makePart(plaza, "Border_S", Vector3.new(52, 0.8, 2), Vector3.new(0, 0.4, -26), COL.NeonCyan, MAT.Neon)
    makePart(plaza, "Border_E", Vector3.new(2, 0.8, 52), Vector3.new(26, 0.4, 0), COL.NeonCyan, MAT.Neon)
    makePart(plaza, "Border_W", Vector3.new(2, 0.8, 52), Vector3.new(-26, 0.4, 0), COL.NeonCyan, MAT.Neon)

    -- Fountain in center
    local fountain = makeModel(plaza, "Fountain")
    makePart(fountain, "Basin", Vector3.new(10, 2, 10), Vector3.new(0, 1, 0), COL.Sidewalk, MAT.Marble)
    makePart(fountain, "WaterPool", Vector3.new(8, 1.5, 8), Vector3.new(0, 1.25, 0), COL.Water, MAT.Water, { Transparency = 0.3 })
    makePart(fountain, "Pillar", Vector3.new(1.5, 6, 1.5), Vector3.new(0, 4, 0), COL.Sidewalk, MAT.Marble)
    local topBulb = makePart(fountain, "TopGlow", Vector3.new(2, 2, 2), Vector3.new(0, 7.5, 0), COL.NeonCyan, MAT.Neon, { Shape = Enum.PartType.Ball })
    addPointLight(topBulb, COL.NeonCyan, 3, 50)

    -- Arab City sign
    makePart(plaza, "SignPole", Vector3.new(1, 10, 1), Vector3.new(15, 5, 15), COL.WallDark, MAT.Metal)
    makePart(plaza, "SignBoard", Vector3.new(12, 4, 0.5), Vector3.new(15, 11, 15), COL.Black, MAT.Smooth)
    local neonSign = makePart(plaza, "NeonSign", Vector3.new(11, 3, 0.3), Vector3.new(15, 11, 15.4), COL.NeonCyan, MAT.Neon)
    addBillboard(neonSign, "🌃 ARAB CITY", COL.NeonCyan, Vector3.new(0, 3, 0))
    addPointLight(neonSign, COL.NeonCyan, 2, 35)

    -- SpawnLocation
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "MainSpawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.Position = Vector3.new(0, 0.5, -15)
    spawn.Anchored = true
    spawn.Material = Enum.Material.Neon
    spawn.Color = COL.NeonCyan
    spawn.Transparency = 0.5
    spawn.CanCollide = false
    spawn.Parent = plaza

    -- Benches around plaza
    for _, pos in ipairs({
        Vector3.new(18, 0, 0), Vector3.new(-18, 0, 0),
        Vector3.new(0, 0, 18), Vector3.new(0, 0, -18),
    }) do
        makePart(plaza, "Bench", Vector3.new(4, 1, 1.5), pos + Vector3.new(0, 0.7, 0), COL.WallDark, MAT.Wood)
        makePart(plaza, "BenchBack", Vector3.new(4, 1, 0.3), pos + Vector3.new(0, 1.5, -0.6), COL.WallDark, MAT.Wood)
    end
end

function MapBuilder:_buildResidentialDistrict()
    local district = makeModel(self._cityFolder, "Residential")

    local houses = {
        { id = "house_001", nameAr = "فيلا الشاطئ",       price = 50000,  rooms = 4, area = 250, cx = -60,  cz = 80,  color = Color3.fromRGB(220, 210, 195) },
        { id = "house_002", nameAr = "شقة وسط المدينة",   price = 20000,  rooms = 2, area = 100, cx = -60,  cz = 120, color = Color3.fromRGB(180, 190, 210) },
        { id = "house_003", nameAr = "قصر الحي الراقي",   price = 150000, rooms = 8, area = 600, cx = -60,  cz = 160, color = Color3.fromRGB(240, 235, 225) },
        { id = "house_004", nameAr = "بيت الضاحية",       price = 30000,  rooms = 3, area = 150, cx = -120, cz = 80,  color = Color3.fromRGB(195, 180, 165) },
        { id = "house_005", nameAr = "بنتهاوس فاخر",     price = 100000, rooms = 5, area = 350, cx = -120, cz = 120, color = Color3.fromRGB(200, 200, 215) },
        { id = "apartment_001", nameAr = "استوديو اقتصادي", price = 8000, rooms = 1, area = 50,  cx = -120, cz = 160, color = Color3.fromRGB(175, 185, 175) },
        { id = "mansion_001", nameAr = "قصر المارينا",    price = 250000, rooms = 10, area = 800, cx = -60, cz = 200, color = Color3.fromRGB(245, 240, 230) },
    }

    for _, h in ipairs(houses) do
        local houseModel = makeHouse(district, h.id, h.cx, h.cz, h.color)
        -- Property sign in front
        makePropertyMarker(houseModel, h.id, h.nameAr, h.price, h.rooms, h.area,
            Vector3.new(h.cx + 8, 0, h.cz + 10))
        -- Yard tree
        makeTree(houseModel, h.cx - 6, h.cz + 12, "normal")
    end

    -- District sign
    local signPost = makePart(district, "DistSign", Vector3.new(0.5, 8, 0.5), Vector3.new(-90, 4, 60), COL.WallDark, MAT.Metal)
    addBillboard(signPost, "🏘️ أحياء سكنية", COL.White, Vector3.new(0, 6, 0))
end

function MapBuilder:_buildCommercialDistrict()
    local district = makeModel(self._cityFolder, "Commercial")

    -- Mall (large building east)
    local mall = makeBuilding(district, "Mall", 120, 0, 60, 40, 25, COL.WallLight, COL.Roof, COL.Window, "🏬 المركز التجاري", COL.NeonCyan)

    -- Glass facade
    makePart(mall, "GlassFront", Vector3.new(58, 20, 0.5), Vector3.new(120, 12, 21), Color3.fromRGB(100, 170, 220), MAT.Glass, { Transparency = 0.4 })

    -- Neon entrance
    makePart(mall, "NeonEntrance", Vector3.new(10, 1, 0.3), Vector3.new(120, 22, 20.5), COL.NeonPink, MAT.Neon)

    -- Bank
    makeBuilding(district, "Bank", 120, 70, 30, 25, 20, Color3.fromRGB(50, 60, 80), COL.Roof, COL.Window, "🏦 البنك المركزي", COL.Gold)

    -- Bank vault door decoration
    makePart(district, "VaultDoor", Vector3.new(4, 6, 0.5), Vector3.new(120, 3, 82.8), COL.Gold, MAT.Metal)

    -- Shops along commercial strip
    local shopColors = {
        Color3.fromRGB(180, 60, 60),
        Color3.fromRGB(60, 120, 180),
        Color3.fromRGB(60, 160, 80),
        Color3.fromRGB(180, 140, 60),
    }
    local shopNames = { "ملابس عربية", "إلكترونيات", "مطعم الشرق", "مجوهرات" }
    for i = 1, 4 do
        local sz = 60 + (i - 1) * 25
        makeBuilding(district, "Shop_" .. i, 180, -80 + sz, 18, 14, 10, shopColors[i], COL.Roof, COL.Window, "🏪 " .. shopNames[i], COL.White)
    end
end

function MapBuilder:_buildBeach()
    local beach = makeModel(self._cityFolder, "Beach")

    -- Beach boardwalk
    makePart(beach, "Boardwalk", Vector3.new(200, 0.5, 6), Vector3.new(0, 0.25, -HALF + 40), Color3.fromRGB(150, 110, 60), MAT.Wood)

    -- Lifeguard tower
    local tower = makeModel(beach, "LifeguardTower")
    makePart(tower, "Legs1", Vector3.new(0.5, 6, 0.5), Vector3.new(-60, 3, -HALF + 20), COL.Red, MAT.Metal)
    makePart(tower, "Legs2", Vector3.new(0.5, 6, 0.5), Vector3.new(-56, 3, -HALF + 20), COL.Red, MAT.Metal)
    makePart(tower, "Legs3", Vector3.new(0.5, 6, 0.5), Vector3.new(-60, 3, -HALF + 16), COL.Red, MAT.Metal)
    makePart(tower, "Legs4", Vector3.new(0.5, 6, 0.5), Vector3.new(-56, 3, -HALF + 16), COL.Red, MAT.Metal)
    makePart(tower, "Platform", Vector3.new(6, 0.5, 6), Vector3.new(-58, 6.25, -HALF + 18), COL.Red, MAT.Smooth)
    makePart(tower, "Roof", Vector3.new(7, 0.3, 7), Vector3.new(-58, 9, -HALF + 18), COL.White, MAT.Smooth)

    -- Beach umbrellas
    for i = -3, 3, 2 do
        local ux = i * 30
        local uz = -HALF + 10
        makePart(beach, "UmbrellaPole", Vector3.new(0.3, 5, 0.3), Vector3.new(ux, 2.5, uz), COL.WallDark, MAT.Metal)
        makePart(beach, "UmbrellaTop", Vector3.new(6, 0.3, 6), Vector3.new(ux, 5, uz),
            (i % 4 == 0) and COL.Red or COL.Blue, MAT.Smooth)
    end

    -- Palm trees along beach
    for i = -4, 4, 2 do
        makeTree(beach, i * 40, -HALF + 35, "palm")
    end

    -- Beach sign
    local beachSign = makePart(beach, "BeachSign", Vector3.new(0.5, 6, 0.5), Vector3.new(0, 3, -HALF + 50), COL.WallDark, MAT.Metal)
    addBillboard(beachSign, "🏖️ شاطئ Arab City", COL.NeonCyan, Vector3.new(0, 5, 0))
end

function MapBuilder:_buildAirport()
    local airport = makeModel(self._cityFolder, "Airport")

    -- Terminal building
    makeBuilding(airport, "Terminal", -200, 0, 80, 30, 15, Color3.fromRGB(200, 210, 220), COL.Roof, COL.Window, "✈️ مطار Arab City الدولي", COL.Gold)

    -- Glass facade
    makePart(airport, "GlassFacade", Vector3.new(78, 12, 0.5), Vector3.new(-200, 8, 16), Color3.fromRGB(120, 180, 230), MAT.Glass, { Transparency = 0.35 })

    -- Control tower
    local ctower = makeModel(airport, "ControlTower")
    makePart(ctower, "TowerBase", Vector3.new(8, 30, 8), Vector3.new(-250, 15, 0), COL.WallLight, MAT.Concrete)
    makePart(ctower, "TowerTop", Vector3.new(12, 5, 12), Vector3.new(-250, 32.5, 0), COL.WallDark, MAT.Metal)
    makePart(ctower, "TowerGlass", Vector3.new(11, 4, 11), Vector3.new(-250, 32.5, 0), COL.Window, MAT.Glass, { Transparency = 0.3 })
    local beacon = makePart(ctower, "Beacon", Vector3.new(2, 2, 2), Vector3.new(-250, 36, 0), COL.Red, MAT.Neon, { Shape = Enum.PartType.Ball })
    addPointLight(beacon, COL.Red, 3, 60)

    -- Runway
    makePart(airport, "Runway", Vector3.new(300, 0.3, 30), Vector3.new(-250, 0.15, -50), COL.Road, MAT.Road)
    -- Runway markings
    for i = 0, 10 do
        makePart(airport, "RunwayMark", Vector3.new(8, 0.32, 1), Vector3.new(-380 + i * 26, 0.16, -50), COL.White, MAT.Smooth)
    end
    -- Runway edge lights
    for i = 0, 20 do
        local lx = -400 + i * 15
        makePart(airport, "RwyLight", Vector3.new(0.5, 0.5, 0.5), Vector3.new(lx, 0.5, -35), COL.NeonCyan, MAT.Neon)
        makePart(airport, "RwyLight", Vector3.new(0.5, 0.5, 0.5), Vector3.new(lx, 0.5, -65), COL.NeonCyan, MAT.Neon)
    end

    -- Taxiway
    makePart(airport, "Taxiway", Vector3.new(20, 0.3, 60), Vector3.new(-200, 0.15, -30), COL.Road, MAT.Road)

    -- Hangar
    makePart(airport, "Hangar", Vector3.new(40, 15, 30), Vector3.new(-160, 7.5, -60), Color3.fromRGB(160, 165, 175), MAT.Metal)
end

function MapBuilder:_buildHospital()
    local hospital = makeModel(self._cityFolder, "Hospital")

    local building = makeBuilding(hospital, "HospitalMain", 80, 150, 40, 30, 22, COL.HospWhite, COL.Roof, COL.Window, "🏥 مستشفى Arab City", Color3.fromRGB(255, 80, 80))

    -- Red cross on front
    makePart(building, "CrossH", Vector3.new(8, 2, 0.3), Vector3.new(80, 18, 165.2), COL.Red, MAT.Neon)
    makePart(building, "CrossV", Vector3.new(2, 8, 0.3), Vector3.new(80, 18, 165.2), COL.Red, MAT.Neon)

    -- Ambulance bay
    makePart(hospital, "AmbBay", Vector3.new(15, 4, 10), Vector3.new(60, 2, 165), Color3.fromRGB(180, 185, 190), MAT.Concrete, { Transparency = 0.5 })

    -- Parking
    makePart(hospital, "Parking", Vector3.new(25, 0.3, 20), Vector3.new(60, 0.15, 140), COL.Road, MAT.Road)
end

function MapBuilder:_buildPoliceStation()
    local station = makeModel(self._cityFolder, "PoliceStation")

    makeBuilding(station, "PoliceMain", 80, 220, 35, 25, 15, COL.PoliceBlue, COL.Roof, COL.Window, "🚔 مركز الشرطة", COL.Blue)

    -- Police sign with neon
    local neonBar = makePart(station, "NeonBar", Vector3.new(20, 1, 0.3), Vector3.new(80, 14, 232.7), COL.Blue, MAT.Neon)
    addPointLight(neonBar, COL.Blue, 2, 25)

    -- Parking
    makePart(station, "Parking", Vector3.new(20, 0.3, 15), Vector3.new(60, 0.15, 220), COL.Road, MAT.Road)
end

function MapBuilder:_buildFireStation()
    local station = makeModel(self._cityFolder, "FireStation")

    makeBuilding(station, "FireMain", -80, -120, 35, 25, 12, COL.Red, COL.Roof, COL.Window, "🚒 مركز الإطفاء", COL.Red)

    -- Garage door
    makePart(station, "GarageDoor", Vector3.new(10, 8, 0.5), Vector3.new(-80, 4, -107.3), Color3.fromRGB(180, 40, 40), MAT.Metal)

    -- Training tower
    makePart(station, "TrainTower", Vector3.new(6, 20, 6), Vector3.new(-100, 10, -120), COL.WallDark, MAT.Concrete)
end

function MapBuilder:_buildVIPZone()
    local vip = makeModel(self._cityFolder, "VIPZone")

    -- VIP platform
    makePart(vip, "VIPFloor", Vector3.new(60, 1, 60), Vector3.new(-150, 0.5, 150), COL.VIPGold, MAT.Marble)

    -- Golden fence
    for i = 0, 3 do
        local angle = i * math.pi / 2
        local dx = math.cos(angle)
        local dz = math.sin(angle)
        local isHorizontal = (i % 2 == 0)
        if isHorizontal then
            makePart(vip, "VIPFence", Vector3.new(62, 3, 0.5), Vector3.new(-150 + dz * 30, 2, 150 + dx * 30), COL.Gold, MAT.Metal)
        else
            makePart(vip, "VIPFence", Vector3.new(0.5, 3, 62), Vector3.new(-150 + dz * 30, 2, 150 + dx * 30), COL.Gold, MAT.Metal)
        end
    end

    -- VIP lounge building
    makeBuilding(vip, "VIPLounge", -150, 150, 30, 20, 10, Color3.fromRGB(30, 25, 40), COL.Roof, COL.Gold, "⭐ منطقة VIP", COL.Gold)

    -- Neon accents
    makePart(vip, "NeonFloor1", Vector3.new(60, 0.3, 2), Vector3.new(-150, 1.2, 130), COL.Gold, MAT.Neon)
    makePart(vip, "NeonFloor2", Vector3.new(60, 0.3, 2), Vector3.new(-150, 1.2, 170), COL.Gold, MAT.Neon)
    makePart(vip, "NeonFloor3", Vector3.new(2, 0.3, 60), Vector3.new(-180, 1.2, 150), COL.Gold, MAT.Neon)
    makePart(vip, "NeonFloor4", Vector3.new(2, 0.3, 60), Vector3.new(-120, 1.2, 150), COL.Gold, MAT.Neon)
end

function MapBuilder:_buildCarDealership()
    local dealer = makeModel(self._cityFolder, "CarDealership")

    -- Showroom
    local showroom = makeBuilding(dealer, "Showroom", 180, -120, 50, 35, 12, COL.WallLight, COL.Roof, COL.Window, "🚗 معرض السيارات", COL.NeonCyan)

    -- Glass walls (transparent showroom)
    makePart(showroom, "GlassWall_F", Vector3.new(48, 10, 0.5), Vector3.new(180, 6, -102.3), COL.Window, MAT.Glass, { Transparency = 0.4 })

    -- Display platforms for cars
    local carColors = { COL.Red, COL.Blue, Color3.fromRGB(240, 240, 240), COL.Gold }
    local carNames = { "سيدان", "كوبيه", "جيب", "سوبر كار" }
    for i = 1, 4 do
        local px = 160 + (i - 1) * 14
        makePart(dealer, "CarPlatform_" .. i, Vector3.new(10, 0.5, 8), Vector3.new(px, 0.75, -120), Color3.fromRGB(50, 50, 55), MAT.Marble)

        -- Simple car shape (body + wheels)
        local carModel = makeModel(dealer, "DisplayCar_" .. i)
        makePart(carModel, "CarBody", Vector3.new(4, 2, 8), Vector3.new(px, 2.5, -120), carColors[i], MAT.Smooth)
        makePart(carModel, "CarRoof", Vector3.new(3.5, 1.5, 4), Vector3.new(px, 4, -120), carColors[i], MAT.Smooth)
        -- Wheels
        for _, woff in ipairs({ Vector3.new(-2.2, 0, 2.5), Vector3.new(2.2, 0, 2.5), Vector3.new(-2.2, 0, -2.5), Vector3.new(2.2, 0, -2.5) }) do
            makePart(carModel, "Wheel", Vector3.new(0.5, 1.5, 1.5), Vector3.new(px + woff.X, 1 + woff.Y, -120 + woff.Z), COL.Black, MAT.Smooth, { Shape = Enum.PartType.Cylinder })
        end
        addBillboard(carModel:FindFirstChild("CarBody"), carNames[i], COL.White, Vector3.new(0, 4, 0))
    end
end

function MapBuilder:_buildDecorations()
    local decor = makeModel(self._cityFolder, "Decorations")

    -- Street lights along main roads
    for i = -6, 6, 2 do
        local z = i * 50
        if math.abs(z) > 30 then
            makeStreetLight(decor, ROAD_WIDTH / 2 + SIDEWALK_WIDTH + 1, z, COL.NeonCyan)
            makeStreetLight(decor, -(ROAD_WIDTH / 2 + SIDEWALK_WIDTH + 1), z, COL.NeonCyan)
        end
    end
    for i = -6, 6, 2 do
        local x = i * 50
        if math.abs(x) > 30 then
            makeStreetLight(decor, x, ROAD_WIDTH / 2 + SIDEWALK_WIDTH + 1, COL.NeonCyan)
            makeStreetLight(decor, x, -(ROAD_WIDTH / 2 + SIDEWALK_WIDTH + 1), COL.NeonCyan)
        end
    end

    -- Trees along sidewalks
    for i = -5, 5, 2 do
        local offset = i * 55
        if math.abs(offset) > 40 then
            makeTree(decor, ROAD_WIDTH / 2 + SIDEWALK_WIDTH + 4, offset, "normal")
            makeTree(decor, -(ROAD_WIDTH / 2 + SIDEWALK_WIDTH + 4), offset, "normal")
            makeTree(decor, offset, ROAD_WIDTH / 2 + SIDEWALK_WIDTH + 4, "normal")
            makeTree(decor, offset, -(ROAD_WIDTH / 2 + SIDEWALK_WIDTH + 4), "normal")
        end
    end

    -- Park area (between residential and center)
    local park = makeModel(decor, "CityPark")
    makePart(park, "ParkGround", Vector3.new(40, 0.2, 40), Vector3.new(-60, 0.1, 40), COL.Grass, MAT.Grass)
    for _, treePos in ipairs({
        Vector3.new(-50, 0, 30), Vector3.new(-70, 0, 30),
        Vector3.new(-50, 0, 50), Vector3.new(-70, 0, 50),
        Vector3.new(-60, 0, 40),
    }) do
        makeTree(park, treePos.X, treePos.Z, "normal")
    end
    makePart(park, "ParkBench1", Vector3.new(4, 1, 1.5), Vector3.new(-55, 0.7, 40), COL.WallDark, MAT.Wood)
    makePart(park, "ParkBench2", Vector3.new(4, 1, 1.5), Vector3.new(-65, 0.7, 40), COL.WallDark, MAT.Wood)
end

function MapBuilder:_buildVehicleSpawns()
    local spawns = makeModel(self._cityFolder, "VehicleSpawns")

    local spawnPoints = {
        { pos = Vector3.new(30, 0.3, -30),  name = "SpawnPad_Center1" },
        { pos = Vector3.new(-30, 0.3, -30), name = "SpawnPad_Center2" },
        { pos = Vector3.new(60, 0.3, 150),  name = "SpawnPad_Hospital" },
        { pos = Vector3.new(60, 0.3, 220),  name = "SpawnPad_Police" },
        { pos = Vector3.new(180, 0.3, -100), name = "SpawnPad_Dealer" },
        { pos = Vector3.new(-200, 0.3, 20), name = "SpawnPad_Airport" },
    }

    for _, sp in ipairs(spawnPoints) do
        local pad = makePart(spawns, sp.name, Vector3.new(8, 0.3, 12), sp.pos, Color3.fromRGB(50, 50, 55), MAT.Concrete)
        -- Neon border
        makePart(spawns, sp.name .. "_Border", Vector3.new(8.5, 0.35, 0.3), sp.pos + Vector3.new(0, 0, 6), COL.NeonCyan, MAT.Neon)
        makePart(spawns, sp.name .. "_Border", Vector3.new(8.5, 0.35, 0.3), sp.pos + Vector3.new(0, 0, -6), COL.NeonCyan, MAT.Neon)
        CollectionService:AddTag(pad, "VehicleSpawn")
    end
end

function MapBuilder:_setupLighting()
    -- Midnight blue atmosphere for Neon theme
    Lighting.ClockTime = 21 -- 9 PM (nighttime for neon feel)
    Lighting.GlobalShadows = true
    Lighting.Brightness = 0.8
    Lighting.OutdoorAmbient = Color3.fromRGB(50, 60, 80)
    Lighting.Ambient = Color3.fromRGB(30, 35, 50)
    Lighting.FogEnd = 2000
    Lighting.FogColor = Color3.fromRGB(10, 15, 30)

    -- Atmosphere
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = 0.35
    atmosphere.Offset = 0.2
    atmosphere.Color = Color3.fromRGB(20, 25, 50)
    atmosphere.Decay = Color3.fromRGB(10, 12, 30)
    atmosphere.Glare = 0.2
    atmosphere.Haze = 3

    -- Sky
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end
    sky.StarCount = 5000
    sky.MoonAngularSize = 14
    sky.SunAngularSize = 8

    -- Bloom for neon glow
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Parent = Lighting
    end
    bloom.Intensity = 0.8
    bloom.Size = 30
    bloom.Threshold = 0.7

    -- Color correction
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Parent = Lighting
    end
    cc.Brightness = 0.02
    cc.Contrast = 0.15
    cc.Saturation = 0.2
    cc.TintColor = Color3.fromRGB(220, 230, 255)

    -- Sun rays
    local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
    if not sunRays then
        sunRays = Instance.new("SunRaysEffect")
        sunRays.Parent = Lighting
    end
    sunRays.Intensity = 0.05
    sunRays.Spread = 0.5
end

return MapBuilder
