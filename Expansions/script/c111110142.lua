-- Nordic Relic - Andvaranaut Spark
local s,id=GetID()
s.listed_series={0x42,0x4b,0x5042}

function s.initial_effect(c)
	-- ① Efecto Principal: Invocación desde Extra Deck (Tratado como Sincronía)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_BATTLE_START)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ② Trampa de Mano
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)

	-- ③ Efecto en Cementerio: Desterrarse para destruir 1 carta
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) 
	e3:SetCost(aux.bfgcost)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-------------------------------------------------
-- CONDICIÓN HAND TRAP
-------------------------------------------------
function s.handcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0 
		and Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
end

-------------------------------------------------
-- ① LOGICA COMPLETAMENTE ABIERTA (BUGS DE CAMPO LLENO CORREGIDOS)
-------------------------------------------------
function s.nordicfilter(c,tp)
	return c:IsSetCard(0x42) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemove(tp) and c:GetLevel()>0
end

function s.aesirfilter(c,e,tp)
	return c:IsSetCard(0x4b) and c:IsType(TYPE_SYNCHRO) 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if e:GetHandler():IsLocation(LOCATION_HAND) and not s.handcon(e) then return false end
		if Duel.IsPlayerAffectedByEffect(tp,EFFECT_CANNOT_REMOVE) then return false end
		
		return Duel.IsExistingMatchingCard(s.aesirfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(s.nordicfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerAffectedByEffect(tp,EFFECT_CANNOT_REMOVE) then return end
	
	-- 1. Seleccionar CUALQUIER Aesir de tu Extra Deck
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local scg=Duel.SelectMatchingCard(tp,s.aesirfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local sc=scg:GetFirst()
	if not sc then return end
	
	-- 2. Recopilar el grupo total de materiales Nordic válidos
	local g=Duel.GetMatchingGroup(s.nordicfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK+LOCATION_GRAVE,0,nil,tp)
	local mat=Group.CreateGroup()
	local current_lv = 0
	local target_lv = sc:GetLevel()
	
	-- 3. Bucle de selección interactivo obligatorio
	while current_lv < target_lv do
		local remaining = target_lv - current_lv
		local tg = g:Filter(function(tc) return tc:GetLevel() <= remaining and not mat:IsContains(tc) end, nil)
		
		if #tg == 0 then break end 
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local sg = tg:Select(tp,1,1,nil)
		if #sg == 0 then break end
		
		local selected_card = sg:GetFirst()
		mat:AddCard(selected_card)
		current_lv = current_lv + selected_card:GetLevel()
	end
	
	-- 4. VALIDACIÓN DE ZONAS ACTUALIZADA (Anti-Bug de Campo Lleno):
	-- Se evalúa el espacio del Extra Deck pasando 'mat' como parámetro. Si desterras monstruos de tu propio campo, 
	-- el motor simulará que esas zonas se liberan, permitiendo la invocación legal del Dios Aesir.
	if current_lv == target_lv and #mat > 0 then
		if Duel.GetLocationCountFromEx(tp,tp,mat,sc)<=0 then return end
		
		sc:SetMaterial(mat)
		if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL)~=0 then
			if Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
				sc:CompleteProcedure()
			end
		end
	else
		return
	end
end

-------------------------------------------------
-- ③ EFECTO EN CEMENTERIO
-------------------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end
