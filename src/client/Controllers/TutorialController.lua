--[[
    Arab City v2.0 - TutorialController
    Step-by-step interactive tutorial for new players.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TutorialController = {}

local Shared, Constants
local player = Players.LocalPlayer

local STEPS = {
    { title = "مرحباً بك في Arab City!", message = "هذي مدينة عربية مفتوحة — تقدر تشتغل، تشتري سيارات، تملك بيوت، وأكثر!", icon = "🏙️" },
    { title = "الوظائف", message = "تقدر تتقدم لوظيفة من المباني (شرطي، طبيب، سائق...) وتجمع راتب كل 5 دقايق.", icon = "💼" },
    { title = "المتجر", message = "اشتري أدوات وملابس من المول — افتح المتجر من قائمة الهاتف.", icon = "🛒" },
    { title = "العقارات", message = "اشتري بيوت وشقق وفلل — كل عقار له سعر مختلف.", icon = "🏠" },
    { title = "السيارات", message = "توجه لمعرض السيارات واشتري سيارتك الأولى!", icon = "🚗" },
    { title = "الدردشة", message = "اضغط على أيقونة 💬 للدردشة مع اللاعبين — عامة أو خاصة.", icon = "💬" },
    { title = "استمتع!", message = "هذي بس البداية — فيه مهمات، إنجازات، حيوانات أليفة، وأكثر بكثير!", icon = "⭐" },
}

function TutorialController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants

    task.spawn(function()
        task.wait(5)
        self:_start()
    end)
end

function TutorialController:_start()
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "TutorialGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 200
    gui.Parent = player:WaitForChild("PlayerGui")

    self._gui = gui
    self._stepIndex = 1
    self:_showStep()
end

function TutorialController:_showStep()
    local step = STEPS[self._stepIndex]
    if not step then
        if self._gui then self._gui:Destroy() end
        return
    end

    local colors = Constants.UI_COLORS

    -- Clear previous
    for _, child in ipairs(self._gui:GetChildren()) do
        child:Destroy()
    end

    -- Overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.6
    overlay.BorderSizePixel = 0
    overlay.Parent = self._gui

    -- Card
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 420, 0, 220)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = colors.background
    card.BorderSizePixel = 0
    card.Parent = self._gui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local cStroke = Instance.new("UIStroke")
    cStroke.Color = colors.accent
    cStroke.Thickness = 2
    cStroke.Parent = card

    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 50, 0, 50)
    icon.Position = UDim2.new(0.5, 0, 0, 15)
    icon.AnchorPoint = Vector2.new(0.5, 0)
    icon.BackgroundTransparency = 1
    icon.Text = step.icon
    icon.TextSize = 36
    icon.Font = Enum.Font.GothamBold
    icon.Parent = card

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 30)
    title.Position = UDim2.new(0, 15, 0, 70)
    title.BackgroundTransparency = 1
    title.Text = step.title
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = colors.accent
    title.Parent = card

    -- Message
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -30, 0, 50)
    msg.Position = UDim2.new(0, 15, 0, 105)
    msg.BackgroundTransparency = 1
    msg.Text = step.message
    msg.TextSize = 15
    msg.Font = Enum.Font.Gotham
    msg.TextColor3 = colors.text
    msg.TextWrapped = true
    msg.Parent = card

    -- Progress
    local progress = Instance.new("TextLabel")
    progress.Size = UDim2.new(0, 100, 0, 20)
    progress.Position = UDim2.new(0, 15, 1, -35)
    progress.BackgroundTransparency = 1
    progress.Text = self._stepIndex .. " / " .. #STEPS
    progress.TextSize = 12
    progress.Font = Enum.Font.Gotham
    progress.TextColor3 = colors.textDim
    progress.TextXAlignment = Enum.TextXAlignment.Left
    progress.Parent = card

    -- Next / Skip buttons
    local nextBtn = Instance.new("TextButton")
    nextBtn.Size = UDim2.new(0, 100, 0, 34)
    nextBtn.Position = UDim2.new(1, -115, 1, -42)
    nextBtn.BackgroundColor3 = colors.accent
    nextBtn.Text = if self._stepIndex == #STEPS then "ابدأ!" else "التالي →"
    nextBtn.TextSize = 14
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.TextColor3 = Color3.new(1, 1, 1)
    nextBtn.BorderSizePixel = 0
    nextBtn.Parent = card
    Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 6)

    local skipBtn = Instance.new("TextButton")
    skipBtn.Size = UDim2.new(0, 60, 0, 34)
    skipBtn.Position = UDim2.new(1, -185, 1, -42)
    skipBtn.BackgroundTransparency = 1
    skipBtn.Text = "تخطي"
    skipBtn.TextSize = 13
    skipBtn.Font = Enum.Font.Gotham
    skipBtn.TextColor3 = colors.textDim
    skipBtn.Parent = card

    nextBtn.MouseButton1Click:Connect(function()
        self._stepIndex = self._stepIndex + 1
        self:_showStep()
    end)

    skipBtn.MouseButton1Click:Connect(function()
        if self._gui then self._gui:Destroy() end
    end)
end

return TutorialController
