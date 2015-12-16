-- get a tree of entities that are children of the first entity found by 'name'
function GetTreeFromName( name )
	local entity = Entities:FindByName(nil, name)
	if not entity then return nil end

	return GetTreeFromEntity(entity)
end

-- first index will always be the origin of the entity the current table is formed from, rest are children
function GetTreeFromEntity( entity )
	if not entity then return nil end
	local children = GetDirectChildren(entity)

	local info = { entity:GetAbsOrigin() }
	for i,child in ipairs(children) do
		if child:GetChildren() and #child:GetChildren() > 0 then
			table.insert(info, GetTreeFromEntity(child))
		else
			table.insert(info, { child:GetAbsOrigin() })
		end
	end

	return info
end

-- strip out children that aren't directly under 'entity'
function GetDirectChildren( entity )
	if not entity then return nil end
	local children = entity:GetChildren()

	for i,child in ipairs(children) do
		if not child:GetMoveParent() or child:GetMoveParent() ~= entity then
			table.remove(children, i)
		end
	end

	return children
end