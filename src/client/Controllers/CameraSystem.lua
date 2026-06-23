--[[
    Arab City - Photography / Camera System
    Players use cameras to take screenshots and publish to Social Network.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local _RunService = game:GetService("RunService")
local _UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CameraSystem = {}
CameraSystem._isActive = false
CameraSystem._cameraType = "Beginner"

function CameraSystem:Init()
    self._gui = self:_buildViewfinder()
    self._gui.Enabled = false
    self._gui.Parent = playerGui

    RemoteManager:OnClientEvent("PhotoTaken", function(photoData)
        self:_onPhotoTaken(photoData)
    end)

    RemoteManager:OnClientEvent("PlayerDataLoaded", function(data)
        if data.cameraType then
            self._cameraType = data.cameraType
        end
    end)
end

function CameraSystem:Activate()
    if self._isActive then
        return
    end
    self._isActive = true
    self._gui.Enabled = true

    self:_updateViewfinder()

    -- Camera mode: lock camera to first person-like view
    self._prevCameraType = workspace.CurrentCamera.CameraType
end

function CameraSystem:Deactivate()
    if not self._isActive then
        return
    end
    self._isActive = false
    self._gui.Enabled = false
end

function CameraSystem:TakePhoto()
    if not self._isActive then
        return
    end

    -- Flash effect
    self:_flashEffect()

    -- Shutter sound
    self:_shutterSound()

    -- Send to server
    local camera = workspace.CurrentCamera
    local photoData = {
        cameraType = self._cameraType,
        position = camera.CFrame.Position,
        lookVector = camera.CFrame.LookVector,
        timestamp = DateTime.now().UnixTimestamp,
    }

    RemoteManager:FireServer("TakePhoto", photoData)
end

function CameraSystem:_buildViewfinder(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_Viewfinder"
    gui.DisplayOrder = 90
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false

    -- Viewfinder overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "ViewfinderOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 90
    overlay.Parent = gui

    -- Corner brackets (viewfinder style)
    local bracketSize = 60
    local bracketThickness = 3
    local brackets = {
        -- Top-left
        { pos = UDim2.new(0.1, 0, 0.1, 0), anchor = Vector2.new(0, 0), sizeH = UDim2.new(0, bracketSize, 0, bracketThickness), sizeV = UDim2.new(0, bracketThickness, 0, bracketSize) },
        -- Top-right
        { pos = UDim2.new(0.9, 0, 0.1, 0), anchor = Vector2.new(1, 0), sizeH = UDim2.new(0, bracketSize, 0, bracketThickness), sizeV = UDim2.new(0, bracketThickness, 0, bracketSize) },
        -- Bottom-left
        { pos = UDim2.new(0.1, 0, 0.9, 0), anchor = Vector2.new(0, 1), sizeH = UDim2.new(0, bracketSize, 0, bracketThickness), sizeV = UDim2.new(0, bracketThickness, 0, bracketSize) },
        -- Bottom-right
        { pos = UDim2.new(0.9, 0, 0.9, 0), anchor = Vector2.new(1, 1), sizeH = UDim2.new(0, bracketSize, 0, bracketThickness), sizeV = UDim2.new(0, bracketThickness, 0, bracketSize) },
    }

    for _, b in ipairs(brackets) do
        local hLine = Instance.new("Frame")
        hLine.Size = b.sizeH
        hLine.Position = b.pos
        hLine.AnchorPoint = b.anchor
        hLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hLine.BackgroundTransparency = 0.3
        hLine.BorderSizePixel = 0
        hLine.ZIndex = 91
        hLine.Parent = overlay

        local vLine = Instance.new("Frame")
        vLine.Size = b.sizeV
        vLine.Position = b.pos
        vLine.AnchorPoint = b.anchor
        vLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        vLine.BackgroundTransparency = 0.3
        vLine.BorderSizePixel = 0
        vLine.ZIndex = 91
        vLine.Parent = overlay
    end

    -- Center crosshair
    local crossH = Instance.new("Frame")
    crossH.Size = UDim2.new(0, 20, 0, 1)
    crossH.Position = UDim2.new(0.5, 0, 0.5, 0)
    crossH.AnchorPoint = Vector2.new(0.5, 0.5)
    crossH.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crossH.BackgroundTransparency = 0.5
    crossH.BorderSizePixel = 0
    crossH.ZIndex = 91
    crossH.Parent = overlay

    local crossV = crossH:Clone()
    crossV.Size = UDim2.new(0, 1, 0, 20)
    crossV.Parent = overlay

    -- Camera info panel (bottom)
    local infoPanel = Instance.new("Frame")
    infoPanel.Name = "InfoPanel"
    infoPanel.Size = UDim2.new(0.4, 0, 0, 40)
    infoPanel.Position = UDim2.new(0.5, 0, 0.92, 0)
    infoPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    infoPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    infoPanel.BackgroundTransparency = 0.5
    infoPanel.BorderSizePixel = 0
    infoPanel.ZIndex = 91
    infoPanel.Parent = overlay

    Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0, 8)

    local cameraLabel = Instance.new("TextLabel")
    cameraLabel.Name = "CameraLabel"
    cameraLabel.Size = UDim2.new(0.6, 0, 1, 0)
    cameraLabel.Position = UDim2.new(0, 10, 0, 0)
    cameraLabel.BackgroundTransparency = 1
    cameraLabel.Text = "📷 كاميرا مبتدئ"
    cameraLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    cameraLabel.Font = Enum.Font.GothamBold
    cameraLabel.TextSize = 13
    cameraLabel.TextXAlignment = Enum.TextXAlignment.Left
    cameraLabel.ZIndex = 92
    cameraLabel.Parent = infoPanel
    self._cameraLabel = cameraLabel

    -- Capture button
    local captureBtn = Instance.new("TextButton")
    captureBtn.Name = "CaptureBtn"
    captureBtn.Size = UDim2.new(0, 50, 0, 50)
    captureBtn.Position = UDim2.new(0.5, 0, 0.82, 0)
    captureBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    captureBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    captureBtn.BorderSizePixel = 0
    captureBtn.Text = ""
    captureBtn.ZIndex = 92
    captureBtn.Parent = overlay

    Instance.new("UICorner", captureBtn).CornerRadius = UDim.new(1, 0)

    local outerRing = Instance.new("UIStroke")
    outerRing.Color = Color3.fromRGB(255, 255, 255)
    outerRing.Thickness = 3
    outerRing.Parent = captureBtn

    captureBtn.MouseButton1Click:Connect(function()
        self:TakePhoto()
    end)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(0.95, 0, 0.05, 0)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.ZIndex = 92
    closeBtn.Parent = overlay

    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

    closeBtn.MouseButton1Click:Connect(function()
        self:Deactivate()
    end)

    -- Flash overlay (for photo capture effect)
    local flash = Instance.new("Frame")
    flash.Name = "Flash"
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flash.BackgroundTransparency = 1
    flash.ZIndex = 100
    flash.Parent = gui
    self._flash = flash

    return gui
end

function CameraSystem:_updateViewfinder()
    local camData = Constants.CAMERAS[self._cameraType]
    if camData and self._cameraLabel then
        self._cameraLabel.Text = "📷 " .. camData.nameAr
    end
end

function CameraSystem:_flashEffect()
    if not self._flash then
        return
    end

    self._flash.BackgroundTransparency = 0.2
    TweenService:Create(self._flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 1,
    }):Play()
end

function CameraSystem:_shutterSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://232127604" -- Replace with shutter click
    sound.Volume = 0.5
    sound.PlayOnRemove = false
    sound.Parent = player.PlayerGui
    sound:Play()

    task.delay(1, function()
        sound:Destroy()
    end)
end

function CameraSystem:_onPhotoTaken(_photoData)
    -- Show confirmation notification
    -- The actual photo is stored server-side
end

function CameraSystem:SetCameraType(cameraType: string)
    self._cameraType = cameraType
    self:_updateViewfinder()
end

return CameraSystem
