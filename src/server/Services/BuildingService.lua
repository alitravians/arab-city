--[[
    Arab City v2.0 - BuildingService
    Connects MapBuilder ProximityPrompts to gameplay actions.
    Waits for MapBuilder to finish, then scans all prompts.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildingService = {}

local Shared, Constants, Remotes, DataService, EconomyService, JobService, XPService

-- Salary cooldown per-player (work zone)
local WORK_COOLDOWN = 60
local _lastWork = {}

function BuildingService:Init(dataService, economyService, jobService, xpService)
    DataService = dataService
    EconomyService = economyService
    JobService = jobService
    XPService = xpService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes

    task.spawn(function()
        self:_waitForBuildings()
    end)
end

function BuildingService:_waitForBuildings()
    local buildings = Workspace:WaitForChild("Buildings", 30)
    if not buildings then
        warn("[BuildingService] Buildings folder not found after 30s")
        return
    end

    -- Wait until MapBuilder finishes (at least 10 buildings expected)
    local maxWait = 30
    local waited = 0
    while #buildings:GetChildren() < 10 and waited < maxWait do
        task.wait(0.5)
        waited = waited + 0.5
    end
    task.wait(1)

    self:_connectAllPrompts(buildings)
    print("[BuildingService] Connected " .. tostring(#buildings:GetChildren()) .. " buildings")
end

function BuildingService:_connectAllPrompts(buildingsFolder)
    for _, building in ipairs(buildingsFolder:GetChildren()) do
        if not building:IsA("Model") then continue end

        local buildingType = building:GetAttribute("BuildingType") or string.lower(building.Name)

        for _, desc in ipairs(building:GetDescendants()) do
            if not desc:IsA("ProximityPrompt") then continue end

            local parentPart = desc.Parent
            local isWorkZone = parentPart and parentPart.Name == "WorkZone"

            if isWorkZone then
                desc.Triggered:Connect(function(player)
                    self:_onWork(player, buildingType)
                end)
            else
                desc.Triggered:Connect(function(player)
                    self:_onEnter(player, buildingType, building)
                end)
            end
        end
    end
end

function BuildingService:_onWork(player, buildingType)
    local data = DataService:Get(player)
    if not data then return end

    local userId = player.UserId
    local now = os.time()

    if _lastWork[userId] and (now - _lastWork[userId]) < WORK_COOLDOWN then
        local remaining = WORK_COOLDOWN - (now - _lastWork[userId])
        Remotes:FireClient("ShowNotification", player, {
            title = "انتظر!",
            message = "تقدر تشتغل مرة ثانية بعد " .. tostring(remaining) .. " ثانية",
            icon = "⏳",
            duration = 3,
        })
        return
    end

    -- Find player's job and salary
    local jobId = data.job or Constants.DEFAULT_JOB
    local job = nil
    for _, j in ipairs(Constants.JOBS) do
        if j.id == jobId then job = j break end
    end
    if not job then
        job = Constants.JOBS[1]
    end

    _lastWork[userId] = now
    EconomyService:AddCash(player, job.salary)
    if XPService then
        XPService:AddXP(player, Constants.XP_SOURCES.job_complete)
    end

    Remotes:FireClient("ShowNotification", player, {
        title = "💰 راتب!",
        message = "كسبت $" .. tostring(job.salary) .. " من العمل كـ " .. job.name,
        icon = job.icon,
        duration = 4,
    })

    Remotes:FireClient("UpdateCash", player, DataService:Get(player).cash)
end

function BuildingService:_onEnter(player, buildingType, building)
    local lower = string.lower(buildingType)

    if lower == "hospital" or string.find(lower, "hospital") then
        local character = player.Character
        if character then
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = hum.MaxHealth
            end
        end
        Remotes:FireClient("ShowNotification", player, {
            title = "🏥 المستشفى",
            message = "تم علاجك بالكامل! صحتك 100%",
            icon = "🏥",
            duration = 3,
        })

    elseif lower == "bank" or string.find(lower, "bank") then
        local data = DataService:Get(player)
        local cash = data and data.cash or 0
        Remotes:FireClient("ShowNotification", player, {
            title = "🏦 البنك",
            message = "رصيدك الحالي: $" .. tostring(cash),
            icon = "🏦",
            duration = 4,
        })

    elseif lower == "mall" or string.find(lower, "mall") then
        Remotes:FireClient("OpenShop", player)
        Remotes:FireClient("ShowNotification", player, {
            title = "🛍️ المول",
            message = "مرحباً! تصفّح المتجر واشتري ما تبي",
            icon = "🛍️",
            duration = 3,
        })

    elseif lower == "police" or string.find(lower, "police") then
        Remotes:FireClient("ShowNotification", player, {
            title = "🚔 مركز الشرطة",
            message = "تبي تصير شرطي؟ الراتب $200 — افتح الهاتف > الوظائف",
            icon = "👮",
            duration = 5,
        })
        Remotes:FireClient("ShowJobOffer", player, "police")

    elseif lower == "fire" or string.find(lower, "fire") then
        Remotes:FireClient("ShowNotification", player, {
            title = "🚒 محطة الإطفاء",
            message = "تبي تصير إطفائي؟ الراتب $180 — افتح الهاتف > الوظائف",
            icon = "🚒",
            duration = 5,
        })
        Remotes:FireClient("ShowJobOffer", player, "firefighter")

    elseif lower == "restaurant" or string.find(lower, "restaurant") then
        local data = DataService:Get(player)
        local jobId = data and data.job or Constants.DEFAULT_JOB
        local isWorker = jobId == "restaurant_worker" or jobId == "chef"
        if isWorker then
            Remotes:FireClient("ShowNotification", player, {
                title = "🍽️ المطعم — مكان عملك!",
                message = "روح لمنطقة العمل (الأصفر) واضغط عشان تكسب فلوس",
                icon = "🍽️",
                duration = 5,
            })
        else
            Remotes:FireClient("ShowNotification", player, {
                title = "🍽️ المطعم",
                message = "أهلاً! تبي تشتغل هنا؟ افتح الهاتف > الوظائف",
                icon = "🍽️",
                duration = 4,
            })
        end

    elseif lower == "airport" or string.find(lower, "airport") then
        Remotes:FireClient("ShowNotification", player, {
            title = "✈️ المطار",
            message = "مرحباً بك في المطار الدولي! تبي تصير طيار؟ الراتب $300",
            icon = "✈️",
            duration = 4,
        })
        Remotes:FireClient("ShowJobOffer", player, "pilot")

    elseif lower == "dealership" or string.find(lower, "dealer") then
        Remotes:FireClient("OpenVehicleShop", player)
        Remotes:FireClient("ShowNotification", player, {
            title = "🚗 معرض السيارات",
            message = "اختر سيارتك! افتح الهاتف > السيارات",
            icon = "🚗",
            duration = 4,
        })

    elseif lower == "villa" or string.find(lower, "villa") then
        local villaIndex = string.match(building.Name, "(%d+)")
        local propertyId = "villa"
        local data = DataService:Get(player)
        if data then
            local owned = false
            for _, p in ipairs(data.properties) do
                if p == propertyId then owned = true break end
            end
            if owned then
                Remotes:FireClient("ShowNotification", player, {
                    title = "🏠 بيتك",
                    message = "أهلاً بك في بيتك! فيلا رقم " .. (villaIndex or ""),
                    icon = "🏠",
                    duration = 3,
                })
            else
                local property = nil
                for _, pr in ipairs(Constants.PROPERTIES) do
                    if pr.id == propertyId then property = pr break end
                end
                local price = property and property.price or 50000
                Remotes:FireClient("ShowNotification", player, {
                    title = "🏠 فيلا للبيع",
                    message = "السعر: $" .. tostring(price) .. " — افتح الهاتف > العقارات للشراء",
                    icon = "🏠",
                    duration = 5,
                })
                Remotes:FireClient("ShowPropertyOffer", player, propertyId)
            end
        end

    elseif lower == "hotel" or string.find(lower, "hotel") then
        Remotes:FireClient("ShowNotification", player, {
            title = "🏨 الفندق",
            message = "مرحباً! الغرف متاحة — شوف العقارات من الهاتف",
            icon = "🏨",
            duration = 4,
        })

    elseif lower == "school" or string.find(lower, "school") then
        Remotes:FireClient("ShowNotification", player, {
            title = "🏫 المدرسة",
            message = "التعليم يرفع مستواك! أكمل المهمات عشان تحصل XP",
            icon = "🏫",
            duration = 4,
        })

    elseif lower == "gasstation" or lower == "gas_station" or string.find(lower, "gas") then
        Remotes:FireClient("ShowNotification", player, {
            title = "⛽ محطة الوقود",
            message = "تبي تشتغل ميكانيكي؟ الراتب $170",
            icon = "⛽",
            duration = 4,
        })
        Remotes:FireClient("ShowJobOffer", player, "mechanic")

    elseif lower == "mosque" or string.find(lower, "mosque") then
        Remotes:FireClient("ShowNotification", player, {
            title = "🕌 المسجد",
            message = "مرحباً بك في المسجد",
            icon = "🕌",
            duration = 3,
        })

    else
        Remotes:FireClient("ShowNotification", player, {
            title = buildingType,
            message = "مرحباً بك!",
            icon = "🏢",
            duration = 3,
        })
    end
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    _lastWork[player.UserId] = nil
end)

return BuildingService
