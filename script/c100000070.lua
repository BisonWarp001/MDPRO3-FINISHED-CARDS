--Profane Altar
local s,id=GetID()

function s.initial_effect(c)
	-- Mention Wicked Gods
	aux.AddCodeList(c,21208154,62180201,57793869)

	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-----------------------------------------
	-- Effect 1: Add or send to GY
	-----------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id) -- Hard OPT
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-----------------------------------------
	-- Effect 2: Banish from GY; Set 1
	-----------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SET)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1) -- Separate Hard OPT
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

-------------------------------------------------
-- Filter: Spell/Trap that mentions Wicked Gods
-------------------------------------------------
function s.altarfilter(c)
	return c:IsSpellTrap()
		and c:ListsCode(21208154,62180201,57793869)
		and not c:IsCode(id)
end

-------------------------------------------------
-- Effect 1 Target
-------------------------------------------------
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.altarfilter,tp,LOCATION_DECK,0,1,nil
		)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

-------------------------------------------------
-- Effect 1 Operation
-------------------------------------------------
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local g=Duel.SelectMatchingCard(
		tp,s.altarfilter,tp,LOCATION_DECK,0,1,1,nil
	)
	if #g==0 then return end
	local tc=g:GetFirst()

	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	else
		Duel.SendtoGrave(tc,REASON_EFFECT)
	end
end

-------------------------------------------------
-- Filter: Set Spell/Trap from Deck or GY
-------------------------------------------------
function s.setfilter(c)
	return c:IsSpellTrap()
		and c:ListsCode(21208154,62180201,57793869)
		and not c:IsCode(id)
		and c:IsSSetable()
end

-------------------------------------------------
-- Effect 2 Target
-------------------------------------------------
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil
		)
	end
	Duel.SetOperationInfo(0,CATEGORY_SET,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

-------------------------------------------------
-- Effect 2 Operation
-------------------------------------------------
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(
		tp,
		aux.NecroValleyFilter(s.setfilter),
		tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil
	)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
	end
end