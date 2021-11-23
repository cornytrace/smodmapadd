local MAPADDDEBUG = true
local _R = debug.getregistry()

if SERVER then

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
                print_mad("Not precaching "..key.." "..value..", not supported by gmod.")
            end
        end
    end

    local function StrToVec(posstr)
        local pos = string.Split(posstr," ")
        return Vector(pos[1],pos[2],pos[3])
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

    local function HandleRandomSpawn(kv)
        if _R.Nodegraph == nil then
            print_mad("Nodegraph library not found, unable to handle random spawns")
            return
        elseif nodes == nil then
            print_mad("Reading nodegraph")
            nodes = _R.Nodegraph.Read():GetNodes()
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
                local ent = ents.Create(key)
                if not IsValid(ent) then continue end

                local pos = GetRandomNodePosition()
                ent:SetPos(pos)

                print_mad("Creating "..key.." "..i.." of "..value["count"].." at "..tostring(pos))

                if value["model"] then
                    ent:SetModel(value["model"])
                end

                if value["targetname"] then
                    ent:SetKeyValue("targetname", value["targetname"])
                end

                if value["values"] then
                    local values = string.Split(value["values"]," ")
                    for i=1,#values,2 do
                        ent:SetKeyValue(values[i],values[i+1])
                    end
                end

                if v["stabilize"] then
                    print_ma("stabilize keyword not yet implemented")
                end

                if v["patrol"] then
                    ent:Fire("StartPatrolling")
                end

                if v["weapon"] then
                    ent:SetKeyValue("additionalequipment", v["weapon"])
                else
                    if ent:IsNPC() then
                        local weapons = {"weapon_smg1", "weapon_ar2", "weapon_shotgun"}
                        if key == "npc_citizen" or key == "npc_metropolice" then
                            table.insert(weapons,"weapon_pistol")
                        end
                        ent:SetKeyValue("additionalequipment", weapons[math.random(#weapons)])
                    end
                end

                if v["grenade"] then
                    ent:SetKeyValue("NumGrenades", v["grenade"])
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

    local function HandleEntities(key, value)
        for i,v in ipairs(value) do
            local k = v["Key"]
            local v = UnpreserveOrder(v["Value"])

            if k == "event" then
                for i,ent in ipairs(ents.FindByName(v["targetname"])) do
                    if IsValid(ent) then
                        ent:Fire(v["action"],v["value"] or "", v["delaytime"] or 0)
                    end
                end
                continue
            end

            if k == "lua" then
                print_mad("Calling mapadd func "..v["callfunc"])
                SmodMapaddLua[v["callfunc"]]()
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
                print_ma("Entity type "..k.." not yet supported")
                continue
            end

            if k == "player" then
                print_ma("Entity type "..k.." not yet supported")
                continue
            end

            print_mad("Spawning "..k.." at "..(v["origin"] or "0 0 0"))
            local ent = ents.Create(k)
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
            if lf then
                print_ma("Running lua code for map...")
                SmodMapaddLua = {}
                lf = string.gsub(lf,"(function%s*)","%1 SmodMapaddLua.") -- prefix functions to avoid lua global pollution
                RunString(lf, "SmodMapaddLua")
                if MAPADDDEBUG then
                    PrintTable(SmodMapaddLua)
                end
            else
                print_mad("No lua file found for map")
            end
        end

        print_ma("Loading mapadd file for current map...")
        
        -- repair keys without values
        local novalue = {"alwaysthink", "freeze", "longrange", "patrol", "patrolrandom"}
        for _,v in ipairs(novalue) do
            txt = string.gsub(txt, "(\""..v.."\")", "%1 \"1\"") 
        end
        
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
                HandleEntities(key,value)
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
                HandleEntities(labelname, value)
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

end