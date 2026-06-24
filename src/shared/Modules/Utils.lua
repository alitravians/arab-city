--[[
    Arab City v2.0 - Utils
    Shared utility functions.
]]

local Utils = {}

function Utils.formatCash(amount)
    local formatted = tostring(math.floor(amount))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return "$" .. formatted
end

function Utils.lerp(a, b, t)
    return a + (b - a) * math.clamp(t, 0, 1)
end

function Utils.lerpColor(c1, c2, t)
    t = math.clamp(t, 0, 1)
    return Color3.new(
        Utils.lerp(c1.R, c2.R, t),
        Utils.lerp(c1.G, c2.G, t),
        Utils.lerp(c1.B, c2.B, t)
    )
end

function Utils.shallowCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

function Utils.deepCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = Utils.deepCopy(v)
    end
    return copy
end

function Utils.findInArray(arr, predicate)
    for i, v in ipairs(arr) do
        if predicate(v, i) then
            return v, i
        end
    end
    return nil, nil
end

function Utils.findById(arr, id)
    return Utils.findInArray(arr, function(item)
        return item.id == id
    end)
end

function Utils.tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

function Utils.clampCash(amount, maxCash)
    return math.clamp(math.floor(amount), 0, maxCash or 999999999)
end

function Utils.randomFromArray(arr)
    if #arr == 0 then return nil end
    local rng = Random.new()
    return arr[rng:NextInteger(1, #arr)]
end

function Utils.createTween(instance, tweenInfo, properties)
    local TweenService = game:GetService("TweenService")
    return TweenService:Create(instance, tweenInfo, properties)
end

function Utils.makeRoundedFrame(props)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = props.color or Color3.fromRGB(30, 38, 55)
    frame.BackgroundTransparency = props.transparency or 0
    frame.Size = props.size or UDim2.new(0, 100, 0, 50)
    frame.Position = props.position or UDim2.new(0, 0, 0, 0)
    frame.AnchorPoint = props.anchor or Vector2.new(0, 0)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, props.radius or 8)
    corner.Parent = frame

    if props.parent then
        frame.Parent = props.parent
    end

    return frame
end

function Utils.makeTextLabel(props)
    local label = Instance.new("TextLabel")
    label.Text = props.text or ""
    label.TextColor3 = props.color or Color3.fromRGB(255, 255, 255)
    label.TextSize = props.textSize or 14
    label.Font = props.font or Enum.Font.GothamBold
    label.BackgroundTransparency = 1
    label.Size = props.size or UDim2.new(1, 0, 0, 30)
    label.Position = props.position or UDim2.new(0, 0, 0, 0)
    label.TextXAlignment = props.alignX or Enum.TextXAlignment.Center
    label.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
    label.RichText = true

    if props.parent then
        label.Parent = props.parent
    end

    return label
end

function Utils.makeTextButton(props)
    local btn = Instance.new("TextButton")
    btn.Text = props.text or "Button"
    btn.TextColor3 = props.textColor or Color3.fromRGB(255, 255, 255)
    btn.TextSize = props.textSize or 14
    btn.Font = props.font or Enum.Font.GothamBold
    btn.BackgroundColor3 = props.color or Color3.fromRGB(0, 170, 255)
    btn.Size = props.size or UDim2.new(0, 120, 0, 36)
    btn.Position = props.position or UDim2.new(0, 0, 0, 0)
    btn.AnchorPoint = props.anchor or Vector2.new(0, 0)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, props.radius or 6)
    corner.Parent = btn

    if props.parent then
        btn.Parent = props.parent
    end

    return btn
end

function Utils.makeScrollingFrame(props)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = props.size or UDim2.new(1, 0, 1, 0)
    scroll.Position = props.position or UDim2.new(0, 0, 0, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = props.scrollBarThickness or 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, props.padding or 4)
    layout.Parent = scroll

    if props.parent then
        scroll.Parent = props.parent
    end

    return scroll
end

return Utils
