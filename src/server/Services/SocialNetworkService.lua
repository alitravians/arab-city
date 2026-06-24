local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Utils = Shared.Utils
local RemoteManager = Shared.RemoteManager

local DataManager

local SocialNetworkService = {}
SocialNetworkService._globalFeed = {} -- Most recent posts across all players
SocialNetworkService._maxFeedSize = 100

function SocialNetworkService:Init(dataManager)
    DataManager = dataManager

    RemoteManager:OnServerEvent("CreatePost", function(player, content, photoId)
        self:CreatePost(player, content, photoId)
    end)

    RemoteManager:OnServerEvent("LikePost", function(player, postOwnerId, postIndex)
        self:LikePost(player, postOwnerId, postIndex)
    end)

    RemoteManager:OnServerEvent("CommentOnPost", function(player, postOwnerId, postIndex, comment)
        self:CommentOnPost(player, postOwnerId, postIndex, comment)
    end)

    RemoteManager:OnServerEvent("FollowPlayer", function(player, targetUserId)
        self:FollowPlayer(player, targetUserId)
    end)

    RemoteManager:OnServerEvent("UnfollowPlayer", function(player, targetUserId)
        self:UnfollowPlayer(player, targetUserId)
    end)

    RemoteManager:SetServerCallback("GetSocialFeed", function(player, feedType)
        return self:GetFeed(player, feedType)
    end)

    RemoteManager:SetServerCallback("GetPlayerProfile", function(player, targetUserId)
        return self:GetProfile(player, targetUserId)
    end)

    RemoteManager:SetServerCallback("GetLeaderboard", function(_player)
        return self:GetLeaderboard()
    end)
end

function SocialNetworkService:CreatePost(player: Player, content: string, photoId: string?)
    if type(content) ~= "string" or #content < 1 or #content > 280 then
        RemoteManager:FireClient("CodeResult", player, false, "المحتوى يجب أن يكون بين 1 و 280 حرفاً!")
        return
    end

    local post = {
        authorId = player.UserId,
        authorName = player.DisplayName,
        content = content,
        photoId = photoId or "",
        timestamp = Utils.getTimestamp(),
        likes = {},
        comments = {},
        views = 0,
    }

    -- Add to player's posts
    DataManager:AddToTable(player, "posts", post)
    local playerPosts = DataManager:GetValue(player, "posts") or {}
    local postIndex = #playerPosts

    -- Add to global feed
    table.insert(self._globalFeed, 1, {
        authorId = player.UserId,
        authorName = player.DisplayName,
        content = content,
        photoId = photoId or "",
        timestamp = post.timestamp,
        likeCount = 0,
        commentCount = 0,
        views = 0,
        postIndex = postIndex,
    })

    -- Trim global feed
    while #self._globalFeed > self._maxFeedSize do
        table.remove(self._globalFeed)
    end

    -- Increment fame
    DataManager:IncrementValue(player, "fame", 1)

    RemoteManager:FireClient("CodeResult", player, true, "تم نشر المنشور بنجاح!")
    RemoteManager:FireAllClients("SocialFeedUpdate", "new_post", {
        authorId = player.UserId,
        authorName = player.DisplayName,
    })
end

function SocialNetworkService:LikePost(player: Player, postOwnerId: number, postIndex: number)
    if type(postOwnerId) ~= "number" or type(postIndex) ~= "number" then
        return
    end

    local ownerPlayer = Players:GetPlayerByUserId(postOwnerId)
    if not ownerPlayer then
        return
    end

    local posts = DataManager:GetValue(ownerPlayer, "posts") or {}
    if postIndex < 1 or postIndex > #posts then
        return
    end

    local post = posts[postIndex]

    -- Check if already liked
    for _, likerId in ipairs(post.likes) do
        if likerId == player.UserId then
            return
        end
    end

    table.insert(post.likes, player.UserId)
    post.views += 1
    DataManager:SetValue(ownerPlayer, "posts", posts)
    DataManager:IncrementValue(ownerPlayer, "fame", 1)

    self:_updateGlobalFeedEntry(postOwnerId, postIndex, #post.likes, #post.comments)

    RemoteManager:FireClient("SocialProfileUpdate", ownerPlayer, "like", postIndex, player.Name)
end

function SocialNetworkService:CommentOnPost(player: Player, postOwnerId: number, postIndex: number, comment: string)
    if type(postOwnerId) ~= "number" or type(postIndex) ~= "number" then
        return
    end
    if type(comment) ~= "string" or #comment < 1 or #comment > 200 then
        return
    end

    local ownerPlayer = Players:GetPlayerByUserId(postOwnerId)
    if not ownerPlayer then
        return
    end

    local posts = DataManager:GetValue(ownerPlayer, "posts") or {}
    if postIndex < 1 or postIndex > #posts then
        return
    end

    table.insert(posts[postIndex].comments, {
        authorId = player.UserId,
        authorName = player.DisplayName,
        content = comment,
        timestamp = Utils.getTimestamp(),
    })

    DataManager:SetValue(ownerPlayer, "posts", posts)
    DataManager:IncrementValue(ownerPlayer, "fame", 1)

    self:_updateGlobalFeedEntry(postOwnerId, postIndex, #posts[postIndex].likes, #posts[postIndex].comments)

    RemoteManager:FireClient("SocialProfileUpdate", ownerPlayer, "comment", postIndex, player.Name)
end

function SocialNetworkService:FollowPlayer(player: Player, targetUserId: number)
    if targetUserId == player.UserId then
        return
    end

    local following = DataManager:GetValue(player, "following") or {}
    for _, id in ipairs(following) do
        if id == targetUserId then
            RemoteManager:FireClient("CodeResult", player, false, "أنت تتابع هذا اللاعب بالفعل!")
            return
        end
    end

    DataManager:AddToTable(player, "following", targetUserId)

    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if targetPlayer then
        DataManager:AddToTable(targetPlayer, "followers", player.UserId)
        DataManager:IncrementValue(targetPlayer, "fame", 5)
        RemoteManager:FireClient("SocialProfileUpdate", targetPlayer, "new_follower", player.UserId, player.Name)
    end

    RemoteManager:FireClient("CodeResult", player, true, "تمت المتابعة بنجاح!")
end

function SocialNetworkService:UnfollowPlayer(player: Player, targetUserId: number)
    DataManager:RemoveFromTable(player, "following", targetUserId)

    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if targetPlayer then
        DataManager:RemoveFromTable(targetPlayer, "followers", player.UserId)
    end

    RemoteManager:FireClient("CodeResult", player, true, "تم إلغاء المتابعة.")
end

function SocialNetworkService:GetFeed(player: Player, feedType: string?)
    if feedType == "following" then
        local following = DataManager:GetValue(player, "following") or {}
        local feed = {}
        for _, entry in ipairs(self._globalFeed) do
            for _, followId in ipairs(following) do
                if entry.authorId == followId then
                    table.insert(feed, entry)
                    break
                end
            end
            if #feed >= 50 then
                break
            end
        end
        return feed
    end

    -- Default: global feed
    local feed = {}
    for i = 1, math.min(50, #self._globalFeed) do
        table.insert(feed, self._globalFeed[i])
    end
    return feed
end

function SocialNetworkService:GetProfile(_requestor: Player, targetUserId: number)
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then
        return nil
    end

    local data = DataManager:GetData(targetPlayer)
    if not data then
        return nil
    end

    return {
        userId = targetUserId,
        displayName = targetPlayer.DisplayName,
        username = targetPlayer.Name,
        fame = data.fame or 0,
        followers = #(data.followers or {}),
        following = #(data.following or {}),
        posts = data.posts or {},
        cameraType = data.cameraType or "Beginner",
        level = data.level or 1,
        rank = data.rank or "None",
    }
end

function SocialNetworkService:GetLeaderboard()
    local players = Players:GetPlayers()
    local leaderboard = {}

    for _, player in ipairs(players) do
        local data = DataManager:GetData(player)
        if data then
            table.insert(leaderboard, {
                userId = player.UserId,
                displayName = player.DisplayName,
                fame = data.fame or 0,
                followers = #(data.followers or {}),
                rank = data.rank or "None",
            })
        end
    end

    table.sort(leaderboard, function(a, b)
        return a.fame > b.fame
    end)

    -- Return top 50
    local top = {}
    for i = 1, math.min(50, #leaderboard) do
        top[i] = leaderboard[i]
    end
    return top
end

function SocialNetworkService:_updateGlobalFeedEntry(authorId: number, postIndex: number, likeCount: number, commentCount: number)
    for _, entry in ipairs(self._globalFeed) do
        if entry.authorId == authorId and entry.postIndex == postIndex then
            entry.likeCount = likeCount
            entry.commentCount = commentCount
            break
        end
    end
end

return SocialNetworkService
