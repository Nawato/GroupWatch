--[[
	GroupWatch — UI_DragCursor
	===========================
	Floating chip that follows the pointer while a player is dragged between
	lists, plus the highlight of the target the pointer is over.

	The chip is created lazily on the first drag and reused afterwards. It
	never takes mouse input, so it can neither swallow the drop nor disturb
	the hover state of the rows underneath it.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local CreateFrame, UIParent = G.CreateFrame, G.UIParent
local GetCursorPosition = G.GetCursorPosition
local IsMouseButtonDown = G.IsMouseButtonDown
local IsKeyDown = G.IsKeyDown
local UnitClass, UnitName = G.UnitClass, G.UnitName
local GetNumRaidMembers = G.GetNumRaidMembers
local GetNumGroupMembers = G.GetNumGroupMembers
local IsInRaid, IsInGroup = G.IsInRaid, G.IsInGroup
local GetRealmName = G.GetRealmName
local math_min, math_max = G.math_min, G.math_max

-- Appearance
local CHIP_HEIGHT = 18
local CHIP_PADDING = 10
local ACCENT_WIDTH = 3
local CURSOR_OFFSET = 14
local HIGHLIGHT_ALPHA = 0.22

-- Neutral accent for characters that cannot be resolved to a unit.
local NEUTRAL_R, NEUTRAL_G, NEUTRAL_B = 0.85, 0.85, 0.85

local cursorFrame = nil
local highlightedRow = nil
local dragSourcePlayer = nil
local dragSourceList = nil
local dragAlreadyIn = {}
local dragFrames = 0
local dragR, dragG, dragB = NEUTRAL_R, NEUTRAL_G, NEUTRAL_B

-- ---------------------------------------------------------------------------
-- Class color
-- ---------------------------------------------------------------------------

-- "Name-Realm" of a unit, built the way Detection.lua builds its keys.
local function UnitFullName(unit)
	local name, realm = UnitName(unit)
	if not name or name == "" then
		return nil
	end
	if not realm or realm == "" then
		realm = GetRealmName():gsub("%s+", "")
	else
		realm = realm:gsub("%s+", "")
	end
	return name .. "-" .. realm
end

-- Class color of a unit, nil when the class is unknown.
local function UnitClassColor(unit)
	local _, classToken = UnitClass(unit)
	if not classToken then
		return nil
	end
	local custom = CUSTOM_CLASS_COLORS
	if custom and custom[classToken] then
		return custom[classToken].r, custom[classToken].g, custom[classToken].b
	end
	local standard = RAID_CLASS_COLORS
	if standard and standard[classToken] then
		return standard[classToken].r, standard[classToken].g, standard[classToken].b
	end
	return nil
end

--- Class color of a watched character.
---
--- Names are stored as "Name-Realm", so the group roster is matched the same
--- way Detection.lua builds its keys. Characters that are not in the group
--- (most list entries are typed by hand) get a neutral accent.
function ns.GetClassColorForName(fullName)
	if not fullName or fullName == "" then
		return NEUTRAL_R, NEUTRAL_G, NEUTRAL_B
	end

	if UnitFullName("player") == fullName then
		local r, g, b = UnitClassColor("player")
		if r then
			return r, g, b
		end
	end

	local prefix, count
	if IsInRaid() then
		prefix, count = "raid", GetNumRaidMembers()
	elseif IsInGroup() then
		prefix, count = "party", GetNumGroupMembers()
	end

	if prefix then
		for i = 1, count do
			-- In a party the last "member" is the player (same as Detection.lua).
			local unit = (prefix == "party" and i == count) and "player" or (prefix .. i)
			if UnitFullName(unit) == fullName then
				local r, g, b = UnitClassColor(unit)
				if r then
					return r, g, b
				end
			end
		end
	end

	return NEUTRAL_R, NEUTRAL_G, NEUTRAL_B
end

-- ---------------------------------------------------------------------------
-- Drop targets
-- ---------------------------------------------------------------------------

--- The list header or player row under the pointer, nil when there is none.
---
--- The hit test is geometric (the frame rect against the cursor position)
--- because the regular hover handling does not run while a drag is active.
function ns.GetDragTargetAtCursor()
	local ui = ns.GroupWatchUI
	if not ui then
		return nil
	end
	local targets = ui.dropTargets
	if not targets or #targets == 0 then
		return nil
	end

	local rawX, rawY = GetCursorPosition()

	-- The scroll frame clips its children: a row scrolled out of view still
	-- has a rect, but the pointer is not on it.
	local scrollFrame = ui.scrollFrame
	local clipLeft, clipBottom, clipWidth, clipHeight
	if scrollFrame then
		clipLeft, clipBottom, clipWidth, clipHeight = scrollFrame:GetRect()
		if clipLeft then
			-- GetRect() is in the frame's own effective-scale units, so the
			-- cursor has to be divided by the same scale to compare them.
			local clipScale = scrollFrame:GetEffectiveScale()
			local cx, cy = rawX / clipScale, rawY / clipScale
			if not (cx >= clipLeft and cx <= clipLeft + clipWidth and cy >= clipBottom and cy <= clipBottom + clipHeight) then
				return nil -- the pointer is outside the scroll area entirely
			end
		end
	end

	for i = 1, #targets do
		local row = targets[i]
		if row:IsVisible() and ns.IsValidDragTarget(row.data and row.data.listName) then
			local left, bottom, width, height = row:GetRect()
			if left and bottom then
				local rowScale = row:GetEffectiveScale()
				local x, y = rawX / rowScale, rawY / rowScale
				if x >= left and x <= left + width and y >= bottom and y <= bottom + height then
					return row
				end
			end
		end
	end
	return nil
end

--- True when `listName` is a drop target worth highlighting.
---
--- Mirrors the checks the move itself makes (the list has to exist, must not
--- be the list the character is dragged out of, and must not already hold the
--- character), so only lists a drop would actually change light up.
---
--- The membership check uses the roster as it was when the drag started: a
--- move that already happened during this drag must not make the list the
--- character now sits in lose its highlight.
function ns.IsValidDragTarget(listName)
	if not dragSourcePlayer or not listName then
		return false
	end
	if listName == dragSourceList then
		return false -- the list it comes from: not a move
	end
	if not GroupWatchDB or not GroupWatchDB.lists or not GroupWatchDB.lists[listName] then
		return false
	end
	if dragAlreadyIn[listName] then
		return false -- the character was already in this list
	end
	return true
end

--- Highlight a drop target (nil clears the highlight).
function ns.SetDragCursorTarget(row)
	if highlightedRow == row then
		return
	end

	if highlightedRow then
		if highlightedRow.dragHighlight then
			highlightedRow.dragHighlight:Hide()
		end
		if highlightedRow.dragHighlightBar then
			highlightedRow.dragHighlightBar:Hide()
		end
	end

	highlightedRow = row

	if row then
		-- Tint the overlay with the dragged character's class color so the
		-- chip and the target it points at read as one thing.
		if row.dragHighlight then
			row.dragHighlight:SetColorTexture(dragR, dragG, dragB, HIGHLIGHT_ALPHA)
			row.dragHighlight:Show()
		end
		if row.dragHighlightBar then
			row.dragHighlightBar:SetColorTexture(dragR, dragG, dragB, 0.9)
			row.dragHighlightBar:Show()
		end
	end
end

--- Called by the rows when a drag passes over them: instant feedback, the
--- per-frame hit test keeps the highlight in sync from there on.
--- A row that is not a valid target is not highlighted.
function ns.NotifyDragOverRow(row)
	if row and ns.IsValidDragTarget(row.data and row.data.listName) then
		ns.SetDragCursorTarget(row)
	end
end

--- True while a character is being dragged.
function ns.IsDragCursorActive()
	return dragSourcePlayer ~= nil
end

--- Re-pick the drop target under the pointer.
--- Called after the list layout changed, so the highlight follows the
--- pointer without waiting for the next frame.
function ns.RefreshDragCursorTarget()
	if not ns.IsDragCursorActive() then
		return
	end
	local target = ns.GetDragTargetAtCursor()
	if target ~= highlightedRow then
		ns.SetDragCursorTarget(target)
	end
end

-- ---------------------------------------------------------------------------
-- The chip
-- ---------------------------------------------------------------------------

-- Keep the chip on the pointer and the highlight on the target below it.
local function UpdateCursor(self)
	if not self:IsShown() then
		return
	end

	-- The first frame after the drag starts is skipped: the button state can
	-- read as "released" for a frame, which would hide the chip instantly.
	dragFrames = dragFrames + 1
	if dragFrames <= 1 then
		return
	end

	-- The drag ended without an OnDragStop (the mouse was released outside
	-- of the window, or the game cancelled the drag).
	if not IsMouseButtonDown("LeftButton") then
		ns.HideDragCursor()
		return
	end

	-- Escape cancels the drag. The game does fire OnDragStop for that, but
	-- the key check makes the hide immediate either way.
	if IsKeyDown("ESCAPE") then
		ns.HideDragCursor()
		return
	end

	-- Follow the pointer. GetCursorPosition() is in unscaled screen pixels,
	-- so it is divided by UIParent's scale to land in UIParent's space.
	local rawX, rawY = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	local x, y = rawX / scale, rawY / scale
	local parentWidth, parentHeight = UIParent:GetWidth(), UIParent:GetHeight()
	local chipWidth, chipHeight = self:GetWidth(), self:GetHeight()
	x = math_min(math_max(x + CURSOR_OFFSET, 0), math_max(parentWidth - chipWidth, 0))
	y = math_min(math_max(y + CURSOR_OFFSET, 0), math_max(parentHeight - chipHeight, 0))
	self:ClearAllPoints()
	self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)

	-- Highlight the target under the pointer
	ns.RefreshDragCursorTarget()
end

local function CreateCursorFrame()
	local f = CreateFrame("Frame", "DragCursorFrame", UIParent, "BackdropTemplate")
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel(100)
	f:EnableMouse(false)
	f:SetHeight(CHIP_HEIGHT)

	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		tile = false,
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	f:SetBackdropColor(0, 0, 0, 0.78)

	-- Class-colored accent bar on the left edge
	local accent = f:CreateTexture(nil, "ARTWORK")
	accent:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
	accent:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
	accent:SetWidth(ACCENT_WIDTH)
	f.accent = accent

	-- The dragged character name
	local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("LEFT", f, "LEFT", ACCENT_WIDTH + CHIP_PADDING, 0)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("MIDDLE")
	f.text = text

	f:SetScript("OnUpdate", UpdateCursor)

	-- Escape cancels the drag (the game fires OnDragStop for it, and the
	-- OnUpdate above checks the key directly); this is the explicit backstop.
	-- Guarded: an event that does not exist must not break the addon.
	pcall(function()
		f:RegisterEvent("CANCEL_ESCAPE")
	end)
	f:SetScript("OnEvent", function(self, event)
		if event == "CANCEL_ESCAPE" then
			ns.HideDragCursor()
		end
	end)

	f:Hide()
	return f
end

--- Show the drag chip for `playerName`.
--- `sourceList` is the list the character is dragged out of; dropping it
--- back into that list is not a move, so it is not marked as a target.
function ns.ShowDragCursor(playerName, sourceList)
	if not cursorFrame then
		cursorFrame = CreateCursorFrame()
	end

	dragSourcePlayer = playerName
	dragSourceList = sourceList
	dragFrames = 0
	ns.SetDragCursorTarget(nil)

	-- The lists the character is already in when the drag starts. A move
	-- during the drag does not change this: the list it moved into stays
	-- highlighted for as long as the pointer is on it.
	dragAlreadyIn = {}
	if GroupWatchDB and GroupWatchDB.lists then
		for lName, lData in pairs(GroupWatchDB.lists) do
			if lData.players and lData.players[playerName] then
				dragAlreadyIn[lName] = true
			end
		end
	end

	local r, g, b = ns.GetClassColorForName(playerName)
	dragR, dragG, dragB = r, g, b
	cursorFrame:SetBackdropBorderColor(r, g, b, 0.9)
	cursorFrame.accent:SetColorTexture(r, g, b, 1)
	cursorFrame.text:SetText(playerName or "")
	cursorFrame:SetWidth(ACCENT_WIDTH + CHIP_PADDING * 2 + cursorFrame.text:GetStringWidth())
	cursorFrame:Show()
end

--- Hide the drag chip and clear the drop target highlight.
function ns.HideDragCursor()
	ns.SetDragCursorTarget(nil)
	dragSourcePlayer = nil
	dragSourceList = nil
	dragAlreadyIn = {}
	dragFrames = 0
	if cursorFrame then
		cursorFrame:Hide()
	end
end
