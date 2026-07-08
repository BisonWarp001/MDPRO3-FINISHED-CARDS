-- Ljos of the Nordic Alfar
local s, id = GetID()
s.listed_series = {0x42} -- 0x42 = Nordic

function s.initial_effect(c)
	-- 1. Invocación Especial desde la mano si un "Nordic" es invocado (HOPT)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id) -- Límite estricto una vez por turno
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- Clonar para detectar Invocaciones Especiales de otros "Nordic"
	local e2 = e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- 2. Al ser Invocado: Tomar el control de 1 monstruo del oponente (OOPT)
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_CONTROL)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1) -- Una vez por turno por copia en campo
	e3:SetTarget(s.ctltg)
	e3:SetOperation(s.ctlop)
	c:RegisterEffect(e3)
	-- Clonar para cuando Ljos sea Invocado de Modo Especial
	local e4 = e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

-- Filtro para detectar monstruos "Nordic" (0x42) válidos que entren al campo
function s.filter(c)
	return c:IsFaceup() and c:IsSetCard(0x42)
end

-- Condiciones para el Efecto 1 (Invocarse desde la mano)
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	-- Revisa que el monstruo invocado sea un "Nordic" válido y no sea este mismo Ljos si entrara por otra vía
	return eg:IsExists(s.filter, 1, nil) and not eg:IsContains(e:GetHandler())
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

-- Filtro para el Efecto 2 (Monstruos del rival que se pueden cambiar de control)
function s.ctlfilter(c)
	return c:IsControlerCanBeChanged()
end

function s.ctltg(e, tp, eg, ep, ev, re, r, rp, chk, chnd)
	if chk == 0 then return Duel.IsExistingTarget(s.ctlfilter, tp, 0, LOCATION_MZONE, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONTROL)
	local g = Duel.SelectTarget(tp, s.ctlfilter, tp, 0, LOCATION_MZONE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_CONTROL, g, 1, 0, 0)
end

function s.ctlop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.GetControl(tc, tp)
	end
end
