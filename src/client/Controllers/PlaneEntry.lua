--[[
    Arab City v2.0 - PlaneEntry
    Plane drop with parachute — players spawn in a plane and skydive.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local PlaneEntry = {}

local Shared, Constants
local player = Players.LocalPlayer
local _active = false

local PLANE_Y = 400
local DROP_SPEED = 50
local GLIDE_SPEED = 30
local CHUTE_DRAG = 0.4

function PlaneEntry:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants

    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        self:_startDrop(char)
    end)

    if player.Character then
        task.spawn(function()
            task.wait(2)
            self:_startDrop(player.Character)
        end)
    end
end

function PlaneEntry:_startDrop(char)
    if _active then return end
    _active = true

    local hrp = char:WaitForChild("HumanoidRootPart")
    local humanoid = char:WaitForChild("Humanoid")

    -- Disable default movement
    humanoid.PlatformStand = true
    char:SetAttribute("InPlaneEntry", true)

    -- Position high up
    hrp.CFrame = CFrame.new(0, PLANE_Y, 0)
    hrp.Anchored = true

    -- Plane model
    local plane = Instance.new("Model")
    plane.Name = "EntryPlane"

    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(12, 4, 40)
    body.Position = Vector3.new(0, PLANE_Y + 5, 0)
    body.BrickColor = BrickColor.new("White")
    body.Material = Enum.Material.SmoothPlastic
    body.Anchored = true
    body.CanCollide = false
    body.Parent = plane

    local wing1 = Instance.new("Part")
    wing1.Name = "WingL"
    wing1.Size = Vector3.new(30, 1, 10)
    wing1.Position = Vector3.new(-18, PLANE_Y + 5, 0)
    wing1.BrickColor = BrickColor.new("Medium stone grey")
    wing1.Anchored = true
    wing1.CanCollide = false
    wing1.Parent = plane

    local wing2 = Instance.new("Part")
    wing2.Name = "WingR"
    wing2.Size = Vector3.new(30, 1, 10)
    wing2.Position = Vector3.new(18, PLANE_Y + 5, 0)
    wing2.BrickColor = BrickColor.new("Medium stone grey")
    wing2.Anchored = true
    wing2.CanCollide = false
    wing2.Parent = plane

    plane.Parent = workspace

    -- Fly forward
    task.wait(2)

    -- Jump prompt
    local jumpGui = Instance.new("ScreenGui")
    jumpGui.Name = "JumpPrompt"
    jumpGui.ResetOnSpawn = false
    jumpGui.Parent = player:WaitForChild("PlayerGui")

    local jumpLabel = Instance.new("TextLabel")
    jumpLabel.Size = UDim2.new(0, 300, 0, 60)
    jumpLabel.Position = UDim2.new(0.5, 0, 0.7, 0)
    jumpLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    jumpLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    jumpLabel.BackgroundTransparency = 0.2
    jumpLabel.Text = "اضغط SPACE أو E للقفز!"
    jumpLabel.TextSize = 20
    jumpLabel.Font = Enum.Font.GothamBold
    jumpLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
    jumpLabel.BorderSizePixel = 0
    jumpLabel.Parent = jumpGui
    Instance.new("UICorner", jumpLabel).CornerRadius = UDim.new(0, 10)

    -- Wait for jump input
    local jumped = false
    local conn = game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.E then
            jumped = true
        end
    end)

    -- Auto jump after 8 seconds
    local timer = 0
    while not jumped and timer < 8 do
        timer = timer + task.wait(0.1)
    end

    conn:Disconnect()
    jumpGui:Destroy()
    plane:Destroy()

    -- Free-fall with parachute
    hrp.Anchored = false
    humanoid.PlatformStand = false

    -- Parachute
    local chute = Instance.new("Part")
    chute.Name = "Parachute"
    chute.Size = Vector3.new(14, 1, 14)
    chute.BrickColor = BrickColor.new("Bright red")
    chute.Material = Enum.Material.Fabric
    chute.Anchored = false
    chute.CanCollide = false
    chute.Massless = true
    chute.Parent = char

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = chute
    weld.Parent = chute

    chute.CFrame = hrp.CFrame * CFrame.new(0, 8, 0)

    -- Body velocity for slow descent
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(10000, 10000, 10000)
    bv.Velocity = Vector3.new(0, -DROP_SPEED * CHUTE_DRAG, 0)
    bv.Parent = hrp

    -- Glide control loop
    local running = true
    local glideConn = RunService.Heartbeat:Connect(function()
        if not running then return end
        local moveDir = humanoid.MoveDirection
        local vx = moveDir.X * GLIDE_SPEED
        local vz = moveDir.Z * GLIDE_SPEED
        bv.Velocity = Vector3.new(vx, -DROP_SPEED * CHUTE_DRAG, vz)
    end)

    -- Wait until near ground
    task.spawn(function()
        while running do
            task.wait(0.2)
            if hrp.Position.Y < 15 then
                running = false
                glideConn:Disconnect()
                bv:Destroy()
                chute:Destroy()
                char:SetAttribute("InPlaneEntry", false)
                _active = false
                break
            end
        end
    end)
end

return PlaneEntry
