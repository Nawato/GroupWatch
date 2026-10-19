--[[
	GroupWatch — Sound
	==================
	Sound options: the built-in SoundKit sounds and the user's own sound
	files from the Sounds/ folder of the addon directory.

	World of Warcraft gives addons no way to list a directory: a file can
	only be asked about by its exact name (C_UIFileAsset.IsKnownFile), and
	only the files the client indexed while it started up are known at all.
	So a user's sound is named once -- "BossAlert" for BossAlert.ogg -- and
	the addon remembers it from then on, re-checking the folder on every
	start. The name that is given is the name of the file without its
	extension, and there is no limit on how many sounds there can be.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local PlaySound = G.PlaySound
local PlaySoundFile = G.PlaySoundFile
local StaticPopup_Show = G.StaticPopup_Show
local ipairs, pairs = G.ipairs, G.pairs
local pcall = G.pcall
local print = G.print
local strtrim = G.strtrim
local string_format = G.string_format
local table_sort = G.table_sort
local type = G.type

-- The folder the user's sound files live in, relative to the client.
local USER_SOUND_DIR = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\"

-- Extensions tried for a name, in order. .ogg comes first: it is what the
-- client prefers and what most users will have.
local USER_SOUND_EXTS = { ".ogg", ".mp3" }

-- The sound files that ship with the addon. They are always listed and
-- cannot be removed: they are part of the addon, not part of the user's
-- own collection. The name is the file name without its extension, like
-- every other sound file.
ns.BUNDLED_SOUNDS = { "Bruh", "Oof" }

-- name (without extension) -> the path that was found for it.
-- nil until the first scan; a name that is registered but whose file is gone
-- is simply not in here.
local resolvedUserSounds = nil

-- ---------------------------------------------------------------------------
-- User sound files
-- ---------------------------------------------------------------------------

-- Silent existence probe.
--
-- C_UIFileAsset.IsKnownFile() answers whether the client has the file
-- indexed, which is exactly the question here: a file the client has not
-- seen (because it was copied in after startup) must not be treated as
-- present. It is also completely silent, so probing a slot does not play
-- anything.
local hasKnownFileAPI = C_UIFileAsset and C_UIFileAsset.IsKnownFile

local function SoundFileExists(path)
	if hasKnownFileAPI then
		return hasKnownFileAPI(path) and true or false
	end

	-- Without the API there is no silent way to ask. The only other way is
	-- to start the file, which is audible -- and the names are checked for
	-- every one of them at once, so that would fire all of them. The file is
	-- assumed to be there instead; the play call then decides, and says so
	-- when the file turns out to be missing.
	return true
end

-- The path of a user's sound file, nil when the client does not have it.
local function ProbeUserSound(name)
	for _, ext in ipairs(USER_SOUND_EXTS) do
		local path = USER_SOUND_DIR .. name .. ext
		if SoundFileExists(path) then
			return path
		end
	end
	return nil
end

-- Clean up a name the user typed: trim it, refuse anything that points
-- outside the Sounds folder, and drop the extension (the same sound is
-- "BossAlert.ogg" and "BossAlert").
local function CleanSoundName(input)
	if type(input) ~= "string" then
		return nil
	end

	local name = strtrim(input)
	if name == "" then
		return nil
	end
	if name:find("[/\\:]") or name:find("%.%.") then
		return nil
	end

	name = name:gsub("%.[Oo][Gg][Gg]$", ""):gsub("%.[Mm][Pp]3$", "")
	name = strtrim(name)
	if name == "" then
		return nil
	end
	return name
end

-- The names of the user's sound files, sorted so the menu is stable.
--
-- The sounds that ship with the addon are part of this list too: they are
-- always offered, and they cannot be removed.
function ns.GetUserSoundNames()
	local registry = GroupWatchDB and GroupWatchDB.userSounds
	if type(registry) ~= "table" then
		registry = {}
	end

	local names = {}
	for name in pairs(registry) do
		names[#names + 1] = name
	end
	for _, name in ipairs(ns.BUNDLED_SOUNDS) do
		local known = false
		for _, existing in ipairs(names) do
			if existing == name then
				known = true
				break
			end
		end
		if not known then
			names[#names + 1] = name
		end
	end
	table_sort(names)
	return names
end

-- True for a sound that ships with the addon. Those are always listed and
-- cannot be removed.
function ns.IsBundledSound(name)
	for _, bundled in ipairs(ns.BUNDLED_SOUNDS) do
		if bundled == name then
			return true
		end
	end
	return false
end

-- Look the registered names up again. Called on every client start: files
-- that were added since the last start are found, files that were deleted
-- are not.
function ns.RefreshUserSounds()
	ns.InitDB()
	resolvedUserSounds = {}

	for _, name in ipairs(ns.GetUserSoundNames()) do
		local path = ProbeUserSound(name)
		if path then
			resolvedUserSounds[name] = path
		end
	end
end

-- The scan runs on the first use if the client start did not trigger it.
local function EnsureScanned()
	if resolvedUserSounds then
		return
	end
	ns.RefreshUserSounds()
end

-- The path of a user's sound file, nil when it is not there.
function ns.ResolveUserSoundPath(name)
	EnsureScanned()
	return resolvedUserSounds[name]
end

-- Remember a sound file. The name is the file name without its extension.
-- `listName` assigns the sound to that list right away, for when the sound
-- was added from a list's sound menu.
function ns.AddUserSound(input, listName)
	ns.InitDB()

	local name = CleanSoundName(input)
	if not name then
		print("|cffff0000[GroupWatch]|r " .. L["MSG_SOUND_BAD_NAME"])
		return false
	end

	local path = ProbeUserSound(name)
	if not path then
		print(
			"|cffff0000[GroupWatch]|r " .. string_format(L["MSG_SOUND_NOT_FOUND"], name)
		)
		return false
	end

	GroupWatchDB.userSounds = GroupWatchDB.userSounds or {}
	GroupWatchDB.userSounds[name] = true
	resolvedUserSounds = resolvedUserSounds or {}
	resolvedUserSounds[name] = path

	print("|cff00ff00[GroupWatch]|r " .. string_format(L["MSG_SOUND_ADDED"], name))

	-- The sound was added from a list's sound menu: put it on that list
	-- right away instead of making the user pick it a second time.
	local ld = listName and GroupWatchDB.lists and GroupWatchDB.lists[listName]
	if ld then
		ld.sound = name
		ns.PlayListSound(name)
		local ui = ns.GroupWatchUI
		if ui and ui:IsShown() then
			ui:Refresh()
		end
	end

	return true
end

-- Forget a sound file. Lists that still point at it keep the name; playing
-- it then reports the missing file.
function ns.RemoveUserSound(input)
	ns.InitDB()

	local name = CleanSoundName(input)
	if not name then
		print("|cffff0000[GroupWatch]|r " .. L["MSG_SOUND_BAD_NAME"])
		return false
	end
	if ns.IsBundledSound(name) then
		-- It ships with the addon, so it is always there.
		print("|cffff0000[GroupWatch]|r " .. string_format(L["MSG_SOUND_BUNDLED"], name))
		return false
	end
	if not (GroupWatchDB.userSounds and GroupWatchDB.userSounds[name]) then
		print("|cffff0000[GroupWatch]|r " .. string_format(L["MSG_SOUND_NOT_REGISTERED"], name))
		return false
	end

	GroupWatchDB.userSounds[name] = nil
	if resolvedUserSounds then
		resolvedUserSounds[name] = nil
	end

	print("|cff00ff00[GroupWatch]|r " .. string_format(L["MSG_SOUND_REMOVED"], name))
	return true
end

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------

-- The user's sound files as sound options, for the menu.
function ns.GetUserSoundOptions()
	EnsureScanned()

	local options = {}
	for _, name in ipairs(ns.GetUserSoundNames()) do
		options[#options + 1] = {
			name = name,
			id = name,
			file = resolvedUserSounds[name],
			missing = resolvedUserSounds[name] == nil,
		}
	end
	return options
end

-- Every sound option: the built-in ones, the user's own files, and "No
-- Sound" at the end.
function ns.GetAllSoundOptions()
	local options = {}
	local userOptions = ns.GetUserSoundOptions()

	for _, s in ipairs(ns.SOUND_OPTIONS) do
		-- "No Sound" closes the list, so the user's files go above it.
		if s.id == 0 then
			for _, u in ipairs(userOptions) do
				options[#options + 1] = u
			end
		end
		options[#options + 1] = s
	end

	return options
end

-- The label of a sound option as shown in the dropdown.
function ns.GetSoundOptionLabel(soundOpt)
	if not soundOpt then
		return ""
	end
	if not soundOpt.missing then
		return soundOpt.name
	end
	return string_format("%s %s", soundOpt.name, L["SOUND_USER_MISSING"])
end

--- The name of the sound a list is set to.
---
--- A number is a SoundKit id, a string is the name of one of the user's
--- sound files.
function ns.GetSoundName(sound)
	if type(sound) == "string" then
		return sound
	end
	if type(sound) ~= "number" then
		return string_format(L["SOUND_CUSTOM"], 0)
	end
	if sound < 0 then
		-- The first version of this feature had a fixed set of slots
		-- numbered -1..-5, which named the files Custom1..Custom5.
		return "Custom" .. tostring(-sound)
	end
	for _, s in ipairs(ns.SOUND_OPTIONS) do
		if s.id == sound then
			return s.name
		end
	end
	return string_format(L["SOUND_CUSTOM"], sound)
end

--- The name of the sound, shortened to fit the narrow button next to a
--- list name. A file name can be far longer than the built-in sounds.
function ns.GetSoundButtonLabel(sound)
	local name = ns.GetSoundName(sound)
	local limit = 14
	if #name > limit then
		return name:sub(1, limit - 2) .. ".."
	end
	return name
end

-- Play the file behind one of the user's sounds.
local function PlayUserSound(name)
	local path = ns.ResolveUserSoundPath(name)
	if not path then
		-- Not registered, or the file is gone. A legacy slot name is still
		-- worth a try: it names a file directly.
		path = ProbeUserSound(name)
	end
	if not path then
		print(
			"|cffff0000[GroupWatch]|r "
				.. string_format(L["MSG_SOUND_FILE_MISSING"], USER_SOUND_DIR .. name)
		)
		return false
	end

	-- A file the client does not know can still make PlaySoundFile error,
	-- so the call is guarded: a missing sound must never throw.
	local ok, willPlay = pcall(PlaySoundFile, path, "Master")
	if not ok then
		return false
	end

	-- Without the file index API the file could not be checked beforehand.
	-- PlaySoundFile reports a file it could not start, which is the last
	-- chance to tell the user that the file is not there.
	if not hasKnownFileAPI and willPlay == false then
		print(
			"|cffff0000[GroupWatch]|r "
				.. string_format(L["MSG_SOUND_FILE_MISSING"], USER_SOUND_DIR .. name)
		)
		return false
	end

	return true
end

--- Play the sound a list is set to.
---
--- A number is a SoundKit id, a string is the name of one of the user's
--- sound files. Unknown ids and files that are not there are ignored.
function ns.PlayListSound(sound)
	-- The sound comes out of the saved variables, so it is not guaranteed to
	-- be a number: a hand-edited file must not make the comparison below
	-- throw.
	if type(sound) == "string" then
		return PlayUserSound(sound)
	end
	if type(sound) ~= "number" or sound == 0 then
		return false
	end
	if sound < 0 then
		-- The first version of this feature had a fixed set of slots
		-- numbered -1..-5, which named the files Custom1..Custom5.
		return PlayUserSound("Custom" .. tostring(-sound))
	end

	PlaySound(sound, "Master")
	return true
end

-- ---------------------------------------------------------------------------
-- Menu
-- ---------------------------------------------------------------------------

--- Fill `rootDescription` with the sound options.
---
--- Selecting a sound stores it on the list and plays it as a preview. A
--- user sound whose file is not there cannot be selected: the choice is
--- refused with a message, so the list keeps the sound it had.
function ns.BuildSoundMenu(rootDescription, listName, onChanged)
	for _, soundOpt in ipairs(ns.GetAllSoundOptions()) do
		rootDescription:CreateButton(ns.GetSoundOptionLabel(soundOpt), function()
			local ld = GroupWatchDB and GroupWatchDB.lists and GroupWatchDB.lists[listName]
			if not ld then
				return
			end

			if soundOpt.missing then
				print(
					"|cffff0000[GroupWatch]|r "
						.. string_format(L["MSG_SOUND_FILE_MISSING"], USER_SOUND_DIR .. soundOpt.name)
				)
				return
			end

			ld.sound = soundOpt.id
			ns.PlayListSound(soundOpt.id)
			if onChanged then
				onChanged()
			end
		end)
	end

	-- Add another of the user's own sound files.
	rootDescription:CreateButton(L["SOUND_USER_ADD"], function()
		StaticPopup_Show("GROUPWATCH_ADD_SOUND", { listName = listName })
	end)
end

-- ---------------------------------------------------------------------------
-- /gw sound
-- ---------------------------------------------------------------------------

--- Handle the "sound" part of the slash command.
function ns.HandleSoundCommand(action, name)
	action = (action or ""):lower()

	if action == "add" then
		ns.AddUserSound(name)
	elseif action == "remove" then
		ns.RemoveUserSound(name)
	elseif action == "list" then
		local names = ns.GetUserSoundNames()
		if #names == 0 then
			print("|cff00ccff[GroupWatch]|r " .. L["MSG_SOUND_NO_FILES"])
			return
		end
		EnsureScanned()
		for _, n in ipairs(names) do
			local state = resolvedUserSounds[n] and "" or (" " .. L["SOUND_USER_MISSING"])
			print("|cff00ccff[GroupWatch]|r " .. n .. state)
		end
	else
		print("|cff00ccff[GroupWatch]|r " .. L["HELP_SOUND_ADD"])
		print(" " .. L["HELP_SOUND_REMOVE"])
		print(" " .. L["HELP_SOUND_LIST"])
	end
end

-- ---------------------------------------------------------------------------
-- Add-sound dialog
-- ---------------------------------------------------------------------------

StaticPopupDialogs["GROUPWATCH_ADD_SOUND"] = {
	text = L["DIALOG_ADD_SOUND_TEXT"],
	button1 = L["DIALOG_ADD"],
	button2 = L["DIALOG_CANCEL"],
	hasEditBox = true,
	OnAccept = function(self)
		local text = self.EditBox:GetText()
		if text and text ~= "" then
			ns.AddUserSound(text, self.data and self.data.listName)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetText()
		if text and text ~= "" then
			ns.AddUserSound(text, self.data and self.data.listName)
		end
		self:GetParent():Hide()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
