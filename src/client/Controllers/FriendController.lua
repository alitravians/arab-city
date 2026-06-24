--[[
    Arab City - Friend Controller
    UI for friend list, requests, adding friends
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

local FriendController = {}
FriendController._isOpen = false
FriendController._activeTab = "friends"

function FriendController:Init()
    self._gui = self:_buildUI()
    self._gui.Enabled = false
    self._gui.Parent = playerGui

    RemoteManager:OnClientEvent("FriendRequestReceived", function()
        self:_refreshIfOpen()
    end)
    RemoteManager:OnClientEvent("FriendUpdate", function()
        self:_refreshIfOpen()
    end)
end

function FriendController:Toggle()
    if self._isOpen then self:Close() else self:Open() end
end

function FriendController:Open()
    if self._isOpen then return end
    self._isOpen = true
    self._gui.Enabled = true
    self:_refresh()
end

function FriendController:Close()
    if not self._isOpen then return end
    self._isOpen = false
    self._gui.Enabled = false
end

function FriendController:_refreshIfOpen()
    if self._isOpen then self:_refresh() end
end

function FriendController:_buildUI(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ArabCity_Friends"
    gui.DisplayOrder = 85
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false

    local backdrop = Instance.new("TextButton")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0
    backdrop.Text = ""
    backdrop.ZIndex = 50
    backdrop.Parent = gui
    backdrop.MouseButton1Click:Connect(function() self:Close() end)

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 360, 0, 480)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = COLORS.Primary
    main.BorderSizePixel = 0
    main.ZIndex = 51
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 200, 255)
    stroke.Thickness = 1.5
    stroke.Parent = main

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 40)
    title.Position = UDim2.new(0, 15, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "👥 الأصدقاء"
    title.TextColor3 = Color3.fromRGB(100, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 52
    title.Parent = main

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 8)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = COLORS.TextDim
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.ZIndex = 52
    closeBtn.Parent = main
    closeBtn.MouseButton1Click:Connect(function() self:Close() end)

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 36)
    tabBar.Position = UDim2.new(0.5, 0, 0, 48)
    tabBar.AnchorPoint = Vector2.new(0.5, 0)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 52
    tabBar.Parent = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabBar

    self._tabButtons = {}
    local tabDefs = { { id = "friends", text = "أصدقائي" }, { id = "requests", text = "الطلبات" }, { id = "players", text = "اللاعبين" } }

    for i, td in ipairs(tabDefs) do
        local tab = Instance.new("TextButton")
        tab.Name = "Tab_" .. td.id
        tab.Size = UDim2.new(0, 100, 1, 0)
        tab.BackgroundColor3 = i == 1 and Color3.fromRGB(100, 200, 255) or COLORS.CardBg
        tab.BackgroundTransparency = i == 1 and 0.2 or 0.6
        tab.BorderSizePixel = 0
        tab.Text = td.text
        tab.TextColor3 = COLORS.Text
        tab.Font = Enum.Font.GothamBold
        tab.TextSize = 12
        tab.LayoutOrder = i
        tab.ZIndex = 53
        tab.Parent = tabBar
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 8)

        self._tabButtons[td.id] = tab
        tab.MouseButton1Click:Connect(function()
            self._activeTab = td.id
            for tid, t in pairs(self._tabButtons) do
                t.BackgroundColor3 = tid == td.id and Color3.fromRGB(100, 200, 255) or COLORS.CardBg
                t.BackgroundTransparency = tid == td.id and 0.2 or 0.6
            end
            self:_refresh()
        end)
    end

    -- Scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "List"
    scroll.Size = UDim2.new(1, -20, 1, -100)
    scroll.Position = UDim2.new(0.5, 0, 0, 92)
    scroll.AnchorPoint = Vector2.new(0.5, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 200, 255)
    scroll.ZIndex = 52
    scroll.Parent = main
    self._scroll = scroll

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scroll

    return gui
end

function FriendController:_refresh()
    for _, child in ipairs(self._scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if self._activeTab == "friends" then
        self:_showFriends()
    elseif self._activeTab == "requests" then
        self:_showRequests()
    else
        self:_showPlayers()
    end
end

function FriendController:_showFriends()
    local friends = RemoteManager:InvokeServer("GetFriendsList")
    if not friends or #friends == 0 then
        self:_addEmptyLabel("ما عندك أصدقاء بعد")
        return
    end

    for i, f in ipairs(friends) do
        local row = self:_createRow(i)
        local statusDot = Instance.new("Frame")
        statusDot.Size = UDim2.new(0, 10, 0, 10)
        statusDot.Position = UDim2.new(0, 12, 0.5, 0)
        statusDot.AnchorPoint = Vector2.new(0, 0.5)
        statusDot.BackgroundColor3 = f.online and COLORS.Success or COLORS.TextDim
        statusDot.BorderSizePixel = 0
        statusDot.ZIndex = 54
        statusDot.Parent = row
        Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

        self:_addLabel(row, f.name, UDim2.new(0, 28, 0, 0))

        local removeBtn = self:_addButton(row, "حذف", COLORS.Danger)
        removeBtn.MouseButton1Click:Connect(function()
            RemoteManager:FireServer("RemoveFriend", f.userId)
            task.wait(0.3)
            self:_refresh()
        end)
    end
    self._scroll.CanvasSize = UDim2.new(0, 0, 0, #friends * 50 + 10)
end

function FriendController:_showRequests()
    local requests = RemoteManager:InvokeServer("GetFriendRequests")
    if not requests or #requests == 0 then
        self:_addEmptyLabel("ما فيه طلبات صداقة")
        return
    end

    for i, req in ipairs(requests) do
        local row = self:_createRow(i)
        self:_addLabel(row, req.fromName or "لاعب", UDim2.new(0, 12, 0, 0))

        local acceptBtn = self:_addButton(row, "قبول", COLORS.Success)
        acceptBtn.Position = UDim2.new(1, -100, 0.5, 0)
        acceptBtn.MouseButton1Click:Connect(function()
            RemoteManager:FireServer("AcceptFriendRequest", req.fromUserId)
            task.wait(0.3)
            self:_refresh()
        end)

        local declineBtn = self:_addButton(row, "رفض", COLORS.Danger)
        declineBtn.Position = UDim2.new(1, -10, 0.5, 0)
        declineBtn.Size = UDim2.new(0, 50, 0, 28)
        declineBtn.MouseButton1Click:Connect(function()
            RemoteManager:FireServer("DeclineFriendRequest", req.fromUserId)
            task.wait(0.3)
            self:_refresh()
        end)
    end
    self._scroll.CanvasSize = UDim2.new(0, 0, 0, #requests * 50 + 10)
end

function FriendController:_showPlayers()
    local count = 0
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            count = count + 1
            local row = self:_createRow(count)
            self:_addLabel(row, otherPlayer.DisplayName or otherPlayer.Name, UDim2.new(0, 12, 0, 0))

            local addBtn = self:_addButton(row, "إضافة", Color3.fromRGB(100, 200, 255))
            addBtn.MouseButton1Click:Connect(function()
                RemoteManager:FireServer("SendFriendRequest", otherPlayer.UserId)
                addBtn.Text = "..."
                task.delay(2, function()
                    if addBtn.Parent then addBtn.Text = "إضافة" end
                end)
            end)
        end
    end
    if count == 0 then self:_addEmptyLabel("ما فيه لاعبين ثانيين") end
    self._scroll.CanvasSize = UDim2.new(0, 0, 0, count * 50 + 10)
end

function FriendController:_createRow(order: number): Frame
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = COLORS.CardBg
    row.BackgroundTransparency = 0.4
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 53
    row.Parent = self._scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    return row
end

function FriendController:_addLabel(parent: Frame, text: string, position: UDim2): TextLabel
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.Position = position
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COLORS.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 54
    lbl.Parent = parent
    return lbl
end

function FriendController:_addButton(parent: Frame, text: string, color: Color3): TextButton
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 64, 0, 28)
    btn.Position = UDim2.new(1, -10, 0.5, 0)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 54
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

function FriendController:_addEmptyLabel(text: string)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 50)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COLORS.TextDim
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.ZIndex = 53
    lbl.Parent = self._scroll
    self._scroll.CanvasSize = UDim2.new(0, 0, 0, 60)
end

return FriendController
