--[[
    Arab City v2.0 - WeatherService
    Day/night cycle and weather — starts at morning (9 AM).
]]

local Lighting = game:GetService("Lighting")

local WeatherService = {}

local DAY_LENGTH = 720
local START_TIME = 9

function WeatherService:Init()
    Lighting.ClockTime = START_TIME
    Lighting.GeographicLatitude = 21.5
    Lighting.GlobalShadows = true
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    Lighting.Ambient = Color3.fromRGB(102, 102, 115)

    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        atmo.Density = 0.3
        atmo.Offset = 0.25
        atmo.Color = Color3.fromRGB(217, 191, 128)
        atmo.Decay = Color3.fromRGB(92, 99, 120)
    end

    task.spawn(function()
        self:_runCycle()
    end)
end

function WeatherService:_runCycle()
    local startTick = tick()
    while true do
        local elapsed = tick() - startTick
        local progress = (elapsed % DAY_LENGTH) / DAY_LENGTH
        local clockTime = (START_TIME + progress * 24) % 24
        Lighting.ClockTime = clockTime

        if clockTime >= 6 and clockTime < 18 then
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        else
            Lighting.Brightness = 0.5
            Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 80)
        end

        task.wait(1)
    end
end

return WeatherService
