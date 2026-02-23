--Nordic Relic Andvaranaut
local s,id=GetID()

s.listed_series={0x42,0x4b}

function s.initial_effect(c)
	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--------------------------------
	-- ① Quick Synchro (HOPT)
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.sccon)
	e1:SetTarget(s.sctg)
	e1:SetOperation(s.scop)
	c:RegisterEffect(e1)

	--------------------------------
	-- ② Banish & Destroy (HOPT)
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE+LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.descon2)
	e2:SetTarget(s.destg2)
	e2:SetOperation(s.desop2)
	c:RegisterEffect(e2)
end

------------------------------------------------
-- Conditions
------------------------------------------------
function s.sccon(e,tp)
	return not Duel.IsExistingMatchingCard(s.aesirfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.descon2(e,tp)
	return Duel.IsExistingMatchingCard(s.aesirfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.aesirfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x4b)
end

function s.nordicfilter(c)
	return (c:IsSetCard(0x42) or c:IsSetCard(0x4b))
		and c:IsMonster()
		and c:IsAbleToRemove()
end

------------------------------------------------
-- ① Synchro Summon
------------------------------------------------
function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.nordicfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
		return #g>=2 and Duel.GetLocationCountFromEx(tp)>0
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,2,tp,LOCATION_MZONE+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.scop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.nordicfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	if #g<2 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local rg=g:Select(tp,2,3,nil)

	local lv=0
	for tc in aux.Next(rg) do
		lv=lv+tc:GetLevel()
	end

	if Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)==0 then return end

	Duel.BreakEffect()

	local sg=Duel.GetMatchingGroup(function(sc)
		return sc:IsSetCard(0x4b)
			and sc:IsType(TYPE_SYNCHRO)
			and sc:IsLevel(lv)
			and sc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
	end,tp,LOCATION_EXTRA,0,nil)

	if #sg==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=sg:Select(tp,1,1,nil):GetFirst()
	if not sc then return end

	if Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)~=0 then
		sc:CompleteProcedure()

		-- Send to GY during End Phase
		local e1=Effect.CreateEffect(sc)
		e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetOperation(function(e,tp)
			Duel.SendtoGrave(e:GetHandler(),REASON_EFFECT)
		end)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		sc:RegisterEffect(e1)
	end
end

------------------------------------------------
-- ② Destroy opponent card
------------------------------------------------
function s.destg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,0)
end

function s.desop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.Remove(c,POS_FACEUP,REASON_EFFECT)==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end