--[[
    Arab City v2.0 - BadgeService
    Achievement / badge system (in-memory tracking, no real Roblox badge IDs).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArabBadgeService = {}

local Shared, Remotes, DataService

local BADGES = {
    { id = "welcome",     name = "مرحباً بك",    description = "دخلت اللعبة لأول مرة",     icon = "🎉" },
    { id = "first_car",   name = "سائق جديد",    description = "اشتريت أول سيارة",          icon = "🚗" },
    { id = "first_house", name = "مالك عقار",     description = "اشتريت أول بيت",            icon = "🏠" },
    { id = "employed",    name = "موظف",          description = "حصلت على أول وظيفة",        icon = "💼" },
    { id = "rich",        name = "مليونير",       description = "جمعت مليون دولار",          icon = "💰" },
    { id = "explorer",    name = "مستكشف",        description = "زرت كل المباني",            icon = "🗺️" },
    { id = "social",      name = "اجتماعي",       description = "أرسلت 100 رسالة",           icon = "💬" },
    { id = "veteran",     name = "محارب قديم",    description = "وصلت مستوى 50",             icon = "⭐" },
}

function ArabBadgeService:Init(dataService)
    DataService = dataService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Remotes = Shared.Remotes
end

function ArabBadgeService:Award(player, badgeId)
    local data = DataService:Get(player)
    if not data then return end

    if not data.badges then
        data.badges = {}
    end
    for _, owned in ipairs(data.badges) do
        if owned == badgeId then return end
    end

    local badge = nil
    for _, b in ipairs(BADGES) do
        if b.id == badgeId then badge = b break end
    end
    if not badge then return end

    table.insert(data.badges, badgeId)
    Remotes:FireClient("BadgeAwarded", player, {
        badgeId = badgeId,
        name = badge.name,
        description = badge.description,
        icon = badge.icon,
    })
    Remotes:FireClient("ShowNotification", player, {
        title = "إنجاز جديد!",
        message = badge.name .. " — " .. badge.description,
        icon = badge.icon, duration = 5,
    })
end

function ArabBadgeService:GetBadges()
    return BADGES
end

return ArabBadgeService
