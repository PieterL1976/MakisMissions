--
-- Function to convert feet to meters
function feetToMeters(feet)
    local meters = feet * 0.3048
    return meters
end

-- Function to convert meters per second to knots
function knotsToMps(kts)
    local mps = kts / 1.94384
    return mps
end

--Setup parameters for Text-to-Speech
STTS.DIRECTORY='C:/Drive_D/SRS/DCS-SimpleRadio-Standalone/'
--STTS.GOOGLE_CREDENTIALS="E:/DCS_missions making/dcs-stts-410bff83c38f.json"

 --ATIS for UG5X - Kobuleti
 atisUG5X=ATIS:New("Kobuleti", 123.00)
 atisUG5X:SetRadioRelayUnitName("RadioKobuleti")
 atisUG5X:SetTowerFrequencies({262, 133, 40.8, 4.35})
 atisUG5X:SetTACAN(67)
 atisUG5X:SetMapMarks()
 atisUG5X:__Start(math.random(5,20))


--ATIS for UGSB - Batumi
atisUGSB=ATIS:New("Batumi", 122.8)
atisUGSB:SetRadioRelayUnitName("RadioBatumi")
atisUGSB:SetTowerFrequencies({260, 131, 40.4, 4.25})
atisUGSB:SetTACAN(16)
atisUGSB:AddILS( 108.75 , "31")
atisUGSB:SetMapMarks()
atisUGSB:__Start(math.random(5,20))

--Random SHORADS
RedAdaZoneSet = SET_ZONE:New()
	:FilterPrefixes("Red_Urban")
	:FilterOnce()
RedAdaZoneTable = RedAdaZoneSet:GetSetObjects()

RedAdaGroupSet = SET_GROUP:New()
	:FilterPrefixes("Red_Ada")
	:FilterOnce()
RedAdaGroupTable = RedAdaGroupSet:GetSetNames()


--for k,v in pairs(RedAdaGroupTable) do
--    trigger.action.outText(tostring(v),15)
--end

Spawn_Infantry = SPAWN:New( "Red_Ada_1")
  :InitLimit( 28, 20 )
  :InitRandomizeZones( RedAdaZoneTable )
  :InitRandomizeTemplate( RedAdaGroupTable ) 
  :SpawnScheduled( .5, .5 )
   

--Mission Logic
--UNITS
local G31ST = GROUP:FindByName( "31st" )

FARPSET=SET_STATIC:New()
	:FilterPrefixes("RED FARP")
	:FilterStart()

HeloTemplateTable = { "RED_HELO_2_SHIP_1"}--,"RED_HELO_2_SHIP_2" }
FighterTemplateTable = { "RED_MIG21","RED_MIRAGE" }

--ZONES
RED_MIG_SPAWN = ZONE:FindByName( "RED_MIG_SPAWN" )
--RUSSIANFORMATIONCLOSE = ZONE:New( "RussianFormation" )
--RUSSIANFORMATIONTRAIL = ZONE:New( "RussianFormation" )
HELOCAS = ZONE:FindByName( "HeloCAS" )
RED_CAP = ZONE:FindByName("RED_CAP")



--GLOBAL VARIABLES
HeloSpawned = 0
HeloDead = 1
RussianMigSpawned = 0
AbchazMigSpawned = 0
AbchazMigDead = 1
FARPDestroyed = 0
Debug = 0

--Missions

missionHelo = AUFTRAG:NewCAS(HELOCAS, 2000, 180) --rest not specified, Coordinate, Heading, Leg, TargetTypes
missionCAP = AUFTRAG:NewCAP(RED_CAP, 25000, 350,RED_CAP:GetCoordinate(), 45, 10)

-------------------------------------------------------------------------------------------------------------------------------------
---BLUE------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------
--UNITS


--ZONES
BLUE_TANKER = ZONE:FindByName("Zone Boom"):DrawZone()

--Missions


--GLOBAL VARIABLES

--Setting up BLUE Forces

---
-- Squadrons
---

-- KC-135 squadron, callsign "Arco".
ARS18=SQUADRON:New("Tanker_template", 5, "18th Air Refueling Squadron") --Ops.Squadron#SQUADRON
ARS18:SetModex(100)
ARS18:SetCallsign(CALLSIGN.Tanker.Texaco)
ARS18:SetRadio(270)
ARS18:SetSkill(AI.Skill.EXCELLENT)
ARS18:AddMissionCapability({AUFTRAG.Type.TANKER}, 100)
ARS18:AddTacanChannel(70, 75)

---  
-- Airwing
---

-- Create an airwing.
ARW931=AIRWING:New("Warehouse Batumi2", "931th Air Refueling Wing") --Ops.AirWing#AIRWING
---
-- Patrol Points
---

-- Set number of tankers constantly in the air.
--ARW931:SetNumberTankerBoom(1)
---
-- Squadrons
---

-- Add squadrons to airwing.
ARW931:AddSquadron(ARS18)
---
-- Start Airwing
---

-- Start airwing.
ARW931:Start()

-- Function to create a new tanker mission.
function NewTankerMission(RefuelSystem)

  -- Get coordinate depending on refuel system type.
  Coordinate=BLUE_TANKER:GetCoordinate()

  -- Tanker mission.
  mission=AUFTRAG:NewTANKER(Coordinate, 20000, 300, 090, 25, RefuelSystem)
  
  -- Assign mission to airwing.
  ARW931:AddMission(mission)
  
end

-- Create a tanker mission with boom.
NewTankerMission(Unit.RefuelingSystem.BOOM_AND_RECEPTACLE)

--- Function called each time a flight group goes on a mission. Can be used to fine tune.
function ARW931:OnAfterFlightOnMission(From, Event, To, Flightgroup, Mission)
  flightgroup=Flightgroup --Ops.FlightGroup#FLIGHTGROUP
  mission=Mission --Ops.Auftrag#AUFTRAG
  
  -- Get info about TACAN channel.
  tacanChannel, tacanMorse, tacanBand=flightgroup:GetTACAN()
  
  -- Print some info.
  text=string.format("Flight %s on %s mission %s. TACAN Channel %s%s (%s)", flightgroup:GetName(), mission:GetType(), mission:GetName(), tostring(tacanChannel), tostring(tacanBand), tostring(tacanMorse))
  MESSAGE:New(text):ToAll():ToLog()  
  
  -- For demo purposes, we set the low fuel threshold to 90%. When the tanker is low on fuel, it will RTB and a new tanker is spawned.
  flightgroup:SetFuelLowThreshold(90)
end
-------------------------------------------------------------------------------------------------------------------------------------
---RED-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--Setting up RED AIR DEFENSE
---
-- Define Squadron(s)
---

-- Squadron of 4 MIG21 two ships (10 airframes in total).
FSR1=SQUADRON:New("RED_MIG21-1", 5, "1st red squadron") --Ops.Squadron#SQUADRON1
FSR1:SetGrouping(2)                      -- Two-ships. Good to have a wingmen.
FSR1:SetModex(100)                       -- Onboard numbers are 100, 101, ...
FSR1:SetCallsign(CALLSIGN.Aircraft.Ford) -- Call sign is Ford.
FSR1:SetRadio(260)                       -- Squadon communicates on 260 MHz AM.
FSR1:SetSkill(AI.Skill.EXCELLENT)        -- These guy are really good.
FSR1:AddMissionCapability({AUFTRAG.Type.ORBIT, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.CAP, AUFTRAG.Type.ESCORT}, 90) --Highly specialized in A2A.
--FS13:AddMissionCapability({AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING, AUFTRAG.Type.BOMBRUNWAY}, 80)                   --Also very good at A2G.

--Squadron of MI-24 (4 airframes in total)

RSR2 = SQUADRON:New("RED_MI24",4,"2nd Red Rotary Squadron")
					:SetGrouping(2)
					:SetModex(200) 
					:SetRadio(260)  
					:SetSkill(AI.Skill.EXCELLENT)
					:AddMissionCapability({AUFTRAG.Type.CAS})
--Squadron of KA-50 III (4 airframes in total)
RSR3 = SQUADRON:New("RED_KA50",4,"3nd Red Rotary Squadron")
					:SetGrouping(2)
					:SetModex(300) 
					:SetRadio(261)  
					:SetSkill(AI.Skill.EXCELLENT)
					:AddMissionCapability({AUFTRAG.Type.CAS})					
--FSR1:SetCallsign(CALLSIGN.Aircraft.Ford)



---  
-- Define Airwings
---

-- Create an airwing.
FWR1=AIRWING:New("Warehouse Gudauta", "1st RED Fighter Wing") --Ops.AirWing#AIRWING
RWR2=AIRWING:New("RED_FARP_WAREHOUSE", "2st RED Rotary Wing") --Ops.AirWing#AIRWING

-- Add squadron(s) to airwings.
FWR1:AddSquadron(FSR1)
RWR2:AddSquadron(RSR2)
RWR2:AddSquadron(RSR3)

---
-- Airwing Payloads
---

-- Add 4 payloads of AIM-120s used for Intercep, CAP and escort missions. Performance is set to 80, i.e. considered a good loadout for these mission types.
FWR1:NewPayload("MIG21_PATROL", 4, {AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.CAP, AUFTRAG.Type.ESCORT}, 80)
RWR2:NewPayload("RED_MI24_CAS", 4 ,{AUFTRAG.Type.CAS},90)
RWR2:NewPayload("RED_KA50_CAS", 4 ,{AUFTRAG.Type.CAS},90)

---
-- Start Airwing
---

-- Start airwing.
FWR1:Start()
RWR2:Start()

-------------------------------------------------------------------------------------------------------------------------------------
---MISSION---------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local FsmMissionState = FSM:New() -- #Fsm for mission state

FsmMissionState:SetStartState( "stopped" )

--fases
-- fase 0 - hunting for helos - search for base
-- fase1a - intercept russian aircraft
-- fase1b - intercept enemy fighters from east
-- fase2 - base detected - attack
-- fase 3 - destroy abchasi fighters out of Gudauta
-- fase 4 - RTB

do 
	FsmMissionState:AddTransition( "stopped", "SwitchTo0", "Fase0" )
	FsmMissionState:AddTransition( "Fase0", "SwitchTo1a", "Fase1a" )
	FsmMissionState:AddTransition( "Fase0", "SwitchTo1b", "Fase1b" )
	FsmMissionState:AddTransition( "Fase1a", "SwitchTo0", "Fase0" )
	FsmMissionState:AddTransition( "Fase1b", "SwitchTo0", "Fase0" )
	FsmMissionState:AddTransition( "Fase0", "SwitchTo2", "Fase2" )
	FsmMissionState:AddTransition( "Fase0", "SwitchTo3", "Fase3" )
	FsmMissionState:AddTransition( "Fase1a", "SwitchTo3", "Fase3" )
	FsmMissionState:AddTransition( "Fase1b", "SwitchTo3", "Fase3" )
	FsmMissionState:AddTransition( "Fase2", "SwitchTo3", "Fase3" )
	FsmMissionState:AddTransition( "Fase3", "SwitchTo4", "Fase4" )
end



---
-- FSM Events
---

--- Function called each time a flight of the airwing goes on a mission.
function FWR1:OnAfterFlightOnMission(From, Event, To, FlightGroup, Mission)
  local flightgroup=FlightGroup --Ops.FlightGroup#FLIGHTGROUP
  local mission=Mission         --Ops.Auftrag#AUFTRAG
  
  -- Info message.
  --local text=string.format("Flight group %s on %s mission %s", flightgroup:GetName(), mission:GetType(), mission:GetName())
  env.info(text)
  --MESSAGE:New(text, 300):ToAll()
end
  
--mission flow controller
fnCheckFase=SCHEDULER:New(nil,
	function()
		fnCheckFase:E( { "Loop", HeloSpawned,HeloDead,RussianMigSpawned,AbchazMigSpawned,AbchazMigDead,FARPDestroyed,Debug,FARPSET:CountAlive() } )

		if (FsmMissionState:GetState()=="stopped" ) then
			FsmMissionState:__SwitchTo0(1)
		end
		
		if (FsmMissionState:GetState()=="Fase0" and HeloSpawned == 1 and HeloDead == 1 ) then --helos are destroyed
			HeloSpawned=0
	
			if RussianMigSpawned == 0 then
				FsmMissionState:__SwitchTo1a(1)
			elseif AbchazMigSpawned == 0 then
				FsmMissionState:__SwitchTo1b(1)
			elseif FARPDestroyed == 0 then 
				FsmMissionState:__SwitchTo2(1)
			end
		end
		
		if ( RussianMigSpawned == 1 and FsmMissionState:GetState()=="Fase1a" ) then
			if(G31ST:IsPartlyOrCompletelyInZone(RUSSIANFORMATIONCLOSE) or G31ST:IsPartlyOrCompletelyInZone(RUSSIANFORMATIONTRAIL)) then
				trigger.action.outText('Looks like he\'s bugging out, return to CAP station',15)
				RUSSIANMIG:RouteRTB(AIRBASE.Caucasus.Maykop_Khanskaya) --send the ruski home
				FsmMissionState:__SwitchTo0(1)
			end
		end
		
		if (FsmMissionState:GetState()=="Fase1b" and AbchazMigSpawned == 1 and AbchazMigDead == 1 ) then --Abchaz Migs are destroyed
			FsmMissionState:__SwitchTo0(1)
		end
		
		if (FARPSET:CountAlive() < 3) then --FARP is destroyed, main mission accomplished
			FARPDestroyed = 1
			FsmMissionState:__SwitchTo3(1)
		end
		
		if (FsmMissionState:GetState()=="Fase3") then --Gudauta Migs are destroyed
			FsmMissionState:__SwitchTo4(1)
		end
		
		if Debug == 1 then
			FsmMissionState:__SwitchTo1a(1)
			Debug = 0
		end
		
	end,
{},1,45)

--mission state changes
function FsmMissionState:OnAfterSwitchTo0( From, Event, To )
  self:E( { From, Event, To} )
  
	HeloSpawnTimer = TIMER:New(
		function()
		  
		  --set flags to handle mission flow
			HeloSpawned=1		
			HeloDead = 0
		   
		  RWR2:AddMission(missionHelo)
		end
	)

	HeloSpawnTimer:Start(math.random(30,45))

end

function FsmMissionState:OnAfterSwitchTo1a( From, Event, To )
  self:E( { From, Event, To} )
  	
	RussianMigSpawnTimer = TIMER:New(
		function()
		  Spawn_RussianMig = SPAWN:New( "RussianMig")
			:InitRandomizePosition(true, 2500, 500)	

			RUSSIANMIG = Spawn_RussianMig:Spawn()
			RUSSIANFORMATIONCLOSE = ZONE_UNIT:New("RussianFormation",RUSSIANMIG,150 ,{rho=250, theta=1.5708, relative_to_unit = true}) --90 degrees in radials
			RUSSIANFORMATIONTRAIL = ZONE_UNIT:New("RussianFormation",RUSSIANMIG,500, {rho=250, theta=3.1415, relative_to_unit = true})
			RussianMigSpawned=1
			trigger.action.outText('Wolf1, Magic, Bogey heading for the Georgian border, investigate',15)

		end
	)
	RussianMigSpawnTimer:Start(math.random(30,45))
end

function FsmMissionState:OnAfterSwitchTo1b( From, Event, To )
  self:E( { From, Event, To} )
  	
	AbchazMigSpawnTimer = TIMER:New(
		function()
		  Spawn_AbchazMig = SPAWN:New( "RussianMig")
			--:InitLimit( 2, 1)
			:InitRandomizeTemplate( FighterTemplateTable ) 
			--:InitRandomizePosition(true, 2500, 500)	
			:SpawnInZone(RED_MIG_SPAWN)
			
			AbchazMigDead = 0
			AbchazMigSpawned=1
			
		  local MIGGroup=FLIGHTGROUP:New(Spawn_AbchazMig)
		  MIGGroup:AddMission(missionCAP)
		  
		  function MIGGroup:OnAfterSpawned(From, Event, To )
			 trigger.action.outText('Wolf1, Magic, Bogeys inbound, investigate',15)
		  end
		
		  function MIGGroup:OnAfterDead(From, Event, To )
				AbchazMigDead = 1
				trigger.action.outText('Wolf1, Magic, good kills, clear, continue mission',15)
		  end
		  
		end
	)
	AbchazMigSpawnTimer:Start(math.random(30,45))
end

function FsmMissionState:OnAfterSwitchTo2( From, Event, To )
  self:E( { From, Event, To} )

	trigger.action.outText('Red FARP detected at GH 14 37, take it out',15)
end

function FsmMissionState:OnAfterSwitchTo3( From, Event, To )
  self:E( { From, Event, To} )

  FWR1:AddMission(missionCAP)
  
end

function missionHelo:OnAfterStarted(From, Event, To)
	self:E( { From, Event, To} )
	trigger.action.outText('Alert, enemy helicopters detected',15)
end

function missionHelo:OnAfterExecuting(From, Event, To)
	self:E( { From, Event, To} )
	trigger.action.outText('Alert, Blue units under attack!',15)
end

function missionHelo:OnAfterFailed(From, Event, To)
	self:E( { From, Event, To} )
	HeloDead = 1
	trigger.action.outText('Good job, all helo\'s eliminated',15)
end

function MissionStatus()

  local text="Blue Missions:"
  for _,_mission in pairs(ARW931.missionqueue) do
    local m=_mission --Ops.Auftrag#AUFTRAG
    text=text..string.format("\n- %s %s %s*%d/%d [%d %%]  (%s*%d/%d)", 
    m:GetName(), m:GetState():upper(), m:GetTargetName(), m:CountMissionTargets(), m:GetTargetInitialNumber(), m:GetTargetDamage(), m:GetType(), m:CountOpsGroups(), m:GetNumberOfRequiredAssets())
  end
  
  text=text.."\nRed Missions:"
  for _,_mission in pairs(FWR1.missionqueue) do
    local m=_mission --Ops.Auftrag#AUFTRAG
    text=text..string.format("\n- %s %s %s*%d/%d [%d %%]  (%s*%d/%d)", 
    m:GetName(), m:GetState():upper(), m:GetTargetName(), m:CountMissionTargets(), m:GetTargetInitialNumber(), m:GetTargetDamage(), m:GetType(), m:CountOpsGroups(), m:GetNumberOfRequiredAssets())
  end
  for _,_mission in pairs(RWR2.missionqueue) do
    local m=_mission --Ops.Auftrag#AUFTRAG
    text=text..string.format("\n- %s %s %s*%d/%d [%d %%]  (%s*%d/%d)", 
    m:GetName(), m:GetState():upper(), m:GetTargetName(), m:CountMissionTargets(), m:GetTargetInitialNumber(), m:GetTargetDamage(), m:GetType(), m:CountOpsGroups(), m:GetNumberOfRequiredAssets())
  end
  
  -- Info message to all.
  MESSAGE:New(text, 25):ToAll()
end

-- Display primary and secondary mission status every 60 seconds.
TIMER:New(MissionStatus):Start(5, 30)












