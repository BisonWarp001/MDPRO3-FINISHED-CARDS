-- Altar of Jashin
local s,id,o=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,21208154,57793869,62180201)
	-- Activar la carta como Magia Continua
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) -- Solo puedes activar 1 "Altar of Jashin" por turno
	c:RegisterEffect(e0)

	-- (1) Protección ante Invocación por Tributo (Lógica basada en Meteor)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetOperation(s.sucop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCode(EVENT_CHAIN_END)
	e2:SetOperation(s.cedop)
	c:RegisterEffect(e2)

	-- (2) Una vez por turno: Añadir 1 monstruo "Jashin" del Deck a la mano
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1) -- Una vez por turno
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	-- (3) Robar 2 cartas si se Invoca de Modo Normal a Avatar, Dreadroot o Eraser
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_DRAW)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1,id) -- Solo puedes usar este efecto de "Altar of Jashin" una vez por turno
	e4:SetTarget(s.drtg)
	e4:SetOperation(s.drop)
	c:RegisterEffect(e4)
end

-- ====================================================================================
-- LÓGICA DEL EFECTO (1): PROTECCIÓN ANTE INVOCACIÓN POR TRIBUTO
-- ====================================================================================

function s.chainlm(e,rp,tp)
	return tp==rp -- El oponente no puede activar cartas (solo tú puedes encadenar)
end

function s.sucfilter(c,tp)
	return c:IsSummonType(SUMMON_TYPE_ADVANCE) and c:IsControler(tp)
end

function s.sucop(e,tp,eg,ep,ev,re,r,rp)
	if not eg:IsExists(s.sucfilter,1,nil,tp) then return end
	if Duel.GetCurrentChain()==0 then
		Duel.SetChainLimitTillChainEnd(s.chainlm)
	elseif Duel.GetCurrentChain()==1 then
		Duel.RegisterFlagEffect(tp,id+o,RESET_EVENT+RESETS_STANDARD,0,1)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_CHAINING)
		e1:SetOperation(s.resetop)
		Duel.RegisterEffect(e1,tp)
		local e2=e1:Clone()
		e2:SetCode(EVENT_BREAK_EFFECT)
		e2:SetReset(RESET_CHAIN)
		Duel.RegisterEffect(e2,tp)
	end
end

function s.resetop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ResetFlagEffect(tp,id+o*2)
	e:Reset()
end

function s.cedop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFlagEffect(tp,id+o*2)~=0 then
		Duel.SetChainLimitTillChainEnd(s.chainlm)
	end
	Duel.ResetFlagEffect(tp,id+o*2)
end

-- ====================================================================================
-- LÓGICA DEL EFECTO (2): BÚSQUEDA DEL ARQUETIPO "JASHIN" (0x3f2)
-- ====================================================================================

function s.thfilter(c)
	return c:IsSetCard(0x3f2) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ====================================================================================
-- LÓGICA DEL EFECTO (3): ROBO DE CARTAS (THE WICKED GODS)
-- ====================================================================================

function s.drfilter(c)
	return c:IsFaceup() and (c:IsCode(21208154) or c:IsCode(57793869) or c:IsCode(62180201))
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.drfilter,1,nil) and Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end
