--Dain of the Nordic Alfar
local s, id = GetID()
s.listed_series = {0x42} -- 0x42 = Nordic

function s.initial_effect(c)
	-- 1. Invocación Especial desde la mano activando el efecto al revelar (HOPT)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION) -- Cambiado a Ignición como el Sacerdote
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id) -- Límite una vez por turno estricto
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Efecto de la Main Phase: Enviar del Deck al GY e Invocar Especialmente de la mano
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_TOGRAVE + CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1) -- Una vez por turno estándar (por copia en el campo)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
end

-- Filtro 1: Buscar monstruos "Nordic" (0x42) en mano para revelar (sin incluirse a sí mismo)
function s.revealfilter(c)
	return c:IsSetCard(0x42) and c:IsType(TYPE_MONSTER) and not c:IsPublic()
end

-- (1) Lógica de Revelación como Costo de Ignición (Idéntica al Sacerdote)
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return Duel.IsExistingMatchingCard(s.revealfilter, tp, LOCATION_HAND, 0, 1, c) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONFIRM)
	local g = Duel.SelectMatchingCard(tp, s.revealfilter, tp, LOCATION_HAND, 0, 1, 1, c)
	Duel.ConfirmCards(1 - tp, g)
	Duel.ShuffleHand(tp)
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

-- Filtros para el Efecto 2 (Mandar al GY del Deck e Invocar de la mano)
function s.tgfilter(c)
	return c:IsSetCard(0x42) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end

function s.spfilter(c, e, tp)
	return c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.tgtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then 
		return Duel.IsExistingMatchingCard(s.tgfilter, tp, LOCATION_DECK, 0, 1, nil)
			and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_DECK)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND)
end

function s.tgop(e, tp, eg, ep, ev, re, r, rp)
	-- 1. Enviar 1 monstruo "Nordic" del Deck al GY
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local g = Duel.SelectMatchingCard(tp, s.tgfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g > 0 and Duel.SendtoGrave(g, REASON_EFFECT) > 0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
		-- 2. "And if you do", Invoca Especialmente 1 monstruo de tu mano
		if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local sg = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND, 0, 1, 1, nil, e, tp)
		if #sg > 0 then
			Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP)
		end
	end
end
