function PrintTable(t, indent, done)
    --print ( string.format ('PrintTable type %s', type(keys)) )
    if type(t) ~= "table" then return end

    done = done or {}
    done[t] = true
    indent = indent or 0

    local l = {}
    for k, v in pairs(t) do
        table.insert(l, k)
    end

    table.sort(l)
    for k, v in ipairs(l) do
        -- Ignore FDesc
        if v ~= 'FDesc' then
            local value = t[v]

            if type(value) == "table" and not done[value] then
                done [value] = true
                print(string.rep ("\t", indent)..tostring(v)..":")
                PrintTable (value, indent + 2, done)
            elseif type(value) == "userdata" and not done[value] then
                done [value] = true
                print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
                PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
            else
                if t.FDesc and t.FDesc[v] then
                    print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
                else
                    print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
                end
            end
        end
    end
end

function ShallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function TableCount( t )
    local n = 0
    for _ in pairs( t ) do
        n = n + 1
    end
    return n
end

function ShallowTableCompareStrict( t1, t2 )
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end

    -- if length is not the same, false
    if TableCount(t1) ~= TableCount(t2) then return false end

    -- check each value 
    for i=1, TableCount(t1) do
        if t1[i] ~= t2[i] then return false end
    end

    -- everything checked out
    return true
end

function ShallowTableCompareLoose( t1, t2 )
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end

    -- if the length is not the same, false
    if TableCount(t1) ~= TableCount(t2) then return false end

    -- create a table to work with
    local t2_temp = ShallowCopy(t2)

    -- look for t1's values in all of t2, if found remove from t2_temp, otherwise return false
    for _, v in pairs(t1) do
        local found = false
        for k, w in pairs(t2_temp) do
            if v == w and not found then
                t2_temp[w] = nil
                found = true
            end
        end
        if not found then return false end
    end

    return true
end