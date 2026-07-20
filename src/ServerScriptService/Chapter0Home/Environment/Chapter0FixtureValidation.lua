--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local EnvironmentalValidation =
	require(ServerScriptService.Interaction.Environmental.EnvironmentalDefinitionValidation)

local Types = require(script.Parent.Chapter0EnvironmentalTypes)

local Validation = {}

local function id(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 140
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

function Validation.fixture(fixture: any): (boolean, string?)
	local ok, reason = EnvironmentalValidation.definition(fixture)
	if not ok then
		return false, reason
	end
	if fixture.chapterId ~= Types.ChapterId then
		return false, Types.ResultCode.InvalidFixture
	end
	if type(fixture.authoringMetadata) ~= "table" then
		return false, Types.ResultCode.InvalidFixture
	end
	if not id(fixture.authoringMetadata.roomId) then
		return false, Types.ResultCode.InvalidFixture
	end
	if not id(fixture.authoringMetadata.authoredInstanceId) then
		return false, Types.ResultCode.InvalidFixture
	end
	if type(fixture.authoringMetadata.authoredInstanceRequired) ~= "boolean" then
		return false, Types.ResultCode.InvalidFixture
	end
	return true, nil
end

function Validation.catalog(fixtures: { any }): (boolean, string?)
	if type(fixtures) ~= "table" or #fixtures == 0 or #fixtures > Types.Limits.MaxFixtures then
		return false, Types.ResultCode.InvalidFixture
	end
	local seen = {}
	for _, fixture in ipairs(fixtures) do
		local ok, reason = Validation.fixture(fixture)
		if not ok then
			return false, reason
		end
		if seen[fixture.id] == true then
			return false, Types.ResultCode.DuplicateFixtureId
		end
		seen[fixture.id] = true
	end
	return true, nil
end

return Validation
