--[[
	GroupWatch — Skins
	==================
	Theme abstraction for the supported UI libraries (EllesmereUI, ElvUI).

	Other modules never talk to the skin libraries directly; they call the
	ns.Skin* wrappers below instead. `ns.skinEUI` holds the raw EllesmereUI
	skin object for the few places that need fine-grained access.
]]

local ADDON_NAME, ns = ...

local skinEUI = nil
ns.skinEUI = nil

-- ---------------------------------------------------------------------------
-- Engine detection
-- ---------------------------------------------------------------------------
function ns.IsElvUIPresent()
	return (ElvUI and ElvUI[1] and ElvUI[1]:GetModule("Skins")) and true or false
end

function ns.GetElvUISkins()
	if ElvUI and ElvUI[1] then
		return ElvUI[1]:GetModule("Skins")
	end
end

-- ---------------------------------------------------------------------------
-- Skinning wrappers
-- ---------------------------------------------------------------------------
function ns.SkinButton(btn)
	if not btn then
		return
	end
	if skinEUI and skinEUI.Button then
		skinEUI.Button(btn)
	elseif ns.IsElvUIPresent() then
		local S = ns.GetElvUISkins()
		if S and S.HandleButton then
			S:HandleButton(btn)
		end
	end
end

function ns.SkinCloseButton(btn)
	if not btn then
		return
	end
	if skinEUI and skinEUI.CloseButton then
		skinEUI.CloseButton(btn)
	elseif ns.IsElvUIPresent() then
		local S = ns.GetElvUISkins()
		if S and S.HandleCloseButton then
			S:HandleCloseButton(btn)
		end
	end
end

function ns.SkinScrollBar(sb)
	if not sb then
		return
	end
	if skinEUI and skinEUI.ScrollBar then
		skinEUI.ScrollBar(sb)
	elseif ns.IsElvUIPresent() then
		local S = ns.GetElvUISkins()
		if S and S.HandleScrollBar then
			S:HandleScrollBar(sb)
		end
	end
end

-- Height of the dark header strip the skin paints along the top of a window
-- (the strip spans the full frame width, so its centre is the frame's top
-- centre pushed down by half its height).
local HEADER_HEIGHT = 25

-- Center a window title inside the header strip.
--
-- The title is a plain FontString, so the skin does not place it for us: it
-- stays where the addon anchored it (the top edge of the frame) and therefore
-- hangs off the black bar instead of sitting in the middle of it.
function ns.SkinTitle(frame, title)
	if not title or not frame then
		return
	end

	title:ClearAllPoints()
	title:SetPoint("CENTER", frame, "TOP", 0, -HEADER_HEIGHT / 2)
end

function ns.SkinWindow(f)
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
	elseif ns.IsElvUIPresent() then
		local S = ns.GetElvUISkins()
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
		ns.SkinCloseButton(f.closeBtn)
	end
	if f.scrollBar then
		ns.SkinScrollBar(f.scrollBar)
	end
	if f.newListBtn then
		ns.SkinButton(f.newListBtn)
	end
	if f.delListBtn then
		ns.SkinButton(f.delListBtn)
	end

	-- Keep the title centered on the header strip (done last: the skin may
	-- have just created the strip, and it re-fonts the title).
	ns.SkinTitle(f, f.title)
end

-- ---------------------------------------------------------------------------
-- EllesmereUI skin registration
-- ---------------------------------------------------------------------------
if EllesmereUI and EllesmereUI.RegisterSkin then
	EllesmereUI.RegisterSkin("GroupWatch", function(S)
		skinEUI = S
		ns.skinEUI = S
		local ui = ns.GroupWatchUI
		if ui then
			ns.SkinWindow(ui)
			ui:Refresh()
		end
	end)
end
