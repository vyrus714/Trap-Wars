-- wrap functions in a class to avoid naming issues
if Util == nil then
    Util = class({})
end

function Util:PrintTable(t, indent, done)
    --print ( string.format ('PrintTable type %s', type(keys)) )
    if type(t) ~= "table" then return end

    done = done or {}
    done[t] = true
    indent = indent or 0

    local l = {}
    for k, v in pairs(t) do
        table.insert(l, k)
    end

    --table.sort(l)
    for k, v in ipairs(l) do
        -- Ignore FDesc
        if v ~= 'FDesc' then
            local value = t[v]

            if type(value) == "table" and not done[value] then
                done [value] = true
                print(string.rep ("\t", indent)..tostring(v)..":")
                Util:PrintTable (value, indent + 2, done)
            elseif type(value) == "userdata" and not done[value] then
                done [value] = true
                print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
                Util:PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
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

function Util:ShallowCopy(orig)
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

function Util:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Util:DeepCopy(orig_key)] = Util:DeepCopy(orig_value)
        end
        setmetatable(copy, Util:DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Util:TableCount(t)
    local n = 0
    for _ in pairs( t ) do
        n = n + 1
    end
    return n
end

function Util:ShallowTableCompareStrict(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end

    -- if length is not the same, false
    if Util:TableCount(t1) ~= Util:TableCount(t2) then return false end

    -- check each value 
    for i=1, Util:TableCount(t1) do
        if t1[i] ~= t2[i] then return false end
    end

    -- everything checked out
    return true
end

function Util:ShallowTableCompareLoose(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end

    -- if the length is not the same, false
    if Util:TableCount(t1) ~= Util:TableCount(t2) then return false end

    -- create a table to work with
    local t2_temp = Util:ShallowCopy(t2)

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

-- distance between two points in 2d or 3d, wants a Vector() -or- table with x,y,z values
function Util:Distance(point1, point2)
    local inside = (point2.x-point1.x)^2 + (point2.y-point1.y)^2
    if type(point1.z) == "number" and type(point2.z) == "number" then
        inside = inside + (point2.z-point1.z)^2
    end

    return math.sqrt(inside)
end



-- valve forgot a few math lib functions: http://lua-users.org/wiki/InfAndNanComparisons
-- Gives 1 if value is +inf, -1 for -inf, and false otherwise (even for NaN)
function math.isinf(value)
    if type(value) ~= "number" then return false end
    if value == math.huge then return 1 end
    if value == -math.huge then return -1 end
    return false
end

-- Gives true if value is NaN and false otherwise
function math.isnan(value)
    if type(value) ~= "number" then return true end
    if value ~= value then return true end
    return false
end

-- Gives true if value is not NaN and not +/-inf and false otherwise
function math.finite(value)
    if type(value) ~= "number" then return false end
    if -math.huge < value and value < math.huge then return true end
    return false
end

-- this one isn't in lua's math lib, however it is present in javascript's
-- returns -1, 0, 1, NaN for negative numbers, 0, positive numbers, non-numbers
function math.sign(value)
    if type(value) ~= "number" then return 0/0 end
    if value < 0 then return -1 end
    if value > 0 then return  1 end

    return 0
end

-- this implementation of lua seems to use an incorrect implementation of the % (modulo) operator
-- http://lua-users.org/lists/lua-l/2007-10/msg00079.html
-- http://www.lua.org/manual/5.1/manual.html#2.5.1   <- this is wrong if you take 'a' as a negative number (math.floor(2.1)=2  math.floor(-2.1)=3)
-- this method keeps the same sign as the dividend (a)
--[[function math.mod(a, b)
    local sign = math.sign(a)
    a, b = math.abs(a), math.abs(b)

    return (a - math.floor(a/b)*b) * sign
end]]
-- math.fmod(a, b) works correctly, and is already included