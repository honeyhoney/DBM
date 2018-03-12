local mod	= DBM:NewMod("Maexxna", "DBM-Naxx", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2943 $"):sub(12, -3))
mod:SetCreatureID(15952)

mod:RegisterCombat("combat")

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_CAST_SUCCESS"
)

local warnWebWrap		= mod:NewTargetAnnounce(28622, 2)
local warnWebSpraySoon	= mod:NewSoonAnnounce(29484, 1)
local warnWebSprayNow	= mod:NewSpellAnnounce(29484, 3)
local warnSpidersSoon	= mod:NewAnnounce("WarningSpidersSoon", 2, 17332)
local warnSpidersNow	= mod:NewAnnounce("WarningSpidersNow", 4, 17332)

local timerWebWrap		= mod:NewNextTimer(25, 28622)
local timerWebSpray		= mod:NewNextTimer(30, 29484)
local timerSpider		= mod:NewTimer(40, "TimerSpider", 17332)

function mod:OnCombatStart(delay)
	warnWebSpraySoon:Schedule(35.5 - delay)
	timerWebSpray:Start(40.5 - delay)
	warnSpidersSoon:Schedule(25 - delay)
	warnSpidersNow:Schedule(30 - delay)
	timerSpider:Start(30 - delay)
	timerWebWrap:Start(20 - delay)
end

function mod:OnCombatEnd(wipe)
	if not wipe then
		if DBM.Bars:GetBar(L.ArachnophobiaTimer) then
			DBM.Bars:CancelBar(L.ArachnophobiaTimer) 
		end	
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(28622) then -- Web Wrap
		warnWebWrap:Show(args.destName)
		if args.destName == UnitName("player") then
			SendChatMessage(L.YellWebWrap, "YELL")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(29484, 28622) then -- Web Spray
		warnWebSprayNow:Show()
		warnWebSpraySoon:Schedule(25)
		timerWebSpray:Start()
		warnSpidersSoon:Schedule(25)
		warnSpidersNow:Schedule(30)
		timerSpider:Start()
    elseif args:IsSpellID(54125) then
		timerWebWrap:Start()
	end
end
