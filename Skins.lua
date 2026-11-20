--[[
	GroupWatch — Skins
	==================
	Theme abstraction for the supported UI libraries (EllesmereUI, ElvUI).

	Other modules never talk to the skin libraries directly; they call the
	`ns.Skin*` wrappers below instead. `ns.skinEUI` holds the raw EllesmereUI
	skin object for the few places that need fine-grained access.

	P3 (Modern EllesmereUI-style look with safe fallback):
	  - EllesmereUI path uses S.Shell(main)/S.Panel(sub)/S.Button/
	    S.CloseButton/S.ScrollBar/S.EditBox(box,{padInput=true})/S.Font/
	    S.OnLooksChanged where available; S.ItemButton is checked before
	    use (apiVersion 4).
	  - No hard EUI dependency: every call is nil/type-guarded so a missing
	    EUI means full fallback styling.
	  - Fallback theme (EUI absent/off): one shared backdrop table, solid
	    fill + 1px WHITE8X8 border strips, hover = alpha bumps only.
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
-- Fallback theme (EUI absent/off)
-- ---------------------------------------------------------------------------
-- One shared backdrop table: dark warm fill, 1px white border at low alpha,
-- no tiled edge files. WHITE8X8 edges avoid the BackdropTemplate
-- black-corner artifacts; pooled/new frames get manual 1px strips instead.
local FALLBACK_FILL_R, FALLBACK_FILL_G, FALLBACK_FILL_B, FALLBACK_FILL_A = 0.07, 0.06, 0.05, 0.9
local FALLBACK_BORDER_A = 0.18

ns.FALLBACK_FILL = { r = FALLBACK_FILL_R, g = FALLBACK_FILL_G, b = FALLBACK_FILL_B, a = FALLBACK_FILL_A }
ns.FALLBACK_BORDER = { r = 1, g = 1, b = 1, a = FALLBACK_BORDER_A }
ns.FALLBACK_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	tile = false,
	tileSize = 0,
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

--- The active EllesmereUI skin object, or nil when skinning is off.
--- Respects S.IsEnabled() so a user-disabled skin falls back gracefully.
local function ActiveEUI()
	local S = skinEUI
	if type(S) ~= "table" then
		return nil
	end
	if type(S.IsEnabled) == "function" then
		local ok, enabled = pcall(S.IsEnabled, S)
		if ok and enabled == false then
			return nil
		end
	end
	return S
end

--- Resolver for the active EUI skin (nil when disabled/absent).
--- Pooled rows build their per-refresh cache from this so
--- IsEnabled()==false falls back instead of using raw ns.skinEUI.
ns.GetActiveEUI = ActiveEUI

--- Paint a frame with the shared fallback backdrop (fill + 1px border).
function ns.ApplyFallbackBackdrop(frame)
	if type(frame) ~= "table" then
		return
	end
	if type(frame.SetBackdrop) == "function" then
		pcall(frame.SetBackdrop, frame, ns.FALLBACK_BACKDROP)
	end
	if type(frame.SetBackdropColor) == "function" then
		pcall(frame.SetBackdropColor, frame, FALLBACK_FILL_R, FALLBACK_FILL_G, FALLBACK_FILL_B, FALLBACK_FILL_A)
	end
	if type(frame.SetBackdropBorderColor) == "function" then
		pcall(frame.SetBackdropBorderColor, frame, 1, 1, 1, FALLBACK_BORDER_A)
	end
end

--- Manual 1px border from WHITE8X8 strips (avoids BackdropTemplate
--- black-corner issues). Idempotent: reuses existing strips on refresh.
function ns.AddFallbackBorder(frame, alpha)
	if type(frame) ~= "table" then
		return nil
	end
	if type(frame.CreateTexture) ~= "function" then
		return nil
	end
	local a = alpha
	if type(a) ~= "number" then
		a = FALLBACK_BORDER_A
	end
	if frame._gwBorder then
		return frame._gwBorder
	end
	-- Strips are WHITE8X8 1px quads (solid white, tinted by vertex/color).
	local WHITE = "Interface\\Buttons\\WHITE8X8"
	local function MakeStrip()
		local ok, tex = pcall(frame.CreateTexture, frame, nil, "BORDER")
		if not ok or tex == nil then
			return nil
		end
		if type(tex.SetTexture) == "function" then
			pcall(tex.SetTexture, tex, WHITE)
		end
		if type(tex.SetColorTexture) == "function" then
			pcall(tex.SetColorTexture, tex, 1, 1, 1, a)
		end
		return tex
	end
	local top = MakeStrip()
	local bottom = MakeStrip()
	local left = MakeStrip()
	local right = MakeStrip()
	if not (top and bottom and left and right) then
		return nil
	end
	if type(top.SetPoint) == "function" then
		pcall(top.SetPoint, top, "TOPLEFT", frame, "TOPLEFT", 0, 0)
		pcall(top.SetPoint, top, "TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	end
	if type(top.SetHeight) == "function" then
		pcall(top.SetHeight, top, 1)
	end
	if type(bottom.SetPoint) == "function" then
		pcall(bottom.SetPoint, bottom, "BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
		pcall(bottom.SetPoint, bottom, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	end
	if type(bottom.SetHeight) == "function" then
		pcall(bottom.SetHeight, bottom, 1)
	end
	if type(left.SetPoint) == "function" then
		pcall(left.SetPoint, left, "TOPLEFT", frame, "TOPLEFT", 0, 0)
		pcall(left.SetPoint, left, "BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	end
	if type(left.SetWidth) == "function" then
		pcall(left.SetWidth, left, 1)
	end
	if type(right.SetPoint) == "function" then
		pcall(right.SetPoint, right, "TOPRIGHT", frame, "TOPRIGHT", 0, 0)
		pcall(right.SetPoint, right, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	end
	if type(right.SetWidth) == "function" then
		pcall(right.SetWidth, right, 1)
	end
	frame._gwBorder = { top = top, bottom = bottom, left = left, right = right }
	frame._gwBorderAlpha = a
	return frame._gwBorder
end

--- Recolor the manual fallback border (e.g. class color on the drag chip).
function ns.SetFallbackBorderColor(frame, r, g, b, a)
	if type(frame) ~= "table" then
		return
	end
	local border = frame._gwBorder
	if type(border) ~= "table" then
		return
	end
	local alpha = a
	if type(alpha) ~= "number" then
		alpha = frame._gwBorderAlpha or FALLBACK_BORDER_A
	end
	for _, key in ipairs({ "top", "bottom", "left", "right" }) do
		local tex = border[key]
		if type(tex) == "table" and type(tex.SetColorTexture) == "function" then
			pcall(tex.SetColorTexture, tex, r, g, b, alpha)
		end
	end
	if type(frame.SetBackdropBorderColor) == "function" then
		pcall(frame.SetBackdropBorderColor, frame, r, g, b, alpha)
	end
end

--- Full fallback frame treatment: shared backdrop + crisp 1px strips.
function ns.ApplyFallbackFrame(frame)
	if type(frame) ~= "table" then
		return
	end
	ns.ApplyFallbackBackdrop(frame)
	ns.AddFallbackBorder(frame)
end

-- ---------------------------------------------------------------------------
-- Fallback fonts
-- ---------------------------------------------------------------------------
-- Prefer the user's font via S.Font; fallback keeps the frame's own font
-- object (STANDARD_TEXT_FONT chain) with a (1,-1) shadow for body copy and
-- OUTLINE only for tiny overlay text. Never hardcodes an EUI font path.
function ns.SkinFont(fs, isTiny)
	if type(fs) ~= "table" then
		return
	end
	local S = ActiveEUI()
	if S and type(S.Font) == "function" then
		local ok = pcall(S.Font, fs)
		if ok then
			return
		end
	end
	if type(fs.SetShadowOffset) == "function" then
		pcall(fs.SetShadowOffset, fs, 1, -1)
	end
	if type(fs.SetShadowColor) == "function" then
		pcall(fs.SetShadowColor, fs, 0, 0, 0, 0.8)
	end
	if isTiny then
		if type(fs.GetFont) == "function" and type(fs.SetFont) == "function" then
			local okGet, path, size = pcall(fs.GetFont, fs)
			if okGet and type(path) == "string" and type(size) == "number" then
				pcall(fs.SetFont, fs, path, size, "OUTLINE")
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- Fallback buttons: solid fill + 1px border + label; hover = alpha only
-- ---------------------------------------------------------------------------
-- Hover handlers bump alpha only (no texture/color swaps) so they compose
-- with tooltips and other OnEnter logic.
local function FallbackHoverEnter(btn)
	if type(btn) == "table" and type(btn.SetAlpha) == "function" then
		btn:SetAlpha(0.85)
	end
end

local function FallbackHoverLeave(btn)
	if type(btn) == "table" and type(btn.SetAlpha) == "function" then
		btn:SetAlpha(1.0)
	end
end

function ns.StyleFallbackButton(btn)
	if type(btn) ~= "table" then
		return
	end
	if btn._gwFallbackStyled then
		return
	end
	btn._gwFallbackStyled = true

	-- Strip default button art where the API offers it, keeping the label.
	if type(btn.StripTextures) == "function" then
		pcall(btn.StripTextures, btn)
	end
	if type(btn.SetNormalTexture) == "function" then
		pcall(btn.SetNormalTexture, btn, "")
	end
	if type(btn.SetPushedTexture) == "function" then
		pcall(btn.SetPushedTexture, btn, "")
	end
	if type(btn.SetHighlightTexture) == "function" then
		pcall(btn.SetHighlightTexture, btn, "")
	end
	if type(btn.SetDisabledTexture) == "function" then
		pcall(btn.SetDisabledTexture, btn, "")
	end

	local usedBackdrop = false
	if type(btn.SetBackdrop) == "function" then
		local ok = pcall(btn.SetBackdrop, btn, ns.FALLBACK_BACKDROP)
		if ok then
			usedBackdrop = true
			if type(btn.SetBackdropColor) == "function" then
				pcall(btn.SetBackdropColor, btn, FALLBACK_FILL_R, FALLBACK_FILL_G, FALLBACK_FILL_B, FALLBACK_FILL_A)
			end
			if type(btn.SetBackdropBorderColor) == "function" then
				pcall(btn.SetBackdropBorderColor, btn, 1, 1, 1, FALLBACK_BORDER_A)
			end
		end
	end
	if not usedBackdrop then
		-- No BackdropTemplate: solid fill + manual 1px strips.
		if type(btn.CreateTexture) == "function" then
			local okBg, bg = pcall(btn.CreateTexture, btn, nil, "BACKGROUND")
			if okBg and bg ~= nil then
				if type(bg.SetAllPoints) == "function" then
					pcall(bg.SetAllPoints, bg, btn)
				end
				if type(bg.SetColorTexture) == "function" then
					pcall(bg.SetColorTexture, bg, FALLBACK_FILL_R, FALLBACK_FILL_G, FALLBACK_FILL_B, FALLBACK_FILL_A)
				end
				btn._gwFallbackBG = bg
			end
		end
		ns.AddFallbackBorder(btn)
	else
		-- Backdrop path already paints a 1px edge; extra strips would
		-- double it, so only ensure strips exist for corner crispness when
		-- the frame supports them without doubling (manual strips share
		-- the same 1px rect and alpha, so this stays a no-op visually).
		if btn._gwBorder == nil then
			-- Keep the backdrop edge as the single source: do not add a
			-- second border on top of it.
		end
	end

	-- Hover = alpha bumps only. HookScript preserves existing handlers
	-- (e.g. the note button tooltip); plain SetScript wraps them.
	if type(btn.HookScript) == "function" then
		pcall(btn.HookScript, btn, "OnEnter", FallbackHoverEnter)
		pcall(btn.HookScript, btn, "OnLeave", FallbackHoverLeave)
	elseif type(btn.SetScript) == "function" then
		local prevEnter, prevLeave
		if type(btn.GetScript) == "function" then
			pcall(function()
				prevEnter = btn:GetScript("OnEnter")
				prevLeave = btn:GetScript("OnLeave")
			end)
		end
		if type(prevEnter) == "function" then
			pcall(btn.SetScript, btn, "OnEnter", function(self)
				pcall(prevEnter, self)
				FallbackHoverEnter(self)
			end)
		else
			pcall(btn.SetScript, btn, "OnEnter", FallbackHoverEnter)
		end
		if type(prevLeave) == "function" then
			pcall(btn.SetScript, btn, "OnLeave", function(self)
				pcall(prevLeave, self)
				FallbackHoverLeave(self)
			end)
		else
			pcall(btn.SetScript, btn, "OnLeave", FallbackHoverLeave)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Skinning wrappers
-- ---------------------------------------------------------------------------
function ns.SkinButton(btn)
	if type(btn) ~= "table" then
		return
	end
	local S = ActiveEUI()
	if S and type(S.Button) == "function" then
		local ok = pcall(S.Button, btn)
		if ok then
			return
		end
	end
	local elv = ns.GetElvUISkins()
	if elv and type(elv.HandleButton) == "function" then
		local ok = pcall(elv.HandleButton, elv, btn)
		if ok then
			return
		end
	end
	ns.StyleFallbackButton(btn)
end

function ns.SkinCloseButton(btn)
	if type(btn) ~= "table" then
		return
	end
	local S = ActiveEUI()
	if S and type(S.CloseButton) == "function" then
		local ok = pcall(S.CloseButton, btn)
		if ok then
			return
		end
	end
	local elv = ns.GetElvUISkins()
	if elv and type(elv.HandleCloseButton) == "function" then
		local ok = pcall(elv.HandleCloseButton, elv, btn)
		if ok then
			return
		end
	end
	ns.StyleFallbackButton(btn)
end

function ns.SkinScrollBar(sb)
	if type(sb) ~= "table" then
		return
	end
	local S = ActiveEUI()
	if S and type(S.ScrollBar) == "function" then
		local ok = pcall(S.ScrollBar, sb)
		if ok then
			return
		end
	end
	local elv = ns.GetElvUISkins()
	if elv and type(elv.HandleScrollBar) == "function" then
		pcall(elv.HandleScrollBar, elv, sb)
	end
end

function ns.SkinEditBox(box, opts)
	if type(box) ~= "table" then
		return
	end
	local S = ActiveEUI()
	if S and type(S.EditBox) == "function" then
		local editOpts = opts or { padInput = true }
		local ok = pcall(S.EditBox, box, editOpts)
		if ok then
			return
		end
		-- Older EUI (apiVersion < 3) ignores opts: retry without them.
		local okPlain = pcall(S.EditBox, box)
		if okPlain then
			return
		end
	end
	local elv = ns.GetElvUISkins()
	if elv and type(elv.HandleEditBox) == "function" then
		local ok = pcall(elv.HandleEditBox, elv, box)
		if ok then
			return
		end
	end
	ns.ApplyFallbackFrame(box)
end

--- Skin a sub-panel / popup. Uses S.Panel; falls back to the shared theme.
function ns.SkinPanel(frame)
	if type(frame) ~= "table" then
		return
	end
	local S = ActiveEUI()
	if S and type(S.Panel) == "function" then
		local ok = pcall(S.Panel, frame)
		if ok then
			return
		end
	end
	local elv = ns.GetElvUISkins()
	if elv and type(elv.HandleFrame) == "function" then
		local ok = pcall(elv.HandleFrame, elv, frame, true)
		if ok then
			return
		end
	end
	ns.ApplyFallbackFrame(frame)
end

--- Skin an item slot. S.ItemButton is apiVersion 4: check it before use
--- and fall back to S.SquareIcon on older EUI, then to the flat fallback.
function ns.SkinItemButton(btn)
	if type(btn) ~= "table" then
		return
	end
	local S = ActiveEUI()
	if S then
		if type(S.ItemButton) == "function" then
			local ok = pcall(S.ItemButton, btn)
			if ok then
				return
			end
		elseif type(S.SquareIcon) == "function" and type(btn.icon) == "table" then
			local ok = pcall(S.SquareIcon, btn.icon, btn, true)
			if ok then
				return
			end
		end
	end
	ns.StyleFallbackButton(btn)
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
	if type(title) ~= "table" or type(frame) ~= "table" then
		return
	end
	if type(title.ClearAllPoints) == "function" then
		pcall(title.ClearAllPoints, title)
	end
	if type(title.SetPoint) == "function" then
		pcall(title.SetPoint, title, "CENTER", frame, "TOP", 0, -HEADER_HEIGHT / 2)
	end
end

function ns.SkinWindow(f)
	if type(f) ~= "table" then
		return
	end

	-- Resolved once per window: every button/row below reuses the same
	-- module instead of calling GetModule again for each of them.
	local S = ActiveEUI()
	local elvSkins = ns.GetElvUISkins()

	if S then
		if type(f.ClearBackdrop) == "function" then
			pcall(f.ClearBackdrop, f)
		elseif type(f.SetBackdrop) == "function" then
			pcall(f.SetBackdrop, f, nil)
		end
		-- A frame that previously used the fallback theme still carries
		-- its manual 1px strips; hide them so they do not leak through
		-- the engine-skinned window.
		if type(f._gwBorder) == "table" then
			for _, key in ipairs({ "top", "bottom", "left", "right" }) do
				local tex = f._gwBorder[key]
				if type(tex) == "table" and type(tex.Hide) == "function" then
					pcall(tex.Hide, tex)
				end
			end
		end
		-- Main window gets the full shell; sub-frames/popups get the flat
		-- panel. Both primitives look identical except for the Shell
		-- backdrop, and both track future EUI tweaks automatically.
		local isMain = (f == ns.GroupWatchUI)
		local skinned = false
		if isMain and type(S.Shell) == "function" then
			skinned = pcall(S.Shell, f)
		elseif not isMain and type(S.Panel) == "function" then
			skinned = pcall(S.Panel, f)
		end
		if not skinned then
			if type(S.Shell) == "function" then
				pcall(S.Shell, f)
			elseif type(S.Panel) == "function" then
				pcall(S.Panel, f)
			end
		end
		if f.title then
			ns.SkinFont(f.title, false)
		end
		if f.listLabel and type(f.listLabel) == "table" then
			ns.SkinFont(f.listLabel, false)
		end
	elseif elvSkins then
		if type(f.ClearBackdrop) == "function" then
			pcall(f.ClearBackdrop, f)
		elseif type(f.SetBackdrop) == "function" then
			pcall(f.SetBackdrop, f, nil)
		end
		if type(elvSkins.HandleFrame) == "function" then
			pcall(elvSkins.HandleFrame, elvSkins, f, true)
		else
			if type(f.StripTextures) == "function" then
				pcall(f.StripTextures, f)
			end
			if type(f.SetTemplate) == "function" then
				pcall(f.SetTemplate, f, "Transparent")
			elseif type(f.CreateBackdrop) == "function" then
				pcall(f.CreateBackdrop, f, "Transparent")
			end
		end
	else
		-- No skin engine: shared fallback theme so the addon still looks
		-- intentional without EUI or ElvUI.
		ns.ApplyFallbackFrame(f)
		if f.title then
			ns.SkinFont(f.title, false)
		end
		if f.listLabel and type(f.listLabel) == "table" then
			ns.SkinFont(f.listLabel, false)
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
-- Guarded: without EUI (or with skinning disabled) this is a silent no-op
-- and the fallback theme above carries the look. The skin object S is kept
-- so pooled rows created after login are still skinned in Refresh().
if type(EllesmereUI) == "table" and type(EllesmereUI.RegisterSkin) == "function" then
	pcall(EllesmereUI.RegisterSkin, "GroupWatch", function(S)
		if type(S) ~= "table" then
			return
		end
		skinEUI = S
		ns.skinEUI = S
		-- Live theme/accent edits re-skin custom elements; skinned frames
		-- track EUI on their own, this only refreshes the window chrome.
		if type(S.OnLooksChanged) == "function" then
			pcall(S.OnLooksChanged, function()
				local ui = ns.GroupWatchUI
				if type(ui) == "table" then
					pcall(ns.SkinWindow, ui)
					if type(ui.Refresh) == "function" then
						pcall(ui.Refresh, ui)
					end
				end
			end)
		end
		local ui = ns.GroupWatchUI
		if type(ui) == "table" then
			pcall(ns.SkinWindow, ui)
			if type(ui.Refresh) == "function" then
				pcall(ui.Refresh, ui)
			end
		end
	end)
end
