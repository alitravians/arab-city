local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("ArabCity_Shared"))
local Constants = Shared.Constants
local RemoteManager = Shared.RemoteManager

local WeatherService = {}
WeatherService._currentWeather = "Clear"
WeatherService._timeOfDay = 12 -- hours (0-24)

function WeatherService:Init()
    self:_setupLighting()
    self:_startDayCycle()
    self:_startWeatherCycle()
end

function WeatherService:_setupLighting()
    Lighting.GlobalShadows = true
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)

    -- Atmosphere
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = 0.3
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(199, 170, 107) -- sandy warmth
    atmosphere.Decay = Color3.fromRGB(92, 60, 13)
    atmosphere.Glare = 0.3
    atmosphere.Haze = 2

    -- Sky
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end
    sky.StarCount = 3000

    -- Bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Parent = Lighting
    end
    bloom.Intensity = 0.5
    bloom.Size = 24
    bloom.Threshold = 0.8

    -- ColorCorrection
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Parent = Lighting
    end
    cc.Brightness = 0.05
    cc.Contrast = 0.1
    cc.Saturation = 0.15
end

function WeatherService:_startDayCycle()
    task.spawn(function()
        while true do
            local cycleDuration = Constants.DAY_CYCLE_DURATION
            local increment = 24 / cycleDuration -- hours per second

            self._timeOfDay += increment
            if self._timeOfDay >= 24 then
                self._timeOfDay -= 24
            end

            -- Set clock time
            Lighting.ClockTime = self._timeOfDay

            -- Adjust lighting based on time
            self:_updateLightingForTime()

            task.wait(1)
        end
    end)
end

function WeatherService:_updateLightingForTime()
    local hour = self._timeOfDay
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

    if hour >= 6 and hour < 8 then
        -- Sunrise
        Lighting.Brightness = 1 + (hour - 6) / 2
        Lighting.OutdoorAmbient = Color3.fromRGB(
            128 + math.floor((hour - 6) / 2 * 50),
            100 + math.floor((hour - 6) / 2 * 50),
            80
        )
        if atmosphere then
            atmosphere.Color = Color3.fromRGB(255, 180, 100)
        end
    elseif hour >= 8 and hour < 17 then
        -- Daytime
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        if atmosphere then
            atmosphere.Color = Color3.fromRGB(199, 170, 107)
        end
    elseif hour >= 17 and hour < 19 then
        -- Sunset
        local t = (hour - 17) / 2
        Lighting.Brightness = 2 - t
        Lighting.OutdoorAmbient = Color3.fromRGB(
            178 - math.floor(t * 100),
            178 - math.floor(t * 120),
            178 - math.floor(t * 130)
        )
        if atmosphere then
            atmosphere.Color = Color3.fromRGB(255, 120, 50)
        end
    else
        -- Night
        Lighting.Brightness = 0.5
        Lighting.OutdoorAmbient = Color3.fromRGB(40, 40, 60)
        if atmosphere then
            atmosphere.Color = Color3.fromRGB(20, 20, 50)
        end
    end
end

function WeatherService:_startWeatherCycle()
    task.spawn(function()
        while true do
            -- Change weather every 5-10 minutes
            task.wait(math.random(300, 600))
            local weatherTypes = Constants.WEATHER_TYPES
            local newWeather = weatherTypes[math.random(1, #weatherTypes)]
            self:SetWeather(newWeather)
        end
    end)
end

function WeatherService:SetWeather(weatherType: string)
    self._currentWeather = weatherType
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

    if weatherType == "Clear" then
        if atmosphere then
            atmosphere.Density = 0.3
            atmosphere.Haze = 2
        end
        Lighting.FogEnd = 100000

    elseif weatherType == "Rain" then
        if atmosphere then
            atmosphere.Density = 0.5
            atmosphere.Haze = 8
        end
        Lighting.FogEnd = 500
        Lighting.FogColor = Color3.fromRGB(120, 120, 140)

    elseif weatherType == "Fog" then
        if atmosphere then
            atmosphere.Density = 0.8
            atmosphere.Haze = 10
        end
        Lighting.FogEnd = 200
        Lighting.FogColor = Color3.fromRGB(180, 180, 190)
    end

    RemoteManager:FireAllClients("WeatherChange", weatherType)
end

function WeatherService:GetCurrentWeather(): string
    return self._currentWeather
end

function WeatherService:GetTimeOfDay(): number
    return self._timeOfDay
end

return WeatherService
