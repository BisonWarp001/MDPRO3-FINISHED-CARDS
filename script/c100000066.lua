--Blasphemous Ascension
local s,id=GetID()

function s.initial_effect(c)
	--Activation (cannot be negated)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE+EFFECT_FLAG_CANNOT_INACTIVATE)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-----------------------------------------------------------
-- Wicked monster list
-----------------------------------------------------------
s.wicked_list={
	21208154, -- The Wicked Avatar
	62180201, -- The Wicked Dreadroot
	57793869  -- The Wicked Eraser
}

-----------------------------------------------------------
-- Filter
-----------------------------------------------------------
function s.filter(c)
	return c:IsFaceup()
		and aux.IsCode(c,table.unpack(s.wicked_list))
		and not c:IsHasEffect(id)
end

-----------------------------------------------------------
-- Target
-----------------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetTargetCard(g)
end

-----------------------------------------------------------
-- Activate
-----------------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	local c=e:GetHandler()

	-- Mark as affected (replaces flag system)
	local eflag=Effect.CreateEffect(c)
	eflag:SetType(EFFECT_TYPE_SINGLE)
	eflag:SetCode(id)
	eflag:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	eflag:SetRange(LOCATION_MZONE)
	eflag:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(eflag)

	-------------------------------------------------------
	-- Effects cannot be negated
	-------------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CANNOT_DISABLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e0)

	-------------------------------------------------------
	-- Attribute also treated as DIVINE
	-------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ADD_ATTRIBUTE)
	e1:SetValue(ATTRIBUTE_DIVINE)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)

	-------------------------------------------------------
	-- Cannot be used as material for a Special Summon
	-------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e2:SetValue(1)
	e2:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e2)

	-------------------------------------------------------
	-- Immune to other monsters' effects except DIVINE
	-------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.immfilter)
	e3:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e3)

	-------------------------------------------------------
	-- Cannot be destroyed by Spell/Trap effects
	-------------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetValue(s.indesfilter)
	e4:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e4)
end

-----------------------------------------------------------
-- Immunity filters
-----------------------------------------------------------
function s.immfilter(e,re)
	return re:IsActiveType(TYPE_MONSTER)
		and not re:GetHandler():IsAttribute(ATTRIBUTE_DIVINE)
end

function s.indesfilter(e,re,tp)
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end