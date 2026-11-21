-- GroupWatch auto-actions + LFG applicant tests (issue #5 partial feature).
--
-- Covers: DB migration, GetAutoAction precedence, direct-invite accept/decline,
-- secret guards, session block handling, LFG role capacity, secret applicants,
-- chat-messaging lockdown, the manual-only LFG panel, and tooltip hardening.
--
-- Run from the addon directory with any Lua 5.1+ interpreter:
--   lua tests/auto.lua
--   lua5.1 tests/auto.lua
-- Exit code is 0 when every test passes, 1 otherwise.
-- Lua 5.1-safe only (no goto, no bitwise, no integer division).

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
LE_PARTY_CATEGORY_HOME = 1
UISpecialFrames = {}
TooltipDataProcessor = nil
LFGListUtil_SetSearchEntryTooltip = nil
Enum = nil

MockUI = { frames = {}, byName = {}, timers = {} }

local function makeMock(kind)
	local self = { __kind = kind, scripts = {}, events = {}, hidden = true, text = "" }

	function self:SetSize(w, h)
		self.width, self.height = w, h
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
		return self.height or 100
	end
	function self:SetAllPoints()
	end
	function self:SetPoint()
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
	function self:GetParent()
		return self.parent
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
	function self:RegisterEvent(event)
		self.events[#self.events + 1] = event
	end
	function self:SetClampedToScreen()
	end
	function self:SetFrameStrata()
	end
	function self:SetFrameLevel()
	end
	function self:SetBackdrop()
	end
	function self:SetTemplate()
	end
	function self:CreateBackdrop()
	end
	function self:ClearBackdrop()
	end
	function self:SetBackdropColor()
	end
	function self:SetBackdropBorderColor()
	end
	function self:StripTextures()
	end
	function self:SetNormalTexture()
	end
	function self:SetPushedTexture()
	end
	function self:SetHighlightTexture()
	end
	function self:SetDisabledTexture()
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
	function self:SetText(t)
		self.text = t
	end
	function self:GetText()
		return self.text
	end
	function self:SetTextColor()
	end
	function self:SetAlpha()
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
	function self:SetWordWrap()
	end
	function self:SetShadowOffset()
	end
	function self:SetShadowColor()
	end
	function self:SetFont()
	end
	function self:GetFont()
		return "Fonts\\FRIZQT__.TTF", 12
	end
	function self:SetFontObject()
	end
	function self:GetFontObject()
		return nil
	end
	function self:SetFocus()
	end
	function self:SetCursorPosition()
	end
	function self:SetMultiLine()
	end
	function self:SetAutoFocus()
	end
	function self:Insert(t)
		self.text = self.text .. (t or "")
	end
	function self:SetScrollChild(child)
		self.scrollChild = child
	end
	function self:GetVerticalScroll()
		return 0
	end
	function self:SetVerticalScroll()
	end
	function self:GetVerticalScrollRange()
		return 0
	end
	function self:GetRect()
		return 0, 0, 500, 500
	end
	function self:GetCenter()
		return 400, 300
	end
	function self:GetEffectiveScale()
		return 1
	end
	function self:StartMoving()
	end
	function self:StopMovingOrSizing()
	end
	function self:CreateFontString()
		return makeMock("fontstring")
	end
	function self:CreateTexture()
		return makeMock("texture")
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

GameTooltip = makeMock("GameTooltip")
GameTooltip.lines = {}
function GameTooltip:AddLine(text)
	self.lines[#self.lines + 1] = text
end

C_Timer = {
	After = function(delay, callback)
		MockUI.timers[#MockUI.timers + 1] = callback
	end,
}

-- hooksecurefunc that actually runs the post-call callback (the real client
-- does this internally); the tests then exercise the same code paths.
local unpack = table.unpack or unpack
function hooksecurefunc(name, callback)
	local original = _G[name]
	if type(original) ~= "function" then
		return
	end
	_G[name] = function(...)
		local results = { original(...) }
		callback(...)
		return unpack(results)
	end
end

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
loadmod("Detection.lua")
loadmod("Tooltips.lua")
loadmod("AutoActions.lua")
loadmod("LFGApplicants.lua")
loadmod("UI_MainWindow.lua")

-- Sound.lua is not loaded in this suite; record requests instead.
ns.PlayListSound = function(sound)
	Stubs.playedSounds[#Stubs.playedSounds + 1] = sound
end

local function fresh()
	Stubs.reset()
	ns.ResetAutoActionState()
	ns.ResetLFGApplicantState()
	ns.InitDB()
	ns.PlayListSound = function(sound)
		Stubs.playedSounds[#Stubs.playedSounds + 1] = sound
	end
	return ns.GetDefaultListName()
end

local function addToList(listName, fullName)
	local ld = GroupWatchDB.lists[listName]
	if type(ld) ~= "table" then
		return
	end
	ld.players[fullName] = true
	ns.InvalidateWatchedIndex()
end

local function countPrint(fragment)
	local count = 0
	for _, line in ipairs(Stubs.printLog) do
		if line:find(fragment, 1, true) then
			count = count + 1
		end
	end
	return count
end

local function visibleRows(panel)
	local count = 0
	if type(panel) ~= "table" or type(panel.rows) ~= "table" then
		return 0
	end
	for _, row in ipairs(panel.rows) do
		if row:IsShown() then
			count = count + 1
		end
	end
	return count
end

local function setupLFGFrame()
	local lfg = _G.LFGListFrame
	if type(lfg) ~= "table" then
		lfg = makeMock("frame")
		lfg.ApplicationViewer = makeMock("frame")
		_G.LFGListFrame = lfg
	end
	lfg:Show()
	ns.SetupLFGApplicants()
	return lfg
end

local function setupApplicant(token, member, info)
	Stubs.applicants = { token }
	Stubs.applicantInfo[token] = info or {
		applicantID = token,
		numMembers = 1,
		applicationStatus = "applied",
	}
	Stubs.applicantMembers[token] = { member }
end

-- ---------------------------------------------------------------------------
-- 1. DB migration: autoAccept/autoDecline defaults and type checks
-- ---------------------------------------------------------------------------
do
	fresh()
	local def = ns.GetDefaultListName()
	local ld = GroupWatchDB.lists[def]
	check("DB: default autoAccept false", ld.autoAccept == false)
	check("DB: default autoDecline false", ld.autoDecline == false)

	ld.autoAccept = "yes"
	ld.autoDecline = 1
	ns.InitDB()
	check("DB: non-boolean autoAccept reset", ld.autoAccept == false)
	check("DB: non-boolean autoDecline reset", ld.autoDecline == false)

	GroupWatchDB.lists["Old"] = { players = {}, notes = {} }
	ns.InitDB()
	check("DB: migrated old list gets autoAccept", GroupWatchDB.lists["Old"].autoAccept == false)
	check("DB: migrated old list gets autoDecline", GroupWatchDB.lists["Old"].autoDecline == false)

	GroupWatchDB.lists["Keep"] = {
		players = {},
		notes = {},
		autoAccept = true,
		autoDecline = true,
	}
	ns.InitDB()
	check("DB: true autoAccept preserved", GroupWatchDB.lists["Keep"].autoAccept == true)
	check("DB: true autoDecline preserved", GroupWatchDB.lists["Keep"].autoDecline == true)

	ns.CreateList("Fresh")
	check("DB: CreateList autoAccept false", GroupWatchDB.lists["Fresh"].autoAccept == false)
	check("DB: CreateList autoDecline false", GroupWatchDB.lists["Fresh"].autoDecline == false)

	GroupWatchDB.lists["Broken"] = "junk"
	local ok, err = pcall(ns.InitDB)
	check("DB: corrupt list migration no throw", ok, err)
	check("DB: corrupt list repaired with flags", GroupWatchDB.lists["Broken"].autoAccept == false)
end

-- ---------------------------------------------------------------------------
-- 2. GetAutoAction: decline wins on conflicts, stable list selection
-- ---------------------------------------------------------------------------
do
	fresh()
	local def = ns.GetDefaultListName()
	addToList(def, "Hero-Realm")
	GroupWatchDB.lists[def].autoAccept = true
	ns.InvalidateWatchedIndex()

	local action, listName = ns.GetAutoAction("Hero-Realm")
	check("AutoAction: accept picked", action == "accept", action)
	check("AutoAction: accept list name", listName == def, listName)

	GroupWatchDB.lists["ZDecline"] = {
		players = { ["Hero-Realm"] = true },
		notes = {},
		autoAccept = false,
		autoDecline = true,
	}
	ns.InvalidateWatchedIndex()
	action, listName = ns.GetAutoAction("Hero-Realm")
	check("AutoAction: decline wins", action == "decline", action)
	check("AutoAction: decline list name", listName == "ZDecline", listName)

	GroupWatchDB.lists["AAccept"] = {
		players = { ["Hero-Realm"] = true },
		notes = {},
		autoAccept = true,
		autoDecline = false,
	}
	ns.InvalidateWatchedIndex()
	action, listName = ns.GetAutoAction("Hero-Realm")
	check("AutoAction: decline wins over multiple accepts", action == "decline", action)
	check("AutoAction: decline list remains", listName == "ZDecline", listName)

	GroupWatchDB.lists["ZDecline"].autoDecline = false
	ns.InvalidateWatchedIndex()
	action, listName = ns.GetAutoAction("Hero-Realm")
	check("AutoAction: first sorted accept list", action == "accept" and listName == "AAccept", tostring(listName))

	GroupWatchDB.lists["AAccept"].autoDecline = true
	ns.InvalidateWatchedIndex()
	action, listName = ns.GetAutoAction("Hero-Realm")
	check("AutoAction: same list both flags -> decline", action == "decline", action)
	check("AutoAction: same list both flags list", listName == "AAccept", listName)

	check("AutoAction: unknown player nil", ns.GetAutoAction("Nobody-Realm") == nil)
	check("AutoAction: nil name nil", ns.GetAutoAction(nil) == nil)
	check("AutoAction: number name nil", ns.GetAutoAction(42) == nil)

	GroupWatchDB.lists = "junk"
	local ok, err = pcall(ns.GetAutoAction, "Hero-Realm")
	check("AutoAction: corrupt DB no throw", ok, err)
	check("AutoAction: corrupt DB nil", ok and err == nil)
end

-- ---------------------------------------------------------------------------
-- 3. Direct party invite: accept / decline / ignore / secrets / dedupe
-- ---------------------------------------------------------------------------
do
	fresh()
	local def = ns.GetDefaultListName()
	addToList(def, "Hero-Realm")
	GroupWatchDB.lists[def].autoAccept = true
	GroupWatchDB.lists[def].sound = 8959

	Stubs.guidInfo["Player-1-00000001"] = { name = "Hero", realm = "Realm" }
	Stubs.guidInfo["Player-1-00000005"] = { name = "Hero", realm = "Realm" }
	local result = ns.HandlePartyInviteRequest(
		"Hero-Realm",
		false,
		false,
		false,
		true,
		false,
		"Player-1-00000001"
	)
	check("Invite: accept action", result == "accept", result)
	check("Invite: AcceptGroup called once", Stubs.accepted == 1, Stubs.accepted)
	check("Invite: decline not called", Stubs.declined == 0, Stubs.declined)
	-- Hiding PARTY_INVITE right after AcceptGroup would make StaticPopup's
	-- OnHide call DeclineGroup and cancel the accept.
	check("Invite: accept leaves popup visible", #Stubs.popupHidden == 0, #Stubs.popupHidden)
	local autoFrame = ns.autoActionsFrame
	local eventOk = pcall(autoFrame.scripts.OnEvent, autoFrame, "PARTY_MEMBERS_CHANGED")
	check("Invite: roster update no throw", eventOk)
	check(
		"Invite: roster update hides popup",
		#Stubs.popupHidden == 1 and Stubs.popupHidden[1] == "PARTY_INVITE",
		#Stubs.popupHidden
	)
	check("Invite: list sound played", #Stubs.playedSounds == 1 and Stubs.playedSounds[1] == 8959)
	check("Invite: accepted message", countPrint("Auto-accepted") == 1, #Stubs.printLog)

	-- Same GUID within the dedupe window is ignored.
	Stubs.time = 0.5
	ns.HandlePartyInviteRequest("Hero-Realm", false, false, false, true, false, "Player-1-00000001")
	check("Invite: duplicate GUID deduped", Stubs.accepted == 1, Stubs.accepted)
	Stubs.time = 10
	ns.HandlePartyInviteRequest("Hero-Realm", false, false, false, true, false, "Player-1-00000002")
	check("Invite: another GUID accepted", Stubs.accepted == 2, Stubs.accepted)

	GroupWatchDB.lists["Bad"] = {
		players = { ["Villain-Realm"] = true },
		notes = {},
		autoAccept = false,
		autoDecline = true,
		sound = 0,
	}
	GroupWatchDB.lists["Bad"].sound = 0
	ns.InvalidateWatchedIndex()
	local hiddenBeforeDecline = #Stubs.popupHidden
	result = ns.HandlePartyInviteRequest("Villain-Realm", false, false, false, true, false, "Player-1-00000003")
	check("Invite: decline action", result == "decline", result)
	check("Invite: DeclineGroup called once", Stubs.declined == 1, Stubs.declined)
	check(
		"Invite: decline hides popup immediately",
		#Stubs.popupHidden == hiddenBeforeDecline + 1
			and Stubs.popupHidden[#Stubs.popupHidden] == "PARTY_INVITE",
		#Stubs.popupHidden
	)
	check("Invite: declined message", countPrint("Auto-declined") == 1)

	Stubs.accepted, Stubs.declined = 0, 0
	result = ns.HandlePartyInviteRequest("Stranger-Realm", false, false, false, true, false, "Player-1-00000004")
	check("Invite: unwatched ignored", result == false, result)
	check("Invite: unwatched no accept", Stubs.accepted == 0, Stubs.accepted)
	check("Invite: unwatched no decline", Stubs.declined == 0, Stubs.declined)

	-- Secret name: no action, no throw. A plain GUID can still resolve it.
	Stubs.secretValues["Hero-Realm"] = true
	local ok, secretResult = pcall(
		ns.HandlePartyInviteRequest,
		"Hero-Realm",
		false,
		false,
		false,
		true,
		false,
		nil
	)
	check("Invite: secret name no throw", ok, secretResult)
	check("Invite: secret name no action", secretResult == false, secretResult)
	check("Invite: secret name did not call AcceptGroup", Stubs.accepted == 0, Stubs.accepted)

	Stubs.time = 20
	result = ns.HandlePartyInviteRequest(
		"Hero-Realm",
		false,
		false,
		false,
		true,
		false,
		"Player-1-00000005"
	)
	check("Invite: secret name + plain GUID fallback", result == "accept", result)
	check("Invite: fallback accepted", Stubs.accepted == 1, Stubs.accepted)

	Stubs.secretValues["Hero-Realm"] = nil
	Stubs.secretValues["Player-1-00000006"] = true
	Stubs.time = 30
	result = ns.HandlePartyInviteRequest(
		"Hero-Realm",
		false,
		false,
		false,
		true,
		false,
		"Player-1-00000006"
	)
	check("Invite: secret GUID still uses plain name", result == "accept", result)

	ok = pcall(ns.HandlePartyInviteRequest, nil, nil, nil, nil, nil, nil, nil)
	check("Invite: nil args no throw", ok)

	-- Missing client API: restricted notification, no retry loop.
	local savedAccept = ns.Globals.AcceptGroup
	local savedAcceptGlobal = _G.AcceptGroup
	ns.Globals.AcceptGroup = nil
	_G.AcceptGroup = nil
	Stubs.accepted = 0
	Stubs.time = 40
	local restrictedResult = ns.HandlePartyInviteRequest(
		"Hero-Realm",
		false,
		false,
		false,
		true,
		false,
		"Player-1-00000007"
	)
	check("Invite: missing API no action", restrictedResult == false, restrictedResult)
	check("Invite: missing API restricted message", countPrint("restricted") >= 1)
	ns.Globals.AcceptGroup = savedAccept
	_G.AcceptGroup = savedAcceptGlobal

	-- The event handler wraps the same logic and must also survive secrets.
	Stubs.secretValues["SecretGuy-Realm"] = true
	local frame = ns.autoActionsFrame
	ok = pcall(
		frame.scripts.OnEvent,
		frame,
		"PARTY_INVITE_REQUEST",
		"SecretGuy-Realm",
		false,
		false,
		false,
		true,
		false,
		nil
	)
	check("Invite: event handler secret name no throw", ok)
end

-- ---------------------------------------------------------------------------
-- 4. Blocked/forbidden invites disable auto invites for the session
-- ---------------------------------------------------------------------------
do
	fresh()
	local def = ns.GetDefaultListName()
	addToList(def, "Hero-Realm")
	GroupWatchDB.lists[def].autoAccept = true

	check("Blocked: other addon ignored", ns.HandleAddonActionBlocked("OtherAddon", "AcceptGroup") == false)
	check("Blocked: other function ignored", ns.HandleAddonActionBlocked("GroupWatch", "StaticPopup_Hide") == false)
	check("Blocked: still enabled", ns.autoInvitesDisabled == false)

	local handled = ns.HandleAddonActionBlocked("GroupWatch", "AcceptGroup")
	check("Blocked: own AcceptGroup handled", handled == true)
	check("Blocked: session disabled", ns.autoInvitesDisabled == true)
	check("Blocked: warning printed", countPrint("blocked") == 1 or countPrint("disabled") == 1)

	Stubs.accepted = 0
	local result = ns.HandlePartyInviteRequest("Hero-Realm", false, false, false, true, false, "Player-1-00000010")
	check("Blocked: invite yields no action", result == false, result)
	check("Blocked: never retried", Stubs.accepted == 0, Stubs.accepted)

	ns.ResetAutoActionState()
	ns.HandleAddonActionBlocked("GroupWatch", "DeclineGroup")
	check("Blocked: forbidden decline disables", ns.autoInvitesDisabled == true)
end

-- ---------------------------------------------------------------------------
-- 5. LFG role capacity: 5-man 1/1/3 versus raid total slots
-- ---------------------------------------------------------------------------
do
	fresh()
	Stubs.activeEntry = { activityIDs = { 123 } }
	Stubs.activityInfo[123] = { maxNumPlayers = 5 }
	Stubs.numMembers = 1
	Stubs.inRaid = false
	Stubs.unitRoles.player = "TANK"
	Stubs.numInvited = 0

	local capacity = ns.GetActiveEntryCapacity()
	check("Role: 5-man capacity present", type(capacity) == "table", type(capacity))
	check("Role: 5-man detected", capacity and capacity.isFiveMan == true)
	check("Role: current group counted", capacity and capacity.current == 1, capacity and capacity.current)
	check("Role: remaining slots", capacity and capacity.remaining == 4, capacity and capacity.remaining)
	check("Role: tank slot filled", capacity and capacity.roleRemaining.tank == 0)
	check("Role: healer slot free", capacity and capacity.roleRemaining.healer == 1)
	check("Role: dps slots free", capacity and capacity.roleRemaining.damage == 3)
	check("Role: role data available", capacity and capacity.roleDataAvailable == true)

	local tankMember = { tank = true, healer = false, damage = false, assignedRole = "TANK" }
	local dpsMember = { tank = false, healer = false, damage = true, assignedRole = "DAMAGER" }
	local multiMember = { tank = true, healer = false, damage = true, assignedRole = nil }
	check("Role: tank does not fit", ns.EvaluateRoleFit({ tankMember }, capacity) == "no_role")
	check("Role: dps fits", ns.EvaluateRoleFit({ dpsMember }, capacity) == "fit")
	check("Role: multi-role uses an available role", ns.EvaluateRoleFit({ multiMember }, capacity) == "fit")

	Stubs.numMembers = 2
	Stubs.unitRoles.party1 = "HEALER"
	capacity = ns.GetActiveEntryCapacity()
	check("Role: healer slot filled", capacity and capacity.roleRemaining.healer == 0)
	check("Role: healer does not fit", ns.EvaluateRoleFit({ { healer = true } }, capacity) == "no_role")
	check("Role: dps still fits", ns.EvaluateRoleFit({ dpsMember }, capacity) == "fit")

	-- Unknown role data must never produce a false "does not fit".
	Stubs.unitRoles.player = "NONE"
	capacity = ns.GetActiveEntryCapacity()
	check("Role: unknown role data", capacity and capacity.roleDataAvailable == false)
	check("Role: unknown role -> unavailable", ns.EvaluateRoleFit({ dpsMember }, capacity) == "unavailable")

	-- Raids: total slots only, role flags irrelevant.
	Stubs.inRaid = true
	Stubs.numMembers = 5
	Stubs.numInvited = 1
	Stubs.activityInfo[124] = { maxNumPlayers = 20 }
	Stubs.activeEntry = { activityIDs = { 124 } }
	capacity = ns.GetActiveEntryCapacity()
	check("Role: raid not 5-man", capacity and capacity.isFiveMan == false)
	check("Role: raid subtracts current + invited", capacity and capacity.remaining == 14, capacity and capacity.remaining)
	check("Role: raid total fit only", ns.EvaluateRoleFit({ dpsMember, tankMember }, capacity) == "fit")
	check("Role: raid full", ns.EvaluateRoleFit({ dpsMember }, { remaining = 0, isFiveMan = false }) == "full")

	-- Secret role values are unavailable, not errors.
	Stubs.inRaid = false
	Stubs.numMembers = 1
	Stubs.unitRoles.player = "SECRETROLE"
	Stubs.secretValues["SECRETROLE"] = true
	local ok, counts = pcall(ns.GetGroupRoleCounts)
	check("Role: secret role no throw", ok, counts)
	check("Role: secret role unavailable", counts == nil, counts)
end

-- ---------------------------------------------------------------------------
-- 5b. Invited roles and backtracking role assignment
-- ---------------------------------------------------------------------------
do
	fresh()
	Stubs.activeEntry = { activityIDs = { 123 } }
	Stubs.activityInfo[123] = { maxNumPlayers = 5 }
	Stubs.numMembers = 1
	Stubs.inRaid = false
	Stubs.unitRoles.player = "TANK"
	Stubs.numInvited = 1

	local capacity = ns.GetActiveEntryCapacity(1, { tank = 0, healer = 1, damage = 0 }, 1)
	check("Role invited: capacity present", type(capacity) == "table")
	check("Role invited: total slots subtract invited", capacity and capacity.remaining == 3)
	check("Role invited: healer slot taken by invited", capacity and capacity.roleRemaining.healer == 0)
	check("Role invited: damage slots remain", capacity and capacity.roleRemaining.damage == 3)
	check("Role invited: role data available", capacity and capacity.roleDataAvailable == true)
	check(
		"Role invited: healer no longer fits",
		ns.EvaluateRoleFit({ { healer = true } }, capacity) == "no_role"
	)

	local restricted = ns.GetActiveEntryCapacity(1, false, 0)
	check("Role invited: restricted roles unavailable", restricted and restricted.roleDataAvailable == false)
	check(
		"Role invited: restricted never claims a fit",
		ns.EvaluateRoleFit({ { healer = true } }, restricted) == "unavailable"
	)

	local incomplete = ns.GetActiveEntryCapacity(1, { tank = 0, healer = 0, damage = 0 }, 0)
	check("Role invited: incomplete role read unavailable", incomplete and incomplete.roleDataAvailable == false)

	-- Greedy T/H/D assignment fails here: A healer/damage, B tank/healer,
	-- C tank/healer with T1/H1/D1 still fits (A damage, B tank, C healer).
	local backtrackCapacity = {
		remaining = 3,
		isFiveMan = true,
		roleDataAvailable = true,
		roleRemaining = { tank = 1, healer = 1, damage = 1 },
	}
	local memberA = { tank = false, healer = true, damage = true }
	local memberB = { tank = true, healer = true, damage = false }
	local memberC = { tank = true, healer = true, damage = false }
	check(
		"Role: backtracking fits greedy counterexample",
		ns.EvaluateRoleFit({ memberA, memberB, memberC }, backtrackCapacity) == "fit"
	)
	check(
		"Role: backtracking rejects impossible group",
		ns.EvaluateRoleFit(
			{ memberB, memberC, { tank = true, healer = false, damage = false } },
			backtrackCapacity
		) == "no_role"
	)

	-- The scan must subtract an invited applicant's role from the applied
	-- applicant's fit check.
	fresh()
	setupLFGFrame()
	local def = ns.GetDefaultListName()
	addToList(def, "Applied-Realm")
	Stubs.activeEntry = { activityIDs = { 123 } }
	Stubs.activityInfo[123] = { maxNumPlayers = 5 }
	Stubs.numMembers = 1
	Stubs.inRaid = false
	Stubs.unitRoles.player = "TANK"
	Stubs.numInvited = 1
	Stubs.applicants = { 201, 202 }
	Stubs.applicantInfo[201] = {
		applicantID = 201,
		numMembers = 1,
		applicationStatus = "invited",
	}
	Stubs.applicantMembers[201] = {
		{ name = "Invited-Realm", tank = false, healer = true, damage = false, assignedRole = "HEALER" },
	}
	Stubs.applicantInfo[202] = {
		applicantID = 202,
		numMembers = 1,
		applicationStatus = "applied",
	}
	Stubs.applicantMembers[202] = {
		{ name = "Applied-Realm", tank = false, healer = true, damage = false, assignedRole = "HEALER" },
	}
	local scanOk = ns.ScanLFGApplicants()
	check("Role invited: scan no throw", scanOk == true)
	local row = ns.lfgApplicantsPanel.rows[1]
	check("Role invited: applied row present", visibleRows(ns.lfgApplicantsPanel) == 1)
	check(
		"Role invited: applied healer shows no free role",
		row ~= nil and row.infoText.text:find("No free role", 1, true) ~= nil,
		row and row.infoText.text
	)

	-- Restricted invited member roles make the whole role fit unavailable.
	fresh()
	setupLFGFrame()
	addToList(ns.GetDefaultListName(), "Applied-Realm")
	Stubs.activeEntry = { activityIDs = { 123 } }
	Stubs.activityInfo[123] = { maxNumPlayers = 5 }
	Stubs.numMembers = 1
	Stubs.inRaid = false
	Stubs.unitRoles.player = "TANK"
	Stubs.numInvited = 1
	Stubs.secretValues["Hidden-Realm"] = true
	Stubs.applicants = { 301, 302 }
	Stubs.applicantInfo[301] = {
		applicantID = 301,
		numMembers = 1,
		applicationStatus = "invited",
	}
	Stubs.applicantMembers[301] = {
		{ name = "Hidden-Realm", tank = false, healer = true, damage = false, assignedRole = "HEALER" },
	}
	Stubs.applicantInfo[302] = {
		applicantID = 302,
		numMembers = 1,
		applicationStatus = "applied",
	}
	Stubs.applicantMembers[302] = {
		{ name = "Applied-Realm", tank = false, healer = false, damage = true, assignedRole = "DAMAGER" },
	}
	scanOk = ns.ScanLFGApplicants()
	check("Role invited restricted: scan no throw", scanOk == true)
	row = ns.lfgApplicantsPanel.rows[1]
	check("Role invited restricted: applied row present", visibleRows(ns.lfgApplicantsPanel) == 1)
	check(
		"Role invited restricted: fit shown unavailable",
		row ~= nil and row.infoText.text:find("Role fit unavailable", 1, true) ~= nil,
		row and row.infoText.text
	)
	check(
		"Role invited restricted: never claims a fit",
		row ~= nil and row.infoText.text:find("Role fits", 1, true) == nil
	)
end

-- ---------------------------------------------------------------------------
-- 6. LFG scan + manual-only panel
-- ---------------------------------------------------------------------------
do
	fresh()
	setupLFGFrame()
	local def = ns.GetDefaultListName()
	addToList(def, "Hero-Realm")
	GroupWatchDB.lists[def].sound = 8959
	GroupWatchDB.lists[def].autoAccept = true

	Stubs.activeEntry = { activityIDs = { 123 } }
	Stubs.activityInfo[123] = { maxNumPlayers = 5 }
	Stubs.numMembers = 1
	Stubs.inRaid = false
	Stubs.unitRoles.player = "TANK"
	Stubs.numInvited = 0
	setupApplicant(101, {
		name = "Hero-Realm",
		tank = false,
		healer = false,
		damage = true,
		assignedRole = "DAMAGER",
	})

	local ok = ns.ScanLFGApplicants()
	check("LFG: scan no throw", ok == true)
	check("LFG: applicants read", Stubs.getApplicantsCalls == 1, Stubs.getApplicantsCalls)
	check("LFG: no automatic invite", #Stubs.lfgInviteCalls == 0, #Stubs.lfgInviteCalls)
	check("LFG: no automatic decline", #Stubs.lfgDeclineCalls == 0, #Stubs.lfgDeclineCalls)
	check("LFG: match printed", countPrint("Hero-Realm") >= 1)
	check("LFG: list sound played", #Stubs.playedSounds == 1, #Stubs.playedSounds)
	check("LFG: panel row visible", visibleRows(ns.lfgApplicantsPanel) == 1, visibleRows(ns.lfgApplicantsPanel))
	check("LFG: panel row token", ns.lfgApplicantsPanel.rows[1].data.token == 101)
	check("LFG: role fit text", ns.lfgApplicantsPanel.rows[1].infoText.text:find("Role fits", 1, true) ~= nil)

	-- A repeat scan does not re-notify.
	Stubs.getApplicantsCalls = 0
	ns.ScanLFGApplicants()
	check("LFG: repeat scan no duplicate sound", #Stubs.playedSounds == 1, #Stubs.playedSounds)
	check("LFG: repeat scan no duplicate print", countPrint("Hero-Realm") == 1)
	check("LFG: panel still one row", visibleRows(ns.lfgApplicantsPanel) == 1)

	-- Manual OnClick actions only.
	local row = ns.lfgApplicantsPanel.rows[1]
	local inviteScript = row.invite:GetScript("OnClick")
	local declineScript = row.decline:GetScript("OnClick")
	check("LFG: invite button wired", type(inviteScript) == "function")
	check("LFG: decline button wired", type(declineScript) == "function")
	inviteScript()
	check("LFG: manual invite called", #Stubs.lfgInviteCalls == 1 and Stubs.lfgInviteCalls[1] == 101)
	declineScript()
	check("LFG: manual decline called", #Stubs.lfgDeclineCalls == 1 and Stubs.lfgDeclineCalls[1] == 101)
	check("LFG: manual actions scheduled a refresh", #MockUI.timers >= 1)

	-- Running the coalescing timers must only scan/read, never decide.
	local invitesBefore = #Stubs.lfgInviteCalls
	local declinesBefore = #Stubs.lfgDeclineCalls
	for _, callback in ipairs(MockUI.timers) do
		pcall(callback)
	end
	MockUI.timers = {}
	check("LFG: timer callbacks do not invite", #Stubs.lfgInviteCalls == invitesBefore)
	check("LFG: timer callbacks do not decline", #Stubs.lfgDeclineCalls == declinesBefore)

	-- Removing an applicant forgets the notification; readding notifies again.
	Stubs.applicants = {}
	ns.ScanLFGApplicants()
	check("LFG: no matches row", visibleRows(ns.lfgApplicantsPanel) == 0, visibleRows(ns.lfgApplicantsPanel))
	setupApplicant(101, {
		name = "Hero-Realm",
		tank = false,
		healer = false,
		damage = true,
		assignedRole = "DAMAGER",
	})
	ns.ScanLFGApplicants()
	check("LFG: reapplication notifies again", #Stubs.playedSounds == 2, #Stubs.playedSounds)
end

-- ---------------------------------------------------------------------------
-- 7. LFG secret tokens / tables / lockdown
-- ---------------------------------------------------------------------------
do
	fresh()
	setupLFGFrame()
	local def = ns.GetDefaultListName()
	addToList(def, "Hero-Realm")
	GroupWatchDB.lists[def].sound = 8959

	Stubs.activeEntry = { activityIDs = { 123 } }
	Stubs.activityInfo[123] = { maxNumPlayers = 5 }
	Stubs.numMembers = 1
	Stubs.unitRoles.player = "TANK"
	Stubs.numInvited = 0

	local secretToken = {}
	Stubs.secretValues[secretToken] = true
	Stubs.applicants = { secretToken, "opaque", 102 }
	Stubs.applicantInfo[102] = {
		applicantID = 102,
		numMembers = 1,
		applicationStatus = "applied",
	}
	Stubs.applicantMembers[102] = {
		{ name = "Hero-Realm", tank = false, healer = false, damage = true, assignedRole = "DAMAGER" },
	}

	local ok = ns.ScanLFGApplicants()
	check("LFG secret: scan no throw", ok == true)
	check("LFG secret: secret token skipped, plain token processed", visibleRows(ns.lfgApplicantsPanel) == 1)
	check("LFG secret: restricted warning printed", countPrint("restricted") >= 1)
	check("LFG secret: no automatic invite", #Stubs.lfgInviteCalls == 0)

	-- Secret applicant info table: skip its contents.
	fresh()
	setupLFGFrame()
	addToList(ns.GetDefaultListName(), "Hero-Realm")
	Stubs.activeEntry = { activityIDs = { 123 } }
	Stubs.activityInfo[123] = { maxNumPlayers = 5 }
	Stubs.numMembers = 1
	Stubs.unitRoles.player = "TANK"
	local secretInfo = { applicantID = 103, numMembers = 1, applicationStatus = "applied" }
	Stubs.noAccessTables[secretInfo] = true
	Stubs.applicants = { 103 }
	Stubs.applicantInfo[103] = secretInfo
	Stubs.applicantMembers[103] = {
		{ name = "Hero-Realm", tank = false, healer = false, damage = true, assignedRole = "DAMAGER" },
	}
	ok = ns.ScanLFGApplicants()
	check("LFG secret: opaque info no throw", ok == true)
	check("LFG secret: opaque info no row", visibleRows(ns.lfgApplicantsPanel) == 0)

	-- Secret member name/role: mark restricted, do not match.
	fresh()
	setupLFGFrame()
	addToList(ns.GetDefaultListName(), "Hero-Realm")
	Stubs.activeEntry = { activityIDs = { 123 } }
	Stubs.activityInfo[123] = { maxNumPlayers = 5 }
	Stubs.numMembers = 1
	Stubs.unitRoles.player = "TANK"
	Stubs.applicants = { 104 }
	Stubs.applicantInfo[104] = { applicantID = 104, numMembers = 1, applicationStatus = "applied" }
	Stubs.secretValues["Hidden-Realm"] = true
	Stubs.applicantMembers[104] = {
		{ name = "Hidden-Realm", tank = false, healer = false, damage = true, assignedRole = "DAMAGER" },
	}
	ok = ns.ScanLFGApplicants()
	check("LFG secret: secret member no throw", ok == true)
	check("LFG secret: secret member no row", visibleRows(ns.lfgApplicantsPanel) == 0)
	check("LFG secret: secret member restricted warning", countPrint("restricted") >= 1)

	-- Chat-messaging lockdown: skip all reads and print the generic message.
	fresh()
	setupLFGFrame()
	addToList(ns.GetDefaultListName(), "Hero-Realm")
	Stubs.lockdown = true
	Stubs.getApplicantsCalls = 0
	Stubs.applicants = { 101 }
	ok = ns.ScanLFGApplicants()
	check("LFG lockdown: no throw", ok == true)
	check("LFG lockdown: no applicant reads", Stubs.getApplicantsCalls == 0, Stubs.getApplicantsCalls)
	check("LFG lockdown: restricted message", countPrint("restricted") >= 1)
	Stubs.lockdown = false

	-- The newer restriction-state API has the same effect.
	_G.Enum = {
		AddOnRestrictionType = { Chat = 5 },
		AddOnRestrictionState = { Active = 2 },
	}
	Stubs.restrictionState = 2
	Stubs.getApplicantsCalls = 0
	ok = ns.ScanLFGApplicants()
	check("LFG restriction state: no throw", ok == true)
	check("LFG restriction state: no applicant reads", Stubs.getApplicantsCalls == 0, Stubs.getApplicantsCalls)
	Stubs.restrictionState = 0
	_G.Enum = nil

	-- No active listing: hide the panel.
	Stubs.activeEntry = nil
	ns.ScanLFGApplicants()
	check("LFG: no listing hides panel", ns.lfgApplicantsPanel:IsShown() == false)
end

-- ---------------------------------------------------------------------------
-- 8. Blizzard applicant row decoration + tooltip
-- ---------------------------------------------------------------------------
do
	fresh()
	setupLFGFrame()
	local def = ns.GetDefaultListName()
	addToList(def, "Hero-Realm")
	GroupWatchDB.lists[def].notes["Hero-Realm"] = "spy"

	_G.LFGListApplicationViewer_UpdateApplicant = function(button)
		button.updated = true
	end
	_G.LFGListApplicationViewer_UpdateApplicantMember = function(member, appID, memberIdx)
		member.memberIdx = memberIdx
	end
	_G.LFGListApplicantMember_OnEnter = function()
	end
	ns.SetupLFGApplicants()

	Stubs.activeEntry = { activityIDs = { 123 } }
	Stubs.activityInfo[123] = { maxNumPlayers = 5 }
	Stubs.numMembers = 1
	Stubs.unitRoles.player = "TANK"
	Stubs.applicantInfo[105] = { applicantID = 105, numMembers = 1, applicationStatus = "applied" }
	Stubs.applicantMembers[105] = {
		{ name = "Hero-Realm", tank = false, healer = false, damage = true, assignedRole = "DAMAGER" },
	}

	local member = makeMock("button")
	member.RoleIcon3 = makeMock("button")
	member.Name = makeMock("fontstring")
	local appRow = makeMock("button")
	appRow.applicantID = 105
	member.parent = appRow
	member.Members = { member }

	_G.LFGListApplicationViewer_UpdateApplicantMember(member, 105, 1)
	check("Rows: GW tag created", type(member.GWTag) == "table")
	check("Rows: watched tag shown", member.GWTag:IsShown() == true)

	GameTooltip.lines = {}
	_G.LFGListApplicantMember_OnEnter(member)
	check("Rows: tooltip note appended", #GameTooltip.lines >= 1)
	local foundNote = false
	for _, line in ipairs(GameTooltip.lines) do
		if line:find("spy", 1, true) then
			foundNote = true
		end
	end
	check("Rows: tooltip contains note", foundNote)
end

-- ---------------------------------------------------------------------------
-- 9. Tooltip LFG secret hardening
-- ---------------------------------------------------------------------------
do
	fresh()
	local def = ns.GetDefaultListName()
	addToList(def, "Hero-Realm")
	GroupWatchDB.lists[def].notes["Hero-Realm"] = "spy"

	local function makeTooltip()
		return {
			lines = {},
			AddLine = function(self, text)
				self.lines[#self.lines + 1] = text
			end,
		}
	end

	Stubs.lfg[55] = { leaderName = "Hero-Realm" }
	local tip = makeTooltip()
	local ok = pcall(ns.AppendLFGSearchResultTooltip, tip, 55)
	check("Tooltip LFG: normal no throw", ok)
	check("Tooltip LFG: note shown", #tip.lines > 0 and tip.lines[#tip.lines]:find("spy", 1, true) ~= nil)

	Stubs.secretValues["Secret-Realm"] = true
	Stubs.lfg[56] = { leaderName = "Secret-Realm" }
	tip = makeTooltip()
	ok = pcall(ns.AppendLFGSearchResultTooltip, tip, 56)
	check("Tooltip LFG: secret leader no throw", ok)
	check("Tooltip LFG: restricted line", #tip.lines == 1 and tip.lines[1]:find("restricted", 1, true) ~= nil)

	Stubs.lfg[57] = { leaderName = "Hero-Realm" }
	Stubs.noAccessTables[Stubs.lfg[57]] = true
	tip = makeTooltip()
	ok = pcall(ns.AppendLFGSearchResultTooltip, tip, 57)
	check("Tooltip LFG: opaque table no throw", ok)
	check("Tooltip LFG: opaque table restricted line", #tip.lines == 1 and tip.lines[1]:find("restricted", 1, true) ~= nil)

	Stubs.secretValues[58] = true
	tip = makeTooltip()
	ok = pcall(ns.AppendLFGSearchResultTooltip, tip, 58)
	check("Tooltip LFG: secret result ID no throw", ok)
	check("Tooltip LFG: secret result ID restricted", #tip.lines == 1 and tip.lines[1]:find("restricted", 1, true) ~= nil)

	Stubs.lfg[59] = { err = "boom" }
	tip = makeTooltip()
	ok = pcall(ns.AppendLFGSearchResultTooltip, tip, 59)
	check("Tooltip LFG: throwing API no throw", ok)
	check("Tooltip LFG: throwing API restricted", #tip.lines == 1 and tip.lines[1]:find("restricted", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
-- 10. Event subscriptions / TOC / no banned automation
-- ---------------------------------------------------------------------------
do
	local lfgSource = readFile(ADDON_DIR .. "LFGApplicants.lua")
	check(
		"LFG: no application-status event subscription",
		lfgSource:find("LFG_LIST_APPLICATION_STATUS_UPDATED", 1, true) == nil
	)

	local registered = false
	local events = ns.lfgApplicantsFrame.events
	for _, event in ipairs(events) do
		if event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
			registered = true
		end
	end
	check("LFG: event frame does not register status event", registered == false)

	local autoEvents = ns.autoActionsFrame.events
	local hasInvite, hasBlocked, hasForbidden = false, false, false
	for _, event in ipairs(autoEvents) do
		if event == "PARTY_INVITE_REQUEST" then
			hasInvite = true
		elseif event == "ADDON_ACTION_BLOCKED" then
			hasBlocked = true
		elseif event == "ADDON_ACTION_FORBIDDEN" then
			hasForbidden = true
		end
	end
	check("AutoActions: PARTY_INVITE_REQUEST registered", hasInvite)
	check("AutoActions: ADDON_ACTION_BLOCKED registered", hasBlocked)
	check("AutoActions: ADDON_ACTION_FORBIDDEN registered", hasForbidden)

	local toc = readFile(ADDON_DIR .. "GroupWatch.toc")
	local detectionAt = toc:find("Detection.lua", 1, true)
	local autoAt = toc:find("AutoActions.lua", 1, true)
	local lfgAt = toc:find("LFGApplicants.lua", 1, true)
	local initAt = toc:find("Init.lua", 1, true)
	check(
		"TOC: load order Detection < AutoActions < LFGApplicants < Init",
		detectionAt and autoAt and lfgAt and initAt and detectionAt < autoAt and autoAt < lfgAt and lfgAt < initAt
	)

	local autoSource = readFile(ADDON_DIR .. "AutoActions.lua")
	local lfgSourceAgain = readFile(ADDON_DIR .. "LFGApplicants.lua")
	local forbidden = {
		"UIDropDownMenu",
		"SendChatMessage",
		"UnitGUID",
		"CHAT_MSG",
		"COMBAT_LOG",
		"OnUpdate",
	}
	for _, name in ipairs(forbidden) do
		check(
			"AutoActions: no " .. name,
			autoSource:find(name, 1, true) == nil
		)
		check(
			"LFGApplicants: no " .. name,
			lfgSourceAgain:find(name, 1, true) == nil
		)
	end

	-- LFG decision calls exist exactly once each, inside the manual action
	-- helper that is only wired to the two OnClick scripts.
	local inviteCalls = 0
	local declineCalls = 0
	for _ in lfgSourceAgain:gmatch("pcall%(C_LFGList%.InviteApplicant") do
		inviteCalls = inviteCalls + 1
	end
	for _ in lfgSourceAgain:gmatch("pcall%(C_LFGList%.DeclineApplicant") do
		declineCalls = declineCalls + 1
	end
	check("LFG: exactly one InviteApplicant reference", inviteCalls == 1, inviteCalls)
	check("LFG: exactly one DeclineApplicant reference", declineCalls == 1, declineCalls)
	check("LFG: manual action helper is OnClick-only", lfgSourceAgain:find('SetScript("OnClick"', 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
-- 11. Auto-action context-menu checkbox getter
-- ---------------------------------------------------------------------------
do
	fresh()
	local def = ns.GetDefaultListName()
	local captured = nil
	local menu = {
		CreateCheckbox = function(self, label, isSelected, onClick)
			captured = { label = label, isSelected = isSelected, onClick = onClick }
			return true
		end,
	}
	local refreshes = 0
	local ok, err = pcall(ns._BuildAutoToggle, menu, def, "AUTO_ACCEPT", "autoAccept", function()
		refreshes = refreshes + 1
	end)
	check("Menu checkbox: builder no throw", ok, err)
	check("Menu checkbox: created", type(captured) == "table")
	check("Menu checkbox: isSelected is a function", type(captured.isSelected) == "function")
	check("Menu checkbox: initial value false", captured.isSelected() == false)
	check("Menu checkbox: initial DB false", GroupWatchDB.lists[def].autoAccept == false)

	GroupWatchDB.lists[def].autoAccept = true
	check("Menu checkbox: getter reads live DB value", captured.isSelected() == true)

	captured.onClick()
	check("Menu checkbox: click toggles DB", GroupWatchDB.lists[def].autoAccept == false)
	check("Menu checkbox: getter reflects toggle", captured.isSelected() == false)
	check("Menu checkbox: toggle refreshed window", refreshes == 1, refreshes)

	-- A legacy CreateCheckbox that throws falls back to a text label, and that
	-- label must also read the current value through the same getter.
	local fallbackLabel = nil
	local fallbackClick = nil
	local fallbackMenu = {
		CreateCheckbox = function()
			error("legacy menu")
		end,
		CreateButton = function(self, label, onClick)
			fallbackLabel = label
			fallbackClick = onClick
			return {}
		end,
	}
	GroupWatchDB.lists[def].autoAccept = true
	ok, err = pcall(ns._BuildAutoToggle, fallbackMenu, def, "AUTO_ACCEPT", "autoAccept", function()
		refreshes = refreshes + 1
	end)
	check("Menu checkbox fallback: builder no throw", ok, err)
	check(
		"Menu checkbox fallback: checked label from getter",
		fallbackLabel == "[x] " .. (ns.L["AUTO_ACCEPT"] or "Auto Accept"),
		fallbackLabel
	)
	fallbackClick()
	check("Menu checkbox fallback: click toggles DB", GroupWatchDB.lists[def].autoAccept == false)
	check("Menu checkbox fallback: toggle refreshed window", refreshes == 2, refreshes)
end

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------
say(string.format("----\n%d passed, %d failed", passed, failed))
if failed > 0 then
	os.exit(1)
end
