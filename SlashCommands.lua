--[[
	GroupWatch — SlashCommands
	=========================
	Chat command handler for /gw and /groupwatch.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local strsplit = G.strsplit
local string_lower = G.string_lower
local print = G.print

SLASH_GROUPWATCH1 = "/gw"
SLASH_GROUPWATCH2 = "/groupwatch"

SlashCmdList["GROUPWATCH"] = function(msg)
	ns.InitDB()
	local arg1, arg2, arg3 = strsplit(" ", msg or "", 3)
	arg1 = string_lower(arg1 or "")

	if arg1 == "list" or arg1 == "ui" or arg1 == "" then
		ns.ToggleUI()
	elseif arg1 == "map" or arg1 == "minimap" then
		local willHide = not (GroupWatchDB.minimap and GroupWatchDB.minimap.hide)
		ns.SetMinimapButtonShown(not willHide)
		print(
			"|cff00ccff[GroupWatch]|r "
				.. (
					willHide and "|cffff0000" .. L["MINIMAP_DISABLED"] .. "|r"
					or "|cff00ff00" .. L["MINIMAP_ENABLED"] .. "|r"
				)
		)
	elseif arg1 == "add" and arg2 and arg3 then
		ns.AddPlayer(arg2, arg3)
	elseif arg1 == "remove" and arg2 then
		ns.RemovePlayer(arg2, arg3)
	else
		print("|cff00ccff[GroupWatch]|r " .. L["HELP_HEADER"])
		print(" " .. L["HELP_TOGGLE"])
		print(" " .. L["HELP_MAP"])
		print(" " .. L["HELP_ADD"])
		print(" " .. L["HELP_REMOVE"])
	end
end
