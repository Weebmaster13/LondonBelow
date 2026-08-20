--!strict

local Types = require(script.Parent.RobloxGuiResponsiveLocalizationTypes)
local LocaleValidator = require(script.Parent.RobloxGuiLocaleValidator)

local Catalog = {}
local bundles = {}
local revisions = {}
local digests = {}

function Catalog.capture(locale: string)
	return {
		locale = locale,
		bundle = bundles[locale],
		revision = revisions[locale],
		digest = digests[locale],
	}
end

function Catalog.restore(snapshot: any)
	if snapshot.bundle == nil then
		bundles[snapshot.locale] = nil
		revisions[snapshot.locale] = nil
		digests[snapshot.locale] = nil
	else
		bundles[snapshot.locale] = snapshot.bundle
		revisions[snapshot.locale] = snapshot.revision
		digests[snapshot.locale] = snapshot.digest
	end
end

local function validId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= Types.Limits.maxKeyLength
end

local function digest(entries: { [string]: string }): string
	local keys = {}
	for key in pairs(entries) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	local canonical = {}
	for _, key in ipairs(keys) do
		canonical[#canonical + 1] = key .. "\0" .. entries[key]
	end
	return table.concat(canonical, "\1")
end

function Catalog.register(locale: any, entries: any, revision: any?): (boolean, string?, any?)
	local validLocale, normalized = LocaleValidator.normalize(locale)
	local requestedRevision = revision == nil and 0 or revision
	if
		not validLocale
		or not normalized
		or type(entries) ~= "table"
		or type(requestedRevision) ~= "number"
		or requestedRevision < 0
		or requestedRevision % 1 ~= 0
	then
		return false, Types.FailureType.InvalidBundle
	end
	normalized = string.lower(string.gsub(normalized, "_", "-"))
	local bundleCount = 0
	for _ in pairs(bundles) do
		bundleCount += 1
	end
	if bundles[normalized] == nil and bundleCount >= Types.Limits.maxBundles then
		return false, Types.FailureType.InvalidBundle
	end
	local copy = {}
	local count = 0
	for key, text in pairs(entries) do
		count += 1
		if
			count > Types.Limits.maxEntriesPerBundle
			or not validId(key)
			or type(text) ~= "string"
			or #text > Types.Limits.maxTextLength
		then
			return false, Types.FailureType.InvalidBundle
		end
		copy[key] = text
	end
	local nextDigest = digest(copy)
	local currentRevision = revisions[normalized]
	if currentRevision ~= nil then
		if requestedRevision < currentRevision then
			return false, Types.FailureType.StaleBundleRevision
		end
		if requestedRevision == currentRevision then
			if digests[normalized] ~= nextDigest then
				return false, Types.FailureType.BundleRevisionConflict
			end
			return true, nil, { idempotent = true, locale = normalized, revision = currentRevision }
		end
	end
	bundles[normalized] = table.freeze(copy)
	revisions[normalized] = requestedRevision
	digests[normalized] = nextDigest
	return true, nil, { idempotent = false, locale = normalized, revision = requestedRevision }
end

function Catalog.resolve(locale: string, key: string): (string?, string?)
	local valid, normalized = LocaleValidator.normalize(locale)
	if not valid or not normalized then
		return nil, nil
	end
	local language = LocaleValidator.language(normalized)
	for _, candidate in ipairs({ normalized, language, Types.DefaultLocale, "en" }) do
		local bundle = candidate and bundles[candidate]
		if bundle and bundle[key] ~= nil then
			return bundle[key], candidate
		end
	end
	return nil, nil
end

function Catalog.clear()
	table.clear(bundles)
	table.clear(revisions)
	table.clear(digests)
end

function Catalog.inspect()
	local locales = {}
	for locale in pairs(bundles) do
		locales[#locales + 1] = locale
	end
	table.sort(locales)
	local versionSnapshot = table.clone(revisions)
	return { locales = locales, bundleCount = #locales, revisions = versionSnapshot }
end

return Catalog
