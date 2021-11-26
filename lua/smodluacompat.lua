local HL2 = {}

function HL2.GetDateMD()
    --return os.date("%m%d")
    return "1225"
end

function HL2.CallMapaddLabel(labelname)
    SmodTriggerLabel(labelname)
end

function HL2.FindEntityByName(ent, targetname)
    local entities = ents.FindByName(targetname)
    if ent == nil and #entities > 0 then
        return entities[1]
    end
    for i,v in ipairs(entities) do
        if ent == v and #entities > i then
            return entities[i+1]
        end
    end

    return nil
end

function HL2.KeyValue(ent, key, value)
    ent:SetKeyValue(key, value)
end

local function print(...)
    _G["print"]("[mapadd] ", ...)
end

return {print=print, HL2=HL2}