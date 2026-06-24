--[[
    Arab City v2.0 - LoadingScreen
    Cinematic loading screen with progress bar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local LoadingScreen = {}

local player = Players.LocalPlayer

function LoadingScreen:Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "LoadingGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.IgnoreGuiInset = true
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Full-screen background
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
    bg.BorderSizePixel = 0
    bg.Parent = gui

    -- City name
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0.3, 0)
    title.BackgroundTransparency = 1
    title.Text = "Arab City"
    title.TextSize = 48
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(0, 180, 255)
    title.Parent = bg

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 30)
    subtitle.Position = UDim2.new(0, 0, 0.3, 60)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "مدينة عربية مفتوحة"
    subtitle.TextSize = 18
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextColor3 = Color3.fromRGB(180, 200, 220)
    subtitle.Parent = bg

    -- Progress bar background
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0.5, 0, 0, 8)
    barBg.Position = UDim2.new(0.25, 0, 0.6, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    barBg.BorderSizePixel = 0
    barBg.Parent = bg
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 0.6, 15)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "جاري التحميل..."
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextColor3 = Color3.fromRGB(150, 160, 180)
    statusLabel.Parent = bg

    -- Tips
    local tips = {
        "💡 اضغط V لتغيير الكاميرا",
        "💡 اشتري سيارة من معرض السيارات",
        "💡 ابحث عن وظيفة في المباني",
        "💡 استخدم الهاتف للوصول لجميع الخدمات",
        "💡 أكمل المهمات اليومية للمكافآت",
    }

    local tipLabel = Instance.new("TextLabel")
    tipLabel.Size = UDim2.new(1, 0, 0, 20)
    tipLabel.Position = UDim2.new(0, 0, 0.75, 0)
    tipLabel.BackgroundTransparency = 1
    tipLabel.Text = tips[math.random(#tips)]
    tipLabel.TextSize = 13
    tipLabel.Font = Enum.Font.Gotham
    tipLabel.TextColor3 = Color3.fromRGB(120, 130, 150)
    tipLabel.Parent = bg

    -- Animate loading
    task.spawn(function()
        -- Wait for game to load
        if not game:IsLoaded() then
            game.Loaded:Wait()
        end

        statusLabel.Text = "جاري تحميل الأصول..."

        local assets = {}
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("BasePart") or desc:IsA("Texture") or desc:IsA("Decal") then
                table.insert(assets, desc)
            end
        end

        local total = math.max(#assets, 1)
        local loaded = 0

        for _, asset in ipairs(assets) do
            pcall(function()
                ContentProvider:PreloadAsync({ asset })
            end)
            loaded = loaded + 1
            local ratio = loaded / total
            TweenService:Create(barFill, TweenInfo.new(0.1), {
                Size = UDim2.new(ratio, 0, 1, 0),
            }):Play()
        end

        statusLabel.Text = "جاهز!"
        TweenService:Create(barFill, TweenInfo.new(0.3), {
            Size = UDim2.new(1, 0, 1, 0),
        }):Play()

        task.wait(1)

        -- Fade out
        TweenService:Create(bg, TweenInfo.new(0.8), {
            BackgroundTransparency = 1,
        }):Play()

        for _, child in ipairs(bg:GetDescendants()) do
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.8), {
                    TextTransparency = 1,
                }):Play()
            elseif child:IsA("Frame") then
                TweenService:Create(child, TweenInfo.new(0.8), {
                    BackgroundTransparency = 1,
                }):Play()
            end
        end

        task.wait(1)
        gui:Destroy()
    end)
end

return LoadingScreen
