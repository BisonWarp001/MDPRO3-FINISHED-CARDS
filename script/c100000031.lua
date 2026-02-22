--Hela, Grim of the Aesir
local s,id=GetID()

function s.initial_effect(c)
	-- Synchro Summon
	aux.AddSynchroProcedure(c,s.tfilter,aux.NonTuner(nil),1)
	c:EnableReviveLimit()

	-------------------------------------------------
	--① Opponent cannot banish cards
	-------------------------------------------------
	--① Your opponent cannot banish cards
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_REMOVE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0,1)
	c:RegisterEffect(e1)

	-------------------------------------------------
	--② Main Phase (Quick): Banish 1 card (HOPT)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.rmcon)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)

	-------------------------------------------------
	--③ Track destroyed by opponent
	-------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetOperation(s.regop)
	c:RegisterEffect(e3)

	-------------------------------------------------
	--④ End Phase self-revival (HOPT)
	-------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.spcon)
	e4:SetCost(s.spcost)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)

	-------------------------------------------------
	--⑤ When Summoned this way: Set 1 "Nordic Horror" Trap
	-------------------------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetCondition(s.setcon)
	e5:SetTarget(s.settg)
	e5:SetOperation(s.setop)
	c:RegisterEffect(e5)
end


-------------------------------------------------
-- Synchro material filter
-------------------------------------------------
function s.tfilter(c)
	return c:IsSetCard(0xa042)
end
-------------------------------------------------
--① Opponent cannot banish
-------------------------------------------------
function s.removelimit(e,c)
	return c:IsAbleToRemove()
end

-------------------------------------------------
--② Quick Effect (Main Phase only)
-------------------------------------------------
function s.rmcon(e,tp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

function s.rmfilter(c)
	return c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE)
			and chkc:IsAbleToRemove()
	end
	if chk==0 then
		return Duel.IsExistingTarget(
			Card.IsAbleToRemove,
			tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil
		)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(
		tp,Card.IsAbleToRemove,
		tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil
	)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end

-------------------------------------------------
--③ Track destroyed by opponent
-------------------------------------------------
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if rp~=tp
		and c:IsPreviousControler(tp)
		and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsPreviousPosition(POS_FACEUP)
		and c:IsReason(REASON_DESTROY) then
		c:RegisterFlagEffect(id,RESET_PHASE+PHASE_END,0,1)
	end
end

-------------------------------------------------
--④ Revival
-------------------------------------------------
function s.spcon(e,tp)
	return e:GetHandler():GetFlagEffect(id)~=0
end

function s.cfilter(c)
	return c:IsSetCard(0xa042)
		and c:IsType(TYPE_TUNER)
		and c:IsAbleToRemoveAsCost()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.cfilter,tp,LOCATION_GRAVE,0,1,nil
		)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(
		tp,s.cfilter,tp,LOCATION_GRAVE,0,1,1,nil
	)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(
		0,CATEGORY_SPECIAL_SUMMON,c,1,0,0
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetHandler():IsRelateToEffect(e) then
		Duel.SpecialSummon(
			e:GetHandler(),
			SUMMON_VALUE_SELF,
			tp,tp,false,false,POS_FACEUP
		)
	end
end

-------------------------------------------------
--⑤ When Summoned this way
-------------------------------------------------
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetSummonType()
		== SUMMON_TYPE_SPECIAL + SUMMON_VALUE_SELF
end

function s.setfilter(c)
	return c:IsSetCard(0x41a)
		and c:IsType(TYPE_TRAP)
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.setfilter,tp,LOCATION_DECK,0,1,nil
		)
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(
		tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil
	)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
		Duel.ConfirmCards(1-tp,g)
	end
end