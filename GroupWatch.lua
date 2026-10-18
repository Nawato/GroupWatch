local ADDON_NAME, ns = ...
local L = ns.L or setmetatable({}, {
	__index = function(t, k)
		return k
	end,
})

-- ---------------------------------------------------------------------------
-- Global function localization (Lua performance)
-- ---------------------------------------------------------------------------
local pairs = pairs
local ipairs = ipairs
local next = next
local type = type
local tostring = tostring
local strsplit = strsplit
local strtrim = strtrim
local string_format = string.format
local string_len = string.len
local string_gsub = string.gsub
local string_find = string.find
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local math_max = math.max
local math_min = math.min
local math_abs = math.abs
local math_rad = math.rad
local math_deg = math.deg
local math_cos = math.cos
local math_sin = math.sin
local math_atan2 = math.atan2
local tinsert = tinsert
local print = print
local PlaySound = PlaySound
local GetRealmName = GetRealmName
local GetNumGroupMembers = GetNumGroupMembers
local GetLocale = GetLocale
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local UnitName = UnitName
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local CreateFrame = CreateFrame
local UIParent = UIParent
local Minimap = Minimap
local GameTooltip = GameTooltip
local GetCursorPosition = GetCursorPosition
local C_Timer = C_Timer
local Menu = Menu
local MenuUtil = MenuUtil
local TooltipDataProcessor = TooltipDataProcessor
local TooltipUtil = TooltipUtil
local Enum = Enum
local C_BattleNet = C_BattleNet
local C_LFGList = C_LFGList
local IsLoggedIn = IsLoggedIn
local hooksecurefunc = hooksecurefunc
local StaticPopup_Show = StaticPopup_Show
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local pcall = pcall
local select = select
local CollectGarbage = collectgarbage

local DEFAULT_SOUND = 8959

-- Available sound options
local SOUND_OPTIONS = {
	{ name = L["SOUND_WARNING"], id = 8959 },
	{ name = L["SOUND_RAID_WARNING"], id = 12867 },
	{ name = L["SOUND_BELL"], id = 8960 },
	{ name = L["SOUND_WHISTLE"], id = 8958 },
	{ name = L["SOUND_READY_CHECK"], id = 8960 },
	{ name = L["SOUND_COIN"], id = 865 },
	{ name = L["SOUND_ACHIEVEMENT"], id = 12891 },
	{ name = L["SOUND_EXPLOSION"], id = 8957 },
	{ name = L["SOUND_NONE"], id = 0 },
}

local function GetSoundNameByID(soundID)
	for _, s in ipairs(SOUND_OPTIONS) do
		if s.id == soundID then
			return s.name
		end
	end
	return string_format(L["SOUND_CUSTOM"], soundID or 0)
end

local function GetDefaultListName()
	if GroupWatchDB and GroupWatchDB.lists then
		if GroupWatchDB.lists[L["DEFAULT_LIST_NAME"]] then
			return L["DEFAULT_LIST_NAME"]
		end
		if GroupWatchDB.lists["Standard"] then
			return "Standard"
		end
		if GroupWatchDB.lists["Default"] then
			return "Default"
		end
		for name in pairs(GroupWatchDB.lists) do
			return name
		end
	end
	return L["DEFAULT_LIST_NAME"]
end

local function IsDefaultList(listName)
	return listName == "Standard" or listName == "Default" or listName == L["DEFAULT_LIST_NAME"]
end

-- Initialize database
local function InitDB()
	if not GroupWatchDB then
		GroupWatchDB = {}
	end
	if not GroupWatchDB.lists then
		local defName = L["DEFAULT_LIST_NAME"]
		GroupWatchDB.lists = {
			[defName] = {
				message = L["DEFAULT_GROUP_MSG"],
				sound = DEFAULT_SOUND,
				collapsed = false,
				players = {},
			},
		}
	end
	if not GroupWatchDB.minimap then
		GroupWatchDB.minimap = {
			hide = false,
			angle = 225,
		}
	end

	for _, listData in pairs(GroupWatchDB.lists) do
		listData.notes = listData.notes or {}
	end
end

local function GetFullName(unitOrName)
	if not unitOrName or unitOrName == "" then
		return nil
	end
	unitOrName = tostring(unitOrName):gsub("%*", "")
	local name, realm = strsplit("-", unitOrName, 2)
	if not name or name == "" then
		return nil
	end
	name = strtrim(name)
	if name == "" then
		return nil
	end
	if not realm or realm == "" then
		realm = GetRealmName():gsub("%s+", "")
	else
		realm = strtrim(realm):gsub("%s+", "")
	end
	return name .. "-" .. realm
end

----------------------------------------------------
-- UI WINDOW & LOGIC
----------------------------------------------------
local GroupWatchUI = nil
local selectedPlayer = nil
local selectedList = nil

local function AddPlayer(listName, fullName)
	if not fullName or fullName == "" then
		return
	end
	fullName = GetFullName(fullName)
	if not fullName then
		return
	end

	InitDB()
	listName = listName or GetDefaultListName()
	if not GroupWatchDB.lists[listName] then
		print("|cffffaa00[GroupWatch]|r " .. string_format(L["MSG_LIST_NOT_FOUND"], listName))
		return
	end

	GroupWatchDB.lists[listName].players[fullName] = true
	GroupWatchDB.lists[listName].notes = GroupWatchDB.lists[listName].notes or {}
	print("|cff00ff00[GroupWatch]|r " .. string_format(L["MSG_PLAYER_ADDED"], fullName, listName))
	if GroupWatchUI and GroupWatchUI:IsShown() then
		GroupWatchUI:Refresh()
	end
end

local function RemovePlayer(fullName, listName)
	if not fullName or fullName == "" then
		return
	end
	fullName = GetFullName(fullName)
	if not fullName then
		return
	end

	InitDB()
	for lName, lData in pairs(GroupWatchDB.lists) do
		if not listName or listName == lName then
			if lData.players[fullName] then
				lData.players[fullName] = nil
				if lData.notes then
					lData.notes[fullName] = nil
				end
				print("|cffff0000[GroupWatch]|r " .. string_format(L["MSG_PLAYER_REMOVED"], fullName, lName))
			end
		end
	end
	if selectedPlayer == fullName then
		selectedPlayer = nil
	end
	if GroupWatchUI and GroupWatchUI:IsShown() then
		GroupWatchUI:Refresh()
	end
end

local function CreateList(listName)
	if not listName or listName == "" then
		return
	end
	InitDB()
	if GroupWatchDB.lists[listName] then
		print("|cffffaa00[GroupWatch]|r " .. string_format(L["MSG_LIST_EXISTS"], listName))
		return
	end

	GroupWatchDB.lists[listName] = {
		message = L["DEFAULT_GROUP_MSG"],
		sound = DEFAULT_SOUND,
		collapsed = false,
		players = {},
		notes = {},
	}
	selectedList = listName
	print("|cff00ff00[GroupWatch]|r " .. string_format(L["MSG_LIST_CREATED"], listName))
	if GroupWatchUI and GroupWatchUI:IsShown() then
		GroupWatchUI:Refresh()
	end
end

local function RenameList(oldName, newName)
	if not oldName or not newName or oldName == "" or newName == "" then
		return
	end
	if oldName == newName then
		return
	end

	InitDB()
	if not GroupWatchDB.lists[oldName] then
		print("|cffffaa00[GroupWatch]|r " .. string_format(L["MSG_LIST_NOT_FOUND"], oldName))
		return
	end

	if GroupWatchDB.lists[newName] then
		print("|cffffaa00[GroupWatch]|r " .. string_format(L["MSG_LIST_EXISTS"], newName))
		return
	end

	-- Migrate list structure, preserving players and note history
	GroupWatchDB.lists[newName] = GroupWatchDB.lists[oldName]
	GroupWatchDB.lists[oldName] = nil

	if selectedList == oldName then
		selectedList = newName
	end

	if GroupWatchUI and GroupWatchUI:IsShown() then
		GroupWatchUI:Refresh()
	end
end

local function MovePlayer(pName, sourceList, targetList)
	InitDB()
	if not GroupWatchDB.lists[sourceList] or not GroupWatchDB.lists[targetList] then
		return
	end

	GroupWatchDB.lists[sourceList].players = GroupWatchDB.lists[sourceList].players or {}
	GroupWatchDB.lists[targetList].players = GroupWatchDB.lists[targetList].players or {}
	local note = GroupWatchDB.lists[sourceList].notes and GroupWatchDB.lists[sourceList].notes[pName]

	-- Remove from source
	GroupWatchDB.lists[sourceList].players[pName] = nil
	if GroupWatchDB.lists[sourceList].notes then
		GroupWatchDB.lists[sourceList].notes[pName] = nil
	end

	-- Add to target
	GroupWatchDB.lists[targetList].players[pName] = true
	if note then
		GroupWatchDB.lists[targetList].notes = GroupWatchDB.lists[targetList].notes or {}
		GroupWatchDB.lists[targetList].notes[pName] = note
	end

	if GroupWatchUI and GroupWatchUI:IsShown() then
		GroupWatchUI:Refresh()
	end
end

local function CopyPlayer(pName, sourceList, targetList)
	InitDB()
	if not GroupWatchDB.lists[sourceList] or not GroupWatchDB.lists[targetList] then
		return
	end

	local note = GroupWatchDB.lists[sourceList].notes and GroupWatchDB.lists[sourceList].notes[pName]

	-- Add to target
	GroupWatchDB.lists[targetList].players[pName] = true
	if note then
		GroupWatchDB.lists[targetList].notes = GroupWatchDB.lists[targetList].notes or {}
		GroupWatchDB.lists[targetList].notes[pName] = note
	end

	if GroupWatchUI and GroupWatchUI:IsShown() then
		GroupWatchUI:Refresh()
	end
end
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
	MovePlayer(dragSourcePlayer, dragSourceList, targetList)
	return true
end

local function ClearDragVisuals()
	if dragSourceRow then
		dragSourceRow:SetAlpha(1.0)
		dragSourceRow = nil
	end
end

local function SavePlayerNote(listName, playerName, note)
	InitDB()
	local listData = GroupWatchDB.lists[listName]
	if not listData or not listData.players or not listData.players[playerName] then
		return
	end

	listData.notes = listData.notes or {}
	note = (note or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if note == "" then
		listData.notes[playerName] = nil
	else
		listData.notes[playerName] = note
	end

	if GroupWatchUI and GroupWatchUI:IsShown() then
		GroupWatchUI:Refresh()
	end
end

local function DeleteList(listName)
	if not listName or listName == "" then
		return
	end
	if IsDefaultList(listName) then
		print("|cffff0000[GroupWatch]|r " .. L["MSG_CANNOT_DELETE_DEFAULT"])
		return
	end

	InitDB()
	if GroupWatchDB.lists[listName] then
		GroupWatchDB.lists[listName] = nil
		print("|cffff0000[GroupWatch]|r " .. string_format(L["MSG_LIST_DELETED"], listName))
		selectedList = GetDefaultListName()
		if GroupWatchUI and GroupWatchUI:IsShown() then
			GroupWatchUI:Refresh()
		end
	end
end

----------------------------------------------------
-- POPUP DIALOGS
----------------------------------------------------
StaticPopupDialogs["GROUPWATCH_NEW_PLAYER"] = {
	text = L["DIALOG_ADD_PLAYER_TEXT"],
	button1 = L["DIALOG_ADD"],
	button2 = L["DIALOG_CANCEL"],
	hasEditBox = true,
	OnAccept = function(self)
		local text = self.EditBox:GetText()
		if text and text ~= "" then
			local targetList = self.data or selectedList or GetDefaultListName()
			AddPlayer(targetList, text)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetText()
		if text and text ~= "" then
			local parent = self:GetParent()
			local targetList = parent.data or selectedList or GetDefaultListName()
			AddPlayer(targetList, text)
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
			CreateList(text)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetText()
		if text and text ~= "" then
			CreateList(text)
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
			RenameList(data, newName)
		end
	end,
	EditBoxOnEnterPressed = function(self, data)
		local newName = self:GetText()
		local parent = self:GetParent()
		local oldName = parent.data or data
		if newName and newName ~= "" and oldName then
			RenameList(oldName, newName)
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
		DeleteList(data)
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

----------------------------------------------------
-- SKINNING (EllesmereUI & ElvUI)
----------------------------------------------------
local skinEUI = nil

local function IsElvUIPresent()
	return (ElvUI and ElvUI[1] and ElvUI[1]:GetModule("Skins")) and true or false
end

local function GetElvUISkins()
	if ElvUI and ElvUI[1] then
		return ElvUI[1]:GetModule("Skins")
	end
end

local function SkinButton(btn)
	if not btn then
		return
	end
	if skinEUI and skinEUI.Button then
		skinEUI.Button(btn)
	elseif IsElvUIPresent() then
		local S = GetElvUISkins()
		if S and S.HandleButton then
			S:HandleButton(btn)
		end
	end
end

local function SkinCloseButton(btn)
	if not btn then
		return
	end
	if skinEUI and skinEUI.CloseButton then
		skinEUI.CloseButton(btn)
	elseif IsElvUIPresent() then
		local S = GetElvUISkins()
		if S and S.HandleCloseButton then
			S:HandleCloseButton(btn)
		end
	end
end

local function SkinScrollBar(sb)
	if not sb then
		return
	end
	if skinEUI and skinEUI.ScrollBar then
		skinEUI.ScrollBar(sb)
	elseif IsElvUIPresent() then
		local S = GetElvUISkins()
		if S and S.HandleScrollBar then
			S:HandleScrollBar(sb)
		end
	end
end

local function SkinWindow(f)
	if not f then
		return
	end

	if skinEUI and skinEUI.Shell then
		if f.ClearBackdrop then
			f:ClearBackdrop()
		elseif f.SetBackdrop then
			f:SetBackdrop(nil)
		end
		skinEUI.Shell(f)
		if f.title and skinEUI.Font then
			skinEUI.Font(f.title)
		end
		if f.listLabel and skinEUI.Font then
			skinEUI.Font(f.listLabel)
		end
	elseif IsElvUIPresent() then
		local S = GetElvUISkins()
		if f.ClearBackdrop then
			f:ClearBackdrop()
		elseif f.SetBackdrop then
			f:SetBackdrop(nil)
		end
		if S and S.HandleFrame then
			S:HandleFrame(f, true)
		else
			if f.StripTextures then
				f:StripTextures()
			end
			if f.SetTemplate then
				f:SetTemplate("Transparent")
			elseif f.CreateBackdrop then
				f:CreateBackdrop("Transparent")
			end
		end
	end

	if f.closeBtn then
		SkinCloseButton(f.closeBtn)
	end
	if f.scrollBar then
		SkinScrollBar(f.scrollBar)
	end
	if f.newListBtn then
		SkinButton(f.newListBtn)
	end
	if f.delListBtn then
		SkinButton(f.delListBtn)
	end
end

-- EllesmereUI skin registration
if EllesmereUI and EllesmereUI.RegisterSkin then
	EllesmereUI.RegisterSkin("GroupWatch", function(S)
		skinEUI = S
		if GroupWatchUI then
			SkinWindow(GroupWatchUI)
			GroupWatchUI:Refresh()
		end
	end)
end

----------------------------------------------------
-- WIDGET POOL (recycle frames instead of recreating each Refresh)
-- ---------------------------------------------------------------------------
-- Instead of CreateFrame-ing every header/row/button on each Refresh() and
-- merely hiding the old ones, we create each widget once and reuse it. Widgets
-- store their dynamic data in a .data table so a single script closure can
-- serve all widgets of a given kind. This eliminates garbage and frame bloat.
-- ---------------------------------------------------------------------------
local widgetPools = {}
local widgetMaster = {}

local function GetWidget(poolName, createFunc)
	local pool = widgetPools[poolName]
	if not pool then
		pool = {}
		widgetPools[poolName] = pool
	end
	for _, w in ipairs(pool) do
		if not w.inUse then
			w.inUse = true
			return w
		end
	end
	local w = createFunc()
	w.inUse = true
	table_insert(pool, w)
	table_insert(widgetMaster, w)
	return w
end

local function ReleaseUnused()
	for _, pool in pairs(widgetPools) do
		for _, w in ipairs(pool) do
			if w.inUse then
				w.inUse = false
			else
				w:Hide()
			end
		end
	end
end

----------------------------------------------------
-- CUSTOM NOTE EDITOR FRAME
----------------------------------------------------
local NoteEditorFrame = nil

local function ShowNoteEditor(playerName, listName, existingNote)
	if not NoteEditorFrame then
		local frame = CreateFrame("Frame", "GroupWatchNoteEditor", UIParent, "BackdropTemplate")
		frame:SetSize(420, 320)
		frame:SetPoint("CENTER")
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
		frame:SetClampedToScreen(true)
		frame:SetFrameStrata("DIALOG")
		frame:SetFrameLevel(100)

		if not (skinEUI or IsElvUIPresent()) then
			frame:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true,
				tileSize = 32,
				edgeSize = 32,
				insets = { left = 8, right = 8, top = 8, bottom = 8 },
			})
		end

		-- Title
		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOP", frame, "TOP", 0, -14)
		title:SetText("")
		frame.title = title

		-- Close button
		local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
		closeBtn:SetScript("OnClick", function()
			frame:Hide()
		end)
		frame.closeBtn = closeBtn

		-- Scroll frame for multiline note input
		local scrollFrame = CreateFrame("ScrollFrame", "GroupWatchNoteScrollFrame", frame, "UIPanelScrollFrameTemplate")
		scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -45)
		scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 50)

		local editBox = CreateFrame("EditBox", "GroupWatchNoteEditBox", scrollFrame)
		editBox:SetMultiLine(true)
		editBox:SetAutoFocus(true)
		editBox:SetFontObject(ChatFontNormal)
		editBox:SetWidth(345)
		editBox:SetScript("OnEscapePressed", function()
			frame:Hide()
		end)

		editBox:SetScript("OnEnterPressed", function(self)
			self:Insert("\n")
		end)

		-- Cache font height once; only recompute line count on text change
		local editFont = editBox:GetFontObject()
		editBox:SetScript("OnTextChanged", function(self)
			local _, h = editFont:GetFont()
			local text = self:GetText() or ""
			local numLines = select(2, string_gsub(text, "\n", "\n")) + 1
			local lineHeight = h and (h + 2) or 14
			local textHeight = math_max(numLines * lineHeight + 20, scrollFrame:GetHeight())
			self:SetHeight(textHeight)
		end)

		scrollFrame:SetScrollChild(editBox)
		frame.scrollFrame = scrollFrame
		frame.editBox = editBox

		-- Save button
		local saveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		saveBtn:SetSize(100, 24)
		saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -6, 16)
		saveBtn:SetText(L["DIALOG_SAVE"])
		saveBtn:SetScript("OnClick", function()
			if frame.noteData then
				SavePlayerNote(frame.noteData.listName, frame.noteData.playerName, frame.editBox:GetText())
			end
			frame:Hide()
		end)
		frame.saveBtn = saveBtn

		-- Cancel button
		local cancelBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		cancelBtn:SetSize(100, 24)
		cancelBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 6, 16)
		cancelBtn:SetText(L["DIALOG_CANCEL"])
		cancelBtn:SetScript("OnClick", function()
			frame:Hide()
		end)
		frame.cancelBtn = cancelBtn

		-- Skin Elements
		SkinCloseButton(closeBtn)
		SkinButton(saveBtn)
		SkinButton(cancelBtn)
		if skinEUI and skinEUI.Shell then
			if frame.ClearBackdrop then
				frame:ClearBackdrop()
			elseif frame.SetBackdrop then
				frame:SetBackdrop(nil)
			end
			skinEUI.Shell(frame)
			if skinEUI.Font then
				skinEUI.Font(title)
			end
		elseif IsElvUIPresent() then
			local S = GetElvUISkins()
			if frame.ClearBackdrop then
				frame:ClearBackdrop()
			elseif frame.SetBackdrop then
				frame:SetBackdrop(nil)
			end
			if S and S.HandleFrame then
				S:HandleFrame(frame, true)
			else
				if frame.StripTextures then
					frame:StripTextures()
				end
				if frame.SetTemplate then
					frame:SetTemplate("Transparent")
				elseif frame.CreateBackdrop then
					frame:CreateBackdrop("Transparent")
				end
			end
		end
		if scrollFrame.ScrollBar then
			SkinScrollBar(scrollFrame.ScrollBar)
		end

		tinsert(UISpecialFrames, "GroupWatchNoteEditor")
		NoteEditorFrame = frame
	end

	local f = NoteEditorFrame
	f.noteData = { listName = listName, playerName = playerName }
	f.title:SetText(string_format(L["DIALOG_EDIT_NOTE_TEXT"], playerName))
	f.editBox:SetText(existingNote or "")
	f.editBox:SetCursorPosition(string_len(existingNote or ""))

	C_Timer.After(0, function()
		if f.scrollFrame:GetWidth() > 0 then
			f.editBox:SetWidth(f.scrollFrame:GetWidth() - 10)
		end
	end)
	f:Show()
	f.editBox:SetFocus()
end

----------------------------------------------------
-- MAIN UI
----------------------------------------------------
local function CreateUI()
	if GroupWatchUI then
		return GroupWatchUI
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

	if not (skinEUI or IsElvUIPresent()) then
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 },
		})
	end

	-- Title bar
	local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOP", f, "TOP", 0, -12)
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
		if IsDefaultList(selectedList) then
			print("|cffff0000[GroupWatch]|r " .. L["MSG_CANNOT_DELETE_DEFAULT"])
		else
			local dialog = StaticPopup_Show("GROUPWATCH_DELETE_LIST", selectedList)
			if dialog then
				dialog.data = selectedList
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
	SkinWindow(f)

	----------------------------------------------------
	-- RENDER LIST (widget-pooled)
	----------------------------------------------------
	function f:Refresh()
		ReleaseUnused()

		if not GroupWatchDB or not GroupWatchDB.lists then
			return
		end

		if not selectedList or not GroupWatchDB.lists[selectedList] then
			selectedList = GetDefaultListName()
		end

		local yOffset = -5

		-- Cache commonly-used locale strings locally to avoid repeated table lookups
		local L_DEFAULT_LIST_NAME = L["DEFAULT_LIST_NAME"]
		local L_NO_PLAYERS_IN_LIST = L["NO_PLAYERS_IN_LIST"]

		-- Sort list names for a stable, deterministic UI order (default lists first)
		local listNames = {}
		for lName in pairs(GroupWatchDB.lists) do
			table_insert(listNames, lName)
		end
		table_sort(listNames, function(a, b)
			local aDefault = IsDefaultList(a)
			local bDefault = IsDefaultList(b)
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
			local headerRow = GetWidget("headerRow", function()
				local btn = CreateFrame("Button", nil, content)
				btn:SetSize(340, 22)
				btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				btn:SetScript("OnClick", function(selfBtn, button)
					local listName = btn.data.listName
					selectedList = listName
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
								if IsDefaultList(listName) then
									delBtn:SetEnabled(false)
								end

								-- Change Sound Alert Submenu
								local soundSubMenu =
									rootDescription:CreateButton(L["CHANGE_SOUND_ALERT"] or "Change Sound Alert")
								for _, soundOpt in ipairs(SOUND_OPTIONS) do
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
			local collapseBtn = GetWidget("collapseBtn", function()
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

			SkinButton(collapseBtn)

			-- List title — white when selected, dim gold otherwise
				local headerText = headerRow.headerText
				if not headerText then
					headerText = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
					headerText:SetPoint("LEFT", collapseBtn, "RIGHT", 6, 0)
					headerRow.headerText = headerText
				end
				if selectedList == lName then
					headerText:SetText("|cffffffff" .. lName .. "|r")
				else
					headerText:SetText("|cffaaaaaa" .. lName .. "|r")
				end
				if skinEUI and skinEUI.Font then
					skinEUI.Font(headerText)
				end

			-- Sound dropdown button after title
			local soundBtn = GetWidget("soundBtn", function()
				local btn = CreateFrame("Button", nil, headerRow, "UIPanelButtonTemplate")
				btn:SetSize(100, 20)
				btn:SetScript("OnClick", function(selfBtn)
					if MenuUtil and MenuUtil.CreateContextMenu then
						local listName = btn.data.listName
						MenuUtil.CreateContextMenu(btn, function(ownerRegion, rootDescription)
							for _, soundOpt in ipairs(SOUND_OPTIONS) do
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
			soundBtn:SetText(GetSoundNameByID(lData.sound))
			soundBtn:Show()
			SkinButton(soundBtn)

			-- (+) Button to add player to list
			local addPlayerBtn = GetWidget("addPlayerBtn", function()
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
			SkinButton(addPlayerBtn)

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

						local row = GetWidget("playerRow", function()
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
								selectedPlayer = pName
								selectedList = lName

								if button == "RightButton" then
									if MenuUtil and MenuUtil.CreateContextMenu then
										-- Re-resolve note at click time so it's current
										local ld = GroupWatchDB.lists[lName]
										local note = ld and ld.notes and ld.notes[pName]
										MenuUtil.CreateContextMenu(btn, function(ownerRegion, rootDescription)
											rootDescription:CreateTitle(pName)

											-- Edit Note
											rootDescription:CreateButton(L["EDIT_NOTE"] or "Edit Note", function()
												ShowNoteEditor(pName, lName, note)
											end)

											-- Remove Player
											rootDescription:CreateButton(L["CONTEXT_REMOVE"] or "Remove Player", function()
												RemovePlayer(pName, lName)
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
														MovePlayer(pName, lName, targetListName)
													end)
												end
												if
													not (
														GroupWatchDB.lists[targetListName].players
														and GroupWatchDB.lists[targetListName].players[pName]
													)
												then
													copySubMenu:CreateButton(targetListName, function()
														CopyPlayer(pName, lName, targetListName)
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
							if skinEUI and skinEUI.Font then
								skinEUI.Font(lineText)
							end
						end
						row.lineText = lineText
						if selectedPlayer == pName then
							lineText:SetText("|cff00ff00• " .. pName .. "|r")
						else
							lineText:SetText("• " .. pName)
						end

						-- (−) Remove player button per row
						local del = GetWidget("delBtn", function()
							local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
							btn:SetSize(22, 20)
							btn:SetText("|cffff5555−|r")
							btn:SetScript("OnClick", function(selfBtn)
								local pName = btn.data.playerName
								local lName = btn.data.listName
								RemovePlayer(pName, lName)
							end)
							return btn
						end)
						del.data = { playerName = pName, listName = lName }
						del:SetPoint("RIGHT", addPlayerBtn, "RIGHT", 0, 0)
						del:SetPoint("TOP", row, "TOP", 0, 0)
						del:Show()
						SkinButton(del)

						local noteBtn = GetWidget("noteBtn", function()
							local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
							btn:SetSize(22, 20)
							btn:SetText("|cffd9b44aN|r")
							btn:SetScript("OnClick", function(selfBtn)
								local pName = btn.data.playerName
								local lName = btn.data.listName
								local ld = GroupWatchDB.lists[lName]
								local note = ld and ld.notes and ld.notes[pName]
								ShowNoteEditor(pName, lName, note)
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
						SkinButton(noteBtn)

						yOffset = yOffset - 24
					end
				end

				if count == 0 then
					local empty = content.emptyText
					if not empty then
						empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
						if skinEUI and skinEUI.Font then
							skinEUI.Font(empty)
						end
					end
					content.emptyText = empty
					empty:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
					empty:SetText(L_NO_PLAYERS_IN_LIST)
					empty:Show()
					yOffset = yOffset - 22
				else
					if content.emptyText then
						content.emptyText:Hide()
					end
				end
			end

			yOffset = yOffset - 14
		end

		content:SetHeight(math_abs(yOffset) + 20)
	end

	tinsert(UISpecialFrames, "GroupWatchMainWindow")
	GroupWatchUI = f
	f:Hide()
	return f
end

local function ToggleUI()
	local ui = CreateUI()
	if ui:IsShown() then
		ui:Hide()
	else
		ui:Refresh()
		ui:Show()
	end
end

----------------------------------------------------
-- MINIMAP BUTTON & LDB
----------------------------------------------------
local MinimapButton = nil
local BUTTON_RADIUS = 102

local function UpdateMinimapButtonPosition()
	if not MinimapButton or not GroupWatchDB or not GroupWatchDB.minimap then
		return
	end
	local angle = math_rad(GroupWatchDB.minimap.angle or 225)
	local x = math_cos(angle) * BUTTON_RADIUS
	local y = math_sin(angle) * BUTTON_RADIUS
	MinimapButton:ClearAllPoints()
	MinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function UpdateMinimapButtonDrag()
	if not Minimap or not MinimapButton then
		return
	end
	local mx, my = Minimap:GetCenter()
	if not mx or not my then
		return
	end
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale() or (UIParent and UIParent:GetEffectiveScale()) or 1
	px = px / scale
	py = py / scale

	local angle = math_deg(math_atan2(py - my, px - mx))
	if angle < 0 then
		angle = angle + 360
	end

	InitDB()
	GroupWatchDB.minimap.angle = angle
	UpdateMinimapButtonPosition()
end

local function SetMinimapButtonShown(show)
	InitDB()
	GroupWatchDB.minimap.hide = not show
	if MinimapButton then
		if show then
			MinimapButton:Show()
			UpdateMinimapButtonPosition()
		else
			MinimapButton:Hide()
		end
	end
end

local function CreateMinimapButton()
	if MinimapButton then
		return MinimapButton
	end
	InitDB()

	local btn = CreateFrame("Button", "GroupWatchMinimapButton", Minimap)
	btn:SetSize(31, 31)
	btn:SetFrameStrata("MEDIUM")
	btn:SetFrameLevel(8)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	btn:RegisterForDrag("LeftButton")
	btn:SetMovable(true)
	btn:SetClampedToScreen(true)

	local icon = btn:CreateTexture(nil, "ARTWORK")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER", 0, 0)
	-- Set custom addon icon path
	icon:SetTexture("Interface\\AddOns\\GroupWatch\\Media\\icon_gw_wei.png")
	icon:SetTexCoord(0, 1, 0, 1)

	local overlay = btn:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetSize(53, 53)
	overlay:SetPoint("TOPLEFT", 0, 0)

	local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	highlight:SetBlendMode("ADD")
	highlight:SetSize(31, 31)
	highlight:SetPoint("CENTER", 0, 0)

	btn.icon = icon
	btn.overlay = overlay
	btn.highlight = highlight

	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("|cff00ccffGroupWatch|r")
		GameTooltip:AddLine(L["TOOLTIP_LEFT_CLICK"])
		GameTooltip:AddLine(L["TOOLTIP_RIGHT_CLICK"])
		GameTooltip:AddLine(L["TOOLTIP_DRAG"])
		GameTooltip:Show()
	end)

	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	btn:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			if MenuUtil and MenuUtil.CreateContextMenu then
				MenuUtil.CreateContextMenu(self, function(ownerRegion, rootDescription)
					rootDescription:CreateTitle("GroupWatch")
					rootDescription:CreateButton(L["TOOLTIP_OPEN_WINDOW"], function()
						ToggleUI()
					end)
					rootDescription:CreateDivider()
					for lName, lData in pairs(GroupWatchDB.lists) do
						local count = 0
						if lData.players then
							for _ in pairs(lData.players) do
								count = count + 1
							end
						end
						rootDescription:CreateTitle(string_format(L["TOOLTIP_PLAYERS_COUNT"], lName, count))
					end
				end)
			else
				ToggleUI()
			end
		else
			ToggleUI()
		end
	end)

	btn:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", UpdateMinimapButtonDrag)
	end)

	btn:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
		UpdateMinimapButtonDrag()
	end)

	MinimapButton = btn

	if GroupWatchDB.minimap.hide then
		btn:Hide()
	else
		btn:Show()
		UpdateMinimapButtonPosition()
	end

	return btn
end

local function RegisterLDB()
	local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
	if ldb and not ldb:GetDataObjectByName("GroupWatch") then
		ldb:NewDataObject("GroupWatch", {
			type = "launcher",
			text = "GroupWatch",
			icon = "Interface\\AddOns\\GroupWatch\\Media\\icon_gw_wei.png",
			OnClick = function(_, mouseBtn)
				if mouseBtn == "LeftButton" then
					ToggleUI()
				end
			end,
			OnTooltipShow = function(tooltip)
				tooltip:AddLine("|cff00ccffGroupWatch|r")
				tooltip:AddLine(L["TOOLTIP_LEFT_CLICK"], 1, 1, 1)
			end,
		})
	end
end

----------------------------------------------------
-- LOGIC & EVENTS
----------------------------------------------------
local function CheckGroup()
	if not IsInGroup() or not GroupWatchDB or not GroupWatchDB.lists then
		return
	end

	local numMembers = GetNumGroupMembers()
	local prefix = IsInRaid() and "raid" or "party"

	-- Build a reverse index: fullName -> { listName, ... } so we don't scan
	-- every list for every group member (O(members * lists) -> O(members + hits)).
	local watched = {}
	for lName, lData in pairs(GroupWatchDB.lists) do
		if lData.players then
			for pName in pairs(lData.players) do
				if not watched[pName] then
					watched[pName] = {}
				end
				table_insert(watched[pName], lName)
			end
		end
	end

	if next(watched) == nil then
		return
	end

	local L_DEFAULT_GROUP_MSG = L["DEFAULT_GROUP_MSG"]

	for i = 1, numMembers do
		local unit = (prefix == "party" and i == numMembers) and "player" or (prefix .. i)
		local name, realm = UnitName(unit)

		if name and unit ~= "player" then
			if not realm or realm == "" then
				realm = GetRealmName():gsub("%s+", "")
			end
			local fullName = name .. "-" .. realm

			local lists = watched[fullName]
			if lists then
				for _, lName in ipairs(lists) do
					local lData = GroupWatchDB.lists[lName]
					if lData then
						local outMsg = string_format(lData.message or L_DEFAULT_GROUP_MSG, fullName)
						print("|cffff0000[GroupWatch - " .. lName .. "]|r " .. outMsg)
						if lData.sound and lData.sound > 0 then
							PlaySound(lData.sound, "Master")
						end
					end
				end
			end
		end
	end
end

local mainEventFrame = CreateFrame("Frame")
mainEventFrame:RegisterEvent("ADDON_LOADED")
mainEventFrame:RegisterEvent("PLAYER_LOGIN")
mainEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
mainEventFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "GroupWatch" then
		InitDB()
		CreateMinimapButton()
		RegisterLDB()
	elseif event == "PLAYER_LOGIN" then
		if GroupWatchUI and (skinEUI or IsElvUIPresent()) then
			SkinWindow(GroupWatchUI)
			GroupWatchUI:Refresh()
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		CheckGroup()
	end
end)

----------------------------------------------------
-- CHAT COMMANDS
----------------------------------------------------
SLASH_GROUPWATCH1 = "/gw"
SLASH_GROUPWATCH2 = "/groupwatch"

-- localize string.lower once
local string_lower = string.lower

SlashCmdList["GROUPWATCH"] = function(msg)
	InitDB()
	local arg1, arg2, arg3 = strsplit(" ", msg or "", 3)
	arg1 = string_lower(arg1 or "")

	if arg1 == "list" or arg1 == "ui" or arg1 == "" then
		ToggleUI()
	elseif arg1 == "map" or arg1 == "minimap" then
		local willHide = not (GroupWatchDB.minimap and GroupWatchDB.minimap.hide)
		SetMinimapButtonShown(not willHide)
		print(
			"|cff00ccff[GroupWatch]|r "
				.. (
					willHide and "|cffff0000" .. L["MINIMAP_DISABLED"] .. "|r"
					or "|cff00ff00" .. L["MINIMAP_ENABLED"] .. "|r"
				)
		)
	elseif arg1 == "add" and arg2 and arg3 then
		AddPlayer(arg2, arg3)
	elseif arg1 == "remove" and arg2 then
		RemovePlayer(arg2, arg3)
	else
		print("|cff00ccff[GroupWatch]|r " .. L["HELP_HEADER"])
		print(" " .. L["HELP_TOGGLE"])
		print(" " .. L["HELP_MAP"])
		print(" " .. L["HELP_ADD"])
		print(" " .. L["HELP_REMOVE"])
	end
end

----------------------------------------------------
-- CONTEXT MENU (Right-click)
----------------------------------------------------
local function GetPlayerFullNameFromUnit(unit)
	if not unit then
		return nil
	end
	local ok, isPlayer = pcall(UnitIsPlayer, unit)
	if not ok or not isPlayer then
		return nil
	end

	local okName, name, realm = pcall(UnitName, unit)
	if not okName or not name or name == "" then
		return nil
	end
	name = strtrim(name)
	if name == "" then
		return nil
	end
	if not realm or realm == "" then
		realm = GetRealmName():gsub("%s+", "")
	else
		realm = strtrim(realm):gsub("%s+", "")
	end
	return name .. "-" .. realm
end

local function GetPlayerFullNameFromContext(contextData)
	if not contextData then
		return nil
	end

	if contextData.unit then
		local fullName = GetPlayerFullNameFromUnit(contextData.unit)
		if fullName then
			return fullName
		end
	end

	local name = contextData.name
	local server = contextData.server or contextData.realm
	if name and name ~= "" then
		name = tostring(name):gsub("%*", "")
		name = strtrim(name)
		if not name:find("#") then
			if server and server ~= "" and not name:find("-") then
				server = strtrim(server):gsub("%s+", "")
				return name .. "-" .. server
			else
				return GetFullName(name)
			end
		end
	end

	local bnetID = contextData.bnetAccountID
	local accountInfo = contextData.accountInfo
	if not accountInfo and bnetID and C_BattleNet and C_BattleNet.GetAccountInfoByID then
		accountInfo = C_BattleNet.GetAccountInfoByID(bnetID)
	end
	if accountInfo and accountInfo.gameAccountInfo then
		local gameInfo = accountInfo.gameAccountInfo
		local charName = gameInfo.characterName
		local realmName = gameInfo.realmName
		if charName and charName ~= "" then
			charName = strtrim(charName)
			if not realmName or realmName == "" then
				realmName = GetRealmName():gsub("%s+", "")
			else
				realmName = strtrim(realmName):gsub("%s+", "")
			end
			return charName .. "-" .. realmName
		end
	end

	if contextData.memberInfo and contextData.memberInfo.name then
		return GetFullName(contextData.memberInfo.name)
	end

	return nil
end

if Menu and Menu.ModifyMenu then
	local function GroupWatchMenuHandler(ownerRegion, rootDescription, contextData)
		local fullName = GetPlayerFullNameFromContext(contextData)
		if not fullName then
			return
		end

		InitDB()
		if not GroupWatchDB or not GroupWatchDB.lists then
			return
		end

		rootDescription:CreateDivider()
		local mainSubMenu = rootDescription:CreateButton("GroupWatch")

		local sortedLists = {}
		for lName in pairs(GroupWatchDB.lists) do
			table_insert(sortedLists, lName)
		end
		table_sort(sortedLists, function(a, b)
			if IsDefaultList(a) and not IsDefaultList(b) then
				return true
			end
			if not IsDefaultList(a) and IsDefaultList(b) then
				return false
			end
			return a < b
		end)

		for _, lName in ipairs(sortedLists) do
			local lData = GroupWatchDB.lists[lName]
			local listSubMenu = mainSubMenu:CreateButton(string_format(L["CONTEXT_LIST"], lName))
			if lData.players and lData.players[fullName] then
				listSubMenu:CreateButton(L["CONTEXT_REMOVE"], function()
					RemovePlayer(fullName, lName)
				end)
			else
				listSubMenu:CreateButton(L["CONTEXT_ADD"], function()
					AddPlayer(lName, fullName)
				end)
			end
		end
	end

	local CONTEXT_MENU_TAGS = {
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

	for _, tag in ipairs(CONTEXT_MENU_TAGS) do
		Menu.ModifyMenu(tag, GroupWatchMenuHandler)
	end
end

----------------------------------------------------
-- TOOLTIP (Hovering over player, unit frames & Group Finder)
----------------------------------------------------
local function GetPlayerFullNameFromTooltip(tooltip, data)
	local unit, name

	if TooltipUtil and TooltipUtil.GetDisplayedUnit then
		local ok, resUnit = pcall(TooltipUtil.GetDisplayedUnit, tooltip)
		if ok and resUnit and type(resUnit) == "string" then
			unit = resUnit
		end
	end

	if not unit and tooltip and tooltip.GetUnit then
		local ok, resName, resUnit = pcall(tooltip.GetUnit, tooltip)
		if ok then
			if resUnit and type(resUnit) == "string" then
				unit = resUnit
			end
			if resName and type(resName) == "string" then
				name = resName
			end
		end
	end

	if unit then
		local ok, exists = pcall(UnitExists, unit)
		if ok and exists then
			local fullName = GetPlayerFullNameFromUnit(unit)
			if fullName then
				return fullName
			end
		end
	end

	if data and data.guid then
		local ok, isPlayerGUID = pcall(function()
			return type(data.guid) == "string" and data.guid:find("^Player%-")
		end)

		if ok and isPlayerGUID and GetPlayerInfoByGUID then
			local okInfo, _, _, _, _, _, pName, pRealm = pcall(GetPlayerInfoByGUID, data.guid)
			if okInfo and pName and pName ~= "" then
				if not pRealm or pRealm == "" then
					pRealm = GetRealmName():gsub("%s+", "")
				else
					pRealm = strtrim(pRealm):gsub("%s+", "")
				end
				return pName .. "-" .. pRealm
			end
		end
	end

	if name and type(name) == "string" and name ~= "" then
		local ok, hasHash = pcall(function()
			return name:find("#")
		end)
		if ok and not hasHash then
			return GetFullName(name)
		end
	end

	return nil
end

local function AppendNotesToTooltip(tooltip, fullName)
	if not tooltip or not tooltip.AddLine or not fullName then
		return
	end
	if not GroupWatchDB or not GroupWatchDB.lists then
		return
	end

	local name = strsplit("-", fullName, 2)

	local entries = {}
	for lName, lData in pairs(GroupWatchDB.lists) do
		local inList = lData.players and (lData.players[fullName] or (name and lData.players[name]))
		if inList then
			local note = lData.notes and (lData.notes[fullName] or (name and lData.notes[name]))
			table_insert(entries, {
				list = lName,
				note = (note and note ~= "") and note or nil,
			})
		end
	end

	if #entries == 0 then
		return
	end

	table_sort(entries, function(a, b)
		if IsDefaultList(a.list) and not IsDefaultList(b.list) then
			return true
		end
		if not IsDefaultList(a.list) and IsDefaultList(b.list) then
			return false
		end
		return a.list < b.list
	end)

	local noteHeader = L["NOTE_HEADER"] or "Note"

	tooltip:AddLine(" ")
	for _, entry in ipairs(entries) do
		if entry.note then
			if IsDefaultList(entry.list) then
				tooltip:AddLine(
					string_format("|cff00ccffGroupWatch %s:|r |cffffffff%s|r", noteHeader, entry.note),
					1,
					1,
					1,
					true
				)
			else
				tooltip:AddLine(
					string_format(
						"|cff00ccffGroupWatch|r (|cffffd100%s|r) - |cff00ccff%s:|r |cffffffff%s|r",
						entry.list,
						noteHeader,
						entry.note
					),
					1,
					1,
					1,
					true
				)
			end
		else
			tooltip:AddLine(string_format("|cff00ccffGroupWatch:|r |cffffd100%s|r", entry.list), 1, 1, 1, true)
		end
	end
	tooltip:Show()
end

local function OnTooltipSetUnit(tooltip, data)
	local fullName = GetPlayerFullNameFromTooltip(tooltip, data)
	if fullName then
		AppendNotesToTooltip(tooltip, fullName)
	end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
	if Enum.TooltipDataType.Unit then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
	end

	if Enum.TooltipDataType.GroupFinderSearchResult then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.GroupFinderSearchResult, function(tooltip, data)
			if not data or not data.id then
				return
			end
			local ok, searchResult = pcall(C_LFGList.GetSearchResultInfo, data.id)
			if ok and searchResult and searchResult.leaderName then
				local fullName = GetFullName(searchResult.leaderName)
				if fullName then
					AppendNotesToTooltip(tooltip, fullName)
				end
			end
		end)
	end
elseif GameTooltip and GameTooltip.HookScript then
	GameTooltip:HookScript("OnTooltipSetUnit", function(self)
		OnTooltipSetUnit(self)
	end)
end

if LFGListUtil_SetSearchEntryTooltip then
	hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", function(tooltip, resultID)
		if not resultID then
			return
		end
		local ok, searchResult = pcall(C_LFGList.GetSearchResultInfo, resultID)
		if ok and searchResult and searchResult.leaderName then
			local fullName = GetFullName(searchResult.leaderName)
			if fullName then
				AppendNotesToTooltip(tooltip, fullName)
			end
		end
	end)
end

if IsLoggedIn and IsLoggedIn() then
	InitDB()
	CreateMinimapButton()
	RegisterLDB()
end
