-- Awakening of the Wicked Deities
local s,id=GetID()

function s.initial_effect(c)
	-- Mención de los Wicked Gods (Originales y Custom)
	aux.AddCodeList(c,62180201,57793869,21208154)

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- Inmunidad de la Magia
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.filter(c,id)
	return c:IsFaceup() and (c:IsCode(62180201,57793869,21208154)) 
		and c:GetFlagEffect(id)==0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil,id) end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil,id)
	local tc=g:GetFirst()
	if not tc then return end
	local c=e:GetHandler()

	-- Registro visual y protección de efectos
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,0))
	
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e0,true)

	-- Protecciones (No material / Inmunidad)
	s.apply_common(tc,c)

	-- Efectos Ganados según el nombre
	if tc:IsCode(21208154) then -- Avatar (CAMPO + GY)
		s.apply_avatar(tc,c)
	elseif tc:IsCode(57793869) then -- Eraser
		s.apply_eraser(tc,c)
	elseif tc:IsCode(62180201) then -- Dreadroot
		s.apply_dreadroot(tc,c)
	end
end

function s.apply_common(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e1:SetValue(aux.FilterBoolFunction(Card.IsType,TYPE_SPECIAL))
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
	
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.efilter)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2,true)
end

function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated()
end

-------------------------------------------------
-- AVATAR: Copia desde Campo o Cementerio
-------------------------------------------------
function s.apply_avatar(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.copy_tg)
	e1:SetOperation(s.copy_op)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
end

function s.copy_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Filtro: Monstruos de Efecto en MZONE o GRAVE de ambos jugadores
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,e:GetHandler(),TYPE_EFFECT) end
end

function s.copy_op(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g=Duel.SelectMatchingCard(tp,Card.IsType,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,1,c,TYPE_EFFECT)
    local tc=g:GetFirst()
    if tc and tc:IsFaceup() then
        Duel.MajesticCopy(c,tc)
        c:SetHint(CHINT_CARD,tc:GetCode())
        
        -- ESTA LÍNEA ES LA CLAVE:
        -- Fuerza al juego a re-evaluar todos los efectos continuos en el campo inmediatamente.
        Duel.Readjust() 
    end
end

-------------------------------------------------
-- ERASER: Negación "Choose"
-------------------------------------------------
function s.apply_eraser(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.neg_tg)
	e1:SetOperation(s.neg_op)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
end

function s.neg_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
end

function s.neg_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
	end
end

-------------------------------------------------
-- DREADROOT: Sentencia "Choose"
-------------------------------------------------
function s.apply_dreadroot(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.des_tg)
	e1:SetOperation(s.des_op)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
end

function s.des_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_MZONE,1,nil) end
end

function s.des_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_MZONE,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetCountLimit(1)
		e1:SetLabelObject(tc)
		e1:SetOperation(s.des_end_op)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,4))
	end
end

function s.des_end_op(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	local c=e:GetOwner() 
	if tc and tc:IsLocation(LOCATION_MZONE) then
		local atk=tc:GetAttack()
		if Duel.Destroy(tc,REASON_EFFECT)>0 and c:IsLocation(LOCATION_MZONE) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(atk)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e1)
		end
	end
end
