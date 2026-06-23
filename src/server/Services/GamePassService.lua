--[[
    Arab City - Game Pass Service
    Manages game pass ownership, benefits, and purchase prompts.
    Game Pass IDs are placeholders (0) — replace with actual IDs from Creator Hub.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local DataManager

local GamePassService = {}
GamePassService._ownedPasses = {} -- [userId] = { passName = true }

function GamePassService:Init(dataManager)
    DataManager = dataManager

    Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            self:_loadPlayerPasses(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self._ownedPasses[player.UserId] = nil
    end)

    -- Handle purchases
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
        if purchased then
            self:_onPassPurchased(player, gamePassId)
        end
    end)

    -- Client requests to prompt a purchase
    RemoteManager:OnServerEvent("GamePassPrompt", function(player, passName)
        self:PromptPurchase(player, passName)
    end)

    -- Client queries owned passes
    RemoteManager:SetServerCallback("GetOwnedGamePasses", function(player)
        return self:GetOwnedPasses(player)
    end)

    -- Apply speed benefit periodically
    task.spawn(function()
        while true do
            task.wait(5)
            for _, player in ipairs(Players:GetPlayers()) do
                self:_applySpeedBenefit(player)
            end
        end
    end)
end

function GamePassService:_loadPlayerPasses(player: Player)
    self._ownedPasses[player.UserId] = {}

    -- Wait for data
    local attempts = 0
    while not DataManager:GetData(player) and attempts < 50 do
        task.wait(0.2)
        attempts += 1
    end

    for _, pass in ipairs(Constants.GAME_PASSES) do
        if pass.id > 0 then
            local success, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
            end)
            if success and owns then
                self._ownedPasses[player.UserId][pass.name] = true
            end
        end
    end

    -- Notify client of owned passes
    RemoteManager:FireClient("GamePassOwned", player, self._ownedPasses[player.UserId] or {})
end

function GamePassService:_onPassPurchased(player: Player, gamePassId: number)
    for _, pass in ipairs(Constants.GAME_PASSES) do
        if pass.id == gamePassId then
            if not self._ownedPasses[player.UserId] then
                self._ownedPasses[player.UserId] = {}
            end
            self._ownedPasses[player.UserId][pass.name] = true
            RemoteManager:FireClient("GamePassOwned", player, self._ownedPasses[player.UserId])

            RemoteManager:FireClient("BuildingAction", player, {
                type = "notification",
                title = "Game Pass",
                message = "تم شراء " .. pass.nameAr .. " بنجاح!",
                icon = "gamepass",
            })
            break
        end
    end
end

function GamePassService:PromptPurchase(player: Player, passName: string)
    for _, pass in ipairs(Constants.GAME_PASSES) do
        if pass.name == passName and pass.id > 0 then
            MarketplaceService:PromptGamePassPurchase(player, pass.id)
            return
        end
    end
end

function GamePassService:OwnsPass(player: Player, passName: string): boolean
    local owned = self._ownedPasses[player.UserId]
    if owned then
        return owned[passName] == true
    end
    return false
end

function GamePassService:HasBenefit(player: Player, benefit: string): boolean
    local owned = self._ownedPasses[player.UserId]
    if not owned then
        return false
    end
    for _, pass in ipairs(Constants.GAME_PASSES) do
        if owned[pass.name] then
            for _, b in ipairs(pass.benefits) do
                if b == benefit then
                    return true
                end
            end
        end
    end
    return false
end

function GamePassService:GetOwnedPasses(player: Player): { [string]: boolean }
    return self._ownedPasses[player.UserId] or {}
end

function GamePassService:GetMoneyMultiplier(player: Player): number
    if self:HasBenefit(player, "doubleMoney") then
        return 2
    end
    return 1
end

function GamePassService:_applySpeedBenefit(player: Player)
    if not self:HasBenefit(player, "extraSpeed") then
        return
    end
    local character = player.Character
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.WalkSpeed < 24 then
        humanoid.WalkSpeed = 24 -- 50% faster than default 16
    end
end

return GamePassService
