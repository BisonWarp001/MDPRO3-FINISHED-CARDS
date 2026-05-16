-- Aura of Despair
local s,id=GetID()
function s.initial_effect(c)
    -- Mencionar a Dreadroot (Original y Custom)
    aux.AddCodeList(c,62180201)
    -- Activar
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    -- Propiedades exactas de Fist of Fate (No puede ser negada)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- Filtro para Dreadroot (IDs específicos)
function s.dreadfilter(c)
    return c:IsFaceup() and (c:IsOriginalCodeRule(62180201))
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.dreadfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.dreadfilter,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.dreadfilter,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_MZONE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
    
    local atk=tc:GetAttack()
    -- Filtrar monstruos del oponente con menor ATK actual
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil):Filter(function(c) return c:GetAttack()<atk end,nil)
    
    if #g>0 then
        for nc in aux.Next(g) do
            -- Negar efectos en campo
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            nc:RegisterEffect(e1)
            local e2=e1:Clone()
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            nc:RegisterEffect(e2)
            
            -- No pueden ser tributados
            local e3=Effect.CreateEffect(e:GetHandler())
            e3:SetType(EFFECT_TYPE_SINGLE)
            e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e3:SetCode(EFFECT_UNRELEASABLE_SUM)
            e3:SetValue(1)
            e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            nc:RegisterEffect(e3)
            local e4=e3:Clone() e4:SetCode(EFFECT_UNRELEASABLE_NONSUM) nc:RegisterEffect(e4)
            
            -- No pueden ser materiales de Extra Deck
            local e5=Effect.CreateEffect(e:GetHandler())
            e5:SetType(EFFECT_TYPE_SINGLE)
            e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e5:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
            e5:SetValue(1)
            e5:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            nc:RegisterEffect(e5)
            local e6=e5:Clone() e6:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL) nc:RegisterEffect(e6)
            local e7=e5:Clone() e7:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL) nc:RegisterEffect(e7)
            local e8=e5:Clone() e8:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL) nc:RegisterEffect(e8)
        end
        Duel.AdjustInstantly()
    end

    -- Efecto adicional Main Phase (Banish del Extra Deck)
    if Duel.GetTurnPlayer()==tp and (Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2) then
        local exg=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
        -- Solo si hay cartas con menos ATK que el Dreadroot objetivo
        local resg=exg:Filter(function(c,matk) return c:GetAttack()<matk end,nil,tc:GetAttack())
        if #resg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
            Duel.BreakEffect()
            Duel.ConfirmCards(tp,exg)
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
            local sg=resg:Select(tp,1,1,nil)
            if #sg>0 then
                Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
            end
            Duel.ShuffleExtra(1-tp)
        end
    end
end
