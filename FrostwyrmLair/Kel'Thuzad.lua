local mod	= DBM:NewMod("Kel'Thuzad", "DBM-Naxx", 5)
local L		= mod:GetLocalizedStrings()

-----
-- Misc.
-----
local PHASE_ONE_DURATION = 225 -- Phase one lasts for 225 seconds.
local KELTHUZAD_ID = 15990

-----
-- Spell IDs
-----
local SPELL_CHAINS_OF_KELTHUZAD = 28410 -- Mind Control (or 28408? 28410 is the actual effect)
local SPELL_FROST_BLAST = 27808 -- Frost Blast (Tomb)
local SPELL_FROSTBOLT_VOLLEY = 55807 -- Frostbolt Volley (28479 is used in 10 man)
local SPELL_DETONATE_MANA = 27819 -- Detonate Mana
local SPELL_SHADOW_FISSURE = 27810 -- Shadow Fissure

-----
-- Timers/Bars
-----
local timerChainsOfKelthuzad = mod:NewNextTimer(90, SPELL_CHAINS_OF_KELTHUZAD) -- every 90 seconds
local timerFrostBlast = mod:NewNextTimer(30, SPELL_FROST_BLAST) -- every 30 seconds
local timerFrostboltVolley = mod:NewNextTimer(30, SPELL_FROSTBOLT_VOLLEY) -- every 20 seconds
local timerDetonateMana = mod:NewNextTimer(20, SPELL_DETONATE_MANA) -- every 20 seconds
local timerShadowFissure = mod:NewNextTimer(15, SPELL_SHADOW_FISSURE) -- every 15 seconds

local timerPhaseTwo = mod:NewTimer(PHASE_ONE_DURATION, "PhaseTwoTimer") -- Phase Two starts after PHASE_ONE_DURATION seconds

-----
-- Warnings/Announcements
-----
local warningPhaseTwoBegin = mod:NewPhaseAnnounce(2, 2)
local warningPhaseTwoSoon = mod:NewSpecialWarning("PhaseTwoSoonWarning")
local warningAddsSoon = mod:NewAnnounce("AddsSoonWarning", 2)
local warningChainsTargets = mod:NewTargetAnnounce(SPELL_CHAINS_OF_KELTHUZAD, 2)
local warningFrostBlastTargets = mod:NewTargetAnnounce(SPELL_FROST_BLAST, 2)
local warningDetonateManaTarget = mod:NewTargetAnnounce(SPELL_DETONATE_MANA, 2)
local warningShadowFissureTarget = mod:NewTargetAnnounce(SPELL_SHADOW_FISSURE, 2)
 
mod:SetRevision(("$Revision: 2574 $"):sub(12, -3))
mod:SetCreatureID(KELTHUZAD_ID)
mod:SetMinCombatTime(60)

mod:RegisterCombat("yell", L.Yell)

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_CAST_SUCCESS",
	"UNIT_HEALTH"
)

mod:AddBoolOption("BlastAlarm", true)
mod:AddBoolOption("ShowRange", true)

mod:SetBossHealthInfo(
	KELTHUZAD_ID, L.KelThuzad
)

local warnedAdds = false

function mod:OnCombatStart(delay)
	warnedAdds = false -- reset warnedAdds
	
	warningPhaseTwoBegin:Schedule(PHASE_ONE_DURATION) -- schedule "Phase Two" announcement
	warningPhaseTwoSoon:Schedule(PHASE_ONE_DURATION-10-delay) -- schedule "Phase Two Soon" warning for 10 seconds before Phase Two
	timerPhaseTwo:Start() -- start timer for Phase Two
	
	timerChainsOfKelthuzad:Start(PHASE_ONE_DURATION+100) -- first mind control should be 100 seconds after Phase One ends
	
	if self.Options.ShowRange then
		self:Schedule(PHASE_ONE_DURATION-10, DBM.RangeCheck.Show, DBM.RangeCheck, 11) -- activate an 11 yard range check just before Phase Two begins
	end
end

function mod:OnCombatEnd()
	if self.Options.ShowRange then
		DBM.RangeCheck.Hide()
	end
end

local frostBlastTargets = {}
local chainsTargets = {}
function mod:SPELL_AURA_APPLIED(args)
	-- Chains of Kel'thuzad / Mind Control
	if args:IsSpellID(SPELL_CHAINS_OF_KELTHUZAD) then
		timerChainsOfKelthuzad:Start()
		
		table.insert(chainsTargets, args.destName)
		self:UnscheduleMethod("AnnounceChainsTargets")
		if #chainsTargets >= 3 then
			self:AnnounceChainsTargets()
		else
			self:ScheduleMethod(1.0, "AnnounceChainsTargets")
		end

	-- Frost Blast
	elseif args:IsSpellID(SPELL_FROST_BLAST) then
		timerFrostBlast:Start()
		
		table.insert(frostBlastTargets, args.destName)
		self:UnscheduleMethod("AnnounceBlastTargets")
		self:ScheduleMethod(0.5, "AnnounceBlastTargets")
		if self.Options.BlastAlarm then
			PlaySoundFile("Interface\\Addons\\DBM-Core\\sounds\\alarm1.wav")
		end
		
	-- Frostbolt Volley
	elseif args:IsSpellID(SPELL_FROSTBOLT_VOLLEY) then
		timerFrostboltVolley:Start()
		
	-- Detonate Mana	
	elseif args:IsSpellID(SPELL_DETONATE_MANA) then
		timerDetonateMana:Start()
		
		warningDetonateManaTarget:Show(args.destName)
	end
end

function mod:AnnounceChainsTargets()
	warningChainsTargets:Show(table.concat(chainsTargets, "< >"))
	table.wipe(chainsTargets)
end

function mod:AnnounceBlastTargets()
	warningFrostBlastTargets:Show(table.concat(frostBlastTargets, "< >"))
	table.wipe(frostBlastTargets)
end

function mod:SPELL_CAST_SUCCESS(args)
	-- Shadow Fissure
	if args:IsSpellID(SPELL_SHADOW_FISSURE) then
		timerShadowFissure:Start()
		
		warningShadowFissureTarget:Show(args.destName)
		
		if (args.destName == UnitName("player")) then
			SendChatMessage("SHADOW FISSURE ON ME", "SAY") -- TODO: localization
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if not warnedAdds and self:GetUnitCreatureId(uId) == KELTHUZAD_ID and UnitHealth(uId) / UnitHealthMax(uId) <= 0.92 then
		warnedAdds = true
		warningAddsSoon:Show()
	end
end
