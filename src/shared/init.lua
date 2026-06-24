--[[
    Arab City v2.0 - Shared Module
    Central hub for constants, remote management, and utilities.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = {}

Shared.Constants = require(script:WaitForChild("Modules"):WaitForChild("Constants"))
Shared.Remotes = require(script:WaitForChild("Modules"):WaitForChild("RemoteManager"))
Shared.Utils = require(script:WaitForChild("Modules"):WaitForChild("Utils"))

return Shared
