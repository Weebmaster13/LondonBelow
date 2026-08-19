--!strict

local Types = require(script.Parent.RobloxGuiResponsiveLocalizationTypes)

local Catalog = {}
local bundles = {}

local function validId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= Types.Limits.maxKeyLength
end

local function normalize(locale: string): string
	return string.lower(string.gsub(locale, "_", "-"))
end

function Catalog.register(locale: any, entries: any): (boolean, string?)
	if not validId(locale) or type(entries) ~= "table" then
		return false, Types.FailureType.InvalidBundle
	end
	local normalized = normalize(locale)
	local bundleCount = 0
	for _ in pairs(bundles) do bundleCount += 1 end
	if bundles[normalized] == nil and bundleCount >= Types.Limits.maxBundles then
		return false, Types.FailureType.InvalidBundle
	end
	local copy = {}
	local count = 0
	for key, text in pairs(entries) do
		count += 1
		if count > Types.Limits.maxEntriesPerBundle or not validId(key) or type(text) ~= "string" or #text > Types.Limits.maxTextLength then
			return false, Types.FailureType.InvalidBundle
		end
		copy[key] = text
	end
	bundles[normalized] = table.freeze(copy)
	return true
end

function Catalog.resolve(locale: string, key: string): (string?, string?)
	local normalized = normalize(locale)
	local language = string.match(normalized, "^([a-z]+)")
	for _, candidate in ipairs({ normalized, language, Types.DefaultLocale, "en" }) do
		local bundle = candidate and bundles[candidate]
		if bundle and bundle[key] ~= nil then return bundle[key], candidate end
	end
	return nil, nil
end

function Catalog.clear()
	table.clear(bundles)
end

function Catalog.inspect()
	local locales = {}
	for locale in pairs(bundles) do locales[#locales + 1] = locale end
	table.sort(locales)
	return { locales = locales, bundleCount = #locales }
end

return Catalog
