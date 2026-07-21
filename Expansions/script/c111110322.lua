--Gardna the Big Shield
local s, id = GetID()

function s.initial_effect(c)
    -- EFECTO 1: Invocar desde la mano, equipar y redirigir ataque
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_ATTACK_ANNOUNCE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- EFECTO 2: Desequipar e Invocarse
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1, id+100)
    e2:SetTarget(s.sptg2)
    e2:SetOperation(s.spop2)
    c:RegisterEffect(e2)

    -- EFECTO 3: Si va del campo al GY -> Buscar Monstruo (Corregido con EVENT_TO_GRAVE)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 2))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_TO_GRAVE) -- <-- CORREGIDO: Cambiado a CONSTANTE exacta de EDOCore
    e3:SetCountLimit(1, id+200)
    e3:SetCondition(s.thcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

-- =========================================================================
-- LOGICA EFECTO 1
-- =========================================================================
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetAttacker():IsControler(1-tp)
end

-- Filtro 1 separado para Guerrero o Guerrero-Bestia
function s.filter1(c, e, tp)
    return (c:IsRace(RACE_WARRIOR) or c:IsRace(RACE_BEASTWARRIOR)) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and Duel.IsExistingMatchingCard(s.filter1, tp, LOCATION_HAND, 0, 1, e:GetHandler(), e, tp) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND)
    Duel.SetOperationInfo(0, CATEGORY_EQUIP, e:GetHandler(), 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
    if not c:IsRelateToEffect(e) then return end
    
    Duel.Hint(HINT_SELECTMSG, tp, HINTSEMSG_SPSUMMON)
    local g = Duel.SelectMatchingCard(tp, s.filter1, tp, LOCATION_HAND, 0, 1, 1, c, e, tp)
    local tc = g:GetFirst()
    
    if tc and Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP) ~= 0 then
        if not Duel.Equip(tp, c, tc) then return end
        
        local e1 = Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EQUIP_LIMIT)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetValue(function(e, c) return c == tc end)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e1)
        
        local def = c:GetDefense()
        local e2 = Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_EQUIP)
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        e2:SetValue(def)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e2)
        
        local a = Duel.GetAttacker()
        if a and a:IsAttackable() and not a:IsImmuneToEffect(e) then
            Duel.ChangeAttackTarget(tc)
        end
    end
end

-- =========================================================================
-- LOGICA EFECTO 2
-- =========================================================================
function s.sptg2(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
        and c:GetEquipTarget() ~= nil
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop2(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsLocation(LOCATION_SZONE) then
        Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
    end
end

-- =========================================================================
-- LOGICA EFECTO 3 (CORREGIDA Y SEPARADA)
-- =========================================================================
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

-- Filtro 3 separado para Guerrero o Guerrero-Bestia, excluyendo esta misma carta
function s.thfilter(c, id)
    return (c:IsRace(RACE_WARRIOR) or c:IsRace(RACE_BEASTWARRIOR)) and c:IsAbleToHand() and not c:IsCode(id)
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil, id) end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
    Duel.Hint(HINT_SELECTMSG, tp, HINTSEMSG_ATOHAND)
    local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil, id)
    if #g > 0 then
        Duel.SendtoHand(g, nil, REASON_EFFECT)
        Duel.ConfirmCards(1-tp, g)
    end
end
