HL2 = {}

function HL2.GetDateMD()
    return os.date("%m%d")
end

function HL2.CallMapaddLabel(labelname)
    SmodTriggerLabel(labelname)
end