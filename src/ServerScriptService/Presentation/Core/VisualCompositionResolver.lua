--!strict

local Compiler = require(script.Parent.VisualCompositionCompiler)

local Resolver = {}

function Resolver.resolve(definition: any, composition: any, binding: any, revision: number)
	return Compiler.compile(definition, composition, binding, revision)
end

return Resolver
