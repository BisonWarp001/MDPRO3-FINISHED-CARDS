--Archangel Malak’el, the Prime Vanguard
local s,id=GetID()
function s.initial_effect(c)
    -- (1) Special Summon desde la mano
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- (2) Add 1 "Archangel" monster (Normal o Especial desde MANO)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,id+1)
    e2:SetTarget(s.addtg)
    e2:SetOperation(s.addop)
    c:RegisterEffect(e2)
    local e2b=e2:Clone()
    e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2b:SetCondition(s.hndcon) -- Solo si viene de mano como pide el texto
    c:RegisterEffect(e2b)

    -- (3) Destruir Spell/Trap en End Phase
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_DESTROY)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_PHASE+PHASE_END)
    e3:SetRange(LOCATION_GY)
    e3:SetCountLimit(1,id+2)
    e3:SetCondition(s.descon)
    e3:SetTarget(s.destg)
    e3:SetOperation(s.desop)
    c:RegisterEffect(e3)
end

-- Filtro del Arquetipo (Ajusta 0x3e8 si ese es tu SetCode real)
s.listed_series={0x3e8}

-- (1) Lógica Special Summon
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 
        or Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- (2) Lógica de Búsqueda
function s.hndcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_HAND)
end
function s.addfilter(c)
    return c:IsSetCard(0x3e8) and c:IsType(TYPE_MONSTER) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.addtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.addfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.addop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.addfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- (3) Lógica de Destrucción
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_TO_GRAVE) -- Verifica que fue enviado al cementerio
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_SZONE,nil,TYPE_SPELL+TYPE_TRAP)
    if chk==0 then return #g>0 end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectMatchingCard(tp,Card.IsType,tp,0,LOCATION_SZONE,1,1,nil,TYPE_SPELL+TYPE_TRAP)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end
