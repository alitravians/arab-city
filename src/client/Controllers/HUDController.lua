--[[
    Arab City v2.0 - HUDController
    Top-bar HUD: cash, level, XP bar, job indicator.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HUDController = {}

local Shared, Remotes, Utils, Constants
local player = Players.LocalPlayer

function HUDController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Utils = Shared.Utils
    Constants = Shared.Constants

    local gui = Instance.new("ScreenGui")
    gui.Name = "HUDGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 10
    gui.Parent = player:WaitForChild("PlayerGui")

    local colors = Constants.UI_COLORS

    -- Top bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = colors.background
    topBar.BackgroundTransparency = 0.2
    topBar.BorderSizePixel = 0
    topBar.Parent = gui

    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    gradient.Parent = topBar

    -- Cash display
    local cashFrame = Instance.new("Frame")
    cashFrame.Size = UDim2.new(0, 180, 0, 36)
    cashFrame.Position = UDim2.new(0, 15, 0.5, -18)
    cashFrame.BackgroundColor3 = colors.card
    cashFrame.BorderSizePixel = 0
    cashFrame.Parent = topBar
    Instance.new("UICorner", cashFrame).CornerRadius = UDim.new(0, 8)

    local cashIcon = Instance.new("TextLabel")
    cashIcon.Size = UDim2.new(0, 30, 1, 0)
    cashIcon.Position = UDim2.new(0, 5, 0, 0)
    cashIcon.BackgroundTransparency = 1
    cashIcon.Text = "💰"
    cashIcon.TextSize = 18
    cashIcon.Font = Enum.Font.GothamBold
    cashIcon.Parent = cashFrame

    self._cashLabel = Instance.new("TextLabel")
    self._cashLabel.Size = UDim2.new(1, -40, 1, 0)
    self._cashLabel.Position = UDim2.new(0, 35, 0, 0)
    self._cashLabel.BackgroundTransparency = 1
    self._cashLabel.Text = "$0"
    self._cashLabel.TextSize = 16
    self._cashLabel.Font = Enum.Font.GothamBold
    self._cashLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    self._cashLabel.TextXAlignment = Enum.TextXAlignment.Left
    self._cashLabel.Parent = cashFrame

    -- Level + XP bar
    local levelFrame = Instance.new("Frame")
    levelFrame.Size = UDim2.new(0, 200, 0, 36)
    levelFrame.Position = UDim2.new(0, 210, 0.5, -18)
    levelFrame.BackgroundColor3 = colors.card
    levelFrame.BorderSizePixel = 0
    levelFrame.Parent = topBar
    Instance.new("UICorner", levelFrame).CornerRadius = UDim.new(0, 8)

    self._levelLabel = Instance.new("TextLabel")
    self._levelLabel.Size = UDim2.new(0, 70, 1, 0)
    self._levelLabel.Position = UDim2.new(0, 5, 0, 0)
    self._levelLabel.BackgroundTransparency = 1
    self._levelLabel.Text = "Lv.1"
    self._levelLabel.TextSize = 14
    self._levelLabel.Font = Enum.Font.GothamBold
    self._levelLabel.TextColor3 = colors.accent
    self._levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    self._levelLabel.Parent = levelFrame

    local xpBg = Instance.new("Frame")
    xpBg.Size = UDim2.new(0, 115, 0, 10)
    xpBg.Position = UDim2.new(0, 78, 0.5, -5)
    xpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    xpBg.BorderSizePixel = 0
    xpBg.Parent = levelFrame
    Instance.new("UICorner", xpBg).CornerRadius = UDim.new(0, 5)

    self._xpFill = Instance.new("Frame")
    self._xpFill.Size = UDim2.new(0, 0, 1, 0)
    self._xpFill.BackgroundColor3 = colors.accent
    self._xpFill.BorderSizePixel = 0
    self._xpFill.Parent = xpBg
    Instance.new("UICorner", self._xpFill).CornerRadius = UDim.new(0, 5)

    -- Job display
    self._jobLabel = Instance.new("TextLabel")
    self._jobLabel.Size = UDim2.new(0, 150, 0, 36)
    self._jobLabel.Position = UDim2.new(0, 425, 0.5, -18)
    self._jobLabel.BackgroundColor3 = colors.card
    self._jobLabel.BorderSizePixel = 0
    self._jobLabel.Text = "🔍 بدون وظيفة"
    self._jobLabel.TextSize = 13
    self._jobLabel.Font = Enum.Font.GothamBold
    self._jobLabel.TextColor3 = colors.textDim
    self._jobLabel.Parent = topBar
    Instance.new("UICorner", self._jobLabel).CornerRadius = UDim.new(0, 8)

    -- Listen for updates
    Remotes:OnClientEvent("UpdateCash", function(cash)
        self._cashLabel.Text = "$" .. Utils.formatCash(cash)
    end)

    Remotes:OnClientEvent("XPUpdate", function(data)
        if type(data) == "table" then
            self._levelLabel.Text = "Lv." .. tostring(data.level or 1)
            local xp = data.xp or 0
            local needed = Constants.XP_PER_LEVEL
            local ratio = math.clamp(xp / needed, 0, 1)
            TweenService:Create(self._xpFill, TweenInfo.new(0.3), {
                Size = UDim2.new(ratio, 0, 1, 0),
            }):Play()
        end
    end)

    Remotes:OnClientEvent("JobUpdate", function(data)
        if type(data) == "table" and data.name then
            self._jobLabel.Text = (data.icon or "💼") .. " " .. data.name
            self._jobLabel.TextColor3 = Constants.UI_COLORS.text
        end
    end)
end

return HUDController
