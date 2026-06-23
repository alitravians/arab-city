local Utils = {}

function Utils.formatNumber(n: number): string
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    end
    return tostring(math.floor(n))
end

function Utils.formatCurrency(amount: number): string
    local formatted = tostring(math.floor(amount))
    local result = ""
    local count = 0
    for i = #formatted, 1, -1 do
        result = string.sub(formatted, i, i) .. result
        count += 1
        if count % 3 == 0 and i > 1 then
            result = "," .. result
        end
    end
    return result .. " $"
end

function Utils.lerp(a: number, b: number, t: number): number
    return a + (b - a) * math.clamp(t, 0, 1)
end

function Utils.lerpColor(c1: Color3, c2: Color3, t: number): Color3
    t = math.clamp(t, 0, 1)
    return Color3.new(
        Utils.lerp(c1.R, c2.R, t),
        Utils.lerp(c1.G, c2.G, t),
        Utils.lerp(c1.B, c2.B, t)
    )
end

function Utils.randomFromTable(tbl: { any }): any
    if #tbl == 0 then
        return nil
    end
    return tbl[math.random(1, #tbl)]
end

function Utils.shallowCopy(tbl: { [any]: any }): { [any]: any }
    return table.clone(tbl)
end

function Utils.deepCopy(tbl: { [any]: any }): { [any]: any }
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = Utils.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Utils.tableFind(tbl: { any }, value: any): number?
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

function Utils.getTimestamp(): number
    return DateTime.now().UnixTimestamp
end

function Utils.secondsToTimeString(seconds: number): string
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    end
    return string.format("%02d:%02d", minutes, secs)
end

function Utils.distanceBetween(pos1: Vector3, pos2: Vector3): number
    return (pos1 - pos2).Magnitude
end

function Utils.createSignal()
    local connections = {}
    local signal = {}

    function signal:Connect(callback)
        local connection = { callback = callback, connected = true }
        table.insert(connections, connection)
        return {
            Disconnect = function()
                connection.connected = false
                for i, conn in ipairs(connections) do
                    if conn == connection then
                        table.remove(connections, i)
                        break
                    end
                end
            end,
        }
    end

    function signal:Fire(...)
        for _, conn in ipairs(connections) do
            if conn.connected then
                task.spawn(conn.callback, ...)
            end
        end
    end

    return signal
end

return Utils
