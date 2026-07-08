-- Galar of the Nordic Alfar
local s, id = GetID()
s.listed_series = {0x42, 0x4b} -- 0x42 = Nordic, 0x4b = Aesir

function s.initial_effect(c)
	-- 1. Invocación Especial desde la mano o GY al enviar un Nordic/Aesir al GY
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetRange(LOCATION_HAND + LOCATION_GRAVE)
	e1:SetCountLimit(1, id) -- HOPT limpio moderno con la ID de la carta
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Efecto de la Main Phase: Invocación por Sincronía Inmediata (QUICK EFFECT)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O) -- CORRECCIÓN: Cambiado a Efecto Rápido
	e2:SetCode(EVENT_FREE_CHAIN)    -- CORRECCIÓN: Permite encadenarlo libremente
	e2:SetHintTiming(0, TIMING_MAIN_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1) -- Una vez por turno estándar (por copia en campo)
	e2:SetCondition(s.syncon) -- CORRECCIÓN: Restringe su activación a la Main Phase
	e2:SetTarget(s.syntg)
	e2:SetOperation(s.synop)
	c:RegisterEffect(e2)
end

-- Filtro: Asegura que sea un MONSTRUO y que pertenezca a "Nordic" o "Aesir"
function s.cfilter(c)
	return c:IsType(TYPE_MONSTER) and (c:IsSetCard(0x42) or c:IsSetCard(0x4b))
end

-- Condiciones para el Efecto 1
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	-- Comprueba que entre las cartas enviadas al GY haya un monstruo del arquetipo
	-- Y evita que Galar se dispare por sí mismo si él fue enviado al GY
	return eg:IsExists(s.cfilter, 1, nil) and not eg:IsContains(e:GetHandler())
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP)
	end
end

-- Condición para el Efecto 2: Solo se puede activar durante la Main Phase (de cualquier jugador)
function s.syncon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsMainPhase()
end

-- Filtro para buscar un monstruo de Sincronía "Aesir" válido
function s.synfilter(c, mg)
	return c:IsSetCard(0x4b) and c:IsSynchroSummonable(nil, mg)
end

-- Condiciones para el Efecto 2 (Sincronía en resolución)
function s.syntg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then 
		-- Valida si hay monstruos listos en el Extra Deck usando los materiales actuales del campo
		return Duel.IsExistingMatchingCard(s.synfilter, tp, LOCATION_EXTRA, 0, 1, nil, nil) 
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.synop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if c:IsControler(tp) and not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, s.synfilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, nil)
	if #g > 0 then
		Duel.SynchroSummon(tp, g:GetFirst(), nil)
	end
end
