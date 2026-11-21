--[[
	GroupWatch — LFGApplicants
	==========================
	Shows GroupWatch matches among incoming Group Finder applicants and offers
	*manual* Invite/Decline buttons.

	Deliberately no automation here: the client does not allow unattended LFG
	applicant decisions. Event handlers only read data and rebuild the panel;
	C_LFGList.InviteApplicant/DeclineApplicant are called from real OnClick
	handlers and from nowhere else.

	Midnight 12.0+ hardening:
	  - applicant tokens, the applicant info table, member names and roles may
	    be secret; every read is pcall + ns.IsPlainValue/ns.CanAccessTable.
	  - chat-messaging lockdown skips all reads and shows a generic message.
	  - Blizzard's applicant rows are only decorated with our own FontString;
	    Blizzard text/regions are never modified.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local C_LFGList = G.C_LFGList
local CreateFrame = G.CreateFrame
local GameTooltip = G.GameTooltip
local hooksecurefunc = G.hooksecurefunc
local ipairs, pairs, pcall = G.ipairs, G.pairs, G.pcall
local type, tostring = G.type, G.tostring
local string_format = G.string_format
local math_max = G.math_max
local math_min = G.math_min
local table_insert = G.table_insert
local tconcat = table.concat
local print = G.print

local GetNumGroupMembers = G.GetNumGroupMembers
local IsInRaid = G.IsInRaid
local UnitGroupRolesAssigned = G.UnitGroupRolesAssigned

local MAX_ROWS = 8
local ROW_HEIGHT = 38
local SCAN_DELAY = 0.2

local seenMatches = {}
local restrictedWarned = false
local scanPending = false
local scanDirty = false

-- ---------------------------------------------------------------------------
-- Client restriction state
-- ---------------------------------------------------------------------------
local function ReadGlobal(name)
	if type(_G) == "table" then
		return rawget(_G, name)
	end
	return nil
end

--- True when the client currently restricts addon access to LFG/chat data.
--- Checks C_ChatInfo.InChatMessagingLockdown() and
--- C_RestrictedActions.GetAddOnRestrictionState(Enum.AddOnRestrictionType.Chat).
--- Both APIs are 12.0.5+; when absent no restriction is assumed.
function ns.IsLFGRestricted()
	local chatInfo = ReadGlobal("C_ChatInfo") or G.C_ChatInfo
	if type(chatInfo) == "table" and type(chatInfo.InChatMessagingLockdown) == "function" then
		local ok, value = pcall(chatInfo.InChatMessagingLockdown)
		if ok and ns.IsPlainValue(value) and value == true then
			return true
		end
	end

	local restrictedActions = ReadGlobal("C_RestrictedActions") or G.C_RestrictedActions
	local enum = ReadGlobal("Enum") or G.Enum
	if
		type(restrictedActions) == "table"
		and type(restrictedActions.GetAddOnRestrictionState) == "function"
		and type(enum) == "table"
	then
		local restrictionType = enum.AddOnRestrictionType and enum.AddOnRestrictionType.Chat
		local activeState = enum.AddOnRestrictionState and enum.AddOnRestrictionState.Active
		if restrictionType ~= nil and activeState ~= nil then
			local ok, state = pcall(restrictedActions.GetAddOnRestrictionState, restrictionType)
			if ok and ns.IsPlainValue(state) and state == activeState then
				return true
			end
		end
	end

	return false
end

local function WarnRestricted()
	if restrictedWarned then
		return
	end
	restrictedWarned = true
	print("|cffffaa00[GroupWatch]|r " .. L["MSG_LFG_RESTRICTED"])
end

-- ---------------------------------------------------------------------------
-- Group role capacity
-- ---------------------------------------------------------------------------
local function HomeGroupCount()
	local category = ReadGlobal("LE_PARTY_CATEGORY_HOME")
	if category == nil then
		category = G.LE_PARTY_CATEGORY_HOME
	end
	if type(GetNumGroupMembers) ~= "function" then
		return nil
	end
	local ok, count
	if category ~= nil then
		ok, count = pcall(GetNumGroupMembers, category)
	else
		ok, count = pcall(GetNumGroupMembers)
	end
	if not ok or not ns.IsPlainValue(count) or type(count) ~= "number" then
		return nil
	end
	return count
end

local function NormalizeRole(role)
	if not ns.IsPlainValue(role) or type(role) ~= "string" then
		return nil
	end
	local upper = role:upper()
	if upper == "TANK" then
		return "tank"
	end
	if upper == "HEALER" then
		return "healer"
	end
	if upper == "DAMAGER" or upper == "DPS" or upper == "DAMAGE" then
		return "damage"
	end
	if upper == "NONE" then
		return "none"
	end
	return nil
end

local ROLE_ORDER = { "tank", "healer", "damage" }

--- Return the set of roles a member can fill, plus the role they selected (if
--- any). Returns nil when the member offers no usable role.
local function GetMemberRoles(member)
	if type(member) ~= "table" then
		return nil
	end
	local roles = {}
	local assigned = NormalizeRole(member.assignedRole)
	if not assigned then
		assigned = NormalizeRole(member.role)
	end
	if assigned and assigned ~= "none" then
		roles[assigned] = true
	end
	if ns.IsPlainValue(member.tank) and member.tank == true then
		roles.tank = true
	end
	if ns.IsPlainValue(member.healer) and member.healer == true then
		roles.healer = true
	end
	if ns.IsPlainValue(member.damage) and member.damage == true then
		roles.damage = true
	end
	if not roles.tank and not roles.healer and not roles.damage then
		return nil
	end
	return roles, assigned
end

--- Count the roles already occupied by invited applicants. Returns nil when
--- any invited member's role cannot be determined, so callers never guess.
local function CountInvitedRoles(members)
	local counts = { tank = 0, healer = 0, damage = 0 }
	for _, member in ipairs(members) do
		local roles, assigned = GetMemberRoles(member)
		if not roles then
			return nil
		end
		local chosen = nil
		if assigned and assigned ~= "none" then
			chosen = assigned
		else
			local offered = 0
			for _, role in ipairs(ROLE_ORDER) do
				if roles[role] then
					offered = offered + 1
					chosen = role
				end
			end
			if offered ~= 1 then
				return nil
			end
		end
		counts[chosen] = counts[chosen] + 1
	end
	return counts
end

--- Count the current home group's roles via
--- GetNumGroupMembers(LE_PARTY_CATEGORY_HOME), IsInRaid() and
--- UnitGroupRolesAssigned(). Returns nil when any member's role is
--- unavailable/secret, so callers never guess and never show a false
--- "does not fit" result.
function ns.GetGroupRoleCounts()
	if type(UnitGroupRolesAssigned) ~= "function" then
		return nil
	end
	local count = HomeGroupCount()
	if type(count) ~= "number" or count < 0 then
		return nil
	end
	-- An active LFG listing always has at least its creator in the group.
	if count < 1 then
		count = 1
	end

	local isRaid = false
	if type(IsInRaid) == "function" then
		local ok, value = pcall(IsInRaid)
		if ok and ns.IsPlainValue(value) and value == true then
			isRaid = true
		end
	end

	local units = {}
	if isRaid then
		for i = 1, count do
			units[#units + 1] = "raid" .. i
		end
	else
		for i = 1, count - 1 do
			units[#units + 1] = "party" .. i
		end
		units[#units + 1] = "player"
	end

	local counts = { tank = 0, healer = 0, damage = 0 }
	for _, unit in ipairs(units) do
		local ok, role = pcall(UnitGroupRolesAssigned, unit)
		if not ok or not ns.IsPlainValue(role) or type(role) ~= "string" then
			return nil
		end
		local normalized = NormalizeRole(role)
		if normalized == "tank" then
			counts.tank = counts.tank + 1
		elseif normalized == "healer" then
			counts.healer = counts.healer + 1
		elseif normalized == "damage" then
			counts.damage = counts.damage + 1
		else
			-- NONE or an unknown role: do not claim role-fit knowledge.
			return nil
		end
	end
	return counts
end

--- Read the active listing's capacity. `invitedFallback` is used only when
--- C_LFGList.GetNumInvitedApplicantMembers is unavailable. `invitedRoles` is
--- the role count already occupied by invited applicants (false when those
--- roles are restricted/unknown); `invitedRolesCount` is how many invited
--- members those counts cover, so an incomplete read cannot claim a fit.
---
--- 5-man listings get explicit 1 tank / 1 healer / 3 damage role slots.
--- Raids (and everything else) are total-slots only.
function ns.GetActiveEntryCapacity(invitedFallback, invitedRoles, invitedRolesCount)
	if type(C_LFGList) ~= "table" then
		return nil
	end
	if type(C_LFGList.GetActiveEntryInfo) ~= "function" then
		return nil
	end
	local okEntry, entry = pcall(C_LFGList.GetActiveEntryInfo)
	if not okEntry or type(entry) ~= "table" or not ns.CanAccessTable(entry) then
		return nil
	end

	local activityIDs = entry.activityIDs
	if not ns.IsPlainValue(activityIDs) or type(activityIDs) ~= "table" or not ns.CanAccessTable(activityIDs) then
		return nil
	end
	local activityID = activityIDs[1]
	if not ns.IsPlainValue(activityID) or type(activityID) ~= "number" then
		return nil
	end

	if type(C_LFGList.GetActivityInfoTable) ~= "function" then
		return nil
	end
	local okActivity, activity = pcall(C_LFGList.GetActivityInfoTable, activityID)
	if not okActivity or type(activity) ~= "table" or not ns.CanAccessTable(activity) then
		return nil
	end
	local maxPlayers = activity.maxNumPlayers
	if not ns.IsPlainValue(maxPlayers) or type(maxPlayers) ~= "number" or maxPlayers <= 0 then
		return nil
	end

	local current = HomeGroupCount()
	if type(current) ~= "number" or current < 0 then
		current = 0
	end
	if current < 1 then
		current = 1
	end

	local invited = nil
	if type(C_LFGList.GetNumInvitedApplicantMembers) == "function" then
		local okInvited, value = pcall(C_LFGList.GetNumInvitedApplicantMembers)
		if okInvited and ns.IsPlainValue(value) and type(value) == "number" and value >= 0 then
			invited = value
		end
	end
	if invited == nil and ns.IsPlainValue(invitedFallback) and type(invitedFallback) == "number" and invitedFallback >= 0 then
		invited = invitedFallback
	end
	if invited == nil then
		invited = 0
	end

	local capacity = {
		max = maxPlayers,
		current = current,
		invited = invited,
		remaining = math_max(0, maxPlayers - current - invited),
		isFiveMan = maxPlayers == 5,
		roleDataAvailable = false,
	}

	if capacity.isFiveMan then
		local counts = ns.GetGroupRoleCounts()
		if type(counts) == "table" then
			local invitedTank, invitedHealer, invitedDamage = 0, 0, 0
			local rolesKnown = true
			if invitedRoles == false then
				-- Restricted invited members: their roles cannot be subtracted,
				-- so a role fit must never be claimed.
				rolesKnown = false
			elseif type(invitedRoles) == "table" then
				local tank = invitedRoles.tank
				local healer = invitedRoles.healer
				local damage = invitedRoles.damage
				if
					ns.IsPlainValue(tank)
					and type(tank) == "number"
					and tank >= 0
					and ns.IsPlainValue(healer)
					and type(healer) == "number"
					and healer >= 0
					and ns.IsPlainValue(damage)
					and type(damage) == "number"
					and damage >= 0
				then
					invitedTank, invitedHealer, invitedDamage = tank, healer, damage
					if type(invitedRolesCount) == "number" and invitedRolesCount < invited then
						rolesKnown = false
					end
				else
					rolesKnown = false
				end
			end

			if rolesKnown then
				capacity.roleRemaining = {
					tank = math_max(0, 1 - counts.tank - invitedTank),
					healer = math_max(0, 1 - counts.healer - invitedHealer),
					damage = math_max(0, 3 - counts.damage - invitedDamage),
				}
				capacity.roleDataAvailable = true
			end
		end
	end

	return capacity
end

--- Evaluate an applicant group against a capacity snapshot.
---
--- Returns "fit", "no_role", "full" or "unavailable". Role checks are only
--- performed for 5-man listings with complete role data; otherwise the total
--- slot count decides and "does not fit" is never claimed.
function ns.EvaluateRoleFit(members, capacity)
	if type(capacity) ~= "table" or type(members) ~= "table" or #members == 0 then
		return "unavailable"
	end
	if type(capacity.remaining) ~= "number" or capacity.remaining <= 0 then
		return "full"
	end
	if #members > capacity.remaining then
		return "full"
	end
	if not capacity.isFiveMan then
		return "fit"
	end
	if not capacity.roleDataAvailable or type(capacity.roleRemaining) ~= "table" then
		return "unavailable"
	end

	local remaining = {
		tank = capacity.roleRemaining.tank or 0,
		healer = capacity.roleRemaining.healer or 0,
		damage = capacity.roleRemaining.damage or 0,
	}
	local memberRoles = {}

	for _, member in ipairs(members) do
		local roles, assigned = GetMemberRoles(member)
		if not roles then
			return "unavailable"
		end
		memberRoles[#memberRoles + 1] = { roles = roles, assigned = assigned }
	end

	if #memberRoles == 0 then
		return "unavailable"
	end

	-- Backtracking assignment: try every role a member can fill and undo the
	-- decrement when a branch fails. A greedy pass can reject a valid group
	-- (e.g. A healer/damage, B tank/healer, C tank/healer with T1/H1/D1).
	local function Assign(index)
		if index > #memberRoles then
			return true
		end
		local entry = memberRoles[index]
		local roles = entry.roles
		local assigned = entry.assigned

		-- Prefer the role the member selected, then any other offered role.
		if assigned and assigned ~= "none" and roles[assigned] and remaining[assigned] > 0 then
			remaining[assigned] = remaining[assigned] - 1
			if Assign(index + 1) then
				return true
			end
			remaining[assigned] = remaining[assigned] + 1
		end
		for _, role in ipairs(ROLE_ORDER) do
			if role ~= assigned and roles[role] and remaining[role] > 0 then
				remaining[role] = remaining[role] - 1
				if Assign(index + 1) then
					return true
				end
				remaining[role] = remaining[role] + 1
			end
		end
		return false
	end

	if not Assign(1) then
		return "no_role"
	end
	return "fit"
end

-- Alias used by the panel/tests; both names describe the same check.
ns.GetApplicantRoleFit = ns.EvaluateRoleFit

-- ---------------------------------------------------------------------------
-- Applicant reads
-- ---------------------------------------------------------------------------
local function ReadMember(appID, memberIdx)
	if type(C_LFGList) ~= "table" or type(C_LFGList.GetApplicantMemberInfo) ~= "function" then
		return nil, false
	end
	local ok, name, _, _, _, _, _, tank, healer, damage, assignedRole =
		pcall(C_LFGList.GetApplicantMemberInfo, appID, memberIdx)
	if not ok then
		return nil, true
	end
	if
		not ns.IsPlainValue(name)
		or not ns.IsPlainValue(tank)
		or not ns.IsPlainValue(healer)
		or not ns.IsPlainValue(damage)
		or not ns.IsPlainValue(assignedRole)
	then
		return nil, true
	end

	local member = {
		name = nil,
		tank = tank == true,
		healer = healer == true,
		damage = damage == true,
		assignedRole = type(assignedRole) == "string" and assignedRole or nil,
	}
	if type(name) == "string" and name ~= "" then
		member.name = ns.GetFullName(name)
	end
	return member, false
end

local function GetMemberMatch(appID, memberIdx)
	local member, restricted = ReadMember(appID, memberIdx)
	if restricted then
		return nil, nil, true
	end
	if type(member) ~= "table" or not member.name then
		return nil, nil, false
	end
	local watched = ns.GetWatchedIndex()
	local lists = watched and watched[member.name]
	if type(lists) ~= "table" or #lists == 0 then
		return nil, nil, false
	end
	return member.name, lists, false
end

local function RoleLabel(role)
	if role == "tank" then
		return L["LFG_ROLE_TANK"]
	end
	if role == "healer" then
		return L["LFG_ROLE_HEALER"]
	end
	if role == "damage" then
		return L["LFG_ROLE_DAMAGE"]
	end
	return L["LFG_ROLE_UNKNOWN"]
end

local function GetMemberRoleText(member)
	if type(member) ~= "table" then
		return L["LFG_ROLE_UNKNOWN"]
	end
	local parts = {}
	local assigned = NormalizeRole(member.assignedRole)
	if not assigned then
		assigned = NormalizeRole(member.role)
	end
	if assigned and assigned ~= "none" then
		parts[#parts + 1] = RoleLabel(assigned)
	else
		if ns.IsPlainValue(member.tank) and member.tank == true then
			parts[#parts + 1] = RoleLabel("tank")
		end
		if ns.IsPlainValue(member.healer) and member.healer == true then
			parts[#parts + 1] = RoleLabel("healer")
		end
		if ns.IsPlainValue(member.damage) and member.damage == true then
			parts[#parts + 1] = RoleLabel("damage")
		end
	end
	if #parts == 0 then
		return L["LFG_ROLE_UNKNOWN"]
	end
	return tconcat(parts, "/")
end
ns.GetMemberRoleText = GetMemberRoleText

local function GetFitText(fit, capacity)
	if fit == "full" then
		return L["LFG_SLOTS_FULL"], "ffff8800"
	end
	if fit == "no_role" then
		return L["LFG_ROLE_NO_FIT"], "ffff5555"
	end
	if fit == "unavailable" then
		return L["LFG_ROLE_UNKNOWN"], "ffaaaaaa"
	end
	if capacity and not capacity.isFiveMan and type(capacity.remaining) == "number" then
		return string_format(L["LFG_SLOTS_AVAILABLE"], capacity.remaining), "ff00ff00"
	end
	return L["LFG_ROLE_FIT"], "ff00ff00"
end

-- ---------------------------------------------------------------------------
-- Blizzard applicant-row decoration
-- ---------------------------------------------------------------------------
local hookedGlobals = {}

local function HookGlobal(name, callback)
	if hookedGlobals[name] then
		return
	end
	if type(hooksecurefunc) ~= "function" then
		return
	end
	local target = ReadGlobal(name)
	if type(target) ~= "function" then
		return
	end
	local ok = pcall(hooksecurefunc, name, callback)
	if ok then
		hookedGlobals[name] = true
	end
end

local function EnsureMemberTag(member)
	if type(member) ~= "table" or type(member.CreateFontString) ~= "function" then
		return nil
	end
	if type(member.GWTag) == "table" then
		return member.GWTag
	end

	local tag = member:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	if type(tag) ~= "table" then
		return nil
	end
	-- Anchor our own region to the right of the right-most Blizzard role
	-- icon. We never move or edit Blizzard's regions.
	local anchor = member.RoleIcon3 or member.RoleIcon1
	if type(anchor) == "table" and type(tag.SetPoint) == "function" then
		pcall(tag.SetPoint, tag, "LEFT", anchor, "RIGHT", 2, 0)
	elseif type(tag.SetPoint) == "function" then
		pcall(tag.SetPoint, tag, "RIGHT", member, "RIGHT", -4, 0)
	end
	if type(tag.SetTextColor) == "function" then
		pcall(tag.SetTextColor, tag, 0, 0.8, 1)
	end
	if type(tag.SetText) == "function" then
		pcall(tag.SetText, tag, "GW")
	end
	if type(tag.Hide) == "function" then
		pcall(tag.Hide, tag)
	end
	member.GWTag = tag
	return tag
end

local function ApplyMemberTag(member, appID, memberIdx)
	local tag = EnsureMemberTag(member)
	if not tag then
		return
	end
	local ok, fullName, _, restricted = pcall(GetMemberMatch, appID, memberIdx)
	if not ok or restricted or not fullName then
		tag:Hide()
		return
	end
	tag:Show()
end

local function AppendRestrictedTooltipLine(tooltip)
	if ns.AppendRestrictedTooltipLine then
		ns.AppendRestrictedTooltipLine(tooltip)
	end
end

local function AppendMemberTooltip(member)
	if type(member) ~= "table" then
		return
	end
	local parent = nil
	if type(member.GetParent) == "function" then
		local ok, value = pcall(member.GetParent, member)
		if ok then
			parent = value
		end
	end
	local appID = type(parent) == "table" and parent.applicantID or nil
	local memberIdx = member.memberIdx
	if not ns.IsPlainValue(appID) or type(appID) ~= "number" then
		return
	end
	if not ns.IsPlainValue(memberIdx) or type(memberIdx) ~= "number" then
		return
	end

	local memberInfo, restricted = ReadMember(appID, memberIdx)
	if restricted then
		AppendRestrictedTooltipLine(GameTooltip)
		return
	end
	if type(memberInfo) == "table" and memberInfo.name and type(ns.AppendNotesToTooltip) == "function" then
		ns.AppendNotesToTooltip(GameTooltip, memberInfo.name)
	end
end

local function HookApplicantGlobals()
	HookGlobal("LFGListApplicationViewer_UpdateApplicant", function(button, appID)
		if type(button) ~= "table" or type(button.Members) ~= "table" then
			return
		end
		for index, member in ipairs(button.Members) do
			local memberIdx = member.memberIdx
			if not ns.IsPlainValue(memberIdx) or type(memberIdx) ~= "number" then
				memberIdx = index
			end
			pcall(ApplyMemberTag, member, appID, memberIdx)
		end
	end)

	HookGlobal("LFGListApplicationViewer_UpdateApplicantMember", function(member, appID, memberIdx)
		pcall(ApplyMemberTag, member, appID, memberIdx)
	end)

	HookGlobal("LFGListApplicantMember_OnEnter", function(member)
		pcall(AppendMemberTooltip, member)
	end)
end

-- ---------------------------------------------------------------------------
-- Manual panel
-- ---------------------------------------------------------------------------
local function GetLFGToken(row)
	if type(row) ~= "table" or type(row.data) ~= "table" then
		return nil
	end
	local token = row.data.token
	if not ns.IsPlainValue(token) or type(token) ~= "number" then
		return nil
	end
	return token
end

local function ReportLFGError(err)
	print("|cffff0000[GroupWatch]|r " .. string_format(L["MSG_LFG_FAILED"], tostring(err)))
end

local function CreatePanelRow(panel, index)
	local row = CreateFrame("Frame", nil, panel)
	row:SetSize(284, ROW_HEIGHT - 2)
	if type(row.SetPoint) == "function" then
		row:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -28 - (index - 1) * ROW_HEIGHT)
	end
	row.data = { token = nil }

	local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	if type(nameText.SetPoint) == "function" then
		nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
	end
	if type(nameText.SetWidth) == "function" then
		nameText:SetWidth(170)
	end
	if type(nameText.SetWordWrap) == "function" then
		nameText:SetWordWrap(false)
	end
	row.nameText = nameText

	local infoText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	if type(infoText.SetPoint) == "function" then
		infoText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -16)
	end
	if type(infoText.SetWidth) == "function" then
		infoText:SetWidth(170)
	end
	if type(infoText.SetWordWrap) == "function" then
		infoText:SetWordWrap(false)
	end
	row.infoText = infoText

	local invite = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	invite:SetSize(52, 18)
	if type(invite.SetPoint) == "function" then
		invite:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -1)
	end
	invite:SetText(L["LFG_INVITE"])
	invite:SetScript("OnClick", function()
		-- Real click path only: never called from events or timers.
		local token = GetLFGToken(row)
		if not token or type(C_LFGList) ~= "table" or type(C_LFGList.InviteApplicant) ~= "function" then
			return
		end
		local ok, err = pcall(C_LFGList.InviteApplicant, token)
		if not ok then
			ReportLFGError(err)
		end
		ns.RequestLFGApplicantScan()
	end)
	if type(ns.SkinButton) == "function" then
		pcall(ns.SkinButton, invite)
	end
	row.invite = invite

	local decline = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	decline:SetSize(52, 18)
	if type(decline.SetPoint) == "function" then
		decline:SetPoint("TOPRIGHT", row, "TOPRIGHT", -56, -1)
	end
	decline:SetText(L["LFG_DECLINE"])
	decline:SetScript("OnClick", function()
		-- Real click path only: never called from events or timers.
		local token = GetLFGToken(row)
		if not token or type(C_LFGList) ~= "table" or type(C_LFGList.DeclineApplicant) ~= "function" then
			return
		end
		local ok, err = pcall(C_LFGList.DeclineApplicant, token)
		if not ok then
			ReportLFGError(err)
		end
		ns.RequestLFGApplicantScan()
	end)
	if type(ns.SkinButton) == "function" then
		pcall(ns.SkinButton, decline)
	end
	row.decline = decline

	return row
end

local function CreateLFGPanel(lfgFrame)
	local panel = CreateFrame("Frame", "GroupWatchLFGApplicants", lfgFrame, "BackdropTemplate")
	panel:SetSize(300, 120)
	local anchor = lfgFrame.ApplicationViewer or lfgFrame
	if type(panel.SetPoint) == "function" then
		panel:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
	end
	if type(panel.SetClampedToScreen) == "function" then
		panel:SetClampedToScreen(true)
	end
	if type(panel.EnableMouse) == "function" then
		panel:EnableMouse(true)
	end
	if type(panel.SetFrameStrata) == "function" then
		pcall(panel.SetFrameStrata, panel, "DIALOG")
	end
	if type(ns.ApplyFallbackFrame) == "function" then
		pcall(ns.ApplyFallbackFrame, panel)
	end

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if type(title.SetPoint) == "function" then
		title:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
	end
	title:SetText(L["LFG_PANEL_TITLE"])
	panel.title = title

	local statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	if type(statusText.SetPoint) == "function" then
		statusText:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -28)
	end
	if type(statusText.SetWidth) == "function" then
		statusText:SetWidth(284)
	end
	if type(statusText.SetWordWrap) == "function" then
		statusText:SetWordWrap(true)
	end
	statusText:Hide()
	panel.statusText = statusText

	local moreText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	moreText:SetText("")
	moreText:Hide()
	panel.moreText = moreText

	panel.rows = {}

	if type(lfgFrame.HookScript) == "function" then
		pcall(lfgFrame.HookScript, lfgFrame, "OnShow", function()
			ns.RequestLFGApplicantScan()
		end)
		pcall(lfgFrame.HookScript, lfgFrame, "OnHide", function()
			local current = ns.lfgApplicantsPanel
			if type(current) == "table" and type(current.Hide) == "function" then
				pcall(current.Hide, current)
			end
		end)
	end

	panel:Hide()
	ns.lfgApplicantsPanel = panel
	return panel
end

--- Store the current match rows in the panel. `rows == nil` means "no active
--- listing" and hides the panel; `restricted` shows the generic message when
--- no readable matches are available.
function ns.UpdateLFGPanel(rows, restricted)
	local panel = ns.lfgApplicantsPanel
	if type(panel) ~= "table" then
		return
	end

	local lfgFrame = ReadGlobal("LFGListFrame")
	local visible = type(lfgFrame) == "table"
	if visible and type(lfgFrame.IsShown) == "function" then
		local ok, shown = pcall(lfgFrame.IsShown, lfgFrame)
		if ok and not shown then
			visible = false
		end
	end
	if not visible or rows == nil then
		panel:Hide()
		return
	end

	for _, row in ipairs(panel.rows) do
		row:Hide()
	end

	local statusText = nil
	local rowCount = #rows
	if rowCount == 0 then
		if restricted then
			statusText = L["MSG_LFG_RESTRICTED"]
		else
			statusText = L["LFG_NO_MATCHES"]
		end
	end

	if statusText then
		panel.statusText:SetText(statusText)
		panel.statusText:Show()
	else
		panel.statusText:Hide()
	end

	local shownRows = 0
	for index = 1, math_min(rowCount, MAX_ROWS) do
		local match = rows[index]
		local row = panel.rows[index]
		if not row then
			row = CreatePanelRow(panel, index)
			table_insert(panel.rows, row)
		end
		row.data.token = match.token
		row.nameText:SetText(match.name)
		row.infoText:SetText(match.info)
		row:Show()
		shownRows = shownRows + 1
	end

	if rowCount > MAX_ROWS and panel.moreText then
		panel.moreText:SetText(string_format(L["LFG_MORE"], rowCount - MAX_ROWS))
		if type(panel.moreText.SetPoint) == "function" then
			pcall(
				panel.moreText.SetPoint,
				panel.moreText,
				"TOPLEFT",
				panel,
				"TOPLEFT",
				8,
				-28 - shownRows * ROW_HEIGHT
			)
		end
		panel.moreText:Show()
	elseif panel.moreText then
		panel.moreText:Hide()
	end

	local height = 28 + shownRows * ROW_HEIGHT + (rowCount > MAX_ROWS and 16 or 0) + 10
	if statusText then
		height = 58
	end
	panel:SetHeight(height)
	panel:Show()
end

-- ---------------------------------------------------------------------------
-- Scan / match collection
-- ---------------------------------------------------------------------------
local function DoScan()
	if ns.IsLFGRestricted() then
		WarnRestricted()
		ns.UpdateLFGPanel(nil, true)
		return
	end

	if type(C_LFGList) ~= "table" then
		ns.UpdateLFGPanel(nil, false)
		return
	end
	if type(C_LFGList.GetActiveEntryInfo) ~= "function" then
		ns.UpdateLFGPanel(nil, false)
		return
	end

	local okEntry, entry = pcall(C_LFGList.GetActiveEntryInfo)
	if not okEntry then
		WarnRestricted()
		ns.UpdateLFGPanel(nil, true)
		return
	end
	if type(entry) ~= "table" then
		seenMatches = {}
		restrictedWarned = false
		ns.UpdateLFGPanel(nil, false)
		return
	end
	if not ns.CanAccessTable(entry) then
		WarnRestricted()
		ns.UpdateLFGPanel(nil, true)
		return
	end

	if type(C_LFGList.GetApplicants) ~= "function" then
		ns.UpdateLFGPanel(nil, false)
		return
	end
	local okList, applicants = pcall(C_LFGList.GetApplicants)
	if not okList or type(applicants) ~= "table" or not ns.CanAccessTable(applicants) then
		WarnRestricted()
		ns.UpdateLFGPanel(nil, true)
		return
	end

	local watched = ns.GetWatchedIndex()
	local applicantsData = {}
	local liveApplicants = {}
	local restricted = false
	local invitedFallback = 0
	local invitedRolesUnavailable = false

	for _, token in ipairs(applicants) do
		if not ns.IsPlainValue(token) then
			restricted = true
		elseif type(token) ~= "number" then
			-- Opaque/unsupported token: skip it, never guess.
			restricted = true
		else
			local okInfo, info = pcall(C_LFGList.GetApplicantInfo, token)
			if not okInfo or type(info) ~= "table" or not ns.CanAccessTable(info) then
				restricted = true
			else
				local appID = info.applicantID
				if not ns.IsPlainValue(appID) or type(appID) ~= "number" then
					appID = token
				end
				local numMembers = info.numMembers
				local status = info.applicationStatus
				if
					not ns.IsPlainValue(numMembers)
					or type(numMembers) ~= "number"
					or numMembers < 1
					or not ns.IsPlainValue(status)
					or (status ~= nil and type(status) ~= "string")
				then
					restricted = true
				else
					liveApplicants[appID] = true
					if status == "invited" then
						invitedFallback = invitedFallback + numMembers
					end

					local data = {
						token = token,
						appID = appID,
						numMembers = numMembers,
						status = status,
						members = {},
						matched = {},
					}
					local applicantRestricted = false

					for memberIndex = 1, numMembers do
						local member, memberRestricted = ReadMember(token, memberIndex)
						if memberRestricted then
							applicantRestricted = true
							restricted = true
							break
						end
						if member then
							data.members[#data.members + 1] = member
							if member.name then
								local lists = watched and watched[member.name]
								if type(lists) == "table" and #lists > 0 then
									data.matched[#data.matched + 1] = member
									if not data.firstLists then
										data.firstLists = lists
									end
									if not data.firstMatch then
										data.firstMatch = member
									end
								end
							end
						end
					end

					if applicantRestricted then
						if status == "invited" then
							invitedRolesUnavailable = true
						end
					else
						applicantsData[#applicantsData + 1] = data
					end
				end
			end
		end
	end

	-- Forget applicants that are no longer present so a future application
	-- by the same applicant ID can notify again.
	for appID in pairs(seenMatches) do
		if not liveApplicants[appID] then
			seenMatches[appID] = nil
		end
	end

	if restricted then
		WarnRestricted()
	else
		restrictedWarned = false
	end

	-- Invited applicants already occupy role slots even though the client
	-- counts them separately from the home group. Subtract their roles so an
	-- applied member is not shown as a fit for a role that is already taken.
	local invitedRoles = { tank = 0, healer = 0, damage = 0 }
	local invitedRoleMembers = 0
	for _, data in ipairs(applicantsData) do
		if data.status == "invited" then
			invitedRoleMembers = invitedRoleMembers + data.numMembers
			local counts = CountInvitedRoles(data.members)
			if counts then
				invitedRoles.tank = invitedRoles.tank + counts.tank
				invitedRoles.healer = invitedRoles.healer + counts.healer
				invitedRoles.damage = invitedRoles.damage + counts.damage
			else
				invitedRolesUnavailable = true
			end
		end
	end

	local capacity = ns.GetActiveEntryCapacity(
		invitedFallback,
		invitedRolesUnavailable and false or invitedRoles,
		invitedRoleMembers
	)
	if not capacity then
		ns.UpdateLFGPanel(nil, false)
		return
	end

	local rows = {}
	for _, data in ipairs(applicantsData) do
		local activeApplication = data.status == nil or data.status == "applied"
		if activeApplication and #data.matched > 0 and data.firstMatch and data.firstLists then
			local fit = ns.EvaluateRoleFit(data.members, capacity)
			local fitText, fitColor = GetFitText(fit, capacity)

			local nameText = data.firstMatch.name
			if #data.matched > 1 then
				nameText = nameText .. " " .. string_format(L["LFG_MORE"], #data.matched - 1)
			end
			local roleText = GetMemberRoleText(data.firstMatch)
			local listName = data.firstLists[1]
			local listText = string_format(L["CONTEXT_LIST"], listName)
			if #data.firstLists > 1 then
				listText = listText .. " " .. string_format(L["LFG_MORE"], #data.firstLists - 1)
			end

			rows[#rows + 1] = {
				token = data.token,
				name = nameText .. "  |cff888888" .. roleText .. "|r",
				info = listText .. "  |cff" .. fitColor .. fitText .. "|r",
			}

			if not seenMatches[data.appID] then
				seenMatches[data.appID] = true
				print(
					"|cff00ccff[GroupWatch]|r "
						.. string_format(L["MSG_LFG_MATCH"], data.firstMatch.name, listName)
				)
				local listData = nil
				if type(GroupWatchDB) == "table" and type(GroupWatchDB.lists) == "table" then
					listData = GroupWatchDB.lists[listName]
				end
				if type(listData) == "table" and listData.sound and listData.sound ~= 0
					and type(ns.PlayListSound) == "function"
				then
					pcall(ns.PlayListSound, listData.sound)
				end
			end
		end
	end

	ns.UpdateLFGPanel(rows, restricted)
end

--- Public scan wrapper: never throws, so event/timer callers stay safe.
function ns.ScanLFGApplicants()
	local ok = pcall(DoScan)
	return ok
end

--- Coalesce bursts of LFG events into one scan ~0.2s later. Without C_Timer
--- the scan runs synchronously so the panel still updates in restricted/test
--- contexts.
function ns.RequestLFGApplicantScan()
	scanDirty = true
	if scanPending then
		return
	end
	local timer = G.C_Timer
	if type(timer) == "table" and type(timer.After) == "function" then
		scanPending = true
		local ok = pcall(timer.After, SCAN_DELAY, function()
			scanPending = false
			if not scanDirty then
				return
			end
			scanDirty = false
			ns.ScanLFGApplicants()
		end)
		if ok then
			return
		end
		scanPending = false
	end
	scanDirty = false
	ns.ScanLFGApplicants()
end

--- Test/debug hook: forget notification dedupe and restriction messages.
function ns.ResetLFGApplicantState()
	seenMatches = {}
	restrictedWarned = false
	scanPending = false
	scanDirty = false
	local panel = ns.lfgApplicantsPanel
	if type(panel) == "table" and type(panel.Hide) == "function" then
		pcall(panel.Hide, panel)
	end
end

-- ---------------------------------------------------------------------------
-- Setup / hooks
-- ---------------------------------------------------------------------------
--- Create the panel and hook Blizzard's applicant view once the Group Finder
--- is available. Safe to call repeatedly.
function ns.SetupLFGApplicants()
	HookApplicantGlobals()
	local lfgFrame = ReadGlobal("LFGListFrame")
	if type(lfgFrame) ~= "table" then
		return false
	end
	if type(ns.lfgApplicantsPanel) ~= "table" then
		CreateLFGPanel(lfgFrame)
	end
	return true
end

-- ---------------------------------------------------------------------------
-- Event frame
-- ---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
ns.lfgApplicantsFrame = eventFrame
eventFrame:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
eventFrame:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
eventFrame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == "Blizzard_GroupFinder" then
			ns.SetupLFGApplicants()
			ns.RequestLFGApplicantScan()
		end
	elseif event == "PLAYER_LOGIN" then
		ns.SetupLFGApplicants()
	else
		ns.SetupLFGApplicants()
		ns.RequestLFGApplicantScan()
	end
end)

-- The Group Finder may already be loaded when this addon loads.
ns.SetupLFGApplicants()
