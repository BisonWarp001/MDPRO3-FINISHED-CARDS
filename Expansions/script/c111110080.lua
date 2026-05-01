-- Calling of the Dark Gods
local s,id=GetID()
function s.initial_effect(c)
	-- Lista de códigos de los Dioses Malvados (Originales y Custom)
	aux.AddCodeList(c,62180201,21208154,57793869,111110200,111110201)
	
	-- (1) Activación (Búsqueda): Efecto de búsqueda doble + descarte
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	-- (2) GY (Invocación): Desterrar para invocar por sacrificio (Quick Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sumtg)
	e2:SetOperation(s.sumop)
	c:RegisterEffect(e2)
end

-- Filtro 1: Magia/Trampa que mencione a los Wicked (Custom y Originales)
function s.thfilter1(c,tp)
	return (aux.IsCodeListed(c,62180201) or aux.IsCodeListed(c,111110200) -- Dreadroot
		or aux.IsCodeListed(c,21208154) or aux.IsCodeListed(c,111110201) -- Avatar
		or aux.IsCodeListed(c,57793869)) -- Eraser
		and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
		and Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,c)
end

-- Filtro 2: Demonio Nivel 10 (Cualquier Wicked)
function s.thfilter2(c)
	return c:IsRace(RACE_FIEND) and c:IsLevel(10) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,1,tp,1)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g1=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter1),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,tp)
	if #g1>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g2=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter2),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,g1:GetFirst())
		g1:Merge(g2)
		if #g1==2 and Duel.SendtoHand(g1,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g1)
			Duel.ShuffleHand(tp)
			Duel.BreakEffect()
			Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
		end
	end
end

-- Lógica para la Invocación por Sacrificio (Cualquier Wicked Fiend Lvl 10)
function s.sumfilter(c)
	return c:IsRace(RACE_FIEND) and c:IsLevel(10) and c:IsSummonable(true,nil)
end

function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end

function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
	local g=Duel.SelectMatchingCard(tp,s.sumfilter,tp,LOCATION_HAND,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		-- Invocación por sacrificio inmediata (true para invocar con efectos activos)
		Duel.Summon(tp,tc,true,nil)
	end
end
