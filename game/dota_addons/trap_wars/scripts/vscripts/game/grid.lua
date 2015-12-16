-- some example grid names     If you've overlapped your grids with one another SHIT IS GOING TO GET FUCKED UP
DEFAULT_GRID_INFO = {  -- start: arithmetically lower corner  stop: arithmetically higher corner  size: indevidual tile size
	{ start="GridStart1", stop="GridStop1", size=128 },
	{ start="GridStart2", stop="GridStop2", size=128 }
}

-- create the context
if Grid == nil then
  print ( '[Grid] Welcome to the Grid.' )
  Grid = {}
  Grid.__index = Grid
end

-- returns a table of grid locations from the map based on DEFAULT_GRID_LOCATIONS, or an optional variable to take its place
function Grid:GetGridLocations( gridinfo )
	local gridinfo = gridinfo or DEFAULT_GRID_INFO
	local gridlist = {}

	for k,grid in pairs(gridinfo) do
		local estart = Entities:FindByName(nil, grid.start)
		local estop  = Entities:FindByName(nil, grid.stop)

		if estart and estop then
			gridlist[k] = { start=estart:GetAbsOrigin(), stop=estop:GetAbsOrigin(), size=grid.size }
		end
	end

	return gridlist
end

-- get the center of the tile nearest to a point, returns nil if not in a grid, returns from first grid found if multiple
function Grid:GetCenter( point, gridlist )
	-- if it's not a vector, gtfo
	if not point.x and not point.y then return nil end

	-- find the grid it's located in, if any
	for k,grid in pairs(gridlist) do
		if grid.start.x and grid.start.y and grid.stop.x and grid.stop.y and grid.size then
			if grid.start.x < point.x and point.x < grid.stop.x and grid.start.y < point.y and point.y < grid.stop.y then
				local offset = Vector(
					math.floor((point.x-grid.start.x)/grid.size)*grid.size,
					math.floor((point.y-grid.start.y)/grid.size)*grid.size,
					--math.floor((point.z-grid.start.z)/grid.size)*grid.size )
					0 )
				--local halftile = Vector(grid.size/2, grid.size/2, grid.size/2)
				local halftile = Vector(grid.size/2, grid.size/2, 0)
				return grid.start + offset + halftile
			end
		end
	end
	return nil  -- not in a grid
end

-- turn the grid into a table of numbers so javascript won't turn it into strings
function Grid:ConvertToJS( gridlist )
	local newgrids = {}
	for k,grid in ipairs(gridlist) do
		newgrids[k] = {
			start = { x=grid.start.x, y=grid.start.y, z=grid.start.z },
			stop  = { x=grid.stop.x,  y=grid.stop.y,  z=grid.stop.z  },
			size  = grid.size
		}
	end
	return newgrids
end

-- send grids to a custom net table so the UI knows where all the grids are:
function Grid:SendToJS( gridlist, name )
	CustomNetTables:SetTableValue("trap_wars_info", name, Grid:ConvertToJS( gridlist ))  -- send the grid to js
end

-- send a dummy entity for each player to use in the UI for particles (this should be called once when the player joins ect)
function Grid:SendDummyToJS( playerid )
    local DummyEntity = SpawnEntityFromTableSynchronous("prop_dynamic", {
    	origin = Vector(0, 0, -512),  -- put it below the map where we don't have to look @ it
        model  = "models/props_structures/radiant_statue001.vmdl",
        angles = Vector(0, 0, 0)
    })
    -- send the dummy to the UI
    CustomNetTables:SetTableValue("trap_wars_info", "dummy"..playerid, {DummyEntity:GetEntityIndex()} )
end