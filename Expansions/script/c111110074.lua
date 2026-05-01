-- Total Submission
local s,id=GetID()
function s.initial_effect(c)
	-- Mencionar a Dreadroot (Original y Custom)
	aux.AddCodeList(c,62180201,111110200)
	
	-------------------------------------------------
	-- (1) Activar: Quick-Play Shuffle
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-------------------------------------------------
	-- (2) GY: Protección por sustitución (Protege de Eraser y rival)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetTarget(s.subtg)
	e2:SetValue(s.subval)
	c:RegisterEffect(e2)
end

-- Filtro para Dreadroot (Incluye Custom)
function s.cfilter(c)
	return c:IsFaceup() and (c:IsCode(62180201) or c:IsCode(111110200))
end

-- (1) Lógica: Shuffle
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.filter(c,atk)
	return c:IsFaceup() and c:GetAttack()<atk and c:IsAbleToDeck()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g1=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then
		if #g1==0 then return false end
		local max_atk=g1:GetMaxGroup(Card.GetAttack):GetFirst():GetAttack()
		return Duel.IsExistingMatchingCard(s.filter,tp,0,LOCATION_MZONE,1,nil,max_atk)
	end
	local max_atk=g1:GetMaxGroup(Card.GetAttack):GetFirst():GetAttack()
	local g2=Duel.GetMatchingGroup(s.filter,tp,0,LOCATION_MZONE,nil,max_atk)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g2,#g2,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g1=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_MZONE,0,nil)
	if #g1==0 then return end
	local max_atk=g1:GetMaxGroup(Card.GetAttack):GetFirst():GetAttack()
	local g2=Duel.GetMatchingGroup(s.filter,tp,0,LOCATION_MZONE,nil,max_atk)
	if #g2>0 then
		Duel.SendtoDeck(g2,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end

-- (2) Lógica: GY Effect
-- Filtro para Dreadroot (Incluye Custom)
function s.cfilter(c)
	return c:IsFaceup() and (c:IsCode(62180201) or c:IsCode(111110200))
end

-- Lógica de Sustitución
function s.subfilter(c,tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_MZONE) 
		and s.cfilter(c) and c:IsFaceup() and not c:IsReason(REASON_REPLACE)
end

function s.subtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.subfilter,1,nil,tp) 
		and e:GetHandler():IsAbleToRemove() end
	if Duel.SelectEffectYesNo(tp,e:GetHandler(),aux.Stringid(id,1)) then
		Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
		return true
	end
	return false
end

function s.subval(e,c)
	return s.subfilter(c,e:GetHandlerPlayer())
end