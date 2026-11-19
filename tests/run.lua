-- GroupWatch P0 regression tests.
--
-- Covers the random-error hardening: name resolution with missing/bad data,
-- corrupted SavedVariables, tooltip injection and GROUP_ROSTER_UPDATE
-- formatting (stray % must never throw).
--
-- Run from the addon directory with any Lua 5.1–5.5 interpreter:
--   lua tests/run.lua
--   lua5.1 tests/run.lua
-- Exit code is 0 when every test passes, 1 otherwise.

local say = print -- real stdout; tests/stubs.lua replaces global print

-- ---------------------------------------------------------------------------
-- Paths
-- ---------------------------------------------------------------------------

local ADDON_DIR = ""
local function fileExists(p)
	local f = io.open(p, "r")
	if f then
		f:close()
		return true
	end
	return false
end

if not fileExists("tests/stubs.lua") then
	local src = (arg and arg[0]) or ""
	local dir = src:match("^(.*/)")
	if dir then
		ADDON_DIR = dir:gsub("tests/$", "")
	end
end

dofile(ADDON_DIR .. "tests/stubs.lua")

-- ---------------------------------------------------------------------------
-- Load addon modules (pure-logic subset; UI files need CreateFrame etc.)
-- ---------------------------------------------------------------------------

local ns = {}
local function loadmod(name)
	local chunk, err = loadfile(ADDON_DIR .. name)
	assert(chunk, "cannot load " .. name .. ": " .. tostring(err))
	chunk("GroupWatch", ns)
end

loadmod("Locales.lua")
loadmod("Core.lua")
loadmod("DB.lua")
loadmod("Detection.lua")
loadmod("ContextMenu.lua")
loadmod("Tooltips.lua")
loadmod("UI_DragCursor.lua")

-- Sound.lua is not loaded (needs the client); record sound requests instead.
ns.PlayListSound = function(sound)
	Stubs.playedSounds[#Stubs.playedSounds + 1] = sound
end

-- ---------------------------------------------------------------------------
-- Harness
-- ---------------------------------------------------------------------------

local passed, failed = 0, 0
local function check(name, cond, extra)
	if cond then
		passed = passed + 1
		say("ok   - " .. name)
	else
		failed = failed + 1
		say("FAIL - " .. name .. (extra ~= nil and ("  (" .. tostring(extra) .. ")") or ""))
	end
end

local function fresh()
	Stubs.reset()
	ns.InitDB()
	return ns.GetDefaultListName()
end

local function makeTooltip()
	return {
		lines = {},
		AddLine = function(self, text)
			self.lines[#self.lines + 1] = text
		end,
	}
end

-- ---------------------------------------------------------------------------
-- ns.GetFullName
-- ---------------------------------------------------------------------------

do
	fresh()
	check("GetFullName nil -> nil", ns.GetFullName(nil) == nil)
	check("GetFullName number -> nil", ns.GetFullName(42) == nil)
	check("GetFullName table -> nil", ns.GetFullName({}) == nil)
	check("GetFullName empty -> nil", ns.GetFullName("") == nil)
	check("GetFullName blank -> nil", ns.GetFullName("   ") == nil)
	check(
		"GetFullName appends realm",
		ns.GetFullName("Hero") == "Hero-MyRealm",
		ns.GetFullName("Hero")
	)
	check(
		"GetFullName trims realm spaces",
		ns.GetFullName("Hero-Other Realm") == "Hero-OtherRealm",
		ns.GetFullName("Hero-Other Realm")
	)
	Stubs.realm = nil
	local ok, res = pcall(ns.GetFullName, "Hero")
	check("GetFullName nil GetRealmName does not throw", ok, res)
	check("GetFullName nil GetRealmName -> 'Hero-'", res == "Hero-", res)
	Stubs.realm = "My Realm"
end

-- ---------------------------------------------------------------------------
-- ns.GetPlayerFullNameFromUnit
-- ---------------------------------------------------------------------------

do
	fresh()
	check("FromUnit nil -> nil", ns.GetPlayerFullNameFromUnit(nil) == nil)
	check("FromUnit number -> nil", ns.GetPlayerFullNameFromUnit(42) == nil)
	check("FromUnit unknown unit -> nil", ns.GetPlayerFullNameFromUnit("raid99") == nil)

	Stubs.units["player"] = { name = "Hero", realm = nil }
	Stubs.isPlayer["player"] = true
	Stubs.realm = nil
	local ok, res = pcall(ns.GetPlayerFullNameFromUnit, "player")
	check("FromUnit nil realm/GetRealmName does not throw", ok, res)
	check("FromUnit nil realm -> 'Hero-'", res == "Hero-", res)

	Stubs.realm = "My Realm"
	check(
		"FromUnit appends realm",
		ns.GetPlayerFullNameFromUnit("player") == "Hero-MyRealm",
		ns.GetPlayerFullNameFromUnit("player")
	)

	Stubs.units["npc"] = { name = "Bystander", realm = nil }
	Stubs.isPlayer["npc"] = false
	check("FromUnit non-player -> nil", ns.GetPlayerFullNameFromUnit("npc") == nil)
end

-- ---------------------------------------------------------------------------
-- ns.GetPlayerFullNameFromContext
-- ---------------------------------------------------------------------------

do
	fresh()
	Stubs.units["player"] = { name = "Hero", realm = nil }
	Stubs.isPlayer["player"] = true

	check("FromContext nil -> nil", ns.GetPlayerFullNameFromContext(nil) == nil)
	check("FromContext number -> nil", ns.GetPlayerFullNameFromContext(42) == nil)
	check("FromContext string -> nil", ns.GetPlayerFullNameFromContext("Hero") == nil)
	check("FromContext empty table -> nil", ns.GetPlayerFullNameFromContext({}) == nil)
	check(
		"FromContext {unit} resolves",
		ns.GetPlayerFullNameFromContext({ unit = "player" }) == "Hero-MyRealm",
		ns.GetPlayerFullNameFromContext({ unit = "player" })
	)
	check(
		"FromContext {name,server} resolves",
		ns.GetPlayerFullNameFromContext({ name = "Hero", server = "Some Realm" }) == "Hero-SomeRealm"
	)
	check(
		"FromContext non-string server falls back to GetFullName",
		ns.GetPlayerFullNameFromContext({ name = "Hero", server = 123 }) == "Hero-MyRealm"
	)
	check(
		"FromContext bnet tag name ignored",
		ns.GetPlayerFullNameFromContext({ name = "Hero#1234" }) == nil
	)

	Stubs.bnetInfo[7] = { gameAccountInfo = { characterName = "Toon", realmName = "Realm X" } }
	check(
		"FromContext {bnetAccountID} resolves",
		ns.GetPlayerFullNameFromContext({ bnetAccountID = 7 }) == "Toon-RealmX"
	)
	Stubs.bnetInfo[8] = { err = "BNet boom" }
	local ok, res = pcall(ns.GetPlayerFullNameFromContext, { bnetAccountID = 8 })
	check("FromContext throwing BNet API does not throw", ok, res)
	check("FromContext throwing BNet API -> nil", res == nil, res)
	check(
		"FromContext non-table accountInfo ignored",
		ns.GetPlayerFullNameFromContext({ accountInfo = "junk" }) == nil
	)
	check(
		"FromContext non-table gameAccountInfo ignored",
		ns.GetPlayerFullNameFromContext({ accountInfo = { gameAccountInfo = "junk" } }) == nil
	)
	check(
		"FromContext {memberInfo} resolves",
		ns.GetPlayerFullNameFromContext({ memberInfo = { name = "Zed" } }) == "Zed-MyRealm"
	)
	check(
		"FromContext non-table memberInfo ignored",
		ns.GetPlayerFullNameFromContext({ memberInfo = "nope" }) == nil
	)
end

-- ---------------------------------------------------------------------------
-- DB: corrupted SavedVariables repair
-- ---------------------------------------------------------------------------

do
	Stubs.reset()
	GroupWatchDB = { lists = "junk" }
	local ok, err = pcall(ns.InitDB)
	check("InitDB non-table lists does not throw", ok, err)
	check("InitDB resets non-table lists", type(GroupWatchDB.lists) == "table")
	local def = ns.GetDefaultListName()
	check("InitDB default list has players table", type(GroupWatchDB.lists[def].players) == "table")
	check("InitDB default list has notes table", type(GroupWatchDB.lists[def].notes) == "table")

	GroupWatchDB.lists[def].players = "corrupt"
	GroupWatchDB.lists[def].notes = nil
	GroupWatchDB.lists["Broken"] = "junk"
	ok, err = pcall(ns.InitDB)
	check("InitDB corrupt entries do not throw", ok, err)
	check("InitDB repairs players table", type(GroupWatchDB.lists[def].players) == "table")
	check("InitDB repairs notes table", type(GroupWatchDB.lists[def].notes) == "table")
	check("InitDB repairs corrupt list entry", type(GroupWatchDB.lists["Broken"]) == "table")

	GroupWatchDB.lists[def].players = "corrupt"
	ok, err = pcall(ns.AddPlayer, def, "NewGuy")
	check("AddPlayer corrupt players does not throw", ok, err)
	check(
		"AddPlayer repairs players table",
		type(GroupWatchDB.lists[def].players) == "table"
			and GroupWatchDB.lists[def].players["NewGuy-MyRealm"] == true
	)

	ok, err = pcall(ns.RemovePlayer, "Nobody-Realm")
	check("RemovePlayer with junk list entry does not throw", ok, err)

	ns.AddPlayer(def, "NoteGuy")
	ok, err = pcall(ns.SavePlayerNote, def, "NoteGuy-MyRealm", 123)
	check("SavePlayerNote non-string note does not throw", ok, err)
	check("SavePlayerNote non-string note clears note", GroupWatchDB.lists[def].notes["NoteGuy-MyRealm"] == nil)
	ok, err = pcall(ns.SavePlayerNote, def, "Nobody-Realm", "hi")
	check("SavePlayerNote unknown player does not throw", ok, err)
	GroupWatchDB.lists[def].players = "corrupt"
	ok, err = pcall(ns.SavePlayerNote, def, "NoteGuy-MyRealm", "hi")
	check("SavePlayerNote corrupt players does not throw", ok, err)

	ok, err = pcall(ns.GetWatchedIndex)
	check("GetWatchedIndex corrupt players does not throw", ok, err)
end

-- ---------------------------------------------------------------------------
-- ns.AppendNotesToTooltip with corrupted SV
-- ---------------------------------------------------------------------------

do
	Stubs.reset()
	local tip = makeTooltip()
	local ok, err = pcall(ns.AppendNotesToTooltip, tip, "Hero-Realm")
	check("AppendNotes nil DB does not throw", ok, err)

	GroupWatchDB = { lists = "junk" }
	tip = makeTooltip()
	ok, err = pcall(ns.AppendNotesToTooltip, tip, "Hero-Realm")
	check("AppendNotes non-table lists does not throw", ok, err)
	check("AppendNotes non-table lists adds nothing", #tip.lines == 0)

	GroupWatchDB = { lists = { Default = "junk" } }
	tip = makeTooltip()
	ok, err = pcall(ns.AppendNotesToTooltip, tip, "Hero-Realm")
	check("AppendNotes junk list entry does not throw", ok, err)

	GroupWatchDB = { lists = { Default = { players = "junk", notes = {} } } }
	tip = makeTooltip()
	ok, err = pcall(ns.AppendNotesToTooltip, tip, "Hero-Realm")
	check("AppendNotes non-table players does not throw", ok, err)

	GroupWatchDB = {
		lists = {
			Default = { players = { ["Hero-Realm"] = true }, notes = "junk" },
		},
	}
	tip = makeTooltip()
	ok, err = pcall(ns.AppendNotesToTooltip, tip, "Hero-Realm")
	check("AppendNotes non-table notes does not throw", ok, err)
	check("AppendNotes still lists player without notes", #tip.lines == 2, #tip.lines)

	GroupWatchDB = {
		lists = {
			Default = { players = { ["Hero-Realm"] = true }, notes = { ["Hero-Realm"] = 123 } },
		},
	}
	tip = makeTooltip()
	ok, err = pcall(ns.AppendNotesToTooltip, tip, "Hero-Realm")
	check("AppendNotes non-string note does not throw", ok, err)
	check("AppendNotes non-string note shows list only", #tip.lines == 2, #tip.lines)

	GroupWatchDB = {
		lists = {
			Default = { players = { ["Hero-Realm"] = true }, notes = { ["Hero-Realm"] = "spy" } },
		},
	}
	tip = makeTooltip()
	ok, err = pcall(ns.AppendNotesToTooltip, tip, "Hero-Realm")
	check("AppendNotes valid note does not throw", ok, err)
	check("AppendNotes valid note shows blank + note line", #tip.lines == 2, #tip.lines)
	check(
		"AppendNotes valid note contains note text",
		tip.lines[2] ~= nil and tip.lines[2]:find("spy", 1, true) ~= nil,
		tip.lines[2]
	)

	tip = makeTooltip()
	ok, err = pcall(ns.AppendNotesToTooltip, tip, 42)
	check("AppendNotes non-string fullName does not throw", ok, err)
	check("AppendNotes non-string fullName adds nothing", #tip.lines == 0)
end

-- ---------------------------------------------------------------------------
-- Detection: stray % in list messages must never throw
-- ---------------------------------------------------------------------------

do
	local function setupDetection(charName, message)
		Stubs.reset()
		ns.InitDB()
		local def = ns.GetDefaultListName()
		GroupWatchDB.lists[def].message = message
		GroupWatchDB.lists[def].sound = 0
		GroupWatchDB.lists[def].players = { [charName .. "-Realm"] = true }
		ns.InvalidateWatchedIndex()
		Stubs.inGroup = true
		Stubs.inRaid = false
		Stubs.numMembers = 2
		Stubs.units = {
			party1 = { name = charName, realm = "Realm" },
			player = { name = "Me", realm = "Realm" },
		}
	end

	setupDetection("Hero", "100%")
	local ok, err = pcall(ns.CheckGroup)
	check("CheckGroup bare '100%' message does not throw", ok, err)
	check(
		"CheckGroup bare '100%' still announces",
		#Stubs.printLog == 1 and Stubs.printLog[1]:find("100%%", 1) ~= nil,
		Stubs.printLog[1]
	)

	setupDetection("HeroTwo", "%d scored!")
	ok, err = pcall(ns.CheckGroup)
	check("CheckGroup '%d' with string arg does not throw", ok, err)
	check("CheckGroup '%d' still announces", #Stubs.printLog == 1, Stubs.printLog[1])

	setupDetection("HeroThree", "100% legit: %s")
	ok, err = pcall(ns.CheckGroup)
	check("CheckGroup valid '%s' does not throw", ok, err)
	check(
		"CheckGroup valid '%s' formats name",
		#Stubs.printLog == 1 and Stubs.printLog[1]:find("HeroThree%-Realm", 1) ~= nil,
		Stubs.printLog[1]
	)

	-- nil realm source + nil GetRealmName inside a roster scan
	Stubs.reset()
	ns.InitDB()
	local def = ns.GetDefaultListName()
	GroupWatchDB.lists[def].players = { ["Hero-"] = true }
	ns.InvalidateWatchedIndex()
	Stubs.inGroup = true
	Stubs.numMembers = 1
	Stubs.realm = nil
	Stubs.units = { player = { name = "Hero", realm = nil } }
	-- party of 1: the only unit is "player" (self) so nothing announces,
	-- but the scan itself must survive nil realms.
	Stubs.numMembers = 2
	Stubs.units = {
		party1 = { name = "Hero", realm = nil },
		player = { name = "Me", realm = nil },
	}
	ok, err = pcall(ns.CheckGroup)
	check("CheckGroup nil realms does not throw", ok, err)
end

-- ---------------------------------------------------------------------------
-- MENU_UNIT_* tag list still present (unknown tags are ignored by client)
-- ---------------------------------------------------------------------------

do
	local path = ADDON_DIR .. "ContextMenu.lua"
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local src = f:read("*a")
	f:close()
	local tags = {
		"MENU_UNIT_PLAYER",
		"MENU_UNIT_PARTY",
		"MENU_UNIT_RAID_PLAYER",
		"MENU_UNIT_RAID",
		"MENU_UNIT_FRIEND",
		"MENU_UNIT_CHAT_ROSTER",
		"MENU_UNIT_COMMUNITY_MEMBER",
		"MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
		"MENU_UNIT_COMMUNITIES_MEMBER",
		"MENU_UNIT_BN_FRIEND",
		"MENU_UNIT_TARGET",
		"MENU_UNIT_FOCUS",
		"MENU_UNIT_SELF",
		"MENU_UNIT_ENEMY_PLAYER",
		"MENU_UNIT_GUILD",
		"MENU_UNIT_GUILD_OFFLINE",
	}
	local missing = {}
	for _, tag in ipairs(tags) do
		if not src:find(tag, 1, true) then
			missing[#missing + 1] = tag
		end
	end
	check("All MENU_UNIT_* tags present", #missing == 0, table.concat(missing, ","))
end

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------

say(string.format("----\n%d passed, %d failed", passed, failed))
if failed > 0 then
	os.exit(1)
end
