--[[
    Arab City v2.0 - GamePassService
    Game pass ownership tracking and perks.
    (Real MarketplaceService checks require valid GamePass IDs on Roblox.)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GamePassService = {}

local Shared, Constants, Remotes

function GamePassService:Init()
    Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
    Constants = Shared.Constants
    Remotes = Shared.Remotes
end

function GamePassService:GetMultiplier(player)
    -- placeholder: returns 1.0 until real GamePass IDs are set
    return 1.0
end

function GamePassService:HasPass(player, passId)
    -- placeholder
    return false
end

return GamePassService
