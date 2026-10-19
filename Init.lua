--[[
	GroupWatch — Init
	=================
	Event glue. Owns the single event frame and wires the modules together:

	  ADDON_LOADED        -> database init, minimap button, LDB data object
	  PLAYER_LOGIN        -> re-apply the skin if a UI library showed up late
	  GROUP_ROSTER_UPDATE -> scan the group for watched players
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local CreateFrame = G.CreateFrame
local IsLoggedIn = G.IsLoggedIn

local mainEventFrame = CreateFrame("Frame")
mainEventFrame:RegisterEvent("ADDON_LOADED")
mainEventFrame:RegisterEvent("PLAYER_LOGIN")
mainEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
mainEventFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "GroupWatch" then
		ns.InitDB()
		ns.CreateMinimapButton()
		ns.RegisterLDB()
	elseif event == "PLAYER_LOGIN" then
		-- The client indexes media files while it starts up, so this is the
		-- first moment the user's sound files can be found.
		ns.RefreshUserSounds()

		local ui = ns.GroupWatchUI
		if ui and (ns.skinEUI or ns.IsElvUIPresent()) then
			ns.SkinWindow(ui)
			ui:Refresh()
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		ns.CheckGroup()
	end
end)

-- Late-login guard: when the addon is loaded after PLAYER_LOGIN already fired.
if IsLoggedIn and IsLoggedIn() then
	ns.InitDB()
	ns.CreateMinimapButton()
	ns.RegisterLDB()
end
