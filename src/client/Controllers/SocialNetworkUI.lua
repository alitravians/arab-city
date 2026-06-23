--[[
    Arab City - Social Network UI
    Full social media experience: feed, posting, profiles, likes, comments, leaderboard
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

local COLORS = Constants.COLORS

local SocialNetworkUI = {}
SocialNetworkUI._isOpen = false

function SocialNetworkUI:Init()
    self._gui = self:_buildUI()
    self._gui.Enabled = false
    self._gui.Parent = playerGui

    RemoteManager:OnClientEvent("SocialFeedUpdate", function(_action, _data)
        if self._isOpen then
            self:_refreshFeed()
        end
    end)
end

function SocialNetworkUI:Open(tab: string?)
    self._isOpen = true
    self._gui.Enabled = true

    -- Slide in
    self._mainFrame.Position = UDim2.new(1.5, 0, 0.5, 0)
    TweenService:Create(self._mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0),
    }):Play()

    if tab == "post" then
        self:_showPostScreen()
    elseif tab == "profile" then
        self:_showProfile(player.UserId)
    elseif tab == "leaderboard" then
        self:_showLeaderboard()
    else
        self:_refreshFeed()
    end
end

function SocialNetworkUI:Close()
    TweenService:Create(self._mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(1.5, 0, 0.5, 0),
    }):Play()

    task.delay(0.3, function()
        self._isOpen = false
        self._gui.Enabled = false
    end)
end

function SocialNetworkUI:_buildUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_SocialNetwork"
    gui.DisplayOrder = 85
    gui.ResetOnSpawn = false

    -- Overlay
    local overlay = Instance.new("TextButton")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0
    overlay.Text = ""
    overlay.ZIndex = 80
    overlay.Parent = gui

    overlay.MouseButton1Click:Connect(function()
        self:Close()
    end)

    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.45, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 81
    mainFrame.Parent = gui
    self._mainFrame = mainFrame

    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(100, 0, 255)
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.5
    mainStroke.Parent = mainFrame

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 45)
    header.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    header.BorderSizePixel = 0
    header.ZIndex = 82
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    local headerTitle = Instance.new("TextLabel")
    headerTitle.Size = UDim2.new(1, -100, 1, 0)
    headerTitle.Position = UDim2.new(0, 15, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "🌐 Social Network"
    headerTitle.TextColor3 = Color3.fromRGB(100, 0, 255)
    headerTitle.Font = Enum.Font.GothamBlack
    headerTitle.TextSize = 18
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.ZIndex = 83
    headerTitle.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.ZIndex = 83
    closeBtn.Parent = header

    closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 35)
    tabBar.Position = UDim2.new(0, 0, 0, 45)
    tabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex = 82
    tabBar.Parent = mainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabBar

    local tabs = {
        { id = "feed", label = "الخلاصة" },
        { id = "post", label = "نشر" },
        { id = "profile", label = "ملفي" },
        { id = "leaderboard", label = "الأشهر" },
    }

    for _, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. tab.id
        tabBtn.Size = UDim2.new(0, 80, 1, -6)
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        tabBtn.BackgroundTransparency = 0.5
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tab.label
        tabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 12
        tabBtn.ZIndex = 83
        tabBtn.Parent = tabBar

        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

        tabBtn.MouseButton1Click:Connect(function()
            if tab.id == "feed" then
                self:_refreshFeed()
            elseif tab.id == "post" then
                self:_showPostScreen()
            elseif tab.id == "profile" then
                self:_showProfile(player.UserId)
            elseif tab.id == "leaderboard" then
                self:_showLeaderboard()
            end
        end)
    end

    -- Content area (scrolling)
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -95)
    contentFrame.Position = UDim2.new(0.5, 0, 0, 85)
    contentFrame.AnchorPoint = Vector2.new(0.5, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 4
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 0, 255)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.ZIndex = 82
    contentFrame.Parent = mainFrame
    self._contentFrame = contentFrame

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentFrame

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 5)
    contentPadding.Parent = contentFrame

    return gui
end

function SocialNetworkUI:_clearContent()
    for _, child in ipairs(self._contentFrame:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

function SocialNetworkUI:_refreshFeed()
    self:_clearContent()

    local feed = RemoteManager:InvokeServer("GetSocialFeed", "global") or {}

    if #feed == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = "لا توجد منشورات بعد. كن أول من ينشر!"
        empty.TextColor3 = Color3.fromRGB(120, 120, 130)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 14
        empty.LayoutOrder = 1
        empty.ZIndex = 83
        empty.Parent = self._contentFrame
        return
    end

    for i, post in ipairs(feed) do
        self:_createPostCard(post, i)
    end
end

function SocialNetworkUI:_createPostCard(post, order: number)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 100)
    card.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 83
    card.Parent = self._contentFrame

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    -- Author info
    local authorLabel = Instance.new("TextLabel")
    authorLabel.Size = UDim2.new(1, -10, 0, 20)
    authorLabel.Position = UDim2.new(0, 10, 0, 8)
    authorLabel.BackgroundTransparency = 1
    authorLabel.Text = "👤 " .. (post.authorName or "مجهول")
    authorLabel.TextColor3 = Color3.fromRGB(100, 0, 255)
    authorLabel.Font = Enum.Font.GothamBold
    authorLabel.TextSize = 13
    authorLabel.TextXAlignment = Enum.TextXAlignment.Left
    authorLabel.ZIndex = 84
    authorLabel.Parent = card

    -- Content
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Size = UDim2.new(1, -20, 0, 35)
    contentLabel.Position = UDim2.new(0, 10, 0, 30)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = post.content or ""
    contentLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextSize = 13
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.TextWrapped = true
    contentLabel.ZIndex = 84
    contentLabel.Parent = card

    -- Stats bar (likes, comments, views)
    local statsBar = Instance.new("Frame")
    statsBar.Size = UDim2.new(1, -20, 0, 25)
    statsBar.Position = UDim2.new(0, 10, 1, -30)
    statsBar.BackgroundTransparency = 1
    statsBar.ZIndex = 84
    statsBar.Parent = card

    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.Padding = UDim.new(0, 15)
    statsLayout.Parent = statsBar

    -- Like button
    local likeBtn = Instance.new("TextButton")
    likeBtn.Size = UDim2.new(0, 60, 1, 0)
    likeBtn.BackgroundTransparency = 1
    likeBtn.Text = `❤️ {post.likeCount or 0}`
    likeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    likeBtn.Font = Enum.Font.GothamBold
    likeBtn.TextSize = 12
    likeBtn.ZIndex = 85
    likeBtn.Parent = statsBar

    likeBtn.MouseButton1Click:Connect(function()
        RemoteManager:FireServer("LikePost", post.authorId, post.postIndex or order)
    end)

    -- Comment count
    local commentLabel = Instance.new("TextLabel")
    commentLabel.Size = UDim2.new(0, 60, 1, 0)
    commentLabel.BackgroundTransparency = 1
    commentLabel.Text = `💬 {post.commentCount or 0}`
    commentLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    commentLabel.Font = Enum.Font.Gotham
    commentLabel.TextSize = 12
    commentLabel.ZIndex = 85
    commentLabel.Parent = statsBar

    -- View count
    local viewLabel = Instance.new("TextLabel")
    viewLabel.Size = UDim2.new(0, 60, 1, 0)
    viewLabel.BackgroundTransparency = 1
    viewLabel.Text = `👁 {post.views or 0}`
    viewLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    viewLabel.Font = Enum.Font.Gotham
    viewLabel.TextSize = 12
    viewLabel.ZIndex = 85
    viewLabel.Parent = statsBar

    return card
end

function SocialNetworkUI:_showPostScreen()
    self:_clearContent()

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = "📝 منشور جديد"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.LayoutOrder = 1
    label.ZIndex = 83
    label.Parent = self._contentFrame

    -- Text input
    local textBox = Instance.new("TextBox")
    textBox.Name = "PostInput"
    textBox.Size = UDim2.new(1, 0, 0, 100)
    textBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    textBox.BorderSizePixel = 0
    textBox.Text = ""
    textBox.PlaceholderText = "اكتب منشورك هنا... (280 حرف كحد أقصى)"
    textBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 14
    textBox.TextXAlignment = Enum.TextXAlignment.Right
    textBox.TextYAlignment = Enum.TextYAlignment.Top
    textBox.TextWrapped = true
    textBox.MultiLine = true
    textBox.ClearTextOnFocus = false
    textBox.LayoutOrder = 2
    textBox.ZIndex = 83
    textBox.Parent = self._contentFrame

    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 8)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = textBox

    -- Character count
    local charCount = Instance.new("TextLabel")
    charCount.Size = UDim2.new(1, 0, 0, 20)
    charCount.BackgroundTransparency = 1
    charCount.Text = "0/280"
    charCount.TextColor3 = Color3.fromRGB(120, 120, 130)
    charCount.Font = Enum.Font.Gotham
    charCount.TextSize = 12
    charCount.TextXAlignment = Enum.TextXAlignment.Right
    charCount.LayoutOrder = 3
    charCount.ZIndex = 83
    charCount.Parent = self._contentFrame

    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        local len = #textBox.Text
        charCount.Text = `{len}/280`
        charCount.TextColor3 = len > 280 and COLORS.Danger or Color3.fromRGB(120, 120, 130)
    end)

    -- Post button
    local postBtn = Instance.new("TextButton")
    postBtn.Size = UDim2.new(1, 0, 0, 40)
    postBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 255)
    postBtn.BorderSizePixel = 0
    postBtn.Text = "📤 نشر"
    postBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    postBtn.Font = Enum.Font.GothamBold
    postBtn.TextSize = 16
    postBtn.LayoutOrder = 4
    postBtn.ZIndex = 83
    postBtn.Parent = self._contentFrame

    Instance.new("UICorner", postBtn).CornerRadius = UDim.new(0, 8)

    postBtn.MouseButton1Click:Connect(function()
        local content = textBox.Text
        if #content >= 1 and #content <= 280 then
            RemoteManager:FireServer("CreatePost", content, "")
            textBox.Text = ""
            self:_refreshFeed()
        end
    end)
end

function SocialNetworkUI:_showProfile(userId: number)
    self:_clearContent()

    local profile = RemoteManager:InvokeServer("GetPlayerProfile", userId)
    if not profile then
        local errLabel = Instance.new("TextLabel")
        errLabel.Size = UDim2.new(1, 0, 0, 40)
        errLabel.BackgroundTransparency = 1
        errLabel.Text = "تعذر تحميل الملف الشخصي"
        errLabel.TextColor3 = COLORS.Danger
        errLabel.Font = Enum.Font.Gotham
        errLabel.TextSize = 14
        errLabel.ZIndex = 83
        errLabel.Parent = self._contentFrame
        return
    end

    -- Profile header
    local profileHeader = Instance.new("Frame")
    profileHeader.Size = UDim2.new(1, 0, 0, 100)
    profileHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    profileHeader.BorderSizePixel = 0
    profileHeader.LayoutOrder = 1
    profileHeader.ZIndex = 83
    profileHeader.Parent = self._contentFrame

    Instance.new("UICorner", profileHeader).CornerRadius = UDim.new(0, 8)

    -- Avatar placeholder
    local avatar = Instance.new("Frame")
    avatar.Size = UDim2.new(0, 50, 0, 50)
    avatar.Position = UDim2.new(0.5, 0, 0, 10)
    avatar.AnchorPoint = Vector2.new(0.5, 0)
    avatar.BackgroundColor3 = Color3.fromRGB(100, 0, 255)
    avatar.ZIndex = 84
    avatar.Parent = profileHeader

    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

    local avatarInitial = Instance.new("TextLabel")
    avatarInitial.Size = UDim2.new(1, 0, 1, 0)
    avatarInitial.BackgroundTransparency = 1
    avatarInitial.Text = string.sub(profile.displayName, 1, 1)
    avatarInitial.TextColor3 = Color3.fromRGB(255, 255, 255)
    avatarInitial.Font = Enum.Font.GothamBlack
    avatarInitial.TextSize = 24
    avatarInitial.ZIndex = 85
    avatarInitial.Parent = avatar

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0.5, 0, 0, 65)
    nameLabel.AnchorPoint = Vector2.new(0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = profile.displayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 15
    nameLabel.ZIndex = 84
    nameLabel.Parent = profileHeader

    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(1, 0, 0, 15)
    rankLabel.Position = UDim2.new(0.5, 0, 0, 85)
    rankLabel.AnchorPoint = Vector2.new(0.5, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = profile.rank ~= "None" and profile.rank or ""
    rankLabel.TextColor3 = COLORS.Gold
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.TextSize = 11
    rankLabel.ZIndex = 84
    rankLabel.Parent = profileHeader

    -- Stats row
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, 0, 0, 50)
    statsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    statsFrame.BorderSizePixel = 0
    statsFrame.LayoutOrder = 2
    statsFrame.ZIndex = 83
    statsFrame.Parent = self._contentFrame

    Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 8)

    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    statsLayout.Padding = UDim.new(0, 20)
    statsLayout.Parent = statsFrame

    local statItems = {
        { label = "منشورات", value = tostring(#(profile.posts or {})) },
        { label = "متابعون", value = Utils.formatNumber(profile.followers) },
        { label = "متابَع", value = Utils.formatNumber(profile.following) },
        { label = "شهرة", value = Utils.formatNumber(profile.fame) },
    }

    for _, stat in ipairs(statItems) do
        local statFrame = Instance.new("Frame")
        statFrame.Size = UDim2.new(0, 60, 1, 0)
        statFrame.BackgroundTransparency = 1
        statFrame.ZIndex = 84
        statFrame.Parent = statsFrame

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, 0, 0.5, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = stat.value
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 14
        valueLabel.ZIndex = 85
        valueLabel.Parent = statFrame

        local statLabel = Instance.new("TextLabel")
        statLabel.Size = UDim2.new(1, 0, 0.5, 0)
        statLabel.Position = UDim2.new(0, 0, 0.5, 0)
        statLabel.BackgroundTransparency = 1
        statLabel.Text = stat.label
        statLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
        statLabel.Font = Enum.Font.Gotham
        statLabel.TextSize = 10
        statLabel.ZIndex = 85
        statLabel.Parent = statFrame
    end

    -- Follow button (if viewing someone else)
    if userId ~= player.UserId then
        local followBtn = Instance.new("TextButton")
        followBtn.Size = UDim2.new(1, 0, 0, 35)
        followBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 255)
        followBtn.BorderSizePixel = 0
        followBtn.Text = "➕ متابعة"
        followBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        followBtn.Font = Enum.Font.GothamBold
        followBtn.TextSize = 14
        followBtn.LayoutOrder = 3
        followBtn.ZIndex = 83
        followBtn.Parent = self._contentFrame

        Instance.new("UICorner", followBtn).CornerRadius = UDim.new(0, 8)

        followBtn.MouseButton1Click:Connect(function()
            RemoteManager:FireServer("FollowPlayer", userId)
        end)
    end

    -- Posts
    local postsHeader = Instance.new("TextLabel")
    postsHeader.Size = UDim2.new(1, 0, 0, 25)
    postsHeader.BackgroundTransparency = 1
    postsHeader.Text = "المنشورات"
    postsHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    postsHeader.Font = Enum.Font.GothamBold
    postsHeader.TextSize = 14
    postsHeader.TextXAlignment = Enum.TextXAlignment.Right
    postsHeader.LayoutOrder = 4
    postsHeader.ZIndex = 83
    postsHeader.Parent = self._contentFrame

    if profile.posts and #profile.posts > 0 then
        for i, post in ipairs(profile.posts) do
            local postCard = Instance.new("Frame")
            postCard.Size = UDim2.new(1, 0, 0, 60)
            postCard.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
            postCard.BorderSizePixel = 0
            postCard.LayoutOrder = 4 + i
            postCard.ZIndex = 83
            postCard.Parent = self._contentFrame

            Instance.new("UICorner", postCard).CornerRadius = UDim.new(0, 6)

            local postContent = Instance.new("TextLabel")
            postContent.Size = UDim2.new(1, -16, 0, 35)
            postContent.Position = UDim2.new(0, 8, 0, 5)
            postContent.BackgroundTransparency = 1
            postContent.Text = post.content or ""
            postContent.TextColor3 = Color3.fromRGB(200, 200, 210)
            postContent.Font = Enum.Font.Gotham
            postContent.TextSize = 12
            postContent.TextXAlignment = Enum.TextXAlignment.Right
            postContent.TextWrapped = true
            postContent.ZIndex = 84
            postContent.Parent = postCard

            local postStats = Instance.new("TextLabel")
            postStats.Size = UDim2.new(1, -16, 0, 15)
            postStats.Position = UDim2.new(0, 8, 1, -20)
            postStats.BackgroundTransparency = 1
            postStats.Text = `❤️ {#(post.likes or {})} | 💬 {#(post.comments or {})} | 👁 {post.views or 0}`
            postStats.TextColor3 = Color3.fromRGB(100, 100, 110)
            postStats.Font = Enum.Font.Gotham
            postStats.TextSize = 10
            postStats.TextXAlignment = Enum.TextXAlignment.Left
            postStats.ZIndex = 84
            postStats.Parent = postCard
        end
    end
end

function SocialNetworkUI:_showLeaderboard()
    self:_clearContent()

    local leaderboard = RemoteManager:InvokeServer("GetLeaderboard") or {}

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundTransparency = 1
    header.Text = "🏆 الأكثر شهرة"
    header.TextColor3 = COLORS.Gold
    header.Font = Enum.Font.GothamBlack
    header.TextSize = 18
    header.LayoutOrder = 1
    header.ZIndex = 83
    header.Parent = self._contentFrame

    for i, entry in ipairs(leaderboard) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 45)
        card.BackgroundColor3 = i <= 3 and Color3.fromRGB(35, 30, 15) or Color3.fromRGB(25, 25, 35)
        card.BorderSizePixel = 0
        card.LayoutOrder = i + 1
        card.ZIndex = 83
        card.Parent = self._contentFrame

        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

        local rankIcons = { "🥇", "🥈", "🥉" }
        local posLabel = Instance.new("TextLabel")
        posLabel.Size = UDim2.new(0, 30, 1, 0)
        posLabel.Position = UDim2.new(0, 5, 0, 0)
        posLabel.BackgroundTransparency = 1
        posLabel.Text = rankIcons[i] or tostring(i)
        posLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        posLabel.Font = Enum.Font.GothamBold
        posLabel.TextSize = 16
        posLabel.ZIndex = 84
        posLabel.Parent = card

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, -40, 1, 0)
        nameLabel.Position = UDim2.new(0, 40, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = entry.displayName
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 84
        nameLabel.Parent = card

        local fameLabel = Instance.new("TextLabel")
        fameLabel.Size = UDim2.new(0.3, 0, 1, 0)
        fameLabel.Position = UDim2.new(0.7, 0, 0, 0)
        fameLabel.BackgroundTransparency = 1
        fameLabel.Text = `⭐ {Utils.formatNumber(entry.fame)}`
        fameLabel.TextColor3 = COLORS.Gold
        fameLabel.Font = Enum.Font.GothamBold
        fameLabel.TextSize = 13
        fameLabel.TextXAlignment = Enum.TextXAlignment.Right
        fameLabel.ZIndex = 84
        fameLabel.Parent = card
    end
end

return SocialNetworkUI
