--[[
    Arab City - Tutorial Controller
    Step-by-step interactive guide for new players
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = Constants.COLORS

local TutorialController = {}
TutorialController._currentStep = 0
TutorialController._gui = nil

function TutorialController:Init()
    self._gui = self:_buildUI()
    self._gui.Parent = playerGui
    self._gui.Enabled = false
end

function TutorialController:Start()
    local data = RemoteManager:InvokeServer("GetPlayerData")
    if data and data.tutorialCompleted then return end

    self._currentStep = 1
    self._gui.Enabled = true
    self:_showStep(1)
end

function TutorialController:_buildUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_Tutorial"
    gui.DisplayOrder = 200
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false

    -- Dim overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.6
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 100
    overlay.Parent = gui

    -- Card
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(0, 420, 0, 260)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = COLORS.Primary
    card.BorderSizePixel = 0
    card.ZIndex = 101
    card.Parent = gui
    self._card = card

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Accent
    stroke.Thickness = 2
    stroke.Parent = card

    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0.5, 0, 0, 25)
    icon.AnchorPoint = Vector2.new(0.5, 0)
    icon.BackgroundTransparency = 1
    icon.Text = ""
    icon.TextSize = 40
    icon.ZIndex = 102
    icon.Parent = card
    self._icon = icon

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0.5, 0, 0, 90)
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.BackgroundTransparency = 1
    title.Text = ""
    title.TextColor3 = COLORS.Accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.ZIndex = 102
    title.Parent = card
    self._title = title

    -- Description
    local desc = Instance.new("TextLabel")
    desc.Name = "Desc"
    desc.Size = UDim2.new(1, -40, 0, 50)
    desc.Position = UDim2.new(0.5, 0, 0, 130)
    desc.AnchorPoint = Vector2.new(0.5, 0)
    desc.BackgroundTransparency = 1
    desc.Text = ""
    desc.TextColor3 = COLORS.Text
    desc.Font = Enum.Font.GothamMedium
    desc.TextSize = 15
    desc.TextWrapped = true
    desc.ZIndex = 102
    desc.Parent = card
    self._desc = desc

    -- Step counter
    local counter = Instance.new("TextLabel")
    counter.Name = "Counter"
    counter.Size = UDim2.new(1, 0, 0, 20)
    counter.Position = UDim2.new(0.5, 0, 0, 185)
    counter.AnchorPoint = Vector2.new(0.5, 0)
    counter.BackgroundTransparency = 1
    counter.Text = ""
    counter.TextColor3 = COLORS.TextDim
    counter.Font = Enum.Font.Gotham
    counter.TextSize = 12
    counter.ZIndex = 102
    counter.Parent = card
    self._counter = counter

    -- Next button
    local nextBtn = Instance.new("TextButton")
    nextBtn.Name = "NextBtn"
    nextBtn.Size = UDim2.new(0, 140, 0, 40)
    nextBtn.Position = UDim2.new(0.5, 0, 1, -20)
    nextBtn.AnchorPoint = Vector2.new(0.5, 1)
    nextBtn.BackgroundColor3 = COLORS.Accent
    nextBtn.BorderSizePixel = 0
    nextBtn.Text = "التالي"
    nextBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.TextSize = 16
    nextBtn.ZIndex = 102
    nextBtn.Parent = card

    Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 10)

    nextBtn.MouseButton1Click:Connect(function()
        self:_nextStep()
    end)
    self._nextBtn = nextBtn

    -- Skip button
    local skipBtn = Instance.new("TextButton")
    skipBtn.Name = "SkipBtn"
    skipBtn.Size = UDim2.new(0, 80, 0, 30)
    skipBtn.Position = UDim2.new(1, -15, 0, 10)
    skipBtn.AnchorPoint = Vector2.new(1, 0)
    skipBtn.BackgroundTransparency = 1
    skipBtn.Text = "تخطي"
    skipBtn.TextColor3 = COLORS.TextDim
    skipBtn.Font = Enum.Font.Gotham
    skipBtn.TextSize = 13
    skipBtn.ZIndex = 102
    skipBtn.Parent = card

    skipBtn.MouseButton1Click:Connect(function()
        self:_finish()
    end)

    return gui
end

function TutorialController:_showStep(stepNum: number)
    local steps = Constants.TUTORIAL_STEPS
    if stepNum > #steps then
        self:_finish()
        return
    end

    local step = steps[stepNum]
    self._icon.Text = step.icon
    self._title.Text = step.titleAr
    self._desc.Text = step.descAr
    self._counter.Text = stepNum .. " / " .. #steps

    if stepNum == #steps then
        self._nextBtn.Text = "ابدأ اللعب!"
        self._nextBtn.BackgroundColor3 = COLORS.Success
    else
        self._nextBtn.Text = "التالي"
        self._nextBtn.BackgroundColor3 = COLORS.Accent
    end

    -- Animate card entrance
    self._card.Size = UDim2.new(0, 380, 0, 230)
    self._card.BackgroundTransparency = 0.3
    TweenService:Create(self._card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 420, 0, 260),
        BackgroundTransparency = 0,
    }):Play()
end

function TutorialController:_nextStep()
    self._currentStep = self._currentStep + 1
    self:_showStep(self._currentStep)
end

function TutorialController:_finish()
    TweenService:Create(self._card, TweenInfo.new(0.2), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 380, 0, 230),
    }):Play()

    task.delay(0.25, function()
        self._gui.Enabled = false
    end)

    RemoteManager:FireServer("TutorialComplete")
end

return TutorialController
