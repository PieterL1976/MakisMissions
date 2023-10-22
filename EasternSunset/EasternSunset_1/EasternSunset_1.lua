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

-- Instantiate and start a CSAR for the blue side, with template "Downed Pilot" and alias "GeorgianEagle" Mtispiri_FARP
local my_aicsar=AICSAR:New("Luftrettung",coalition.side.BLUE,"Downed Pilot","GeorgianEagle",AIRBASE:FindByName("Mtispiri_FARP"),ZONE:New("MASH"))

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
   
--Setup EWR Site

_SETTINGS:SetA2A_LL_DMS()

RecceSetGroup = SET_GROUP:New():FilterPrefixes( "EWR" ):FilterStart()
HQ = GROUP:FindByName( "EWR_blue" )
CC = COMMANDCENTER:New( HQ, "HQ" )
RecceDetection = DETECTION_AREAS:New( RecceSetGroup, 30000000)
RecceDetection:Start()



--Mission Logic

--"E:\DCS_missions making\EasternSunset_1\1st_2.ogg"
--local soundfile=SOUNDFILE:New("1st_2.ogg", "E:\\DCS_missions making\\EasternSunset_1")

soundfile=SOUNDFILE:New('1st_2.ogg','E:/')
soundfile:SetPlayWithSRS()
msrs=MSRS:New('C:/Drive_D/SRS/DCS-SimpleRadio-Standalone/', 310, radio.modulation.AM)
msrs:SetLabel('Anatoli')
msrs:PlaySoundFile(soundfile)

--UNITS
local G31ST = GROUP:FindByName( "31st" )

local G1ST = GROUP:FindByName( "1st" )
G1ST_Radio = G1ST:GetRadio()

--local GTEST = GROUP:FindByName( "TEST" ) -- unit for testing logic etc

local EWR_Site = GROUP:FindByName( "EWR_blue" )
EWR_Site_Radio = EWR_Site:GetRadio()

local RHelo = GROUP:FindByName( "Red_Helo" )

--ZONES

ZONE1 = ZONE:New( "Fase1 - Welcome to Georgia" )
ZONE2 = ZONE:New( "Fase 2 - linking up" )
ZONE3 = ZONE:New( "Fase 3 - River" )
ZONE4 = ZONE:New( "Fase 4  - Sameba" )
ZONE5 = ZONE:New( "Fase 5 - Nortern end" )
ZONE6 = ZONE:New( "Fase 6 - EWR" )
ZONE7 = ZONE:New( "Fase 7 - Mtispiri" )
ZONE8 = ZONE:New( "Fase 8 - Kutaisi" )
ZONE9 = ZONE:New( "Fase 9 - Kartlis" )
ZONE10 = ZONE:New( "Fase 10 - Kobuleti" )
ZONE11 = ZONE:New( "Fase 11 - Batumi" )

GEORGIANFORMATION = ZONE_UNIT:New("GeorgianFormation",G1ST,300)
GEORGIANFORMATION.relative_to_unit=1
GEORGIANFORMATION.rho=250
GEORGIANFORMATION.theta=135

--GLOBAL VARIABLES
waitcheck = 0

function fnarty()
	-- Creat a new ARTY object from a Paladin group.
	arty=ARTY:New(GROUP:FindByName("Blue_Arty"))

	--Define a rearming group. This is a Transport M818 truck.
	arty:SetRearmingGroup(GROUP:FindByName("Blue_Resupply"))

	--Set the max firing range. A Paladin unit has a range of 20 km.
	arty:SetMaxFiringRange(15)

	--Low priorty (90) target, will be engage last. Target is engaged two times. At each engagement five shots are fired.
	arty:AssignTargetCoord(ZONE:FindByName("Red_Urban"):GetCoordinate(),  90, nil,  5, 2)
	--Medium priorty (nil=50) target, will be engage second. Target is engaged two times. At each engagement ten shots are fired.
	arty:AssignTargetCoord(ZONE:FindByName("Red_Urban-5"):GetCoordinate(), nil, nil, 10, 2)
	arty:SetReportOFF()
	--Start ARTY process.
	arty:Start()
end

--function to move to next WPT
function fnmoveToZone(ZONE)	
	ContinueTimer = TIMER:New(
		function()
			wpt = ZONE:GetVec3(feetToMeters(5000))
			G1ST:ClearTasks()
			G1ST:RouteToVec3(wpt,knotsToMps(340))
		end
	)
	ContinueTimer:Start(7, 20, 1)
end

--function to hold at position
function fnholdPosition()
	trigger.action.outText('Waiting for you to join up',15)
	waitcheck=1  --to be passed as a reference
	waittask=G1ST:TaskOrbitCircle(feetToMeters(5000), knotsToMps(300))
	G1ST:SetTask(waittask)
end


local FsmMissionState = FSM:New() -- #Fsm for mission state

FsmMissionState:SetStartState( "stopped" )

do 
	FsmMissionState:AddTransition( "stopped", "SwitchTo0", "Fase0" )
	FsmMissionState:AddTransition( "Fase0", "SwitchTo1", "Fase1" )
	FsmMissionState:AddTransition( "Fase1", "SwitchTo2", "Fase2" )
	FsmMissionState:AddTransition( "Fase2", "SwitchTo3", "Fase3" )
	FsmMissionState:AddTransition( "Fase3", "SwitchTo4", "Fase4" )
	FsmMissionState:AddTransition( "Fase4", "SwitchTo5", "Fase5" )
	FsmMissionState:AddTransition( "Fase5", "SwitchTo6", "Fase6" )
	FsmMissionState:AddTransition( "Fase6", "SwitchTo7", "Fase7" )
	FsmMissionState:AddTransition( "Fase7", "SwitchTo8", "Fase8" )
	FsmMissionState:AddTransition( "Fase8", "SwitchTo9", "Fase9" )
	FsmMissionState:AddTransition( "Fase9", "SwitchTo10", "Fase10")
	FsmMissionState:AddTransition( "Fase10", "SwitchTo11", "Fase11")
	FsmMissionState:AddTransition( "Fase1", "SwitchToIntercept", "Intercept")
	FsmMissionState:AddTransition( "Fase9", "SwitchToIntercept", "Intercept")
	FsmMissionState:AddTransition( "Fase10", "SwitchToIntercept", "Intercept")
	FsmMissionState:AddTransition( "Fase11", "SwitchToIntercept", "Intercept")
end

-- define a flag & set to 0 to wait for target detection
local StartIntercept = USERFLAG:New( "InterceptStarted" )
StartIntercept:Set(0)


function RecceDetection:OnAfterDetectedItem( From, Event, To, DetectedItem )
  if DetectedItem.IsDetected then
    local Coordinate = DetectedItem.Coordinate -- Core.Point#COORDINATE
    HQ:MessageToAll( Coordinate:ToStringBULLS(coalition.side.BLUE), 60, "Contact bogeys" )
	if StartIntercept:Is( 0 ) then
		StartIntercept:Set(1)
		FsmMissionState:__SwitchToIntercept(1)
	end
  end
end

fnCheckFase=SCHEDULER:New(nil,
	function()
		--self:E( { FsmMissionState:GetState() , G31ST:IsCompletelyInZone(ZONE1)} )
		if (G31ST:IsCompletelyInZone(ZONE1 ) and FsmMissionState:GetState()=="Fase0" ) then
			FsmMissionState:__SwitchTo1(1)
		end
		
		if (G31ST:IsCompletelyInZone(ZONE2) and G31ST:IsPartlyOrCompletelyInZone(GEORGIANFORMATION) and FsmMissionState:GetState()=="Fase1" ) then
			FsmMissionState:__SwitchTo2(1)
		elseif (G1ST:IsCompletelyInZone(ZONE2 ) and (FsmMissionState:GetState()=="Fase1" or FsmMissionState:GetState()=="Fase0") and waitcheck==0) then
				  fnholdPosition()
		end
		
		if (G31ST:IsCompletelyInZone(ZONE3 ) and G31ST:IsPartlyOrCompletelyInZone(GEORGIANFORMATION) and FsmMissionState:GetState()=="Fase2" ) then
				FsmMissionState:__SwitchTo3(1)
		elseif (G1ST:IsCompletelyInZone(ZONE3 ) and (FsmMissionState:GetState()=="Fase2") and waitcheck==0) then
				  fnholdPosition()
		end
		
		if (G31ST:IsCompletelyInZone(ZONE4 ) and G31ST:IsPartlyOrCompletelyInZone(GEORGIANFORMATION) and FsmMissionState:GetState()=="Fase3" ) then
				FsmMissionState:__SwitchTo4(1)
				fnarty()
		elseif (G1ST:IsCompletelyInZone(ZONE4 ) and FsmMissionState:GetState()=="Fase3" ) then
				  fnholdPosition()
		end
		
		if (G31ST:IsCompletelyInZone(ZONE5 ) and G31ST:IsPartlyOrCompletelyInZone(GEORGIANFORMATION) and FsmMissionState:GetState()=="Fase4" ) then
				FsmMissionState:__SwitchTo5(1)
		elseif (G1ST:IsCompletelyInZone(ZONE5 ) and FsmMissionState:GetState()=="Fase4" ) then
				  fnholdPosition()
		end
		
		if (G31ST:IsCompletelyInZone(ZONE6 ) and G31ST:IsPartlyOrCompletelyInZone(GEORGIANFORMATION) and FsmMissionState:GetState()=="Fase5" ) then
				FsmMissionState:__SwitchTo6(1)
		elseif (G1ST:IsCompletelyInZone(ZONE6 ) and FsmMissionState:GetState()=="Fase5" ) then
				  fnholdPosition()
		end
		
		if (G31ST:IsCompletelyInZone(ZONE7 ) and G31ST:IsPartlyOrCompletelyInZone(GEORGIANFORMATION) and FsmMissionState:GetState()=="Fase6" ) then
				FsmMissionState:__SwitchTo7(1)
		elseif (G1ST:IsCompletelyInZone(ZONE7 ) and FsmMissionState:GetState()=="Fase5" ) then
				  fnholdPosition()
		end
		
		if (G31ST:IsCompletelyInZone(ZONE8 ) and G31ST:IsPartlyOrCompletelyInZone(GEORGIANFORMATION) and FsmMissionState:GetState()=="Fase7" ) then
				FsmMissionState:__SwitchTo8(1)
		elseif (G1ST:IsCompletelyInZone(ZONE8 ) and FsmMissionState:GetState()=="Fase7" ) then
				  fnholdPosition()
		end
		
		if (G31ST:IsCompletelyInZone(ZONE9 ) and G31ST:IsPartlyOrCompletelyInZone(GEORGIANFORMATION) and FsmMissionState:GetState()=="Fase8" ) then
				FsmMissionState:__SwitchTo9(1)
		elseif (G1ST:IsCompletelyInZone(ZONE9 ) and FsmMissionState:GetState()=="Fase8" ) then
				  fnholdPosition()
		end
		
		if (G31ST:IsCompletelyInZone(ZONE10 ) and G31ST:IsPartlyOrCompletelyInZone(GEORGIANFORMATION) and FsmMissionState:GetState()=="Fase9" ) then
				FsmMissionState:__SwitchTo10(1)
		elseif (G1ST:IsCompletelyInZone(ZONE10 ) and FsmMissionState:GetState()=="Fase9" ) then
				  fnholdPosition()
		end
		
		if (G31ST:IsCompletelyInZone(ZONE11 ) and G31ST:IsPartlyOrCompletelyInZone(GEORGIANFORMATION) and FsmMissionState:GetState()=="Fase10" ) then
				FsmMissionState:__SwitchTo11(1)
		elseif (G1ST:IsCompletelyInZone(ZONE11 ) and FsmMissionState:GetState()=="Fase10" ) then
				  fnholdPosition()
		end
	end,
{},1,3)

function FsmMissionState:OnAfterSwitchTo0( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('October 13, 2008 \nCaucasus \nOperation Eastern Sunset \nDutch 31 Sqn',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//Texaco_1.mp3",'251.00','AM','0.7','Texaco',2,GROUP:FindByName('Texaco'):GetRandomVec3())


end

function FsmMissionState:OnAfterSwitchTo1( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('Welcome to Georgia!',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//Magic_12.mp3",'310.00','AM','0.7','Magic',2,GROUP:FindByName('EWR_blue'):GetRandomVec3())

end

function FsmMissionState:OnAfterSwitchTo2( From, Event, To )
	self:E( { From, Event, To} )
	trigger.action.outText('Lets go',15)
	STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//1st_2.mp3",'127.00','AM','0.7','1st',2,GROUP:FindByName('1st'):GetRandomVec3())
	waitcheck=0
  	
	fnmoveToZone(ZONE3)


end

function FsmMissionState:OnAfterSwitchTo3( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('We\'ll be turning east along the Enguri river. Our forces have stopped the abchazi on the river, so it now form the FLOT. We still hold some bridgeheads from which we\'re planning a counter offensive soon',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//1st_3.mp3",'127.00','AM','0.7','1st',2,GROUP:FindByName('1st'):GetRandomVec3())
	waitcheck=0
  	
	fnmoveToZone(ZONE4)

end

function FsmMissionState:OnAfterSwitchTo4( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('To our left is FOB Sambeda, our main base supporting the Enguri line. You\'ll be working with ground units based in this camp.',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//1st_4.mp3",'127.00','AM','0.7','1st',2,GROUP:FindByName('1st'):GetRandomVec3())
  waitcheck=0
		
	fnmoveToZone(ZONE5)
end

function FsmMissionState:OnAfterSwitchTo5( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('the FLOT runs all the way up here to the Enguri dam and the Caucasus mountains. From here the terrain gets rough quickly, allowing guerilla operations only',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//1st_5.mp3",'127.00','AM','0.7','1st',2,GROUP:FindByName('1st'):GetRandomVec3())
	waitcheck=0
  	
	fnmoveToZone(ZONE6)

end

function FsmMissionState:OnAfterSwitchTo6( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('We\'re passing the Mtispiri EWR site, our air control centre. It has a blind spot to the north, but can\'t place these valuable assets closer to the russian border',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//1st_6.mp3",'127.00','AM','0.7','1st',2,GROUP:FindByName('1st'):GetRandomVec3())
  	local CommandNext = G1ST:CommandSwitchWayPoint( 7, 8 )
	waitcheck=0
  	
	fnmoveToZone(ZONE7)

end

function FsmMissionState:OnAfterSwitchTo7( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('FOB Mtispiri, our recon base supporting the EWR site, monitoring enemy activity in the area and supporting orur light troops in the mountains. It also hosts the Greek Apache detachment providing CAS to all our ground operations',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//1st_7.mp3",'127.00','AM','0.7','1st',2,GROUP:FindByName('1st'):GetRandomVec3())
  	local CommandNext = G1ST:CommandSwitchWayPoint( 8, 9 )
	waitcheck=0
  	
	fnmoveToZone(ZONE8)

end

function FsmMissionState:OnAfterSwitchTo8( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('Kutaisi AFB is closed, as well as Senaki AFB, as we can not guarantee safe operations between the Enguri and Rioni rivers',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//1st_8.mp3",'127.00','AM','0.7','1st',2,GROUP:FindByName('1st'):GetRandomVec3())
	waitcheck=0
  	
	fnmoveToZone(ZONE9)	

end

function FsmMissionState:OnAfterSwitchTo9( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('FAB Kartlis is the logistics hub for this area, providing ammunition, supplies and transport. It also houses the main field hospital. Lets hope none of you have to pay a visit there',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//1st_9.mp3",'127.00','AM','0.7','1st',2,GROUP:FindByName('1st'):GetRandomVec3())
	waitcheck=0
  	
	fnmoveToZone(ZONE10)
	
	Spawn_Helo = SPAWN:New( "Red_Helo")
		  :InitLimit( 2, 1)
		  :InitRandomizePosition(true, 2500, 500)
		  :SpawnScheduled(25, 0.5,true )
end
function FsmMissionState:OnAfterSwitchTo10( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('AFB Kobuleti, my home base. My squadron of SU-25 aircraft operates from here, supporting our operations along the Enguri river. It also hase some supplies, should you need rearming',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//1st_10.mp3",'127.00','AM','0.7','1st',2,GROUP:FindByName('1st'):GetRandomVec3())
	waitcheck=0
  	
	fnmoveToZone(ZONE11)

end

function FsmMissionState:OnAfterSwitchTo11( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('We\'ve reached the eastern entry point of Batumi AFB, you base for the time being. I\'ll let you settle in, we\'ll meet again soon, We can\'t thank you enough for the much needed support.',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//1st_11.mp3",'127.00','AM','0.7','1st',2,GROUP:FindByName('1st'):GetRandomVec3())

end

function FsmMissionState:OnAfterSwitchToIntercept( From, Event, To )
  self:E( { From, Event, To} )
  trigger.action.outText('Enemy helicopters detected, commit',15)
  STTS.PlayMP3("E://DCS_missions making//EasternSunset_1//Magic_13.mp3",'310.00','AM','0.7','Magic',2,GROUP:FindByName('EWR_blue'):GetRandomVec3())
  G1ST:OptionROTNoReaction() -- set the SU-25 not to react to threats
  fnCheckHeloAlive=SCHEDULER:New(nil,
	function()
		if (RHelo:GetLife()<1 and FsmMissionState:GetState()=="Intercept" ) then
			if From =="Fase9" then
				FsmMissionState:__SwitchTo9(1)
			elseif From =="Fase10" then
				FsmMissionState:__SwitchTo10(1)
			elseif From =="Fase11" then
				FsmMissionState:__SwitchTo11(1)
			else
				FsmMissionState:__SwitchTo11(1)
			end
			fnCheckHeloAlive:Stop()
		end
	end,
	{},1,3)

end
	
	--fnMissionFlow = SCHEDULER:New(nil,
	--function()
		--ZONE1:DrawZone(-1, {1,0,0}, 0.5, {1,0,0}, 0.15, 1)
	--end,
	--{},1,5)

FsmMissionState:__SwitchTo0(2)







