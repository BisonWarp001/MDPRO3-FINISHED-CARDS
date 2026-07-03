-- Zorc Necrophades (Versión Final - Coloso del Apocalipsis)
local s,id=GetID()

function s.initial_effect(c)
	-- No puede ser Invocado de Modo Especial
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e1)

	-- PROCEDIMIENTO NATIVO: Requiere obligatoriamente 5 tributos (Normal Summon)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_LIMIT_SUMMON_PROC)
	e2:SetCondition(s.ttcon)
	e2:SetOperation(s.ttop)
	e2:SetValue(SUMMON_TYPE_ADVANCE)
	c:RegisterEffect(e2)

	-- No puede ser Colocado (cannot be Normal Set)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_LIMIT_SET_PROC)
	e3:SetCondition(s.setcon)
	c:RegisterEffect(e3)

	-- Innegable (Su Invocación Avanzada no puede ser negada)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CANNOT_DISABLE_SUMMON)
	e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e4)
	
	-- Bloqueo total de respuestas en su Invocación
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_SUMMON_SUCCESS)
	e5:SetOperation(s.sumsuc)
	c:RegisterEffect(e5)

	-- INMUNIDAD ABSOLUTA: Inafectado por los efectos de otras cartas
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_IMMUNE_EFFECT)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetValue(s.efilter)
	c:RegisterEffect(e6)

	-- ATAQUE DIRECTO: Si no controlas otros monstruos
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetCode(EFFECT_DIRECT_ATTACK)
	e7:SetCondition(s.dircon)
	c:RegisterEffect(e7)

	-- QUICK EFFECT: Mostrar mano, mandar monstruos al GY y terminar Battle Phase
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,1))
	e8:SetCategory(CATEGORY_TOGRAVE)
	e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e8:SetCode(EVENT_ATTACK_ANNOUNCE)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCountLimit(1)
	e8:SetCondition(s.bpcon)
	e8:SetTarget(s.bptg)
	e8:SetOperation(s.bpop)
	c:RegisterEffect(e8)

	-- END PHASE: Descartar mano entera y limpiar campo del rival (Mandar al GY)
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,2))
	e9:SetCategory(CATEGORY_HANDES+CATEGORY_TOGRAVE)
	e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCode(EVENT_PHASE+PHASE_END)
	e9:SetCountLimit(1)
	e9:SetCondition(s.endcon)
	e9:SetTarget(s.endtg)
	e9:SetOperation(s.endop)
	c:RegisterEffect(e9)
end

--==================================================================
-- REGLAS DE INVOCACIÓN POR SACRIFICIO (5 TRIBUTOS)
--==================================================================
function s.setcon(e,c,minc)
	if not c then return true end
	return false
end

function s.ttcon(e,c,minc)
	if c==nil then return true end
	return minc<=5 and Duel.CheckTribute(c,5)
end

function s.ttop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectTribute(tp,c,5,5)
	c:SetMaterial(g)
	Duel.Release(g,REASON_SUMMON+REASON_MATERIAL)
end

--==================================================================
-- BLOQUEO DE RESPUESTAS E INMUNIDAD ABSOLUTA
--==================================================================
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

--==================================================================
-- CONDICIÓN DE ATAQUE DIRECTO
--==================================================================
function s.dircon(e)
	local c=e:GetHandler()
	local tp=c:GetControler()
	return Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_MZONE,0,nil,TYPE_MONSTER)==1
end

--==================================================================
-- LÓGICA QUICK EFFECT: FRENAZO A LA BATTLE PHASE
--==================================================================
function s.bpcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetAttacker():IsControler(1-tp)
end

function s.bptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,0,tp,LOCATION_HAND)
end

function s.bpop(e,tp,eg,ep,ev,re,r,rp)
	local hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	if #hand==0 then return end
	
	-- Muestra la mano obligatoriamente
	Duel.ConfirmCards(1-tp,hand)
	
	-- Filtra los monstruos en la mano mostrada
	local sg=hand:Filter(Card.IsType,nil,TYPE_MONSTER)
	if #sg>0 then
		Duel.SendtoGrave(sg,REASON_EFFECT)
	end
	
	-- Salta inmediatamente al final de la Battle Phase
	Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_BATTLE,RESET_PHASE+PHASE_BATTLE,1)
end

--==================================================================
-- LÓGICA DE LA END PHASE: LIMPIEZA TOTAL
--==================================================================
function s.endcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.endtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	local opp_field=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,#hand)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,opp_field,#opp_field,0,0)
end

function s.endop(e,tp,eg,ep,ev,re,r,rp)
	local hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	
	-- Ejecuta el descarte oficial de toda la mano
	if #hand>0 and Duel.DiscardHand(tp,nil,#hand,#hand,REASON_EFFECT+REASON_DISCARD)~=0 then
		local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
		if #g>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	-- Si la mano ya estaba vacía, limpia el campo directamente de todas formas
	elseif #hand==0 then
		local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
		if #g>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end
