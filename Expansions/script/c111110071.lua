-- ID de la carta (Reemplaza 1000000 por el tuyo)
local s,id=GetID()
function s.initial_effect(c)
	-- Registrar los monstruos que menciona la carta obligatoriamente
	aux.AddCodeList(c,21208154,62180201,57793869)
	
	-- Activar carta
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetHintTiming(0,TIMING_END_PHASE)
	c:RegisterEffect(e0)
	
	-- Invocación Especial (Efecto 1)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,EFFECT_COUNT_CODE_CHAIN)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	-- Añadir e Invocar de forma Normal (Efecto 2)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- Filtros de IDs de los monstruos "The Wicked"
function s.wicked_filter(c)
	return c:IsCode(21208154,62180201,57793869)
end

-- Filtro corregido separando individualmente cada ID que menciona la carta
function s.spfilter(c,e,tp)
	return (aux.IsCodeListed(c,21208154) or aux.IsCodeListed(c,62180201) or aux.IsCodeListed(c,57793869))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP)
end


-- Condición Efecto 1: El oponente activa una carta o efecto
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

-- Target Efecto 1
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

-- Operación Efecto 1
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<1 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- Restricción: No invocar monstruos con el mismo nombre original por este efecto el resto del turno
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetLabel(g:GetFirst():GetOriginalCodeRule())
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

-- Limitación de invocación
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	local sc=se:GetHandler()
	return sc and sc:IsCode(id) and c:IsOriginalCodeRule(e:GetLabel())
end

-- Condición Efecto 2: Enviado de la mano o campo al cementerio
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_HAND+LOCATION_ONFIELD)
end

-- Target Efecto 2
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.wicked_filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end

-- Operación Efecto 2
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.wicked_filter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		local sc=g:GetFirst()
		-- Invocar Normal inmediatamente después de resolver
		if sc:IsSummonable(true,nil) or sc:IsMSetable(true,nil) then
			Duel.BreakEffect()
			Duel.Summon(tp,sc,true,nil)
		end
	end
end
