-- Sleipnir, Nordic Steed of the Aesir
local s,id=GetID()
s.listed_series={0x42,0x4b} -- Nordic / Aesir

--------------------------------
-- Initialization
--------------------------------
function s.initial_effect(c)
	-- Link Summon: 2 Effect Monsters, including a "Nordic"
	c:EnableReviveLimit()
	Link.AddProcedure(c,
		aux.FilterBoolFunctionEx(Card.IsType,TYPE_EFFECT),
		2,2,
		s.lcheck
	)

	-------------------------------------------------
	-- ① Banish 1 from hand or GY → send Nordic to GY (HOPT)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.tgcon)
	e1:SetCost(s.tgcost)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② Opponent's turn (Quick): Tribute → SS + Synchro (HOPT)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.spcon2)
	e2:SetCost(s.spcost2)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)
end

--------------------------------
-- Link material check
--------------------------------
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0x42)
end

-------------------------------------------------
-- ① Effect: Send Nordic to GY
-------------------------------------------------
function s.tgcon(e,tp)
	return Duel.GetFlagEffect(tp,id)==0
end

function s.tgcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			Card.IsAbleToRemoveAsCost,
			tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil
		)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(
		tp,Card.IsAbleToRemoveAsCost,
		tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil
	)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.tgfilter(c)
	return c:IsSetCard(0x42)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	return chk==0
		and Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
end

function s.tgop(e,tp)
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

-------------------------------------------------
-- ② Effect: Tribute → SS + immediate Synchro
-------------------------------------------------
function s.spcon2(e,tp)
	return Duel.GetTurnPlayer()~=tp
		and Duel.GetFlagEffect(tp,id+1)==0
end

function s.spcost2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsReleasable() end
	Duel.Release(c,REASON_COST)
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0x42)
		and not c:IsType(TYPE_LINK)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(
				function(c)
					return c:IsSetCard(0x4b)
						and c:IsType(TYPE_SYNCHRO)
				end,
				tp,LOCATION_EXTRA,0,1,nil
			)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.spop2(e,tp)
	Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE+PHASE_END,0,1)

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	-- Special Summon Nordic
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if not tc then return end
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	-- Immediately after: Synchro Summon Aesir
	local sg=Duel.GetMatchingGroup(
		function(c)
			return c:IsSetCard(0x4b)
				and c:IsType(TYPE_SYNCHRO)
				and c:IsSynchroSummonable(nil)
		end,
		tp,LOCATION_EXTRA,0,nil
	)
	if #sg==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=sg:Select(tp,1,1,nil):GetFirst()
	Duel.SynchroSummon(tp,sc,nil)
end
