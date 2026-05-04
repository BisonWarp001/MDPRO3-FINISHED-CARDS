-- Archangel Repha’ya, the Luminous Herald
local s,id=GetID()
function s.initial_effect(c)
    -- (1) Especial desde GY + Add Nivel 10 + Summon
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_TO_GRAVE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- (2) Restricción Extra Deck (DARK)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(1,0)
    e2:SetTarget(s.splimit)
    c:RegisterEffect(e2)

    -- (3) Reciclar Solomonite desde el GY
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetCountLimit(1,id+1)
    e3:SetTarget(s.rectg)
    e3:SetOperation(s.recop)
    c:RegisterEffect(e3)
end

s.listed_series={0x3e8}

-- (1) Lógica Special Summon + Add + Summon
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_HAND+LOCATION_DECK)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.thfilter(c)
    return c:IsLevel(10) and c:IsAbleToHand()
end
function s.sumfilter(c)
    return c:IsLevel(10) and c:IsSummonable(true,nil)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        -- Parte opcional: Añadir Nivel 10
        local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
        if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local sg=g:Select(tp,1,1,nil)
            if Duel.SendtoHand(sg,nil,REASON_EFFECT)>0 then
                Duel.ConfirmCards(1-tp,sg)
                -- Parte opcional: Invocación Normal inmediata
                local sc=sg:GetFirst()
                if sc:IsSummonable(true,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
                    Duel.Summon(tp,sc,true,nil)
                end
            end
        end
    end
end

-- (2) Restricción de Extra Deck
function s.splimit(e,c,sump,sumtyp,sumpos,targetp,se)
    return not c:IsAttribute(ATTRIBUTE_DARK) and c:IsLocation(LOCATION_EXTRA)
end

-- (3) Lógica de Reciclaje (Shuffle self, Add target)
function s.recfilter(c)
    return c:IsSetCard(0x3e8) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.recfilter(chkc) end
    if chk==0 then return e:GetHandler():IsAbleToDeck() 
        and Duel.IsExistingTarget(s.recfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(tp,s.recfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.recop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
        if tc:IsRelateToEffect(e) then
            Duel.SendtoHand(tc,nil,REASON_EFFECT)
        end
    end
end
