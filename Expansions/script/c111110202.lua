-- Mound of the God's Beasts (Custom Version)
local s,id=GetID()
function s.initial_effect(c)
	-- Soporte para buscadores y listas (IDs actualizados)
	aux.AddCodeList(c,10000000,10000010,10000020,15771991)
    
	-- Al activar: Añadir Obelisk, Slifer o Ra
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
    
	-- PROTECCIÓN Nivel 10+: Bloquea al oponente, pero TE PERMITE targetear a ti
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsLevelAbove,10))
	e2:SetValue(function(e,re,rp) return rp~=e:GetHandlerPlayer() end)
	c:RegisterEffect(e2)
    
	local e3=e2:Clone()
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetValue(aux.indoval)
	c:RegisterEffect(e3)
    
	-- EFECTO SLIME/GUARDIAN: Enviar al GY y Tokens
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1)
	e4:SetTarget(s.slimetg)
	e4:SetOperation(s.slimeop)
	c:RegisterEffect(e4)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_DECK,0,nil,10000000,10000010,10000020)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end

-- FILTRO: Slime Arquetipo (0x54b) O Guardian Slime (15571991)
function s.slimefilter(c,tp)
	local lv=c:GetLevel()
	return c:IsFaceup() and (c:IsSetCard(0x54b) or c:IsCode(15771991)) and lv>0
		and Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil,lv)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,111110021,0,TYPES_TOKEN,500,500,1,RACE_AQUA,ATTRIBUTE_WATER)
end

function s.tgfilter(c,lv)
	return c:IsLevel(lv) and c:IsAbleToGrave()
end

function s.slimetg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.slimefilter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.slimefilter,tp,LOCATION_MZONE,0,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.slimefilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,tp,0)
end

function s.slimeop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
	local lv=tc:GetLevel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil,lv)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if ft<=0 or not Duel.IsPlayerCanSpecialSummonMonster(tp,111110021,0,TYPES_TOKEN,500,500,1,RACE_AQUA,ATTRIBUTE_WATER) then return end
		local ct=math.min(ft,2)
		if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ct=1 end
		for i=1,ct do
			local token=Duel.CreateToken(tp,111110021)
			Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
		end
		Duel.SpecialSummonComplete()
	end
end
