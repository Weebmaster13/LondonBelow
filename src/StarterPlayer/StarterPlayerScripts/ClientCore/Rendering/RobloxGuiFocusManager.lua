--!strict

local GuiService = game:GetService("GuiService")

local FocusManager = {}
local selectedNodeId = nil :: string?

function FocusManager.capture(record: any)
	local selected = GuiService.SelectedObject
	if selected and record and record.root and selected:IsDescendantOf(record.root) then
		selectedNodeId = selected:GetAttribute("LondonEngineNodeId")
	else
		selectedNodeId = nil
	end
end

function FocusManager.restore(
	controlsByNodeId: { [string]: any },
	orderedControls: { any }
): (boolean, string?)
	local preferred = selectedNodeId and controlsByNodeId[selectedNodeId] or nil
	if preferred and not preferred.disabled then
		GuiService.SelectedObject = preferred.instance
		return true
	end
	for _, control in ipairs(orderedControls) do
		if not control.disabled then
			GuiService.SelectedObject = control.instance
			return true
		end
	end
	GuiService.SelectedObject = nil
	return false, "no-enabled-focus-target"
end

function FocusManager.clear(record: any?)
	local selected = GuiService.SelectedObject
	if selected and (not record or (record.root and selected:IsDescendantOf(record.root))) then
		GuiService.SelectedObject = nil
	end
	selectedNodeId = nil
end

function FocusManager.getSelectedNodeId(): string?
	local selected = GuiService.SelectedObject
	if selected then
		return selected:GetAttribute("LondonEngineNodeId")
	end
	return nil
end

return FocusManager
