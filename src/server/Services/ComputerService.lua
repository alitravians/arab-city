local _Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local RemoteManager = Shared.RemoteManager

local DataManager
local SocialNetworkService

local ComputerService = {}

function ComputerService:Init(dataManager, socialNetworkService)
    DataManager = dataManager
    SocialNetworkService = socialNetworkService

    RemoteManager:OnServerEvent("ComputerInteract", function(player, action, ...)
        self:HandleInteraction(player, action, ...)
    end)
end

function ComputerService:HandleInteraction(player: Player, action: string, ...)
    local args = { ... }

    if action == "browse_social" then
        local feed = SocialNetworkService:GetFeed(player, "global")
        RemoteManager:FireClient("ComputerInteract", player, "social_feed", feed)

    elseif action == "view_profile" then
        local targetUserId = args[1]
        if type(targetUserId) == "number" then
            local profile = SocialNetworkService:GetProfile(player, targetUserId)
            RemoteManager:FireClient("ComputerInteract", player, "profile_data", profile)
        end

    elseif action == "view_stats" then
        local data = DataManager:GetData(player)
        if data then
            local stats = {
                cash = data.cash,
                level = data.level,
                fame = data.fame,
                followers = #(data.followers or {}),
                following = #(data.following or {}),
                posts = #(data.posts or {}),
                photos = data.photosTaken,
                properties = #(data.ownedProperties or {}),
                vehicles = #(data.ownedVehicles or {}),
                achievements = #(data.achievements or {}),
                playTime = data.playTime,
                totalEarned = data.totalEarned,
            }
            RemoteManager:FireClient("ComputerInteract", player, "stats_data", stats)
        end

    elseif action == "leaderboard" then
        local leaderboard = SocialNetworkService:GetLeaderboard()
        RemoteManager:FireClient("ComputerInteract", player, "leaderboard_data", leaderboard)
    end
end

return ComputerService
