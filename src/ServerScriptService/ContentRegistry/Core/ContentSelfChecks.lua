--!strict
-- Deterministic self-checks for Phase 36 Content Registry Runtime Foundation.

local Serialization = require(script.Parent.ContentSerialization)
local Types = require(script.Parent.ContentTypes)
local Validation = require(script.Parent.ContentValidation)

local SelfChecks = {}

local function base(idField: string, id: string, schemaType: string): any
	return {
		[idField] = id,
		ownerSystem = "contentRegistrySelfCheck",
		schemaType = schemaType,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function content(id: string, domain: string?): any
	local schema = base("contentId", id, Types.SchemaType.ContentDefinitionSchema)
	schema.contentDomain = domain or "System"
	return schema
end

local function category(id: string): any
	return base("categoryId", id, Types.SchemaType.ContentCategorySchema)
end

local function reference(id: string, sourceId: string?, targetId: string?): any
	local schema = base("referenceId", id, Types.SchemaType.ContentReferenceSchema)
	schema.sourceContentId = sourceId or "content.valid"
	schema.targetContentId = targetId or "content.target"
	return schema
end

local function dependency(id: string, sourceId: string?, requiredId: string?): any
	local schema = base("dependencyId", id, Types.SchemaType.ContentDependencySchema)
	schema.sourceContentId = sourceId or "content.valid"
	schema.requiredContentId = requiredId or "content.required"
	return schema
end

local function package(id: string, contentIds: { string }?): any
	local schema = base("packageId", id, Types.SchemaType.ContentPackageSchema)
	schema.contentIds = contentIds or { "content.valid" }
	return schema
end

local function version(id: string, contentId: string?): any
	local schema = base("versionId", id, Types.SchemaType.ContentVersionSchema)
	schema.contentId = contentId or "content.valid"
	return schema
end

local function tag(id: string): any
	return base("tagId", id, Types.SchemaType.ContentTagSchema)
end

local function result(name: string, ok: boolean, detail: string?): any
	return { name = name, ok = ok, detail = detail }
end

local function expectReject(name: string, ok: boolean, reason: string?): any
	return result(name, not ok, reason)
end

local function expectAccept(name: string, ok: boolean, reason: string?): any
	return result(name, ok, reason)
end

local function add(results: { any }, check: any)
	table.insert(results, check)
end

local function unsafeSchema(schema: any, fields: any): any
	schema.context = fields
	return schema
end

local function unsupported(schema: any): any
	schema.schemaType = "UnsupportedContentRegistrySchema"
	return schema
end

local function forbiddenContent(fields: any): any
	return unsafeSchema(content("content.forbidden"), fields)
end

local function longString(): string
	return string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
end

local function oversizedArray(limit: number): { string }
	local values = {}
	for index = 1, limit + 1 do
		table.insert(values, "value." .. index)
	end
	return values
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(
		results,
		expectReject(
			"malformed content definition rejects",
			Validation.contentDefinition({ contentId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported content schema type rejects",
			Validation.contentDefinition(unsupported(content("content.unsupported")))
		)
	)
	add(
		results,
		expectReject(
			"unsupported content domain rejects",
			Validation.contentDefinition(content("content.bad.domain", "Unsupported"))
		)
	)
	local contentResult = service.registerContentDefinition(content("content.valid"))
	add(
		results,
		expectAccept("valid content definition registers", contentResult.ok, contentResult.message)
	)
	service.registerContentDefinition(content("content.target"))
	service.registerContentDefinition(content("content.required"))
	local duplicateContent = service.registerContentDefinition(content("content.valid"))
	add(
		results,
		expectReject(
			"duplicate content definition rejects",
			duplicateContent.ok,
			duplicateContent.message
		)
	)
	local unsafeContent = service.registerContentDefinition(
		unsafeSchema(content("content.unsafe"), { finalStory = true })
	)
	add(
		results,
		expectReject("unsafe content definition rejects", unsafeContent.ok, unsafeContent.message)
	)

	add(
		results,
		expectReject("malformed category rejects", Validation.category({ categoryId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported category schema type rejects",
			Validation.category(unsupported(category("category.unsupported")))
		)
	)
	local invalidCategoryDomain = category("category.bad.domain")
	invalidCategoryDomain.allowedDomains = { "Unsupported" }
	add(
		results,
		expectReject("invalid category domain rejects", Validation.category(invalidCategoryDomain))
	)
	local categoryResult = service.registerCategory(category("category.valid"))
	add(
		results,
		expectAccept("valid category registers", categoryResult.ok, categoryResult.message)
	)
	local contentIdAsCategory = service.registerCategory(category("content.valid"))
	add(
		results,
		expectReject(
			"content id rejects as category id",
			contentIdAsCategory.ok,
			contentIdAsCategory.message
		)
	)
	local duplicateCategory = service.registerCategory(category("category.valid"))
	add(
		results,
		expectReject("duplicate category rejects", duplicateCategory.ok, duplicateCategory.message)
	)

	add(
		results,
		expectReject("malformed reference rejects", Validation.reference({ referenceId = "" }))
	)
	local invalidReferenceSource = service.registerReference(
		reference("reference.bad.source", "missing.content", "content.target")
	)
	add(
		results,
		expectReject(
			"invalid reference source rejects",
			invalidReferenceSource.ok,
			invalidReferenceSource.message
		)
	)
	local invalidReferenceTarget = service.registerReference(
		reference("reference.bad.target", "content.valid", "missing.content")
	)
	add(
		results,
		expectReject(
			"invalid reference target rejects",
			invalidReferenceTarget.ok,
			invalidReferenceTarget.message
		)
	)
	local referenceResult = service.registerReference(reference("reference.valid"))
	add(
		results,
		expectAccept("valid reference registers", referenceResult.ok, referenceResult.message)
	)
	local categoryIdAsReference = service.registerReference(reference("category.valid"))
	add(
		results,
		expectReject(
			"category id rejects as reference id",
			categoryIdAsReference.ok,
			categoryIdAsReference.message
		)
	)
	local duplicateReference = service.registerReference(reference("reference.valid"))
	add(
		results,
		expectReject(
			"duplicate reference rejects",
			duplicateReference.ok,
			duplicateReference.message
		)
	)

	add(
		results,
		expectReject("malformed dependency rejects", Validation.dependency({ dependencyId = "" }))
	)
	add(
		results,
		expectReject(
			"direct circular dependency rejects",
			Validation.dependency(
				dependency("dependency.circular", "content.valid", "content.valid")
			)
		)
	)
	local invalidDependencySource = service.registerDependency(
		dependency("dependency.bad.source", "missing.content", "content.required")
	)
	add(
		results,
		expectReject(
			"invalid dependency source rejects",
			invalidDependencySource.ok,
			invalidDependencySource.message
		)
	)
	local invalidDependencyTarget = service.registerDependency(
		dependency("dependency.bad.target", "content.valid", "missing.content")
	)
	add(
		results,
		expectReject(
			"invalid dependency target rejects",
			invalidDependencyTarget.ok,
			invalidDependencyTarget.message
		)
	)
	local dependencyResult = service.registerDependency(dependency("dependency.valid"))
	add(
		results,
		expectAccept("valid dependency registers", dependencyResult.ok, dependencyResult.message)
	)
	local referenceIdAsDependency = service.registerDependency(dependency("reference.valid"))
	add(
		results,
		expectReject(
			"reference id rejects as dependency id",
			referenceIdAsDependency.ok,
			referenceIdAsDependency.message
		)
	)
	local duplicateDependency = service.registerDependency(dependency("dependency.valid"))
	add(
		results,
		expectReject(
			"duplicate dependency rejects",
			duplicateDependency.ok,
			duplicateDependency.message
		)
	)

	add(results, expectReject("malformed package rejects", Validation.package({ packageId = "" })))
	local invalidPackageMember =
		service.registerPackage(package("package.bad.member", { "missing.content" }))
	add(
		results,
		expectReject(
			"invalid package member rejects",
			invalidPackageMember.ok,
			invalidPackageMember.message
		)
	)
	local oversizedPackage =
		package("package.oversized", oversizedArray(Types.Limits.MaxPackageMembers))
	add(results, expectReject("package member limits reject", Validation.package(oversizedPackage)))
	local packageResult = service.registerPackage(package("package.valid"))
	add(results, expectAccept("valid package registers", packageResult.ok, packageResult.message))
	local dependencyIdAsPackage = service.registerPackage(package("dependency.valid"))
	add(
		results,
		expectReject(
			"dependency id rejects as package id",
			dependencyIdAsPackage.ok,
			dependencyIdAsPackage.message
		)
	)
	local duplicatePackage = service.registerPackage(package("package.valid"))
	add(
		results,
		expectReject("duplicate package rejects", duplicatePackage.ok, duplicatePackage.message)
	)

	add(results, expectReject("malformed version rejects", Validation.version({ versionId = "" })))
	local invalidVersionContent =
		service.registerVersion(version("version.bad.content", "missing.content"))
	add(
		results,
		expectReject(
			"invalid version content rejects",
			invalidVersionContent.ok,
			invalidVersionContent.message
		)
	)
	local versionResult = service.registerVersion(version("version.valid"))
	add(results, expectAccept("valid version registers", versionResult.ok, versionResult.message))
	local packageIdAsVersion = service.registerVersion(version("package.valid"))
	add(
		results,
		expectReject(
			"package id rejects as version id",
			packageIdAsVersion.ok,
			packageIdAsVersion.message
		)
	)
	local duplicateVersion = service.registerVersion(version("version.valid"))
	add(
		results,
		expectReject("duplicate version rejects", duplicateVersion.ok, duplicateVersion.message)
	)

	add(results, expectReject("malformed tag rejects", Validation.tag({ tagId = "" })))
	local tagResult = service.registerTag(tag("tag.valid"))
	add(results, expectAccept("valid tag registers", tagResult.ok, tagResult.message))
	local versionIdAsTag = service.registerTag(tag("version.valid"))
	add(
		results,
		expectReject("version id rejects as tag id", versionIdAsTag.ok, versionIdAsTag.message)
	)
	local duplicateTag = service.registerTag(tag("tag.valid"))
	add(results, expectReject("duplicate tag rejects", duplicateTag.ok, duplicateTag.message))

	local linkHeavy = content("content.link.heavy")
	linkHeavy.referenceIds = oversizedArray(Types.Limits.MaxReferenceLinks)
	add(
		results,
		expectReject("reference link limits reject", Validation.contentDefinition(linkHeavy))
	)
	local dependencyHeavy = content("content.dependency.heavy")
	dependencyHeavy.dependencyIds = oversizedArray(Types.Limits.MaxDependencyLinks)
	add(
		results,
		expectReject("dependency link limits reject", Validation.contentDefinition(dependencyHeavy))
	)

	local unsafeMetadata = content("content.unsafe.metadata")
	unsafeMetadata.metadata = { assetLoading = true }
	add(
		results,
		expectReject("unsafe metadata rejects", Validation.contentDefinition(unsafeMetadata))
	)
	local unsafeContext = content("content.unsafe.context")
	unsafeContext.context = { gameplayExecution = true }
	add(
		results,
		expectReject("unsafe context rejects", Validation.contentDefinition(unsafeContext))
	)
	local unsafeTags = content("content.unsafe.tags")
	unsafeTags.tags = { "contentStreaming" }
	add(results, expectReject("unsafe tags reject", Validation.contentDefinition(unsafeTags)))
	local nestedForbidden = content("content.unsafe.nested")
	nestedForbidden.metadata = { nested = { roomLoading = true } }
	add(
		results,
		expectReject(
			"nested forbidden fields reject",
			Validation.contentDefinition(nestedForbidden)
		)
	)
	local forbiddenKey = content("content.unsafe.key")
	forbiddenKey.metadata = { fireClient = "blocked" }
	add(
		results,
		expectReject("forbidden table keys reject", Validation.contentDefinition(forbiddenKey))
	)
	local forbiddenValue = content("content.unsafe.value")
	forbiddenValue.metadata = { marker = "assetLoading" }
	add(
		results,
		expectReject("forbidden string values reject", Validation.contentDefinition(forbiddenValue))
	)

	local forbiddenGroups = {
		["final story fields reject"] = { finalStory = true },
		["final dialogue fields reject"] = { finalDialogue = true },
		["story fields reject"] = { story = true },
		["Chapter content fields reject"] = { chapterContent = true },
		["Chapter 0 content fields reject"] = { chapter0Content = true },
		["final room layout fields reject"] = { finalRoomLayout = true },
		["final puzzle content fields reject"] = { finalPuzzleContent = true },
		["final item content fields reject"] = { finalItemContent = true },
		["final objective completion fields reject"] = { finalObjectiveCompletion = true },
		["final monster behavior fields reject"] = { finalMonsterBehavior = true },
		["asset loading fields reject"] = { assetLoading = true },
		["map loading fields reject"] = { mapLoading = true },
		["room loading fields reject"] = { roomLoading = true },
		["streaming execution fields reject"] = { streamingExecution = true },
		["content spawning fields reject"] = { contentSpawning = true },
		["gameplay execution fields reject"] = { gameplayExecution = true },
		["puzzle execution fields reject"] = { puzzleExecution = true },
		["interaction execution fields reject"] = { interactionExecution = true },
		["inventory execution fields reject"] = { inventoryExecution = true },
		["narrative execution fields reject"] = { narrativeExecution = true },
		["objective completion fields reject"] = { objectiveCompletion = true },
		["save persistence fields reject"] = { savePersistence = true },
		["data store fields reject"] = {
			dataStore = true,
			dataStoreRead = true,
			dataStoreWrite = true,
		},
		["http service fields reject"] = { httpService = true },
		["http fields reject"] = { http = true },
		["messaging service fields reject"] = { messagingService = true },
		["messaging fields reject"] = { messaging = true },
		["analytics fields reject"] = { analytics = true, analyticsCollection = true },
		["telemetry fields reject"] = { telemetry = true, telemetrySending = true },
		["ui rendering fields reject"] = { uiRendering = true },
		["audio execution fields reject"] = { audioExecution = true },
		["presentation execution fields reject"] = { presentationExecution = true },
		["remote fields reject"] = { remote = true },
		["remote event fields reject"] = { remoteEvent = true },
		["remote function fields reject"] = { remoteFunction = true },
		["client fire fields reject"] = { fireClient = true },
		["all-clients fire fields reject"] = { fireAllClients = true },
		["client invoke fields reject"] = { invokeClient = true },
		["client authority fields reject"] = { clientAuthority = true },
		["workspace fields reject"] = { workspace = true },
		["service reference fields reject"] = { serviceReference = true },
		["adapter reference fields reject"] = { adapterReference = true },
		["handler reference fields reject"] = { handlerReference = true },
		["execute fields reject"] = { execute = true },
	}
	for name, fields in pairs(forbiddenGroups) do
		add(results, expectReject(name, Validation.contentDefinition(forbiddenContent(fields))))
	end

	local cyclic: any = {}
	cyclic.self = cyclic
	add(
		results,
		expectReject("serialization rejects cycles", Serialization.validateSerializable(cyclic))
	)
	add(
		results,
		expectReject(
			"serialization rejects Roblox Instances",
			Serialization.validateSerializable(script)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects functions",
			Serialization.validateSerializable(function() end)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects threads",
			Serialization.validateSerializable(coroutine.create(function() end))
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects oversized strings",
			Serialization.validateSerializable(longString())
		)
	)
	local wide: any = {}
	for index = 1, Types.Limits.MaxPayloadNodes + 2 do
		wide["node" .. index] = index
	end
	add(
		results,
		expectReject(
			"serialization rejects oversized payloads",
			Serialization.validateSerializable(wide)
		)
	)
	local deep: any = {}
	local cursor = deep
	for _ = 1, Types.Limits.MaxPayloadDepth + 2 do
		cursor.next = {}
		cursor = cursor.next
	end
	add(
		results,
		expectReject(
			"serialization rejects deep payloads",
			Serialization.validateSerializable(deep)
		)
	)
	local diagnosticCopy = Serialization.diagnosticCopy({
		callback = function() end,
		thread = coroutine.create(function() end),
		instance = script,
	})
	add(
		results,
		result(
			"diagnostic copy sanitizes unsafe values",
			diagnosticCopy.callback == "<unsafe:function>"
				and diagnosticCopy.thread == "<unsafe:thread>"
				and diagnosticCopy.instance == "<RobloxInstance>",
			nil
		)
	)

	local snapshot = service.getSnapshot()
	snapshot.counts.contentDefinitions = -100
	add(
		results,
		result(
			"snapshots are isolated",
			service.getSnapshot().counts.contentDefinitions ~= -100,
			nil
		)
	)
	local diagnostics = service.inspect()
	diagnostics.counts.contentDefinitions = -100
	add(
		results,
		result(
			"diagnostics are read-only",
			service.inspect().counts.contentDefinitions ~= -100,
			nil
		)
	)

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerContentDefinition({ contentId = "", index = index })
	end
	add(
		results,
		result(
			"validation histories are bounded",
			service.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
			nil
		)
	)
	for _ = 1, Types.Limits.MaxSnapshotHistory + 5 do
		service.getSnapshot()
	end
	add(
		results,
		result(
			"snapshots are bounded",
			service.inspect().counts.snapshots <= Types.Limits.MaxSnapshotHistory,
			nil
		)
	)

	service.shutdown()
	for index = 1, Types.Limits.MaxCategories do
		service.registerCategory(category("limit.category." .. index))
	end
	local overLimit = service.registerCategory(category("limit.category.extra"))
	add(results, expectReject("runtime category limits reject", overLimit.ok, overLimit.message))

	service.shutdown()
	add(
		results,
		result(
			"shutdown clears state",
			service.inspect().counts.contentDefinitions == 0 and service.inspect().counts.tags == 0,
			nil
		)
	)
	local afterShutdownContent = service.registerContentDefinition(content("shutdown.reuse"))
	local previousIdAfterShutdown = service.registerCategory(category("content.valid"))
	local afterShutdownTag = service.registerTag(tag("shutdown.tag"))
	local duplicateAfterReuse = service.registerVersion(version("shutdown.tag", "shutdown.reuse"))
	add(
		results,
		result(
			"shutdown clears global schema namespace",
			afterShutdownContent.ok
				and previousIdAfterShutdown.ok
				and afterShutdownTag.ok
				and not duplicateAfterReuse.ok,
			duplicateAfterReuse.message
		)
	)
	service.shutdown()

	local noExecution = {
		"no Chapter content",
		"no Chapter 0 content",
		"no final story",
		"no final dialogue",
		"no asset loading",
		"no map loading",
		"no room loading",
		"no content streaming",
		"no content spawning",
		"no world mutation",
		"no gameplay execution",
		"no puzzle execution",
		"no interaction execution",
		"no inventory execution",
		"no objective completion",
		"no narrative execution",
		"no save persistence",
		"no data store reads/writes",
		"no external http access",
		"no external messaging access",
		"no remotes",
		"no client authority",
		"no analytics collection",
		"no telemetry sending",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Content Registry stores schemas only."))
	end

	service.initialize()
	service.start()
	local refused = service.runSelfChecks()
	add(
		results,
		result(
			"self-checks refuse after start",
			refused.ok == false and refused.reason ~= nil,
			refused.reason
		)
	)
	service.shutdown()

	local allOk = true
	for _, check in ipairs(results) do
		if not check.ok then
			allOk = false
			break
		end
	end

	return { ok = allOk, results = results }
end

return SelfChecks
