--[[
Copyright (c) 2009, Hendrik "Nevcairiel" Leppkes < h.leppkes@gmail.com >
All rights reserved.
]]

local Mapster = LibStub("AceAddon-3.0"):NewAddon("Mapster", "AceEvent-3.0")

local LibWindow = LibStub("LibWindow-1.1")

local defaults = {
	profile = {
		strata = "HIGH",
		hideMapButton = false,
		arrowScale = 0.88,
		modules = {
			['*'] = true,
		},
		x = 0,
		y = 0,
		points = "CENTER",
		scale = 0.75,
		alpha = 1,
		hideBorder = false,
		disableMouse = false,
		mini = {
			x = 0,
			y = 0,
			point = "CENTER",
			scale = 1,
			alpha = 0.9,
			hideBorder = true,
			disableMouse = true,
		}
	}
}

-- Variables that are changed on "mini" mode
local miniList = { x = true, y = true, point = true, scale = true, alpha = true, hideBorder = true, disableMouse = true }

local db_
local db = setmetatable({}, {
	__index = function(t, k)
		if Mapster.miniMap and miniList[k] then
			return db_.mini[k]
		else
			return db_[k]
		end
	end,
	__newindex = function(t, k, v)
		if Mapster.miniMap and miniList[k] then
			db_.mini[k] = v
		else
			db_[k] = v
		end
	end
})

local format = string.format

local wmfOnShow, wmfStartMoving, wmfStopMoving, dropdownScaleFix

function Mapster:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("MapsterDB", defaults, "Default")
	db_ = self.db.profile

	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")

	self:SetupOptions()
end

-- local oldUIPanel,
local oldwmfOnKeyDown, realZone
function Mapster:OnEnable()
	local advanced, mini = GetCVarBool("advancedWorldMap"), GetCVarBool("miniWorldMap")
	SetCVar("miniWorldMap", nil)
	SetCVar("advancedWorldMap", nil)
	InterfaceOptionsObjectivesPanelAdvancedWorldMap:Disable()
	InterfaceOptionsObjectivesPanelAdvancedWorldMapText:SetTextColor(0.5,0.5,0.5)
	-- restore map to its vanilla state
	if mini then
		WorldMap_ToggleSizeUp()
	end
	if advanced then
		WorldMapFrame_ToggleAdvanced()
	end

	self:SetupMapButton()

	LibWindow.RegisterConfig(WorldMapFrame, db)

	local vis = WorldMapFrame:IsVisible()
	if vis then
		HideUIPanel(WorldMapFrame)
	end

	--oldUIPanel = UIPanelWindows["WorldMapFrame"]
	UIPanelWindows["WorldMapFrame"] = nil
	WorldMapFrame:SetAttribute("UIPanelLayout-enabled", false)
	WorldMapFrame:HookScript("OnShow", wmfOnShow)
	WorldMapFrame:HookScript("OnHide", wmfOnHide)
	BlackoutWorld:Hide()
	WorldMapTitleButton:Hide()

	oldwmfOnKeyDown = WorldMapFrame:GetScript("OnKeyDown")
	WorldMapFrame:SetScript("OnKeyDown", nil)

	WorldMapFrame:SetMovable(true)
	WorldMapFrame:RegisterForDrag("LeftButton")
	WorldMapFrame:SetScript("OnDragStart", wmfStartMoving)
	WorldMapFrame:SetScript("OnDragStop", wmfStopMoving)

	WorldMapFrame:SetParent(UIParent)
	WorldMapFrame:SetToplevel(true)
	WorldMapFrame:SetWidth(1024)
	WorldMapFrame:SetHeight(768)
	self:SetPosition()

	WorldMapContinentDropDownButton:SetScript("OnClick", dropdownScaleFix)
	WorldMapZoneDropDownButton:SetScript("OnClick", dropdownScaleFix)
	WorldMapZoneMinimapDropDownButton:SetScript("OnClick", dropdownScaleFix)

	WorldMapFrameSizeDownButton:SetScript("OnClick", function() Mapster:ToggleMapSize() end)
	WorldMapFrameSizeUpButton:SetScript("OnClick", function() Mapster:ToggleMapSize() end)

	self:SetAlpha()
	-- Apply all frame settings
	wmfOnShow(WorldMapFrame)

	hooksecurefunc(WorldMapTooltip, "Show", function(self)
		self:SetFrameStrata("TOOLTIP")
	end)

	-- fix hard-coded frame levels
	--[[hooksecurefunc("QuestPOI_DisplayButton", function(parentName, buttonType, buttonIndex)
		local buttonName = "poi"..parentName..buttonType.."_"..buttonIndex
		local poiButton = _G[buttonName]
		if not poiButton.MapsterLevelFix then
			poiButton.SetRealFrameLevel = poiButton.SetFrameLevel
			poiButton.SetFrameLevel = function() end
		end
	end)]]

	tinsert(UISpecialFrames, "WorldMapFrame")

	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

	self:SetArrow()
	self:UpdateBorderVisibility()
	self:UpdateMouseInteractivity()

	if vis then
		ShowUIPanel(WorldMapFrame)
	end
end

--[[
function Mapster:OnDisable()
	UIPanelWindows["WorldMapFrame"] = oldUIPanel
	WorldMapFrame:SetAttribute("UIPanelLayout-enabled", true)
	WorldMapFrame:SetScript("OnKeyDown", oldwmfOnKeyDown)
	BlackoutWorld:Show()
end
]]

function Mapster:Refresh()
	db_ = self.db.profile

	self:SetStrata()
	self:SetAlpha()
	self:SetArrow()
	self:SetScale()
	self:SetPosition()

	for k,v in self:IterateModules() do
		if self:GetModuleEnabled(k) and not v:IsEnabled() then
			self:EnableModule(k)
		elseif not self:GetModuleEnabled(k) and v:IsEnabled() then
			self:DisableModule(k)
		end
		if type(v.Refresh) == "function" then
			v:Refresh()
		end
	end

	if self.optionsButton then
		if db.hideMapButton then
			self.optionsButton:Hide()
		else
			self.optionsButton:Show()
		end
	end

	self:UpdateBorderVisibility()
	self:UpdateMouseInteractivity()
end


function Mapster:ToggleMapSize()
	self.miniMap = not self.miniMap
	ToggleFrame(WorldMapFrame)
	if self.miniMap then
		self:SizeDown()
	else
		self:SizeUp()
	end
	self:SetAlpha()
	self:SetPosition()

	-- Notify the modules about the map size change,
	-- so they can re-anchor frames or stuff like that.
	self:UpdateModuleMapsizes()

	self:UpdateBorderVisibility()
	self:UpdateMouseInteractivity()

	ToggleFrame(WorldMapFrame)
	WorldMapFrame_UpdateQuests()
end

function Mapster:UpdateModuleMapsizes()
	for k,v in self:IterateModules() do
		if v:IsEnabled() and type(v.UpdateMapsize) == "function" then
			v:UpdateMapsize(self.miniMap)
		end
	end
end

function Mapster:SizeUp()
	WorldMapFrame.sizedDown = false
	WorldMapFrame.scale = WORLDMAP_RATIO_SMALL
	-- adjust main frame
	WorldMapFrame:SetWidth(1024)
	WorldMapFrame:SetHeight(768)
	-- adjust map frames
	WorldMapPositioningGuide:ClearAllPoints()
	WorldMapPositioningGuide:SetPoint("CENTER")
	WorldMapDetailFrame:SetScale(WORLDMAP_RATIO_SMALL);
	WorldMapDetailFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -726, -99)
	WorldMapButton:SetScale(WORLDMAP_RATIO_SMALL)
	WorldMapFrameAreaFrame:SetScale(WORLDMAP_RATIO_SMALL)
	WorldMapPOIFrame.ratio = WORLDMAP_RATIO_SMALL
	WorldMapBlobFrame:SetScale(WORLDMAP_RATIO_SMALL)
	WorldMapBlobFrame.xRatio = nil		-- force hit recalculations
	-- show big window elements
	WorldMapZoneMinimapDropDown:Show()
	WorldMapZoomOutButton:Show()
	WorldMapZoneDropDown:Show()
	WorldMapContinentDropDown:Show()
	WorldMapLevelDropDown:Show()
	WorldMapQuestScrollFrame:Show()
	WorldMapQuestDetailScrollFrame:Show()
	WorldMapQuestRewardScrollFrame:Show()
	WorldMapFrameSizeDownButton:Show()
	-- hide small window elements
	WorldMapFrameMiniBorderLeft:Hide()
	WorldMapFrameMiniBorderRight:Hide()
	WorldMapFrameSizeUpButton:Hide()
	-- tiny adjustments
	WorldMapFrameCloseButton:SetPoint("TOPRIGHT", WorldMapPositioningGuide, 4, 4)
	WorldMapFrameSizeDownButton:SetPoint("TOPRIGHT", WorldMapPositioningGuide, -16, 4)
	WorldMapFrameTitle:ClearAllPoints()
	WorldMapFrameTitle:SetPoint("CENTER", 0, 372)

	WorldMapFrame_SetPOIMaxBounds()
	WorldMapQuestShowObjectives_AdjustPosition()

	self.optionsButton:SetPoint("BOTTOMLEFT", "WorldMapPositioningGuide", "BOTTOMLEFT", 5, 7)
end

function Mapster:SizeDown()
	WorldMapFrame.sizedDown = true
	WorldMapFrame.scale = WORLDMAP_RATIO_MINI
	WorldMapFrame.bigMap = nil
	-- adjust main frame
	WorldMapFrame:SetWidth(623)
	WorldMapFrame:SetHeight(437)
	-- adjust map frames
	WorldMapPositioningGuide:ClearAllPoints()
	WorldMapPositioningGuide:SetAllPoints()
	WorldMapDetailFrame:SetScale(WORLDMAP_RATIO_MINI)
	WorldMapDetailFrame:SetPoint("TOPLEFT", 37, -66)
	WorldMapButton:SetScale(WORLDMAP_RATIO_MINI)
	WorldMapFrameAreaFrame:SetScale(WORLDMAP_RATIO_MINI)
	WorldMapPOIFrame.ratio = WORLDMAP_RATIO_MINI
	WorldMapBlobFrame:SetScale(WORLDMAP_RATIO_MINI)
	WorldMapBlobFrame.xRatio = nil		-- force hit recalculations
	WorldMapFrameMiniBorderLeft:SetPoint("TOPLEFT", 10, -14)
	-- hide big window elements
	WorldMapZoneMinimapDropDown:Hide()
	WorldMapZoomOutButton:Hide()
	WorldMapZoneDropDown:Hide()
	WorldMapContinentDropDown:Hide()
	WorldMapLevelDropDown:Hide()
	WorldMapLevelUpButton:Hide()
	WorldMapLevelDownButton:Hide()
	WorldMapQuestScrollFrame:Hide()
	WorldMapQuestDetailScrollFrame:Hide()
	WorldMapQuestRewardScrollFrame:Hide()
	WorldMapFrameSizeDownButton:Hide()
	-- show small window elements
	WorldMapFrameMiniBorderLeft:Show()
	WorldMapFrameMiniBorderRight:Show()
	WorldMapFrameSizeUpButton:Show()
	-- tiny adjustments
	WorldMapFrameCloseButton:SetPoint("TOPRIGHT", WorldMapFrameMiniBorderRight, "TOPRIGHT", -44, 5)
	WorldMapFrameSizeDownButton:SetPoint("TOPRIGHT", WorldMapFrameMiniBorderRight, "TOPRIGHT", -66, 5)
	WorldMapFrameTitle:ClearAllPoints()
	WorldMapFrameTitle:SetPoint("TOP", WorldMapDetailFrame, 0, 20)

	WorldMapFrame_SetPOIMaxBounds()
	WorldMapQuestShowObjectives_AdjustPosition()

	self.optionsButton:SetPoint("BOTTOMLEFT", "WorldMapPositioningGuide", "BOTTOMLEFT", 16, -8)
end

local function getZoneId()
	return (GetCurrentMapZone() + GetCurrentMapContinent() * 100)
end

function Mapster:ZONE_CHANGED_NEW_AREA()
	local curZone = getZoneId()
	if realZone == curZone or ((curZone % 100) > 0 and (GetPlayerMapPosition("player")) ~= 0) then
		SetMapToCurrentZone()
		realZone = getZoneId()
	end
end

local oldBFMOnUpdate
function wmfOnShow(frame)
	Mapster:SetScale()
	Mapster:SetStrata()
	realZone = getZoneId()
	if BattlefieldMinimap then
		oldBFMOnUpdate = BattlefieldMinimap:GetScript("OnUpdate")
		BattlefieldMinimap:SetScript("OnUpdate", nil)
	end

	WORLDMAP_POI_FRAMELEVEL = WorldMapPOIFrame:GetFrameLevel() + 5
	WorldMapFrame_SelectQuest(WorldMapQuestScrollChildFrame.selected)
end

function wmfOnHide(frame)
	SetMapToCurrentZone()
	if BattlefieldMinimap then
		BattlefieldMinimap:SetScript("OnUpdate", oldBFMOnUpdate or BattlefieldMinimap_OnUpdate)
	end
end

function wmfStartMoving(frame)
	frame:StartMoving()
end

function wmfStopMoving(frame)
	frame:StopMovingOrSizing()
	LibWindow.SavePosition(frame)
end

function dropdownScaleFix(self)
	ToggleDropDownMenu(nil, nil, self:GetParent())
	DropDownList1:SetScale(db.scale)
end

function Mapster:SetStrata()
	WorldMapFrame:SetFrameStrata(db.strata)
	WorldMapDetailFrame:SetFrameStrata(db.strata)
end

function Mapster:SetAlpha()
	WorldMapFrame:SetAlpha(db.alpha)
end

function Mapster:SetArrow()
	PlayerArrowFrame:SetModelScale(db.arrowScale)
	PlayerArrowEffectFrame:SetModelScale(db.arrowScale)
end

function Mapster:SetScale()
	if WorldMapFrame:IsShown() then
		WorldMapFrame:SetScale(db.scale)
	end
end

function Mapster:SetPosition()
	LibWindow.RestorePosition(WorldMapFrame)
end

function Mapster:GetModuleEnabled(module)
	return db.modules[module]
end

function Mapster:UpdateBorderVisibility()
	if db.hideBorder then
		Mapster.bordersVisible = false
		if self.miniMap then
			WorldMapFrameMiniBorderLeft:Hide()
			WorldMapFrameMiniBorderRight:Hide()
			WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapDetailFrame, "TOPRIGHT", -50 - WorldMapQuestShowObjectivesText:GetWidth(), 2);
		else
			-- TODO
		end
		WorldMapFrameTitle:Hide()
		self:RegisterEvent("WORLD_MAP_UPDATE", "UpdateDetailTiles")
		self:UpdateDetailTiles()
		self.optionsButton:Hide()
	else
		Mapster.bordersVisible = true
		if self.miniMap then
			WorldMapFrameMiniBorderLeft:Show()
			WorldMapFrameMiniBorderRight:Show()
		else
			-- TODO
		end
		WorldMapQuestShowObjectives_AdjustPosition()
		WorldMapFrameTitle:Show()
		self:UnregisterEvent("WORLD_MAP_UPDATE")
		self:UpdateDetailTiles()
		if not db.hideMapButton then
			self.optionsButton:Show()
		end
	end

	for k,v in self:IterateModules() do
		if v:IsEnabled() and type(v.BorderVisibilityChanged) == "function" then
			v:BorderVisibilityChanged(not db.hideBorder)
		end
	end
end

function Mapster:UpdateMouseInteractivity()
	if db.disableMouse then
		WorldMapButton:EnableMouse(false)
		WorldMapFrame:EnableMouse(false)
	else
		WorldMapButton:EnableMouse(true)
		WorldMapFrame:EnableMouse(true)
	end
end


local function hasOverlays()
	if Mapster:GetModuleEnabled("FogClear") then
		return Mapster:GetModule("FogClear"):RealHasOverlays()
	else
		return GetNumMapOverlays() > 0
	end
end

function Mapster:UpdateDetailTiles()
	if db.hideBorder and GetCurrentMapZone() > 0 and hasOverlays() then
		for i=1, NUM_WORLDMAP_DETAIL_TILES do
			_G["WorldMapDetailTile"..i]:Hide()
		end
	else
		for i=1, NUM_WORLDMAP_DETAIL_TILES do
			_G["WorldMapDetailTile"..i]:Show()
		end
	end
end

function Mapster:SetModuleEnabled(module, value)
	local old = db.modules[module]
	db.modules[module] = value
	if old ~= value then
		if value then
			self:EnableModule(module)
		else
			self:DisableModule(module)
		end
	end
end
