--[[
    Arab City - HUD Controller
    Manages the main game HUD:
    - Top bar: Codes, Shop, Inventory, Phone, Map, Missions
    - Bottom bar: Cash, Level, Health
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local Utils = Shared.Utils
local RemoteManager = Shared.RemoteManager

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDController = {}
HUDController._panels = {} -- references to sub-panel controllers

local COLORS = Constants.COLORS

function HUDController:Init()
    self._gui = self:_buildHUD()
    self._gui.Parent = playerGui

    -- Listen for data updates
    RemoteManager:OnClientEvent("UpdateMoney", function(newBalance, change, reason)
        self:_updateCash(newBalance)
        if change ~= 0 then
            self:_showMoneyPopup(change, reason)
        end
    end)

    RemoteManager:OnClientEvent("MoneyUpdate", function(newBalance)
        self:_updateCash(newBalance)
    end)

    RemoteManager:OnClientEvent("PlayerDataLoaded", function(data)
        self:_updateFromData(data)
    end)

    RemoteManager:OnClientEvent("PlayerDataUpdate", function(key, value)
        self:_onDataUpdate(key, value)
    end)

    -- XP updates
    RemoteManager:OnClientEvent("XPGain", function(_amount, currentXP, currentLevel)
        self:_updateXP(currentXP, currentLevel)
    end)

    RemoteManager:OnClientEvent("LevelUp", function(newLevel)
        self:_updateLevel(newLevel)
    end)

    -- Health monitoring
    self:_monitorHealth()
end

function HUDController:_buildHUD(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_HUD"
    gui.DisplayOrder = 10
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- ═══════════════════════════════════
    -- TOP BAR
    -- ═══════════════════════════════════
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = COLORS.Primary
    topBar.BackgroundTransparency = 0.2
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 20
    topBar.Parent = gui

    local topGradient = Instance.new("UIGradient")
    topGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 0.3),
    })
    topGradient.Rotation = 90
    topGradient.Parent = topBar

    -- Top bar buttons container
    local topBtnContainer = Instance.new("Frame")
    topBtnContainer.Name = "ButtonContainer"
    topBtnContainer.Size = UDim2.new(1, -20, 1, -10)
    topBtnContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    topBtnContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    topBtnContainer.BackgroundTransparency = 1
    topBtnContainer.ZIndex = 21
    topBtnContainer.Parent = topBar

    local topLayout = Instance.new("UIListLayout")
    topLayout.FillDirection = Enum.FillDirection.Horizontal
    topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    topLayout.Padding = UDim.new(0, 10)
    topLayout.SortOrder = Enum.SortOrder.LayoutOrder
    topLayout.Parent = topBtnContainer

    -- Top bar button definitions
    local topButtons = {
        { name = "Codes",      icon = "🎁", labelAr = "أكواد",     order = 1, action = "codes" },
        { name = "Shop",       icon = "🛒", labelAr = "المتجر",    order = 2, action = "shop" },
        { name = "Inventory",  icon = "🎒", labelAr = "الحقيبة",   order = 3, action = "inventory" },
        { name = "Phone",      icon = "📱", labelAr = "الهاتف",    order = 4, action = "phone" },
        { name = "Map",        icon = "🗺️", labelAr = "الخريطة",   order = 5, action = "map" },
        { name = "Missions",   icon = "📋", labelAr = "المهمات",   order = 6, action = "missions" },
        { name = "Friends",    icon = "👥", labelAr = "أصدقاء",    order = 7, action = "friends" },
        { name = "Leaderboard",icon = "🏆", labelAr = "متصدرين",   order = 8, action = "leaderboard" },
        { name = "Challenges", icon = "🎯", labelAr = "تحديات",    order = 9, action = "challenges" },
        { name = "Pets",       icon = "🐾", labelAr = "حيوانات",   order = 10, action = "pets" },
        { name = "Trade",      icon = "🔄", labelAr = "تبادل",     order = 11, action = "trade" },
        { name = "Admin",      icon = "🛡️", labelAr = "إدارة",     order = 12, action = "admin", adminOnly = true },
    }

    self._topButtons = {}
    for _, btnDef in ipairs(topButtons) do
        local btn = self:_createTopButton(btnDef)
        btn.LayoutOrder = btnDef.order
        btn.Parent = topBtnContainer
        if btnDef.adminOnly then
            btn.Visible = false
        end
        self._topButtons[btnDef.action] = btn
    end

    -- Listen for admin status to show admin button
    RemoteManager:OnClientEvent("AdminStatus", function(isAdmin)
        if self._topButtons["admin"] then
            self._topButtons["admin"].Visible = isAdmin
        end
    end)

    -- ═══════════════════════════════════
    -- BOTTOM BAR
    -- ═══════════════════════════════════
    local bottomBar = Instance.new("Frame")
    bottomBar.Name = "BottomBar"
    bottomBar.Size = UDim2.new(1, 0, 0, 60)
    bottomBar.Position = UDim2.new(0, 0, 1, 0)
    bottomBar.AnchorPoint = Vector2.new(0, 1)
    bottomBar.BackgroundColor3 = COLORS.Primary
    bottomBar.BackgroundTransparency = 0.2
    bottomBar.BorderSizePixel = 0
    bottomBar.ZIndex = 20
    bottomBar.Parent = gui

    local bottomGradient = Instance.new("UIGradient")
    bottomGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0),
    })
    bottomGradient.Rotation = 90
    bottomGradient.Parent = bottomBar

    -- Cash display (left)
    local cashFrame = Instance.new("Frame")
    cashFrame.Name = "CashFrame"
    cashFrame.Size = UDim2.new(0, 200, 0, 40)
    cashFrame.Position = UDim2.new(0, 15, 0.5, 0)
    cashFrame.AnchorPoint = Vector2.new(0, 0.5)
    cashFrame.BackgroundColor3 = COLORS.CardBg
    cashFrame.BackgroundTransparency = 0.3
    cashFrame.BorderSizePixel = 0
    cashFrame.ZIndex = 21
    cashFrame.Parent = bottomBar

    Instance.new("UICorner", cashFrame).CornerRadius = UDim.new(0, 8)

    local cashIcon = Instance.new("TextLabel")
    cashIcon.Size = UDim2.new(0, 30, 1, 0)
    cashIcon.BackgroundTransparency = 1
    cashIcon.Text = "💰"
    cashIcon.TextSize = 20
    cashIcon.ZIndex = 22
    cashIcon.Parent = cashFrame

    local cashLabel = Instance.new("TextLabel")
    cashLabel.Name = "CashLabel"
    cashLabel.Size = UDim2.new(1, -35, 1, 0)
    cashLabel.Position = UDim2.new(0, 30, 0, 0)
    cashLabel.BackgroundTransparency = 1
    cashLabel.Text = "0 $"
    cashLabel.TextColor3 = COLORS.Gold
    cashLabel.Font = Enum.Font.GothamBold
    cashLabel.TextSize = 18
    cashLabel.TextXAlignment = Enum.TextXAlignment.Left
    cashLabel.ZIndex = 22
    cashLabel.Parent = cashFrame
    self._cashLabel = cashLabel

    -- Level + XP display (center-left)
    local levelFrame = Instance.new("Frame")
    levelFrame.Name = "LevelFrame"
    levelFrame.Size = UDim2.new(0, 220, 0, 40)
    levelFrame.Position = UDim2.new(0, 230, 0.5, 0)
    levelFrame.AnchorPoint = Vector2.new(0, 0.5)
    levelFrame.BackgroundColor3 = COLORS.CardBg
    levelFrame.BackgroundTransparency = 0.3
    levelFrame.BorderSizePixel = 0
    levelFrame.ZIndex = 21
    levelFrame.Parent = bottomBar

    Instance.new("UICorner", levelFrame).CornerRadius = UDim.new(0, 8)

    local levelIcon = Instance.new("TextLabel")
    levelIcon.Size = UDim2.new(0, 30, 0, 20)
    levelIcon.Position = UDim2.new(0, 0, 0, 2)
    levelIcon.BackgroundTransparency = 1
    levelIcon.Text = "⭐"
    levelIcon.TextSize = 16
    levelIcon.ZIndex = 22
    levelIcon.Parent = levelFrame

    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, -35, 0, 20)
    levelLabel.Position = UDim2.new(0, 30, 0, 2)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "المستوى 1"
    levelLabel.TextColor3 = COLORS.Accent
    levelLabel.Font = Enum.Font.GothamBold
    levelLabel.TextSize = 14
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.ZIndex = 22
    levelLabel.Parent = levelFrame
    self._levelLabel = levelLabel

    -- XP Progress Bar
    local xpBarBg = Instance.new("Frame")
    xpBarBg.Name = "XPBarBg"
    xpBarBg.Size = UDim2.new(1, -16, 0, 8)
    xpBarBg.Position = UDim2.new(0.5, 0, 1, -12)
    xpBarBg.AnchorPoint = Vector2.new(0.5, 0)
    xpBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    xpBarBg.BorderSizePixel = 0
    xpBarBg.ZIndex = 22
    xpBarBg.Parent = levelFrame
    Instance.new("UICorner", xpBarBg).CornerRadius = UDim.new(1, 0)

    local xpBarFill = Instance.new("Frame")
    xpBarFill.Name = "XPBarFill"
    xpBarFill.Size = UDim2.new(0, 0, 1, 0)
    xpBarFill.BackgroundColor3 = COLORS.Accent
    xpBarFill.BorderSizePixel = 0
    xpBarFill.ZIndex = 23
    xpBarFill.Parent = xpBarBg
    Instance.new("UICorner", xpBarFill).CornerRadius = UDim.new(1, 0)
    self._xpBarFill = xpBarFill

    local xpText = Instance.new("TextLabel")
    xpText.Name = "XPText"
    xpText.Size = UDim2.new(1, 0, 1, 0)
    xpText.BackgroundTransparency = 1
    xpText.Text = "0 XP"
    xpText.TextColor3 = COLORS.Text
    xpText.Font = Enum.Font.GothamBold
    xpText.TextSize = 7
    xpText.ZIndex = 24
    xpText.Parent = xpBarBg
    self._xpText = xpText

    -- Health bar (right side)
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthFrame"
    healthFrame.Size = UDim2.new(0, 200, 0, 40)
    healthFrame.Position = UDim2.new(1, -15, 0.5, 0)
    healthFrame.AnchorPoint = Vector2.new(1, 0.5)
    healthFrame.BackgroundColor3 = COLORS.CardBg
    healthFrame.BackgroundTransparency = 0.3
    healthFrame.BorderSizePixel = 0
    healthFrame.ZIndex = 21
    healthFrame.Parent = bottomBar

    Instance.new("UICorner", healthFrame).CornerRadius = UDim.new(0, 8)

    local healthIcon = Instance.new("TextLabel")
    healthIcon.Size = UDim2.new(0, 30, 1, 0)
    healthIcon.BackgroundTransparency = 1
    healthIcon.Text = "❤️"
    healthIcon.TextSize = 18
    healthIcon.ZIndex = 22
    healthIcon.Parent = healthFrame

    local healthBarBg = Instance.new("Frame")
    healthBarBg.Name = "HealthBarBg"
    healthBarBg.Size = UDim2.new(1, -40, 0, 12)
    healthBarBg.Position = UDim2.new(0, 32, 0.5, 0)
    healthBarBg.AnchorPoint = Vector2.new(0, 0.5)
    healthBarBg.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
    healthBarBg.BorderSizePixel = 0
    healthBarBg.ZIndex = 22
    healthBarBg.Parent = healthFrame

    Instance.new("UICorner", healthBarBg).CornerRadius = UDim.new(0, 6)

    local healthBarFill = Instance.new("Frame")
    healthBarFill.Name = "HealthBarFill"
    healthBarFill.Size = UDim2.new(1, 0, 1, 0)
    healthBarFill.BackgroundColor3 = COLORS.Success
    healthBarFill.BorderSizePixel = 0
    healthBarFill.ZIndex = 23
    healthBarFill.Parent = healthBarBg

    Instance.new("UICorner", healthBarFill).CornerRadius = UDim.new(0, 6)
    self._healthBarFill = healthBarFill

    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100"
    healthText.TextColor3 = COLORS.Text
    healthText.Font = Enum.Font.GothamBold
    healthText.TextSize = 10
    healthText.ZIndex = 24
    healthText.Parent = healthBarBg
    self._healthText = healthText

    -- ═══════════════════════════════════
    -- MONEY POPUP (floating)
    -- ═══════════════════════════════════
    local moneyPopup = Instance.new("TextLabel")
    moneyPopup.Name = "MoneyPopup"
    moneyPopup.Size = UDim2.new(0, 200, 0, 30)
    moneyPopup.Position = UDim2.new(0, 115, 1, -70)
    moneyPopup.AnchorPoint = Vector2.new(0.5, 0.5)
    moneyPopup.BackgroundTransparency = 1
    moneyPopup.Text = ""
    moneyPopup.TextColor3 = COLORS.Success
    moneyPopup.Font = Enum.Font.GothamBold
    moneyPopup.TextSize = 16
    moneyPopup.TextTransparency = 1
    moneyPopup.ZIndex = 30
    moneyPopup.Parent = gui
    self._moneyPopup = moneyPopup

    return gui
end

function HUDController:_createTopButton(def): TextButton
    local btn = Instance.new("TextButton")
    btn.Name = "Btn_" .. def.name
    btn.Size = UDim2.new(0, 100, 0, 36)
    btn.BackgroundColor3 = COLORS.CardBg
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = def.icon .. " " .. def.labelAr
    btn.TextColor3 = COLORS.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.ZIndex = 22
    btn.AutoButtonColor = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Parent = btn

    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.2), { Transparency = 0.2 }):Play()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.2), { Transparency = 0.7 }):Play()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundTransparency = 0.3 }):Play()
    end)

    -- Click handler
    btn.MouseButton1Click:Connect(function()
        self:_onButtonClicked(def.action)
    end)

    return btn
end

function HUDController:_onButtonClicked(action: string)
    -- Fire signal to open respective panel
    if self.OnPanelRequested then
        self.OnPanelRequested(action)
    end
end

function HUDController:_updateCash(amount: number)
    if self._cashLabel then
        self._cashLabel.Text = Utils.formatCurrency(amount)
    end
end

function HUDController:_updateLevel(level: number)
    if self._levelLabel then
        self._levelLabel.Text = `المستوى {level}`
    end
end

function HUDController:_showMoneyPopup(change: number, _reason: string)
    if not self._moneyPopup then
        return
    end

    local isPositive = change > 0
    self._moneyPopup.Text = (isPositive and "+" or "") .. Utils.formatCurrency(change)
    self._moneyPopup.TextColor3 = isPositive and COLORS.Success or COLORS.Danger
    self._moneyPopup.TextTransparency = 0
    self._moneyPopup.Position = UDim2.new(0, 115, 1, -70)

    -- Float up and fade
    TweenService:Create(self._moneyPopup, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 115, 1, -120),
        TextTransparency = 1,
    }):Play()
end

function HUDController:_monitorHealth()
    local function setupHealthListener()
        local character = player.Character
        if not character then
            return
        end
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then
            return
        end

        humanoid.HealthChanged:Connect(function(health)
            local ratio = health / humanoid.MaxHealth
            if self._healthBarFill then
                TweenService:Create(self._healthBarFill, TweenInfo.new(0.3), {
                    Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0),
                }):Play()

                -- Color based on health
                local color
                if ratio > 0.6 then
                    color = COLORS.Success
                elseif ratio > 0.3 then
                    color = Color3.fromRGB(255, 165, 0)
                else
                    color = COLORS.Danger
                end
                TweenService:Create(self._healthBarFill, TweenInfo.new(0.3), {
                    BackgroundColor3 = color,
                }):Play()
            end
            if self._healthText then
                self._healthText.Text = tostring(math.ceil(health))
            end
        end)
    end

    setupHealthListener()
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        setupHealthListener()
    end)
end

function HUDController:_updateXP(currentXP: number, currentLevel: number)
    self:_updateLevel(currentLevel)
    local needed = Constants.getXPForLevel(currentLevel)
    local ratio = if needed > 0 then math.clamp(currentXP / needed, 0, 1) else 0
    if self._xpBarFill then
        TweenService:Create(self._xpBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
            Size = UDim2.new(ratio, 0, 1, 0),
        }):Play()
    end
    if self._xpText then
        self._xpText.Text = currentXP .. " / " .. needed .. " XP"
    end
end

function HUDController:_updateFromData(data)
    if data.cash then
        self:_updateCash(data.cash)
    end
    if data.level then
        self:_updateLevel(data.level)
    end
    if data.xp and data.level then
        self:_updateXP(data.xp, data.level)
    end
end

function HUDController:_onDataUpdate(key: string, value: any)
    if key == "cash" then
        self:_updateCash(value)
    elseif key == "level" then
        self:_updateLevel(value)
    end
end

function HUDController:RegisterPanelCallback(callback: (string) -> ())
    self.OnPanelRequested = callback
end

return HUDController
