-- Obliteration of the Gods
local s,id=GetID()

function s.initial_effect(c)
    -- Fusion Summon materials & Revive limit
    c:EnableReviveLimit()
    aux.AddFusionProcCode3(c,10000000,10000010,10000020,true,true)

    -- Must be Special Summoned from your Extra Deck by sending the above monsters you control to the GY
    aux.AddContactFusionProcedure(c,s.contactfilter(c),LOCATION_MZONE,0,Duel.SendtoGrave,REASON_MATERIAL|REASON_FUSION)

    -- Special Summon condition & You can only Special Summon "Obliteration of the Gods" once per turn (Hard OPT Check)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    e1:SetValue(s.splimit)
    c:RegisterEffect(e1)

    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCondition(s.regcon)
    e2:SetOperation(s.regop)
    c:RegisterEffect(e2)

    -- This card's Special Summon cannot be negated
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    c:RegisterEffect(e3)

    -- When Special Summoned, your opponent's cards and effects cannot be activated
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    e4:SetOperation(s.sumsuc)
    c:RegisterEffect(e4)

    -- This card's ATK/DEF become the combined ATK/DEF the above monsters had on the field
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_SPSUMMON_SUCCESS)
    e5:SetOperation(s.statop)
    c:RegisterEffect(e5)

    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCode(EFFECT_SET_ATTACK_FINAL)
    e6:SetValue(s.atkval)
    c:RegisterEffect(e6)

    local e7=e6:Clone()
    e7:SetCode(EFFECT_SET_DEFENSE_FINAL)
    e7:SetValue(s.defval)
    c:RegisterEffect(e7)

    -- Unaffected by other card effects
    local e8=Effect.CreateEffect(c)
    e8:SetType(EFFECT_TYPE_SINGLE)
    e8:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCode(EFFECT_IMMUNE_EFFECT)
    e8:SetValue(s.immfilter)
    c:RegisterEffect(e8)

    -- (1) Each time a card(s) your opponent controls is destroyed by this card's effect: Inflict 1000 damage to your opponent
    local e9=Effect.CreateEffect(c)
    e9:SetDescription(aux.Stringid(id,0))
    e9:SetCategory(CATEGORY_DAMAGE)
    e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e9:SetCode(EVENT_DESTROYED)
    e9:SetRange(LOCATION_MZONE)
    e9:SetCondition(s.damcon)
    e9:SetTarget(s.damtg)
    e9:SetOperation(s.damop)
    c:RegisterEffect(e9)

    -- (2) Thrice per turn (Quick Effect): When your opponent activates a card or effect; you can negate the activation, and if you do, destroy it
    local e10=Effect.CreateEffect(c)
    e10:SetDescription(aux.Stringid(id,1))
    e10:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e10:SetType(EFFECT_TYPE_QUICK_O)
    e10:SetCode(EVENT_CHAINING)
    e10:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e10:SetRange(LOCATION_MZONE)
    e10:SetCountLimit(3,id+100)
    e10:SetCondition(s.negcon)
    e10:SetTarget(s.negtg)
    e10:SetOperation(s.negop)
    c:RegisterEffect(e10)
end

---------------------------------------------------------------------------------
-- CONTACT FUSION & SUMMON LIMIT
---------------------------------------------------------------------------------
function s.contactfilter(ec)
    return function(c)
        return c:IsAbleToGraveAsCost()
            and Duel.GetFlagEffect(ec:GetControler(),id)==0
    end
end

function s.splimit(e,se,sp,st)
    return bit.band(st,SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION
        and Duel.GetFlagEffect(sp,id)==0
end

function s.regcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
end

---------------------------------------------------------------------------------
-- NO RESPONSE ON SUMMON
---------------------------------------------------------------------------------
function s.sumsuc(e,tp,eg,ep,ev,re,r,rp)
    Duel.SetChainLimitTillChainEnd(aux.FALSE)
end

---------------------------------------------------------------------------------
-- REGISTER ATK/DEF CALCULATIONS
---------------------------------------------------------------------------------
function s.statop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local mg=c:GetMaterial()
    local atk,def=0,0
    for tc in aux.Next(mg) do
        atk=atk+math.max(tc:GetPreviousAttackOnField(),0)
        def=def+math.max(tc:GetPreviousDefenseOnField(),0)
    end
    c:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,0,1,atk)
    c:RegisterFlagEffect(id+1,RESET_EVENT|RESETS_STANDARD,0,1,def)
end

function s.atkval(e,c)
    return c:GetFlagEffectLabel(id)
end

function s.defval(e,c)
    return c:GetFlagEffectLabel(id+1)
end

---------------------------------------------------------------------------------
-- IMMUNITY FILTER
---------------------------------------------------------------------------------
function s.immfilter(e,te)
    return te:GetOwner()~=e:GetHandler()
end

---------------------------------------------------------------------------------
-- EFFECT 1: DAMAGE ON DESTRUCTION
---------------------------------------------------------------------------------
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    if not re then return false end
    local rc=re:GetHandler()
    return rc==e:GetHandler() and eg:IsExists(Card.IsControler,1,nil,1-tp)
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetTargetPlayer(1-tp)
    Duel.SetTargetParam(1000)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    Duel.Damage(p,d,REASON_EFFECT)
end

---------------------------------------------------------------------------------
-- EFFECT 2: TRIPLE NEGATE & DESTROY
---------------------------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local rc=re:GetHandler()
        if rc:IsRelateToEffect(re) then
            Duel.Destroy(rc,REASON_EFFECT)
        end
    end
end
