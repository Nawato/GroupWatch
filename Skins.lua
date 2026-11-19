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
-- The ElvUI skin module, resolved once and cached so a full list refresh
-- (one GetModule call per button per row) does not hammer ElvUI. The cache
-- is dropped by ns.InvalidateElvUICache, which Init.lua calls on
-- PLAYER_LOGIN so a UI library that shows up late is still picked up.
local elvCacheValid = false
local elvSkinsModule = nil

local function FetchElvUISkins()
	if type(ElvUI) ~= "table" or type(ElvUI[1]) ~= "table" then
		return nil
	end
	-- GetModule throws when the module is unknown; a throwing skin engine
	-- must never break the addon.
	local accessor = ElvUI[1].GetModule
	if type(accessor) ~= "function" then
		return nil
	end
	local ok, mod = pcall(accessor, ElvUI[1], "Skins")
	if not ok or type(mod) ~= "table" then
		return nil
	end
	return mod
end

function ns.GetElvUISkins()
	if elvCacheValid then
		return elvSkinsModule
	end
	elvCacheValid = true
	elvSkinsModule = FetchElvUISkins()
	return elvSkinsModule
end

function ns.IsElvUIPresent()
	return ns.GetElvUISkins() ~= nil
end

function ns.InvalidateElvUICache()
	elvCacheValid = false
	elvSkinsModule = nil
end

-- ---------------------------------------------------------------------------
-- Skinning wrappers
-- ---------------------------------------------------------------------------
function ns.SkinButton(btn)
	if not btn then
		return
	end
	if skinEUI and type(skinEUI.Button) == "function" then
		skinEUI.Button(btn)
		return
	end
	local S = ns.GetElvUISkins()
	if S and type(S.HandleButton) == "function" then
		S:HandleButton(btn)
	end
end

function ns.SkinCloseButton(btn)
	if not btn then
		return
	end
	if skinEUI and type(skinEUI.CloseButton) == "function" then
		skinEUI.CloseButton(btn)
		return
	end
	local S = ns.GetElvUISkins()
	if S and type(S.HandleCloseButton) == "function" then
		S:HandleCloseButton(btn)
	end
end

function ns.SkinScrollBar(sb)
	if not sb then
		return
	end
	if skinEUI and type(skinEUI.ScrollBar) == "function" then
		skinEUI.ScrollBar(sb)
		return
	end
	local S = ns.GetElvUISkins()
	if S and type(S.HandleScrollBar) == "function" then
		S:HandleScrollBar(sb)
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

	-- Resolved once per window: every button/row below reuses the same
	-- module instead of calling GetModule again for each of them.
	local elvSkins = ns.GetElvUISkins()

	if skinEUI and type(skinEUI.Shell) == "function" then
		if f.ClearBackdrop then
			f:ClearBackdrop()
		elseif f.SetBackdrop then
			f:SetBackdrop(nil)
		end
		skinEUI.Shell(f)
		if f.title and type(skinEUI.Font) == "function" then
			skinEUI.Font(f.title)
		end
		if f.listLabel and type(skinEUI.Font) == "function" then
			skinEUI.Font(f.listLabel)
		end
	elseif elvSkins then
		if f.ClearBackdrop then
			f:ClearBackdrop()
		elseif f.SetBackdrop then
			f:SetBackdrop(nil)
		end
		if type(elvSkins.HandleFrame) == "function" then
			elvSkins:HandleFrame(f, true)
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
