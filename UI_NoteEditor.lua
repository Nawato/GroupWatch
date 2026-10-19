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
		ns.SkinCloseButton(closeBtn)
		ns.SkinButton(saveBtn)
		ns.SkinButton(cancelBtn)
		if ns.skinEUI and ns.skinEUI.Shell then
			if frame.ClearBackdrop then
				frame:ClearBackdrop()
			elseif frame.SetBackdrop then
				frame:SetBackdrop(nil)
			end
			ns.skinEUI.Shell(frame)
			if ns.skinEUI.Font then
				ns.skinEUI.Font(title)
			end
		elseif ns.IsElvUIPresent() then
			local S = ns.GetElvUISkins()
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
			ns.SkinScrollBar(scrollFrame.ScrollBar)
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
