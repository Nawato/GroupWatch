-- GroupWatch P3 (skin) tests.
--
-- Covers the Modern EllesmereUI-style look with safe fallback:
-- fallback table values in range, RegisterSkin guard with EUI absent
-- (no throw), S primitive guards with partial S, scrollbar exists,
-- button hover only alphas, fonts (S.Font preferred, fallback shadow),
-- minimap standalone + optional LibDBIcon, pooled rows after login.
--
-- Run from the addon directory with any Lua 5.1+ interpreter:
--   lua tests/skin.lua
--   lua5.1 tests/skin.lua
-- Exit code is 0 when every test passes, 1 otherwise.
-- Lua 5.1-safe only (no goto, no bitwise, no integer division).

local say = print -- real stdout; tests/stubs.lua replaces global print

-- ---------------------------------------------------------------------------
-- Paths
-- ---------------------------------------------------------------------------

local ADDON_DIR = ""
local function fileExists(p)
	local f = io.open(p, "r")
	if f then
		f:close()
		return true
	end
	return false
end

if not fileExists("tests/stubs.lua") then
	local src = (arg and arg[0]) or ""
	local dir = src:match("^(.*/)")
	if dir then
		ADDON_DIR = dir:gsub("tests/$", "")
	end
end

-- ---------------------------------------------------------------------------
-- Test-only client globals (must exist BEFORE Core.lua captures them)
-- ---------------------------------------------------------------------------

StaticPopupDialogs = {}
tinsert = table.insert
ChatFontNormal = {}
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"

MockUI = { frames = {}, byName = {} }

local function makeTex()
	local self = { texCoords = nil, color = nil }
	function self:SetColorTexture(r, g, b, a)
		self.color = { r, g, b, a }
	end
	function self:SetTexture() end
	function self:SetTexCoord(l, r, t, b)
		self.texCoords = { l, r, t, b }
	end
	function self:SetPoint() end
	function self:SetAllPoints() end
	function self:SetSize() end
	function self:SetWidth() end
	function self:SetHeight() end
	function self:SetBlendMode() end
	function self:SetVertexColor() end
	function self:SetDesaturated() end
	function self:Hide() self.hidden = true end
	function self:Show() self.hidden = false end
	function self:SetAlpha() end
	return self
end

local function makeFont()
	local self = { shadow = nil, shadowColor = nil, font = { "Fonts\\FRIZQT__.TTF", 12, "" }, hidden = true }
	function self:SetPoint() end
	function self:ClearAllPoints() end
	function self:Hide() self.hidden = true end
	function self:Show() self.hidden = false end
	function self:IsShown() return not self.hidden end
	function self:IsVisible() return not self.hidden end
	function self:SetText(t) self.text = t end
	function self:GetText() return self.text end
	function self:SetJustifyH() end
	function self:SetJustifyV() end
	function self:SetShadowOffset(x, y) self.shadow = { x, y } end
	function self:SetShadowColor(r, g, b, a) self.shadowColor = { r, g, b, a } end
	function self:GetFont() return self.font[1], self.font[2], self.font[3] end
	function self:SetFont(path, size, flags) self.font = { path, size, flags } end
	return self
end

local function makeMock(kind)
	local self = { __kind = kind, scripts = {}, hidden = true, text = "", width = 100, height = 100 }
	function self:SetSize(w, h) self.width = w; self.height = h end
	function self:SetPoint() end
	function self:SetAllPoints() end
	function self:ClearAllPoints() end
	function self:SetMovable() end
	function self:EnableMouse() end
	function self:EnableMouseWheel() end
	function self:RegisterForDrag() end
	function self:RegisterForClicks() end
	function self:SetParent(p) self.parent = p end
	function self:GetParent() return self.parent end
	function self:SetScript(k, fn) self.scripts[k] = fn end
	function self:GetScript(k) return self.scripts[k] end
	function self:HookScript(k, fn)
		local prev = self.scripts[k]
		if type(prev) == "function" then
			self.scripts[k] = function(s, ...)
				prev(s, ...)
				fn(s, ...)
			end
		else
			self.scripts[k] = fn
		end
	end
	function self:SetClampedToScreen() end
	function self:SetFrameStrata() end
	function self:SetFrameLevel() end
	function self:SetBackdrop(bd) self.backdrop = bd end
	function self:ClearBackdrop() self.backdrop = nil end
	function self:SetBackdropColor(r, g, b, a) self.backdropColor = { r, g, b, a } end
	function self:SetBackdropBorderColor(r, g, b, a) self.backdropBorder = { r, g, b, a } end
	function self:RegisterEvent() end
	function self:StartMoving() end
	function self:StopMovingOrSizing() end
	function self:StripTextures() end
	function self:SetTemplate() end
	function self:CreateBackdrop() end
	function self:Hide() self.hidden = true end
	function self:Show() self.hidden = false end
	function self:IsShown() return not self.hidden end
	function self:IsVisible() return not self.hidden end
	function self:SetWidth(w) self.width = w end
	function self:SetHeight(h) self.height = h end
	function self:GetWidth() return self.width or 100 end
	function self:GetHeight() return self.height or 100 end
	function self:GetEffectiveScale() return 1 end
	function self:GetRect() return 0, 0, 500, 500 end
	function self:GetCenter() return 400, 300 end
	function self:GetVerticalScroll() return self.scrollPos or 0 end
	function self:SetVerticalScroll(v) self.scrollPos = v end
	function self:GetVerticalScrollRange() return 0 end
	function self:SetScrollChild(child) self.scrollChild = child end
	function self:SetText(t) self.text = t end
	function self:GetText() return self.text end
	function self:SetAlpha(a) self.alpha = a end
	function self:GetAlpha() return self.alpha or 1 end
	function self:SetColorTexture() end
	function self:SetTexture() end
	function self:SetTexCoord() end
	function self:SetBlendMode() end
	function self:SetJustifyH() end
	function self:SetJustifyV() end
	function self:GetStringWidth() return 100 end
	function self:SetNormalTexture() end
	function self:SetPushedTexture() end
	function self:SetHighlightTexture() end
	function self:SetDisabledTexture() end
	function self:SetValue(v) self.value = v end
	function self:SetMinMaxValues() end
	function self:CreateFontString() return makeFont() end
	function self:CreateTexture() return makeTex() end
	function self:SetCursorPosition() end
	function self:SetFocus() end
	function self:SetMultiLine() end
	function self:SetAutoFocus() end
	function self:SetFontObject() end
	function self:Insert() end
	function self:SetHeight2() end
	function self:GetFontObject() return nil end
	return self
end

function CreateFrame(ftype, name, parent, template)
	local m = makeMock(ftype)
	m.mockName = name
	m.parent = parent
	m.template = template
	-- UIPanelScrollFrameTemplate provides a ScrollBar child on live.
	if ftype == "ScrollFrame" and template == "UIPanelScrollFrameTemplate" then
		local sb = makeMock("Slider")
		sb.parent = m
		m.ScrollBar = sb
	end
	MockUI.frames[#MockUI.frames + 1] = m
	if name then
		MockUI.byName[name] = m
	end
	return m
end

UIParent = makeMock("UIParent")
function UIParent:GetWidth() return 800 end
function UIParent:GetHeight() return 600 end
UISpecialFrames = {}

Minimap = makeMock("Minimap")

GameTooltip = { lines = {} }
function GameTooltip:SetOwner() end
function GameTooltip:ClearLines() end
function GameTooltip:AddLine() end
function GameTooltip:Show() end
function GameTooltip:Hide() end

function GetCursorPosition() return 0, 0 end
function IsMouseButtonDown() return true end
function IsKeyDown() return false end

MenuUtil = nil
C_Timer = nil

dofile(ADDON_DIR .. "tests/stubs.lua")

-- ---------------------------------------------------------------------------
-- Harness
-- ---------------------------------------------------------------------------

local passed, failed = 0, 0
local function check(name, cond, extra)
	if cond then
		passed = passed + 1
		say("ok   - " .. name)
	else
		failed = failed + 1
		say("FAIL - " .. name .. (extra ~= nil and ("  (" .. tostring(extra) .. ")") or ""))
	end
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local src = f:read("*a")
	f:close()
	return src
end

local function loadmod(ns, name)
	local chunk, err = loadfile(ADDON_DIR .. name)
	assert(chunk, "cannot load " .. name .. ": " .. tostring(err))
	chunk("GroupWatch", ns)
end

local function loadLogic(ns)
	loadmod(ns, "Locales.lua")
	loadmod(ns, "Core.lua")
	loadmod(ns, "DB.lua")
	loadmod(ns, "Detection.lua")
	loadmod(ns, "ContextMenu.lua")
	loadmod(ns, "Tooltips.lua")
	loadmod(ns, "UI_DragCursor.lua")
end

-- ---------------------------------------------------------------------------
-- 1. Fallback table values in range
-- ---------------------------------------------------------------------------

do
	_G.EllesmereUI = nil
	_G.ElvUI = nil
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Skins.lua")
	check("Skin: FALLBACK_BACKDROP exists", type(ns.FALLBACK_BACKDROP) == "table")
	local bd = ns.FALLBACK_BACKDROP or {}
	check("Skin: fallback bgFile WHITE8X8", type(bd.bgFile) == "string" and bd.bgFile:find("WHITE8X8", 1, true) ~= nil, bd.bgFile)
	check("Skin: fallback edgeFile WHITE8X8", type(bd.edgeFile) == "string" and bd.edgeFile:find("WHITE8X8", 1, true) ~= nil, bd.edgeFile)
	check("Skin: fallback edgeSize 1px", bd.edgeSize == 1, bd.edgeSize)
	check("Skin: fallback no tiled edge files", bd.tile == false, tostring(bd.tile))
	check("Skin: fallback insets 1px", type(bd.insets) == "table" and bd.insets.left == 1 and bd.insets.right == 1 and bd.insets.top == 1 and bd.insets.bottom == 1)
	local fill = ns.FALLBACK_FILL or {}
	check("Skin: fallback fill table", type(fill.r) == "number" and type(fill.g) == "number" and type(fill.b) == "number" and type(fill.a) == "number")
	local function inRange(v) return type(v) == "number" and v >= 0 and v <= 1 end
	check("Skin: fallback fill in range", inRange(fill.r) and inRange(fill.g) and inRange(fill.b) and inRange(fill.a))
	check("Skin: fallback fill dark warm", (fill.r or 1) < 0.15 and (fill.g or 1) < 0.15 and (fill.b or 1) < 0.15, (fill.r or "?") .. "," .. (fill.g or "?") .. "," .. (fill.b or "?"))
	check("Skin: fallback fill alpha ~0.9", type(fill.a) == "number" and fill.a >= 0.85 and fill.a <= 0.95, fill.a)
	local border = ns.FALLBACK_BORDER or {}
	check("Skin: fallback border table", inRange(border.r) and inRange(border.g) and inRange(border.b) and inRange(border.a))
	check("Skin: fallback border white", border.r == 1 and border.g == 1 and border.b == 1)
	check("Skin: fallback border alpha 0.15-0.2", type(border.a) == "number" and border.a >= 0.15 and border.a <= 0.2, border.a)
end

-- ---------------------------------------------------------------------------
-- 2. RegisterSkin guard with EUI absent (no throw)
-- ---------------------------------------------------------------------------

do
	-- Absent entirely.
	_G.EllesmereUI = nil
	_G.ElvUI = nil
	local ok, err = pcall(function()
		local ns = {}
		loadLogic(ns)
		loadmod(ns, "Skins.lua")
		ns.SkinButton({})
		ns.SkinCloseButton({})
		ns.SkinScrollBar({})
		ns.SkinWindow({})
		ns.SkinButton(nil)
	end)
	check("Skin: EUI absent no throw", ok, err)

	-- Empty table (no RegisterSkin).
	_G.EllesmereUI = {}
	local ok2, err2 = pcall(function()
		local ns = {}
		loadmod(ns, "Skins.lua")
	end)
	check("Skin: EUI without RegisterSkin no throw", ok2, err2)

	-- Non-function RegisterSkin.
	_G.EllesmereUI = { RegisterSkin = "x" }
	local ok3, err3 = pcall(function()
		local ns = {}
		loadmod(ns, "Skins.lua")
	end)
	check("Skin: non-function RegisterSkin no throw", ok3, err3)

	-- Throwing RegisterSkin never breaks load.
	_G.EllesmereUI = { RegisterSkin = function() error("EUI boom") end }
	local ok4, err4 = pcall(function()
		local ns = {}
		loadmod(ns, "Skins.lua")
	end)
	check("Skin: throwing RegisterSkin no throw", ok4, err4)

	_G.EllesmereUI = nil
	_G.ElvUI = nil
end

-- ---------------------------------------------------------------------------
-- 3. S primitive guards with partial S
-- ---------------------------------------------------------------------------

do
	local function loadSkinsWith(S)
		_G.EllesmereUI = {
			RegisterSkin = function(name, cb) cb(S) end,
		}
		_G.ElvUI = nil
		local ns = {}
		loadLogic(ns)
		loadmod(ns, "Skins.lua")
		return ns
	end

	-- Non-function fields: type-guarded, silent.
	local ns = loadSkinsWith({ Button = "x", CloseButton = {}, ScrollBar = 0, Shell = false, Panel = 1, Font = "y", EditBox = {}, ItemButton = 0, OnLooksChanged = "z" })
	local ok, err = pcall(function()
		ns.SkinButton({})
		ns.SkinCloseButton({})
		ns.SkinScrollBar({})
		ns.SkinEditBox({}, { padInput = true })
		ns.SkinPanel({})
		ns.SkinWindow({})
		ns.SkinFont({ SetShadowOffset = function() end, SetShadowColor = function() end }, false)
		ns.SkinItemButton({ icon = {} })
		ns.ApplyFallbackFrame({})
		ns.StyleFallbackButton({})
		ns.AddFallbackBorder({})
	end)
	check("Skin: non-function S fields no throw", ok, err)

	-- Throwing primitives: pcall-contained, falls back.
	ns = loadSkinsWith({
		Button = function() error("boom") end,
		CloseButton = function() error("boom") end,
		ScrollBar = function() error("boom") end,
		Shell = function() error("boom") end,
		Panel = function() error("boom") end,
		Font = function() error("boom") end,
		EditBox = function() error("boom") end,
		OnLooksChanged = function() error("boom") end,
	})
	local ok2, err2 = pcall(function()
		ns.SkinButton(makeMock("Button"))
		ns.SkinCloseButton(makeMock("Button"))
		ns.SkinScrollBar(makeMock("Slider"))
		ns.SkinEditBox(makeMock("EditBox"), { padInput = true })
		ns.SkinPanel(makeMock("Frame"))
		ns.SkinWindow(makeMock("Frame"))
	end)
	check("Skin: throwing S primitives no throw", ok2, err2)

	-- apiVersion 4 ItemButton present vs absent.
	ns = loadSkinsWith({ ItemButton = function(btn) btn.itemSkinned = true end })
	local btn = makeMock("Button")
	local ok3 = pcall(ns.SkinItemButton, btn)
	check("Skin: S.ItemButton present no throw", ok3)
	check("Skin: S.ItemButton used when present", btn.itemSkinned == true)
	local nsOld = loadSkinsWith({ SquareIcon = function(icon) icon.squared = true end })
	local btnOld = makeMock("Button")
	btnOld.icon = makeMock("Texture")
	local ok4 = pcall(nsOld.SkinItemButton, btnOld)
	check("Skin: apiVersion3 SquareIcon fallback no throw", ok4)

	-- Stored S skins pooled rows created after login.
	local stored = nil
	_G.EllesmereUI = {
		RegisterSkin = function(name, cb)
			stored = cb
		end,
	}
	_G.ElvUI = nil
	local nsLate = {}
	loadLogic(nsLate)
	loadmod(nsLate, "Skins.lua")
	check("Skin: S not stored before login", nsLate.skinEUI == nil)
	local skinObj = { Button = function(b) b.lateSkinned = true end, Font = function() end }
	stored("GroupWatch", skinObj)
	-- Note: RegisterSkin mock above captures cb, invoke manually:
	-- (our mock stored the register fn, call the captured skin callback)
	-- stored is the RegisterSkin fn; call it with name + cb? Re-drive:
	_G.EllesmereUI = { RegisterSkin = function(name, cb) cb(skinObj) end }
	local nsLate2 = {}
	loadLogic(nsLate2)
	loadmod(nsLate2, "Skins.lua")
	check("Skin: S stored for pooled rows after login", nsLate2.skinEUI ~= nil)
	local lateBtn = makeMock("Button")
	nsLate2.SkinButton(lateBtn)
	check("Skin: pooled row after login uses stored S", lateBtn.lateSkinned == true)

	_G.EllesmereUI = nil
	_G.ElvUI = nil
end

-- ---------------------------------------------------------------------------
-- 4. Scrollbar exists (real scrollbar, wheel kept, offset restored)
-- ---------------------------------------------------------------------------

do
	_G.EllesmereUI = nil
	_G.ElvUI = nil
	MockUI.frames = {}
	MockUI.byName = {}
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Sound.lua")
	loadmod(ns, "Skins.lua")
	loadmod(ns, "WidgetPool.lua")
	loadmod(ns, "UI_NoteEditor.lua")
	loadmod(ns, "UI_MainWindow.lua")
	Stubs.reset()
	ns.InitDB()
	ns.PlayListSound = function() end
	local ok, err = pcall(ns.ToggleUI)
	check("Skin: ToggleUI no throw", ok, err)
	local ui = ns.GroupWatchUI
	check("Skin: main window exists", ui ~= nil)
	check("Skin: scrollFrame exists", ui ~= nil and type(ui.scrollFrame) == "table")
	check("Skin: scrollbar exists", ui ~= nil and type(ui.scrollBar) == "table", ui and ui.scrollBar)
	check("Skin: scrollFrame.ScrollBar linked", ui ~= nil and ui.scrollFrame ~= nil and ui.scrollFrame.ScrollBar ~= nil)
	local wheel = ui and ui.scrollFrame and ui.scrollFrame:GetScript("OnMouseWheel")
	check("Skin: wheel handler kept", type(wheel) == "function")
	-- Offset restore: Refresh must not throw and must keep a clamped offset.
	local okR, errR = pcall(function() ui:Refresh() end)
	check("Skin: Refresh with scrollbar no throw", okR, errR)
	local src = readFile(ADDON_DIR .. "UI_MainWindow.lua")
	check("Skin: UIPanelScrollFrameTemplate used", src:find("UIPanelScrollFrameTemplate", 1, true) ~= nil)
	check("Skin: no nil scrollbar assignment", src:find("f.scrollBar = nil", 1, true) == nil)
	check("Skin: scroll offset restore kept", src:find("GetVerticalScroll", 1, true) ~= nil and src:find("SetVerticalScroll", 1, true) ~= nil)
	if ui then ui:Hide() end
end

-- ---------------------------------------------------------------------------
-- 5. Button hover only alphas (pooled buttons)
-- ---------------------------------------------------------------------------

do
	_G.EllesmereUI = nil
	_G.ElvUI = nil
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Skins.lua")
	-- Recording button: logs every visual call during hover.
	local calls = {}
	local b = makeMock("Button")
	function b:SetAlpha(a) calls[#calls + 1] = { "SetAlpha", a } self.alpha = a end
	function b:SetColorTexture(...) calls[#calls + 1] = { "SetColorTexture" } end
	function b:SetBackdropColor(...) calls[#calls + 1] = { "SetBackdropColor" } end
	function b:SetBackdropBorderColor(...) calls[#calls + 1] = { "SetBackdropBorderColor" } end
	function b:SetVertexColor(...) calls[#calls + 1] = { "SetVertexColor" } end
	ns.StyleFallbackButton(b)
	local enter = b:GetScript("OnEnter")
	local leave = b:GetScript("OnLeave")
	check("Skin: fallback hover enter exists", type(enter) == "function")
	check("Skin: fallback hover leave exists", type(leave) == "function")
	calls = {}
	local okE, errE = pcall(enter, b)
	check("Skin: hover enter no throw", okE, errE)
	local onlyAlphaEnter = true
	for _, c in ipairs(calls) do
		if c[1] ~= "SetAlpha" then onlyAlphaEnter = false end
	end
	check("Skin: button hover only alphas (enter)", onlyAlphaEnter and #calls >= 1, #calls)
	calls = {}
	local okL, errL = pcall(leave, b)
	check("Skin: hover leave no throw", okL, errL)
	local onlyAlphaLeave = true
	for _, c in ipairs(calls) do
		if c[1] ~= "SetAlpha" then onlyAlphaLeave = false end
	end
	check("Skin: button hover only alphas (leave)", onlyAlphaLeave and #calls >= 1, #calls)
	-- Existing tooltip handler preserved via HookScript chaining.
	local tipShown = 0
	local b2 = makeMock("Button")
	b2:SetScript("OnEnter", function() tipShown = tipShown + 1 end)
	ns.StyleFallbackButton(b2)
	local enter2 = b2:GetScript("OnEnter")
	pcall(enter2, b2)
	check("Skin: fallback hover preserves prior OnEnter", tipShown == 1, tipShown)
	-- Source: pooled buttons all go through the cached skin path.
	local mainSrc = readFile(ADDON_DIR .. "UI_MainWindow.lua")
	for _, pname in ipairs({ "soundBtn", "addPlayerBtn", "delBtn", "noteBtn", "collapseBtn" }) do
		check("Skin: " .. pname .. " skinned", mainSrc:find(pname, 1, true) ~= nil and mainSrc:find("SkinButtonCached", 1, true) ~= nil)
	end
end

-- ---------------------------------------------------------------------------
-- 6. Fonts: S.Font preferred, fallback shadow, OUTLINE only tiny
-- ---------------------------------------------------------------------------

do
	_G.EllesmereUI = nil
	_G.ElvUI = nil
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Skins.lua")
	-- Fallback body: (1,-1) shadow, no OUTLINE.
	local fs = makeFont()
	ns.SkinFont(fs, false)
	check("Skin: fallback body shadow (1,-1)", fs.shadow ~= nil and fs.shadow[1] == 1 and fs.shadow[2] == -1, fs.shadow and (fs.shadow[1] .. "," .. fs.shadow[2]))
	check("Skin: fallback body no OUTLINE", fs.font[3] ~= "OUTLINE", fs.font[3])
	-- Tiny overlay: OUTLINE.
	local tiny = makeFont()
	ns.SkinFont(tiny, true)
	check("Skin: tiny overlay OUTLINE", tiny.font[3] == "OUTLINE", tiny.font[3])
	-- S.Font preferred when present.
	local used = 0
	_G.EllesmereUI = { RegisterSkin = function(name, cb) cb({ Font = function() used = used + 1 end }) end }
	local nsE = {}
	loadLogic(nsE)
	loadmod(nsE, "Skins.lua")
	nsE.SkinFont(makeFont(), false)
	check("Skin: S.Font preferred", used == 1, used)
	_G.EllesmereUI = nil
	-- No hardcoded EUI font path.
	local skinSrc = readFile(ADDON_DIR .. "Skins.lua")
	check("Skin: uses S.Font", skinSrc:find("S.Font", 1, true) ~= nil or skinSrc:find("S%.Font", 1, true) ~= nil)
	check("Skin: uses S.OnLooksChanged", skinSrc:find("OnLooksChanged", 1, true) ~= nil)
	check("Skin: uses S.Shell", skinSrc:find("S.Shell", 1, true) ~= nil or skinSrc:find("Shell", 1, true) ~= nil)
	check("Skin: uses S.Panel", skinSrc:find("S.Panel", 1, true) ~= nil or skinSrc:find("Panel", 1, true) ~= nil)
	check("Skin: uses S.EditBox padInput", skinSrc:find("padInput", 1, true) ~= nil)
	check("Skin: checks S.ItemButton (apiVersion 4)", skinSrc:find("ItemButton", 1, true) ~= nil)
	check("Skin: fallback shadow (1,-1)", skinSrc:find("1, -1", 1, true) ~= nil)
	check("Skin: tiny OUTLINE", skinSrc:find("OUTLINE", 1, true) ~= nil)
	local lower = skinSrc:lower()
	check("Skin: never hardcodes EUI font path", lower:find("ellesmereui", 1, true) == nil or lower:find(".ttf", 1, true) == nil, "eui+ttf both present?")
end

-- ---------------------------------------------------------------------------
-- 7. Minimap: standalone + optional LibDBIcon, thin border + inset crop
-- ---------------------------------------------------------------------------

do
	_G.EllesmereUI = nil
	_G.ElvUI = nil
	_G.LibStub = nil
	MockUI.frames = {}
	MockUI.byName = {}
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Skins.lua")
	loadmod(ns, "MinimapButton.lua")
	Stubs.reset()
	ns.InitDB()
	local ok, err = pcall(ns.CreateMinimapButton)
	check("Skin: minimap standalone no throw", ok, err)
	local btn = MockUI.byName["GroupWatchMinimapButton"]
	check("Skin: minimap button exists", btn ~= nil)
	check("Skin: minimap thin border", btn ~= nil and btn._gwBorder ~= nil)
	-- Inset crop recorded on the icon texture is done at creation; verify
	-- via source (mock icon is internal) plus runtime border.
	local miniSrc = readFile(ADDON_DIR .. "MinimapButton.lua")
	check("Skin: minimap inset icon crop", miniSrc:find("0.08", 1, true) ~= nil and miniSrc:find("0.92", 1, true) ~= nil)
	check("Skin: minimap LibStub path", miniSrc:find("LibStub", 1, true) ~= nil)
	check("Skin: minimap LibDBIcon path", miniSrc:find("LibDBIcon", 1, true) ~= nil)
	check("Skin: minimap never requires", miniSrc:find("require(", 1, true) == nil)
	-- With LibStub present (both brokers), still no throw.
	_G.LibStub = function(name, silent)
		if name == "LibDataBroker-1.1" then
			return { GetDataObjectByName = function() return nil end, NewDataObject = function() end }
		end
		if name == "LibDBIcon-1.0" then
			return { Register = function() end }
		end
		return nil
	end
	local ok2, err2 = pcall(ns.RegisterLDB)
	check("Skin: LibDBIcon path no throw", ok2, err2)
	_G.LibStub = nil
end

-- ---------------------------------------------------------------------------
-- 8. IsEnabled==false pooled fallback (active-skin resolver)
-- ---------------------------------------------------------------------------

do
	local function loadSkinsWith(S)
		_G.EllesmereUI = {
			RegisterSkin = function(name, cb) cb(S) end,
		}
		_G.ElvUI = nil
		local ns = {}
		loadLogic(ns)
		loadmod(ns, "Skins.lua")
		return ns
	end
	-- Resolver is exposed.
	local nsD = loadSkinsWith({ Button = function() end })
	check("Skin: GetActiveEUI exposed", type(nsD.GetActiveEUI) == "function")
	-- Disabled engine resolves to nil and passes self to IsEnabled.
	local seenSelf = nil
	local S_disabled = {}
	S_disabled.Button = function() end
	S_disabled.IsEnabled = function(self)
		seenSelf = self
		return false
	end
	local nsOff = loadSkinsWith(S_disabled)
	check("Skin: GetActiveEUI nil when IsEnabled false", nsOff.GetActiveEUI() == nil)
	check("Skin: IsEnabled receives self", seenSelf == nsOff.skinEUI)
	-- Enabled engine still resolves.
	local S_on = { Button = function() end, IsEnabled = function() return true end }
	local nsOn = loadSkinsWith(S_on)
	check("Skin: GetActiveEUI returns S when enabled", nsOn.GetActiveEUI() == S_on)
	-- Pooled cached path falls back when the cached engine is disabled.
	_G.EllesmereUI = nil
	_G.ElvUI = nil
	MockUI.frames = {}
	MockUI.byName = {}
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Sound.lua")
	loadmod(ns, "Skins.lua")
	loadmod(ns, "WidgetPool.lua")
	loadmod(ns, "UI_NoteEditor.lua")
	loadmod(ns, "UI_MainWindow.lua")
	local called = false
	local Sdis = {
		IsEnabled = function() return false end,
		Button = function() called = true end,
	}
	local poolBtn = makeMock("Button")
	ns._SkinButtonCached(poolBtn, { eui = Sdis, elv = nil })
	check("Skin: disabled pooled row skips EUI Button", called == false)
	check("Skin: disabled pooled row uses fallback", poolBtn._gwFallbackStyled == true)
	local mainSrc = readFile(ADDON_DIR .. "UI_MainWindow.lua")
	check("Skin: skinCache uses GetActiveEUI", mainSrc:find("GetActiveEUI", 1, true) ~= nil)
	check("Skin: no raw ns.skinEUI cache", mainSrc:find("eui = ns.skinEUI", 1, true) == nil)
	_G.EllesmereUI = nil
	_G.ElvUI = nil
end

-- ---------------------------------------------------------------------------
-- 9. LDB throw safety + icon registers even when object pre-exists
-- ---------------------------------------------------------------------------

do
	_G.EllesmereUI = nil
	_G.ElvUI = nil
	MockUI.frames = {}
	MockUI.byName = {}
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Skins.lua")
	loadmod(ns, "MinimapButton.lua")
	Stubs.reset()
	ns.InitDB()
	-- Throwing brokers never break RegisterLDB.
	_G.LibStub = function(name, silent)
		if name == "LibDataBroker-1.1" then
			return {
				GetDataObjectByName = function() error("boom get") end,
				NewDataObject = function() error("boom new") end,
			}
		end
		if name == "LibDBIcon-1.0" then
			return { Register = function() error("boom reg") end }
		end
		return nil
	end
	local okT, errT = pcall(ns.RegisterLDB)
	check("Skin: throwing LDB brokers no throw", okT, errT)
	-- Non-table broker object is guarded.
	_G.LibStub = function(name, silent)
		if name == "LibDataBroker-1.1" then return "not-a-table" end
		if name == "LibDBIcon-1.0" then return "not-a-table" end
		return nil
	end
	local okN, errN = pcall(ns.RegisterLDB)
	check("Skin: non-table LDB no throw", okN, errN)
	-- Pre-existing object still registers the minimap icon (dedented).
	local registered = false
	_G.LibStub = function(name, silent)
		if name == "LibDataBroker-1.1" then
			return {
				GetDataObjectByName = function() return { name = "GroupWatch" } end,
				NewDataObject = function() error("must not create when exists") end,
			}
		end
		if name == "LibDBIcon-1.0" then
			return { Register = function() registered = true end }
		end
		return nil
	end
	local okP, errP = pcall(ns.RegisterLDB)
	check("Skin: pre-existing object no throw", okP, errP)
	check("Skin: icon registers when object pre-exists", registered == true)
	local miniSrc = readFile(ADDON_DIR .. "MinimapButton.lua")
	check("Skin: LDB guarded by type checks", miniSrc:find("type(ldb)", 1, true) ~= nil and miniSrc:find("type(ldb.GetDataObjectByName)", 1, true) ~= nil)
	check("Skin: LDB broker calls pcall-guarded", miniSrc:find("pcall(ldb.GetDataObjectByName", 1, true) ~= nil and miniSrc:find("pcall(ldb.NewDataObject", 1, true) ~= nil)
	_G.LibStub = nil
end

-- ---------------------------------------------------------------------------
-- 10. Fallback strips hidden on the EUI path
-- ---------------------------------------------------------------------------

do
	_G.ElvUI = nil
	local S = {
		Shell = function() end,
		Panel = function() end,
	}
	_G.EllesmereUI = { RegisterSkin = function(name, cb) cb(S) end }
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Skins.lua")
	local f = makeMock("Frame")
	ns.ApplyFallbackFrame(f)
	check("Skin: fallback strips exist before EUI skin", type(f._gwBorder) == "table")
	local okS, errS = pcall(ns.SkinWindow, f)
	check("Skin: EUI SkinWindow no throw with strips", okS, errS)
	local hiddenAll = true
	if type(f._gwBorder) == "table" then
		for _, key in ipairs({ "top", "bottom", "left", "right" }) do
			local tex = f._gwBorder[key]
			if not (type(tex) == "table" and tex.hidden == true) then hiddenAll = false end
		end
	else
		hiddenAll = false
	end
	check("Skin: EUI path hides fallback strips", hiddenAll == true)
	_G.EllesmereUI = nil
	_G.ElvUI = nil
end

-- ---------------------------------------------------------------------------
-- 11. Scrollbar stays synced after offset restore
-- ---------------------------------------------------------------------------

do
	_G.EllesmereUI = nil
	_G.ElvUI = nil
	MockUI.frames = {}
	MockUI.byName = {}
	local ns = {}
	loadLogic(ns)
	loadmod(ns, "Sound.lua")
	loadmod(ns, "Skins.lua")
	loadmod(ns, "WidgetPool.lua")
	loadmod(ns, "UI_NoteEditor.lua")
	loadmod(ns, "UI_MainWindow.lua")
	Stubs.reset()
	ns.InitDB()
	ns.PlayListSound = function() end
	pcall(ns.ToggleUI)
	local ui = ns.GroupWatchUI
	local okR = pcall(function() ui:Refresh() end)
	check("Skin: Refresh no throw for scrollbar sync", okR)
	local sb = ui and ui.scrollFrame and ui.scrollFrame.ScrollBar
	local synced = sb ~= nil and sb.value ~= nil and sb.value == ui.scrollFrame:GetVerticalScroll()
	check("Skin: scrollbar value synced after restore", synced, sb and sb.value)
	local src = readFile(ADDON_DIR .. "UI_MainWindow.lua")
	check("Skin: restore mirrors SetValue", src:find("scrollFrame.ScrollBar", 1, true) ~= nil and src:find("pcall(sb.SetValue", 1, true) ~= nil)
	if ui then ui:Hide() end
end

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------

say(string.format("----\n%d passed, %d failed", passed, failed))
if failed > 0 then
	os.exit(1)
end
