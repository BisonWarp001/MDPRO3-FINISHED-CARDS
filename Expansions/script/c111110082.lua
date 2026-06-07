-- Divine Eclipse
local s,id=GetID()

function s.initial_effect(c)
	-- Mentions "The Wicked Avatar"
	aux.AddCodeList(c,21208154)

	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(TIMING_MAIN_END+TIMING_BATTLE_START)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.avatarfilter(c)
	return c:IsFaceup() and c:IsCode(21208154)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetTurnPlayer()==tp then
		return false
	end
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_BATTLE_START
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetChainLimit(aux.FALSE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- Track monsters that battled The Wicked Avatar
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_DAMAGE_STEP_END)
	e1:SetOperation(s.battleop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- Resolve at start of Main Phase 2
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_PHASE_START+PHASE_MAIN2)
	e2:SetCountLimit(1)
	e2:SetOperation(s.mp2op)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

-- Mark opponent monsters that battled The Wicked Avatar
function s.battleop(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	if not a or not d then
		return
	end

	if a:IsCode(21208154) and d:IsControler(1-tp) then
		d:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
	elseif d:IsCode(21208154) and a:IsControler(1-tp) then
		a:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
	end
end

function s.samecodetg(e,c)
	return c:IsOriginalCode(e:GetLabel())
end

function s.mp2op(e,tp,eg,ep,ev,re,r,rp)
	-- Must still control The Wicked Avatar
	if not Duel.IsExistingMatchingCard(s.avatarfilter,tp,LOCATION_MZONE,0,1,nil) then
		return
	end

	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	if #g==0 then
		return
	end

	Duel.Hint(HINT_CARD,0,id)

	for tc in aux.Next(g) do
		-- Did not battle The Wicked Avatar this turn
		if tc:GetFlagEffect(id)==0 and not tc:IsImmuneToEffect(e) then
			local code=tc:GetOriginalCode()

			-- Negate that monster
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_SELF_TURN,1)
			tc:RegisterEffect(e1)

			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)

			-- Negate monsters with same original name on field
			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetType(EFFECT_TYPE_FIELD)
			e3:SetCode(EFFECT_DISABLE)
			e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
			e3:SetTarget(s.samecodetg)
			e3:SetLabel(code)
			e3:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN,1)
			Duel.RegisterEffect(e3,tp)

			local e4=e3:Clone()
			e4:SetCode(EFFECT_DISABLE_EFFECT)
			Duel.RegisterEffect(e4,tp)

			-- Negate activated effects of monsters with same original name
			local e5=Effect.CreateEffect(e:GetHandler())
			e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e5:SetCode(EVENT_CHAIN_SOLVING)
			e5:SetLabel(code)
			e5:SetOperation(s.disop)
			e5:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN,1)
			Duel.RegisterEffect(e5,tp)

			Duel.SendtoGrave(tc,REASON_EFFECT)
		end
	end
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if not rc then
		return
	end

	if rc:IsOriginalCode(e:GetLabel()) then
		Duel.NegateEffect(ev)
	end
end