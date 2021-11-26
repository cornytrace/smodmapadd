if SERVER then
local _R = debug.getregistry()

function ParseSnl()
    local path = "mapadd/nodes/"..game.GetMap()..".snl"
    print("Looking for "..path)
    local txt = file.Read(path, "GAME")
    if txt == nil then 
        print("Warning: "..path.." not found! Cannot add ai nodes to map!")
        return nil, nil 
    end
    local lines = string.Split(txt, "\n")
    local in_nodes = true -- if true we're parsing nodes, else we're parsing links
    local err = false
    local nodes = {}
    local links_dedup = {}
    for i,line in ipairs(lines) do
        line = string.TrimRight(line, "\r")
        if string.StartWith(line, "-") then 
            if in_nodes then 
                in_nodes = false 
                continue 
            else 
                break 
            end 
        end
        local tokens = string.Split(line, " ")
        if in_nodes then
            if #tokens ~= 7 or tokens[1] ~= "N" then 
                err = line
                break 
            end
            local node = {}
            node.hint = tonumber(string.sub(tokens[2],2))
            node.type = tonumber(tokens[3])
            node.pos = {tokens[4],tokens[5],tokens[6]}
            node.yaw = string.sub(tokens[7],1,#tokens[7]-1)
            table.insert(nodes, node)
        else
            if #tokens ~= 4 then
                err = line
                break
            end
            local link = {}
            link.type = tokens[1]
            link.src = tonumber(string.sub(tokens[2],2))
            link.dst = tonumber(tokens[3])
            link.move = {}
            -- we need to merge move_type from previous matching entries
            local move_type = tonumber(string.sub(tokens[4],1,#tokens[4]-1))
            local dedup_key = link.type.." "..link.src.." "..link.dst
            local check_dup = links_dedup[dedup_key]
            if check_dup ~= nil then
                move_type = bit.bor(move_type, check_dup.move[1])
            end
            for i=1,10 do
                link.move[i] = move_type
            end
            
            links_dedup[dedup_key] = link
        end
    end
    if err ~= false then
        print("Error while parsing .snl file at line "..err)
        return nil,nil
    end
    local links = {}
    for k,v in pairs(links_dedup) do
        table.insert(links,v)
    end
    return nodes, links
end

-- note that this function cannot check if the snl was already applied
function ApplySnl()
    local nodegraph = _R.Nodegraph.Read()
    local nodes = nodegraph:GetNodes()
    local snlnodes, snllinks = ParseSnl()
    if snlnodes == nil or snllinks == nil then
        return
    end

    local nodeoffset = #nodes + 1
    for i,node in ipairs(snlnodes) do
        print("addnode "..node.pos[1].." "..node.type)
        nodegraph:AddNode(node.pos,node.type,node.yaw)
    end
    for i,link in ipairs(snllinks) do
        if link.type == "L" then
            print("addlink "..nodeoffset + link.src.." "..nodeoffset + link.dst)
            nodegraph:AddLink(nodeoffset + link.src, nodeoffset + link.dst, link.move)
        elseif link.type == "I" then
            nodegraph:AddLink(nodeoffset + link.src, link.dst, link.move)
        elseif link.type == "O" then
            nodegraph:AddLink(link.src, nodeoffset + link.dst, link.move)
        end
    end

    nodegraph:Save()
    PrintMessage(HUD_PRINTTALK,"[smodmapadd] You must move data/nodegraph/"..game.GetMap()..".txt to maps/graphs/"..game.GetMap()..".ain and restart the map to enable ai movement and random spawns")
end

end