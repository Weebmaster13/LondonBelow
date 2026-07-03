--!strict
-- Central bounded state store for the Content Registry Runtime Foundation.

local Serialization = require(script.Parent.ContentSerialization)
local Types = require(script.Parent.ContentTypes)
local Validation = require(script.Parent.ContentValidation)

local State = {}

local contentDefinitions: { [string]: any } = {}
local categories: { [string]: any } = {}
local references: { [string]: any } = {}
local dependencies: { [string]: any } = {}
local packages: { [string]: any } = {}
local versions: { [string]: any } = {}
local tags: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function rejectDuplicate(schemaId: string, reason: string): (boolean, string?)
	if schemaIds[schemaId] == true then
		return false, reason
	end
	return true, nil
end

local function contentExists(contentId: string): boolean
	return contentDefinitions[contentId] ~= nil
end

function State.registerContentDefinition(schema: any): (boolean, string?)
	local ok, reason = Validation.contentDefinition(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.contentId, "duplicate contentId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(contentDefinitions) >= Types.Limits.MaxContentDefinitions then
		return false, "content definition limit exceeded"
	end
	schemaIds[schema.contentId] = true
	contentDefinitions[schema.contentId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerCategory(schema: any): (boolean, string?)
	local ok, reason = Validation.category(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.categoryId, "duplicate categoryId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(categories) >= Types.Limits.MaxCategories then
		return false, "category limit exceeded"
	end
	schemaIds[schema.categoryId] = true
	categories[schema.categoryId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerReference(schema: any): (boolean, string?)
	local ok, reason = Validation.reference(schema)
	if not ok then
		return false, reason
	end
	if not contentExists(schema.sourceContentId) then
		return false, "invalid source content reference"
	end
	if not contentExists(schema.targetContentId) then
		return false, "invalid target content reference"
	end
	local unique, duplicateReason = rejectDuplicate(schema.referenceId, "duplicate referenceId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(references) >= Types.Limits.MaxReferences then
		return false, "reference limit exceeded"
	end
	schemaIds[schema.referenceId] = true
	references[schema.referenceId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerDependency(schema: any): (boolean, string?)
	local ok, reason = Validation.dependency(schema)
	if not ok then
		return false, reason
	end
	if not contentExists(schema.sourceContentId) then
		return false, "invalid dependency source"
	end
	if not contentExists(schema.requiredContentId) then
		return false, "invalid dependency target"
	end
	local unique, duplicateReason = rejectDuplicate(schema.dependencyId, "duplicate dependencyId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(dependencies) >= Types.Limits.MaxDependencies then
		return false, "dependency limit exceeded"
	end
	schemaIds[schema.dependencyId] = true
	dependencies[schema.dependencyId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerPackage(schema: any): (boolean, string?)
	local ok, reason = Validation.package(schema)
	if not ok then
		return false, reason
	end
	if schema.contentIds ~= nil then
		for _, contentId in ipairs(schema.contentIds) do
			if not contentExists(contentId) then
				return false, "invalid package member reference"
			end
		end
	end
	local unique, duplicateReason = rejectDuplicate(schema.packageId, "duplicate packageId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(packages) >= Types.Limits.MaxPackages then
		return false, "package limit exceeded"
	end
	schemaIds[schema.packageId] = true
	packages[schema.packageId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerVersion(schema: any): (boolean, string?)
	local ok, reason = Validation.version(schema)
	if not ok then
		return false, reason
	end
	if not contentExists(schema.contentId) then
		return false, "invalid version content reference"
	end
	local unique, duplicateReason = rejectDuplicate(schema.versionId, "duplicate versionId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(versions) >= Types.Limits.MaxVersions then
		return false, "version limit exceeded"
	end
	schemaIds[schema.versionId] = true
	versions[schema.versionId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerTag(schema: any): (boolean, string?)
	local ok, reason = Validation.tag(schema)
	if not ok then
		return false, reason
	end
	local unique, duplicateReason = rejectDuplicate(schema.tagId, "duplicate tagId")
	if not unique then
		return false, duplicateReason
	end
	if countMap(tags) >= Types.Limits.MaxTags then
		return false, "tag limit exceeded"
	end
	schemaIds[schema.tagId] = true
	tags[schema.tagId] = Serialization.deepCopy(schema)
	return true, nil
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function State.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function State.inspect()
	return Serialization.deepCopy({
		contentDefinitions = contentDefinitions,
		categories = categories,
		references = references,
		dependencies = dependencies,
		packages = packages,
		versions = versions,
		tags = tags,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			contentDefinitions = countMap(contentDefinitions),
			categories = countMap(categories),
			references = countMap(references),
			dependencies = countMap(dependencies),
			packages = countMap(packages),
			versions = countMap(versions),
			tags = countMap(tags),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(contentDefinitions)
	table.clear(categories)
	table.clear(references)
	table.clear(dependencies)
	table.clear(packages)
	table.clear(versions)
	table.clear(tags)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
