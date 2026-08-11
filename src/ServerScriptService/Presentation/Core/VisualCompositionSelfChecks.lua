--!strict

local Runtime = require(script.Parent.RuntimeRobloxVisualComposition)
local Types = require(script.Parent.PresentationTypes)

local SelfChecks = {}

local function suite()
	local checks = {}
	local function expect(name: string, condition: boolean, detail: string?)
		checks[#checks + 1] = { name = name, ok = condition == true, detail = detail }
	end
	local function summarize()
		local failures = {}
		for _, check in ipairs(checks) do
			if not check.ok then
				failures[#failures + 1] = check
			end
		end
		return {
			phase = 183,
			ok = #failures == 0,
			total = #checks,
			passed = #checks - #failures,
			failed = #failures,
			failures = failures,
		}
	end
	return expect, summarize
end

local function definition(overrides: any?)
	local data = {
		compositionId = "chapter0.dialogue.primary",
		version = "1.0.0",
		compositionKind = Types.VisualCompositionKind.Dialogue,
		rootNodeId = "dialogue.root",
		supportedPresentationKinds = { "DialogueLine", "DialogueChoiceList" },
		defaultThemeReference = "theme.london.chapter0.home",
		nodes = {
			{
				nodeId = "dialogue.root",
				nodeKind = Types.VisualNodeKind.Root,
				semanticRole = Types.VisualSemanticRole.DialogueRoot,
				order = 1,
				layout = { mode = Types.VisualLayoutMode.Fill },
				accessibility = { screenReaderToken = "dialogue.root" },
			},
			{
				nodeId = "dialogue.layer",
				nodeKind = Types.VisualNodeKind.Layer,
				semanticRole = Types.VisualLayerKind.Dialogue,
				layerKind = Types.VisualLayerKind.Dialogue,
				parentNodeId = "dialogue.root",
				order = 10,
				layout = { mode = Types.VisualLayoutMode.Overlay },
			},
			{
				nodeId = "dialogue.region",
				nodeKind = Types.VisualNodeKind.Region,
				semanticRole = Types.VisualSemanticRole.DialoguePanel,
				parentNodeId = "dialogue.layer",
				order = 20,
				layout = { mode = Types.VisualLayoutMode.AnchorIntent, anchor = "BottomCenter" },
				constraints = { minimumWidth = 420, maximumWidth = 980 },
				responsiveVariants = { Compact = {}, Standard = {} },
			},
			{
				nodeId = "dialogue.body",
				nodeKind = Types.VisualNodeKind.Text,
				semanticRole = Types.VisualSemanticRole.DialogueBody,
				parentNodeId = "dialogue.region",
				order = 30,
				styleReference = "dialogue.body",
				typographyReference = "type.dialogue",
				localizationSlot = "dialogue.body",
				tokenReference = "dialogue.chapter0.home.01",
				accessibility = { screenReaderToken = "dialogue.body", focusIntent = "Readable" },
				states = { Default = {}, Focused = {} },
				visibility = Types.VisualVisibilityState.Visible,
			},
			{
				nodeId = "dialogue.choice.group",
				nodeKind = Types.VisualNodeKind.ChoiceGroup,
				semanticRole = Types.VisualSemanticRole.ChoiceContainer,
				parentNodeId = "dialogue.region",
				order = 40,
				layout = { mode = Types.VisualLayoutMode.FlowVertical },
			},
			{
				nodeId = "dialogue.choice.1",
				nodeKind = Types.VisualNodeKind.Choice,
				semanticRole = Types.VisualSemanticRole.ChoiceItem,
				parentNodeId = "dialogue.choice.group",
				order = 50,
				styleReference = "choice.normal",
				localizationSlot = "dialogue.choice",
				tokenReference = "dialogue.chapter0.choice.01",
			},
			{
				nodeId = "dialogue.portrait",
				nodeKind = Types.VisualNodeKind.Image,
				semanticRole = Types.VisualSemanticRole.SpeakerPortrait,
				parentNodeId = "dialogue.region",
				order = 60,
				assetReference = "asset.portrait.mum.shadow",
				accessibility = { alternateTextToken = "portrait.mum.shadow" },
			},
		},
		runtimeMetadata = { owner = "Phase183" },
	}
	if overrides ~= nil then
		for key, value in pairs(overrides) do
			data[key] = value
		end
	end
	return data
end

local function composition(overrides: any?)
	local data = {
		compositionInstanceId = "composition.instance.phase183.primary",
		compositionId = "chapter0.dialogue.primary",
		robloxRenderingSessionId = "roblox.rendering.session.phase182.primary",
		renderingExecutionSessionId = "rendering.execution.phase180.primary",
		renderingSessionId = "rendering.session.phase179.primary",
		presentationSessionId = "presentation.session.phase176.primary",
		rendererId = "roblox.renderer.phase181.primary",
		owner = "Presentation",
		stateVariants = { Default = {} },
		runtimeMetadata = { source = "self-check" },
	}
	if overrides ~= nil then
		for key, value in pairs(overrides) do
			data[key] = value
		end
	end
	return data
end

local definitionCounter = 0

local function changedDefinition(mutator: (any) -> ())
	local data = definition()
	definitionCounter += 1
	data.compositionId = data.compositionId .. "." .. tostring(definitionCounter)
	mutator(data)
	return data
end

function SelfChecks.run()
	Runtime.reset()
	definitionCounter = 0
	local expect, summarize = suite()

	local registered = Runtime.registerDefinition(definition())
	expect("valid definition registered", registered.ok)
	expect("definition immutable copy", registered.definition.nodes[1] ~= definition().nodes[1])
	local duplicateDefinition = Runtime.registerDefinition(definition())
	expect("duplicate definition rejected", not duplicateDefinition.ok)
	expect("malformed definition rejected", not Runtime.registerDefinition(nil).ok)
	local unsafe = definition({
		compositionId = "chapter0.dialogue.unsafe",
		runtimeMetadata = { callback = function() end },
	})
	expect("unsafe payload rejected", not Runtime.registerDefinition(unsafe).ok)
	local withUnknownField =
		definition({ compositionId = "chapter0.dialogue.unknown", executable = true })
	expect("unknown definition field rejected", not Runtime.registerDefinition(withUnknownField).ok)
	local invalidKind =
		definition({ compositionId = "chapter0.dialogue.invalidKind", compositionKind = "Invalid" })
	expect("invalid composition kind rejected", not Runtime.registerDefinition(invalidKind).ok)
	local missingRoot = changedDefinition(function(data)
		data.rootNodeId = "missing.root"
	end)
	expect("missing root rejected", not Runtime.registerDefinition(missingRoot).ok)
	local multipleRoots = changedDefinition(function(data)
		data.nodes[#data.nodes + 1] = {
			nodeId = "second.root",
			nodeKind = Types.VisualNodeKind.Root,
			order = 99,
		}
	end)
	expect("multiple roots rejected", not Runtime.registerDefinition(multipleRoots).ok)
	local duplicateNode = changedDefinition(function(data)
		data.nodes[#data.nodes + 1] = table.clone(data.nodes[1])
	end)
	expect("duplicate node rejected", not Runtime.registerDefinition(duplicateNode).ok)
	local missingParent = changedDefinition(function(data)
		data.nodes[2].parentNodeId = "missing.parent"
	end)
	expect("missing parent rejected", not Runtime.registerDefinition(missingParent).ok)
	local cycle = changedDefinition(function(data)
		data.nodes[1].parentNodeId = "dialogue.body"
	end)
	expect("circular hierarchy rejected", not Runtime.registerDefinition(cycle).ok)
	local invalidNodeKind = changedDefinition(function(data)
		data.nodes[2].nodeKind = "PhysicalFrame"
	end)
	expect("invalid node kind rejected", not Runtime.registerDefinition(invalidNodeKind).ok)
	local invalidSemanticRole = changedDefinition(function(data)
		data.nodes[2].semanticRole = "RenderButton"
	end)
	expect("invalid semantic role rejected", not Runtime.registerDefinition(invalidSemanticRole).ok)
	local invalidPortrait = changedDefinition(function(data)
		data.nodes[7].nodeKind = Types.VisualNodeKind.Text
	end)
	expect(
		"invalid semantic/node pairing rejected",
		not Runtime.registerDefinition(invalidPortrait).ok
	)
	local invalidAnchor = changedDefinition(function(data)
		data.nodes[3].layout.anchor = "Impossible"
	end)
	expect("invalid anchor rejected", not Runtime.registerDefinition(invalidAnchor).ok)
	local invalidConstraint = changedDefinition(function(data)
		data.nodes[3].constraints.minimumWidth = 1000
		data.nodes[3].constraints.maximumWidth = 200
	end)
	expect("invalid constraints rejected", not Runtime.registerDefinition(invalidConstraint).ok)
	local invalidResponsive = changedDefinition(function(data)
		data.nodes[3].responsiveVariants.Hologram = {}
	end)
	expect(
		"invalid responsive variant rejected",
		not Runtime.registerDefinition(invalidResponsive).ok
	)
	local invalidTheme = changedDefinition(function(data)
		data.defaultThemeReference = "not-theme"
	end)
	expect("invalid theme reference rejected", not Runtime.registerDefinition(invalidTheme).ok)
	local invalidTypography = changedDefinition(function(data)
		data.nodes[4].typographyReference = "font.body"
	end)
	expect(
		"invalid typography reference rejected",
		not Runtime.registerDefinition(invalidTypography).ok
	)
	local invalidAsset = changedDefinition(function(data)
		data.nodes[7].assetReference = "rbxassetid://1"
	end)
	expect("invalid asset reference rejected", not Runtime.registerDefinition(invalidAsset).ok)
	local invalidAccessibility = changedDefinition(function(data)
		data.nodes[4].accessibility.screenReaderToken = 42
	end)
	expect(
		"invalid accessibility rejected",
		not Runtime.registerDefinition(invalidAccessibility).ok
	)
	local semanticOnlyAsset = changedDefinition(function(data)
		data.nodes[4].nodeKind = Types.VisualNodeKind.SemanticOnly
		data.nodes[4].assetReference = "asset.invalid.semantic"
	end)
	expect(
		"semantic-only asset intent rejected",
		not Runtime.registerDefinition(semanticOnlyAsset).ok
	)

	local created = Runtime.createComposition(composition())
	expect("composition created", created.ok)
	expect("unknown definition rejected", not Runtime.createComposition(composition({
		compositionInstanceId = "composition.instance.phase183.unknown",
		compositionId = "unknown.definition",
	})).ok)
	expect("duplicate composition rejected", not Runtime.createComposition(composition()).ok)
	expect("malformed composition rejected", not Runtime.createComposition(nil).ok)
	expect("composition unknown field rejected", not Runtime.createComposition(composition({
		compositionInstanceId = "composition.instance.phase183.invalidfield",
		callback = "bad",
	})).ok)
	local bound = Runtime.bindComposition("composition.instance.phase183.primary")
	expect("composition bound", bound.ok)
	local duplicateBindingComposition = Runtime.createComposition(composition({
		compositionInstanceId = "composition.instance.phase183.duplicateBinding",
	}))
	expect("duplicate binding composition created", duplicateBindingComposition.ok)
	expect(
		"duplicate binding rejected",
		not Runtime.bindComposition("composition.instance.phase183.duplicateBinding").ok
	)
	local unknownBind = Runtime.bindComposition("composition.instance.phase183.unknown")
	expect("unknown composition bind rejected", not unknownBind.ok)
	local plan = Runtime.compileComposition("composition.instance.phase183.primary", 0)
	expect("composition compiled", plan.ok)
	expect("revision incremented", plan.plan.revision == 1)
	expect("root preserved", plan.plan.rootNodeId == "dialogue.root")
	expect("ordered nodes compiled", #plan.plan.orderedNodes == 7)
	expect("layers compiled", #plan.plan.layers == 1)
	expect("regions compiled", #plan.plan.regions == 1)
	local planAgain = Runtime.getResolvedPlan("composition.instance.phase183.primary")
	expect("resolved plan inspectable", planAgain ~= nil and planAgain.revision == 1)
	planAgain.orderedNodes[1].nodeId = "mutated"
	expect(
		"resolved plan isolated",
		Runtime.getResolvedPlan("composition.instance.phase183.primary").orderedNodes[1].nodeId
			~= "mutated"
	)
	expect(
		"activate composition",
		Runtime.activateComposition("composition.instance.phase183.primary").ok
	)
	expect(
		"supersede composition",
		Runtime.supersedeComposition("composition.instance.phase183.primary").ok
	)
	expect(
		"release composition",
		Runtime.releaseComposition("composition.instance.phase183.primary").ok
	)
	expect(
		"illegal lifecycle rejected",
		not Runtime.activateComposition("composition.instance.phase183.primary").ok
	)

	local staleComposition = Runtime.createComposition(composition({
		compositionInstanceId = "composition.instance.phase183.stale",
		robloxRenderingSessionId = "roblox.rendering.session.phase182.stale",
		renderingExecutionSessionId = "rendering.execution.phase180.stale",
		renderingSessionId = "rendering.session.phase179.stale",
		presentationSessionId = "presentation.session.phase176.stale",
		rendererId = "roblox.renderer.phase181.stale",
	}))
	expect("stale test composition created", staleComposition.ok)
	expect(
		"stale composition bound",
		Runtime.bindComposition("composition.instance.phase183.stale").ok
	)
	local stale = Runtime.compileComposition("composition.instance.phase183.stale", 1)
	expect("stale revision rejected", not stale.ok)
	expect(
		"stale rejection preserved state",
		Runtime.getComposition("composition.instance.phase183.stale").revision == 0
	)
	expect(
		"compare-and-commit accepts current revision",
		Runtime.compileComposition("composition.instance.phase183.stale", 0).ok
	)

	local diagnostics = Runtime.inspect()
	expect(
		"provider identity",
		diagnostics.providerName == Types.RobloxVisualCompositionProviderName
	)
	expect("runtime identity", diagnostics.runtimeId == Types.RobloxVisualCompositionRuntimeId)
	expect(
		"capability identity",
		diagnostics.capabilityId == Types.RobloxVisualCompositionCapabilityId
	)
	expect("platform identity", diagnostics.platform == Types.RobloxRenderingPlatform)
	expect("definitions in diagnostics", #diagnostics.definitions == 1)
	expect("compositions in diagnostics", #diagnostics.compositions >= 2)
	expect("plans in diagnostics", #diagnostics.resolvedPlans >= 2)
	expect("bindings in diagnostics", #diagnostics.bindings >= 2)
	expect("ownership in diagnostics", #diagnostics.ownership >= 2)
	expect(
		"revisions in diagnostics",
		diagnostics.revisions["composition.instance.phase183.primary"] == 1
	)
	expect("evidence recorded", #diagnostics.evidence > 0)
	expect("metrics definitions", diagnostics.metrics.definitionsRegistered == 1)
	expect("metrics nodes compiled", diagnostics.metrics.nodesCompiled >= 14)
	expect("profiler recorded", #diagnostics.profiler > 0)
	expect(
		"budgets exposed",
		diagnostics.budgets.MaxDefinitions == Types.VisualCompositionLimits.MaxDefinitions
	)
	expect(
		"governance exposed",
		diagnostics.governance.systemName == "Roblox Visual Composition Runtime"
	)
	expect("certification candidate", diagnostics.certification.status == "ProductionCandidate")
	expect(
		"posture server authoritative",
		diagnostics.robloxVisualCompositionPosture.serverAuthoritative == true
	)
	expect("posture data only", diagnostics.robloxVisualCompositionPosture.dataOnly == true)
	expect(
		"posture deterministic compilation",
		diagnostics.robloxVisualCompositionPosture.deterministicCompilation == true
	)
	expect(
		"posture deterministic revisions",
		diagnostics.robloxVisualCompositionPosture.deterministicRevisions == true
	)
	expect(
		"posture no GUI creation",
		diagnostics.robloxVisualCompositionPosture.noGuiCreation == true
	)
	expect("posture no rendering", diagnostics.robloxVisualCompositionPosture.noRendering == true)
	expect(
		"posture no Instance mutation",
		diagnostics.robloxVisualCompositionPosture.noInstanceMutation == true
	)
	expect(
		"posture no asset loading",
		diagnostics.robloxVisualCompositionPosture.noAssetLoading == true
	)
	expect("posture no networking", diagnostics.robloxVisualCompositionPosture.noNetworking == true)
	expect(
		"posture no Workspace mutation",
		diagnostics.robloxVisualCompositionPosture.noWorkspaceMutation == true
	)
	expect(
		"posture no client authority",
		diagnostics.robloxVisualCompositionPosture.noClientAuthority == true
	)
	expect(
		"posture no persistence",
		diagnostics.robloxVisualCompositionPosture.noPersistence == true
	)
	expect(
		"posture no gameplay execution",
		diagnostics.robloxVisualCompositionPosture.noGameplayExecution == true
	)
	expect(
		"posture no dialogue execution",
		diagnostics.robloxVisualCompositionPosture.noDialogueExecution == true
	)
	expect(
		"posture no AI execution",
		diagnostics.robloxVisualCompositionPosture.noAiExecution == true
	)
	expect("posture no analytics", diagnostics.robloxVisualCompositionPosture.noAnalytics == true)
	expect("posture no telemetry", diagnostics.robloxVisualCompositionPosture.noTelemetry == true)
	diagnostics.definitions[1].compositionId = "mutated"
	expect("diagnostics isolated", Runtime.inspect().definitions[1].compositionId ~= "mutated")
	local snapshot = Runtime.getSnapshot()
	expect(
		"snapshot provider identity",
		snapshot.providerName == Types.RobloxVisualCompositionProviderName
	)
	expect("snapshot root", snapshot.robloxVisualCompositionSnapshot ~= nil)
	snapshot.robloxVisualCompositionSnapshot.definitions[1].compositionId = "mutated"
	expect(
		"snapshot isolated",
		Runtime.getSnapshot().robloxVisualCompositionSnapshot.definitions[1].compositionId
			~= "mutated"
	)
	local valid, reason = Runtime.validate()
	expect("runtime validation passes", valid, reason)

	Runtime.reset()
	expect("reset clears definitions", #Runtime.inspect().definitions == 0)
	expect("reset clears compositions", #Runtime.inspect().compositions == 0)
	expect("reset clears plans", #Runtime.inspect().resolvedPlans == 0)
	Runtime.shutdown()
	local blockedDefinition =
		Runtime.registerDefinition(definition({ compositionId = "chapter0.dialogue.shutdown" }))
	expect(
		"shutdown blocks definition",
		not blockedDefinition.ok
			and blockedDefinition.code == Types.VisualCompositionFailureType.RuntimeShutdown
	)
	local blockedComposition = Runtime.createComposition(composition({
		compositionInstanceId = "composition.instance.phase183.shutdown",
	}))
	expect(
		"shutdown blocks composition",
		not blockedComposition.ok
			and blockedComposition.code == Types.VisualCompositionFailureType.RuntimeShutdown
	)

	return summarize()
end

return SelfChecks
