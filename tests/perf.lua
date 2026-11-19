-- GroupWatch P2 (performance) regression tests.
--
-- Covers the no-behavior-change perf work: tooltip sort-skip + miss-path
-- allocation avoidance, widget .data table reuse, per-refresh ElvUI/skin
-- caching, drag-cursor hit-test throttling, and Detection index/session
-- caching. Behavior assertions (order, highlight target) are included so a
-- wrong "optimization" fails loudly.
--
-- Run from the addon directory with any Lua 5.1+ interpreter:
--   lua tests/perf.lua
--   lua5.1 tests/perf.lua
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

MockUI = { frames = {}, byName = {}, cursor = { x = 0, y = 0 } }

local function makeMock(kind)
	local self = { __kind = kind, scripts = {}, hidden = true, text = "" }
	function self:SetSize()
	end
	function self:SetPoint()
	end
	function self:SetAllPoints()
	end
	function self:ClearAllPoints()
	end
	function self:SetMovable()
	end
	function self:EnableMouse()
	end
	function self:EnableMouseWheel()
	end
	function self:RegisterForDrag()
	end
	function self:RegisterForClicks()
	end
	function self:SetParent(p)
		self.parent = p
	end
	function self:SetScript(k, fn)
		self.scripts[k] = fn
	end
	function self:GetScript(k)
		return self.scripts[k]
	end
	function self:HookScript(k, fn)
		self.scripts[k] = fn
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
	function self:SetBackdropBorderColor()
	end
	function self:RegisterEvent()
	end
	function self:StartMoving()
	end
	function self:StopMovingOrSizing()
	end
	function self:StripTextures()
	end
	function self:SetTemplate()
	end
	function self:CreateBackdrop()
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
	function self:GetEffectiveScale()
		return 1
	end
	function self:GetRect()
		return 0, 0, 500, 500
	end
	function self:GetCenter()
		return 400, 300
	end
	function self:GetVerticalScroll()
		return 0
	end
	function self:SetVerticalScroll(v)
		self.scrollPos = v
	end
	function self:GetVerticalScrollRange()
		return 0
	end
	function self:SetScrollChild(child)
		self.scrollChild = child
	end
	function self:SetText(t)
		self.text = t
	end
	function self:GetText()
		return self.text
	end
	function self:SetAlpha(a)
		self.alpha = a
	end
	function self:GetAlpha()
		return self.alpha or 1
	end
	function self:SetColorTexture()
	end
	function self:SetTexture()
	end
	function self:SetTexCoord()
	end
	function self:SetBlendMode()
	end
	function self:SetJustifyH()
	end
	function self:SetJustifyV()
	end
	function self:GetStringWidth()
		return 100
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
function UIParent:GetWidth()
	return 800
end
function UIParent:GetHeight()
	return 600
end
UISpecialFrames = {}

function GetCursorPosition()
	return MockUI.cursor.x, MockUI.cursor.y
end

function IsMouseButtonDown()
	return true
end

function IsKeyDown()
	return false
end

dofile(ADDON_DIR .. "tests/stubs.lua")

-- Count table.sort calls: Core.lua captures table.sort into ns.Globals at
-- load time, so the wrapper must be installed before any addon module loads.
local sortCalls = 0
local realSort = table.sort
table.sort = function(t, ...)
	sortCalls = sortCalls + 1
	return realSort(t, ...)
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

local ns = {}
local function loadmod(name)
	local chunk, err = loadfile(ADDON_DIR .. name)
	assert(chunk, "cannot load " .. name .. ": " .. tostring(err))
	chunk("GroupWatch", ns)
end

loadmod("Locales.lua")
loadmod("Core.lua")
loadmod("DB.lua")
loadmod("Skins.lua")
loadmod("WidgetPool.lua")
loadmod("Sound.lua")
loadmod("Detection.lua")
loadmod("ContextMenu.lua")
loadmod("Tooltips.lua")
loadmod("UI_DragCursor.lua")
loadmod("UI_MainWindow.lua")

-- Sound.lua is not loaded (needs the client); record sound requests instead.
ns.PlayListSound = function(sound)
	Stubs.playedSounds[#Stubs.playedSounds + 1] = sound
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
-- 1. Tooltips: sort-skip + miss-path allocation avoidance
-- ---------------------------------------------------------------------------

do
	-- Miss with no DB at all: no sort, no lines.
	Stubs.reset()
	local tip = makeTooltip()
	sortCalls = 0
	local ok, err = pcall(ns.AppendNotesToTooltip, tip, "Nobody-Realm")
	check("Perf tooltip: nil DB no throw", ok, err)
	check("Perf tooltip: miss sorts nothing", sortCalls == 0, sortCalls)
	check("Perf tooltip: miss adds no lines", #tip.lines == 0, #tip.lines)

	-- Single entry: order is trivial, sort must be skipped.
	fresh()
	local def = ns.GetDefaultListName()
	GroupWatchDB.lists[def].players = { ["Hero-Realm"] = true }
	GroupWatchDB.lists[def].notes = { ["Hero-Realm"] = "spy" }
	ns.InvalidateWatchedIndex()
	tip = makeTooltip()
	sortCalls = 0
	ok, err = pcall(ns.AppendNotesToTooltip, tip, "Hero-Realm")
	check("Perf tooltip: single entry no throw", ok, err)
	check("Perf tooltip: single entry sorts nothing", sortCalls == 0, sortCalls)
	check("Perf tooltip: single entry blank + note line", #tip.lines == 2, #tip.lines)
	check(
		"Perf tooltip: single entry keeps note text",
		tip.lines[2] ~= nil and tip.lines[2]:find("spy", 1, true) ~= nil,
		tip.lines[2]
	)

	-- Multiple entries: still sorted exactly once, default list first.
	GroupWatchDB.lists["Beta"] = {
		message = "m",
		sound = 0,
		collapsed = false,
		players = { ["Hero-Realm"] = true },
		notes = {},
	}
	GroupWatchDB.lists["Alpha"] = {
		message = "m",
		sound = 0,
		collapsed = false,
		players = { ["Hero-Realm"] = true },
		notes = { ["Hero-Realm"] = "ask" },
	}
	ns.InvalidateWatchedIndex()
	tip = makeTooltip()
	sortCalls = 0
	ok, err = pcall(ns.AppendNotesToTooltip, tip, "Hero-Realm")
	check("Perf tooltip: multi entry no throw", ok, err)
	check("Perf tooltip: multi entry sorts once", sortCalls == 1, sortCalls)
	check("Perf tooltip: multi entry blank + 3 lines", #tip.lines == 4, #tip.lines)
	check(
		"Perf tooltip: default list first",
		tip.lines[2] ~= nil and tip.lines[2]:find("spy", 1, true) ~= nil,
		tip.lines[2]
	)
	check(
		"Perf tooltip: Alpha before Beta",
		tip.lines[3] ~= nil and tip.lines[3]:find("Alpha", 1, true) ~= nil,
		tip.lines[3]
	)
	check(
		"Perf tooltip: Beta last",
		tip.lines[4] ~= nil and tip.lines[4]:find("Beta", 1, true) ~= nil,
		tip.lines[4]
	)
end

-- ---------------------------------------------------------------------------
-- 2. Widget .data table reuse (no fresh table per row per refresh)
-- ---------------------------------------------------------------------------

do
	local w = {}
	local d1 = ns.SetWidgetData(w, "P-Realm", "L")
	check("Perf data: table attached", w.data == d1)
	local d2 = ns.SetWidgetData(w, "Q-Realm", "L2")
	check("Perf data: same table reused", rawequal(d1, d2))
	check("Perf data: playerName updated", d2.playerName == "Q-Realm", d2.playerName)
	check("Perf data: listName updated", d2.listName == "L2", d2.listName)

	-- Header-style reuse clears a stale playerName from a recycled widget.
	local h = {}
	local hd1 = ns.SetWidgetData(h, "P-Realm", "L")
	local hd2 = ns.SetWidgetData(h, nil, "L2")
	check("Perf data: header reuse same table", rawequal(hd1, hd2))
	check("Perf data: stale playerName cleared", hd2.playerName == nil, hd2.playerName)
	check("Perf data: header listName set", hd2.listName == "L2", hd2.listName)

	-- First assignment allocates exactly one table.
	local w2 = {}
	local before = w2.data
	ns.SetWidgetData(w2, nil, "OnlyList")
	check("Perf data: first use creates table", before == nil and type(w2.data) == "table")
	check("Perf data: header shape", w2.data.playerName == nil and w2.data.listName == "OnlyList")
end

-- ---------------------------------------------------------------------------
-- 3. Full Refresh smoke: pooled-widget correctness with the perf paths
-- ---------------------------------------------------------------------------

do
	fresh()
	local def = ns.GetDefaultListName()
	GroupWatchDB.lists["Beta"] = {
		message = "m",
		sound = 0,
		collapsed = false,
		players = { ["A-Realm"] = true, ["B-Realm"] = true },
		notes = { ["A-Realm"] = "note-a" },
	}
	ns.InvalidateWatchedIndex()
	ns.selectedList = def
	ns.selectedPlayer = nil
	_G.ElvUI = nil
	ns.InvalidateElvUICache()

	local ui = nil
	local ok, err = pcall(function()
		ns.ToggleUI()
		ui = ns.GroupWatchUI
	end)
	check("Perf refresh: ToggleUI no throw", ok, err)
	check("Perf refresh: window shown", ui ~= nil and ui:IsShown())

	-- 2 headers + 2 player rows (Default is empty -> placeholder, no row).
	local nTargets = (ui and ui.dropTargets and #ui.dropTargets) or -1
	check("Perf refresh: drop targets rebuilt", nTargets == 4, nTargets)

	-- Snapshot widget + .data identities, refresh again, same tables reused.
	local snap = {}
	if ui and ui.dropTargets then
		for i, row in ipairs(ui.dropTargets) do
			snap[i] = { w = row, d = row.data }
		end
	end
	sortCalls = 0
	ok, err = pcall(function()
		ui:Refresh()
	end)
	check("Perf refresh: second Refresh no throw", ok, err)
	local sameCount = ui ~= nil and ui.dropTargets ~= nil and #ui.dropTargets == #snap
	check("Perf refresh: same target count", sameCount, ui and ui.dropTargets and #ui.dropTargets)
	local reused = true
	if ui and ui.dropTargets then
		for i, row in ipairs(ui.dropTargets) do
			if not rawequal(row, snap[i].w) or not rawequal(row.data, snap[i].d) then
				reused = false
			end
		end
	end
	check("Perf refresh: widgets + .data tables reused", reused)
	local namesOk = true
	if ui and ui.dropTargets then
		for _, row in ipairs(ui.dropTargets) do
			if type(row.data) ~= "table" or type(row.data.listName) ~= "string" then
				namesOk = false
			end
		end
	end
	check("Perf refresh: .data fields valid", namesOk)

	ui:Hide()
end

-- ---------------------------------------------------------------------------
-- 4. ElvUI cache: one GetModule call per refresh burst
-- ---------------------------------------------------------------------------

do
	local calls = 0
	local handled = {}
	local skinsMod = {}
	function skinsMod:HandleButton(b)
		handled[#handled + 1] = b
	end
	_G.ElvUI = {
		[1] = {
			GetModule = function(_, name)
				calls = calls + 1
				assert(name == "Skins")
				return skinsMod
			end,
		},
	}
	ns.InvalidateElvUICache()
	calls = 0
	handled = {}

	-- Direct cached path: one lookup builds the cache, N skins cost nothing.
	local cache = { eui = ns.skinEUI, elv = ns.GetElvUISkins() }
	check("Perf skins: cache build is one GetModule call", calls == 1, calls)
	for i = 1, 10 do
		local ok, err = pcall(ns._SkinButtonCached, {}, cache)
		if not ok then
			check("Perf skins: cached SkinButton no throw", false, err)
			break
		end
		if i == 10 then
			check("Perf skins: cached SkinButton no throw", true)
		end
	end
	check("Perf skins: burst of 10 costs no more calls", calls == 1, calls)
	check("Perf skins: all 10 handled", #handled == 10, #handled)

	-- Non-function skin fields stay silent no-ops on the cached path.
	local ok, err = pcall(function()
		ns._SkinButtonCached({}, { eui = { Button = "x" }, elv = nil })
		ns._SkinButtonCached(nil, cache)
	end)
	check("Perf skins: bad fields / nil button no throw", ok, err)

	-- Full Refresh with the engine present: still exactly one call total.
	local ui = ns.GroupWatchUI
	calls = 0
	ns.InvalidateElvUICache()
	ok, err = pcall(function()
		ui:Refresh()
	end)
	check("Perf skins: Refresh with ElvUI no throw", ok, err)
	check("Perf skins: whole Refresh costs one GetModule call", calls == 1, calls)
	ok, err = pcall(function()
		ui:Refresh()
	end)
	check("Perf skins: second Refresh no throw", ok, err)
	check("Perf skins: cache persists across refreshes", calls == 1, calls)

	_G.ElvUI = nil
	ns.InvalidateElvUICache()
end

-- ---------------------------------------------------------------------------
-- 5. Drag throttle: half the hit tests, highlight never sticks
-- ---------------------------------------------------------------------------

do
	fresh()
	GroupWatchDB.lists["A"] = {
		message = "m",
		sound = 0,
		collapsed = false,
		players = { ["Hero-Realm"] = true },
		notes = {},
	}
	GroupWatchDB.lists["B"] = {
		message = "m",
		sound = 0,
		collapsed = false,
		players = {},
		notes = {},
	}
	GroupWatchDB.lists["C"] = {
		message = "m",
		sound = 0,
		collapsed = false,
		players = {},
		notes = {},
	}
	ns.InvalidateWatchedIndex()
	Stubs.units = {}

	local savedUI = ns.GroupWatchUI
	local scroll = makeMock("scroll")
	function scroll:GetRect()
		return 0, 0, 500, 500
	end
	local function makeRow(lName, left, bottom, w, h)
		local row = makeMock("button")
		row:Show()
		function row:GetRect()
			return left, bottom, w, h
		end
		row.data = { listName = lName }
		row.dragHighlight = makeMock("texture")
		row.dragHighlightBar = makeMock("texture")
		return row
	end
	local rowB = makeRow("B", 10, 10, 100, 20)
	local rowC = makeRow("C", 10, 40, 100, 20)
	ns.GroupWatchUI = { dropTargets = { rowB, rowC }, scrollFrame = scroll }

	MockUI.cursor.x, MockUI.cursor.y = 60, 20 -- over row B
	local ok, err = pcall(ns.ShowDragCursor, "Hero-Realm", "A")
	check("Perf drag: ShowDragCursor no throw", ok, err)
	check("Perf drag: drag active", ns.IsDragCursorActive())

	local origHit = ns.GetDragTargetAtCursor
	local hitTests = 0
	ns.GetDragTargetAtCursor = function(...)
		hitTests = hitTests + 1
		return origHit(...)
	end

	ns._ResetDragThrottle()
	local okRefresh = true
	for i = 1, 4 do
		local okCall, errCall = pcall(ns.RefreshDragCursorTarget)
		okRefresh = okRefresh and okCall
		if not okCall then
			err = errCall
		end
	end
	check("Perf drag: throttled refresh no throw", okRefresh, err)
	check("Perf drag: 4 ticks cost 2 hit tests", hitTests == 2, hitTests)
	check(
		"Perf drag: highlight lands on B",
		rowB.dragHighlight.hidden == false and rowC.dragHighlight.hidden == true
	)

	-- Pointer moves to C: the highlight must follow within two ticks.
	MockUI.cursor.x, MockUI.cursor.y = 60, 50
	local beforeMove = hitTests
	for i = 1, 2 do
		pcall(ns.RefreshDragCursorTarget)
	end
	check("Perf drag: move costs at most 1 more hit test", hitTests - beforeMove <= 1, hitTests - beforeMove)
	check(
		"Perf drag: highlight follows to C (no stick)",
		rowC.dragHighlight.hidden == false and rowB.dragHighlight.hidden == true
	)

	-- Forced refresh (layout change) applies immediately.
	MockUI.cursor.x, MockUI.cursor.y = 60, 20 -- back over B
	local beforeForce = hitTests
	ok, err = pcall(ns.RefreshDragCursorTarget, true)
	check("Perf drag: forced refresh no throw", ok, err)
	check("Perf drag: forced refresh hit-tests now", hitTests == beforeForce + 1, hitTests - beforeForce)
	check(
		"Perf drag: forced refresh highlights B",
		rowB.dragHighlight.hidden == false and rowC.dragHighlight.hidden == true
	)

	ns.HideDragCursor()
	check("Perf drag: drag inactive after hide", not ns.IsDragCursorActive())
	ns.GetDragTargetAtCursor = origHit
	ns.GroupWatchUI = savedUI
end

-- ---------------------------------------------------------------------------
-- 6. Detection: cached index + session dedupe (no per-event rebuild)
-- ---------------------------------------------------------------------------

do
	fresh()
	local def = ns.GetDefaultListName()
	GroupWatchDB.lists[def].message = "%s is here"
	GroupWatchDB.lists[def].sound = ns.DEFAULT_SOUND
	GroupWatchDB.lists[def].players = { ["Hero-Realm"] = true }
	ns.InvalidateWatchedIndex()

	local i1 = ns.GetWatchedIndex()
	local i2 = ns.GetWatchedIndex()
	check("Perf detection: index cached (no rebuild)", rawequal(i1, i2))

	Stubs.inGroup = true
	Stubs.inRaid = false
	Stubs.numMembers = 2
	Stubs.units = {
		party1 = { name = "Hero", realm = "Realm" },
		player = { name = "Me", realm = "Realm" },
	}
	Stubs.playedSounds = {}
	local ok, err = pcall(ns.CheckGroup)
	check("Perf detection: CheckGroup no throw", ok, err)
	check("Perf detection: watched member announces", #Stubs.playedSounds == 1, #Stubs.playedSounds)
	ok, err = pcall(ns.CheckGroup)
	check("Perf detection: repeat event no throw", ok, err)
	check("Perf detection: session dedupes repeat", #Stubs.playedSounds == 1, #Stubs.playedSounds)

	-- Member leaves and rejoins: forgotten, then announced again.
	Stubs.units = { player = { name = "Me", realm = "Realm" } }
	Stubs.numMembers = 1
	pcall(ns.CheckGroup)
	Stubs.units = {
		party1 = { name = "Hero", realm = "Realm" },
		player = { name = "Me", realm = "Realm" },
	}
	Stubs.numMembers = 2
	pcall(ns.CheckGroup)
	check("Perf detection: rejoin announces again", #Stubs.playedSounds == 2, #Stubs.playedSounds)
end

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------

say(string.format("----\n%d passed, %d failed", passed, failed))
if failed > 0 then
	os.exit(1)
end
