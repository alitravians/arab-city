--[[
    Arab City v2.0 - SocialNetworkUI
    In-game social network: post photos, like, comment, follow.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SocialNetworkUI = {}

local Shared, Remotes, Constants
local player = Players.LocalPlayer
local _isOpen = false

function SocialNetworkUI:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
    Constants = Shared.Constants
    local colors = Constants.UI_COLORS

    local gui = Instance.new("ScreenGui")
    gui.Name = "SocialGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 55
    gui.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Name = "SocialPanel"
    panel.Size = UDim2.new(0, 380, 0, 500)
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
    title.BackgroundColor3 = colors.accent
    title.Text = "📸 Social Network"
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1, 1, 1)
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
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Parent = panel

    -- Post input
    local postFrame = Instance.new("Frame")
    postFrame.Size = UDim2.new(1, -20, 0, 60)
    postFrame.Position = UDim2.new(0, 10, 0, 45)
    postFrame.BackgroundColor3 = colors.card
    postFrame.BorderSizePixel = 0
    postFrame.Parent = panel
    Instance.new("UICorner", postFrame).CornerRadius = UDim.new(0, 8)

    local postBox = Instance.new("TextBox")
    postBox.Size = UDim2.new(1, -80, 1, -10)
    postBox.Position = UDim2.new(0, 8, 0, 5)
    postBox.BackgroundTransparency = 1
    postBox.PlaceholderText = "شارك منشور..."
    postBox.Text = ""
    postBox.TextSize = 13
    postBox.Font = Enum.Font.Gotham
    postBox.TextColor3 = colors.text
    postBox.PlaceholderColor3 = colors.textDim
    postBox.TextXAlignment = Enum.TextXAlignment.Left
    postBox.TextYAlignment = Enum.TextYAlignment.Top
    postBox.TextWrapped = true
    postBox.ClearTextOnFocus = false
    postBox.Parent = postFrame

    local postBtn = Instance.new("TextButton")
    postBtn.Size = UDim2.new(0, 60, 0, 30)
    postBtn.Position = UDim2.new(1, -68, 0.5, -15)
    postBtn.BackgroundColor3 = colors.accent
    postBtn.Text = "نشر"
    postBtn.TextSize = 13
    postBtn.Font = Enum.Font.GothamBold
    postBtn.TextColor3 = Color3.new(1, 1, 1)
    postBtn.BorderSizePixel = 0
    postBtn.Parent = postFrame
    Instance.new("UICorner", postBtn).CornerRadius = UDim.new(0, 6)

    -- Feed scroll
    self._feedScroll = Instance.new("ScrollingFrame")
    self._feedScroll.Size = UDim2.new(1, -20, 1, -120)
    self._feedScroll.Position = UDim2.new(0, 10, 0, 112)
    self._feedScroll.BackgroundTransparency = 1
    self._feedScroll.ScrollBarThickness = 4
    self._feedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self._feedScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self._feedScroll.Parent = panel

    local feedLayout = Instance.new("UIListLayout")
    feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
    feedLayout.Padding = UDim.new(0, 8)
    feedLayout.Parent = self._feedScroll

    self._panel = panel
    self._postOrder = 0

    postBtn.MouseButton1Click:Connect(function()
        local text = postBox.Text
        if text ~= "" then
            Remotes:FireServer("SocialPost", { text = text })
            postBox.Text = ""
        end
    end)

    Remotes:OnClientEvent("SocialFeed", function(data)
        self:_refreshFeed(data)
    end)

    Remotes:OnClientEvent("OpenSocial", function()
        _isOpen = true
        panel.Visible = true
        Remotes:FireServer("RequestSocialFeed")
    end)

    closeBtn.MouseButton1Click:Connect(function()
        _isOpen = false
        panel.Visible = false
    end)
end

function SocialNetworkUI:_refreshFeed(data)
    if type(data) ~= "table" then return end
    local colors = Constants.UI_COLORS

    for _, child in ipairs(self._feedScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local posts = data.posts or {}
    for i, post in ipairs(posts) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -5, 0, 80)
        card.BackgroundColor3 = colors.card
        card.BorderSizePixel = 0
        card.LayoutOrder = i
        card.Parent = self._feedScroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local author = Instance.new("TextLabel")
        author.Size = UDim2.new(1, -10, 0, 18)
        author.Position = UDim2.new(0, 8, 0, 5)
        author.BackgroundTransparency = 1
        author.Text = post.author or "???"
        author.TextSize = 13
        author.Font = Enum.Font.GothamBold
        author.TextColor3 = colors.accent
        author.TextXAlignment = Enum.TextXAlignment.Left
        author.Parent = card

        local body = Instance.new("TextLabel")
        body.Size = UDim2.new(1, -10, 0, 30)
        body.Position = UDim2.new(0, 8, 0, 24)
        body.BackgroundTransparency = 1
        body.Text = post.text or ""
        body.TextSize = 12
        body.Font = Enum.Font.Gotham
        body.TextColor3 = colors.text
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextWrapped = true
        body.Parent = card

        local likeBtn = Instance.new("TextButton")
        likeBtn.Size = UDim2.new(0, 50, 0, 22)
        likeBtn.Position = UDim2.new(0, 8, 1, -28)
        likeBtn.BackgroundTransparency = 1
        likeBtn.Text = "❤️ " .. tostring(post.likes or 0)
        likeBtn.TextSize = 11
        likeBtn.Font = Enum.Font.GothamBold
        likeBtn.TextColor3 = colors.textDim
        likeBtn.Parent = card

        local postId = post.id
        likeBtn.MouseButton1Click:Connect(function()
            Remotes:FireServer("SocialLike", { postId = postId })
        end)
    end
end

return SocialNetworkUI
