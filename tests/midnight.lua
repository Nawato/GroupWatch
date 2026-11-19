-- GroupWatch P1 (Midnight / 12.0) compliance tests.
--
-- Covers: banned/removed globals (source scan), TOC identity, ElvUI skin
-- hardening (pcall + caching + non-function fields), PlaySound nil-safety,
-- C_Timer nil-guard, NoteEditor font/playerName nil-safety, and realm
-- normalization (GetNormalizedRealmName preferred, GetRealmName fallback).
--
-- Run from the addon directory with any Lua 5.1+ interpreter:
--   lua tests/midnight.lua
--   lua5.1 tests/midnight.lua
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

-- ---------------------------------------------------------------------------
-- Test-only client globals (must exist BEFORE Core.lua captures them)
-- ---------------------------------------------------------------------------

StaticPopupDialogs = {}
tinsert = table.insert
ChatFontNormal = {}

MockUI = { frames = {}, byName = {}, cursor = {}, after = {}, fontNil = true, fontHeight = 12 }

local function makeMock(kind)
	local self = { __kind = kind, scripts = {}, hidden = true, text = "" }
	function self:SetSize()
	end
	function self:SetPoint()
	end
	function self:ClearAllPoints()
	end
	function self:SetMovable()
	end
	function self:EnableMouse()
	end
	function self:RegisterForDrag()
	end
	function self:SetScript(k, fn)
		self.scripts[k] = fn
	end
	function self:GetScript(k)
		return self.scripts[k]
	end
	function self:SetClampedToScreen()
	end
	function self:SetFrameStrata()
	end
	function self:SetFrameLevel()
	end
	function self:SetBackdrop()
	end
	function self:ClearBackdrop()
	end
	function self:SetBackdropColor()
	end
	function self:RegisterEvent()
	end
	function self:Hide()
		self.hidden = true
	end
	function self:Show()
		self.hidden = false
	end
	function self:IsShown()
		return not self.hidden
	end
	function self:IsVisible()
		return not self.hidden
	end
	function self:SetWidth(w)
		self.width = w
	end
	function self:SetHeight(h)
		self.height = h
	end
	function self:GetWidth()
		return self.width or 100
	end
	function self:GetHeight()
		return 100
	end
	function self:SetText(t)
		self.text = t
	end
	function self:GetText()
		return self.text
	end
	function self:SetCursorPosition(p)
		MockUI.cursor[#MockUI.cursor + 1] = p
	end
	function self:SetFocus()
		self.focused = true
	end
	function self:SetMultiLine()
	end
	function self:SetAutoFocus()
	end
	function self:SetFontObject()
	end
	function self:Insert(t)
		self.text = self.text .. (t or "")
	end
	function self:SetScrollChild(child)
		self.scrollChild = child
	end
	function self:SetColorTexture()
	end
	function self:CreateFontString()
		return makeMock("fontstring")
	end
	function self:CreateTexture()
		return makeMock("texture")
	end
	function self:GetParent()
		return self.parent
	end
	function self:GetFont()
		return "GameFontNormal", MockUI.fontHeight
	end
	function self:GetFontObject()
		if MockUI.fontNil then
			return nil
		end
		return makeMock("font")
	end
	return self
end

function CreateFrame(ftype, name, parent, template)
	local m = makeMock(ftype)
	m.mockName = name
	m.parent = parent
	MockUI.frames[#MockUI.frames + 1] = m
	if name then
		MockUI.byName[name] = m
	end
	return m
end

UIParent = makeMock("UIParent")
UISpecialFrames = {}

dofile(ADDON_DIR .. "tests/stubs.lua")

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

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local src = f:read("*a")
	f:close()
	return src
end

local LUA_FILES = {
	"Locales.lua",
	"Core.lua",
	"DB.lua",
	"Skins.lua",
	"WidgetPool.lua",
	"Sound.lua",
	"UI_DragCursor.lua",
	"UI_NoteEditor.lua",
	"UI_MainWindow.lua",
	"MinimapButton.lua",
	"Detection.lua",
	"ContextMenu.lua",
	"Tooltips.lua",
	"SlashCommands.lua",
	"Init.lua",
}

local function allSources()
	local parts = {}
	for _, name in ipairs(LUA_FILES) do
		parts[#parts + 1] = readFile(ADDON_DIR .. name)
	end
	return table.concat(parts, "\n")
end

local function loadmod(ns, name)
	local chunk, err = loadfile(ADDON_DIR .. name)
	assert(chunk, "cannot load " .. name .. ": " .. tostring(err))
	chunk("GroupWatch", ns)
end

-- Logic-only subset (mirrors tests/run.lua; UI files needing the full
-- client are loaded per-section with mocks).
local function loadLogic(ns)
	loadmod(ns, "Locales.lua")
	loadmod(ns, "Core.lua")
	loadmod(ns, "DB.lua")
	loadmod(ns, "Detection.lua")
	loadmod(ns, "ContextMenu.lua")
	loadmod(ns, "Tooltips.lua")
	loadmod(ns, "UI_DragCursor.lua")
end

-- ---------------------------------------------------------------------------
-- 1. Banned / removed globals (source scan)
-- ---------------------------------------------------------------------------

do
	local src = allSources()
	local banned = {
		"GetNumRaidMembers",
		"UnitNameFromGUID",
		"UnitClassFromGUID",
		"UnitHealthPercent",
		"UnitPowerPercent",
		"UnitHealthMissing",
		"UnitSexBase",
		"BNSendWhisper",
		"BNSendGameTime",
		"CombatLogGetCurrentEventInfo",
		"DoEmote",
		"ShowHelm",
		"ShowCloak",
		"string.concat",
		"SetPortraitToTexture",
		"UIDropDownMenu",
		"UnitPopup",
		"EasyMenu",
		"SendChatMessage",
		"COMBAT_LOG",
		"CHAT_MSG",
		"UnitGUID",
		"GetAction",
	}
	for _, name in ipairs(banned) do
		check("no banned global " .. name, src:find(name, 1, true) == nil)
	end

	-- GetAddOnMetadata / GetBattlegroundInfo are only legal via their C_
	-- namespaces (C_AddOns / C_PvP).
	local scrubbed = src:gsub("C_AddOns%.GetAddOnMetadata", "")
	check("no bare GetAddOnMetadata", scrubbed:find("GetAddOnMetadata", 1, true) == nil)
	scrubbed = src:gsub("C_PvP%.GetBattlegroundInfo", "")
	check("no bare GetBattlegroundInfo", scrubbed:find("GetBattlegroundInfo", 1, true) == nil)

	-- Modern menu/tooltip APIs only; no legacy dropdown reintroduction.
	check("Menu.ModifyMenu used", src:find("Menu.ModifyMenu", 1, true) ~= nil)
	check("MenuUtil.CreateContextMenu used", src:find("MenuUtil.CreateContextMenu", 1, true) ~= nil)
	check(
		"TooltipDataProcessor post-call used",
		src:find("TooltipDataProcessor", 1, true) ~= nil
			and src:find("AddTooltipPostCall", 1, true) ~= nil
	)

	-- GetPlayerInfoByGUID positional unpack must stay (6th name, 7th realm);
	-- GUID substrings are never parsed/stored as persistent ids.
	local tipSrc = readFile(ADDON_DIR .. "Tooltips.lua")
	check(
		"GetPlayerInfoByGUID unpack order (name 6th, realm 7th)",
		tipSrc:find("_, _, _, _, _, pName, pRealm = pcall(GetPlayerInfoByGUID", 1, true) ~= nil
	)

	-- No OnUpdate polling of unit state: only drag-cursor frame updates.
	for _, name in ipairs(LUA_FILES) do
		local fsrc = readFile(ADDON_DIR .. name)
		local hasUpdate = fsrc:find("OnUpdate", 1, true) ~= nil
		if name == "UI_DragCursor.lua" or name == "MinimapButton.lua" then
			check("OnUpdate allowed in " .. name, hasUpdate)
		else
			check("no OnUpdate in " .. name, not hasUpdate, name)
		end
	end

	-- Init.lua registers exactly the three lifecycle/roster events.
	local initSrc = readFile(ADDON_DIR .. "Init.lua")
	check("Init listens ADDON_LOADED", initSrc:find('"ADDON_LOADED"', 1, true) ~= nil)
	check("Init listens PLAYER_LOGIN", initSrc:find('"PLAYER_LOGIN"', 1, true) ~= nil)
	check(
		"Init listens GROUP_ROSTER_UPDATE",
		initSrc:find('"GROUP_ROSTER_UPDATE"', 1, true) ~= nil
	)
end

-- ---------------------------------------------------------------------------
-- 2. TOC identity
-- ---------------------------------------------------------------------------

do
	local toc = readFile(ADDON_DIR .. "GroupWatch.toc")
	check("TOC Interface 120105, 16001", toc:find("## Interface: 120105, 16001", 1, true) ~= nil)
	check("TOC OptionalDeps EllesmereUI", toc:find("EllesmereUI", 1, true) ~= nil)
	check("TOC OptionalDeps ElvUI", toc:find("ElvUI", 1, true) ~= nil)
	check("TOC no RequiredDeps", toc:find("## RequiredDeps", 1, true) == nil)
	check("TOC no hard Dependencies", toc:find("## Dependencies:", 1, true) == nil)
end

-- ---------------------------------------------------------------------------
-- 3. Skins.lua: pcall + caching + non-function fields
-- ---------------------------------------------------------------------------

do
	local function loadSkins(elvui, ellesmere)
		_G.ElvUI = elvui
		_G.EllesmereUI = ellesmere
		local ns = {}
		loadmod(ns, "Skins.lua")
		return ns
	end

	-- Missing engine: everything is a silent no-op.
	local ns = loadSkins(nil, nil)
	check("Skins: absent ElvUI not present", ns.IsElvUIPresent() == false)
	check("Skins: absent ElvUI no module", ns.GetElvUISkins() == nil)
	local ok, err = pcall(ns.SkinButton, {})
	check("Skins: absent ElvUI SkinButton no throw", ok, err)
	ok, err = pcall(ns.SkinCloseButton, {})
	check("Skins: absent ElvUI SkinCloseButton no throw", ok, err)
	ok, err = pcall(ns.SkinScrollBar, {})
	check("Skins: absent ElvUI SkinScrollBar no throw", ok, err)
	ok, err = pcall(ns.SkinWindow, {})
	check("Skins: absent ElvUI SkinWindow no throw", ok, err)
	ok, err = pcall(ns.SkinButton, nil)
	check("Skins: nil button no throw", ok, err)

	-- Throwing GetModule: pcall-contained, still absent.
	ns = loadSkins({
		[1] = {
			GetModule = function()
				error("ElvUI boom")
			end,
		},
	}, nil)
	ok, err = pcall(ns.IsElvUIPresent)
	check("Skins: throwing GetModule no throw", ok, err)
	check("Skins: throwing GetModule not present", ns.IsElvUIPresent() == false)
	ok, err = pcall(ns.SkinWindow, {})
	check("Skins: throwing GetModule SkinWindow no throw", ok, err)

	-- Missing accessor / non-table module: absent, no throw.
	ns = loadSkins({ [1] = {} }, nil)
	check("Skins: no GetModule not present", ns.IsElvUIPresent() == false)
	ns = loadSkins({
		[1] = {
			GetModule = function()
				return "not-a-table"
			end,
		},
	}, nil)
	check("Skins: non-table module not present", ns.IsElvUIPresent() == false)

	-- Caching: one GetModule call no matter how many widgets are skinned.
	local calls = 0
	local handled = {}
	local skinsMod = {}
	function skinsMod:HandleButton(b)
		handled[#handled + 1] = b
	end
	ns = loadSkins({
		[1] = {
			GetModule = function(_, name)
				calls = calls + 1
				assert(name == "Skins")
				return skinsMod
			end,
		},
	}, nil)
	check("Skins: engine present", ns.IsElvUIPresent() == true)
	ns.SkinButton({})
	ns.SkinCloseButton({})
	ns.SkinScrollBar({})
	ns.SkinWindow({})
	ns.SkinButton({})
	check("Skins: GetModule cached (1 call)", calls == 1, calls)

	-- Module without handlers: silent no-op.
	ns = loadSkins({
		[1] = {
			GetModule = function()
				return {}
			end,
		},
	}, nil)
	ok, err = pcall(function()
		ns.SkinButton({})
		ns.SkinCloseButton({})
		ns.SkinScrollBar({})
		ns.SkinWindow({})
	end)
	check("Skins: handler-less module no throw", ok, err)

	-- EllesmereUI with non-function fields: type-checked, no throw.
	ns = loadSkins(nil, {
		RegisterSkin = function(name, cb)
			cb({ Button = "x", CloseButton = {}, ScrollBar = 0, Shell = false, Font = "y" })
		end,
	})
	ok, err = pcall(function()
		ns.SkinButton({})
		ns.SkinCloseButton({})
		ns.SkinScrollBar({})
		ns.SkinWindow({})
	end)
	check("Skins: non-function skinEUI fields no throw", ok, err)

	-- Cache invalidation lets a late-loading engine get picked up.
	calls = 0
	local lateElvUI = {
		[1] = {
			GetModule = function()
				calls = calls + 1
				return skinsMod
			end,
		},
	}
	ns = loadSkins(nil, nil)
	check("Skins: pre-login absent", ns.IsElvUIPresent() == false)
	_G.ElvUI = lateElvUI
	ns.InvalidateElvUICache()
	check("Skins: late engine detected after invalidate", ns.IsElvUIPresent() == true)
	_G.ElvUI = nil
	_G.EllesmereUI = nil
end

-- ---------------------------------------------------------------------------
-- 4. Sound.lua: PlaySound / PlaySoundFile nil-safe
-- ---------------------------------------------------------------------------

do
	-- Phase A: neither API exists (restricted/test context).
	_G.PlaySound = nil
	_G.PlaySoundFile = nil
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Sound.lua")
	Stubs.reset()
	ns.InitDB()
	local ok, res = pcall(ns.PlayListSound, 8959)
	check("Sound: nil PlaySound no throw", ok, res)
	check("Sound: nil PlaySound returns false", ok and res == false, res)
	ok, res = pcall(ns.PlayListSound, "Oof")
	check("Sound: nil PlaySoundFile user sound no throw", ok, res)
	check("Sound: nil PlaySoundFile user sound returns false", ok and res == false, res)

	-- Phase B: real APIs -> sounds play.
	_G.PlaySound = function()
	end
	_G.PlaySoundFile = function()
		return true
	end
	local ns2 = {}
	loadLogic(ns2)
	loadmod(ns2, "Sound.lua")
	Stubs.reset()
	ns2.InitDB()
	ok, res = pcall(ns2.PlayListSound, 8959)
	check("Sound: PlaySound path no throw", ok, res)
	check("Sound: PlaySound path returns true", ok and res == true, res)
	ok, res = pcall(ns2.PlayListSound, "Oof")
	check("Sound: PlaySoundFile path no throw", ok, res)
	check("Sound: PlaySoundFile path returns true", ok and res == true, res)
	_G.PlaySound = nil
	_G.PlaySoundFile = nil
end

-- ---------------------------------------------------------------------------
-- 5. UI_NoteEditor.lua: C_Timer + font + playerName nil-safe
-- ---------------------------------------------------------------------------

do
	-- Phase A: no C_Timer, GetFontObject() returns nil.
	_G.C_Timer = nil
	MockUI.fontNil = true
	MockUI.cursor = {}
	MockUI.frames = {}
	MockUI.byName = {}
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Skins.lua")
	loadmod(ns, "Sound.lua")
	loadmod(ns, "UI_NoteEditor.lua")
	Stubs.reset()
	ns.InitDB()

	local ok, err = pcall(ns.ShowNoteEditor, "Hero-Realm", "Default", "hello")
	check("NoteEditor: open without C_Timer/font no throw", ok, err)
	local eb = MockUI.byName["GroupWatchNoteEditBox"]
	check("NoteEditor: editBox got note text", eb ~= nil and eb.text == "hello", eb and eb.text)
	check(
		"NoteEditor: cursor at end of note",
		MockUI.cursor[#MockUI.cursor] == 5,
		MockUI.cursor[#MockUI.cursor]
	)
	local editor = MockUI.byName["GroupWatchNoteEditor"]
	check("NoteEditor: frame shown", editor ~= nil and editor.hidden == false)

	-- OnTextChanged with nil font falls back to a default line height.
	local onText = eb and eb.scripts["OnTextChanged"]
	ok, err = pcall(onText, eb)
	check("NoteEditor: OnTextChanged with nil font no throw", ok, err)
	check("NoteEditor: OnTextChanged sets numeric height", ok and type(eb.height) == "number")

	-- nil/invalid player or list names never open the editor.
	local noteDataBefore = editor.noteData
	ok, err = pcall(ns.ShowNoteEditor, nil, "Default", "x")
	check("NoteEditor: nil playerName no throw", ok, err)
	check("NoteEditor: nil playerName keeps state", editor.noteData == noteDataBefore)
	ok, err = pcall(ns.ShowNoteEditor, "Hero-Realm", nil, "x")
	check("NoteEditor: nil listName no throw", ok, err)
	ok, err = pcall(ns.SavePlayerNote, "Default", nil, "x")
	check("NoteEditor: SavePlayerNote nil player no throw", ok, err)

	-- Phase B: C_Timer present, real font object.
	_G.C_Timer = {
		After = function(_, fn)
			MockUI.after[#MockUI.after + 1] = fn
			fn()
		end,
	}
	MockUI.fontNil = false
	MockUI.fontHeight = 20
	MockUI.cursor = {}
	MockUI.after = {}
	MockUI.frames = {}
	MockUI.byName = {}
	local ns2 = {}
	loadLogic(ns2)
	loadmod(ns2, "Skins.lua")
	loadmod(ns2, "Sound.lua")
	loadmod(ns2, "UI_NoteEditor.lua")
	Stubs.reset()
	ns2.InitDB()
	ok, err = pcall(ns2.ShowNoteEditor, "Hero-Realm", "Default", "note")
	check("NoteEditor: open with C_Timer/font no throw", ok, err)
	check("NoteEditor: C_Timer.After used", #MockUI.after == 1, #MockUI.after)
	local eb2 = MockUI.byName["GroupWatchNoteEditBox"]
	eb2.text = "a\nb\nc\nd\ne\nf\ng\nh\ni\nj" -- 10 lines
	ok, err = pcall(eb2.scripts["OnTextChanged"], eb2)
	check("NoteEditor: OnTextChanged with font no throw", ok, err)
	check("NoteEditor: OnTextChanged font height math", ok and eb2.height == 10 * (20 + 2) + 20, eb2 and eb2.height)
	_G.C_Timer = nil
end

-- ---------------------------------------------------------------------------
-- 6. Realms: normalized keys, GetNormalizedRealmName fallback
-- ---------------------------------------------------------------------------

do
	_G.PlaySound = nil
	_G.PlaySoundFile = nil
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Sound.lua")

	Stubs.reset()
	check("HomeRealm falls back to GetRealmName", ns.GetHomeRealm() == "MyRealm", ns.GetHomeRealm())

	Stubs.realm = "Wrong Realm"
	Stubs.normalizedRealm = "Connected Realm"
	check(
		"HomeRealm prefers GetNormalizedRealmName",
		ns.GetHomeRealm() == "ConnectedRealm",
		ns.GetHomeRealm()
	)

	Stubs.normalizedRealm = { err = "boom" }
	Stubs.realm = "My Realm"
	local ok, res = pcall(ns.GetHomeRealm)
	check("HomeRealm throwing normalized API no throw", ok, res)
	check("HomeRealm throwing normalized API falls back", ok and res == "MyRealm", res)

	Stubs.normalizedRealm = nil
	Stubs.realm = nil
	ok, res = pcall(ns.GetHomeRealm)
	check("HomeRealm nil APIs no throw", ok, res)
	check("HomeRealm nil APIs returns empty", ok and res == "", res)
	Stubs.realm = "My Realm"

	check("GetFullName appends normalized home realm", ns.GetFullName("Hero") == "Hero-MyRealm")
	Stubs.normalizedRealm = "Connected Realm"
	check(
		"GetFullName uses normalized realm",
		ns.GetFullName("Hero") == "Hero-ConnectedRealm",
		ns.GetFullName("Hero")
	)
	Stubs.normalizedRealm = nil

	check("NormalizeRealm strips spaces", ns.NormalizeRealm("  A  B  ") == "AB")
	check("NormalizeRealm nil falls back home", ns.NormalizeRealm(nil) == "MyRealm")
	check("NormalizeRealm non-string falls back home", ns.NormalizeRealm(123) == "MyRealm")

	check("DisplayName shortens via Ambiguate", ns.GetDisplayName("Hero-MyRealm") == "Hero")
	Stubs.ambiguateErr = "boom"
	ok, res = pcall(ns.GetDisplayName, "Hero-MyRealm")
	check("DisplayName throwing Ambiguate no throw", ok, res)
	check("DisplayName throwing Ambiguate falls back", ok and res == "Hero-MyRealm", res)
	Stubs.ambiguateErr = nil
	check("DisplayName nil passthrough", ns.GetDisplayName(nil) == nil)

	-- Realm normalization flows through the roster scan without throwing.
	Stubs.reset()
	ns.InitDB()
	local def = ns.GetDefaultListName()
	GroupWatchDB.lists[def].players = { ["Hero-ConnectedRealm"] = true }
	ns.InvalidateWatchedIndex()
	Stubs.inGroup = true
	Stubs.numMembers = 2
	Stubs.normalizedRealm = "Connected Realm"
	Stubs.units = {
		party1 = { name = "Hero", realm = nil },
		player = { name = "Me", realm = nil },
	}
	ns.PlayListSound = function()
	end
	ok, err = pcall(ns.CheckGroup)
	check("CheckGroup nil unit realms normalize no throw", ok, err)
	Stubs.normalizedRealm = nil
end

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------

say(string.format("----\n%d passed, %d failed", passed, failed))
if failed > 0 then
	os.exit(1)
end
