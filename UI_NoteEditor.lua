--[[
	GroupWatch — UI_NoteEditor
	==========================
	Modal-ish dialog used to edit the note attached to a player inside a list.

	The frame is created lazily on the first call and reused afterwards.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local CreateFrame, UIParent = G.CreateFrame, G.UIParent
local C_Timer = G.C_Timer
local math_max = G.math_max
local string_format, string_len, string_gsub = G.string_format, G.string_len, G.string_gsub
local select = G.select
local tinsert = G.tinsert

local NoteEditorFrame = nil

--- Open the note editor for `playerName` inside `listName`.
--- `existingNote` is the note that is currently stored (may be nil).
function ns.ShowNoteEditor(playerName, listName, existingNote)
	-- Both names are required: without a valid player there is nothing to
	-- save a note on, and every write below (title, cursor, save) assumes
	-- them. A nil/invalid opener must never throw.
	if type(playerName) ~= "string" or playerName == "" then
		return
	end
	if type(listName) ~= "string" or listName == "" then
		return
	end
	local noteText = type(existingNote) == "string" and existingNote or ""
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

		if not (ns.skinEUI or ns.IsElvUIPresent()) then
			frame:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true,
				tileSize = 32,
				edgeSize = 32,
				insets = { left = 8, right = 8, top = 8, bottom = 8 },
			})
		end

		-- Title (placed on the header strip by ns.SkinWindow)
		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("CENTER", frame, "TOP", 0, -12)
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

		-- Cache font height once; only recompute line count on text change.
		-- GetFontObject may be nil on restricted clients, so the handler
		-- falls back to a default line height instead of throwing.
		local editFont = nil
		if editBox.GetFontObject then
			local okFont, fontObj = pcall(editBox.GetFontObject, editBox)
			if okFont then
				editFont = fontObj
			end
		end
		editBox:SetScript("OnTextChanged", function(self)
			local h = nil
			if editFont and editFont.GetFont then
				local okH, _, fh = pcall(editFont.GetFont, editFont)
				if okH then
					h = fh
				end
			end
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
				ns.SavePlayerNote(frame.noteData.listName, frame.noteData.playerName, frame.editBox:GetText())
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
		ns.SkinButton(saveBtn)
		ns.SkinButton(cancelBtn)
		-- SkinWindow paints the shell (and its black header strip) and centers
		-- the title on it; it skins the close button as well.
		ns.SkinWindow(frame)
		if scrollFrame.ScrollBar then
			ns.SkinScrollBar(scrollFrame.ScrollBar)
		end

		tinsert(UISpecialFrames, "GroupWatchNoteEditor")
		NoteEditorFrame = frame
	end

	local f = NoteEditorFrame
	f.noteData = { listName = listName, playerName = playerName }
	f.title:SetText(string_format(L["DIALOG_EDIT_NOTE_TEXT"], playerName))
	f.editBox:SetText(noteText)
	if f.editBox.SetCursorPosition and type(f.editBox.GetText) == "function" then
		local okLen, curText = pcall(f.editBox.GetText, f.editBox)
		f.editBox:SetCursorPosition(string_len((okLen and type(curText) == "string") and curText or noteText))
	end

	-- C_Timer is localized at load and may be nil in restricted/test
	-- contexts; the deferred resize is best-effort only.
	if C_Timer and type(C_Timer.After) == "function" then
		C_Timer.After(0, function()
			if f.scrollFrame:GetWidth() > 0 then
				f.editBox:SetWidth(f.scrollFrame:GetWidth() - 10)
			end
		end)
	end
	f:Show()
	f.editBox:SetFocus()
end
