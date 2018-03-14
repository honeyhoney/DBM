local mod	= DBM:NewMod("Gluth", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2869 $"):sub(12, -3))
mod:SetCreatureID(15932)

mod:RegisterCombat("combat")

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_DAMAGE"
--	"SPELL_CAST_SUCCESS"
)


local warnDecimateSoon	= mod:NewSoonAnnounce(54426, 2)
local warnDecimateNow	= mod:NewSpellAnnounce(54426, 3)

local enrageTimer		= mod:NewBerserkTimer(420)
local timerDecimate		= mod:NewCDTimer(105, 54426)

local decimateCounter

function mod:OnCombatStart(delay)
	decimateCounter = 0
	enrageTimer:Start(420 - delay)
	timerDecimate:Start(105 - delay)
	warnDecimateSoon:Schedule(95 - delay)
end

--function mod:SPELL_CAST_SUCCESS(args)
--	if args:IsSpellID(54426)
--		decimateCounter = decimateCounter + 1
--	end
--end

local decimateSpam = 0
function mod:SPELL_DAMAGE(args)
	if args:IsSpellID(28375) and (GetTime() - decimateSpam) > 20 then
		decimateSpam = GetTime()
		warnDecimateNow:Show()
		timerDecimate:Start()
		warnDecimateSoon:Schedule(96)
	end
end


