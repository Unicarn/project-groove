local OldUnitBuffs = require "wargroove/unit_buffs"
local Wargroove = require "wargroove/wargroove"

local TempUnits = require "temp_units"

local UnitBuffs = {}

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local CopyUnitBuffs = deepcopy(OldUnitBuffs)

function UnitBuffs.init()
    OldUnitBuffs.getBuffs = UnitBuffs.getBuffs
    OldUnitBuffs.TempUnits = UnitBuffs.TempUnits
end

function UnitBuffs:getBuffs()
    local overhealAnimation = "ui/icons/overheal"

    local OldBuffs = CopyUnitBuffs.getBuffs()

    for tempUnitName, origUnitName in pairs(TempUnits.reverse) do
        function tempFunction(Wargroove, unit)
            if Wargroove.isSimulating() then
                return
            end
        
            if unit.playerId ~= Wargroove.getCurrentPlayerId() then
                unit.unitClassId = origUnitName
                unit.grooveCharge = 0
                Wargroove.updateUnit(unit)
            end
        end

        OldBuffs[tempUnitName] = tempFunction
    end

    function TravelboatBuff(Wargroove, unit)
        if Wargroove.isSimulating() then
            return
        end

        if unit.playerId ~= Wargroove.getCurrentPlayerId() then
            if (Wargroove.getUnitState(unit, "freeTurnUsed") == "true") then
                Wargroove.setUnitState(unit, "freeTurnUsed", "false")
                Wargroove.updateUnit(unit)
            end
        end
    end

    function DarkMerciaBuff(Wargroove, unit)
        if Wargroove.isSimulating() then
            return
        end
        if (unit.health > 100) then
            if not Wargroove.hasUnitEffect(unit.id, overhealAnimation) then
                Wargroove.spawnUnitEffect(unit.id, overhealAnimation, "overheal", startAnimation, true, false)
            end
        elseif Wargroove.hasUnitEffect(unit.id, overhealAnimation) then
            Wargroove.deleteUnitEffectByAnimation(unit.id, overhealAnimation)
        end
    end

    OldBuffs['travelboat'] = TravelboatBuff
    OldBuffs['commander_darkmercia'] = DarkMerciaBuff

    return OldBuffs
end

return UnitBuffs