-- Terror and Despair
local s,id=GetID()

local DREADROOT=62180201

function s.initial_effect(c)

	aux.AddCodeList(c,DREADROOT)

	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Activation cannot be negated
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_INACTIVATE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.dreadroot_cond)
	e2:SetValue(s.protectfilter)
	c:RegisterEffect(e2)

	-- Effect cannot be negated
	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_DISEFFECT)
	c:RegisterEffect(e3)

end


function s.dreadfilter(c)
	return c:IsFaceup() and c:IsCode(DREADROOT)
end


function s.dreadroot_cond(e)
	return Duel.IsExistingMatchingCard(s.dreadfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end


function s.protectfilter(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	return te and te:GetHandler()==e:GetHandler()
end


function s.thfilter(c)
	return c:IsCode(DREADROOT) and c:IsAbleToHand()
		and (c:IsLocation(LOCATION_DECK) or c:IsLocation(LOCATION_GRAVE)
		or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end


function s.negfilter(c,atk)
	return c:IsFaceup() and c:GetAttack()<atk
end


function s.target(e,tp,eg,ep,ev,re,r,rp,chk)

	local b1=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)

	local dg=Duel.GetMatchingGroup(s.dreadfilter,tp,LOCATION_MZONE,0,nil)

	local b2=false
	local atk=0

	for tc in aux.Next(dg) do
		if tc:GetAttack()>atk then
			atk=tc:GetAttack()
		end
	end

	if atk>0 then
		b2=Duel.IsExistingMatchingCard(s.negfilter,tp,0,LOCATION_MZONE,1,nil,atk)
	end

	if chk==0 then
		return b1 or b2
	end

	local op=aux.SelectFromOptions(tp,
		{b1,aux.Stringid(id,1),1},
		{b2,aux.Stringid(id,2),2})

	e:SetLabel(op)

	if op==1 then
		e:SetCountLimit(1,id)
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
	elseif op==2 then
		e:SetCountLimit(1,id+100)
		e:SetCategory(CATEGORY_DISABLE)
	end

end


function s.activate(e,tp,eg,ep,ev,re,r,rp)

	local op=e:GetLabel()

	if op==1 then

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)

		if g:GetCount()>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end


	elseif op==2 then

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)

		local dg=Duel.SelectMatchingCard(tp,s.dreadfilter,tp,LOCATION_MZONE,0,1,1,nil)

		if dg:GetCount()==0 then
			return
		end

		local atk=dg:GetFirst():GetAttack()

		local g=Duel.GetMatchingGroup(s.negfilter,tp,0,LOCATION_MZONE,nil,atk)

		for tc in aux.Next(g) do

			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)

			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e2)

		end

	end

end