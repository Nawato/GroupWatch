--[[
	GroupWatch — UI_MainWindow
	==========================
	The main list window: popup dialogs, drag-and-drop state, frame creation
	and the widget-pooled rendering of lists and players.

	This module only concerns itself with rendering; all persistence lives in
	DB.lua and is triggered through ns.AddPlayer / ns.RemovePlayer / ...
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local CreateFrame, UIParent = G.CreateFrame, G.UIParent
local GameTooltip = G.GameTooltip
local MenuUtil = G.MenuUtil
local StaticPopup_Show = G.StaticPopup_Show
local string_format = G.string_format
local table_insert, table_sort = G.table_insert, G.table_sort
local ipairs, pairs = G.ipairs, G.pairs
local type = G.type
local math_max, math_min, math_abs = G.math_max, G.math_min, G.math_abs
local tinsert = G.tinsert
local print = G.print

-- The main window frame, created lazily by CreateUI().
ns.GroupWatchUI = nil

-- ---------------------------------------------------------------------------
-- Popup dialogs
-- ---------------------------------------------------------------------------
StaticPopupDialogs["GROUPWATCH_NEW_PLAYER"] = {
	text = L["DIALOG_ADD_PLAYER_TEXT"],
	button1 = L["DIALOG_ADD"],
	button2 = L["DIALOG_CANCEL"],
	hasEditBox = true,
	OnAccept = function(self)
		local editBox = self.editBox or self.EditBox
		local text = editBox and editBox:GetText()
		if text and text ~= "" then
			local targetList = self.data or ns.selectedList or ns.GetDefaultListName()
			ns.AddPlayer(targetList, text)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetText()
		if text and text ~= "" then
			local parent = self:GetParent()
			local targetList = parent.data or ns.selectedList or ns.GetDefaultListName()
			ns.AddPlayer(targetList, text)
		end
		self:GetParent():Hide()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["GROUPWATCH_NEW_LIST"] = {
	text = L["DIALOG_NEW_LIST_TEXT"],
	button1 = L["DIALOG_CREATE"],
	button2 = L["DIALOG_CANCEL"],
	hasEditBox = true,
	OnAccept = function(self)
		local editBox = self.editBox or self.EditBox
		local text = editBox and editBox:GetText()
		if text and text ~= "" then
			ns.CreateList(text)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetText()
		if text and text ~= "" then
			ns.CreateList(text)
		end
		self:GetParent():Hide()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["GROUPWATCH_RENAME_LIST"] = {
	text = L["DIALOG_RENAME_LIST_TEXT"] or "Rename List:",
	button1 = L["DIALOG_SAVE"] or "Save",
	button2 = L["DIALOG_CANCEL"],
	hasEditBox = true,
	OnShow = function(self, data)
		local editBox = self.editBox or self.EditBox
		if data and editBox then
			editBox:SetText(data)
			editBox:HighlightText()
		end
	end,
	OnAccept = function(self, data)
		local editBox = self.editBox or self.EditBox
		local newName = editBox and editBox:GetText()
		if newName and newName ~= "" and data then
			ns.RenameList(data, newName)
		end
	end,
	EditBoxOnEnterPressed = function(self, data)
		local newName = self:GetText()
		local parent = self:GetParent()
		local oldName = parent.data or data
		if newName and newName ~= "" and oldName then
			ns.RenameList(oldName, newName)
		end
		parent:Hide()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["GROUPWATCH_DELETE_LIST"] = {
	text = L["DIALOG_DELETE_LIST_TEXT"],
	button1 = L["DIALOG_DELETE"],
	button2 = L["DIALOG_CANCEL"],
	OnAccept = function(self, data)
		ns.DeleteList(data)
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- ---------------------------------------------------------------------------
-- Drag-and-drop state for reorganizing players between lists
-- ---------------------------------------------------------------------------
local dragSourcePlayer = nil
local dragSourceList = nil
local dragSourceRow = nil

local function TryMoveDraggedPlayer(targetList)
	if not dragSourcePlayer or not dragSourceList or not targetList then
		return false
	end
	if dragSourceList == targetList then
		return false -- same list: cancel cleanly
	end
	if type(GroupWatchDB) ~= "table" or type(GroupWatchDB.lists) ~= "table" then
		return false
	end
	if type(GroupWatchDB.lists[targetList]) ~= "table" then
		return false
	end
	local targetPlayers = GroupWatchDB.lists[targetList].players
	if type(targetPlayers) == "table" and targetPlayers[dragSourcePlayer] then
		return false -- already a member of the target list
	end
	ns.MovePlayer(dragSourcePlayer, dragSourceList, targetList)
	return true
end

local function ClearDragVisuals()
	if dragSourceRow then
		dragSourceRow:SetAlpha(1.0)
		dragSourceRow = nil
	end
end

-- Drop-target overlay for a row: a soft fill plus a line along the top
-- edge, mirroring the drag cursor chip. Created once per pooled widget; the
-- drag cursor module shows and hides it.
local function CreateDropHighlight(row)
	local fill = row:CreateTexture(nil, "BACKGROUND")
	fill:SetAllPoints(row)
	fill:SetColorTexture(1, 1, 1, 0.3)
	fill:Hide()

	-- A line across the top edge: the row's own controls (the collapse
	-- button, the player bullet) sit at the left, so the accent goes here.
	local bar = row:CreateTexture(nil, "BACKGROUND")
	bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
	bar:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -1)
	bar:SetHeight(2)
	bar:SetColorTexture(1, 1, 1, 0.9)
	bar:Hide()

	row.dragHighlight = fill
	row.dragHighlightBar = bar
end

-- ---------------------------------------------------------------------------
-- Per-refresh caches (P2 perf: same behavior, less work per Refresh)
-- ---------------------------------------------------------------------------

--- Reuse a pooled widget's .data table across refreshes instead of
--- allocating a fresh { playerName, listName } table per row per refresh.
--- Stale fields are cleared so a recycled widget never keeps old data.
function ns.SetWidgetData(widget, playerName, listName)
	local d = widget.data
	if d then
		d.playerName = playerName
		d.listName = listName
		return d
	end
	d = { playerName = playerName, listName = listName }
	widget.data = d
	return d
end

--- Skin one button with a per-refresh cache instead of resolving the skin
--- engine again. Mirrors ns.SkinButton; `cache` is { eui, elv } captured
--- once at the top of f:Refresh(), so skinning N buttons costs one
--- GetElvUISkins() call no matter how many rows are shown.
local function SkinButtonCached(btn, cache)
	if type(btn) ~= "table" then
		return
	end
	local eui = cache and cache.eui
	-- A disabled engine must fall back even when the cache holds the raw
	-- object (e.g. pooled rows); mirrors ns.GetActiveEUI.
	if type(eui) == "table" and type(eui.IsEnabled) == "function" then
		local okEn, enabled = pcall(eui.IsEnabled, eui)
		if okEn and enabled == false then
			eui = nil
		end
	end
	if type(eui) == "table" and type(eui.Button) == "function" then
		local ok = pcall(eui.Button, btn)
		if ok then
			return
		end
	end
	local elv = cache and cache.elv
	if type(elv) == "table" and type(elv.HandleButton) == "function" then
		local ok = pcall(elv.HandleButton, elv, btn)
		if ok then
			return
		end
	end
	if type(ns.StyleFallbackButton) == "function" then
		pcall(ns.StyleFallbackButton, btn)
	end
end

-- Test hook: exercise the per-refresh cached skin path without a window.
ns._SkinButtonCached = SkinButtonCached

-- ---------------------------------------------------------------------------
-- Refresh callback (overrides the no-op stub from Core.lua)
-- ---------------------------------------------------------------------------
function ns.RefreshUI()
	local ui = ns.GroupWatchUI
	if ui and ui:IsShown() then
		ui:Refresh()
	end
end

-- ---------------------------------------------------------------------------
-- Frame creation
-- ---------------------------------------------------------------------------
local function CreateUI()
	if ns.GroupWatchUI then
		return ns.GroupWatchUI
	end

	-- Main window with BackdropTemplate
	local f = CreateFrame("Frame", "GroupWatchMainWindow", UIParent, "BackdropTemplate")
	f:SetSize(400, 460)
	f:SetPoint("CENTER")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)

	-- Base look: shared fallback theme (EUI/ElvUI upgrade it in SkinWindow).
	if type(ns.ApplyFallbackFrame) == "function" then
		ns.ApplyFallbackFrame(f)
	end

	-- Title bar (placed on the header strip by ns.SkinWindow)
	local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("CENTER", f, "TOP", 0, -12)
	title:SetText("|cff00ccffGroupWatch|r - " .. L["SUBTITLE"])
	f.title = title

	-- Close button
	local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
	f.closeBtn = closeBtn

	-- ScrollFrame for list area with a real scrollbar (wheel still works).
	local scrollFrame = CreateFrame("ScrollFrame", "GroupWatchScrollFrame", f, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -40)
	scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -40, 65)

	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local current = self:GetVerticalScroll()
		local max = self:GetVerticalScrollRange()
		self:SetVerticalScroll(math_max(0, math_min(max, current - delta * 20)))
		local sb = self.ScrollBar
		if type(sb) == "table" and type(sb.SetValue) == "function" then
			pcall(sb.SetValue, sb, self:GetVerticalScroll())
		end
	end)

	-- The template provides ScrollBar on live clients; test/restricted
	-- contexts get a manual slider so f.scrollBar is never nil.
	local scrollBar = scrollFrame.ScrollBar
	if type(scrollBar) ~= "table" and type(_G) == "table" then
		local globalBar = rawget(_G, "GroupWatchScrollFrameScrollBar")
		if type(globalBar) == "table" then
			scrollBar = globalBar
			scrollFrame.ScrollBar = scrollBar
		end
	end
	if type(scrollBar) ~= "table" then
		local okBar, newBar = pcall(CreateFrame, "Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
		if okBar and type(newBar) == "table" then
			if type(newBar.SetPoint) == "function" then
				pcall(newBar.SetPoint, newBar, "TOPLEFT", scrollFrame, "TOPRIGHT", -20, -16)
				pcall(newBar.SetPoint, newBar, "BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -20, 16)
			end
			if type(newBar.SetWidth) == "function" then
				pcall(newBar.SetWidth, newBar, 16)
			end
			scrollFrame.ScrollBar = newBar
			scrollBar = newBar
		end
	end

	f.scrollFrame = scrollFrame
	f.scrollBar = scrollBar

	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(345, 100)
	scrollFrame:SetScrollChild(content)

	f.content = content

	----------------------------------------------------
	-- FOOTER: LIST CONTROLS
	----------------------------------------------------

	-- "-" Delete list button (Right-aligned)
	local delListBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	delListBtn:SetSize(28, 24)
	delListBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 22)
	delListBtn:SetText("|cffff5555-|r")
	f.delListBtn = delListBtn
	delListBtn:SetScript("OnClick", function()
		if ns.IsDefaultList(ns.selectedList) then
			print("|cffff0000[GroupWatch]|r " .. L["MSG_CANNOT_DELETE_DEFAULT"])
		else
			local dialog = StaticPopup_Show("GROUPWATCH_DELETE_LIST", ns.selectedList)
			if dialog then
				dialog.data = ns.selectedList
			end
		end
	end)

	-- "+" Create list button (left of delete button)
	local newListBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	newListBtn:SetSize(28, 24)
	newListBtn:SetPoint("RIGHT", delListBtn, "LEFT", -4, 0)
	newListBtn:SetText("|cff00ff00+|r")
	f.newListBtn = newListBtn
	newListBtn:SetScript("OnClick", function()
		StaticPopup_Show("GROUPWATCH_NEW_LIST")
	end)

	-- Apply skin to window & base elements
	ns.SkinWindow(f)

	----------------------------------------------------
	-- RENDER LIST (widget-pooled)
	----------------------------------------------------
	function f:Refresh()
		ns.ReleaseUnused()

		-- The scroll frame template resets its scroll bar when the content
		-- height changes, so remember the offset and restore it after layout.
		local scrollOffset = scrollFrame:GetVerticalScroll()

		-- A refresh recycles the row widgets, so the highlighted drop target
		-- is stale: drop it and let the drag cursor pick the target under
		-- the pointer again once the new layout is in place.
		ns.SetDragCursorTarget(nil)
		f.dropTargets = {}

		if not GroupWatchDB or type(GroupWatchDB.lists) ~= "table" then
			return
		end

		if not ns.selectedList or not GroupWatchDB.lists[ns.selectedList] then
			ns.selectedList = ns.GetDefaultListName()
		end

		local yOffset = -5

		-- Cache commonly-used locale strings locally to avoid repeated table lookups
		local L_NO_PLAYERS_IN_LIST = L["NO_PLAYERS_IN_LIST"]

		-- P2 perf: resolve the skin engine once per refresh so the buttons
		-- below cost one lookup total, not one per button; hoist the
		-- default-list name out of the sort comparator further down.
		-- Use the active-skin resolver so IsEnabled()==false falls back
		-- instead of skinning pooled rows with a disabled engine.
		local activeEUI = nil
		if type(ns.GetActiveEUI) == "function" then
			local okActive, resolved = pcall(ns.GetActiveEUI)
			if okActive and type(resolved) == "table" then
				activeEUI = resolved
			end
		end
		local skinCache = { eui = activeEUI, elv = ns.GetElvUISkins() }
		local skinFont = skinCache.eui and skinCache.eui.Font
		if type(skinFont) ~= "function" then
			skinFont = nil
		end
		local function SkinText(fs)
			if type(fs) ~= "table" then
				return
			end
			if skinFont then
				local ok = pcall(skinFont, fs)
				if ok then
					return
				end
			end
			if type(ns.SkinFont) == "function" then
				pcall(ns.SkinFont, fs, false)
			end
		end
		local LDefName = L["DEFAULT_LIST_NAME"]

		-- Drop targets for the drag cursor: the list headers and the player
		-- rows a dragged player can be dropped on. Rebuilt on every refresh
		-- because the pool recycles the widgets.
		local dropTargets = {}
		f.dropTargets = dropTargets

		-- Sort list names for a stable, deterministic UI order (default lists first)
		local listNames = {}
		for lName in pairs(GroupWatchDB.lists) do
			table_insert(listNames, lName)
		end
		table_sort(listNames, function(a, b)
			local aDefault = a == "Standard" or a == "Default" or a == LDefName
			local bDefault = b == "Standard" or b == "Default" or b == LDefName
			if aDefault and not bDefault then
				return true
			end
			if not aDefault and bDefault then
				return false
			end
			return a < b
		end)

		for _, lName in ipairs(listNames) do
			local lData = GroupWatchDB.lists[lName]
			if lData.collapsed == nil then
				lData.collapsed = false
			end

			-- Header container
			local headerRow = ns.GetWidget("headerRow", function()
				local btn = CreateFrame("Button", nil, content)
				btn:SetSize(340, 22)
				btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				CreateDropHighlight(btn)
				btn:SetScript("OnClick", function(selfBtn, button)
					local listName = selfBtn.data.listName
					ns.selectedList = listName
					if button == "RightButton" then
						if MenuUtil and MenuUtil.CreateContextMenu then
							MenuUtil.CreateContextMenu(selfBtn, function(ownerRegion, rootDescription)
								rootDescription:CreateTitle(listName)

								-- Rename Option
								rootDescription:CreateButton(L["RENAME_LIST"] or "Rename List", function()
									local dialog = StaticPopup_Show("GROUPWATCH_RENAME_LIST", listName)
									if dialog then
										dialog.data = listName
									end
								end)

								-- Delete Option
								local delBtn = rootDescription:CreateButton(
									L["DELETE_LIST"] or "Delete List",
									function()
										local dialog = StaticPopup_Show("GROUPWATCH_DELETE_LIST", listName)
										if dialog then
											dialog.data = listName
										end
									end
								)
								if ns.IsDefaultList(listName) then
									delBtn:SetEnabled(false)
								end

								-- Change Sound Alert Submenu
								local soundSubMenu =
									rootDescription:CreateButton(L["CHANGE_SOUND_ALERT"] or "Change Sound Alert")
								ns.BuildSoundMenu(soundSubMenu, listName, function()
									f:Refresh()
								end)
							end)
						end
					else
						f:Refresh()
					end
				end)
				btn:SetScript("OnReceiveDrag", function(selfBtn)
					local targetList = selfBtn.data.listName
					ns.NotifyDragOverRow(selfBtn)
					if TryMoveDraggedPlayer(targetList) then
						-- moved successfully; Refresh handled by MovePlayer
					end
					ClearDragVisuals()
				end)
				-- Releasing the mouse over a target ends the drag: the chip
				-- goes away right away.
				btn:SetScript("OnMouseUp", function()
					if ns.IsDragCursorActive() then
						ns.HideDragCursor()
					end
				end)
				return btn
			end)
			headerRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
			headerRow:Show()
			ns.SetWidgetData(headerRow, nil, lName)
			table_insert(dropTargets, headerRow)

			-- Collapse/Expand button [-] / [+]
			local collapseBtn = ns.GetWidget("collapseBtn", function()
				local btn = CreateFrame("Button", nil, headerRow)
				btn:SetSize(18, 18)
				btn:SetPoint("LEFT", headerRow, "LEFT", 0, 0)
				btn:SetScript("OnClick", function(selfBtn)
					local ld = GroupWatchDB.lists[selfBtn.data.listName]
					if ld then
						ld.collapsed = not ld.collapsed
						f:Refresh()
					end
				end)
				return btn
			end)
			ns.SetWidgetData(collapseBtn, nil, lName)
			collapseBtn:SetParent(headerRow)
			collapseBtn:SetPoint("LEFT", headerRow, "LEFT", 0, 0)
			collapseBtn:Show()

			local collapseText = collapseBtn.collapseText
			if not collapseText then
				collapseText = collapseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				collapseText:SetPoint("CENTER", collapseBtn, "CENTER", 0, 0)
				collapseBtn.collapseText = collapseText
			end
			collapseText:SetText(lData.collapsed and "|cffffd100[+]|r" or "|cffffd100[-]|r")

			SkinButtonCached(collapseBtn, skinCache)

			-- List title — white when selected, dim gold otherwise
			local headerText = headerRow.headerText
			if not headerText then
				headerText = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
				headerText:SetPoint("LEFT", collapseBtn, "RIGHT", 6, 0)
				headerRow.headerText = headerText
			end
			if ns.selectedList == lName then
				headerText:SetText("|cffffffff" .. lName .. "|r")
			else
				headerText:SetText("|cffaaaaaa" .. lName .. "|r")
			end
			SkinText(headerText)

			-- Sound dropdown button after title
			local soundBtn = ns.GetWidget("soundBtn", function()
				local btn = CreateFrame("Button", nil, headerRow, "UIPanelButtonTemplate")
				btn:SetSize(100, 20)
				btn:SetScript("OnClick", function(selfBtn)
					if MenuUtil and MenuUtil.CreateContextMenu then
						local listName = selfBtn.data.listName
						MenuUtil.CreateContextMenu(selfBtn, function(ownerRegion, rootDescription)
							ns.BuildSoundMenu(rootDescription, listName, function()
								f:Refresh()
							end)
						end)
					end
				end)
				return btn
			end)
			ns.SetWidgetData(soundBtn, nil, lName)
			soundBtn:SetParent(headerRow)
			soundBtn:SetPoint("LEFT", headerText, "RIGHT", 8, 0)
			soundBtn:SetText(ns.GetSoundButtonLabel(lData.sound))
			soundBtn:Show()
			SkinButtonCached(soundBtn, skinCache)

			-- (+) Button to add player to list
			local addPlayerBtn = ns.GetWidget("addPlayerBtn", function()
				local btn = CreateFrame("Button", nil, headerRow, "UIPanelButtonTemplate")
				btn:SetSize(22, 20)
				btn:SetText("|cff00ff00+|r")
				btn:SetScript("OnClick", function(selfBtn)
					local listName = selfBtn.data.listName
					local dialog = StaticPopup_Show("GROUPWATCH_NEW_PLAYER")
					if dialog then
						dialog.data = listName
					end
				end)
				return btn
			end)
			ns.SetWidgetData(addPlayerBtn, nil, lName)
			addPlayerBtn:SetParent(headerRow)
			addPlayerBtn:SetPoint("TOP", headerRow, "TOP", 0, 0)
			addPlayerBtn:SetPoint("RIGHT", headerRow, "RIGHT", 0, 0)
			addPlayerBtn:Show()
			SkinButtonCached(addPlayerBtn, skinCache)

			yOffset = yOffset - 26

			if not lData.collapsed then
				local count = 0
				if lData.players then
					-- Sort player names for stable row order
					local playerNames = {}
					for pName in pairs(lData.players) do
						table_insert(playerNames, pName)
					end
					table_sort(playerNames)

					for _, pName in ipairs(playerNames) do
						count = count + 1

						local lNotes = lData.notes
						local noteText = lNotes and lNotes[pName]

						local row = ns.GetWidget("playerRow", function()
							local btn = CreateFrame("Button", nil, content)
							btn:SetSize(290, 20)
							btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
							btn:RegisterForDrag("LeftButton")
							CreateDropHighlight(btn)
							btn:SetScript("OnClick", function(selfBtn, button)
								if dragSourceRow == selfBtn then
									-- drag cancelled on this row; do not select it
									return
								end
								local pName = selfBtn.data.playerName
								local lName = selfBtn.data.listName
								ns.selectedPlayer = pName
								ns.selectedList = lName

								if button == "RightButton" then
									if MenuUtil and MenuUtil.CreateContextMenu then
										-- Re-resolve note at click time so it's current
										local ld = GroupWatchDB.lists[lName]
										local note = ld and ld.notes and ld.notes[pName]
										MenuUtil.CreateContextMenu(selfBtn, function(ownerRegion, rootDescription)
											rootDescription:CreateTitle(pName)

											-- Edit Note
											rootDescription:CreateButton(L["EDIT_NOTE"] or "Edit Note", function()
												ns.ShowNoteEditor(pName, lName, note)
											end)

											-- Remove Player
											rootDescription:CreateButton(
												L["CONTEXT_REMOVE"] or "Remove Player",
												function()
													ns.RemovePlayer(pName, lName)
												end
											)

											-- Move To List Submenu
											local moveSubMenu =
												rootDescription:CreateButton(L["MOVE_TO_LIST"] or "Move to List")
											-- Copy To List Submenu
											local copySubMenu =
												rootDescription:CreateButton(L["COPY_TO_LIST"] or "Copy to List")

											if type(GroupWatchDB) == "table" and type(GroupWatchDB.lists) == "table" then
												for targetListName in pairs(GroupWatchDB.lists) do
													local targetData = GroupWatchDB.lists[targetListName]
													if targetListName ~= lName then
														moveSubMenu:CreateButton(targetListName, function()
															ns.MovePlayer(pName, lName, targetListName)
														end)
													end
													if
														not (
															type(targetData) == "table"
															and type(targetData.players) == "table"
															and targetData.players[pName]
														)
													then
														copySubMenu:CreateButton(targetListName, function()
															ns.CopyPlayer(pName, lName, targetListName)
														end)
													end
												end
											end
										end)
									end
								else
									f:Refresh()
								end
							end)
							btn:SetScript("OnDragStart", function(selfBtn)
								dragSourcePlayer = selfBtn.data.playerName
								dragSourceList = selfBtn.data.listName
								dragSourceRow = selfBtn
								selfBtn:SetAlpha(0.5)
								ns.ShowDragCursor(selfBtn.data.playerName, selfBtn.data.listName)
							end)
							btn:SetScript("OnDragStop", function(selfBtn)
								ClearDragVisuals()
								ns.HideDragCursor()
							end)
							btn:SetScript("OnReceiveDrag", function(selfBtn)
								local targetList = selfBtn.data.listName
								ns.NotifyDragOverRow(selfBtn)
								if TryMoveDraggedPlayer(targetList) then
									-- moved successfully; Refresh handled by MovePlayer
								end
								ClearDragVisuals()
							end)
							-- Releasing the mouse over a target ends the drag:
							-- the chip goes away right away.
							btn:SetScript("OnMouseUp", function()
								if ns.IsDragCursorActive() then
									ns.HideDragCursor()
								end
							end)
							return btn
						end)
						ns.SetWidgetData(row, pName, lName)
						row:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
						row:Show()
						table_insert(dropTargets, row)

						local lineText = row.lineText
						if not lineText then
							lineText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
							lineText:SetPoint("LEFT", row, "LEFT", 0, 0)
							SkinText(lineText)
						end
						row.lineText = lineText
						if ns.selectedPlayer == pName then
							lineText:SetText("|cff00ff00• " .. pName .. "|r")
						else
							lineText:SetText("• " .. pName)
						end

						-- (-) Remove player button per row
						local del = ns.GetWidget("delBtn", function()
							local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
							btn:SetSize(22, 20)
							btn:SetText("|cffff5555-|r")
							btn:SetScript("OnClick", function(selfBtn)
								local pName = selfBtn.data.playerName
								local lName = selfBtn.data.listName
								ns.RemovePlayer(pName, lName)
							end)
							return btn
						end)
						ns.SetWidgetData(del, pName, lName)
						del:SetPoint("RIGHT", addPlayerBtn, "RIGHT", 0, 0)
						del:SetPoint("TOP", row, "TOP", 0, 0)
						del:Show()
						SkinButtonCached(del, skinCache)

						local noteBtn = ns.GetWidget("noteBtn", function()
							local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
							btn:SetSize(22, 20)
							btn:SetText("|cffd9b44aN|r")
							btn:SetScript("OnClick", function(selfBtn)
								local pName = selfBtn.data.playerName
								local lName = selfBtn.data.listName
								local ld = GroupWatchDB.lists[lName]
								local note = ld and ld.notes and ld.notes[pName]
								ns.ShowNoteEditor(pName, lName, note)
							end)
							btn:SetScript("OnEnter", function(selfBtn)
								local pName = selfBtn.data.playerName
								local lName = selfBtn.data.listName
								local ld = GroupWatchDB.lists[lName]
								local note = ld and ld.notes and ld.notes[pName]
								GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
								GameTooltip:ClearLines()
								if note and note ~= "" then
									GameTooltip:AddLine(string_format(L["NOTE_TOOLTIP"], note), 1, 1, 1, true)
								else
									GameTooltip:AddLine(L["NOTE_TOOLTIP_EMPTY"], 1, 1, 1, true)
								end
								GameTooltip:Show()
							end)
							btn:SetScript("OnLeave", function()
								GameTooltip:Hide()
							end)
							return btn
						end)
						ns.SetWidgetData(noteBtn, pName, lName)
						noteBtn:SetPoint("RIGHT", del, "LEFT", -4, 0)
						noteBtn:Show()
						SkinButtonCached(noteBtn, skinCache)

						yOffset = yOffset - 24
					end
				end

				if count == 0 then
					-- One placeholder per empty list: a single shared font
					-- string would be moved around (and hidden again) by the
					-- next list, so only the last list would ever show it.
					local empty = ns.GetWidget("emptyText", function()
						local fs = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
						SkinText(fs)
						return fs
					end)
					empty:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
					empty:SetText(L_NO_PLAYERS_IN_LIST)
					empty:Show()
					yOffset = yOffset - 22
				end
			end

			yOffset = yOffset - 14
		end

		content:SetHeight(math_abs(yOffset) + 20)
		scrollFrame:SetVerticalScroll(
			math_min(scrollOffset, math_max(0, content:GetHeight() - scrollFrame:GetHeight()))
		)
		-- Mirror the wheel handler: keep the slider value in sync after
		-- the restore so the thumb does not desync.
		local sb = scrollFrame.ScrollBar
		if type(sb) == "table" and type(sb.SetValue) == "function" then
			pcall(sb.SetValue, sb, scrollFrame:GetVerticalScroll())
		end

		-- The layout changed under the pointer (a move refreshes the list), so
		-- the drop target under it is picked again right away instead of on
		-- the next frame: forced, bypassing the hit-test throttle.
		ns.RefreshDragCursorTarget(true)
	end

	-- Closing the window mid-drag (Escape) must take the drag cursor with it.
	f:HookScript("OnHide", function()
		ns.HideDragCursor()
	end)

	tinsert(UISpecialFrames, "GroupWatchMainWindow")
	ns.GroupWatchUI = f
	f:Hide()
	return f
end

-- ---------------------------------------------------------------------------
-- Show / hide
-- ---------------------------------------------------------------------------
function ns.ToggleUI()
	local ui = CreateUI()
	if ui:IsShown() then
		ui:Hide()
	else
		ui:Refresh()
		ui:Show()
	end
end
