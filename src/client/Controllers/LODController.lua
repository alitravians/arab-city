--[[
    Arab City - LOD (Level of Detail) Controller
    Manages rendering optimization:
    - Hides small detail parts when far from camera
    - Reduces transparency of distant windows
    - Merges small parts conceptually by toggling visibility
    - Runs on Heartbeat with throttled updates
]]

local RunService = game:GetService("RunService")

local LODController = {}

local LOD_UPDATE_INTERVAL = 0.5 -- seconds between LOD sweeps
local LOD_NEAR = 120            -- studs: full detail
local LOD_MID = 300             -- studs: reduced detail
local LOD_FAR = 600             -- studs: minimal detail

-- Part name patterns considered "detail" (hidden at distance)
local DETAIL_PATTERNS = {
    "Shutter", "Chair", "Bench", "Lamp", "Pillow", "Rug", "Nightstand",
    "Stove", "Fridge", "Sink", "Bathtub", "CoffeeTable", "DiningTable",
    "Sofa", "SofaBack", "TV", "TVStand", "Wardrobe", "BedFrame", "Bed",
    "Counter", "Appliance", "AC_", "ParkLine", "RunwayMark", "RwyLight",
    "Flower", "Pot", "Umbrella",
}

local WINDOW_PATTERN = "Window"

local function isDetailPart(name: string): boolean
    for _, pat in ipairs(DETAIL_PATTERNS) do
        if string.find(name, pat, 1, true) then
            return true
        end
    end
    return false
end

function LODController:Init()
    self._cachedParts = {}
    self._lastUpdate = 0

    -- Collect LOD-eligible parts from map
    task.defer(function()
        self:_collectParts()
    end)

    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - self._lastUpdate < LOD_UPDATE_INTERVAL then
            return
        end
        self._lastUpdate = now
        self:_updateLOD()
    end)
end

function LODController:_collectParts()
    local mapFolder = workspace:FindFirstChild("ArabCity_Map")
    if not mapFolder then return end

    local detailParts = {}
    local windowParts = {}

    for _, desc in ipairs(mapFolder:GetDescendants()) do
        if desc:IsA("BasePart") then
            if isDetailPart(desc.Name) then
                table.insert(detailParts, { part = desc, origTransparency = desc.Transparency })
            elseif string.find(desc.Name, WINDOW_PATTERN, 1, true) then
                table.insert(windowParts, { part = desc, origTransparency = desc.Transparency })
            end
        end
    end

    self._detailParts = detailParts
    self._windowParts = windowParts
end

function LODController:_updateLOD()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local camPos = camera.CFrame.Position

    -- Detail parts: hide when far
    if self._detailParts then
        for _, entry in ipairs(self._detailParts) do
            local part = entry.part
            if not part or not part.Parent then continue end
            local dist = (part.Position - camPos).Magnitude

            if dist < LOD_NEAR then
                part.Transparency = entry.origTransparency
            elseif dist < LOD_MID then
                part.Transparency = math.max(entry.origTransparency, 0.6)
            else
                part.Transparency = 1
            end
        end
    end

    -- Windows: increase transparency when far
    if self._windowParts then
        for _, entry in ipairs(self._windowParts) do
            local part = entry.part
            if not part or not part.Parent then continue end
            local dist = (part.Position - camPos).Magnitude

            if dist < LOD_MID then
                part.Transparency = entry.origTransparency
            elseif dist < LOD_FAR then
                part.Transparency = math.max(entry.origTransparency, 0.7)
            else
                part.Transparency = 1
            end
        end
    end

    -- Disable point lights on far objects
    if self._detailParts then
        for _, entry in ipairs(self._detailParts) do
            local part = entry.part
            if not part or not part.Parent then continue end
            local dist = (part.Position - camPos).Magnitude
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("PointLight") or child:IsA("SpotLight") then
                    child.Enabled = dist < LOD_MID
                end
            end
        end
    end
end

return LODController
