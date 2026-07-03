--The Divine Gods Test
local s,id=GetID()

function s.initial_effect(c)
    aux.AddCodeList(c,10000000,10000010,10000020)

    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.spfilter(c,e,tp)
    return c:IsCode(10000000,10000010,10000020)
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SPECIAL,tp,true,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>=3
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,
                LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,
                0,3,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,3,tp,
        LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<3 then return end

    local codes={10000000,10000010,10000020}

    for _,code in ipairs(codes) do
        local g=Duel.GetMatchingGroup(
            aux.NecroValleyFilter(function(c)
                return c:IsCode(code)
                    and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SPECIAL,tp,true,false)
            end),
            tp,
            LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,
            0,nil)

        local tc=g:GetFirst()
        if tc then
            Duel.SpecialSummonStep(tc,SUMMON_TYPE_SPECIAL,tp,tp,true,false,POS_FACEUP)
            tc:CompleteProcedure()
        end
    end

    Duel.SpecialSummonComplete()
end