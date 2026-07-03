-- The Black Sun (Trampa de Contraefecto)
local s,id=GetID()

function s.initial_effect(c)
	-- Mencionar a los 3 Dioses Malignos (Permite que el motor detecte el soporte)
	aux.AddCodeList(c, 21208184, 57793869, 62180201) -- Avatar, Dreadroot, Eraser
	
	-- (1) ACTIVACIÓN: Negate + Banish + Destroy ST (Avatar)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id) -- Límite una vez por turno
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- (2) EFECTO EN GY: Añadir a la mano ST que los mencione
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100) -- Límite una vez por turno (efecto diferente)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- ID de los Dioses Malignos
local WICKED_AVATAR   = 21208184
local WICKED_DREADROOT = 57793869
local WICKED_ERASER    = 62180201

--====================================
-- LÓGICA (1): NEGACIÓN
--====================================
function s.wicked_filter(c)
	return c:IsFaceup() and (c:IsCode(WICKED_AVATAR) or c:IsCode(WICKED_DREADROOT) or c:IsCode(WICKED_ERASER))
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- El oponente activa un efecto y controlas al menos uno de los 3
	return rp==1-tp and Duel.IsExistingMatchingCard(s.wicked_filter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
	end
	
	-- Si controlas a Avatar, añade destrucción de Magias/Trampas al objetivo del efecto
	if Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_MZONE,0,1,nil,WICKED_AVATAR) then
		local sg=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_SZONE,nil,TYPE_SPELL+TYPE_TRAP)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,sg,#sg,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Negar la activación
	if Duel.NegateActivation(ev) then
		local rc=re:GetHandler()
		-- 2. Desterrar la carta (Se remueve IsRelateToEffect para evitar fallos si cambió de zona)
		Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)
		
		-- 3. Chequeo exclusivo para "The Wicked Avatar" boca arriba en tu campo
		local avatar_chk=Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsCode(WICKED_AVATAR) end,tp,LOCATION_MZONE,0,1,nil)
		if avatar_chk then
			local sg=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_SZONE,nil,TYPE_SPELL+TYPE_TRAP)
			if #sg>0 then
				Duel.BreakEffect() -- Añade la pausa de tiempo "also" (también)
				Duel.Destroy(sg,REASON_EFFECT)
			end
		end
	end
end

--====================================
-- LÓGICA (2): BUSCADOR DESDE EL CEMENTERIO
--====================================
function s.thfilter(c)
	-- Filtra Magia/Trampa que mencione a cualquiera de los tres, excepto esta misma carta
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand() and not c:IsCode(id)
		and (aux.IsCodeListed(c,WICKED_AVATAR) or aux.IsCodeListed(c,WICKED_DREADROOT) or aux.IsCodeListed(c,WICKED_ERASER))
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
