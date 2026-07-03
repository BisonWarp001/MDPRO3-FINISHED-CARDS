-- Zorc Necrophades
local s,id=GetID()

function s.initial_effect(c)
	-- No puede ser Invocado de Modo Especial
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e1)

	-- PROCEDIMIENTO ÚNICO: Invocación Normal en el campo rival tributando TODO su campo
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SPSUM_PARAM)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e2:SetTargetRange(POS_FACEUP_ATTACK,1) -- 1 fuerza la aparición en el campo enemigo
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

	-- Innegable (Normal Summon cannot be negated)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
	e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e5)
	
	-- Bloqueo de respuestas al entrar (cards and effects cannot be activated)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_SUMMON_SUCCESS)
	e6:SetOperation(s.sumsuc)
	c:RegisterEffect(e6)

	-- INMUNIDAD ABSOLUTA
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetCode(EFFECT_IMMUNE_EFFECT)
	e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e7:SetRange(LOCATION_MZONE)
	e7:SetValue(s.efilter)
	c:RegisterEffect(e7)

	-- INDESTRUIBLE POR BATALLA
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE)
	e8:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e8:SetValue(1)
	c:RegisterEffect(e8)

	-- Standby Phase: Pagar la mitad de los LP o candado de invocación (Para el Controlador Actual)
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,1))
	e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e9:SetCountLimit(1)
	e9:SetCondition(s.lpcon)
	e9:SetOperation(s.lpop)
	c:RegisterEffect(e9)

	-- End Phase: Destruir todas las cartas que controla tu oponente (Para el Controlador Actual)
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,2))
	e10:SetCategory(CATEGORY_DESTROY)
	e10:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCode(EVENT_PHASE+PHASE_END)
	e10:SetCountLimit(1)
	e10:SetCondition(s.descon)
	e10:SetTarget(s.destg)
	e10:SetOperation(s.desop)
	c:RegisterEffect(e10)
end

--==================================================================
-- LÓGICA DE INVOCACIÓN (TRIBUTAR TODO EL CAMPO ENEMIGO)
--==================================================================
function s.setcon(e,c,minc)
	if not c then return true end
	return false
end

function s.ttcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	-- Verifica los monstruos que controla tu oponente (1-tp) que se puedan tributar
	local mg=Duel.GetMatchingGroup(Card.IsReleasable,tp,0,LOCATION_MZONE,nil)
	-- Requiere que el oponente controle al menos 1 monstruo para poder bajar a Zorc
	return #mg>0 and Duel.CheckTribute(c,#mg,#mg,mg,1-tp)
end

function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	local tp=c:GetControler()
	local mg=Duel.GetMatchingGroup(Card.IsReleasable,tp,0,LOCATION_MZONE,nil)
	c:SetMaterial(mg)
	Duel.Release(mg,REASON_SUMMON+REASON_MATERIAL)
end

function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

--==================================================================
-- LÓGICA DE LA STANDBY PHASE (PAGAR MITAD DE LP O CANDADO)
--==================================================================
function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
	-- Se activa en la Standby Phase de quien controla físicamente la carta hoy
	return Duel.GetTurnPlayer()==tp
end

function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	-- Pregunta al controlador actual si desea pagar la mitad de sus LP
	if Duel.GetLP(tp)>1 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
	else
		-- Si decide NO pagar, se aplica el candado de Invocación por el resto del turno
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CANNOT_SUMMON)
		Duel.RegisterEffect(e2,tp)
		
		local e3=e1:Clone()
		e3:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
		Duel.RegisterEffect(e3,tp)
	end
end

--==================================================================
-- LÓGICA DE LA END PHASE (DESTRUIR EL CAMPO DEL OPONENTE DEL CONTROLADOR)
--==================================================================
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Desde la perspectiva del controlador actual (tp), destruye las cartas de su oponente (1-tp)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
