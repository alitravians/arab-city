--[[
    Arab City - Enhanced 3D Map Builder Service
    Generates professional 3D buildings with detailed architecture,
    furnished interiors, and interactive elements.

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
local CITY_SIZE = 800
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
    Granite   = Enum.Material.Granite,
    Fabric    = Enum.Material.Fabric,
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
    WallCream   = Color3.fromRGB(235, 225, 205),
    WallWhite   = Color3.fromRGB(245, 248, 250),
    WallBeige   = Color3.fromRGB(210, 195, 170),
    Roof        = Color3.fromRGB(50, 55, 65),
    RoofTile    = Color3.fromRGB(140, 60, 40),
    Window      = Color3.fromRGB(120, 180, 230),
    WindowFrame = Color3.fromRGB(80, 85, 90),
    NeonCyan    = Color3.fromRGB(0, 230, 255),
    NeonPink    = Color3.fromRGB(255, 0, 120),
    NeonBlue    = Color3.fromRGB(50, 100, 255),
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
    FloorWood   = Color3.fromRGB(160, 120, 80),
    FloorTile   = Color3.fromRGB(200, 200, 205),
    Carpet      = Color3.fromRGB(80, 40, 50),
    Sofa        = Color3.fromRGB(60, 80, 120),
    Table       = Color3.fromRGB(100, 70, 40),
    Counter     = Color3.fromRGB(180, 180, 185),
    Appliance   = Color3.fromRGB(220, 225, 230),
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

local function makeWedge(parent, name, size, pos, color, material, orientation)
    local w = Instance.new("WedgePart")
    w.Name = name
    w.Size = size
    w.Position = pos
    w.Anchored = true
    w.Color = color or COL.Roof
    w.Material = material or MAT.Concrete
    w.TopSurface = Enum.SurfaceType.Smooth
    w.BottomSurface = Enum.SurfaceType.Smooth
    if orientation then
        w.Orientation = orientation
    end
    w.Parent = parent
    return w
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

local function addSpotLight(parent, color, brightness, range, angle)
    local sl = Instance.new("SpotLight")
    sl.Color = color or COL.White
    sl.Brightness = brightness or 2
    sl.Range = range or 20
    sl.Angle = angle or 90
    sl.Face = Enum.NormalId.Bottom
    sl.Parent = parent
    return sl
end

local function makeStreetLight(parent, x, z, color)
    local pole = makePart(parent, "LightPole", Vector3.new(0.4, 12, 0.4), Vector3.new(x, 6, z), COL.WallDark, MAT.Metal)
    makePart(parent, "LightArm", Vector3.new(3, 0.3, 0.3), Vector3.new(x + 1.5, 11.5, z), COL.WallDark, MAT.Metal)
    local bulb = makePart(parent, "LightBulb", Vector3.new(1.2, 0.6, 1.2), Vector3.new(x + 3, 11.2, z), color or COL.NeonCyan, MAT.Neon)
    addPointLight(bulb, color or COL.NeonCyan, 1.5, 40)
    return pole
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

local function addProximityPrompt(parent, buildingType, actionText)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = actionText or "دخول"
    prompt.ObjectText = buildingType or ""
    prompt.MaxActivationDistance = 10
    prompt.HoldDuration = 0.3
    prompt.RequiresLineOfSight = false
    prompt.Parent = parent
    CollectionService:AddTag(parent, "InteractiveBuilding")
    parent:SetAttribute("BuildingType", buildingType)
    return prompt
end

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

    addBillboard(marker, nameAr .. "\n" .. tostring(price) .. "$", COL.Gold, Vector3.new(0, 4, 0))

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "شراء"
    prompt.ObjectText = nameAr
    prompt.MaxActivationDistance = 12
    prompt.HoldDuration = 0.5
    prompt.RequiresLineOfSight = false
    prompt.Parent = marker
    return marker
end

----------------------------------------------------------------------------
-- 3D Building Generators (Enhanced Architecture)
----------------------------------------------------------------------------

-- Creates a detailed multi-story building with proper architecture
local function makeBuilding3D(parent, name, cx, cz, w, d, floors, style, labelText, labelColor, buildingType)
    local model = makeModel(parent, name)
    local floorH = 5
    local totalH = floors * floorH
    local wallColor = style.wall or COL.WallLight
    local trimColor = style.trim or COL.WallDark
    local accentColor = style.accent or COL.NeonCyan
    local roofStyle = style.roof or "flat"

    -- Foundation / base
    makePart(model, "Foundation", Vector3.new(w + 2, 1, d + 2), Vector3.new(cx, 0.5, cz), Color3.fromRGB(100, 100, 105), MAT.Granite)

    -- Build each floor
    for floor = 1, floors do
        local baseY = (floor - 1) * floorH + 1
        local floorModel = makeModel(model, "Floor_" .. floor)

        -- Floor plate
        makePart(floorModel, "FloorPlate", Vector3.new(w, 0.4, d), Vector3.new(cx, baseY, cz), COL.FloorTile, MAT.Concrete)

        -- Walls (front, back, left, right)
        makePart(floorModel, "WallFront", Vector3.new(w, floorH, 0.5), Vector3.new(cx, baseY + floorH / 2, cz + d / 2), wallColor, MAT.Concrete)
        makePart(floorModel, "WallBack", Vector3.new(w, floorH, 0.5), Vector3.new(cx, baseY + floorH / 2, cz - d / 2), wallColor, MAT.Concrete)
        makePart(floorModel, "WallLeft", Vector3.new(0.5, floorH, d), Vector3.new(cx - w / 2, baseY + floorH / 2, cz), wallColor, MAT.Concrete)
        makePart(floorModel, "WallRight", Vector3.new(0.5, floorH, d), Vector3.new(cx + w / 2, baseY + floorH / 2, cz), wallColor, MAT.Concrete)

        -- Floor trim / ledge between floors
        if floor > 1 then
            makePart(floorModel, "Ledge", Vector3.new(w + 1, 0.4, d + 1), Vector3.new(cx, baseY + 0.2, cz), trimColor, MAT.Concrete)
        end

        -- Windows with frames (front and back)
        local winCols = math.max(2, math.floor(w / 8))
        for col = 1, winCols do
            local wx = cx + (col - (winCols + 1) / 2) * (w / (winCols + 1))
            local wy = baseY + floorH / 2

            -- Front window
            makePart(floorModel, "WinFrame_F", Vector3.new(2.4, 3.2, 0.2), Vector3.new(wx, wy, cz + d / 2 + 0.2), COL.WindowFrame, MAT.Metal)
            makePart(floorModel, "Window_F", Vector3.new(2, 2.8, 0.15), Vector3.new(wx, wy, cz + d / 2 + 0.3), COL.Window, MAT.Glass, { Transparency = 0.3 })

            -- Back window
            makePart(floorModel, "WinFrame_B", Vector3.new(2.4, 3.2, 0.2), Vector3.new(wx, wy, cz - d / 2 - 0.2), COL.WindowFrame, MAT.Metal)
            makePart(floorModel, "Window_B", Vector3.new(2, 2.8, 0.15), Vector3.new(wx, wy, cz - d / 2 - 0.3), COL.Window, MAT.Glass, { Transparency = 0.3 })
        end

        -- Side windows
        local sideCols = math.max(1, math.floor(d / 10))
        for col = 1, sideCols do
            local wz = cz + (col - (sideCols + 1) / 2) * (d / (sideCols + 1))
            local wy = baseY + floorH / 2
            makePart(floorModel, "Win_L", Vector3.new(0.15, 2.5, 1.8), Vector3.new(cx - w / 2 - 0.2, wy, wz), COL.Window, MAT.Glass, { Transparency = 0.3 })
            makePart(floorModel, "Win_R", Vector3.new(0.15, 2.5, 1.8), Vector3.new(cx + w / 2 + 0.2, wy, wz), COL.Window, MAT.Glass, { Transparency = 0.3 })
        end

        -- Balconies (floors 2+, front only)
        if floor >= 2 and style.balcony then
            for col = 1, math.min(winCols, 3) do
                local bx = cx + (col - (math.min(winCols, 3) + 1) / 2) * (w / (winCols + 1))
                makePart(floorModel, "BalconyFloor", Vector3.new(3.5, 0.3, 2), Vector3.new(bx, baseY + 0.15, cz + d / 2 + 1.2), trimColor, MAT.Concrete)
                makePart(floorModel, "BalconyRail_F", Vector3.new(3.5, 1.2, 0.15), Vector3.new(bx, baseY + 0.75, cz + d / 2 + 2.1), trimColor, MAT.Metal)
                makePart(floorModel, "BalconyRail_L", Vector3.new(0.15, 1.2, 2), Vector3.new(bx - 1.7, baseY + 0.75, cz + d / 2 + 1.2), trimColor, MAT.Metal)
                makePart(floorModel, "BalconyRail_R", Vector3.new(0.15, 1.2, 2), Vector3.new(bx + 1.7, baseY + 0.75, cz + d / 2 + 1.2), trimColor, MAT.Metal)
            end
        end
    end

    -- Roof
    local roofY = totalH + 1
    if roofStyle == "flat" then
        makePart(model, "RoofFlat", Vector3.new(w + 2, 0.6, d + 2), Vector3.new(cx, roofY + 0.3, cz), COL.Roof, MAT.Concrete)
        -- AC units on roof
        makePart(model, "AC_1", Vector3.new(3, 2, 2), Vector3.new(cx - w / 4, roofY + 1.6, cz), COL.Counter, MAT.Metal)
        makePart(model, "AC_2", Vector3.new(3, 2, 2), Vector3.new(cx + w / 4, roofY + 1.6, cz), COL.Counter, MAT.Metal)
    elseif roofStyle == "sloped" then
        makePart(model, "RoofBase", Vector3.new(w + 2, 0.4, d + 2), Vector3.new(cx, roofY + 0.2, cz), COL.Roof, MAT.Concrete)
        makeWedge(model, "RoofSlope_F", Vector3.new(w + 2, 4, d / 2 + 1), Vector3.new(cx, roofY + 2.2, cz + d / 4 + 0.5), COL.RoofTile, MAT.Concrete, Vector3.new(0, 0, 0))
        makeWedge(model, "RoofSlope_B", Vector3.new(w + 2, 4, d / 2 + 1), Vector3.new(cx, roofY + 2.2, cz - d / 4 - 0.5), COL.RoofTile, MAT.Concrete, Vector3.new(0, 180, 0))
    elseif roofStyle == "parapet" then
        makePart(model, "RoofFlat", Vector3.new(w, 0.5, d), Vector3.new(cx, roofY + 0.25, cz), COL.Roof, MAT.Concrete)
        makePart(model, "Parapet_F", Vector3.new(w + 1, 2, 0.4), Vector3.new(cx, roofY + 1.5, cz + d / 2), trimColor, MAT.Concrete)
        makePart(model, "Parapet_B", Vector3.new(w + 1, 2, 0.4), Vector3.new(cx, roofY + 1.5, cz - d / 2), trimColor, MAT.Concrete)
        makePart(model, "Parapet_L", Vector3.new(0.4, 2, d + 1), Vector3.new(cx - w / 2, roofY + 1.5, cz), trimColor, MAT.Concrete)
        makePart(model, "Parapet_R", Vector3.new(0.4, 2, d + 1), Vector3.new(cx + w / 2, roofY + 1.5, cz), trimColor, MAT.Concrete)
    end

    -- Entrance (ground floor front)
    local entranceY = 1.5 + floorH / 2
    -- Door
    local door = makePart(model, "Door", Vector3.new(3, 4.5, 0.4), Vector3.new(cx, 3.25, cz + d / 2 + 0.5), COL.WallDark, MAT.Metal)
    if buildingType then
        addProximityPrompt(door, buildingType, "دخول")
    end
    -- Entrance canopy
    makePart(model, "Canopy", Vector3.new(6, 0.3, 3), Vector3.new(cx, floorH + 0.85, cz + d / 2 + 1.5), trimColor, MAT.Metal)
    -- Entrance columns
    makePart(model, "Col_L", Vector3.new(0.6, floorH, 0.6), Vector3.new(cx - 2.5, floorH / 2 + 1, cz + d / 2 + 1.5), trimColor, MAT.Concrete)
    makePart(model, "Col_R", Vector3.new(0.6, floorH, 0.6), Vector3.new(cx + 2.5, floorH / 2 + 1, cz + d / 2 + 1.5), trimColor, MAT.Concrete)

    -- Neon accent strip
    if style.neon ~= false then
        local neonStrip = makePart(model, "NeonAccent", Vector3.new(w, 0.3, 0.2), Vector3.new(cx, roofY - 0.5, cz + d / 2 + 0.4), accentColor, MAT.Neon)
        addPointLight(neonStrip, accentColor, 1, 20)
    end

    -- Label
    if labelText then
        local signBoard = makePart(model, "SignBoard", Vector3.new(math.min(w - 2, 12), 2.5, 0.3), Vector3.new(cx, totalH - 1, cz + d / 2 + 0.6), COL.Black, MAT.Smooth)
        addBillboard(signBoard, labelText, labelColor or COL.White, Vector3.new(0, 3, 0))
    end

    return model
end

-- Detailed residential house with rooms and furniture
local function makeHouse3D(parent, name, cx, cz, houseStyle)
    local model = makeModel(parent, name)
    local wallColor = houseStyle.wall or COL.WallCream
    local roofColor = houseStyle.roof or COL.RoofTile
    local floors = houseStyle.floors or 1
    local w = houseStyle.width or 16
    local d = houseStyle.depth or 14
    local floorH = 5

    -- Foundation
    makePart(model, "Foundation", Vector3.new(w + 2, 0.8, d + 2), Vector3.new(cx, 0.4, cz), Color3.fromRGB(100, 95, 90), MAT.Concrete)

    for floor = 1, floors do
        local baseY = (floor - 1) * floorH + 0.8
        local floorModel = makeModel(model, "Floor_" .. floor)

        -- Floor
        makePart(floorModel, "Floor", Vector3.new(w, 0.3, d), Vector3.new(cx, baseY + 0.15, cz), COL.FloorWood, MAT.Wood)

        -- Exterior walls with window openings
        -- Front wall (with door on ground floor)
        makePart(floorModel, "WF_L", Vector3.new(w / 2 - 2, floorH, 0.4), Vector3.new(cx - w / 4 - 1, baseY + floorH / 2, cz + d / 2), wallColor, MAT.Concrete)
        makePart(floorModel, "WF_R", Vector3.new(w / 2 - 2, floorH, 0.4), Vector3.new(cx + w / 4 + 1, baseY + floorH / 2, cz + d / 2), wallColor, MAT.Concrete)
        makePart(floorModel, "WF_Top", Vector3.new(4, floorH - 4, 0.4), Vector3.new(cx, baseY + floorH - (floorH - 4) / 2, cz + d / 2), wallColor, MAT.Concrete)

        -- Back, Left, Right walls
        makePart(floorModel, "WallBack", Vector3.new(w, floorH, 0.4), Vector3.new(cx, baseY + floorH / 2, cz - d / 2), wallColor, MAT.Concrete)
        makePart(floorModel, "WallLeft", Vector3.new(0.4, floorH, d), Vector3.new(cx - w / 2, baseY + floorH / 2, cz), wallColor, MAT.Concrete)
        makePart(floorModel, "WallRight", Vector3.new(0.4, floorH, d), Vector3.new(cx + w / 2, baseY + floorH / 2, cz), wallColor, MAT.Concrete)

        -- Windows with shutters
        for _, wpos in ipairs({
            Vector3.new(cx - w / 4 - 1, baseY + 2.8, cz + d / 2 + 0.3),
            Vector3.new(cx + w / 4 + 1, baseY + 2.8, cz + d / 2 + 0.3),
            Vector3.new(cx, baseY + 2.8, cz - d / 2 - 0.3),
        }) do
            makePart(floorModel, "WinFrame", Vector3.new(2.4, 2.8, 0.1), wpos, COL.WindowFrame, MAT.Metal)
            makePart(floorModel, "Window", Vector3.new(2, 2.4, 0.08), wpos + Vector3.new(0, 0, 0.05), COL.Window, MAT.Glass, { Transparency = 0.3 })
            -- Shutters
            makePart(floorModel, "Shutter_L", Vector3.new(0.15, 2.8, 1.2), Vector3.new(wpos.X - 1.3, wpos.Y, wpos.Z), wallColor, MAT.Wood)
            makePart(floorModel, "Shutter_R", Vector3.new(0.15, 2.8, 1.2), Vector3.new(wpos.X + 1.3, wpos.Y, wpos.Z), wallColor, MAT.Wood)
        end

        -- Interior walls (dividing rooms)
        if floor == 1 then
            -- Divider: living room | kitchen
            makePart(floorModel, "IntWall_1", Vector3.new(0.3, floorH, d / 2 - 1), Vector3.new(cx, baseY + floorH / 2, cz + d / 4), COL.WallWhite, MAT.Smooth)
            -- Divider: bedroom area
            makePart(floorModel, "IntWall_2", Vector3.new(w / 2 - 2, floorH, 0.3), Vector3.new(cx + w / 4, baseY + floorH / 2, cz), COL.WallWhite, MAT.Smooth)
        end

        -- Furniture
        if floor == 1 then
            -- Living room (front-left quadrant)
            makePart(floorModel, "Sofa", Vector3.new(4.5, 1.2, 1.8), Vector3.new(cx - w / 4, baseY + 0.9, cz + d / 4 + 2), COL.Sofa, MAT.Fabric)
            makePart(floorModel, "SofaBack", Vector3.new(4.5, 0.8, 0.4), Vector3.new(cx - w / 4, baseY + 1.6, cz + d / 4 + 2.9), COL.Sofa, MAT.Fabric)
            makePart(floorModel, "CoffeeTable", Vector3.new(2.5, 0.6, 1.5), Vector3.new(cx - w / 4, baseY + 0.6, cz + d / 4), COL.Table, MAT.Wood)
            makePart(floorModel, "TV", Vector3.new(3.5, 2.2, 0.2), Vector3.new(cx - w / 4, baseY + 2.4, cz - 0.1), COL.Black, MAT.Smooth)
            makePart(floorModel, "TVStand", Vector3.new(4, 0.8, 1.2), Vector3.new(cx - w / 4, baseY + 0.7, cz - 0.1), COL.Table, MAT.Wood)
            -- Rug
            makePart(floorModel, "Rug", Vector3.new(5, 0.05, 3.5), Vector3.new(cx - w / 4, baseY + 0.33, cz + d / 4 + 1), COL.Carpet, MAT.Fabric)

            -- Kitchen (front-right quadrant)
            makePart(floorModel, "Counter", Vector3.new(5, 1.5, 1.2), Vector3.new(cx + w / 4, baseY + 1.05, cz + d / 4 + 2.5), COL.Counter, MAT.Granite)
            makePart(floorModel, "Stove", Vector3.new(1.5, 1.5, 1.2), Vector3.new(cx + w / 4 + 2.5, baseY + 1.05, cz + d / 4 + 2.5), COL.Black, MAT.Metal)
            makePart(floorModel, "Fridge", Vector3.new(1.5, 3.5, 1.2), Vector3.new(cx + w / 4 + 2.5, baseY + 2.05, cz + d / 4 - 1), COL.Appliance, MAT.Metal)
            makePart(floorModel, "DiningTable", Vector3.new(3, 1.2, 2), Vector3.new(cx + w / 4 - 1, baseY + 0.9, cz + d / 4 - 1), COL.Table, MAT.Wood)
            -- Chairs around dining table
            for _, cOff in ipairs({Vector3.new(-1.5, 0, 0), Vector3.new(1.5, 0, 0), Vector3.new(0, 0, -1.2), Vector3.new(0, 0, 1.2)}) do
                makePart(floorModel, "Chair", Vector3.new(0.8, 1, 0.8), Vector3.new(cx + w / 4 - 1 + cOff.X, baseY + 0.8, cz + d / 4 - 1 + cOff.Z), COL.Table, MAT.Wood)
            end

            -- Bedroom (back-right)
            makePart(floorModel, "Bed", Vector3.new(3.5, 0.8, 5), Vector3.new(cx + w / 4, baseY + 0.7, cz - d / 4), COL.White, MAT.Fabric)
            makePart(floorModel, "BedFrame", Vector3.new(3.7, 0.5, 5.2), Vector3.new(cx + w / 4, baseY + 0.55, cz - d / 4), COL.Table, MAT.Wood)
            makePart(floorModel, "Pillow", Vector3.new(2.5, 0.4, 1), Vector3.new(cx + w / 4, baseY + 1, cz - d / 4 + 2), COL.White, MAT.Fabric)
            makePart(floorModel, "Nightstand", Vector3.new(1, 1, 1), Vector3.new(cx + w / 4 + 2.5, baseY + 0.8, cz - d / 4 + 2), COL.Table, MAT.Wood)
            makePart(floorModel, "Lamp", Vector3.new(0.4, 1.2, 0.4), Vector3.new(cx + w / 4 + 2.5, baseY + 1.9, cz - d / 4 + 2), COL.Gold, MAT.Smooth)
            makePart(floorModel, "Wardrobe", Vector3.new(3, 4, 1), Vector3.new(cx + w / 4, baseY + 2.3, cz - d / 2 + 0.8), COL.Table, MAT.Wood)

            -- Bathroom (back-left corner)
            makePart(floorModel, "Bathtub", Vector3.new(1.5, 1, 3), Vector3.new(cx - w / 4 - 2, baseY + 0.8, cz - d / 4), COL.White, MAT.Smooth)
            makePart(floorModel, "Sink", Vector3.new(1, 1.2, 0.8), Vector3.new(cx - w / 4, baseY + 0.9, cz - d / 2 + 0.7), COL.White, MAT.Smooth)
        end

        -- Ceiling
        makePart(floorModel, "Ceiling", Vector3.new(w, 0.3, d), Vector3.new(cx, baseY + floorH, cz), COL.WallWhite, MAT.Smooth)
    end

    -- Roof (sloped tile)
    local roofY = floors * floorH + 0.8
    makeWedge(model, "Roof_F", Vector3.new(w + 2, 3, d / 2 + 1), Vector3.new(cx, roofY + 1.5, cz + d / 4 + 0.5), roofColor, MAT.Concrete, Vector3.new(0, 0, 0))
    makeWedge(model, "Roof_B", Vector3.new(w + 2, 3, d / 2 + 1), Vector3.new(cx, roofY + 1.5, cz - d / 4 - 0.5), roofColor, MAT.Concrete, Vector3.new(0, 180, 0))

    -- Front door
    local door = makePart(model, "Door", Vector3.new(2.5, 4, 0.3), Vector3.new(cx, 2.8, cz + d / 2 + 0.5), Color3.fromRGB(80, 50, 30), MAT.Wood)
    addProximityPrompt(door, "Property", "معلومات")

    -- Front porch
    makePart(model, "Porch", Vector3.new(6, 0.3, 3), Vector3.new(cx, 0.95, cz + d / 2 + 1.5), COL.FloorWood, MAT.Wood)
    -- Porch pillars
    makePart(model, "PorchPillar_L", Vector3.new(0.4, 3.5, 0.4), Vector3.new(cx - 2.8, 2.75, cz + d / 2 + 2.8), wallColor, MAT.Concrete)
    makePart(model, "PorchPillar_R", Vector3.new(0.4, 3.5, 0.4), Vector3.new(cx + 2.8, 2.75, cz + d / 2 + 2.8), wallColor, MAT.Concrete)
    makePart(model, "PorchRoof", Vector3.new(7, 0.3, 3.5), Vector3.new(cx, 4.6, cz + d / 2 + 1.5), wallColor, MAT.Concrete)

    -- Yard fence
    local yardD = 8
    makePart(model, "Fence_F", Vector3.new(w + 4, 1.5, 0.2), Vector3.new(cx, 0.75, cz + d / 2 + yardD), COL.WallDark, MAT.Metal)
    makePart(model, "Fence_L", Vector3.new(0.2, 1.5, yardD), Vector3.new(cx - w / 2 - 2, 0.75, cz + d / 2 + yardD / 2), COL.WallDark, MAT.Metal)
    makePart(model, "Fence_R", Vector3.new(0.2, 1.5, yardD), Vector3.new(cx + w / 2 + 2, 0.75, cz + d / 2 + yardD / 2), COL.WallDark, MAT.Metal)

    -- Yard with grass
    makePart(model, "YardGrass", Vector3.new(w + 3, 0.15, yardD - 1), Vector3.new(cx, 0.08, cz + d / 2 + yardD / 2), COL.Grass, MAT.Grass)

    -- Ceiling light inside
    local ceilingLight = makePart(model, "CeilingLight", Vector3.new(1, 0.3, 1), Vector3.new(cx, floors * floorH + 0.5, cz), COL.White, MAT.Neon)
    addPointLight(ceilingLight, COL.White, 1, 15)

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
    makePart(terrain, "Ground", Vector3.new(CITY_SIZE + 200, 1, CITY_SIZE + 200), Vector3.new(0, -0.5, 0), COL.DarkGrass, MAT.Grass)
    makePart(terrain, "AirportGround", Vector3.new(300, 1, 200), Vector3.new(-HALF - 100, -0.5, 0), COL.Grass, MAT.Grass)
    makePart(terrain, "BeachSand", Vector3.new(CITY_SIZE + 200, 0.8, 120), Vector3.new(0, -0.6, -HALF - 20), COL.Sand, MAT.Sand)
    makePart(terrain, "Ocean", Vector3.new(CITY_SIZE + 400, 8, 300), Vector3.new(0, -4, -HALF - 200), COL.Water, MAT.Water, { Transparency = 0.4, CanCollide = false })

    local killPart = makePart(terrain, "KillBrick", Vector3.new(2000, 1, 2000), Vector3.new(0, -50, 0), COL.Black, MAT.Smooth, { Transparency = 1, CanCollide = false })
    killPart.Touched:Connect(function(hit)
        local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end)
end

function MapBuilder:_buildRoads()
    local roads = makeModel(self._cityFolder, "Roads")

    -- Main roads N/S and E/W
    makePart(roads, "MainRoad_NS", Vector3.new(ROAD_WIDTH, 0.3, CITY_SIZE), Vector3.new(0, 0.15, 0), COL.Road, MAT.Road)
    makePart(roads, "CenterLine_NS", Vector3.new(0.4, 0.32, CITY_SIZE), Vector3.new(0, 0.16, 0), COL.RoadLine, MAT.Smooth)
    makePart(roads, "MainRoad_EW", Vector3.new(CITY_SIZE, 0.3, ROAD_WIDTH), Vector3.new(0, 0.15, 0), COL.Road, MAT.Road)
    makePart(roads, "CenterLine_EW", Vector3.new(CITY_SIZE, 0.32, 0.4), Vector3.new(0, 0.16, 0), COL.RoadLine, MAT.Smooth)

    -- Ring road
    local ringOff = HALF - 40
    makePart(roads, "Ring_N", Vector3.new(CITY_SIZE - 60, 0.3, ROAD_WIDTH), Vector3.new(0, 0.15, ringOff), COL.Road, MAT.Road)
    makePart(roads, "Ring_S", Vector3.new(CITY_SIZE - 60, 0.3, ROAD_WIDTH), Vector3.new(0, 0.15, -ringOff), COL.Road, MAT.Road)
    makePart(roads, "Ring_E", Vector3.new(ROAD_WIDTH, 0.3, CITY_SIZE - 60), Vector3.new(ringOff, 0.15, 0), COL.Road, MAT.Road)
    makePart(roads, "Ring_W", Vector3.new(ROAD_WIDTH, 0.3, CITY_SIZE - 60), Vector3.new(-ringOff, 0.15, 0), COL.Road, MAT.Road)

    -- Secondary roads
    for i = -1, 1, 2 do
        local off = BLOCK_SIZE * 1.5 * i
        makePart(roads, "SecRoad_NS_" .. i, Vector3.new(ROAD_WIDTH * 0.7, 0.3, CITY_SIZE * 0.6), Vector3.new(off, 0.15, 0), COL.Road, MAT.Road)
        makePart(roads, "SecRoad_EW_" .. i, Vector3.new(CITY_SIZE * 0.6, 0.3, ROAD_WIDTH * 0.7), Vector3.new(0, 0.15, off), COL.Road, MAT.Road)
    end

    -- Sidewalks
    for _, side in ipairs({ -1, 1 }) do
        makePart(roads, "Sidewalk_NS", Vector3.new(SIDEWALK_WIDTH, 0.4, CITY_SIZE), Vector3.new(side * (ROAD_WIDTH / 2 + SIDEWALK_WIDTH / 2), 0.2, 0), COL.Sidewalk, MAT.Sidewalk)
        makePart(roads, "Sidewalk_EW", Vector3.new(CITY_SIZE, 0.4, SIDEWALK_WIDTH), Vector3.new(0, 0.2, side * (ROAD_WIDTH / 2 + SIDEWALK_WIDTH / 2)), COL.Sidewalk, MAT.Sidewalk)
    end
end

function MapBuilder:_buildCentralPlaza()
    local plaza = makeModel(self._cityFolder, "CentralPlaza")

    -- Main plaza with decorative pattern
    makePart(plaza, "FloorOuter", Vector3.new(55, 0.5, 55), Vector3.new(0, 0.25, 0), COL.Sidewalk, MAT.Marble)
    makePart(plaza, "FloorInner", Vector3.new(35, 0.52, 35), Vector3.new(0, 0.26, 0), Color3.fromRGB(180, 170, 150), MAT.Marble)
    makePart(plaza, "FloorCenter", Vector3.new(15, 0.54, 15), Vector3.new(0, 0.27, 0), Color3.fromRGB(160, 150, 130), MAT.Marble)

    -- Neon border
    for _, data in ipairs({
        {Vector3.new(56, 0.6, 1), Vector3.new(0, 0.3, 28)},
        {Vector3.new(56, 0.6, 1), Vector3.new(0, 0.3, -28)},
        {Vector3.new(1, 0.6, 56), Vector3.new(28, 0.3, 0)},
        {Vector3.new(1, 0.6, 56), Vector3.new(-28, 0.3, 0)},
    }) do
        makePart(plaza, "NeonBorder", data[1], data[2], COL.NeonCyan, MAT.Neon)
    end

    -- Grand fountain
    local fountain = makeModel(plaza, "Fountain")
    makePart(fountain, "BasinOuter", Vector3.new(12, 1.5, 12), Vector3.new(0, 0.75, 0), Color3.fromRGB(180, 175, 170), MAT.Marble)
    makePart(fountain, "BasinInner", Vector3.new(10, 2, 10), Vector3.new(0, 1, 0), Color3.fromRGB(160, 155, 150), MAT.Marble)
    makePart(fountain, "Water", Vector3.new(9, 1.2, 9), Vector3.new(0, 1, 0), COL.Water, MAT.Water, { Transparency = 0.3 })
    makePart(fountain, "Pillar", Vector3.new(1.2, 7, 1.2), Vector3.new(0, 4.5, 0), COL.WallWhite, MAT.Marble)
    local topOrb = makePart(fountain, "TopOrb", Vector3.new(2.5, 2.5, 2.5), Vector3.new(0, 8.5, 0), COL.NeonCyan, MAT.Neon, { Shape = Enum.PartType.Ball })
    addPointLight(topOrb, COL.NeonCyan, 3, 50)

    -- City monument sign
    local signModel = makeModel(plaza, "CitySign")
    makePart(signModel, "SignPole_L", Vector3.new(0.5, 8, 0.5), Vector3.new(-5, 4, 18), COL.WallDark, MAT.Metal)
    makePart(signModel, "SignPole_R", Vector3.new(0.5, 8, 0.5), Vector3.new(5, 4, 18), COL.WallDark, MAT.Metal)
    makePart(signModel, "SignBoard", Vector3.new(11, 4, 0.5), Vector3.new(0, 9, 18), COL.Black, MAT.Smooth)
    local neonSign = makePart(signModel, "NeonText", Vector3.new(10, 3, 0.2), Vector3.new(0, 9, 18.4), COL.NeonCyan, MAT.Neon)
    addBillboard(neonSign, "ARAB CITY", COL.NeonCyan, Vector3.new(0, 3, 0))
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

    -- Benches with armrests
    for _, pos in ipairs({
        Vector3.new(18, 0, 0), Vector3.new(-18, 0, 0),
        Vector3.new(0, 0, 18), Vector3.new(0, 0, -20),
        Vector3.new(12, 0, 12), Vector3.new(-12, 0, 12),
    }) do
        local bench = makeModel(plaza, "Bench")
        makePart(bench, "Seat", Vector3.new(4, 0.4, 1.5), pos + Vector3.new(0, 0.9, 0), COL.WallDark, MAT.Wood)
        makePart(bench, "Back", Vector3.new(4, 1.2, 0.3), pos + Vector3.new(0, 1.7, -0.6), COL.WallDark, MAT.Wood)
        makePart(bench, "Leg_L", Vector3.new(0.3, 0.9, 1.5), pos + Vector3.new(-1.8, 0.45, 0), COL.Black, MAT.Metal)
        makePart(bench, "Leg_R", Vector3.new(0.3, 0.9, 1.5), pos + Vector3.new(1.8, 0.45, 0), COL.Black, MAT.Metal)
    end
end

function MapBuilder:_buildResidentialDistrict()
    local district = makeModel(self._cityFolder, "Residential")

    local houses = {
        { id = "house_001", nameAr = "فيلا الشاطئ", price = 50000, rooms = 4, area = 250, cx = -60, cz = 80, style = { wall = COL.WallCream, roof = COL.RoofTile, floors = 2, width = 18, depth = 16 } },
        { id = "house_002", nameAr = "شقة وسط المدينة", price = 20000, rooms = 2, area = 100, cx = -60, cz = 130, style = { wall = Color3.fromRGB(190, 200, 215), roof = COL.Roof, floors = 1, width = 14, depth = 12 } },
        { id = "house_003", nameAr = "قصر الحي الراقي", price = 150000, rooms = 8, area = 600, cx = -60, cz = 190, style = { wall = Color3.fromRGB(245, 240, 230), roof = COL.RoofTile, floors = 2, width = 22, depth = 18 } },
        { id = "house_004", nameAr = "بيت الضاحية", price = 30000, rooms = 3, area = 150, cx = -130, cz = 80, style = { wall = Color3.fromRGB(200, 190, 175), roof = COL.RoofTile, floors = 1, width = 16, depth = 14 } },
        { id = "house_005", nameAr = "بنتهاوس فاخر", price = 100000, rooms = 5, area = 350, cx = -130, cz = 130, style = { wall = Color3.fromRGB(210, 215, 225), roof = COL.Roof, floors = 2, width = 18, depth = 16 } },
        { id = "apartment_001", nameAr = "استوديو اقتصادي", price = 8000, rooms = 1, area = 50, cx = -130, cz = 190, style = { wall = Color3.fromRGB(185, 195, 185), roof = COL.Roof, floors = 1, width = 12, depth = 10 } },
        { id = "mansion_001", nameAr = "قصر المارينا", price = 250000, rooms = 10, area = 800, cx = -60, cz = 250, style = { wall = Color3.fromRGB(250, 245, 235), roof = COL.RoofTile, floors = 2, width = 26, depth = 20 } },
    }

    for _, h in ipairs(houses) do
        local houseModel = makeHouse3D(district, h.id, h.cx, h.cz, h.style)
        makePropertyMarker(houseModel, h.id, h.nameAr, h.price, h.rooms, h.area, Vector3.new(h.cx + h.style.width / 2 + 3, 0, h.cz + h.style.depth / 2 + 5))
        makeTree(houseModel, h.cx - h.style.width / 2 - 3, h.cz + h.style.depth / 2 + 4, "normal")
    end

    -- District sign
    local signPost = makePart(district, "DistSign", Vector3.new(0.5, 8, 0.5), Vector3.new(-90, 4, 60), COL.WallDark, MAT.Metal)
    addBillboard(signPost, "أحياء سكنية", COL.White, Vector3.new(0, 6, 0))
end

function MapBuilder:_buildCommercialDistrict()
    local district = makeModel(self._cityFolder, "Commercial")

    -- Mall (3 floors, balconies, glass facade)
    local mall = makeBuilding3D(district, "Mall", 120, 0, 60, 40, 3, {
        wall = COL.WallLight, trim = COL.WallDark, accent = COL.NeonPink,
        balcony = true, roof = "parapet", neon = true
    }, "المركز التجاري", COL.NeonCyan, "Mall")

    -- Mall glass curtain wall
    makePart(mall, "GlassCurtain", Vector3.new(58, 14, 0.4), Vector3.new(120, 9, 21), Color3.fromRGB(100, 170, 220), MAT.Glass, { Transparency = 0.35 })

    -- Mall interior features (ground floor visible through glass)
    makePart(mall, "Escalator_L", Vector3.new(2, 5, 8), Vector3.new(115, 3, 0), COL.Counter, MAT.Metal)
    makePart(mall, "Escalator_R", Vector3.new(2, 5, 8), Vector3.new(125, 3, 0), COL.Counter, MAT.Metal)
    makePart(mall, "InfoDesk", Vector3.new(4, 1.5, 2), Vector3.new(120, 1.55, 10), COL.Counter, MAT.Marble)

    -- Bank (2 floors, columns, gold accents)
    local bank = makeBuilding3D(district, "Bank", 120, 70, 30, 25, 2, {
        wall = Color3.fromRGB(50, 60, 80), trim = Color3.fromRGB(80, 85, 90), accent = COL.Gold,
        balcony = false, roof = "parapet", neon = true
    }, "البنك المركزي", COL.Gold, "Bank")

    -- Bank vault door
    makePart(bank, "VaultDoor", Vector3.new(4.5, 5, 0.8), Vector3.new(120, 3.5, 82.8), COL.Gold, MAT.Metal)
    -- Bank columns at entrance
    for _, xOff in ipairs({-6, -3, 3, 6}) do
        makePart(bank, "Column", Vector3.new(1, 10, 1), Vector3.new(120 + xOff, 6, 83.5), Color3.fromRGB(200, 195, 180), MAT.Marble, { Shape = Enum.PartType.Cylinder })
    end

    -- Shops (detailed storefronts)
    local shopData = {
        { name = "ملابس عربية", color = Color3.fromRGB(180, 60, 60), accent = COL.NeonPink },
        { name = "إلكترونيات", color = Color3.fromRGB(60, 120, 180), accent = COL.NeonBlue },
        { name = "مطعم الشرق", color = Color3.fromRGB(60, 160, 80), accent = Color3.fromRGB(0, 255, 100) },
        { name = "مجوهرات", color = Color3.fromRGB(180, 140, 60), accent = COL.Gold },
    }
    for i, shop in ipairs(shopData) do
        local sz = 60 + (i - 1) * 28
        makeBuilding3D(district, "Shop_" .. i, 180, -80 + sz, 18, 14, 2, {
            wall = shop.color, trim = COL.WallDark, accent = shop.accent,
            balcony = false, roof = "flat", neon = true
        }, shop.name, COL.White)
    end
end

function MapBuilder:_buildBeach()
    local beach = makeModel(self._cityFolder, "Beach")

    -- Boardwalk with railings
    makePart(beach, "Boardwalk", Vector3.new(200, 0.5, 6), Vector3.new(0, 0.25, -HALF + 40), Color3.fromRGB(150, 110, 60), MAT.Wood)
    makePart(beach, "BoardRail_F", Vector3.new(200, 1.2, 0.2), Vector3.new(0, 1.1, -HALF + 37), COL.WallDark, MAT.Metal)
    makePart(beach, "BoardRail_B", Vector3.new(200, 1.2, 0.2), Vector3.new(0, 1.1, -HALF + 43), COL.WallDark, MAT.Metal)

    -- Lifeguard tower (detailed)
    local tower = makeModel(beach, "LifeguardTower")
    for _, lpos in ipairs({Vector3.new(-60, 3, -HALF + 20), Vector3.new(-56, 3, -HALF + 20), Vector3.new(-60, 3, -HALF + 16), Vector3.new(-56, 3, -HALF + 16)}) do
        makePart(tower, "Leg", Vector3.new(0.4, 6, 0.4), lpos, COL.Red, MAT.Metal)
    end
    makePart(tower, "Platform", Vector3.new(6, 0.4, 6), Vector3.new(-58, 6.2, -HALF + 18), COL.Red, MAT.Smooth)
    makePart(tower, "Walls", Vector3.new(5, 3, 5), Vector3.new(-58, 7.7, -HALF + 18), COL.White, MAT.Smooth)
    makePart(tower, "Roof", Vector3.new(7, 0.3, 7), Vector3.new(-58, 9.5, -HALF + 18), COL.Red, MAT.Smooth)

    -- Beach umbrellas and chairs
    for i = -3, 3, 2 do
        local ux = i * 30
        local uz = -HALF + 10
        makePart(beach, "UmbrellaPole", Vector3.new(0.3, 5, 0.3), Vector3.new(ux, 2.5, uz), COL.WallDark, MAT.Metal)
        makePart(beach, "UmbrellaTop", Vector3.new(6, 0.3, 6), Vector3.new(ux, 5, uz), (i % 4 == 0) and COL.Red or COL.Blue, MAT.Smooth)
        -- Beach chairs
        makePart(beach, "Chair", Vector3.new(1.5, 0.5, 4), Vector3.new(ux + 2, 0.5, uz), Color3.fromRGB(180, 180, 200), MAT.Smooth)
        makePart(beach, "Chair", Vector3.new(1.5, 0.5, 4), Vector3.new(ux - 2, 0.5, uz), Color3.fromRGB(180, 180, 200), MAT.Smooth)
    end

    -- Palm trees
    for i = -4, 4, 2 do
        makeTree(beach, i * 40, -HALF + 35, "palm")
    end

    -- Beach bar/hut
    local beachBar = makeModel(beach, "BeachBar")
    makePart(beachBar, "Counter", Vector3.new(8, 1.5, 2), Vector3.new(50, 1.05, -HALF + 25), Color3.fromRGB(130, 90, 50), MAT.Wood)
    makePart(beachBar, "Roof", Vector3.new(10, 0.3, 5), Vector3.new(50, 4, -HALF + 25), Color3.fromRGB(100, 70, 40), MAT.Wood)
    makePart(beachBar, "RoofSupport_L", Vector3.new(0.4, 3, 0.4), Vector3.new(45.5, 2.5, -HALF + 22.5), Color3.fromRGB(90, 60, 30), MAT.Wood)
    makePart(beachBar, "RoofSupport_R", Vector3.new(0.4, 3, 0.4), Vector3.new(54.5, 2.5, -HALF + 22.5), Color3.fromRGB(90, 60, 30), MAT.Wood)

    local beachSign = makePart(beach, "BeachSign", Vector3.new(0.5, 6, 0.5), Vector3.new(0, 3, -HALF + 50), COL.WallDark, MAT.Metal)
    addBillboard(beachSign, "شاطئ Arab City", COL.NeonCyan, Vector3.new(0, 5, 0))
end

function MapBuilder:_buildAirport()
    local airport = makeModel(self._cityFolder, "Airport")

    -- Terminal (3 floors, glass facade)
    makeBuilding3D(airport, "Terminal", -200, 0, 80, 30, 3, {
        wall = Color3.fromRGB(200, 210, 220), trim = COL.WallDark, accent = COL.NeonCyan,
        balcony = false, roof = "parapet", neon = true
    }, "مطار Arab City الدولي", COL.Gold, "Airport")

    -- Glass curtain wall
    makePart(airport, "GlassFacade", Vector3.new(78, 14, 0.5), Vector3.new(-200, 9, 16), Color3.fromRGB(120, 180, 230), MAT.Glass, { Transparency = 0.35 })

    -- Control tower (detailed)
    local ctower = makeModel(airport, "ControlTower")
    makePart(ctower, "TowerBase", Vector3.new(8, 30, 8), Vector3.new(-250, 15, 0), COL.WallLight, MAT.Concrete)
    makePart(ctower, "TowerNeck", Vector3.new(5, 5, 5), Vector3.new(-250, 32.5, 0), COL.WallDark, MAT.Concrete)
    makePart(ctower, "TowerCab", Vector3.new(12, 5, 12), Vector3.new(-250, 37.5, 0), COL.WallDark, MAT.Metal)
    makePart(ctower, "TowerGlass", Vector3.new(11, 4, 11), Vector3.new(-250, 37.5, 0), COL.Window, MAT.Glass, { Transparency = 0.3 })
    makePart(ctower, "TowerRoof", Vector3.new(13, 0.5, 13), Vector3.new(-250, 40.25, 0), COL.Roof, MAT.Metal)
    local beacon = makePart(ctower, "Beacon", Vector3.new(1.5, 1.5, 1.5), Vector3.new(-250, 41.5, 0), COL.Red, MAT.Neon, { Shape = Enum.PartType.Ball })
    addPointLight(beacon, COL.Red, 3, 60)

    -- Runway
    makePart(airport, "Runway", Vector3.new(300, 0.3, 30), Vector3.new(-250, 0.15, -50), COL.Road, MAT.Road)
    for i = 0, 10 do
        makePart(airport, "RunwayMark", Vector3.new(8, 0.32, 1), Vector3.new(-380 + i * 26, 0.16, -50), COL.White, MAT.Smooth)
    end
    for i = 0, 20 do
        local lx = -400 + i * 15
        makePart(airport, "RwyLight", Vector3.new(0.5, 0.5, 0.5), Vector3.new(lx, 0.5, -35), COL.NeonCyan, MAT.Neon)
        makePart(airport, "RwyLight", Vector3.new(0.5, 0.5, 0.5), Vector3.new(lx, 0.5, -65), COL.NeonCyan, MAT.Neon)
    end

    -- Hangar
    makePart(airport, "Hangar", Vector3.new(40, 15, 30), Vector3.new(-160, 7.5, -60), Color3.fromRGB(160, 165, 175), MAT.Metal)
    makePart(airport, "HangarDoor", Vector3.new(25, 12, 0.5), Vector3.new(-160, 6, -44.7), Color3.fromRGB(140, 145, 155), MAT.Metal)
end

function MapBuilder:_buildHospital()
    local hospital = makeModel(self._cityFolder, "Hospital")

    local building = makeBuilding3D(hospital, "HospitalMain", 80, 150, 40, 30, 4, {
        wall = COL.HospWhite, trim = Color3.fromRGB(200, 205, 210), accent = COL.Red,
        balcony = false, roof = "parapet", neon = true
    }, "مستشفى Arab City", COL.Red, "Hospital")

    -- Red cross neon
    makePart(building, "CrossH", Vector3.new(8, 2, 0.3), Vector3.new(80, 18, 165.5), COL.Red, MAT.Neon)
    makePart(building, "CrossV", Vector3.new(2, 8, 0.3), Vector3.new(80, 18, 165.5), COL.Red, MAT.Neon)

    -- Ambulance bay
    makePart(hospital, "AmbBay_Roof", Vector3.new(15, 0.4, 10), Vector3.new(60, 5, 165), COL.WallLight, MAT.Concrete)
    makePart(hospital, "AmbBay_Col_L", Vector3.new(0.5, 5, 0.5), Vector3.new(52.5, 2.5, 170), COL.WallDark, MAT.Metal)
    makePart(hospital, "AmbBay_Col_R", Vector3.new(0.5, 5, 0.5), Vector3.new(67.5, 2.5, 170), COL.WallDark, MAT.Metal)

    -- Parking
    makePart(hospital, "Parking", Vector3.new(25, 0.3, 20), Vector3.new(60, 0.15, 130), COL.Road, MAT.Road)
    -- Parking lines
    for i = 0, 4 do
        makePart(hospital, "ParkLine", Vector3.new(0.2, 0.32, 5), Vector3.new(50 + i * 5, 0.16, 130), COL.White, MAT.Smooth)
    end

    -- Helipad on roof
    makePart(hospital, "Helipad", Vector3.new(12, 0.2, 12), Vector3.new(80, 21.7, 150), Color3.fromRGB(100, 100, 105), MAT.Concrete)
    makePart(hospital, "HelipadH", Vector3.new(6, 0.22, 1), Vector3.new(80, 21.8, 150), COL.White, MAT.Smooth)
    makePart(hospital, "HelipadH2", Vector3.new(1, 0.22, 6), Vector3.new(80, 21.8, 150), COL.White, MAT.Smooth)
end

function MapBuilder:_buildPoliceStation()
    local station = makeModel(self._cityFolder, "PoliceStation")

    makeBuilding3D(station, "PoliceMain", 80, 220, 35, 25, 2, {
        wall = COL.PoliceBlue, trim = Color3.fromRGB(40, 50, 80), accent = COL.Blue,
        balcony = false, roof = "flat", neon = true
    }, "مركز الشرطة", COL.Blue, "PoliceStation")

    -- Police light bar
    local lightBar = makePart(station, "LightBar", Vector3.new(4, 0.5, 0.5), Vector3.new(80, 11.5, 232.8), COL.Blue, MAT.Neon)
    addPointLight(lightBar, COL.Blue, 2, 25)
    local lightBar2 = makePart(station, "LightBar2", Vector3.new(4, 0.5, 0.5), Vector3.new(84, 11.5, 232.8), COL.Red, MAT.Neon)
    addPointLight(lightBar2, COL.Red, 2, 25)

    -- Parking
    makePart(station, "Parking", Vector3.new(20, 0.3, 15), Vector3.new(60, 0.15, 220), COL.Road, MAT.Road)
end

function MapBuilder:_buildFireStation()
    local station = makeModel(self._cityFolder, "FireStation")

    makeBuilding3D(station, "FireMain", -80, -120, 35, 25, 2, {
        wall = COL.Red, trim = Color3.fromRGB(150, 30, 30), accent = Color3.fromRGB(255, 100, 0),
        balcony = false, roof = "flat", neon = true
    }, "مركز الإطفاء", COL.Red, "FireStation")

    -- Garage doors (large)
    makePart(station, "GarageDoor1", Vector3.new(8, 7, 0.5), Vector3.new(-84, 4.5, -107.3), Color3.fromRGB(180, 40, 40), MAT.Metal)
    makePart(station, "GarageDoor2", Vector3.new(8, 7, 0.5), Vector3.new(-76, 4.5, -107.3), Color3.fromRGB(180, 40, 40), MAT.Metal)

    -- Training tower
    makePart(station, "TrainTower", Vector3.new(6, 20, 6), Vector3.new(-100, 10, -120), COL.WallDark, MAT.Concrete)
    -- Tower windows
    for i = 1, 4 do
        makePart(station, "TowerWin_" .. i, Vector3.new(2, 2, 0.2), Vector3.new(-100, 3 + i * 4, -116.8), COL.Window, MAT.Glass, { Transparency = 0.3 })
    end
end

function MapBuilder:_buildVIPZone()
    local vip = makeModel(self._cityFolder, "VIPZone")

    -- VIP elevated platform with marble
    makePart(vip, "VIPFloor", Vector3.new(65, 1.2, 65), Vector3.new(-150, 0.6, 150), Color3.fromRGB(40, 35, 50), MAT.Marble)
    makePart(vip, "VIPFloorAccent", Vector3.new(50, 1.22, 50), Vector3.new(-150, 0.61, 150), Color3.fromRGB(50, 40, 60), MAT.Marble)

    -- Golden neon border
    for _, data in ipairs({
        {Vector3.new(66, 0.4, 1), Vector3.new(-150, 1.4, 183)},
        {Vector3.new(66, 0.4, 1), Vector3.new(-150, 1.4, 117)},
        {Vector3.new(1, 0.4, 66), Vector3.new(-183, 1.4, 150)},
        {Vector3.new(1, 0.4, 66), Vector3.new(-117, 1.4, 150)},
    }) do
        makePart(vip, "NeonBorder", data[1], data[2], COL.Gold, MAT.Neon)
    end

    -- VIP lounge building (premium look)
    makeBuilding3D(vip, "VIPLounge", -150, 150, 30, 20, 2, {
        wall = Color3.fromRGB(30, 25, 40), trim = Color3.fromRGB(50, 45, 60), accent = COL.Gold,
        balcony = true, roof = "flat", neon = true
    }, "منطقة VIP", COL.Gold, "VIPLounge")

    -- VIP fountain
    makePart(vip, "VIPFountain", Vector3.new(6, 1, 6), Vector3.new(-150, 1.1, 165), COL.Gold, MAT.Marble)
    makePart(vip, "VIPWater", Vector3.new(5, 0.8, 5), Vector3.new(-150, 1.1, 165), COL.Water, MAT.Water, { Transparency = 0.3 })
end

function MapBuilder:_buildCarDealership()
    local dealer = makeModel(self._cityFolder, "CarDealership")

    -- Showroom (glass facade, modern)
    local showroom = makeBuilding3D(dealer, "Showroom", 180, -120, 50, 35, 2, {
        wall = COL.WallLight, trim = COL.WallDark, accent = COL.NeonCyan,
        balcony = false, roof = "parapet", neon = true
    }, "معرض السيارات", COL.NeonCyan, "CarDealership")

    -- Full glass front wall
    makePart(showroom, "GlassWall", Vector3.new(48, 9, 0.4), Vector3.new(180, 5.5, -102.3), COL.Window, MAT.Glass, { Transparency = 0.35 })

    -- Display platforms with cars
    local carColors = { COL.Red, COL.Blue, Color3.fromRGB(240, 240, 240), COL.Gold }
    local carNames = { "سيدان", "كوبيه", "جيب", "سوبر كار" }
    for i = 1, 4 do
        local px = 158 + (i - 1) * 14
        -- Rotating platform
        makePart(dealer, "Platform_" .. i, Vector3.new(10, 0.6, 8), Vector3.new(px, 1, -120), Color3.fromRGB(50, 50, 55), MAT.Marble)
        makePart(dealer, "PlatformLight_" .. i, Vector3.new(10, 0.15, 0.2), Vector3.new(px, 0.4, -116), COL.NeonCyan, MAT.Neon)

        -- Detailed car shape
        local carModel = makeModel(dealer, "Car_" .. i)
        makePart(carModel, "Body", Vector3.new(4, 1.8, 8), Vector3.new(px, 2.5, -120), carColors[i], MAT.Smooth)
        makePart(carModel, "Roof", Vector3.new(3.4, 1.3, 4), Vector3.new(px, 3.8, -119.5), carColors[i], MAT.Smooth)
        makePart(carModel, "Windshield", Vector3.new(3.2, 1.2, 0.2), Vector3.new(px, 3.6, -117.3), COL.Window, MAT.Glass, { Transparency = 0.3 })
        makePart(carModel, "Headlight_L", Vector3.new(0.8, 0.4, 0.2), Vector3.new(px - 1.2, 2.2, -115.9), COL.White, MAT.Neon)
        makePart(carModel, "Headlight_R", Vector3.new(0.8, 0.4, 0.2), Vector3.new(px + 1.2, 2.2, -115.9), COL.White, MAT.Neon)
        -- Wheels
        for _, woff in ipairs({Vector3.new(-2.2, 0, 2.5), Vector3.new(2.2, 0, 2.5), Vector3.new(-2.2, 0, -2.5), Vector3.new(2.2, 0, -2.5)}) do
            makePart(carModel, "Wheel", Vector3.new(0.5, 1.5, 1.5), Vector3.new(px + woff.X, 1.6 + woff.Y, -120 + woff.Z), COL.Black, MAT.Smooth, { Shape = Enum.PartType.Cylinder })
        end
        addBillboard(carModel:FindFirstChild("Body"), carNames[i], COL.White, Vector3.new(0, 4, 0))
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

    -- Park (detailed with paths and benches)
    local park = makeModel(decor, "CityPark")
    makePart(park, "ParkGround", Vector3.new(45, 0.2, 45), Vector3.new(-60, 0.1, 40), COL.Grass, MAT.Grass)
    -- Park paths
    makePart(park, "Path_H", Vector3.new(40, 0.22, 3), Vector3.new(-60, 0.11, 40), COL.Sidewalk, MAT.Concrete)
    makePart(park, "Path_V", Vector3.new(3, 0.22, 40), Vector3.new(-60, 0.11, 40), COL.Sidewalk, MAT.Concrete)
    -- Park trees
    for _, treePos in ipairs({
        Vector3.new(-48, 0, 28), Vector3.new(-72, 0, 28),
        Vector3.new(-48, 0, 52), Vector3.new(-72, 0, 52),
        Vector3.new(-60, 0, 40),
    }) do
        makeTree(park, treePos.X, treePos.Z, "normal")
    end
    -- Park benches
    for _, bpos in ipairs({Vector3.new(-52, 0.9, 40), Vector3.new(-68, 0.9, 40)}) do
        makePart(park, "Bench", Vector3.new(4, 0.4, 1.5), bpos, COL.WallDark, MAT.Wood)
        makePart(park, "BenchBack", Vector3.new(4, 1, 0.3), bpos + Vector3.new(0, 0.7, -0.6), COL.WallDark, MAT.Wood)
    end
end

function MapBuilder:_buildVehicleSpawns()
    local spawns = makeModel(self._cityFolder, "VehicleSpawns")

    local spawnPoints = {
        { pos = Vector3.new(30, 0.3, -30), name = "SpawnPad_Center1" },
        { pos = Vector3.new(-30, 0.3, -30), name = "SpawnPad_Center2" },
        { pos = Vector3.new(60, 0.3, 150), name = "SpawnPad_Hospital" },
        { pos = Vector3.new(60, 0.3, 220), name = "SpawnPad_Police" },
        { pos = Vector3.new(180, 0.3, -100), name = "SpawnPad_Dealer" },
        { pos = Vector3.new(-200, 0.3, 20), name = "SpawnPad_Airport" },
    }

    for _, sp in ipairs(spawnPoints) do
        local pad = makePart(spawns, sp.name, Vector3.new(8, 0.3, 12), sp.pos, Color3.fromRGB(50, 50, 55), MAT.Concrete)
        makePart(spawns, sp.name .. "_Br1", Vector3.new(8.5, 0.35, 0.3), sp.pos + Vector3.new(0, 0, 6), COL.NeonCyan, MAT.Neon)
        makePart(spawns, sp.name .. "_Br2", Vector3.new(8.5, 0.35, 0.3), sp.pos + Vector3.new(0, 0, -6), COL.NeonCyan, MAT.Neon)
        CollectionService:AddTag(pad, "VehicleSpawn")
    end
end

function MapBuilder:_setupLighting()
    Lighting.ClockTime = 9
    Lighting.GlobalShadows = true
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
    Lighting.Ambient = Color3.fromRGB(100, 105, 115)
    Lighting.FogEnd = 5000
    Lighting.FogColor = Color3.fromRGB(180, 200, 230)

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = 0.25
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(199, 170, 107)
    atmosphere.Decay = Color3.fromRGB(92, 100, 120)
    atmosphere.Glare = 0.1
    atmosphere.Haze = 1.5

    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end
    sky.StarCount = 0
    sky.MoonAngularSize = 8
    sky.SunAngularSize = 18

    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Parent = Lighting
    end
    bloom.Intensity = 0.4
    bloom.Size = 24
    bloom.Threshold = 0.85

    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Parent = Lighting
    end
    cc.Brightness = 0.03
    cc.Contrast = 0.1
    cc.Saturation = 0.15
    cc.TintColor = Color3.fromRGB(255, 245, 230)

    local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
    if not sunRays then
        sunRays = Instance.new("SunRaysEffect")
        sunRays.Parent = Lighting
    end
    sunRays.Intensity = 0.15
    sunRays.Spread = 0.8
end

return MapBuilder
