-- Zorc Necrophades
local s,id=GetID()

function s.initial_effect(c)
	-- No puede ser Invocado de Modo Especial
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e1)

	-- PROCEDIMIENTO ÚNICO: Invocación Normal SIEMPRE en el campo del RIVAL (Tributando de CUALQUIER campo)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SPSUM_PARAM)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e2:SetTargetRange(POS_FACEUP_ATTACK,1) -- Fuerza la aparición en el campo del oponente (1 = oponente)
	e2:SetCondition(s.ttcon)
	e2:SetOperation(s.ttop)
	e2:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(e2)

	-- No puede ser Colocado (cannot be Normal Set)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_LIMIT_SET_PROC)
	e4:SetCondition(s.setcon)
	c:RegisterEffect(e4)

	-- Inmunidades de Invocación (Innegable + Bloqueo de respuestas)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
	e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e5)
	
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_SUMMON_SUCCESS)
	e6:SetOperation(s.sumsuc)
	c:RegisterEffect(e6)

	-- INMUNIDAD ABSOLUTA (Estilo Ra Fénix Inmortal)
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetCode(EFFECT_IMMUNE_EFFECT)
	e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e7:SetRange(LOCATION_MZONE)
	e7:SetValue(s.efilter)
	c:RegisterEffect(e7)

	-- INDESTRUIBLE POR BATALLA (Estilo Egyptian God Slime)
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE)
	e8:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e8:SetValue(1)
	c:RegisterEffect(e8)

	-- Efecto Continuo: Standby Phase (Reducir LP a un cuarto)
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,1))
	e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e9:SetCountLimit(1)
	e9:SetCondition(s.lpcon1)
	e9:SetOperation(s.lpop1)
	c:RegisterEffect(e9)

	-- Efecto Opcional: End Phase (Reducir LP a un cuarto -> Pasar Control)
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,2))
	e10:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCode(EVENT_PHASE+PHASE_END)
	e10:SetCountLimit(1)
	e10:SetCondition(s.lpcon2)
	e10:SetTarget(s.lptg2)
	e10:SetOperation(s.lpop2)
	c:RegisterEffect(e10)
end

--==================================================================
-- LÓGICA DE INVOCACIÓN CORREGIDA
--==================================================================
function s.setcon(e,c,minc)
	if not c then return true end
	return false
end

function s.ttcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	-- mg junta los monstruos sacrificables de AMBOS campos sin distinción
	local mg=Duel.GetMatchingGroup(Card.IsReleasable,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	-- El '1-tp' aquí le dice al juego que el destino final de la invocación será el rival
	return minc<=5 and #mg>=5 and Duel.CheckTribute(c,5,5,mg,1-tp)
end

function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	local mg=Duel.GetMatchingGroup(Card.IsReleasable,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	-- Selecciona 5 monstruos combinando libremente ambos lados del campo para mandarlos al oponente
	local g=Duel.SelectTribute(tp,c,5,5,mg,1-tp)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end

--==================================================================
-- COMPORTAMIENTO DE EFECTOS E INMUNIDAD
--==================================================================
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

--==================================================================
-- LÓGICA DE PUNTOS DE VIDA (QUARTER LP)
--==================================================================
function s.lpcon1(e,tp,eg,ep,ev,re,r,rp)
	-- Registra el turno del dueño ACTUAL de la carta
	return Duel.GetTurnPlayer()==tp
end
function s.lpop1(e,tp,eg,ep,ev,re,r,rp)
	local lp=Duel.GetLP(tp)
	local nlp=math.ceil(lp/4)
	Duel.SetLP(tp,nlp)
end

function s.lpcon2(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end
function s.lptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsControlerCanBeChanged() end
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,e:GetHandler(),1,0,0)
end
function s.lpop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	local lp=Duel.GetLP(tp)
	local nlp=math.ceil(lp/4)
	Duel.SetLP(tp,nlp)
	
	Duel.BreakEffect()
	if not Duel.GetControl(c,1-tp) then
		if not c:IsImmuneToEffect(e) and c:IsAbleToChangeControler() then
			Duel.Destroy(c,REASON_EFFECT)
		end
	end
end
