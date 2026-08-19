--!strict

local Decoder = {}

local function finite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function number(value: any, name: string): number
	assert(finite(value), name .. " must be finite")
	return value
end

local function enum(value: string): EnumItem
	local enumTypeName, itemName = string.match(value, "^Enum%.([%w_]+)%.([%w_]+)$")
	assert(enumTypeName and itemName, "enum values must use Enum.Type.Item")
	local enumType = (Enum :: any)[enumTypeName]
	assert(enumType ~= nil and enumType[itemName] ~= nil, "unknown enum value")
	return enumType[itemName]
end

function Decoder.decode(value: any): any
	if type(value) ~= "table" then
		if type(value) == "string" and string.sub(value, 1, 5) == "Enum." then
			return enum(value)
		end
		return value
	end
	if value.kind == "Color3" then
		return Color3.new(number(value.r, "r"), number(value.g, "g"), number(value.b, "b"))
	elseif value.kind == "Color3RGB" then
		return Color3.fromRGB(number(value.r, "r"), number(value.g, "g"), number(value.b, "b"))
	elseif value.kind == "Vector2" then
		return Vector2.new(number(value.x, "x"), number(value.y, "y"))
	elseif value.kind == "UDim" then
		return UDim.new(number(value.scale, "scale"), number(value.offset, "offset"))
	elseif value.kind == "UDim2" or value.xScale ~= nil then
		return UDim2.new(
			number(value.xScale, "xScale"),
			number(value.xOffset, "xOffset"),
			number(value.yScale, "yScale"),
			number(value.yOffset, "yOffset")
		)
	elseif value.kind == "Rect" then
		return Rect.new(
			number(value.minX, "minX"),
			number(value.minY, "minY"),
			number(value.maxX, "maxX"),
			number(value.maxY, "maxY")
		)
	elseif value.kind == "AssetReference" or value.assetId ~= nil then
		assert(type(value.assetId) == "string", "assetId must be a string")
		if string.match(value.assetId, "^%d+$") then
			return "rbxassetid://" .. value.assetId
		end
		return value.assetId
	elseif value.kind == "NumberSequence" then
		local points = {}
		for _, point in ipairs(value.keypoints or {}) do
			points[#points + 1] = NumberSequenceKeypoint.new(
				number(point.time, "time"),
				number(point.value, "value"),
				number(point.envelope or 0, "envelope")
			)
		end
		return NumberSequence.new(points)
	elseif value.kind == "ColorSequence" then
		local points = {}
		for _, point in ipairs(value.keypoints or {}) do
			points[#points + 1] =
				ColorSequenceKeypoint.new(number(point.time, "time"), Decoder.decode(point.color))
		end
		return ColorSequence.new(points)
	end
	error("unsupported structured Roblox value")
end

function Decoder.decodeProperty(propertyName: string, value: any): any
	if propertyName == "FontFace" and type(value) == "string" then
		return Font.fromName(value)
	end
	return Decoder.decode(value)
end

return table.freeze(Decoder)
