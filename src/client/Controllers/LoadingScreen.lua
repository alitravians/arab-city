--[[
    Arab City - Professional Cinematic Loading Screen
    Features:
    - Animated gradient background with particle effects
    - Glowing gold logo with pulse animation
    - Neon-gradient progress bar with glow
    - Smooth tip cycling with fade transitions
    - Update notes panel
    - Welcome music
    - Cinematic dismiss animation (fade + scale + blur)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local _RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants

local LoadingScreen = {}

-- Configuration
local CONFIG = {
    tipCycleTime = 4,
    minLoadTime = 5,
    logoText = "ARAB CITY",
    subtitleText = "عالمك المفتوح",
    versionText = "v" .. Constants.VERSION,
    musicId = "rbxassetid://1837849285", -- Replace with actual ambient music
    updates = {
        "نظام Social Network الجديد!",
        "سيارات وعقارات جديدة",
        "نظام الوظائف والمهمات",
        "تأثيرات دخول لأصحاب الرتب",
        "نظام الشهرة والمتابعين",
    },
}

-- Midnight Blue Neon Theme (approved by user)
local COLORS = {
    bgDark = Color3.fromRGB(2, 4, 18),
    bgMid = Color3.fromRGB(5, 8, 30),
    accent = Color3.fromRGB(80, 170, 255),
    accentDim = Color3.fromRGB(50, 120, 200),
    accentBright = Color3.fromRGB(120, 200, 255),
    neonBlue = Color3.fromRGB(0, 150, 255),
    neonCyan = Color3.fromRGB(0, 230, 255),
    neonPink = Color3.fromRGB(255, 0, 100),
    white = Color3.fromRGB(255, 255, 255),
    whiteDim = Color3.fromRGB(180, 190, 210),
    barBg = Color3.fromRGB(10, 15, 35),
    panelBg = Color3.fromRGB(5, 8, 22),
    accentLine = Color3.fromRGB(80, 170, 255),
    moonGlow = Color3.fromRGB(100, 140, 200),
    windowLight = Color3.fromRGB(100, 180, 255),
}

function LoadingScreen:Show()
    -- Disable default Roblox loading screen
    local _success = pcall(function()
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    end)

    self._gui = self:_buildUI()
    self._gui.Parent = playerGui

    -- Start animations
    self:_animateBackground()
    self:_animateParticles()
    self:_animateLogo()
    self:_animateProgressGlow()
    self:_cycleTips()
    self:_playMusic()

    -- Pre-load assets
    self:_preloadAssets()
end

function LoadingScreen:_buildUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_LoadingScreen"
    gui.DisplayOrder = 999
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false

    -- ═══════════════════════════════════════
    -- BACKGROUND LAYER
    -- ═══════════════════════════════════════
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = COLORS.bgDark
    bg.BorderSizePixel = 0
    bg.Parent = gui
    self._bg = bg

    -- Midnight Blue gradient overlay
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(2, 4, 18)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(5, 10, 35)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(8, 15, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 4, 18)),
    })
    bgGradient.Rotation = 45
    bgGradient.Parent = bg
    self._bgGradient = bgGradient

    -- Vignette overlay
    local vignette = Instance.new("ImageLabel")
    vignette.Name = "Vignette"
    vignette.Size = UDim2.new(1, 0, 1, 0)
    vignette.BackgroundTransparency = 1
    vignette.Image = "rbxassetid://1749612826" -- radial gradient
    vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
    vignette.ImageTransparency = 0.3
    vignette.ZIndex = 2
    vignette.Parent = bg

    -- ═══════════════════════════════════════
    -- PARTICLE CONTAINER
    -- ═══════════════════════════════════════
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "Particles"
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.ZIndex = 3
    particleContainer.ClipsDescendants = true
    particleContainer.Parent = bg
    self._particleContainer = particleContainer

    -- ═══════════════════════════════════════
    -- MAIN CONTENT FRAME (centered)
    -- ═══════════════════════════════════════
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.ZIndex = 10
    content.Parent = gui
    self._content = content

    -- ═══════════════════════════════════════
    -- LOGO SECTION (upper area)
    -- ═══════════════════════════════════════
    local logoContainer = Instance.new("Frame")
    logoContainer.Name = "LogoContainer"
    logoContainer.Size = UDim2.new(1, 0, 0, 180)
    logoContainer.Position = UDim2.new(0, 0, 0.22, 0)
    logoContainer.AnchorPoint = Vector2.new(0, 0)
    logoContainer.BackgroundTransparency = 1
    logoContainer.ZIndex = 11
    logoContainer.Parent = content

    -- Decorative top line
    local topLine = Instance.new("Frame")
    topLine.Name = "TopLine"
    topLine.Size = UDim2.new(0.3, 0, 0, 2)
    topLine.Position = UDim2.new(0.5, 0, 0, 0)
    topLine.AnchorPoint = Vector2.new(0.5, 0)
    topLine.BackgroundColor3 = COLORS.accent
    topLine.BorderSizePixel = 0
    topLine.ZIndex = 12
    topLine.Parent = logoContainer

    local topLineGradient = Instance.new("UIGradient")
    topLineGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.3, 0),
        NumberSequenceKeypoint.new(0.7, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    topLineGradient.Parent = topLine

    -- Main logo text
    local logoText = Instance.new("TextLabel")
    logoText.Name = "LogoText"
    logoText.Size = UDim2.new(1, 0, 0, 80)
    logoText.Position = UDim2.new(0.5, 0, 0, 20)
    logoText.AnchorPoint = Vector2.new(0.5, 0)
    logoText.BackgroundTransparency = 1
    logoText.Text = CONFIG.logoText
    logoText.TextColor3 = COLORS.white
    logoText.Font = Enum.Font.GothamBlack
    logoText.TextSize = 72
    logoText.ZIndex = 12
    logoText.Parent = logoContainer
    self._logoText = logoText

    -- Logo glow (duplicate behind with larger size for glow effect)
    local logoGlow = Instance.new("TextLabel")
    logoGlow.Name = "LogoGlow"
    logoGlow.Size = UDim2.new(1, 0, 0, 80)
    logoGlow.Position = UDim2.new(0.5, 0, 0, 20)
    logoGlow.AnchorPoint = Vector2.new(0.5, 0)
    logoGlow.BackgroundTransparency = 1
    logoGlow.Text = CONFIG.logoText
    logoGlow.TextColor3 = COLORS.accentBright
    logoGlow.TextTransparency = 0.6
    logoGlow.Font = Enum.Font.GothamBlack
    logoGlow.TextSize = 76
    logoGlow.ZIndex = 11
    logoGlow.Parent = logoContainer
    self._logoGlow = logoGlow

    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 30)
    subtitle.Position = UDim2.new(0.5, 0, 0, 105)
    subtitle.AnchorPoint = Vector2.new(0.5, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = CONFIG.subtitleText
    subtitle.TextColor3 = COLORS.whiteDim
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 22
    subtitle.TextTransparency = 0.2
    subtitle.ZIndex = 12
    subtitle.Parent = logoContainer

    -- Bottom decorative line
    local bottomLine = topLine:Clone()
    bottomLine.Name = "BottomLine"
    bottomLine.Position = UDim2.new(0.5, 0, 0, 150)
    bottomLine.Parent = logoContainer

    -- ═══════════════════════════════════════
    -- PROGRESS BAR SECTION (lower-center)
    -- ═══════════════════════════════════════
    local progressSection = Instance.new("Frame")
    progressSection.Name = "ProgressSection"
    progressSection.Size = UDim2.new(0.5, 0, 0, 80)
    progressSection.Position = UDim2.new(0.5, 0, 0.62, 0)
    progressSection.AnchorPoint = Vector2.new(0.5, 0)
    progressSection.BackgroundTransparency = 1
    progressSection.ZIndex = 11
    progressSection.Parent = content

    -- Progress percentage text
    local progressPercent = Instance.new("TextLabel")
    progressPercent.Name = "ProgressPercent"
    progressPercent.Size = UDim2.new(1, 0, 0, 25)
    progressPercent.Position = UDim2.new(0.5, 0, 0, 0)
    progressPercent.AnchorPoint = Vector2.new(0.5, 0)
    progressPercent.BackgroundTransparency = 1
    progressPercent.Text = "0%"
    progressPercent.TextColor3 = COLORS.accent
    progressPercent.Font = Enum.Font.GothamBold
    progressPercent.TextSize = 20
    progressPercent.ZIndex = 12
    progressPercent.Parent = progressSection
    self._progressPercent = progressPercent

    -- Progress bar background
    local barBg = Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.Size = UDim2.new(1, 0, 0, 6)
    barBg.Position = UDim2.new(0.5, 0, 0, 32)
    barBg.AnchorPoint = Vector2.new(0.5, 0)
    barBg.BackgroundColor3 = COLORS.barBg
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 12
    barBg.Parent = progressSection

    local barBgCorner = Instance.new("UICorner")
    barBgCorner.CornerRadius = UDim.new(0, 3)
    barBgCorner.Parent = barBg

    -- Progress bar fill
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = COLORS.accent
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 13
    barFill.Parent = barBg
    self._barFill = barFill

    local barFillCorner = Instance.new("UICorner")
    barFillCorner.CornerRadius = UDim.new(0, 3)
    barFillCorner.Parent = barFill

    -- Bar gradient (midnight blue neon effect)
    local barGradient = Instance.new("UIGradient")
    barGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.neonBlue),
        ColorSequenceKeypoint.new(0.5, COLORS.accentBright),
        ColorSequenceKeypoint.new(1, COLORS.neonCyan),
    })
    barGradient.Parent = barFill
    self._barGradient = barGradient

    -- Bar glow (behind the bar)
    local barGlow = Instance.new("Frame")
    barGlow.Name = "BarGlow"
    barGlow.Size = UDim2.new(0, 0, 1, 8)
    barGlow.Position = UDim2.new(0, 0, 0.5, 0)
    barGlow.AnchorPoint = Vector2.new(0, 0.5)
    barGlow.BackgroundColor3 = COLORS.neonCyan
    barGlow.BackgroundTransparency = 0.7
    barGlow.BorderSizePixel = 0
    barGlow.ZIndex = 11
    barGlow.Parent = barBg
    self._barGlow = barGlow

    local barGlowCorner = Instance.new("UICorner")
    barGlowCorner.CornerRadius = UDim.new(0, 6)
    barGlowCorner.Parent = barGlow

    -- Loading status text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 0, 20)
    statusText.Position = UDim2.new(0.5, 0, 0, 45)
    statusText.AnchorPoint = Vector2.new(0.5, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "جاري تحميل الموارد..."
    statusText.TextColor3 = COLORS.whiteDim
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 14
    statusText.TextTransparency = 0.3
    statusText.ZIndex = 12
    statusText.Parent = progressSection
    self._statusText = statusText

    -- ═══════════════════════════════════════
    -- TIPS SECTION (below progress bar)
    -- ═══════════════════════════════════════
    local tipContainer = Instance.new("Frame")
    tipContainer.Name = "TipContainer"
    tipContainer.Size = UDim2.new(0.6, 0, 0, 50)
    tipContainer.Position = UDim2.new(0.5, 0, 0.75, 0)
    tipContainer.AnchorPoint = Vector2.new(0.5, 0)
    tipContainer.BackgroundTransparency = 1
    tipContainer.ZIndex = 11
    tipContainer.Parent = content

    local tipIcon = Instance.new("TextLabel")
    tipIcon.Name = "TipIcon"
    tipIcon.Size = UDim2.new(0, 20, 0, 20)
    tipIcon.Position = UDim2.new(0.5, -160, 0, 0)
    tipIcon.AnchorPoint = Vector2.new(0.5, 0)
    tipIcon.BackgroundTransparency = 1
    tipIcon.Text = "💡"
    tipIcon.TextSize = 16
    tipIcon.ZIndex = 12
    tipIcon.Parent = tipContainer

    local tipLabel = Instance.new("TextLabel")
    tipLabel.Name = "TipLabel"
    tipLabel.Size = UDim2.new(0.9, 0, 0, 20)
    tipLabel.Position = UDim2.new(0.5, 0, 0, 0)
    tipLabel.AnchorPoint = Vector2.new(0.5, 0)
    tipLabel.BackgroundTransparency = 1
    tipLabel.Text = ""
    tipLabel.TextColor3 = COLORS.whiteDim
    tipLabel.Font = Enum.Font.GothamMedium
    tipLabel.TextSize = 15
    tipLabel.TextTransparency = 1
    tipLabel.ZIndex = 12
    tipLabel.Parent = tipContainer
    self._tipLabel = tipLabel

    -- ═══════════════════════════════════════
    -- UPDATES PANEL (bottom-left)
    -- ═══════════════════════════════════════
    local updatesPanel = Instance.new("Frame")
    updatesPanel.Name = "UpdatesPanel"
    updatesPanel.Size = UDim2.new(0.25, 0, 0, 140)
    updatesPanel.Position = UDim2.new(0.03, 0, 0.88, 0)
    updatesPanel.AnchorPoint = Vector2.new(0, 1)
    updatesPanel.BackgroundColor3 = COLORS.panelBg
    updatesPanel.BackgroundTransparency = 0.4
    updatesPanel.BorderSizePixel = 0
    updatesPanel.ZIndex = 11
    updatesPanel.Parent = content

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 8)
    panelCorner.Parent = updatesPanel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = COLORS.accent
    panelStroke.Thickness = 1
    panelStroke.Transparency = 0.7
    panelStroke.Parent = updatesPanel

    local updatesTitle = Instance.new("TextLabel")
    updatesTitle.Name = "UpdatesTitle"
    updatesTitle.Size = UDim2.new(1, -16, 0, 25)
    updatesTitle.Position = UDim2.new(0, 8, 0, 5)
    updatesTitle.BackgroundTransparency = 1
    updatesTitle.Text = "📋 آخر التحديثات"
    updatesTitle.TextColor3 = COLORS.accent
    updatesTitle.Font = Enum.Font.GothamBold
    updatesTitle.TextSize = 14
    updatesTitle.TextXAlignment = Enum.TextXAlignment.Right
    updatesTitle.ZIndex = 12
    updatesTitle.Parent = updatesPanel

    local updatesList = Instance.new("Frame")
    updatesList.Name = "UpdatesList"
    updatesList.Size = UDim2.new(1, -16, 1, -35)
    updatesList.Position = UDim2.new(0, 8, 0, 32)
    updatesList.BackgroundTransparency = 1
    updatesList.ZIndex = 12
    updatesList.Parent = updatesPanel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 3)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = updatesList

    for i, update in ipairs(CONFIG.updates) do
        local item = Instance.new("TextLabel")
        item.Name = "Update_" .. i
        item.Size = UDim2.new(1, 0, 0, 18)
        item.BackgroundTransparency = 1
        item.Text = "• " .. update
        item.TextColor3 = COLORS.whiteDim
        item.Font = Enum.Font.Gotham
        item.TextSize = 12
        item.TextXAlignment = Enum.TextXAlignment.Right
        item.TextTransparency = 0.2
        item.LayoutOrder = i
        item.ZIndex = 13
        item.Parent = updatesList
    end

    -- ═══════════════════════════════════════
    -- VERSION (bottom-right)
    -- ═══════════════════════════════════════
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Name = "Version"
    versionLabel.Size = UDim2.new(0, 100, 0, 20)
    versionLabel.Position = UDim2.new(0.97, 0, 0.96, 0)
    versionLabel.AnchorPoint = Vector2.new(1, 1)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = CONFIG.versionText
    versionLabel.TextColor3 = COLORS.whiteDim
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextSize = 12
    versionLabel.TextTransparency = 0.5
    versionLabel.TextXAlignment = Enum.TextXAlignment.Right
    versionLabel.ZIndex = 12
    versionLabel.Parent = content

    return gui
end

-- ═══════════════════════════════════════════
-- ANIMATIONS
-- ═══════════════════════════════════════════

function LoadingScreen:_animateBackground()
    task.spawn(function()
        local rotation = 0
        while self._gui and self._gui.Parent do
            rotation += 0.3
            if rotation >= 360 then
                rotation -= 360
            end
            self._bgGradient.Rotation = rotation
            task.wait(0.05)
        end
    end)
end

function LoadingScreen:_animateParticles()
    task.spawn(function()
        while self._gui and self._gui.Parent do
            -- Spawn a floating particle
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5))
            particle.Position = UDim2.new(math.random() * 1, 0, 1.05, 0)
            particle.AnchorPoint = Vector2.new(0.5, 0.5)
            particle.BackgroundColor3 = math.random() > 0.5 and COLORS.accent or COLORS.neonCyan
            particle.BackgroundTransparency = math.random() * 0.4 + 0.4
            particle.BorderSizePixel = 0
            particle.ZIndex = 4
            particle.Parent = self._particleContainer

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = particle

            -- Float upward with slight drift
            local drift = math.random(-100, 100) / 1000
            local duration = math.random(40, 80) / 10

            local tween = TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                Position = UDim2.new(particle.Position.X.Scale + drift, 0, -0.1, 0),
                BackgroundTransparency = 1,
            })
            tween:Play()
            tween.Completed:Connect(function()
                particle:Destroy()
            end)

            task.wait(math.random(1, 3) / 10)
        end
    end)
end

function LoadingScreen:_animateLogo()
    task.spawn(function()
        while self._gui and self._gui.Parent do
            -- Pulse glow
            TweenService:Create(self._logoGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                TextTransparency = 0.3,
            }):Play()
            task.wait(1.5)

            TweenService:Create(self._logoGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                TextTransparency = 0.7,
            }):Play()
            task.wait(1.5)
        end
    end)
end

function LoadingScreen:_animateProgressGlow()
    task.spawn(function()
        local offset = 0
        while self._gui and self._gui.Parent do
            offset += 0.01
            if offset >= 1 then
                offset -= 1
            end
            self._barGradient.Offset = Vector2.new(math.sin(offset * math.pi * 2) * 0.3, 0)
            task.wait(0.03)
        end
    end)
end

function LoadingScreen:_cycleTips()
    task.spawn(function()
        local tipIndex = 0
        while self._gui and self._gui.Parent do
            tipIndex = (tipIndex % #Constants.LOADING_TIPS) + 1
            local tip = Constants.LOADING_TIPS[tipIndex]

            -- Fade in
            self._tipLabel.Text = tip
            TweenService:Create(self._tipLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0.1,
            }):Play()

            task.wait(CONFIG.tipCycleTime - 1.2)

            -- Fade out
            TweenService:Create(self._tipLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1,
            }):Play()

            task.wait(0.6)
        end
    end)
end

function LoadingScreen:_playMusic()
    local music = Instance.new("Sound")
    music.Name = "LoadingMusic"
    music.SoundId = CONFIG.musicId
    music.Volume = 0
    music.Looped = true
    music.Parent = SoundService
    music:Play()
    self._music = music

    -- Fade in
    TweenService:Create(music, TweenInfo.new(2, Enum.EasingStyle.Quad), {
        Volume = 0.3,
    }):Play()
end

function LoadingScreen:_setProgress(progress: number)
    progress = math.clamp(progress, 0, 1)

    TweenService:Create(self._barFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(progress, 0, 1, 0),
    }):Play()

    TweenService:Create(self._barGlow, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(progress, 0, 1, 8),
    }):Play()

    self._progressPercent.Text = math.floor(progress * 100) .. "%"
end

function LoadingScreen:_setStatus(text: string)
    self._statusText.Text = text
end

function LoadingScreen:_preloadAssets()
    task.spawn(function()
        -- Collect assets to preload
        local assets = {}
        for _, desc in ipairs(game:GetDescendants()) do
            if desc:IsA("Sound") or desc:IsA("Animation") then
                table.insert(assets, desc)
            end
        end

        local _totalAssets = math.max(#assets, 1)
        local loaded = 0
        local _startTime = tick()

        self:_setStatus("جاري تحميل الموارد...")
        self:_setProgress(0)

        -- Simulate staged loading for smooth feel
        local stages = {
            { progress = 0.15, status = "تحميل الخرائط..." },
            { progress = 0.35, status = "تحميل السيارات..." },
            { progress = 0.55, status = "تحميل المباني..." },
            { progress = 0.75, status = "تحميل واجهة المستخدم..." },
            { progress = 0.90, status = "التحقق من البيانات..." },
        }

        -- Preload real assets in background
        if #assets > 0 then
            ContentProvider:PreloadAsync(assets, function(_, _status)
                loaded += 1
            end)
        end

        -- Animate through stages smoothly
        for _, stage in ipairs(stages) do
            self:_setStatus(stage.status)
            local duration = CONFIG.minLoadTime / #stages
            local steps = 20
            local currentProgress = self._barFill.Size.X.Scale
            for step = 1, steps do
                local t = step / steps
                local p = currentProgress + (stage.progress - currentProgress) * t
                self:_setProgress(p)
                task.wait(duration / steps)
            end
        end

        -- Final push to 100%
        self:_setStatus("جاهز!")
        self:_setProgress(1)
        task.wait(0.8)

        -- Dismiss
        self:Dismiss()
    end)
end

function LoadingScreen:Dismiss()
    -- Re-enable core GUI
    pcall(function()
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    end)

    -- Fade out music
    if self._music then
        TweenService:Create(self._music, TweenInfo.new(1.5), {
            Volume = 0,
        }):Play()
        task.delay(1.5, function()
            if self._music then
                self._music:Stop()
                self._music:Destroy()
            end
        end)
    end

    -- Cinematic dismiss: scale up + fade
    if self._content then
        TweenService:Create(self._content, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(1.1, 0, 1.1, 0),
            Position = UDim2.new(-0.05, 0, -0.05, 0),
        }):Play()
    end

    if self._bg then
        TweenService:Create(self._bg, TweenInfo.new(1, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1,
        }):Play()
    end

    -- Fade all text elements
    for _, desc in ipairs(self._gui:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            TweenService:Create(desc, TweenInfo.new(0.8), {
                TextTransparency = 1,
            }):Play()
        elseif desc:IsA("Frame") then
            TweenService:Create(desc, TweenInfo.new(0.8), {
                BackgroundTransparency = 1,
            }):Play()
        elseif desc:IsA("ImageLabel") then
            TweenService:Create(desc, TweenInfo.new(0.8), {
                ImageTransparency = 1,
            }):Play()
        elseif desc:IsA("UIStroke") then
            TweenService:Create(desc, TweenInfo.new(0.8), {
                Transparency = 1,
            }):Play()
        end
    end

    task.wait(1.1)

    if self._gui then
        self._gui:Destroy()
        self._gui = nil
    end
end

return LoadingScreen
