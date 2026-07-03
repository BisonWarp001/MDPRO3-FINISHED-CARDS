-- Nordic Relic - Andvaranaut Spark
local s,id=GetID()

s.listed_series={0x42,0x4b,0x5042}

function s.initial_effect(c)
	-- ① Efecto Principal: Invocación desde Extra Deck
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	-- REGLA IMPERMANENCE: Habilita ventanas de respuesta automáticas en el turno rival
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_BATTLE_START)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ② PERMISO ESTILO IMPERMANENCE: Activar Trampa Normal desde la mano
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND) -- Código oficial para Trampas de Mano
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)

	-- ③ Efecto en Cementerio: Desterrarse para destruir 1 carta
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id+1)
	e3:SetCost(aux.bfgcost)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-------------------------------------------------
-- CONDICIÓN HAND TRAP (Estilo Impermanence)
-------------------------------------------------
function s.handcon(e)
	local tp=e:GetHandlerPlayer()
	-- El rival controla al menos 1 monstruo y tú controlas EXACTAMENTE 0 monstruos
	return Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0 
		and Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
end

-------------------------------------------------
-- ① TARGET Y FILTROS PRINCIPALES
-------------------------------------------------
function s.nordicfilter(c)
	return c:IsSetCard(0x42) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemove() and c:GetLevel()>0
end

function s.aesirfilter(c,e,tp)
	if not (c:IsSetCard(0x4b) and c:IsType(TYPE_SYNCHRO) 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)) then return false end
	
	local g=Duel.GetMatchingGroup(s.nordicfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK+LOCATION_GRAVE,0,nil)
	return g:CheckWithSumEqual(Card.GetLevel,c:GetLevel(),1,99)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- Si intentas activarla desde la mano, valida de forma obligatoria la condición de casillas
		if e:GetHandler():IsLocation(LOCATION_HAND) and not s.handcon(e) then return false end
		return Duel.IsExistingMatchingCard(s.aesirfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then return end
	
	-- 1. Elige al Dios Aesir
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local scg=Duel.SelectMatchingCard(tp,s.aesirfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local sc=scg:GetFirst()
	if not sc then return end
	
	-- 2. Elige materiales automáticos que sumen su nivel
	local g=Duel.GetMatchingGroup(s.nordicfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK+LOCATION_GRAVE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local mat=g:SelectWithSumEqual(tp,Card.GetLevel,sc:GetLevel(),1,99)
	
	-- 3. Desierra del Deck/Mano/Campo/GY e Invoca por Sincronía
	if #mat>0 and Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL)~=0 then
		sc:SetMaterial(mat)
		if Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
			sc:CompleteProcedure()
		end
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
