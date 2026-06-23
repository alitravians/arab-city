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

function VehicleController:_startSpeedTracking(seat: VehicleSeat)
    if self._speedConnection then
        self._speedConnection:Disconnect()
    end

    self._speedConnection = RunService.Heartbeat:Connect(function()
        if not self._isDriving or not seat or not seat.Parent then
            return
        end

        local velocity = seat.AssemblyLinearVelocity
        local speed = velocity.Magnitude
        local kmh = math.floor(speed * 3.6) -- Convert studs/s to approx km/h

        self._currentSpeed = kmh

        -- Update UI
        if self._speedNumber then
            self._speedNumber.Text = tostring(kmh)
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

return VehicleController
