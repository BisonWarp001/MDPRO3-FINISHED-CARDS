--Unleashed Divinity
local s,id=GetID()

function s.initial_effect(c)
	-- Mención de los Dioses
	aux.AddCodeList(c,10000020)

	-- Activación: No puede ser negada
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- TARGET
-------------------------------------------------
function s.filter(c)
	return c:IsFaceup()
		and (c:IsCode(10000020))
		and c:GetFlagEffect(id)==0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_MZONE,0,1,nil)
	end
end

-------------------------------------------------
-- OPERACIÓN PRINCIPAL
-------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_APPLYTO)
	local tc=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
	if not tc then return end

	local c=e:GetHandler()

	-- Registro de Flag y Client Hint visual
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,0))

	-- Limpiar negaciones previas y proteger efectos (No pueden ser negados)
	tc:ResetEffect(EFFECT_DISABLE,RESET_CODE)
	tc:ResetEffect(EFFECT_DISABLE_EFFECT,RESET_CODE)
	
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetCode(EFFECT_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e0,true)

	-- Aplicar Protecciones Comunes (Material e Inmunidad Reforzada)
	s.apply_common(tc,c)

	-- Aplicar Efectos Ganados específicos
	if tc:IsCode(10000020) then
		s.apply_slifer(tc,c)
	end
end

-----------------------------------------------------------
-- PROTECCIONES COMUNES (LA CLAVE VS MIRRORJADE)
-----------------------------------------------------------
function s.apply_common(tc,c)
	-- ① No puede ser usado como material
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e1:SetValue(aux.FilterBoolFunction(Card.IsType,TYPE_SPECIAL))
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)

	-- ② Inmune a efectos ACTIVADOS del oponente (Prioridad Máxima)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	-- Se añade UNCOPYABLE y CANNOT_DISABLE para que el motor no lo ignore en resoluciones complejas
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.efilter)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2,true)

	-- Impedir que sus efectos activados sean negados
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_INACTIVATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(1,0)
	e3:SetValue(s.negfilter)
	e3:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e3,true)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_DISEFFECT)
	tc:RegisterEffect(e4,true)
end

function s.efilter(e,te)
	-- 1. No proteger de tus propios efectos (para que tus cartas sigan funcionando en tus Dioses)
	if te:GetOwnerPlayer()==e:GetHandlerPlayer() then return false end

	-- 2. Si el efecto se ACTIVA (como el remover de Mirrorjade o un Raigeki), el Dios es INMUNE.
	if te:IsActivated() then return true end

	-- 3. Si NO es un efecto Continuo ni de Campo (como la destrucción de Mirrorjade en la End Phase),
	-- el Dios también es INMUNE. Esto cubre los efectos residuales.
	return not te:IsHasType(EFFECT_TYPE_CONTINUOUS) and not te:IsHasType(EFFECT_TYPE_FIELD)
end


function s.negfilter(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	return te and te:GetHandler()==e:GetHandler()
end


-------------------------------------------------
-- SLIFER (MODIFICADO: Escudo de Segunda Boca Nerfeado)
-------------------------------------------------
function s.apply_slifer(tc,c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_BATTLE_START+TIMING_ATTACK)
	e1:SetCondition(s.slifercon)
	e1:SetTarget(s.slifertg)
	e1:SetOperation(s.sliferop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1,true)
end

-- Condición estricta: Solo en el turno del oponente
function s.slifercon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end

-- Target: Solo permite activarse si Slifer está actualmente en Posición de Defensa
function s.slifertg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsDefensePos() end
end

-- Operación: Aplica la redirección de ataque si Slifer continúa en Defensa al resolver
function s.sliferop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsDefensePos() and c:IsFaceup() then
		-- Crea una restricción global en el campo para bloquear objetivos de ataque
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
		e1:SetTargetRange(0,LOCATION_MZONE)
		e1:SetValue(function(e,tc) return tc~=c end) -- Prohíbe elegir cualquier carta que no sea este Slifer
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		
		-- Indicador visual en pantalla para avisar que el Escudo está activo
		Duel.Hint(HINT_CARD,0,10000020)
	end
end

