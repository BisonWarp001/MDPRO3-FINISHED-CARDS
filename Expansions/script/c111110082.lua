--Divine Eclipse
local s,id=GetID()
function s.initial_effect(c)
	-- Mención de Avatar (Oficial y Custom)
	aux.AddCodeList(c,21208154)

	-------------------------------------------------
	-- (1) Activar: Inmunidad de Magia/Trampa
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- Innegable: No se puede negar la activación ni el efecto
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- (2) GY: Bloqueo de Cementerio
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	-- Innegable
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

function s.avatarfilter(c)
	return c:IsFaceup() and (c:IsCode(21208154))
end

-- (1) Lógica: Inmunidad
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.avatarfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g1=Duel.GetMatchingGroup(s.avatarfilter,tp,LOCATION_MZONE,0,nil)
	if #g1==0 then return end
	-- Tomamos el Avatar con el ATK más alto actualmente
	local tc=g1:GetMaxGroup(Card.GetAttack):GetFirst()
	local atk=tc:GetAttack()
	
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetTargetRange(LOCATION_MZONE,0)
	-- Compara con el ATK actual del momento de la resolución
	e1:SetTarget(function(e,c) return c:GetAttack()<atk end)
	e1:SetValue(s.efilter)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.efilter(e,re)
	return re:IsActivated() and re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- (2) Lógica: Bloqueo de GY (CORREGIDO)
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.avatarfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.avatarfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.avatarfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
	
	-- Capturamos el ATK actual (current ATK) justo ahora
	local current_atk=tc:GetAttack()
	
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(0,1)
	e1:SetLabel(current_atk) -- Guardamos el valor exacto en el efecto
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	local atk_threshold=e:GetLabel() -- Recuperamos el ATK que tenía el Avatar
	return rc:IsLocation(LOCATION_GRAVE) and rc:IsMonster() and rc:GetAttack() < atk_threshold
end
