--Dark Hole Phoenix A
local s, id = GetID()

function s.initial_effect(c)
    -- Activar: Magia de Juego Rápido con Limpieza de Campo Total
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(TIMING_BATTLE_START+TIMING_END_PHASE, TIMINGS_CHECK_MONSTER_E)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    -- Bloqueo de respuesta absoluto (Spell Speed 4)
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_IN_RESPONSE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetRange(LOCATION_HAND+LOCATION_SZONE)
    e2:SetTargetRange(1, 1)
    e2:SetValue(s.chainop)
    c:RegisterEffect(e2)
end

-- =========================================================================
-- LOGICA DEL COSTO (Descartar 1 carta)
-- =========================================================================
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable, tp, LOCATION_HAND, 0, 1, e:GetHandler()) end
    Duel.DiscardHand(tp, Card.IsDiscardable, 1, 1, REASON_COST+REASON_DISCARD, e:GetHandler())
end

-- =========================================================================
-- LOGICA DEL TARGET (Verificar que haya cartas en el campo)
-- =========================================================================
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    -- Cuenta todas las cartas en el campo excepto esta misma si se activó desde el campo
    local g = Duel.GetMatchingGroup(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, e:GetHandler())
    if chk == 0 then return #g > 0 end
    Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, #g, 0, 0)
end

-- =========================================================================
-- LOGICA DE LA ACTIVACION (Desterrar todo boca abajo)
-- =========================================================================
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    -- Selecciona todas las cartas en el campo excepto esta misma Magia si se activó desde ahí
    local g = Duel.GetMatchingGroup(nil, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, e:GetHandler())
    if #g > 0 then
        -- Remueve el grupo completo de golpe, boca abajo, por efecto de carta
        Duel.Remove(g, POS_FACEDOWN, REASON_EFFECT)
    end
end

-- =========================================================================
-- LOGICA DEL BLOQUEO DE RESPUESTA (Evita activaciones del rival y tuyas)
-- =========================================================================
function s.chainop(e, re, rp, cl)
    -- Si la carta que se está intentando activar en la cadena es esta misma, bloquea el paso de respuesta
    return re:GetHandler() == e:GetHandler()
end
