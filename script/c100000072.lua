--Inevitable End
local s,id=GetID()

function s.initial_effect(c)
	-- Mention The Wicked Eraser
	aux.AddCodeList(c,57793869)

	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id) -- Only 1 per turn
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- Condition: You control The Wicked Eraser
-------------------------------------------------
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and re:IsActiveType(TYPE_MONSTER)
		and Duel.IsExistingMatchingCard(s.eraserfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.eraserfilter(c)
	return c:IsFaceup() and c:IsCode(57793869)
end

-------------------------------------------------
-- Target
-------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsChainNegatable(ev) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,0,1-tp,LOCATION_DECK+LOCATION_GRAVE)
end

-------------------------------------------------
-- Operation
-------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=re:GetHandler()
	if not tc then return end

	local code=tc:GetOriginalCode()

	-- Negate activation
	if not Duel.NegateActivation(ev) then return end

	-- Destroy that monster if possible
	local destroyed=false
	if tc:IsRelateToEffect(re) and tc:IsDestructable() then
		if Duel.Destroy(tc,REASON_EFFECT)>0 then
			destroyed=true
		end
	end

	if not destroyed then return end

	-- Banish all cards with that original name from Deck and GY
	local g=Duel.GetMatchingGroup(
		aux.NecroValleyFilter(function(c)
			return c:IsOriginalCode(code)
		end),
		1-tp,
		LOCATION_DECK+LOCATION_GRAVE,
		0,nil
	)

	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end