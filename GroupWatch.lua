local ADDON_NAME, ns = ...
local L = ns.L or setmetatable({}, { __index = function(t, k) return k end })

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
    return string.format(L["SOUND_CUSTOM"], soundID or 0)
end

local function GetDefaultListName()
    if GroupWatchDB and GroupWatchDB.lists then
        if GroupWatchDB.lists[L["DEFAULT_LIST_NAME"]] then return L["DEFAULT_LIST_NAME"] end
        if GroupWatchDB.lists["Standard"] then return "Standard" end
        if GroupWatchDB.lists["Default"] then return "Default" end
        for name in pairs(GroupWatchDB.lists) do return name end
    end
    return L["DEFAULT_LIST_NAME"]
end

local function IsDefaultList(listName)
    return listName == "Standard" or listName == "Default" or listName == L["DEFAULT_LIST_NAME"]
end

-- Initialize database
local function InitDB()
    if not GroupWatchDB then GroupWatchDB = {} end
    if not GroupWatchDB.lists then
        local defName = L["DEFAULT_LIST_NAME"]
        GroupWatchDB.lists = {
            [defName] = {
                message = L["DEFAULT_GROUP_MSG"],
                sound = DEFAULT_SOUND,
                collapsed = false,
                players = {}
            }
        }
    end
    if not GroupWatchDB.minimap then
        GroupWatchDB.minimap = {
            hide = false,
            angle = 225
        }
    end
end

local function GetFullName(unitOrName)
    if not unitOrName or unitOrName == "" then return nil end
    local name, realm = strsplit("-", unitOrName)
    if not name or name == "" then return nil end
    if not realm or realm == "" then
        realm = GetRealmName():gsub("%s+", "")
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
    if not fullName or fullName == "" then return end
    fullName = GetFullName(fullName)
    if not fullName then return end

    InitDB()
    listName = listName or GetDefaultListName()
    if not GroupWatchDB.lists[listName] then
        print("|cffffaa00[GroupWatch]|r " .. string.format(L["MSG_LIST_NOT_FOUND"], listName))
        return
    end

    GroupWatchDB.lists[listName].players[fullName] = true
    print("|cff00ff00[GroupWatch]|r " .. string.format(L["MSG_PLAYER_ADDED"], fullName, listName))
    if GroupWatchUI and GroupWatchUI:IsShown() then GroupWatchUI:Refresh() end
end

local function RemovePlayer(fullName, listName)
    if not fullName or fullName == "" then return end
    fullName = GetFullName(fullName)
    if not fullName then return end

    InitDB()
    for lName, lData in pairs(GroupWatchDB.lists) do
        if not listName or listName == lName then
            if lData.players[fullName] then
                lData.players[fullName] = nil
                print("|cffff0000[GroupWatch]|r " .. string.format(L["MSG_PLAYER_REMOVED"], fullName, lName))
            end
        end
    end
    if selectedPlayer == fullName then
        selectedPlayer = nil
    end
    if GroupWatchUI and GroupWatchUI:IsShown() then GroupWatchUI:Refresh() end
end

local function CreateList(listName)
    if not listName or listName == "" then return end
    InitDB()
    if GroupWatchDB.lists[listName] then
        print("|cffffaa00[GroupWatch]|r " .. string.format(L["MSG_LIST_EXISTS"], listName))
        return
    end

    GroupWatchDB.lists[listName] = {
        message = L["DEFAULT_GROUP_MSG"],
        sound = DEFAULT_SOUND,
        collapsed = false,
        players = {}
    }
    selectedList = listName
    print("|cff00ff00[GroupWatch]|r " .. string.format(L["MSG_LIST_CREATED"], listName))
    if GroupWatchUI and GroupWatchUI:IsShown() then GroupWatchUI:Refresh() end
end

local function DeleteList(listName)
    if not listName or listName == "" then return end
    if IsDefaultList(listName) then
        print("|cffff0000[GroupWatch]|r " .. L["MSG_CANNOT_DELETE_DEFAULT"])
        return
    end

    InitDB()
    if GroupWatchDB.lists[listName] then
        GroupWatchDB.lists[listName] = nil
        print("|cffff0000[GroupWatch]|r " .. string.format(L["MSG_LIST_DELETED"], listName))
        selectedList = GetDefaultListName()
        if GroupWatchUI and GroupWatchUI:IsShown() then GroupWatchUI:Refresh() end
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
    if not btn then return end
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
    if not btn then return end
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
    if not sb then return end
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
    if not f then return end

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
            if f.StripTextures then f:StripTextures() end
            if f.SetTemplate then
                f:SetTemplate("Transparent")
            elseif f.CreateBackdrop then
                f:CreateBackdrop("Transparent")
            end
        end
    end

    if f.closeBtn then SkinCloseButton(f.closeBtn) end
    if f.scrollBar then SkinScrollBar(f.scrollBar) end
    if f.dropDownBtn then SkinButton(f.dropDownBtn) end
    if f.newListBtn then SkinButton(f.newListBtn) end
    if f.delListBtn then SkinButton(f.delListBtn) end
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
-- MAIN UI
----------------------------------------------------
local function CreateUI()
    if GroupWatchUI then return GroupWatchUI end

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

    -- Only set default background & border if EllesmereUI or ElvUI is not active
    if not (skinEUI or IsElvUIPresent()) then
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
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
    local scrollFrame = CreateFrame("ScrollFrame", "GroupWatchScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -35, 65)

    local scrollBar = scrollFrame.ScrollBar or _G["GroupWatchScrollFrameScrollBar"]
    f.scrollFrame = scrollFrame
    f.scrollBar = scrollBar

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(320, 100)
    scrollFrame:SetScrollChild(content)

    f.content = content
    f.widgets = {}

    ----------------------------------------------------
    -- FOOTER: LIST CONTROLS
    ----------------------------------------------------
    local listLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    listLabel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 22)
    listLabel:SetText("|cffffd100" .. L["LISTS_LABEL"] .. "|r")
    f.listLabel = listLabel

    local dropDownBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    dropDownBtn:SetSize(170, 24)
    dropDownBtn:SetPoint("LEFT", listLabel, "RIGHT", 10, 0)
    dropDownBtn:SetText(GetDefaultListName())
    f.dropDownBtn = dropDownBtn

    dropDownBtn:SetScript("OnClick", function(self)
        if MenuUtil and MenuUtil.CreateContextMenu then
            MenuUtil.CreateContextMenu(self, function(ownerRegion, rootDescription)
                InitDB()
                for lName in pairs(GroupWatchDB.lists) do
                    rootDescription:CreateButton(lName, function()
                        selectedList = lName
                        dropDownBtn:SetText(lName)
                    end)
                end
            end)
        end
    end)

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

    -- Apply skin to window & base elements (if EUI / ElvUI active)
    SkinWindow(f)

    ----------------------------------------------------
    -- RENDER LIST
    ----------------------------------------------------
    function f:Refresh()
        for _, w in ipairs(self.widgets) do
            w:Hide()
        end
        self.widgets = {}

        if not GroupWatchDB or not GroupWatchDB.lists then return end

        if not selectedList or not GroupWatchDB.lists[selectedList] then
            selectedList = GetDefaultListName()
        end
        self.dropDownBtn:SetText(selectedList)

        local yOffset = -5

        for lName, lData in pairs(GroupWatchDB.lists) do
            if lData.collapsed == nil then lData.collapsed = false end

            -- Header container
            local headerRow = CreateFrame("Frame", nil, self.content)
            headerRow:SetSize(320, 22)
            headerRow:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, yOffset)
            table.insert(self.widgets, headerRow)

            -- Collapse/Expand button [−] / [+]
            local collapseBtn = CreateFrame("Button", nil, headerRow)
            collapseBtn:SetSize(18, 18)
            collapseBtn:SetPoint("LEFT", headerRow, "LEFT", 0, 0)
            
            local collapseText = collapseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            collapseText:SetPoint("CENTER", collapseBtn, "CENTER", 0, 0)
            collapseText:SetText(lData.collapsed and "|cffffd100[+]|r" or "|cffffd100[−]|r")

            collapseBtn:SetScript("OnClick", function()
                lData.collapsed = not lData.collapsed
                f:Refresh()
            end)
            SkinButton(collapseBtn)

            -- List title
            local headerText = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            headerText:SetPoint("LEFT", collapseBtn, "RIGHT", 6, 0)
            headerText:SetText("|cffffd100" .. lName .. "|r")
            if skinEUI and skinEUI.Font then
                skinEUI.Font(headerText)
            end

            -- Sound dropdown button after title
            local soundBtn = CreateFrame("Button", nil, headerRow, "UIPanelButtonTemplate")
            soundBtn:SetSize(100, 20)
            soundBtn:SetPoint("LEFT", headerText, "RIGHT", 8, 0)
            soundBtn:SetText(GetSoundNameByID(lData.sound))

            soundBtn:SetScript("OnClick", function(selfBtn)
                if MenuUtil and MenuUtil.CreateContextMenu then
                    MenuUtil.CreateContextMenu(selfBtn, function(ownerRegion, rootDescription)
                        for _, soundOpt in ipairs(SOUND_OPTIONS) do
                            rootDescription:CreateButton(soundOpt.name, function()
                                lData.sound = soundOpt.id
                                soundBtn:SetText(soundOpt.name)
                                if soundOpt.id > 0 then
                                    PlaySound(soundOpt.id, "Master")
                                end
                            end)
                        end
                    end)
                end
            end)
            SkinButton(soundBtn)

            -- (+) Button to add player to list
            local addPlayerBtn = CreateFrame("Button", nil, headerRow, "UIPanelButtonTemplate")
            addPlayerBtn:SetSize(22, 20)
            addPlayerBtn:SetPoint("RIGHT", headerRow, "RIGHT", 0, 0)
            addPlayerBtn:SetText("|cff00ff00+|r")
            addPlayerBtn:SetScript("OnClick", function()
                local dialog = StaticPopup_Show("GROUPWATCH_NEW_PLAYER")
                if dialog then
                    dialog.data = lName
                end
            end)
            SkinButton(addPlayerBtn)

            yOffset = yOffset - 26

            if not lData.collapsed then
                local count = 0
                if lData.players then
                    for pName in pairs(lData.players) do
                        count = count + 1

                        local row = CreateFrame("Button", nil, self.content)
                        row:SetSize(270, 20)
                        row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 20, yOffset)

                        local lineText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        lineText:SetPoint("LEFT", row, "LEFT", 0, 0)
                        if skinEUI and skinEUI.Font then
                            skinEUI.Font(lineText)
                        end

                        if selectedPlayer == pName then
                            lineText:SetText("|cff00ff00• " .. pName .. "|r")
                        else
                            lineText:SetText("• " .. pName)
                        end

                        row:SetScript("OnClick", function()
                            selectedPlayer = pName
                            selectedList = lName
                            f:Refresh()
                        end)
                        table.insert(self.widgets, row)

                        -- (−) Remove player button per row
                        local del = CreateFrame("Button", nil, self.content, "UIPanelButtonTemplate")
                        del:SetSize(20, 18)
                        del:SetPoint("LEFT", row, "RIGHT", 4, 0)
                        del:SetText("|cffff5555−|r")

                        del:SetScript("OnClick", function()
                            RemovePlayer(pName, lName)
                        end)
                        SkinButton(del)
                        table.insert(self.widgets, del)

                        yOffset = yOffset - 24
                    end
                end

                if count == 0 then
                    local empty = self.content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
                    empty:SetPoint("TOPLEFT", self.content, "TOPLEFT", 20, yOffset)
                    empty:SetText(L["NO_PLAYERS_IN_LIST"])
                    if skinEUI and skinEUI.Font then
                        skinEUI.Font(empty)
                    end
                    table.insert(self.widgets, empty)
                    yOffset = yOffset - 22
                end
            end

            yOffset = yOffset - 14
        end

        self.content:SetHeight(math.abs(yOffset) + 20)
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
    if not MinimapButton or not GroupWatchDB or not GroupWatchDB.minimap then return end
    local angle = math.rad(GroupWatchDB.minimap.angle or 225)
    local x = math.cos(angle) * BUTTON_RADIUS
    local y = math.sin(angle) * BUTTON_RADIUS
    MinimapButton:ClearAllPoints()
    MinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function UpdateMinimapButtonDrag()
    if not Minimap or not MinimapButton then return end
    local mx, my = Minimap:GetCenter()
    if not mx or not my then return end
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale() or (UIParent and UIParent:GetEffectiveScale()) or 1
    px = px / scale
    py = py / scale

    local angle = math.deg(math.atan2(py - my, px - mx))
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
    if MinimapButton then return MinimapButton end
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
    icon:SetTexture("Interface\\Icons\\inv_misc_groupneedmore")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

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
                            for _ in pairs(lData.players) do count = count + 1 end
                        end
                        rootDescription:CreateTitle(string.format(L["TOOLTIP_PLAYERS_COUNT"], lName, count))
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
            icon = "Interface\\Icons\\inv_misc_groupneedmore",
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
    if not IsInGroup() or not GroupWatchDB or not GroupWatchDB.lists then return end
    
    local numMembers = GetNumGroupMembers()
    local prefix = IsInRaid() and "raid" or "party"
    
    for i = 1, numMembers do
        local unit = (prefix == "party" and i == numMembers) and "player" or (prefix .. i)
        local name, realm = UnitName(unit)
        
        if name and unit ~= "player" then
            if not realm or realm == "" then
                realm = GetRealmName():gsub("%s+", "")
            end
            local fullName = name .. "-" .. realm
            
            for lName, lData in pairs(GroupWatchDB.lists) do
                if lData.players and lData.players[fullName] then
                    local outMsg = string.format(lData.message or L["DEFAULT_GROUP_MSG"], fullName)
                    print("|cffff0000[GroupWatch - " .. lName .. "]|r " .. outMsg)
                    if lData.sound and lData.sound > 0 then
                        PlaySound(lData.sound, "Master")
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

SlashCmdList["GROUPWATCH"] = function(msg)
    InitDB()
    local arg1, arg2, arg3 = strsplit(" ", msg or "", 3)
    arg1 = string.lower(arg1 or "")

    if arg1 == "list" or arg1 == "ui" or arg1 == "" then
        ToggleUI()
    elseif arg1 == "map" or arg1 == "minimap" then
        local willHide = not (GroupWatchDB.minimap and GroupWatchDB.minimap.hide)
        SetMinimapButtonShown(not willHide)
        print("|cff00ccff[GroupWatch]|r " .. (willHide and "|cffff0000" .. L["MINIMAP_DISABLED"] .. "|r" or "|cff00ff00" .. L["MINIMAP_ENABLED"] .. "|r"))
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
if Menu and Menu.ModifyMenu then
    Menu.ModifyMenu("MENU_UNIT_PLAYER", function(ownerRegion, rootDescription, contextData)
        if not contextData or not contextData.name then return end
        local name = contextData.name
        local realm = contextData.server
        
        if not realm or realm == "" then
            realm = GetRealmName():gsub("%s+", "")
        end
        local fullName = name .. "-" .. realm

        rootDescription:CreateDivider()
        local mainSubMenu = rootDescription:CreateButton("GroupWatch")

        InitDB()
        for lName, lData in pairs(GroupWatchDB.lists) do
            local listSubMenu = mainSubMenu:CreateButton(string.format(L["CONTEXT_LIST"], lName))
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
    end)
end

if IsLoggedIn and IsLoggedIn() then
    InitDB()
    CreateMinimapButton()
    RegisterLDB()
end