--[[
    Arab City v2.0 - CodeController
    UI for redeeming promo codes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CodeController = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function CodeController:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "CodeGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 72
    gui.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 320, 0, 180)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = colors.background
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", panel).Color = colors.accent

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = colors.card
    title.Text = "🎫 استبدال كود"
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = colors.text
    title.BorderSizePixel = 0
    title.Parent = panel
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = colors.text
    closeBtn.Parent = panel

    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(1, -30, 0, 40)
    inputBg.Position = UDim2.new(0, 15, 0, 55)
    inputBg.BackgroundColor3 = colors.card
    inputBg.BorderSizePixel = 0
    inputBg.Parent = panel
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 8)

    local codeBox = Instance.new("TextBox")
    codeBox.Size = UDim2.new(1, -10, 1, 0)
    codeBox.Position = UDim2.new(0, 5, 0, 0)
    codeBox.BackgroundTransparency = 1
    codeBox.PlaceholderText = "أدخل الكود هنا..."
    codeBox.Text = ""
    codeBox.TextSize = 16
    codeBox.Font = Enum.Font.GothamBold
    codeBox.TextColor3 = colors.text
    codeBox.PlaceholderColor3 = colors.textDim
    codeBox.Parent = inputBg

    local redeemBtn = Instance.new("TextButton")
    redeemBtn.Size = UDim2.new(1, -30, 0, 38)
    redeemBtn.Position = UDim2.new(0, 15, 0, 105)
    redeemBtn.BackgroundColor3 = colors.accent
    redeemBtn.Text = "استبدال"
    redeemBtn.TextSize = 16
    redeemBtn.Font = Enum.Font.GothamBold
    redeemBtn.TextColor3 = Color3.new(1, 1, 1)
    redeemBtn.BorderSizePixel = 0
    redeemBtn.Parent = panel
    Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 8)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -30, 0, 20)
    statusLabel.Position = UDim2.new(0, 15, 0, 148)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextColor3 = colors.success
    statusLabel.Parent = panel

    self._panel = panel

    redeemBtn.MouseButton1Click:Connect(function()
        local code = codeBox.Text
        if code ~= "" then
            Remotes:FireServer("RedeemCode", code)
        end
    end)

    codeBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and codeBox.Text ~= "" then
            Remotes:FireServer("RedeemCode", codeBox.Text)
        end
    end)

    Remotes:OnClientEvent("CodeResult", function(data)
        if type(data) == "table" then
            statusLabel.Text = data.message or ""
            statusLabel.TextColor3 = if data.success then colors.success else colors.danger
        end
    end)

    Remotes:OnClientEvent("OpenCodes", function()
        _isOpen = true
        panel.Visible = true
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)
end

return CodeController
