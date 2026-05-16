-- Altar of the Wicked Divinities
local s,id=GetID()
s.listed_series={0x3f2}
function s.initial_effect(c)
	-- Mencionar a los 3 Dioses Oscuros (Originales y Custom)
	aux.AddCodeList(c,62180201,21208154,57793869)
	
	-- (0) Activación
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) 
	c:RegisterEffect(e0)
	
	-- Protección: Primera vez que un Wicked (Demonio Nivel 10) fuera a ser destruido
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetTarget(s.indtg)
	e1:SetCountLimit(1)
	e1:SetValue(s.indct)
	c:RegisterEffect(e1)

	-- (1) Búsqueda manual (Ignition)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	
	-- (2) Robo de cartas (Continuo)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.drcon)
	e3:SetOperation(s.drop)
	e3:SetCountLimit(1,id+100)
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

--====================================
-- Protection logic (Cubre Custom y Originales)
--====================================
function s.indtg(e,c)
	-- Filtra Demonios de Nivel 10 (Los Wicked Gods originales y tus custom)
	return c:IsFaceup() and c:IsRace(RACE_FIEND) and c:IsLevel(10)
end
function s.indct(e,re,r,rp)
	return (r&REASON_DESTROY)~=0
end

--====================================
-- Search "Wicked Divinities"
--====================================
function s.thfilter(c)
	return c:IsSetCard(0x3f2) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,1,tp,LOCATION_HAND)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		Duel.BreakEffect()
		if Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 then
			Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_EFFECT+REASON_DISCARD)
		end
	end
end

--====================================
-- Draw logic (Ajustado con IDs Custom)
--====================================
function s.cfilter(c,tp)
    -- Se activa con Avatar, Dreadroot o Eraser (Originales y IDs Custom)
    return c:IsSummonPlayer(tp) and 
        (c:IsCode(62180201) or c:IsCode(21208154) or c:IsCode(57793869))
end

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Draw(tp,2,REASON_EFFECT)
end
