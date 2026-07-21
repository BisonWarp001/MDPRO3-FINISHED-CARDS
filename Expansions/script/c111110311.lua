-- Ra the Immortal Phoenix (Spell Quick) - ESTILO DE SLIFER REPARADO
local s,id=GetID()
function s.initial_effect(c)
	-- Lista al Ra Fénix Oficial (10000090) y a tu Ra Custom (111110310)
	aux.AddCodeList(c,10000090,111110310,10000010)
	
	-- 1. Activación de la carta: Special Summon Innegable (Estilo Slifer)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- Usamos tus flags de Slifer para blindar la activación sin usar funciones extras
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end

-- --- COSTO: PAGAR 1000 LP ---

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end

-- --- TARGET (Filtro con IDs separados estilo Slifer) ---

function s.spfilter(c,e,tp)
	-- Al agrupar los IDs entre paréntesis, Lua evalúa correctamente ambos códigos por igual
	-- El doble true al final obliga al juego a saltarse el candado e4 (splimit) de tu Ra Custom
	return (c:IsCode(10000090) or c:IsCode(111110310)) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

-- --- OPERACIÓN ---

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	
	if tc then
		-- Forzamos la invocación ignorando condiciones (doble true)
		Duel.SpecialSummon(tc,0,tp,tp,true,true,POS_FACEUP)
	end
end
