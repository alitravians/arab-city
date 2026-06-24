--[[
    Arab City - Vehicle Controller (Client)
    Speedometer HUD, engine sounds, headlights control
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local _UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local _Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local VehicleController = {}
VehicleController._isDriving = false
VehicleController._currentSpeed = 0
VehicleController._currentGear = 1
VehicleController._rpm = 0
VehicleController._lastVelocity = Vector3.zero

function VehicleController:Init()
    self._gui = self:_buildSpeedometerUI()
    self._gui.Enabled = false
    self._gui.Parent = playerGui

    -- Detect when player sits in a vehicle
    player.CharacterAdded:Connect(function(character)
        task.wait(1)
        self:_setupSeatDetection(character)
    end)

    if player.Character then
        self:_setupSeatDetection(player.Character)
    end

    RemoteManager:OnClientEvent("VehicleUpdate", function(action, _vehicleId)
        if action == "despawned" then
            self:_hideSpeedometer()
        end
    end)
end

function VehicleController:_setupSeatDetection(character: Model)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        return
    end

    humanoid.Seated:Connect(function(isSeated, seat)
        if isSeated and seat and seat:IsA("VehicleSeat") then
            self:_onEnterVehicle(seat)
        else
            self:_onExitVehicle()
        end
    end)
end

function VehicleController:_onEnterVehicle(seat: VehicleSeat)
    self._isDriving = true
    self._currentSeat = seat
    self:_showSpeedometer()
    self:_startSpeedTracking(seat)
    self:_playEngineSound(seat)
end

function VehicleController:_onExitVehicle()
    self._isDriving = false
    self._currentSeat = nil
    self:_hideSpeedometer()
    self:_stopSpeedTracking()
    self:_stopEngineSound()
end

function VehicleController:_buildSpeedometerUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_Speedometer"
    gui.DisplayOrder = 15
    gui.ResetOnSpawn = false

    -- Speedometer frame (bottom-right)
    local frame = Instance.new("Frame")
    frame.Name = "SpeedFrame"
    frame.Size = UDim2.new(0, 180, 0, 80)
    frame.Position = UDim2.new(1, -20, 1, -80)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.ZIndex = 30
    frame.Parent = gui
    self._speedFrame = frame

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 170, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = frame

    -- Speed number
    local speedNumber = Instance.new("TextLabel")
    speedNumber.Name = "SpeedNumber"
    speedNumber.Size = UDim2.new(0.7, 0, 0.6, 0)
    speedNumber.Position = UDim2.new(0, 10, 0, 5)
    speedNumber.BackgroundTransparency = 1
    speedNumber.Text = "0"
    speedNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedNumber.Font = Enum.Font.GothamBlack
    speedNumber.TextSize = 36
    speedNumber.TextXAlignment = Enum.TextXAlignment.Left
    speedNumber.ZIndex = 31
    speedNumber.Parent = frame
    self._speedNumber = speedNumber

    -- KM/H label
    local unitLabel = Instance.new("TextLabel")
    unitLabel.Size = UDim2.new(0.3, 0, 0.3, 0)
    unitLabel.Position = UDim2.new(0.7, 0, 0, 15)
    unitLabel.BackgroundTransparency = 1
    unitLabel.Text = "KM/H"
    unitLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
    unitLabel.Font = Enum.Font.GothamBold
    unitLabel.TextSize = 12
    unitLabel.ZIndex = 31
    unitLabel.Parent = frame

    -- Speed bar
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0.9, 0, 0, 6)
    barBg.Position = UDim2.new(0.5, 0, 0.75, 0)
    barBg.AnchorPoint = Vector2.new(0.5, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 31
    barBg.Parent = frame

    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 3)

    local barFill = Instance.new("Frame")
    barFill.Name = "SpeedBar"
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 32
    barFill.Parent = barBg

    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 3)

    local barGradient = Instance.new("UIGradient")
    barGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 100)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50)),
    })
    barGradient.Parent = barFill

    self._speedBar = barFill

    -- Vehicle name
    local vehicleName = Instance.new("TextLabel")
    vehicleName.Name = "VehicleName"
    vehicleName.Size = UDim2.new(0.9, 0, 0, 15)
    vehicleName.Position = UDim2.new(0.5, 0, 0.9, 0)
    vehicleName.AnchorPoint = Vector2.new(0.5, 0)
    vehicleName.BackgroundTransparency = 1
    vehicleName.Text = ""
    vehicleName.TextColor3 = Color3.fromRGB(150, 150, 160)
    vehicleName.Font = Enum.Font.Gotham
    vehicleName.TextSize = 10
    vehicleName.ZIndex = 31
    vehicleName.Parent = frame
    self._vehicleNameLabel = vehicleName

    -- Gear indicator
    local gearLabel = Instance.new("TextLabel")
    gearLabel.Name = "GearLabel"
    gearLabel.Size = UDim2.new(0.25, 0, 0.35, 0)
    gearLabel.Position = UDim2.new(0.75, 0, 0.35, 0)
    gearLabel.BackgroundTransparency = 1
    gearLabel.Text = "G1"
    gearLabel.TextColor3 = Color3.fromRGB(0, 200, 130)
    gearLabel.Font = Enum.Font.GothamBold
    gearLabel.TextSize = 16
    gearLabel.ZIndex = 31
    gearLabel.Parent = frame
    self._gearLabel = gearLabel

    -- RPM bar (below speed bar)
    local rpmBg = Instance.new("Frame")
    rpmBg.Size = UDim2.new(0.9, 0, 0, 4)
    rpmBg.Position = UDim2.new(0.5, 0, 0.85, 0)
    rpmBg.AnchorPoint = Vector2.new(0.5, 0)
    rpmBg.BackgroundColor3 = Color3.fromRGB(40, 30, 30)
    rpmBg.BorderSizePixel = 0
    rpmBg.ZIndex = 31
    rpmBg.Parent = frame
    Instance.new("UICorner", rpmBg).CornerRadius = UDim.new(0, 2)

    local rpmFill = Instance.new("Frame")
    rpmFill.Name = "RPMBar"
    rpmFill.Size = UDim2.new(0, 0, 1, 0)
    rpmFill.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    rpmFill.BorderSizePixel = 0
    rpmFill.ZIndex = 32
    rpmFill.Parent = rpmBg
    Instance.new("UICorner", rpmFill).CornerRadius = UDim.new(0, 2)
    self._rpmBar = rpmFill

    -- Controls hint
    local controls = Instance.new("TextLabel")
    controls.Size = UDim2.new(0, 180, 0, 20)
    controls.Position = UDim2.new(1, -20, 1, -5)
    controls.AnchorPoint = Vector2.new(1, 1)
    controls.BackgroundTransparency = 1
    controls.Text = "WASD للقيادة | F للنزول"
    controls.TextColor3 = Color3.fromRGB(100, 100, 110)
    controls.Font = Enum.Font.Gotham
    controls.TextSize = 10
    controls.TextXAlignment = Enum.TextXAlignment.Right
    controls.ZIndex = 30
    controls.Parent = gui
    self._controlsHint = controls

    return gui
end

function VehicleController:_showSpeedometer()
    self._gui.Enabled = true
    self._speedFrame.Position = UDim2.new(1, 20, 1, -80)
    TweenService:Create(self._speedFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -20, 1, -80),
    }):Play()
end

function VehicleController:_hideSpeedometer()
    TweenService:Create(self._speedFrame, TweenInfo.new(0.2), {
        Position = UDim2.new(1, 20, 1, -80),
    }):Play()
    task.delay(0.2, function()
        if not self._isDriving then
            self._gui.Enabled = false
        end
    end)
end

-- Gear thresholds (km/h) for automatic transmission
local GEAR_SPEEDS = { 0, 20, 45, 80, 120, 180 }
local GEAR_COUNT = #GEAR_SPEEDS

local function getGear(kmh: number): number
    local gear = 1
    for i = GEAR_COUNT, 1, -1 do
        if kmh >= GEAR_SPEEDS[i] then
            gear = i
            break
        end
    end
    return gear
end

local function getRPM(kmh: number, gear: number): number
    local low = GEAR_SPEEDS[gear] or 0
    local high = GEAR_SPEEDS[gear + 1] or (low + 60)
    local range = high - low
    if range <= 0 then return 0.3 end
    return math.clamp((kmh - low) / range, 0.15, 1)
end

function VehicleController:_startSpeedTracking(seat: VehicleSeat)
    if self._speedConnection then
        self._speedConnection:Disconnect()
    end

    self._lastVelocity = Vector3.zero

    self._speedConnection = RunService.Heartbeat:Connect(function(dt)
        if not self._isDriving or not seat or not seat.Parent then
            return
        end

        local velocity = seat.AssemblyLinearVelocity
        local speed = velocity.Magnitude
        local kmh = math.floor(speed * 3.6)

        -- Deceleration detection (for brake lights / tire screech)
        local decel = (self._lastVelocity.Magnitude - velocity.Magnitude) / math.max(dt, 0.001)
        self._lastVelocity = velocity

        -- Gear and RPM
        local gear = getGear(kmh)
        local rpm = getRPM(kmh, gear)
        self._currentGear = gear
        self._rpm = rpm
        self._currentSpeed = kmh

        -- Dynamic engine sound pitch based on RPM
        if self._engineSound and self._engineSound.Parent then
            local targetPitch = 0.6 + rpm * 0.8
            self._engineSound.PlaybackSpeed = targetPitch
            self._engineSound.Volume = 0.2 + rpm * 0.25
        end

        -- Tire screech on hard braking
        if decel > 25 and kmh > 15 then
            self:_playTireScreech(seat)
        end

        -- Update UI
        if self._speedNumber then
            self._speedNumber.Text = tostring(kmh)
        end

        if self._gearLabel then
            self._gearLabel.Text = "G" .. tostring(gear)
        end

        if self._rpmBar then
            TweenService:Create(self._rpmBar, TweenInfo.new(0.1), {
                Size = UDim2.new(rpm, 0, 1, 0),
            }):Play()
        end

        -- Update speed bar
        local maxSpeed = seat.MaxSpeed or 100
        local ratio = math.clamp(speed / maxSpeed, 0, 1)
        if self._speedBar then
            TweenService:Create(self._speedBar, TweenInfo.new(0.1), {
                Size = UDim2.new(ratio, 0, 1, 0),
            }):Play()
        end

        -- Color speed number based on speed
        if self._speedNumber then
            if ratio > 0.8 then
                self._speedNumber.TextColor3 = Color3.fromRGB(255, 80, 80)
            elseif ratio > 0.5 then
                self._speedNumber.TextColor3 = Color3.fromRGB(255, 200, 0)
            else
                self._speedNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
    end)
end

function VehicleController:_stopSpeedTracking()
    if self._speedConnection then
        self._speedConnection:Disconnect()
        self._speedConnection = nil
    end
end

function VehicleController:_playEngineSound(seat: VehicleSeat)
    local vehicleModel = seat.Parent
    if not vehicleModel then
        return
    end

    -- Check if engine sound already exists
    local existing = vehicleModel:FindFirstChild("EngineSound")
    if existing then
        existing:Play()
        return
    end

    local sound = Instance.new("Sound")
    sound.Name = "EngineSound"
    sound.SoundId = "rbxassetid://9125402735" -- Replace with engine sound
    sound.Volume = 0.3
    sound.Looped = true
    sound.Parent = vehicleModel.PrimaryPart or seat
    sound:Play()
    self._engineSound = sound
end

function VehicleController:_stopEngineSound()
    if self._engineSound and self._engineSound.Parent then
        local sound = self._engineSound
        self._engineSound = nil
        TweenService:Create(sound, TweenInfo.new(0.5), { Volume = 0 }):Play()
        task.delay(0.5, function()
            if sound and sound.Parent then
                sound:Stop()
                sound:Destroy()
            end
        end)
    else
        self._engineSound = nil
    end
end

function VehicleController:_playTireScreech(seat: VehicleSeat)
    if self._screechCooldown and os.clock() - self._screechCooldown < 2 then
        return
    end
    self._screechCooldown = os.clock()

    local parent = seat.Parent
    if not parent then return end
    local target = (parent :: Model):FindFirstChildWhichIsA("BasePart") or seat

    local screech = Instance.new("Sound")
    screech.Name = "TireScreech"
    screech.SoundId = "rbxassetid://9125402735"
    screech.Volume = 0.15
    screech.PlaybackSpeed = 1.8
    screech.Parent = target
    screech:Play()
    task.delay(1.5, function()
        if screech and screech.Parent then
            screech:Destroy()
        end
    end)
end

return VehicleController
