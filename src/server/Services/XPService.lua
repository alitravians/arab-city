--[[
    Arab City v2.0 - XPService
    Experience points and leveling system.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local XPService = {}

local Shared, Constants, Remotes, DataService

function XPService:Init(dataService)
    DataService = dataService
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes
end

function XPService:AddXP(player, amount)
    if type(amount) ~= "number" or amount <= 0 then return end
    local data = DataService:Get(player)
    if not data then return end

    data.xp = data.xp + math.floor(amount)

    local leveledUp = false
    while data.xp >= Constants.XP_PER_LEVEL and data.level < Constants.MAX_LEVEL do
        data.xp = data.xp - Constants.XP_PER_LEVEL
        data.level = data.level + 1
        leveledUp = true
    end

    Remotes:FireClient("XPUpdate", player, {
        xp = data.xp,
        level = data.level,
        xpNeeded = Constants.XP_PER_LEVEL,
    })

    if leveledUp then
        Remotes:FireClient("ShowNotification", player, {
            title = "ارتقيت مستوى!",
            message = "أصبحت مستوى " .. tostring(data.level),
            icon = "⬆️", duration = 5,
        })
    end
end

function XPService:GetLevel(player)
    local data = DataService:Get(player)
    return data and data.level or 1
end

return XPService
