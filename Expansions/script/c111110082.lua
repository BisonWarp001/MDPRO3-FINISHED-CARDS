--Divine Eclipse
local s,id=GetID()
function s.initial_effect(c)
	-- Mención de Avatar (Oficial y Custom)
	aux.AddCodeList(c,21208154,111110201)

	-------------------------------------------------
	-- (1) Activar: Inmunidad de Magia/Trampa (Innegable)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- Protección total contra negación
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- (2) GY: Bloqueo de Cementerio (Innegable)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	-- Protección de efecto en cementerio
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

function s.avatarfilter(c)
	return c:IsFaceup() and (c:IsCode(21208154) or c:IsCode(111110201))
end

-- (1) Lógica: Inmunidad
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.avatarfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g1=Duel.GetMatchingGroup(s.avatarfilter,tp,LOCATION_MZONE,0,nil)
	if #g1==0 then return end
	local max_atk=g1:GetMaxGroup(Card.GetAttack):GetFirst():GetAttack()
	
	-- Monstruos con menor ATK son inafectados por activaciones de S/T
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(e,c) return c:GetAttack()<max_atk end)
	e1:SetValue(s.efilter)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.efilter(e,te)
	return te:IsHasType(EFFECT_TYPE_ACTIONS) and te:IsActiveType(TYPE_SPELL+TYPE_TRAP) and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- (2) Lógica: Bloqueo de GY
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.avatarfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.avatarfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.avatarfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	local atk=tc:GetAttack()
	
	-- El oponente no puede activar efectos de monstruos en el GY con menor ATK
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(0,1)
	e1:SetValue(function(e,re,tp)
		local rc=re:GetHandler()
		return rc:IsLocation(LOCATION_GRAVE) and rc:IsMonster() and rc:GetAttack()<atk
	end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
