local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DataManager -- forward ref

local RankService = {}

function RankService:Init(dataManager)
    DataManager = dataManager

    -- Check ranks on join
    Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            self:_checkPlayerRanks(player)
        end)
    end)

    -- Handle GamePass purchases
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
        if purchased then
            self:_onGamePassPurchased(player, gamePassId)
        end
    end)
end

function RankService:_checkPlayerRanks(player: Player)
    -- Wait for data to load
    local attempts = 0
    while not DataManager:GetData(player) and attempts < 50 do
        task.wait(0.1)
        attempts += 1
    end

    local highestRank = "None"
    local highestOrder = 0

    for rankName, rankData in pairs(Constants.RANKS) do
        if rankData.gamePassId > 0 then
            local success, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, rankData.gamePassId)
            end)
            if success and owns and rankData.order > highestOrder then
                highestRank = rankName
                highestOrder = rankData.order
            end
        end
    end

    if highestRank ~= "None" then
        DataManager:SetValue(player, "rank", highestRank)
        RemoteManager:FireClient("RankUpdate", player, highestRank)
        -- Trigger entry effect for all clients
        RemoteManager:FireAllClients("RankEffectTrigger", player.UserId, highestRank)
    end
end

function RankService:_onGamePassPurchased(player: Player, gamePassId: number)
    for rankName, rankData in pairs(Constants.RANKS) do
        if rankData.gamePassId == gamePassId then
            local currentRank = DataManager:GetValue(player, "rank") or "None"
            local currentOrder = 0
            if currentRank ~= "None" and Constants.RANKS[currentRank] then
                currentOrder = Constants.RANKS[currentRank].order
            end

            if rankData.order > currentOrder then
                DataManager:SetValue(player, "rank", rankName)
                RemoteManager:FireClient("RankUpdate", player, rankName)
                RemoteManager:FireAllClients("RankEffectTrigger", player.UserId, rankName)
            end
            break
        end
    end
end

function RankService:GetPlayerRank(player: Player): string
    return DataManager:GetValue(player, "rank") or "None"
end

function RankService:HasRank(player: Player, rankName: string): boolean
    local playerRank = self:GetPlayerRank(player)
    if playerRank == "None" then
        return false
    end
    local playerOrder = Constants.RANKS[playerRank] and Constants.RANKS[playerRank].order or 0
    local requiredOrder = Constants.RANKS[rankName] and Constants.RANKS[rankName].order or 0
    return playerOrder >= requiredOrder
end

function RankService:GetRankData(rankName: string)
    return Constants.RANKS[rankName]
end

return RankService
