--The Evil Shapeshifter
local s,id=GetID()

function s.initial_effect(c)
	-- Mention The Wicked Avatar
	aux.AddCodeList(c,21208154)

	-------------------------------------------------
	-- Effect 1: Add Avatar + Extra Tribute Summon
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id) -- Hard OPT
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- Effect 2: GY Lock Set S/T
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1) -- Separate Hard OPT
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.lockop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Effect 1
-------------------------------------------------

function s.thfilter(c)
	return c:IsCode(21208154) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil
		)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- Add Avatar
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(
		tp,
		aux.NecroValleyFilter(s.thfilter),
		tp,
		LOCATION_DECK+LOCATION_GRAVE,
		0,1,1,nil
	)
	if #g==0 then return end

	if Duel.SendtoHand(g,nil,REASON_EFFECT)==0 then return end
	Duel.ConfirmCards(1-tp,g)

	-- Extra Tribute Summon (Level 5+)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(_,c)
		return c:IsLevelAbove(5) and c:IsSummonable(true,nil)
	end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-------------------------------------------------
-- Effect 2: Lock Set S/T during this Main Phase
-------------------------------------------------

function s.lockop(e,tp,eg,ep,ev,re,r,rp)
	-- Only applies during Main Phase this turn
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(0,1)
	e1:SetValue(s.aclimit)
	e1:SetCondition(s.mainphasecond)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.mainphasecond(e)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

function s.aclimit(e,re,tp)
	local c=re:GetHandler()
	return re:IsHasType(EFFECT_TYPE_ACTIVATE)
		and c:IsLocation(LOCATION_SZONE)
		and c:IsFacedown()
end