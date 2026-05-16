-- Jack's Joker Knight (ID: 111110132)
local s,id=GetID()
function s.initial_effect(c)
	-- Mantenemos los originales solo en la lista de códigos para las Magias oficiales
	aux.AddCodeList(c,111110131,25652259,64788463,90876561)
	
	-- (REGLA) Nombre siempre Jack's Knight
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_ADD_CODE)
	e1:SetValue(90876561)
	c:RegisterEffect(e1)

	-- (1) Search Level 10 on Special Summon by King's JOKER Knight
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- (2) Restriction (Extra Deck LIGHT Warrior)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetTargetRange(1,0)
	e3:SetTarget(s.splimit)
	c:RegisterEffect(e3)

	-- (3) GY Protection (Banish)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_GY)
	e4:SetCountLimit(1,id+1)
	e4:SetCost(aux.bfgcost)
	e4:SetOperation(s.protop)
	c:RegisterEffect(e4)
end

-- (1) Condición: Solo activado por el King CUSTOM
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return re and re:GetHandler():IsCode(111110131)
end

function s.thfilter(c)
	return c:IsLevel(10) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		local sc=g:GetFirst()
		-- Invocación Normal inmediata (ignora límite de 1 por turno)
		if sc:IsSummonable(true,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Summon(tp,sc,true,nil)
		end
	end
end

-- (2) Lógica de Restricción
function s.splimit(e,c)
	return c:IsLocation(LOCATION_EXTRA) and not (c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_WARRIOR))
end

-- (3) Lógica de Protección (Solo efectos del oponente)
function s.protop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsLevel,10))
	e1:SetValue(aux.indoval)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
