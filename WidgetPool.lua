--[[
	GroupWatch — WidgetPool
	=======================
	Frame recycler.

	Instead of CreateFrame-ing every header/row/button on each Refresh() and
	merely hiding the old ones, each widget is created once and reused. Widgets
	store their dynamic data in a .data table so a single script closure can
	serve all widgets of a given kind. This eliminates garbage and frame bloat.
]]

local ADDON_NAME, ns = ...

local G = ns.Globals
local ipairs, pairs = G.ipairs, G.pairs
local table_insert = G.table_insert

local widgetPools = {}
local widgetMaster = {}

--- Return a recycled widget from `poolName`, creating one when the pool is
--- exhausted. The returned widget is flagged as in-use.
function ns.GetWidget(poolName, createFunc)
	local pool = widgetPools[poolName]
	if not pool then
		pool = {}
		widgetPools[poolName] = pool
	end
	for _, w in ipairs(pool) do
		if not w.inUse then
			w.inUse = true
			return w
		end
	end
	local w = createFunc()
	w.inUse = true
	table_insert(pool, w)
	table_insert(widgetMaster, w)
	return w
end

--- Release every widget of every pool and hide it.
---
--- Called at the start of a refresh: the widgets that are needed again are
--- re-acquired by ns.GetWidget() and shown by the caller, everything else
--- stays hidden. Hiding on release (instead of on the *next* release) is what
--- makes a removed row disappear immediately instead of lingering for one
--- extra refresh.
function ns.ReleaseUnused()
	for _, pool in pairs(widgetPools) do
		for _, w in ipairs(pool) do
			w.inUse = false
			w:Hide()
		end
	end
end
