--[[
    Arab City v2.0 - LODController
    Level-of-Detail: hide distant detail parts for performance.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LODController = {}

local player = Players.LocalPlayer
local LOD_DISTANCE = 300
local LOD_INTERVAL = 2

function LODController:Init()
    self._detailParts = {}

    task.spawn(function()
        task.wait(5)
        self:_collectDetails()
    end)

    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < LOD_INTERVAL then return end
        elapsed = 0
        self:_updateLOD()
    end)
end

function LODController:_collectDetails()
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("BasePart") and desc:GetAttribute("LODDetail") then
            table.insert(self._detailParts, desc)
        end
    end
end

function LODController:_updateLOD()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local playerPos = hrp.Position

    for _, part in ipairs(self._detailParts) do
        if part and part.Parent then
            local dist = (part.Position - playerPos).Magnitude
            local shouldShow = dist < LOD_DISTANCE
            if part.Transparency ~= (if shouldShow then 0 else 1) then
                part.Transparency = if shouldShow then 0 else 1
                part.CanCollide = shouldShow
            end
        end
    end
end

return LODController
