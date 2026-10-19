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
local PlaySound = G.PlaySound
local StaticPopup_Show = G.StaticPopup_Show
local string_format = G.string_format
local table_insert, table_sort = G.table_insert, G.table_sort
local ipairs, pairs = G.ipairs, G.pairs
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
		local text = self.EditBox:GetText()
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
		local text = self.EditBox:GetText()
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
		if data then
			self.EditBox:SetText(data)
			self.EditBox:HighlightText()
		end
	end,
	OnAccept = function(self, data)
		local newName = self.EditBox:GetText()
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
	if not GroupWatchDB.lists[targetList] then
		return false
	end
	if GroupWatchDB.lists[targetList].players
		and GroupWatchDB.lists[targetList].players[dragSourcePlayer] then
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

	if not (ns.skinEUI or ns.IsElvUIPresent()) then
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 },
		})
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

	-- ScrollFrame for list area
	local scrollFrame = CreateFrame("ScrollFrame", "GroupWatchScrollFrame", f)
	scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -40)
	scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 65)

	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local current = self:GetVerticalScroll()
		local max = self:GetVerticalScrollRange()
		self:SetVerticalScroll(math_max(0, math_min(max, current - delta * 20)))
	end)

	f.scrollFrame = scrollFrame
	f.scrollBar = nil

	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(340, 100)
	scrollFrame:SetScrollChild(content)

	f.content = content

	----------------------------------------------------
	-- FOOTER: LIST CONTROLS
	----------------------------------------------------

	-- "−" Delete list button (Right-aligned)
	local delListBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	delListBtn:SetSize(28, 24)
	delListBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 22)
	delListBtn:SetText("|cffff5555−|r")
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

		if not GroupWatchDB or not GroupWatchDB.lists then
			return
		end

		if not ns.selectedList or not GroupWatchDB.lists[ns.selectedList] then
			ns.selectedList = ns.GetDefaultListName()
		end

		local yOffset = -5

		-- Cache commonly-used locale strings locally to avoid repeated table lookups
		local L_NO_PLAYERS_IN_LIST = L["NO_PLAYERS_IN_LIST"]

		-- Sort list names for a stable, deterministic UI order (default lists first)
		local listNames = {}
		for lName in pairs(GroupWatchDB.lists) do
			table_insert(listNames, lName)
		end
		table_sort(listNames, function(a, b)
			local aDefault = ns.IsDefaultList(a)
			local bDefault = ns.IsDefaultList(b)
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
				btn:SetScript("OnClick", function(selfBtn, button)
					local listName = btn.data.listName
					ns.selectedList = listName
					if button == "RightButton" then
						if MenuUtil and MenuUtil.CreateContextMenu then
							MenuUtil.CreateContextMenu(btn, function(ownerRegion, rootDescription)
								rootDescription:CreateTitle(listName)

								-- Rename Option
								rootDescription:CreateButton(L["RENAME_LIST"] or "Rename List", function()
									local dialog = StaticPopup_Show("GROUPWATCH_RENAME_LIST", listName)
									if dialog then
										dialog.data = listName
									end
								end)

								-- Delete Option
								local delBtn = rootDescription:CreateButton(L["DELETE_LIST"] or "Delete List", function()
									local dialog = StaticPopup_Show("GROUPWATCH_DELETE_LIST", listName)
									if dialog then
										dialog.data = listName
									end
								end)
								if ns.IsDefaultList(listName) then
									delBtn:SetEnabled(false)
								end

								-- Change Sound Alert Submenu
								local soundSubMenu =
									rootDescription:CreateButton(L["CHANGE_SOUND_ALERT"] or "Change Sound Alert")
								for _, soundOpt in ipairs(ns.SOUND_OPTIONS) do
									soundSubMenu:CreateButton(soundOpt.name, function()
										local ld = GroupWatchDB.lists[listName]
										if ld then
											ld.sound = soundOpt.id
											if soundOpt.id > 0 then
												PlaySound(soundOpt.id, "Master")
											end
											f:Refresh()
										end
									end)
								end
							end)
						end
					else
						f:Refresh()
					end
				end)
				btn:SetScript("OnReceiveDrag", function(selfBtn)
					local targetList = selfBtn.data.listName
					if TryMoveDraggedPlayer(targetList) then
						-- moved successfully; Refresh handled by MovePlayer
					end
					ClearDragVisuals()
				end)
				return btn
			end)
			headerRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
			headerRow:Show()
			headerRow.data = { listName = lName }

			-- Collapse/Expand button [−] / [+]
			local collapseBtn = ns.GetWidget("collapseBtn", function()
				local btn = CreateFrame("Button", nil, headerRow)
				btn:SetSize(18, 18)
				btn:SetPoint("LEFT", headerRow, "LEFT", 0, 0)
				btn:SetScript("OnClick", function(selfBtn)
					local ld = GroupWatchDB.lists[btn.data.listName]
					if ld then
						ld.collapsed = not ld.collapsed
						f:Refresh()
					end
				end)
				return btn
			end)
			collapseBtn.data = { listName = lName }
			collapseBtn:SetParent(headerRow)
			collapseBtn:SetPoint("LEFT", headerRow, "LEFT", 0, 0)
			collapseBtn:Show()

				local collapseText = collapseBtn.collapseText
				if not collapseText then
					collapseText = collapseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					collapseText:SetPoint("CENTER", collapseBtn, "CENTER", 0, 0)
					collapseBtn.collapseText = collapseText
				end
				collapseText:SetText(lData.collapsed and "|cffffd100[+]|r" or "|cffffd100[−]|r")

			ns.SkinButton(collapseBtn)

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
				if ns.skinEUI and ns.skinEUI.Font then
					ns.skinEUI.Font(headerText)
				end

			-- Sound dropdown button after title
			local soundBtn = ns.GetWidget("soundBtn", function()
				local btn = CreateFrame("Button", nil, headerRow, "UIPanelButtonTemplate")
				btn:SetSize(100, 20)
				btn:SetScript("OnClick", function(selfBtn)
					if MenuUtil and MenuUtil.CreateContextMenu then
						local listName = btn.data.listName
						MenuUtil.CreateContextMenu(btn, function(ownerRegion, rootDescription)
							for _, soundOpt in ipairs(ns.SOUND_OPTIONS) do
								rootDescription:CreateButton(soundOpt.name, function()
									local ld = GroupWatchDB.lists[listName]
									if ld then
										ld.sound = soundOpt.id
										btn:SetText(soundOpt.name)
										if soundOpt.id > 0 then
											PlaySound(soundOpt.id, "Master")
										end
										f:Refresh()
									end
								end)
							end
						end)
					end
				end)
				return btn
			end)
			soundBtn.data = { listName = lName }
			soundBtn:SetParent(headerRow)
			soundBtn:SetPoint("LEFT", headerText, "RIGHT", 8, 0)
			soundBtn:SetText(ns.GetSoundNameByID(lData.sound))
			soundBtn:Show()
			ns.SkinButton(soundBtn)

			-- (+) Button to add player to list
			local addPlayerBtn = ns.GetWidget("addPlayerBtn", function()
				local btn = CreateFrame("Button", nil, headerRow, "UIPanelButtonTemplate")
				btn:SetSize(22, 20)
				btn:SetText("|cff00ff00+|r")
				btn:SetScript("OnClick", function(selfBtn)
					local listName = btn.data.listName
					local dialog = StaticPopup_Show("GROUPWATCH_NEW_PLAYER")
					if dialog then
						dialog.data = listName
					end
				end)
				return btn
			end)
			addPlayerBtn.data = { listName = lName }
			addPlayerBtn:SetParent(headerRow)
			addPlayerBtn:SetPoint("TOP", headerRow, "TOP", 0, 0)
			addPlayerBtn:SetPoint("RIGHT", f, "RIGHT", -20, 0)
			addPlayerBtn:Show()
			ns.SkinButton(addPlayerBtn)

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
							btn:SetSize(270, 20)
							btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
							btn:RegisterForDrag("LeftButton")
							btn:SetScript("OnClick", function(selfBtn, button)
							if dragSourceRow == selfBtn then
								-- drag cancelled on this row; do not select it
								return
							end
								local pName = btn.data.playerName
								local lName = btn.data.listName
								ns.selectedPlayer = pName
								ns.selectedList = lName

								if button == "RightButton" then
									if MenuUtil and MenuUtil.CreateContextMenu then
										-- Re-resolve note at click time so it's current
										local ld = GroupWatchDB.lists[lName]
										local note = ld and ld.notes and ld.notes[pName]
										MenuUtil.CreateContextMenu(btn, function(ownerRegion, rootDescription)
											rootDescription:CreateTitle(pName)

											-- Edit Note
											rootDescription:CreateButton(L["EDIT_NOTE"] or "Edit Note", function()
												ns.ShowNoteEditor(pName, lName, note)
											end)

											-- Remove Player
											rootDescription:CreateButton(L["CONTEXT_REMOVE"] or "Remove Player", function()
												ns.RemovePlayer(pName, lName)
											end)

											-- Move To List Submenu
											local moveSubMenu =
												rootDescription:CreateButton(L["MOVE_TO_LIST"] or "Move to List")
											-- Copy To List Submenu
											local copySubMenu =
												rootDescription:CreateButton(L["COPY_TO_LIST"] or "Copy to List")

											for targetListName in pairs(GroupWatchDB.lists) do
												if targetListName ~= lName then
													moveSubMenu:CreateButton(targetListName, function()
														ns.MovePlayer(pName, lName, targetListName)
													end)
												end
												if
													not (
														GroupWatchDB.lists[targetListName].players
														and GroupWatchDB.lists[targetListName].players[pName]
													)
												then
													copySubMenu:CreateButton(targetListName, function()
														ns.CopyPlayer(pName, lName, targetListName)
													end)
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
							end)
							btn:SetScript("OnDragStop", function(selfBtn)
								ClearDragVisuals()
							end)
							btn:SetScript("OnReceiveDrag", function(selfBtn)
								local targetList = selfBtn.data.listName
								if TryMoveDraggedPlayer(targetList) then
									-- moved successfully; Refresh handled by MovePlayer
								end
								ClearDragVisuals()
							end)
							return btn
						end)
						row.data = { playerName = pName, listName = lName }
						row:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
						row:Show()

						local lineText = row.lineText
						if not lineText then
							lineText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
							lineText:SetPoint("LEFT", row, "LEFT", 0, 0)
							if ns.skinEUI and ns.skinEUI.Font then
								ns.skinEUI.Font(lineText)
							end
						end
						row.lineText = lineText
						if ns.selectedPlayer == pName then
							lineText:SetText("|cff00ff00• " .. pName .. "|r")
						else
							lineText:SetText("• " .. pName)
						end

						-- (−) Remove player button per row
						local del = ns.GetWidget("delBtn", function()
							local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
							btn:SetSize(22, 20)
							btn:SetText("|cffff5555−|r")
							btn:SetScript("OnClick", function(selfBtn)
								local pName = btn.data.playerName
								local lName = btn.data.listName
								ns.RemovePlayer(pName, lName)
							end)
							return btn
						end)
						del.data = { playerName = pName, listName = lName }
						del:SetPoint("RIGHT", addPlayerBtn, "RIGHT", 0, 0)
						del:SetPoint("TOP", row, "TOP", 0, 0)
						del:Show()
						ns.SkinButton(del)

						local noteBtn = ns.GetWidget("noteBtn", function()
							local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
							btn:SetSize(22, 20)
							btn:SetText("|cffd9b44aN|r")
							btn:SetScript("OnClick", function(selfBtn)
								local pName = btn.data.playerName
								local lName = btn.data.listName
								local ld = GroupWatchDB.lists[lName]
								local note = ld and ld.notes and ld.notes[pName]
								ns.ShowNoteEditor(pName, lName, note)
							end)
							btn:SetScript("OnEnter", function(selfBtn)
								local pName = btn.data.playerName
								local lName = btn.data.listName
								local ld = GroupWatchDB.lists[lName]
								local note = ld and ld.notes and ld.notes[pName]
								GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
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
						noteBtn.data = { playerName = pName, listName = lName }
						noteBtn:SetPoint("RIGHT", del, "LEFT", -2, 0)
						noteBtn:Show()
						ns.SkinButton(noteBtn)

						yOffset = yOffset - 24
					end
				end

				if count == 0 then
					-- One placeholder per empty list: a single shared font
					-- string would be moved around (and hidden again) by the
					-- next list, so only the last list would ever show it.
					local empty = ns.GetWidget("emptyText", function()
						local fs = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
						if ns.skinEUI and ns.skinEUI.Font then
							ns.skinEUI.Font(fs)
						end
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
	end

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
