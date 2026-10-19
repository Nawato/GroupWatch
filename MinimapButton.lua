--[[
	GroupWatch — MinimapButton
	==========================
	The minimap icon (drag to reposition, click to toggle the main window) and
	the optional LibDataBroker data object.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local L = ns.L
local CreateFrame = G.CreateFrame
local GameTooltip = G.GameTooltip
local GetCursorPosition = G.GetCursorPosition
local Minimap, UIParent = G.Minimap, G.UIParent
local MenuUtil = G.MenuUtil
local math_atan2, math_cos, math_deg, math_rad, math_sin = G.math_atan2, G.math_cos, G.math_deg, G.math_rad, G.math_sin
local pairs = G.pairs
local string_format = G.string_format

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

	ns.InitDB()
	GroupWatchDB.minimap.angle = angle
	UpdateMinimapButtonPosition()
end

function ns.SetMinimapButtonShown(show)
	ns.InitDB()
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

function ns.CreateMinimapButton()
	if MinimapButton then
		return MinimapButton
	end
	ns.InitDB()

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
						ns.ToggleUI()
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
				ns.ToggleUI()
			end
		else
			ns.ToggleUI()
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

function ns.RegisterLDB()
	local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
	if ldb and not ldb:GetDataObjectByName("GroupWatch") then
		ldb:NewDataObject("GroupWatch", {
			type = "launcher",
			text = "GroupWatch",
			icon = "Interface\\AddOns\\GroupWatch\\Media\\icon_gw_wei.png",
			OnClick = function(_, mouseBtn)
				if mouseBtn == "LeftButton" then
					ns.ToggleUI()
				end
			end,
			OnTooltipShow = function(tooltip)
				tooltip:AddLine("|cff00ccffGroupWatch|r")
				tooltip:AddLine(L["TOOLTIP_LEFT_CLICK"], 1, 1, 1)
			end,
		})
	end
end
