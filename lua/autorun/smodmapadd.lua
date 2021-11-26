local MAPADDDEBUG = true
local _R = debug.getregistry()

if SERVER then
    include("snlparser.lua")

    SmodMapAddisPlayerSpawned = SmodMapAddisPlayerSpawned or false
    SmodMapAddisPlayerSpawning = SmodMapAddisPlayerSpawning or false
    local SmodMapAddHandleDelayed = {}
    local smod_strings = {}

    local function print_ma(text)
        print("[mapadd] "..text)
    end

    local function print_mad(text)
        if MAPADDDEBUG then
            print("[mapadd] DEBUG: "..text)
        end
    end

    -- Converts ipairs table back to pairs table
    local function UnpreserveOrder(tbl)
        local result = {}
        for i,v in ipairs(tbl) do
            result[v["Key"]] = v["Value"]
            if type(v["Value"]) == "table" then
                result[v["Key"]] = UnpreserveOrder(result[v["Key"]])
            end
        end
        return result
    end

    local function HandlePrecache(kv)
        for i, v in ipairs(kv) do
            key = v["Key"]
            value = v["Value"]
            if key == "model" then
                print_mad("Precaching model "..value)
                util.PrecacheModel(value)
            else
                --print_mad("Not precaching "..key.." "..value..", not supported by gmod.")
            end
        end
    end

    local function StrToVec(posstr)
        local pos = string.Split(posstr," ")
        return Vector(pos[1],pos[2],pos[3])
    end

    local function StrToAng(posstr)
        local pos = string.Split(posstr," ")
        return Angle(pos[1],pos[2],pos[3])
    end

    -- {{Vector pos, number radius}}
    local removenodes = {}
    local nodes
    local function GetRandomNodePosition()
        for i,node in ipairs(nodes) do
            for _,removenodes in ipairs(removenodes) do
                if node.pos:Distance(removenodes[1]) < removenodes[2] then
                    table.remove(nodes,i)
                end
            end
        end
        if #nodes > 0 then
            local choice = math.random(#nodes)
            local pos = nodes[choice].pos
            table.remove(nodes,choice)
            return pos
        else
            return nil 
        end
    end

    local function SmodFixupClassname(classname)
        local testent = ents.Create(classname)
        if not IsValid(testent) then
            for _,v in ipairs({"npc_combine_e","npc_combine_ace", "npc_combine_c", "npc_combine_p"}) do
                if v == classname then
                    return "npc_combine_s"
                end
            end
            for _,v in ipairs({"npc_laser_turret", "npc_f_laser_turret", "npc_rocket_turret", "npc_f_rocket_turret", "npc_f_crossbow_turret", "npc_f_turret_floor"}) do
                if v == classname then
                    return "npc_turret_floor"
                end
            end
            if classname == "npc_kscanner" then
                return "npc_scanner"
            end
            if classname == "weapon_ak47" then
                return "weapon_ak-47"
            end
        else
            testent:Remove()
        end
        return classname
    end

    local function SmodEntsCreate(classname)
        local ent = ents.Create(SmodFixupClassname(classname))
        if classname == "npc_combine_p" then
            ent:SetModel("models/combine_soldier_prisonguard.mdl")
        end
        if string.StartWith(classname,"npc_f_") then
            for k,v in pairs(list.get("NPC")) do
                if v["Category"] == "Humans + Resistance" then
                    ent:AddRelationship(k.." DT_LI 99")
                elseif v["Category"] == "Zombies + Enemy Aliens" then
                    ent:AddRelationship(k.." DT_HT 99")
                elseif v["Category"] == "Combine" then
                    ent:AddRelationship(k.." DT_HT 99")
                end
            end
        end
        return ent
    end

    local function HandleRandomSpawn(kv)
        if _R.Nodegraph == nil then
            print_mad("Nodegraph library not found, unable to handle random spawns")
            return
        elseif nodes == nil then
            print_mad("Reading nodegraph")
            nodes = _R.Nodegraph.Read():GetNodes()
            if #nodes == 0 then
                PrintMessage(HUD_PRINTTALK, "[smodmapadd] No ai nodegraph found!")
                if file.Exists("mapadd/nodes/"..game.GetMap()..".snl", "GAME") then
                    PrintMessage(HUD_PRINTTALK, "[smodmapadd] Generating nodegraph from SMOD .snl file...")
                    ApplySnl()
                end
            end
        end
        
        for i, v in ipairs(kv) do
            key = v["Key"]
            value = UnpreserveOrder(v["Value"])

            if(key == "removenodes") then
                local vec = StrToVec(value["origin"])
                local radius = value["radius"]
                table.insert(removenodes,{vec,radius})
                continue
            end

            if(key == "removeairnodes") then
                print_ma("removeairnodes not implemented")
                continue
            end

            if GetRandomNodePosition() == nil then
                print_ma("Error: No ai nodes left to randomspawn")
                return 
            end

            for i=1,value["count"] do
                local ent = SmodEntsCreate(key)
                if not IsValid(ent) then continue end

                local pos = GetRandomNodePosition()
                ent:SetPos(pos)

                print_mad("Creating "..key.." "..i.." of "..value["count"].." at "..tostring(pos))

                if value["model"] then
                    if file.Exists(value["model"], "GAME") then
                        ent:SetModel(value["model"])
                    else 
                        print_ma("Model not found: "..value["model"])
                    end
                end

                if value["targetname"] then
                    ent:SetKeyValue("targetname", value["targetname"])
                end

                if value["values"] then
                    local values = string.Replace(value["values"],"\t"," ")
                    values = string.Split(values, " ")
                    for i=1,#values,2 do
                        ent:SetKeyValue(values[i],values[i+1])
                    end
                end

                if value["stabilize"] then
                    print_ma("stabilize keyword not yet implemented")
                end

                if value["patrol"] then
                    ent:Fire("StartPatrolling")
                end

                if value["weapon"] then
                    local weapon = SmodFixupClassname(value["weapon"])
                    ent:SetKeyValue("additionalequipment", weapon)
                end

                if value["grenade"] then
                    ent:SetKeyValue("NumGrenades", value["grenade"])
                end

                ent:Spawn()
                ent:Activate()
            end

        end
    end

    smodRelTarget = {a={"npc_antlion","npc_antlionguard"},
                     c={"npc_combine_s", "npc_metropolice", "npc_cscanner", "npc_rollermine",
                        "npc_manhack", "npc_combinegunship", "npc_combinedropship", "npc_clawscanner",
                        "npc_turret_floor", "npc_turret_ground"},
                     g={"player"},
                     l={"npc_zombie", "npc_zombie_torso", "npc_headcrab", "npc_headcrab_fast", 
                        "npc_poisonzombie", "npc_fastzombie", "npc_fastzombie_torso"},
                     p={"npc_citizen"},
                     s={"npc_stalker"},
                     v={"npc_vortigaunt"}
                    }
    smodRelDispNum = {h=D_HT,
                      f=D_FR,
                      l=D_LI,
                      n=D_NU
                     }
    smodRelDispStr = {h="D_HT",
                      f="D_FR",
                      l="D_LI",
                      n="D_NU"
                     }
    -- ent can be entity or class name
    -- todo?: add relations to npcs spawned after this function is ran
    local function smodSetRelation(ent, rel)
        -- ent is class name string
        local targets = {}
        if type(ent) == string then
            targets = ents.FindByClass(ent)
        elseif IsValid(ent) then
            targets = {ent}
        end
        for i,v in ipairs(string.Split(rel," ")) do
            local destclasses = smodRelTarget[string.sub(v,1,1)]
            local disp = smodRelDispStr[string.sub(v,2,2)]
            local rank = string.sub(v,3,3)

            for i,target in ipairs(targets) do
                for i,destclass in ipairs(destclasses) do
                    local str = destclass.." "..disp.." "..rank
                    target:AddRelationship(str)
                end
            end

        end
    end

    local function HandleEntities(value)
        for i,section in ipairs(value) do
            local k = section["Key"]
            local v = UnpreserveOrder(section["Value"])

            if k == "event" then
                local entities = ents.FindByName(v["targetname"])
                if #entities == 0 then
                    print_ma("Warning: Firing event "..v["action"].." on non existent "..v["targetname"])
                end
                for i,ent in ipairs(entities) do
                    if IsValid(ent) then
                        ent:Fire(v["action"],v["value"] or "", v["delaytime"] or 0)
                    end
                end
                continue
            end

            if k == "lua" then
                print_mad("Calling mapadd func "..v["callfunc"])
                local func = SmodMapaddLua[v["callfunc"]]
                if func == nil then
                    print_ma("Error: Function "..v["callfunc"].." does not exist!")
                    continue
                end
                setfenv(func, SmodMapaddLua)
                local _,err = pcall(func)
                if err then
                    print_ma("Error while running mapadd func "..v["callfunc"]..": "..err)
                end
                continue
            end

            if k == "relation" then
                smodSetRelation(v["classname"], v["relation"])
                continue
            end

            if k == "removeentity" then
                if v["classname"] then
                    for i,ent in ipairs(ents.FindByClass(v["classname"])) do
                        if v["radius"] == nil or ent:GetPos():Distance(StrToVec(v["origin"])) < tonumber(v["radius"]) then
                            print_mad("Removing "..v["classname"])
                            ent:Remove()
                        end
                    end
                end
                if v["targetname"] then
                    for i,ent in ipairs(ents.FindByName(v["targetname"])) do
                        if v["radius"] == nil or ent:GetPos():Distance(StrToVec(v["origin"])) < tonumber(v["radius"]) then
                            print_mad("Removing "..v["targetname"])
                            ent:Remove()
                        end
                    end
                end
                continue
            end

            if k == "sound" then
                if v["targetname"] then
                    for i,ent in ipairs(ents.FindByName(v["targetname"])) do
                        ent:EmitSound(v["soundname"])
                    end
                elseif v["origin"] then
                    EmitSound(v["soundname"],v["origin"],0)
                end
                continue
            end

            if k == "player" then
                if not SmodMapAddisPlayerSpawning then
                    print_mad("Deferring player section until after first player spawns")
                    table.insert(SmodMapAddHandleDelayed,section)
                    continue
                end
                local players = player.GetHumans()
                print_mad("Found "..#players.." players")
                for i,ply in ipairs(players) do
                    if v["origin"] then
                        ply:SetPos(StrToVec(v["origin"]))
                    end
                    if v["angle"] then
                        ply:SetEyeAngles(StrToAng(v["angle"]))
                    end
                    if v["fadein"] then
                        ply:ScreenFade(SCREENFADE.IN,color_black,v["fadein"],0)
                    end
                    if v["fadeout"] then
                        ply:ScreenFade(SCREENFADE.OUT,color_black,v["fadeout"],0)
                    end
                    if v["message"] then
                        local msg = string.gsub(v["message"],"#[%w_]*",function(match) 
                            lmatch = string.sub(string.lower(match),2)
                            if smod_strings and smod_strings[lmatch] ~= nil then 
                                return smod_strings[lmatch] 
                            else 
                                return match 
                            end
                        end)
                        local delay = 0.5
                        -- initial spawn, so delay needs to be longer or message is gone before first scene draw
                        if not SmodMapAddisPlayerSpawned then
                            delay = 2
                        end
                        timer.Simple(delay,function() PrintMessage(HUD_PRINTCENTER, msg) end)
                    end
                    if v["music"] then
                        ply:SendLua("surface.PlaySound(\""..v["music"].."\")")
                    end
                    if v["kill"] then
                        ply:Kill()
                    end
                end
                continue
            end

            print_mad("Spawning "..k.." at "..(v["origin"] or "0 0 0"))
            local ent = SmodEntsCreate(k)
            if not IsValid(ent) then 
                print_ma("Spawning "..k.." failed!")
                continue 
            end
            if v["origin"] then
                local pos = StrToVec(v["origin"])
                ent:SetPos(pos)
            end
            if v["angle"] then
                local ang = string.Split(v["angle"], " ")
                ent:SetAngles(Angle(ang[1], ang[2], ang[3]))
            end
            if v["keyvalues"] then
                for k,v in pairs(v["keyvalues"]) do 
                    if k == "additionalequipment" then
                        v = SmodFixupClassname(v)
                    elseif k == "model" then
                        if not file.Exists(v, "GAME") then
                            print_ma("Model not found: "..v)
                            continue
                        end
                    end
                    ent:SetKeyValue(k,v)
                end
            end
            local spawnflags = 0
            if v["longrange"] then
                spawnflags = bit.bor(spawnflags, SF_NPC_LONG_RANGE)
            end
            if v["freeze"] then
                spawnflags = bit.bor(spawnflags, SF_PHYSBOX_MOTIONDISABLED)
            end
            if v["patrol"] then
                ent:Fire("StartPatrolling")
            end
            if v["relation"] then
                smodSetRelation(ent,v["relation"])
            end
            if v["alwaysthink"] then
                spawnflags = bit.bor(spawnflags, SF_NPC_ALWAYSTHINK)
            end
            if spawnflags > 0 then
                ent:SetKeyValue("spawnflags", spawnflags)
            end
            ent:Spawn()
            ent:Activate()
        end
        print_ma("Loading done")
    end

    local mapadd
    local function LoadMapAdd()
        SmodMapAddisGameLoaded = true
        local mapname = game.GetMap()

        local txt = file.Read("mapadd/"..mapname..".txt", "GAME")
        if txt == nil then
            txt = file.Read("mapadd/"..mapname..".txt", "DATA")
            if txt == nil then
                print_ma("No mapadd file found for "..mapname)
                return
            end
        end

        local lf = file.Read("mapadd/"..mapname..".lua", "GAME")
        if lf == nil then
            lf = file.Read("mapadd/"..mapname..".lua", "DATA")
        end
        if lf then
            print_ma("Running lua code for map...")
            SmodMapaddLua = include("smodluacompat.lua")
            local loadfunc = CompileString(lf,"SmodMapaddLua")
            setfenv(loadfunc,SmodMapaddLua)
            local _,err = pcall(loadfunc)
            if err then
                print_ma("Error while calling mapadd lua: "..err)
            elseif MAPADDDEBUG then
                PrintTable(SmodMapaddLua)
            end
        else
            print_mad("No lua file found for map")
        end

        local strfile = file.Read("resource/smod_english.txt", "GAME")
        if strfile ~= nil then
            print_ma("Loading smod strings")
            local strings = util.KeyValuesToTable(strfile, true, false)
            if strings ~= nil then
                smod_strings = strings["tokens"]
            else
                print_ma("Parsing resource/smod_english.txt failed! Check if the file is saved in UTF-8")
            end
        else
            print_ma("Cannot load resource/smod_english.txt, string localization not available")
        end

        print_ma("Loading mapadd file for current map...")
        
        -- repair keys without values
        local novalue = {"alwaysthink", "freeze", "longrange", "patrol", "patrolrandom", "activate"}
        for _,v in ipairs(novalue) do
            txt = string.gsub(txt, "(\""..v.."\")", "%1 \"1\"") 
        end

        txt = string.gsub(txt, "(\r?\n[ \t]*\"kill\")([ \t]*\r?\n)", "%1 \"1\"%2") -- kill is not only used as key without value, but also as targetname etc.
        
        if MAPADDDEBUG then
            file.Write("mapadd/"..mapname..".debug.txt", txt)
        end

        mapadd = util.KeyValuesToTablePreserveOrder("\"mapadd\" {"..txt.."}")

        for i,v in ipairs(mapadd) do
            local key = string.lower(v["Key"])
            local value = v["Value"]
            
            if key == "precache" then
                HandlePrecache(value)
            elseif key == "randomspawn" then
                HandleRandomSpawn(value)
            elseif key == "entities" then
                HandleEntities(value)
            end
        end
    end

    function SmodTriggerLabel(labelname)
        print_mad("Triggering label "..labelname)
        local keyname = "entities:"..string.lower(labelname)
        for i,v in ipairs(mapadd) do
            local key = string.lower(v["Key"])
            local value = v["Value"]
            if key == keyname then
                HandleEntities(value)
                return
            end
        end
        print_ma("Label "..labelname.." not found!")
    end

    hook.Remove("InitPostEntity", "smodmapadd")
    hook.Add("InitPostEntity", "smodmapadd", LoadMapAdd)

    if MAPADDDEBUG and SmodMapAddisGameLoaded then
        LoadMapAdd()
    end

    
    hook.Remove("PlayerSpawn", "smodmapadd")
    hook.Add("PlayerSpawn", "smodmapadd", function(ply)
        SmodMapAddisPlayerSpawning = true
        if #SmodMapAddHandleDelayed > 0 then
            print_mad("Handling deferred sections")
            HandleEntities(SmodMapAddHandleDelayed)
        end
        hook.Remove("PlayerSpawn", "smodmapadd")
        SmodMapAddisPlayerSpawned = true
    end)
end