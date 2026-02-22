-- Brynhildr, Valkyria of the Aesir
local s,id=GetID()

function s.initial_effect(c)
	-- Synchro Summon
	c:EnableReviveLimit()
	Synchro.AddProcedure(
		c,
		aux.FilterBoolFunctionEx(Card.IsSetCard,0x42), -- "Nordic" Tuner
		1,1,
		Synchro.NonTuner(nil),
		1,99
	)

	-------------------------------------------------
	-- ① Synchro Summon: Set 1 "Nordic Relic" (HOPT)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② Tribute → Special Summon Aesir Lv10 (HOPT)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-------------------------------------------------
	-- ③ End Phase: Banish + revive Aesir Lv10 (HOPT)
	-------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCondition(s.revcon)
	e3:SetCost(s.revcost)
	e3:SetTarget(s.revtg)
	e3:SetOperation(s.revop)
	c:RegisterEffect(e3)
end

-------------------------------------------------
-- ① Set Nordic Relic (HOPT)
-------------------------------------------------
function s.setcon(e,tp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
		and Duel.GetFlagEffect(tp,id)==0
end

function s.setfilter(c)
	return c:IsSetCard(0x5042)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	return chk==0
		and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
end

function s.setop(e,tp)
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
		Duel.ConfirmCards(1-tp,g)
	end
end

-------------------------------------------------
-- ② Tribute → Aesir Lv10 (COST)
-------------------------------------------------
function s.relfilter(c)
	return c:IsFaceup() and c:IsReleasable() and c:GetLevel()>0
end

function s.aesirfilter(c,e,tp)
	return c:IsSetCard(0x4b)
		and c:IsLevel(10)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

function s.validtribute(tp,c)
	local g=Duel.GetMatchingGroup(s.relfilter,tp,LOCATION_MZONE,0,c)
	return aux.SelectUnselectGroup(
		g,nil,tp,0,2,
		function(sg) return sg:GetSum(Card.GetLevel)+c:GetLevel()==10 end,
		0
	)
end

function s.spcon(e,tp)
	local c=e:GetHandler()
	return Duel.GetFlagEffect(tp,id+1)==0
		and Duel.GetLocationCountFromEx(tp,tp,c)>0
		and Duel.IsExistingMatchingCard(s.aesirfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
		and s.validtribute(tp,c)
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return s.validtribute(tp,c) end

	Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE+PHASE_END,0,1)

	local g=Duel.GetMatchingGroup(s.relfilter,tp,LOCATION_MZONE,0,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local rg=aux.SelectUnselectGroup(
		g,e,tp,0,2,
		function(sg) return sg:GetSum(Card.GetLevel)+c:GetLevel()==10 end,
		1,tp,HINTMSG_RELEASE
	)
	rg:AddCard(c)
	Duel.Release(rg,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	return chk==0
end

function s.spop(e,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.aesirfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local sc=sg:GetFirst()
	if sc then
		Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end

-------------------------------------------------
-- ③ End Phase revive (COST)
-------------------------------------------------
function s.revcon(e,tp)
	return Duel.GetFlagEffect(tp,id+2)==0
		and e:GetHandler():IsLocation(LOCATION_GRAVE)
end

function s.revcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end

	Duel.RegisterFlagEffect(tp,id+2,RESET_PHASE+PHASE_END,0,1)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

function s.revtg(e,tp,eg,ep,ev,re,r,rp,chk)
	return chk==0
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(
			function(c)
				return c:IsSetCard(0x4b)
					and c:IsLevel(10)
					and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			end,
			tp,LOCATION_GRAVE,0,1,nil
		)
end

function s.revop(e,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,function(tc)
		return tc:IsSetCard(0x4b)
			and tc:IsLevel(10)
			and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end,tp,LOCATION_GRAVE,0,1,1,nil)

	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
