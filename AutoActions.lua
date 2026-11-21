--[[
	GroupWatch — AutoActions
	========================
	Automatic handling of *direct* party invites based on the per-list
	autoAccept/autoDecline flags. LFG applicants are deliberately not handled
	here: the client only allows manual applicant decisions.

	Safety rules:
	  - Event arguments may be secret values in 12.0+; every name/GUID is
	    checked with ns.IsPlainValue before it is read or passed to another API.
	  - AcceptGroup/DeclineGroup are protected. If the client reports either as
	    blocked or forbidden, auto invites are disabled for the rest of the
	    session and never retried.
	  - Nothing in this module throws out of an event handler.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local CreateFrame = G.CreateFrame
local string_format = G.string_format
local string_find = G.string_find
local pcall, type, tostring = G.pcall, G.type, G.tostring
local print = G.print

-- How long the same inviter GUID/name is ignored after we handled an invite.
-- PARTY_INVITE_REQUEST can fire more than once for the same offer.
local DEDUPE_SECONDS = 2

local autoInvitesDisabled = false
ns.autoInvitesDisabled = false
local blockedWarned = false
local pendingPopupHide = false
local lastInvite = nil

local function Now()
	local getTime = G.GetTime
	if type(getTime) ~= "function" and type(_G) == "table" then
		getTime = rawget(_G, "GetTime")
	end
	if type(getTime) ~= "function" then
		return nil
	end
	local ok, value = pcall(getTime)
	if ok and type(value) == "number" then
		return value
	end
	return nil
end

--- Resolve a client global at call time, so a test/restricted context that
--- installs AcceptGroup/DeclineGroup after load is still supported.
local function ClientGlobal(name)
	local value = G[name]
	if value == nil and type(_G) == "table" then
		value = rawget(_G, name)
	end
	return value
end

local function HideInvitePopup()
	local hide = ClientGlobal("StaticPopup_Hide")
	if type(hide) == "function" then
		pcall(hide, "PARTY_INVITE")
	end
end

local function PlayListSoundFor(listName)
	if type(ns.PlayListSound) ~= "function" then
		return
	end
	if type(GroupWatchDB) ~= "table" or type(GroupWatchDB.lists) ~= "table" then
		return
	end
	local listData = GroupWatchDB.lists[listName]
	if type(listData) ~= "table" then
		return
	end
	local sound = listData.sound
	if sound == nil or sound == 0 then
		return
	end
	pcall(ns.PlayListSound, sound)
end

--- Resolve the inviter's "Name-Realm" from the event name, falling back to
--- GetPlayerInfoByGUID. GUID substrings are never parsed: the GUID is passed
--- to the client API as-is and only a plain name/realm pair is used.
local function ResolveInviterFullName(name, inviterGUID)
	local fullName = nil

	if ns.IsPlainValue(name) and type(name) == "string" and name ~= "" then
		fullName = ns.GetFullName(name)
	end
	if fullName then
		return fullName
	end

	local getPlayerInfo = ClientGlobal("GetPlayerInfoByGUID")
	if
		ns.IsPlainValue(inviterGUID)
		and type(inviterGUID) == "string"
		and inviterGUID ~= ""
		and type(getPlayerInfo) == "function"
	then
		local ok, _, _, _, _, _, playerName, playerRealm = pcall(getPlayerInfo, inviterGUID)
		if ok and ns.IsPlainValue(playerName) and type(playerName) == "string" and playerName ~= "" then
			local realm = nil
			if ns.IsPlainValue(playerRealm) and type(playerRealm) == "string" then
				realm = playerRealm
			end
			fullName = ns.GetFullName(playerName .. "-" .. (realm or ""))
		end
	end

	return fullName
end

--- Handle a direct party invite.
---
--- Returns "accept"/"decline" when an action was attempted, otherwise false.
--- Never throws; the event handler additionally wraps this in pcall.
function ns.HandlePartyInviteRequest(name, isTank, isHealer, isDamage, isNativeRealm, allowMultipleRoles, inviterGUID)
	if autoInvitesDisabled then
		return false
	end

	-- Resolve before checking the list so a secret name can still fall back
	-- to the (plain) GUID.
	local fullName = ResolveInviterFullName(name, inviterGUID)
	if not fullName then
		return false
	end

	local okAction, action, listName = pcall(ns.GetAutoAction, fullName)
	if not okAction or not action or not listName then
		return false
	end

	local key = nil
	if ns.IsPlainValue(inviterGUID) and type(inviterGUID) == "string" and inviterGUID ~= "" then
		key = inviterGUID
	else
		key = fullName
	end

	local now = Now()
	if now ~= nil and lastInvite and lastInvite.key == key and (now - lastInvite.at) < DEDUPE_SECONDS then
		return false
	end

	local actionFunction
	if action == "accept" then
		actionFunction = ClientGlobal("AcceptGroup")
	elseif action == "decline" then
		actionFunction = ClientGlobal("DeclineGroup")
	else
		return false
	end

	if type(actionFunction) ~= "function" then
		print("|cffffaa00[GroupWatch]|r " .. L["MSG_AUTO_RESTRICTED"])
		if now ~= nil then
			lastInvite = { key = key, at = now }
		end
		return false
	end

	local okCall, err = pcall(actionFunction)
	if not okCall then
		print(
			"|cffffaa00[GroupWatch]|r "
				.. string_format(L["MSG_AUTO_FAILED"], fullName, tostring(err))
		)
		if now ~= nil then
			lastInvite = { key = key, at = now }
		end
		return false
	end

	-- A synchronous ADDON_ACTION_BLOCKED handler may have disabled auto
	-- invites while the protected call was running; do not claim success.
	if autoInvitesDisabled then
		if now ~= nil then
			lastInvite = { key = key, at = now }
		end
		return false
	end

	if now ~= nil then
		lastInvite = { key = key, at = now }
	end

	if action == "accept" then
		-- Do not hide the popup here: StaticPopup's OnHide calls DeclineGroup()
		-- while dialog.inviteAccepted is unset, which would cancel the accept.
		-- PARTY_MEMBERS_CHANGED hides it once the roster has updated.
		pendingPopupHide = true
		print("|cff00ff00[GroupWatch]|r " .. string_format(L["MSG_AUTO_ACCEPTED"], fullName, listName))
	else
		-- DeclineGroup already ran, so closing the dialog immediately is safe.
		pendingPopupHide = false
		HideInvitePopup()
		print("|cffff0000[GroupWatch]|r " .. string_format(L["MSG_AUTO_DECLINED"], fullName, listName))
	end
	PlayListSoundFor(listName)

	return action
end

--- Called for ADDON_ACTION_BLOCKED/ADDON_ACTION_FORBIDDEN. Only our own
--- addon and only AcceptGroup/DeclineGroup count; anything else is ignored.
function ns.HandleAddonActionBlocked(addonName, functionName)
	if not ns.IsPlainValue(addonName) or type(addonName) ~= "string" then
		return false
	end
	if addonName ~= ADDON_NAME then
		return false
	end
	if not ns.IsPlainValue(functionName) or type(functionName) ~= "string" then
		return false
	end
	local mentionsAccept = string_find(functionName, "AcceptGroup", 1, true) ~= nil
	local mentionsDecline = string_find(functionName, "DeclineGroup", 1, true) ~= nil
	if not mentionsAccept and not mentionsDecline then
		return false
	end

	autoInvitesDisabled = true
	ns.autoInvitesDisabled = true
	if not blockedWarned then
		blockedWarned = true
		print("|cffff0000[GroupWatch]|r " .. L["MSG_AUTO_BLOCKED"])
	end
	return true
end

--- Test/debug hook: forget the session block and dedupe state.
function ns.ResetAutoActionState()
	autoInvitesDisabled = false
	ns.autoInvitesDisabled = false
	blockedWarned = false
	pendingPopupHide = false
	lastInvite = nil
end

ns.ResetAutoActionState()

-- ---------------------------------------------------------------------------
-- Event frame
-- ---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
ns.autoActionsFrame = eventFrame
eventFrame:RegisterEvent("PARTY_INVITE_REQUEST")
eventFrame:RegisterEvent("ADDON_ACTION_BLOCKED")
eventFrame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "PARTY_INVITE_REQUEST" then
		-- pcall at the outermost boundary: a malformed/secret argument must
		-- never break the client's invite event dispatch.
		pcall(ns.HandlePartyInviteRequest, ...)
	elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
		pcall(ns.HandleAddonActionBlocked, ...)
	elseif event == "PARTY_MEMBERS_CHANGED" then
		if pendingPopupHide then
			pendingPopupHide = false
			HideInvitePopup()
		end
	end
end)
