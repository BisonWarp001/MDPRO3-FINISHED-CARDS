-- Apostle of Jashin
local s,id=GetID()

function s.initial_effect(c)
	-- Registrar que esta carta nombra textualmente a los 3 Dioses Malignos
	aux.AddCodeList(c,21208154,62180201,57793869)

	-------------------------------------------------
	-- ① If added to hand (except draw): SS (HOPT id)
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② If Tributed for a Wicked God: Select 1 (HOPT)
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.wickedcon)
	e2:SetTarget(s.wickedtg)
	e2:SetOperation(s.wickedop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e2b)
end

-- IDs de los Dioses Malignos
local CARD_AVATAR   = 21208154
local CARD_DREADROOT = 62180201
local CARD_ERASER    = 57793869

-------------------------------------------------
-- ① Condition & Functions (Gargoyle Style)
-------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsReason(REASON_DRAW)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-------------------------------------------------
-- ② Condition & Functions
-------------------------------------------------
function s.wickedcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	return c:IsReason(REASON_SUMMON) and rc 
		and (rc:IsCode(CARD_AVATAR) or rc:IsCode(CARD_DREADROOT) or rc:IsCode(CARD_ERASER))
end

-- Filtro para buscar una trampa "Jashin" (arquetipo 0x3f2)
function s.trapfilter(c)
	return c:IsSetCard(0x3f2) and c:IsType(TYPE_TRAP) and c:IsSSetable()
end

function s.wickedtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	
	-- Contar cuántos monstruos totales se usaron como tributo para esa invocación
	local ct=rc:GetMaterialCount()
	if chk==0 then
		if ct==0 then return false end
		-- Opción 1: Negar cartas boca arriba (HOPT usando id+100)
		local b1=Duel.IsExistingMatchingCard(aux.NegateAnyFilter,tp,0,LOCATION_ONFIELD,1,nil) and Duel.GetFlagEffect(tp,id+100)==0
		-- Opción 2: Colocar Trampa "Jashin" (HOPT usando id+200)
		local b2=Duel.IsExistingMatchingCard(s.trapfilter,tp,LOCATION_DECK,0,1,nil) and Duel.GetFlagEffect(tp,id+200)==0
		return b1 or b2
	end

	local b1=Duel.IsExistingMatchingCard(aux.NegateAnyFilter,tp,0,LOCATION_ONFIELD,1,nil) and Duel.GetFlagEffect(tp,id+100)==0
	local b2=Duel.IsExistingMatchingCard(s.trapfilter,tp,LOCATION_DECK,0,1,nil) and Duel.GetFlagEffect(tp,id+200)==0

	-- Menú de opciones utilizando la estructura clásica de EDOCore
	local op=aux.SelectFromOptions(tp,
		{b1,aux.Stringid(id,2),1}, -- "Negate face-up cards"
		{b2,aux.Stringid(id,3),2}) -- "Set 1 Jashin Trap"

	e:SetLabel(op,ct)
	if op==1 then
		e:SetCategory(CATEGORY_DISABLE)
		Duel.RegisterFlagEffect(tp,id+100,RESET_PHASE+PHASE_END,0,1)
		local g=Duel.GetMatchingGroup(aux.NegateAnyFilter,tp,0,LOCATION_ONFIELD,nil)
		Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
	elseif op==2 then
		e:SetCategory(0)
		Duel.RegisterFlagEffect(tp,id+200,RESET_PHASE+PHASE_END,0,1)
	end
end

function s.wickedop(e,tp,eg,ep,ev,re,r,rp)
	local op,ct=e:GetLabel()
	
	-- ● Opción 1: Negar efectos del oponente igual a la cantidad de materiales
	if op==1 then
		if not Duel.IsExistingMatchingCard(aux.NegateAnyFilter,tp,0,LOCATION_ONFIELD,1,nil) then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISABLE)
		local g=Duel.SelectMatchingCard(tp,aux.NegateAnyFilter,tp,0,LOCATION_ONFIELD,1,ct,nil)
		if #g>0 then
			Duel.HintSelection(g)
			for tc in aux.Next(g) do
				Duel.NegateRelatedChain(tc,RESET_TURN_SET)
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
				local e2=Effect.CreateEffect(e:GetHandler())
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e2:SetCode(EFFECT_DISABLE_EFFECT)
				e2:SetValue(RESET_TURN_SET)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e2)
				if tc:IsType(TYPE_TRAPMONSTER) then
					local e3=Effect.CreateEffect(e:GetHandler())
					e3:SetType(EFFECT_TYPE_SINGLE)
					e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
					e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
					e3:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e3)
				end
			end
		end

	-- ● Opción 2: Colocar 1 Trampa "Jashin" directamente desde el Deck
	elseif op==2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g=Duel.SelectMatchingCard(tp,s.trapfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SSet(tp,g:GetFirst())
		end
	end
end
