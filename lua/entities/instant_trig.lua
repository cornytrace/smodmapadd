AddCSLuaFile()

ENT.Type = "point"

if SERVER then
function ENT:Initialize()
    if self.timer then
       timer.Simple(tonumber(self.timer), function() self:Trigger() end) 
    end
end

function ENT:Think()
    if self.islived then
        local entities = ents.FindByName(self.islived)
        for i,ent in ipairs(entities) do
            if not IsValid(ent) then
                self:Trigger()
            end
        end
        if #entities == 0 then
            self:Trigger()
        end
    end

    if self.radius then 
        local entities
        if self.touchname ~= nil then
            entities = ents.FindByName(self.touchname)
        else
            entities = ents.FindByClass("player")
        end
        local pos = self:GetPos()
        for i,ent in ipairs(entities) do
            if not IsValid(ent) then continue end
            if pos:Distance(ent:GetPos()) < tonumber(self.radius) then
                self:Trigger()
            end
        end
    end
end

function ENT:KeyValue(key, value)
    self[string.lower(key)] = value
end

function ENT:Trigger()
    if self.label then
        SmodTriggerLabel(self.label)
    end
    if self.onhittrigger then
        local trigdata = string.Split(self.onhittrigger, ",")
        local entities = ents.FindByName(trigdata[1])
        for i,ent in ipairs(entities) do
            if IsValid(ent) then
                -- todo: handle trigdata[5]?
                ent:Fire(trigdata[2],trigdata[3],trigdata[4])
            end
        end
    end
    if self.removegroup ~= nil then
        local triggers = ents.FindByClass("instant_trig")
        for i,ent in ipairs(triggers) do
            if ent.group and ent.group == self.removegroup then
                ent:Remove()
            end
        end
    end
    if (self.noclear == nil) or (self.noclear and self.noclear == 0) then
        self:Remove()
    end
end
end