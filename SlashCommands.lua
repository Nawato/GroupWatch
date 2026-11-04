--[[
	GroupWatch — SlashCommands
	=========================
	Chat command handler for /gw and /groupwatch.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local string_lower = G.string_lower
local print = G.print

SLASH_GROUPWATCH1 = "/gw"
SLASH_GROUPWATCH2 = "/groupwatch"

--- Split a command string into tokens. Double quotes group a token that
--- contains spaces, so list names like "Key Runners" survive.
local function ParseArgs(msg)
	local args = {}
	local length = #msg
	local i = 1

	while i <= length do
		-- Skip whitespace between tokens.
		while i <= length and msg:sub(i, i):match("%s") do
			i = i + 1
		end
		if i > length then
			break
		end

		local token
		if msg:sub(i, i) == '"' then
			i = i + 1
			local start = i
			local closing = msg:find('"', start, true)
			if closing then
				token = msg:sub(start, closing - 1)
				i = closing + 1
			else
				token = msg:sub(start)
				i = length + 1
			end
		else
			local start = i
			while i <= length and not msg:sub(i, i):match("%s") do
				i = i + 1
			end
			token = msg:sub(start, i - 1)
		end

		args[#args + 1] = token
	end

	return args
end

SlashCmdList["GROUPWATCH"] = function(msg)
	ns.InitDB()
	local args = ParseArgs(msg or "")
	local arg1 = string_lower(args[1] or "")
	local arg2, arg3 = args[2], args[3]

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
	elseif arg1 == "add" and arg2 then
		-- "/gw add <list> <player>" as before, but "/gw add <player>" now
		-- targets the default list instead of printing the help text.
		if arg3 then
			ns.AddPlayer(arg2, arg3)
		else
			ns.AddPlayer(ns.GetDefaultListName(), arg2)
		end
	elseif arg1 == "remove" and arg2 then
		ns.RemovePlayer(arg2, arg3)
	elseif arg1 == "sound" then
		ns.HandleSoundCommand(arg2, arg3)
	else
		print("|cff00ccff[GroupWatch]|r " .. L["HELP_HEADER"])
		print(" " .. L["HELP_TOGGLE"])
		print(" " .. L["HELP_MAP"])
		print(" " .. L["HELP_ADD"])
		print(" " .. L["HELP_REMOVE"])
		print(" " .. L["HELP_SOUND_ADD"])
	end
end
