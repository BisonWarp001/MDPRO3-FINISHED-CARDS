--Osiris the Sky Dragon (Custom Version)
local s,id=GetID()
function s.initial_effect(c)
	-- EFECTO 0: Tratar el nombre/código de esta carta como el Slifer Original (1000020)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_CODE)
	e0:SetValue(10000020)
	c:RegisterEffect(e0)
	
	-- Invocación: Requiere 3 sacrificios (Sistema nativo idéntico a Obelisk)
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e1:SetCondition(s.ttcon)
	e1:SetOperation(s.ttop)
	c:RegisterEffect(e1)
	
	-- No puede ser Colocado (Normal Set)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_LIMIT_SET_PROC)
	e2:SetCondition(s.setcon)
	c:RegisterEffect(e2)
	
	-- Su Invocación Normal no puede ser negada
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e3)
	
	-- No se pueden activar cartas/efectos cuando es invocado
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetOperation(s.sumsuc)
	c:RegisterEffect(e4)
	
	-- Inmune a los efectos de cartas activados del oponente (Si fue Invocado por Sacrificio - Idéntico a Obelisk)
	local e5a=Effect.CreateEffect(c)
	e5a:SetType(EFFECT_TYPE_SINGLE)
	e5a:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5a:SetRange(LOCATION_MZONE)
	e5a:SetCode(EFFECT_IMMUNE_EFFECT)
	e5a:SetCondition(s.immcon)
	e5a:SetValue(s.efilter)
	c:RegisterEffect(e5a)
	
	-- ATK/DEF: Gana 1000 por cada carta en mano
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_UPDATE_ATTACK)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetValue(s.adval)
	c:RegisterEffect(e6)
	local e7=e6:Clone()
	e7:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e7)
	
	-- BOCA DE LA SEGUNDA FUERZA: Reducción de ATK al ser Invocado
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,0))
	e8:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCode(EVENT_SUMMON_SUCCESS)
	e8:SetTarget(s.atktg)
	e8:SetOperation(s.atkop)
	c:RegisterEffect(e8)
	local e9=e8:Clone()
	e9:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e9)
	
	-- EL CANDADO ESTILO DARK PALADIN: Monstruos destruidos por la Boca de la Segunda Fuerza
	local e10=Effect.CreateEffect(c)
	e10:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e10:SetCode(EVENT_DESTROYED)
	e10:SetRange(LOCATION_MZONE)
	e10:SetOperation(s.checkop)
	c:RegisterEffect(e10)
	
	-- Si fue Invocado de Modo Especial: Mandar al GY en la End Phase
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_TOGRAVE)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetCondition(s.tgcon)
	e5:SetTarget(s.tgtg)
	e5:SetOperation(s.tgop)
	c:RegisterEffect(e5)
end

-- Funciones para la Invocación Nativa por Sacrificio (Copiado exacto de Obelisk)
function s.ttcon(e,c,minc)
	if c==nil then return true end
	return minc<=3 and Duel.CheckTribute(c,3)
end
function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectTribute(tp,c,3,3)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end
function s.setcon(e,c,minc)
	if not c then return true end
	return false
end
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

-- Condiciones de Inmunidad (Copiado exacto de Obelisk, usando SUMMON_TYPE_TRIBUTE)
function s.immcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_TRIBUTE)
end
function s.efilter(e,re)
	return re:GetOwnerPlayer()~=e:GetHandlerPlayer() and re:IsActivated()
end

-- Cálculo de ATK/DEF por mano
function s.adval(e,c)
	return Duel.GetFieldGroupCount(c:GetControler(),LOCATION_HAND,0)*1000
end

-- Filtro para detectar invocaciones enemigas en Posición de Ataque
function s.atkfilter(c,tp)
	return c:IsControler(1-tp) and c:IsPosition(POS_FACEUP_ATTACK)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.atkfilter,1,nil,tp) end
	local g=eg:Filter(s.atkfilter,nil,tp)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,g,#g,0,0)
end

-- OPERACIÓN DE REDUCCIÓN DE ATK
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetsRelateToChain():Filter(Card.IsFaceup,nil)
	if #g==0 then return end
	local dg=Group.CreateGroup()
	local c=e:GetHandler()
	local tc=g:GetFirst()
	while tc do
		local preatk=tc:GetAttack()
		
		-- Reducir 2000 ATK
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-2000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		
		-- Si su ATK original no era 0, pero ahora llegó a 0 como resultado directo:
		if preatk~=0 and tc:IsAttack(0) then
			dg:AddCard(tc)
		end
		tc=g:GetNext()
	end
	
	-- Destruir todos los monstruos cuya fuerza cayó a 0
	if #dg>0 then
		Duel.Destroy(dg,REASON_EFFECT)
	end
end

-- SISTEMA DE MONITOREO DE DESTRUCCIÓN PERSISTENTE (Estilo Dark Paladin)
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=eg:GetFirst()
	while tc do
		-- Si la carta terminó en el GY, pertenece al oponente (1-tp),
		-- fue destruida por un efecto, y ese efecto fue disparado por este Slifer
		if tc:IsLocation(LOCATION_GRAVE) and tc:IsControler(1-tp) 
			and tc:IsReason(REASON_EFFECT) and re and re:GetHandler()==c then
			
			-- Aplicar candado absoluto de activación en el GY
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CANNOT_TRIGGER)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1,true)
		end
		tc=eg:GetNext()
	end
end

-- Mantenimiento de la Invocación Especial (End Phase)
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,e:GetHandler(),1,0,0)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		Duel.SendtoGrave(c,REASON_EFFECT)
	end
end
