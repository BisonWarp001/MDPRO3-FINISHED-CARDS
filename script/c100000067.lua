--Unholy Synchronicity
local s,id=GetID()

function s.initial_effect(c)

	--------------------------------
	-- You can only control 1
	--------------------------------
	c:SetUniqueOnField(1,0,id)

	--------------------------------
	-- Mention Wicked monsters
	--------------------------------
	aux.AddCodeList(c,21208154,62180201,57793869)

	--------------------------------
	-- Activate
	--------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--------------------------------
	-- Avatar & Eraser unaffected by Dreadroot
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.immtg1)
	e1:SetValue(s.immval1)
	c:RegisterEffect(e1)

	--------------------------------
	-- Avatar & Dreadroot unaffected by Eraser
	--------------------------------
	local e2=e1:Clone()
	e2:SetTarget(s.immtg2)
	e2:SetValue(s.immval2)
	c:RegisterEffect(e2)

	--------------------------------
	-- If sent to GY: Add 1 Wicked monster
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

end

--------------------------------
-- Wicked codes
--------------------------------
s.wicked_list={
	21208154, -- The Wicked Avatar
	62180201, -- The Wicked Dreadroot
	57793869  -- The Wicked Eraser
}

--------------------------------
-- (1) Avatar & Eraser unaffected by Dreadroot
--------------------------------
function s.immtg1(e,c)
	return c:IsFaceup() and c:IsCode(21208154,57793869)
end
function s.immval1(e,re)
	local tc=re:GetHandler()
	return re:IsActiveType(TYPE_MONSTER)
		and tc:IsControler(e:GetHandlerPlayer())
		and tc:IsCode(62180201)
end

--------------------------------
-- (2) Avatar & Dreadroot unaffected by Eraser
--------------------------------
function s.immtg2(e,c)
	return c:IsFaceup() and c:IsCode(21208154,62180201)
end
function s.immval2(e,re)
	local tc=re:GetHandler()
	return re:IsActiveType(TYPE_MONSTER)
		and tc:IsControler(e:GetHandlerPlayer())
		and tc:IsCode(57793869)
end

--------------------------------
-- Search filter
--------------------------------
function s.thfilter(c)
	return c:IsCode(21208154,62180201,57793869)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil
		)
	end
	Duel.SetOperationInfo(
		0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(
		tp,
		aux.NecroValleyFilter(s.thfilter),
		tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil
	)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end