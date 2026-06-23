--[[
    Arab City - Plane Entry & Parachute System
    Player spawns inside a plane flying over the city.
    They choose when to jump, then parachute down to any location.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local player = Players.LocalPlayer

local PlaneEntry = {}
PlaneEntry._active = false
PlaneEntry._phase = "none" -- "plane", "freefall", "parachute", "landed"

local PLANE_CONFIG = {
    altitude = Constants.PLANE_ALTITUDE,
    speed = Constants.PLANE_SPEED,
    pathLength = 2000,
    startX = -1000,
    endX = 1000,
    freefallSpeed = 120,
    parachuteSpeed = Constants.PARACHUTE_FALL_SPEED,
    driftSpeed = Constants.PARACHUTE_DRIFT_SPEED,
    jumpKey = Enum.KeyCode.Space,
    parachuteKey = Enum.KeyCode.Space,
    landingThreshold = 10,
}

function PlaneEntry:Start()
    if self._active then
        return
    end
    self._active = true
    self._phase = "plane"

    -- Create plane model
    self._plane = self:_createPlane()

    -- Position player inside plane
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    -- Disable character movement during plane phase
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    -- Attach player to plane seat
    local planeSeat = self._plane:FindFirstChild("PlaneSeat")
    if planeSeat and planeSeat:IsA("Seat") then
        planeSeat:Sit(humanoid)
    else
        -- Weld player to plane
        self._planeWeld = Instance.new("WeldConstraint")
        self._planeWeld.Part0 = self._plane.PrimaryPart
        self._planeWeld.Part1 = rootPart
        self._planeWeld.Parent = rootPart
    end

    -- Show jump prompt GUI
    self:_showJumpPrompt()

    -- Camera follow
    self:_setupPlaneCamera()

    -- Fly the plane
    self:_flyPlane()

    -- Input handlers
    self._jumpConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == PLANE_CONFIG.jumpKey or input.UserInputType == Enum.UserInputType.Touch then
            if self._phase == "plane" then
                self:_jump()
            elseif self._phase == "freefall" then
                self:_deployParachute()
            end
        end
    end)
end

function PlaneEntry:_createPlane(): Model
    local model = Instance.new("Model")
    model.Name = "EntryPlane"

    -- Fuselage
    local fuselage = Instance.new("Part")
    fuselage.Name = "Fuselage"
    fuselage.Size = Vector3.new(8, 6, 40)
    fuselage.Position = Vector3.new(PLANE_CONFIG.startX, PLANE_CONFIG.altitude, 0)
    fuselage.Anchored = true
    fuselage.CanCollide = false
    fuselage.Material = Enum.Material.SmoothPlastic
    fuselage.Color = Color3.fromRGB(220, 220, 230)
    fuselage.Transparency = 0.3
    fuselage.Parent = model

    -- Wings
    local leftWing = Instance.new("Part")
    leftWing.Name = "LeftWing"
    leftWing.Size = Vector3.new(25, 0.5, 10)
    leftWing.Position = fuselage.Position + Vector3.new(-16, 0, 0)
    leftWing.Anchored = true
    leftWing.CanCollide = false
    leftWing.Material = Enum.Material.SmoothPlastic
    leftWing.Color = Color3.fromRGB(200, 200, 210)
    leftWing.Transparency = 0.3
    leftWing.Parent = model

    local rightWing = leftWing:Clone()
    rightWing.Name = "RightWing"
    rightWing.Position = fuselage.Position + Vector3.new(16, 0, 0)
    rightWing.Parent = model

    -- Tail
    local tail = Instance.new("Part")
    tail.Name = "Tail"
    tail.Size = Vector3.new(1, 8, 6)
    tail.Position = fuselage.Position + Vector3.new(0, 4, -18)
    tail.Anchored = true
    tail.CanCollide = false
    tail.Material = Enum.Material.SmoothPlastic
    tail.Color = Color3.fromRGB(200, 200, 210)
    tail.Transparency = 0.3
    tail.Parent = model

    -- Engines (under wings)
    for _, xOff in ipairs({ -12, 12 }) do
        local engine = Instance.new("Part")
        engine.Name = "Engine"
        engine.Size = Vector3.new(3, 3, 6)
        engine.Position = fuselage.Position + Vector3.new(xOff, -2, 2)
        engine.Anchored = true
        engine.CanCollide = false
        engine.Material = Enum.Material.Metal
        engine.Color = Color3.fromRGB(100, 100, 110)
        engine.Transparency = 0.3
        engine.Parent = model

        -- Engine glow
        local glow = Instance.new("Part")
        glow.Size = Vector3.new(2, 2, 0.5)
        glow.Position = engine.Position + Vector3.new(0, 0, -3)
        glow.Anchored = true
        glow.CanCollide = false
        glow.Material = Enum.Material.Neon
        glow.Color = Color3.fromRGB(100, 150, 255)
        glow.Transparency = 0.2
        glow.Shape = Enum.PartType.Cylinder
        glow.Parent = model
    end

    -- Seat inside
    local seat = Instance.new("Seat")
    seat.Name = "PlaneSeat"
    seat.Size = Vector3.new(2, 0.5, 2)
    seat.Position = fuselage.Position + Vector3.new(0, -1, 5)
    seat.Anchored = true
    seat.CanCollide = true
    seat.Transparency = 1
    seat.Parent = model

    -- Interior light
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range = 20
    light.Color = Color3.fromRGB(255, 240, 200)
    light.Parent = fuselage

    -- Engine sound
    local engineSound = Instance.new("Sound")
    engineSound.Name = "EngineSound"
    engineSound.SoundId = "rbxassetid://6602555210" -- Replace with plane engine sound
    engineSound.Volume = 0.4
    engineSound.Looped = true
    engineSound.Parent = fuselage
    engineSound:Play()

    -- Arab City banner on fuselage
    local banner = Instance.new("BillboardGui")
    banner.Size = UDim2.new(8, 0, 2, 0)
    banner.StudsOffset = Vector3.new(0, 5, 0)
    banner.AlwaysOnTop = true
    banner.Parent = fuselage

    local bannerText = Instance.new("TextLabel")
    bannerText.Size = UDim2.new(1, 0, 1, 0)
    bannerText.BackgroundTransparency = 1
    bannerText.Text = "✈️ ARAB CITY"
    bannerText.TextColor3 = Color3.fromRGB(255, 215, 0)
    bannerText.TextStrokeTransparency = 0
    bannerText.Font = Enum.Font.GothamBlack
    bannerText.TextScaled = true
    bannerText.Parent = banner

    model.PrimaryPart = fuselage
    model.Parent = workspace
    return model
end

function PlaneEntry:_flyPlane()
    task.spawn(function()
        local start = Vector3.new(PLANE_CONFIG.startX, PLANE_CONFIG.altitude, 0)
        local finish = Vector3.new(PLANE_CONFIG.endX, PLANE_CONFIG.altitude, 0)
        local distance = (finish - start).Magnitude
        local duration = distance / PLANE_CONFIG.speed
        local elapsed = 0

        while self._phase == "plane" and self._plane and self._plane.Parent do
            local dt = RunService.Heartbeat:Wait()
            elapsed += dt

            local t = math.clamp(elapsed / duration, 0, 1)
            local pos = start:Lerp(finish, t)
            self._plane:SetPrimaryPartCFrame(CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0))

            if t >= 1 then
                -- Auto-jump if player didn't jump
                if self._phase == "plane" then
                    self:_jump()
                end
                break
            end
        end
    end)
end

function PlaneEntry:_setupPlaneCamera()
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable

    task.spawn(function()
        while self._phase == "plane" and self._plane and self._plane.Parent do
            local planeCF = self._plane.PrimaryPart.CFrame
            camera.CFrame = planeCF * CFrame.new(0, 8, 25) * CFrame.Angles(math.rad(-10), 0, 0)
            RunService.RenderStepped:Wait()
        end
    end)
end

function PlaneEntry:_showJumpPrompt()
    local gui = Instance.new("ScreenGui")
    gui.Name = "JumpPrompt"
    gui.DisplayOrder = 50
    gui.ResetOnSpawn = false
    gui.Parent = player.PlayerGui
    self._jumpGui = gui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.3, 0, 0, 60)
    frame.Position = UDim2.new(0.5, 0, 0.85, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 215, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "اضغط [Space] أو اللمس للقفز!"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.Parent = frame
    self._jumpLabel = label

    -- Pulse animation
    task.spawn(function()
        while gui.Parent do
            TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.2,
            }):Play()
            task.wait(0.8)
            TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.5,
            }):Play()
            task.wait(0.8)
        end
    end)
end

function PlaneEntry:_jump()
    self._phase = "freefall"

    local character = player.Character
    if not character then
        return
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then
        return
    end

    -- Detach from plane
    if self._planeWeld then
        self._planeWeld:Destroy()
        self._planeWeld = nil
    end

    local seat = self._plane:FindFirstChild("PlaneSeat")
    if seat and seat:IsA("Seat") then
        humanoid.Sit = false
    end

    rootPart.Anchored = false

    -- Remove plane after delay
    task.delay(3, function()
        if self._plane then
            self._plane:Destroy()
            self._plane = nil
        end
    end)

    -- Update GUI
    if self._jumpLabel then
        self._jumpLabel.Text = "اضغط [Space] لفتح المظلة!"
    end

    -- Switch camera to follow freefall
    self:_freefallCamera()

    -- Freefall physics
    self:_handleFreefall(rootPart, humanoid)
end

function PlaneEntry:_freefallCamera()
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
end

function PlaneEntry:_handleFreefall(rootPart: BasePart, _humanoid: Humanoid)
    -- Create wind sound
    local windSound = Instance.new("Sound")
    windSound.Name = "WindSound"
    windSound.SoundId = "rbxassetid://5982605124" -- Replace with wind sound
    windSound.Volume = 0.6
    windSound.Looped = true
    windSound.Parent = rootPart
    windSound:Play()
    self._windSound = windSound

    -- Apply downward velocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, -PLANE_CONFIG.freefallSpeed, 0)
    bodyVelocity.Parent = rootPart
    self._bodyVelocity = bodyVelocity

    -- Monitor altitude for auto-parachute
    task.spawn(function()
        while self._phase == "freefall" do
            if rootPart.Position.Y <= PLANE_CONFIG.altitude * 0.3 then
                self:_deployParachute()
                break
            end
            task.wait(0.1)
        end
    end)
end

function PlaneEntry:_deployParachute()
    if self._phase ~= "freefall" then
        return
    end
    self._phase = "parachute"

    local character = player.Character
    if not character then
        return
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then
        return
    end

    -- Reduce wind sound
    if self._windSound then
        TweenService:Create(self._windSound, TweenInfo.new(1), { Volume = 0.2 }):Play()
    end

    -- Create parachute visual
    self._parachute = self:_createParachuteVisual(rootPart)

    -- Slow down descent
    if self._bodyVelocity then
        TweenService:Create(self._bodyVelocity, TweenInfo.new(0.5), {
            Velocity = Vector3.new(0, -PLANE_CONFIG.parachuteSpeed, 0),
        }):Play()
    end

    -- Enable drift controls
    humanoid.WalkSpeed = PLANE_CONFIG.driftSpeed

    -- Update prompt
    if self._jumpLabel then
        self._jumpLabel.Text = "استخدم WASD / الجويستيك للانزلاق"
    end

    -- Monitor landing
    self:_monitorLanding(rootPart, humanoid)
end

function PlaneEntry:_createParachuteVisual(rootPart: BasePart): Model
    local model = Instance.new("Model")
    model.Name = "Parachute"

    -- Canopy
    local canopy = Instance.new("Part")
    canopy.Name = "Canopy"
    canopy.Size = Vector3.new(12, 1, 12)
    canopy.Shape = Enum.PartType.Ball
    canopy.Material = Enum.Material.SmoothPlastic
    canopy.Color = Color3.fromRGB(255, 215, 0)
    canopy.CanCollide = false
    canopy.Anchored = false
    canopy.Parent = model

    -- Scale it to look like a chute
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = Vector3.new(3, 1.5, 3)
    mesh.Parent = canopy

    -- Strings (rope visuals)
    for i = 0, 3 do
        local angle = math.rad(i * 90)
        local rope = Instance.new("Part")
        rope.Name = "Rope_" .. i
        rope.Size = Vector3.new(0.1, 10, 0.1)
        rope.CanCollide = false
        rope.Anchored = false
        rope.Material = Enum.Material.Fabric
        rope.Color = Color3.fromRGB(180, 160, 100)
        rope.Parent = model

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = canopy
        weld.Part1 = rope
        weld.Parent = rope

        rope.CFrame = canopy.CFrame * CFrame.new(math.cos(angle) * 4, -5, math.sin(angle) * 4)
    end

    -- Attach canopy above player
    local attachment = Instance.new("WeldConstraint")
    attachment.Part0 = rootPart
    attachment.Part1 = canopy
    attachment.Parent = canopy

    canopy.CFrame = rootPart.CFrame * CFrame.new(0, 12, 0)

    model.PrimaryPart = canopy
    model.Parent = workspace
    return model
end

function PlaneEntry:_monitorLanding(rootPart: BasePart, humanoid: Humanoid)
    task.spawn(function()
        while self._phase == "parachute" do
            -- Raycast down to check ground distance
            local ray = workspace:Raycast(rootPart.Position, Vector3.new(0, -PLANE_CONFIG.landingThreshold, 0))
            if ray or rootPart.Position.Y <= 5 then
                self:_land(rootPart, humanoid)
                break
            end
            task.wait(0.1)
        end
    end)
end

function PlaneEntry:_land(_rootPart: BasePart, humanoid: Humanoid)
    self._phase = "landed"

    -- Clean up body velocity
    if self._bodyVelocity then
        self._bodyVelocity:Destroy()
        self._bodyVelocity = nil
    end

    -- Clean up wind sound
    if self._windSound then
        TweenService:Create(self._windSound, TweenInfo.new(0.5), { Volume = 0 }):Play()
        task.delay(0.5, function()
            if self._windSound then
                self._windSound:Destroy()
            end
        end)
    end

    -- Destroy parachute with animation
    if self._parachute then
        for _, part in ipairs(self._parachute:GetDescendants()) do
            if part:IsA("BasePart") then
                TweenService:Create(part, TweenInfo.new(1), { Transparency = 1 }):Play()
            end
        end
        task.delay(1.5, function()
            if self._parachute then
                self._parachute:Destroy()
            end
        end)
    end

    -- Restore character movement
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50

    -- Dismiss jump prompt
    if self._jumpGui then
        local frame = self._jumpGui:FindFirstChildWhichIsA("Frame")
        if frame then
            TweenService:Create(frame, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
            }):Play()
        end
        task.delay(0.5, function()
            if self._jumpGui then
                self._jumpGui:Destroy()
            end
        end)
    end

    -- Clean up input handler
    if self._jumpConnection then
        self._jumpConnection:Disconnect()
        self._jumpConnection = nil
    end

    -- Notify server
    RemoteManager:FireServer("PlayerLanded")

    self._active = false
    self._phase = "none"
end

function PlaneEntry:IsActive(): boolean
    return self._active
end

return PlaneEntry
