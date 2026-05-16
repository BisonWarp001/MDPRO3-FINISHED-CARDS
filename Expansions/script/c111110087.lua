-- Wicked Apostle - Sky Devourer
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Xyz Summon
	aux.AddXyzProcedure(c,nil,10,2,s.ovfilter,aux.Stringid(id,0))

	-- Triple Tribute Flag
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(id)
	c:RegisterEffect(e0)

	-- Triple Tribute Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_HAND,0)
	e1:SetCondition(s.ttcon)
	e1:SetTarget(s.RequireSummon)
	e1:SetOperation(s.ttop)
	e1:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_LIMIT_SET_PROC)
	e2:SetTarget(s.RequireSet)
	c:RegisterEffect(e2)

	local e3=e1:Clone()
	e3:SetCode(EFFECT_SUMMON_PROC)
	e3:SetTarget(s.CanSummon)
	e3:SetValue(SUMMON_TYPE_ADVANCE+SUMMON_VALUE_SELF)
	c:RegisterEffect(e3)

	-- Banish Extra Deck
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCost(s.rmcost)
	e4:SetTarget(s.extg)
	e4:SetOperation(s.exop)
	c:RegisterEffect(e4)

	-- Double Attack Inheritance
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_BE_PRE_MATERIAL)
	e5:SetCondition(s.regcon)
	e5:SetOperation(s.regop)
	c:RegisterEffect(e5)
end

-- =========================================================
-- Alternative Xyz Material
-- =========================================================

function s.ovfilter(c)
	return c:IsFaceup()
		and c:GetBaseDefense()==3000
end

-- =========================================================
-- Triple Tribute Logic
-- =========================================================

function s.ttfilter(c,tp)
	return c:IsHasEffect(id)
		and c:IsReleasable(REASON_SUMMON)
		and Duel.GetMZoneCount(tp,c)>0
end

function s.ttcon(e,c,minc)
	if c==nil then return true end

	local tp=c:GetControler()

	return minc<=3
		and (
			s.RequireSummon(e,c)
			or s.RequireSet(e,c)
			or s.CanSummon(e,c)
		)
		and Duel.IsExistingMatchingCard(
			s.ttfilter,tp,LOCATION_MZONE,0,1,nil,tp
		)
end

function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)

	local g=Duel.SelectMatchingCard(
		tp,s.ttfilter,tp,LOCATION_MZONE,0,1,1,nil,tp
	)

	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end

function s.RequireSummon(e,c)
	return c:IsCode(
		10000000,10000010,10000020,10000080,
		21208154,57793869,62180201,57761191
	)
end

function s.RequireSet(e,c)
	return c:IsCode(
		21208154,57793869,62180201,
		111110200,111110201
	)
end

function s.CanSummon(e,c)
	return c:IsCode(
		3912064,25524823,36354007,
		75285069,78651105
	)
end

-- =========================================================
-- Banish Extra Deck
-- =========================================================

function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:GetHandler():CheckRemoveOverlayCard(
			tp,1,REASON_COST
		)
	end

	e:GetHandler():RemoveOverlayCard(
		tp,1,1,REASON_COST
	)
end

function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			aux.TRUE,tp,0,LOCATION_EXTRA,1,nil
		)
	end
end

function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)

	if #g>0 then
		local sg=g:RandomSelect(tp,1)
		Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)
	end
end

-- =========================================================
-- Double Attack Inheritance
-- =========================================================

function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetHandler():GetReasonCard()

	return r==REASON_SUMMON
		and rc
		and rc:IsCode(
			21208154,
			62180201,
			57793869
		)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetHandler():GetReasonCard()
	if not rc then return end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EXTRA_ATTACK)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)

	rc:RegisterEffect(e1)
end