--[[
    Arab City v2.0 - TrafficService
    Spawns NPC cars that drive along predefined waypoint paths.
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrafficService = {}

local Shared, Constants
local NPC_COLORS = {
    BrickColor.new("Bright red"),
    BrickColor.new("Bright blue"),
    BrickColor.new("White"),
    BrickColor.new("Black"),
    BrickColor.new("Dark stone grey"),
    BrickColor.new("Bright yellow"),
    BrickColor.new("Sand green"),
}
local NPC_SPEED = 30
local NPC_COUNT = 4

function TrafficService:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants

    task.spawn(function()
        task.wait(3)
        self:_spawnTraffic()
    end)
end

function TrafficService:_spawnTraffic()
    local folder = Instance.new("Folder")
    folder.Name = "NPCTraffic"
    folder.Parent = Workspace

    local rng = Random.new()

    for pathIndex, path in ipairs(Constants.TRAFFIC_PATHS) do
        for i = 1, NPC_COUNT do
            local startIdx = ((i - 1) % #path) + 1
            local car = self:_createCar(rng)
            car.Name = "NPC_Car_" .. pathIndex .. "_" .. i
            local startWP = path[startIdx]
            car.CFrame = CFrame.new(startWP[1], startWP[2], startWP[3])
            car.Parent = folder

            task.spawn(function()
                self:_drivePath(car, path, startIdx)
            end)
        end
    end
end

function TrafficService:_createCar(rng)
    local body = Instance.new("Part")
    body.Size = Vector3.new(5, 2.5, 10)
    body.Anchored = true
    body.CanCollide = true
    body.BrickColor = NPC_COLORS[rng:NextInteger(1, #NPC_COLORS)]
    body.Material = Enum.Material.SmoothPlastic
    body.TopSurface = Enum.SurfaceType.Smooth
    body.BottomSurface = Enum.SurfaceType.Smooth

    local roof = Instance.new("Part")
    roof.Size = Vector3.new(4.5, 1.5, 5)
    roof.Anchored = true
    roof.CanCollide = false
    roof.BrickColor = body.BrickColor
    roof.Material = Enum.Material.SmoothPlastic
    roof.CFrame = body.CFrame * CFrame.new(0, 1.8, -0.5)
    roof.Parent = body

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = body
    weld.Part1 = roof
    weld.Parent = body

    return body
end

function TrafficService:_drivePath(car, path, startIdx)
    local idx = startIdx
    while car and car.Parent do
        local nextIdx = (idx % #path) + 1
        local wp = path[nextIdx]
        local targetPos = Vector3.new(wp[1], wp[2], wp[3])
        local currentPos = car.Position

        local direction = (targetPos - currentPos)
        local distance = direction.Magnitude
        if distance < 1 then
            idx = nextIdx
            continue
        end

        local lookAt = CFrame.lookAt(currentPos, targetPos)
        local duration = distance / NPC_SPEED

        local tween = TweenService:Create(car, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            CFrame = lookAt + (targetPos - currentPos),
        })
        tween:Play()
        tween.Completed:Wait()

        idx = nextIdx
    end
end

return TrafficService
