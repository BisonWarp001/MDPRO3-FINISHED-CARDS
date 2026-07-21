--The Tormentor Obelisk (Custom Version)
local s,id=GetID()
function s.initial_effect(c)

	-- EFECTO 0: Tratar el nombre/código de esta carta como el Obelisk Original (10000000)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_CODE)
	e0:SetValue(10000000)
	c:RegisterEffect(e0)
	
	-- Invocación: Requiere 3 sacrificios (Sistema nativo sin errores de interfaz)
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e1:SetValue(SUMMON_TYPE_ADVANCE)
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
	
	-- Inmune a los efectos de cartas activados del oponente (Si fue Invocado por Sacrificio)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetCondition(s.immcon)
	e5:SetValue(s.efilter)
	c:RegisterEffect(e5)
	
	-- EFECTO RÁPIDO: Destruir monstruos y aplicar efectos "ALSO" (Simultáneos)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,0))
	e6:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE+CATEGORY_ATKCHANGE)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_MZONE)
	e6:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e6:SetCost(s.descost)
	e6:SetTarget(s.destg)
	e6:SetOperation(s.desop)
	c:RegisterEffect(e6)
	
	-- EL CANDADO ESTILO DARK PALADIN (Monstruos del oponente destruidos por este efecto)
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e7:SetCode(EVENT_DESTROYED)
	e7:SetRange(LOCATION_MZONE)
	e7:SetOperation(s.checkop)
	c:RegisterEffect(e7)
	
	-- Si fue Invocado de Modo Especial: Mandar al GY en la End Phase
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,1))
	e8:SetCategory(CATEGORY_TOGRAVE)
	e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCountLimit(1)
	e8:SetCode(EVENT_PHASE+PHASE_END)
	e8:SetCondition(s.tgcon)
	e8:SetTarget(s.tgtg)
	e8:SetOperation(s.tgop)
	c:RegisterEffect(e8)
end

-- Funciones para la Invocación Nativa por Sacrificio
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

-- Condiciones de Inmunidad
function s.immcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_TRIBUTE)
end
function s.efilter(e,re)
	return re:GetOwnerPlayer()~=e:GetHandlerPlayer() and re:IsActivated()
end

-- Costo y Target del nuevo Efecto Rápido
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Group.FromCards(c)
	if chk==0 then return Duel.CheckReleaseGroup(tp,Card.IsFaceup,2,g) end
	local rg=Duel.SelectReleaseGroup(tp,Card.IsFaceup,2,2,g)
	Duel.Release(rg,REASON_COST)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	if Duel.GetTurnPlayer()~=tp then
		Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,4000)
	end
end

-- RESOLUCIÓN DEL EFECTO RÁPIDO
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_MZONE,nil)
	
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		-- DURANTE TU TURNO: Gana 4000 ATK (El bloqueo del GY ocurre automáticamente gracias a e7)
		if Duel.GetTurnPlayer()==tp then
			if c:IsRelateToEffect(e) and c:IsFaceup() then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_ATTACK)
				e1:SetValue(4000)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				c:RegisterEffect(e1)
			end
		-- EN EL TURNO DEL OPONENTE: 4000 Daño y Destruir Magias/Trampas
		else
			Duel.Damage(1-tp,4000,REASON_EFFECT)
			local sg=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_ONFIELD,nil,TYPE_SPELL+TYPE_TRAP)
			if #sg>0 then
				Duel.Destroy(sg,REASON_EFFECT)
			end
		end
	end
end

-- SISTEMA DE MONITOREO DE DESTRUCCIÓN (Lógica exacta de Dark Paladin)
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=eg:GetFirst()
	while tc do
		-- Si la carta terminó en el GY, su dueño es el oponente (1-tp), y fue destruida por el efecto de este Obelisk
		if tc:IsLocation(LOCATION_GRAVE) and tc:IsControler(1-tp) 
			and tc:IsReason(REASON_EFFECT) and re and re:GetHandler()==c then
			
			-- Aplicar el candado de activación
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
