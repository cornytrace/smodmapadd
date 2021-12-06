local env = {
    table=table,
    math=math,
    PrintTable=PrintTable,
    tonumber=tonumber,
    tostring=tostring
}
local HL2 = {}
env.HL2 = HL2

local _R = debug.getregistry()

// Global Functions

function env.print(...)
    _G["print"]("[mapadd] Lua: ", ...)
end

env.VECTORZERO = {x=0,y=0,z=0}

env.DISPOSITION = {D_HT=D_HT,
                   D_FR=D_FR,
                   D_LI=D_LI,
                   D_NU=D_NU}

local disptostr = {D_HT="D_HT",
                   D_FR="D_FR",
                   D_LI="D_LI",
                   D_NU="D_NU"}

// General Functions

function HL2.GetDateMD()
    if MAPADDDEBUG then
        return "1225"
    else
        return os.date("%m%d")
    end
end

function HL2.CurrentMapName()
    return game.GetMap()
end

function HL2.ChangeLevel(map)
    RunConsoleCommand("map", map)
end

function HL2.CallMapaddLabel(labelname)
    SmodTriggerLabel(labelname)
end

local money = 0
function HL2.GetMoney()
    return money
end

function HL2.SetMoney(amount)
    money = amount
end

// Vectors

-- smod vector to gmod vector
local function svtogv(sv)
    return Vector(sv[1], sv[2], sv[3])
end

local function gvtosv(gv)
    return HL2.Vector(gv.x, gv.y, gv.z)
end

-- smod vector to gmod angle
local function svtoga(sv)
    return Angle(sv[1], sv[2], sv[3])
end

local function gatosv(ga)
    return HL2.Vector(ga.pitch, ga.yaw, ga.roll)
end

function HL2.Vector(x, y, z)
    return {x,y,z}
end

function HL2.VectorString(vec)
    return table.concat(vec, " ")
end

function HL2.DotProduct(v1, v2)
    return gvtosv(svtogv(v1):Dot(svtogv(v2)))
end

function HL2.VectorLength(v1, v2)
    return gvtosv(svtogv(v1):Distance(svtogv(v2)))
end

function HL2.VectorNormalize(vec)
    return gvtosv(svtogv(vec):Normalize())
end

function HL2.AngleVectors(ang)
    return gvtosv(gvtosa(ang):Forward())
end

function HL2.VectorAngles(vec)
    return gatosv(svtogv(vec):Angle())
end

// Entity Handling

function HL2.EntFire(targetname, activator, input, parameter, delay)
    local entities = ents.FindByName(targetname)
    for i,ent in ipairs(entities) do
        -- todo: set caller to activator or nil?
        ent:Fire(input, parameter, delay, activator, activator)
    end
end

function HL2.GetEntInfo(ent)
    local Entinfo = {}
    Entinfo.Health = ent:Health()
    Entinfo.Classname = ent:GetClass()
    Entinfo.ModelName = ent:GetModel()
    Entinfo.IsAlive = (ent:Health() > 0) and 1 or 0
    Entinfo.IsNpc = ent:IsNPC() and 1 or 0
    Entinfo.IsPlayer = ent:IsPlayer() and 1 or 0
    Entinfo.Owner = ent:GetOwner()
    Entinfo.Name = ent:GetName()
    return Entinfo
end

function HL2.GetAbsOrigin(ent)
    return ent:GetPos()
end

HL2.GetEntityAbsOrigin = HL2.GetAbsOrigin

function HL2.SetAbsOrigin(ent, pos)
    ent:SetPos(svtogv(pos))
end

HL2.SetEntityAbsOrigin = HL2.SetAbsOrigin

function HL2.GetAbsAngles(ent)
    return ent:GetAngles()
end

HL2.GetEntityAbsAngles = HL2.GetAbsAngles

function HL2.SetAbsAngles(ent, ang)
    ent:SetAngles(svtoga(ang))
end

HL2.SetEntityAbsAngles = HL2.SetAbsAngles

function HL2.GetAbsVelocity(ent)
    return ent:GetAbsVelocity()
end

function HL2.EyePosition(ent)
    return gvtosv(ent:GetAttachment(ent:LookupAttachment("eyes"))["Pos"])
end

function HL2.EyeAngles(ent)
    return gatosv(ent:GetAttachment(ent:LookupAttachment("eyes"))["Ang"])
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

function HL2.FindEntityByClass(ent, classname)
    local entities = ents.FindByClass(classname)
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

function HL2.CreateEntity(classname, origin, angle)
    local ent = SmodEntsCreate(classname)
    if ent:IsValid() then
        ent:SetPos(svtogv(origin))
        ent:SetAngles(svtoga(angle))
    else
        ent = nil
    end
    return ent
end

function HL2.SetEntityOwner(owner, ent)
    ent:SetOwner(owner)
end

function HL2.SetEntityParent(parent, child, attach)
    if attach then
        child:SetParent(parent, parent:LookupAttachment(attach))
    else
        child:SetParent(parent)
    end
end

function HL2.SetEntityMoveType(ent, movetype)
    ent:SetMoveType(movetype)
end

function HL2.SetEntityPhysVelocity(ent, vel)
    local physobj = ent:GetPhysicsObject()
    if not IsValid(physobj) then return end
    physobj.SetVelocity(svtogv(vel))
end

function HL2.SetEntityLocalOrigin(ent, pos)
    ent:SetLocalPos(svtogv(pos))
end

function HL2.SetEntityLocalAngles(ent, ang)
    ent:SetLocalAngles(svtoga(ang))
end

function HL2.SetModel(ent, modelname)
    if file.Exists(modelname, "GAME") then
        ent:SetModel(modelname)
        ent:PhysicsInit(SOLID_VPHYSICS)
    end
end

function HL2.SpawnEntity(ent)
    ent:Spawn()
end

function HL2.RemoveEntity(ent)
    ent:Remove()
end

function HL2.GetPlayer()
    if not game.SinglePlayer() then
        print("[mapadd] GetPlayer not implemented yet for multiplayer, mapadd may not work correctly!")
    end
    return Entity(1)
end

-- todo: Does this check for collision with world or only entities?
function HL2.CheckRoom(origin, mins, maxs)
    return (#ents.FindInBox(svtogv(mins), svtogv(maxs)) == 0) and 1 or 0
end

function HL2.CheckVisible(ent1, ent2)
    local visinfo = {}
    visinfo.IsVisible = ent1:Visible(ent2) and 1 or 0
    visinfo.Length = (ent1:GetPos()-ent2:GetPos()):Length()
    -- todo
    visinfo.AngleYaw = 0
    visinfo.AnglePitch = 0

    return visinfo
end

// Entity Relationships

function HL2.SetEntityRelationship(ent1, ent2orclass, disposition, priority)
    if not ent1:IsNPC() then return end
    if(type(ent2orclass) == "string") then
        ent1:AddRelationship(ent2orclass..disptostr[disposition]..priority)
    elseif IsEntity(ent2orclass) and IsValid(ent2orclass) then
        ent1:AddEntityRelationship(ent2orclass, disposition, priority)
    end
end

function HL2.SetEntityRelationshipName(ent1, targetname, disposition, priority)
    if not ent1:IsNPC() then return end
    local entities = ents.FindByName(targetname)
    for i,ent in ipairs(entities) do
            ent1:AddEntityRelationship(ent, disposition, priority)
    end
end

function HL2.SetEntityRelationshipName2(target1, target2, disposition, priority)
    local ents1 = ents.FindByName(target1)
    local ents2 = ents.FindByName(target2)
    for i,ent1 in ipairs(ents1) do
        for i2,ent2 in ipairs(ents2) do
            if ent1:IsNPC() then
                ent1:AddEntityRelationship(ent2, disposition, priority)
            end
        end
    end
end

// Player Messages
function HL2.ShowHUDMessage(text)
    PrintMessage(HUD_PRINTCENTER, msg)
end

function HL2.ShowInfoMessage(color, time, msg)
    -- todo
    PrintMessage(HUD_PRINTCENTER, msg)
end

function HL2.TimeStr(time)
    local mins = math.floor(time/60)
    local secs = math.floor(time)%60
    return mins..":"..secs
end

// Hooks and Timers
local HookKilledCallback
function HL2.HookKilledEvent(func)
    if type(func) == "string" then
        func = env[func]
    end
    HookKilledCallback = func
end

hook.Remove("PostEntityTakeDamage", "smodmapadd")
hook.Add("PostEntityTakeDamage", "smodmapadd", function(ent, dmg, took)
    if HookKilledCallback == nil or not took or ent:Health() > 0 then return end

    local info = {}
    info.IsPlayer = ent:IsPlayer() and 1 or 0
    info.IsNPC = ent:IsNPC() and 1 or 0
    info.Attacker = dmg:GetAttacker()
    info.DamageType = dmg:GetDamageType()
    info.Damage = dmg:GetDamage()
    info.AmmoType = dmg:GetAmmoType()
    info.KilledEnt = ent
    if ent:IsNPC() then
        info.Relation = ent:Disposition(info.Attacker)
    end

    HookKilledCallback(info)

end)

function HL2.CreateTimer(func, interval, ...)
    local args = {...}
    if type(func) == "string" then
        func = env[func]
    end
    local timername = "smodmapadd:"..tostring(func)..":"..os.time()
    timer.Create(timername, interval, 0, function() 
        local result = func(unpack(args))
        if result == 0 then
            timer.Stop(timername)
        end
    end)
end

// Random

function HL2.RandomSeed(num)
    if num ~= nil then
        math.randomseed(num)
    end
end

function HL2.RandomInt(min, max)
    return math.random(min, max)
end

function HL2.RandomFloat(min, max)
    return ((max-min) * math.random()) + min
end

// Sounds

function HL2.PlaySoundPos(soundname, origin)
    EmitSound(soundname, svtogv(origin))
end

function HL2.PlaySoundEntity(soundname, ent)
    ent:EmitSound(soundname)
end

// AI Nodes

function HL2.GetNodeCounts()
    if _R.Nodegraph == nil then
        return 0
    end
    return #_R.Nodegraph.Read():GetNodes()
end

function HL2.GetNodeData(nodeid)
    if _R.Nodegraph == nil then
        return nil 
    end
    local node = _R.Nodegraph.Read():GetNodes()[nodeid+1]
    return {x=node.pos[1], y=node.pos[2], z=node.pos[3], yaw=node.yaw, type=node.type}
end 

// Work Vars

local stringarray = {}
function HL2.SaveString(idx, str)
    stringarray[idx] = str
end

function HL2.LoadString(idx)
    return stringarray[idx]
end

_luaworkvar1 = {}
function HL2.StoreWorkVar(idx, str)
    _luaworkvar1[idx] = str
end

function HL2.GetWorkVar(idx)
    return _luaworkvar1[idx]
end

// DEBUG

local function setDebugMeta(tbl)
    local function mapadddbg(key, func, ...)
        return function(...) 
            local args = {}
            for i,v in ipairs({...}) do
                table.insert(args,tostring(v))
            end
            local args = table.concat(args, ", ")
            print("[mapadd] DEBUG: Calling function "..key.."("..args..")") 
            local retvalue = func(...)
            print("[mapadd] DEBUG: "..key.." returning "..tostring(retvalue))
            return retvalue
        end
    end 
    local proxy = {}
    local meta = {
        __index = function(proxy, key)
            local res = tbl[key]
            if type(res) == "function" then
                return mapadddbg(key, res)
            end
            return res
        end,

        __newindex = function(t,k,v)
            tbl[k] = v
        end
    }
    setmetatable(proxy, meta)

    return proxy
end

if MAPADDDEBUG then
    env.HL2 = setDebugMeta(HL2)
    return setDebugMeta(env)
end

return env