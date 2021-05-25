#include <sourcemod>
#include <sdktools>
//rc sm plugins unload bg3_amongus
#pragma semicolon 1

#define PLUGIN_VERSION "0.1"

//constantss
#define SPEC_TEAM 1
#define AMER_TEAM 2
#define BRIT_TEAM 3

#define SIZE_OF_INT 2147483647 

const ButtonNum = 61; 
const TriggerNum = 10;

new g_offsCollisionGroup = -1;

//game sound paths
new String:soundNames[3][80] = 
{
	"among_us/kill.wav",
	"among_us/vent_in.wav",
	"among_us/vent_out.wav"
};

new String:scoreboard[2][80] = 
{
	"materials/VGUI/scoreboard/maps/bg_amongus_b4.vmt",
	"materials/VGUI/scoreboard/maps/bg_amongus_b4.vtf"
};


//State booleans
ExecutionTime = false;
MeetingTime = false;

//taskID constants seriously, its either this or I use raw numbers in code. Maybe a diff file would work too but fakk it
const ClearAsteroids = 0;
const CleanO2Filter = 1;
const ChartCourse = 2;
const StabiliseSteering = 3;
const SwipeCard = 4;
const PrimeShields = 5;
const CalibrateDistributor = 6;
const AlignUpperEngine = 7;
const AlignLowerEngine = 8;
const StartReactor = 9;
const UnlockManifolds = 10;
const SubmitScan = 11;
const InspectSample = 12;
const EmptyGarbage = 13;
const EmptyChute = 14;
const FuelUpperEngine = 15;
const FuelLowerEngine = 16;
const DownloadData = 17;
const DiverPower = 18;
const FixWiring = 19;
const EmptyGarbageFirst = 20;
const EmptyChuteFirst = 21;
const EmptyAirlockSecond = 22;
const FuelUpperEngineFirst = 23;
const FuelUpperEngineSecond = 24;
const FuelLowerEngineFirst = 25;
const FuelLowerEngineSecond = 26;
const DownloadDataCafeteria = 27;
const DownloadDataWeapons = 28;
const DownloadDataNavigation = 29;
const DownloadDataCommunications = 30;
const DownloadDataElectric = 31;
const UploadDataAdmin = 32;
const DivertPowerSecurityFirst = 33;
const DivertPowerWeaponsFirst = 34;
const DivertPowerO2First = 35;
const DivertPowerNavigationFirst = 36;
const DivertPowerShieldsFirst = 37;
const DivertPowerCommunicationsFirst = 38;
const DivertPowerLowerEngineFirst = 39;
const DivertPowerUpperEngineFirst = 40;
const DivertPowerSecuritySecond = 41;
const DivertPowerWeaponsSecond = 42;
const DivertPowerO2Second = 43;
const DivertPowerNavigationSecond= 44;
const DivertPowerShieldsSecond= 45;
const DivertPowerCommunicationsSecond = 46;
const DivertPowerLowerEngineSecond = 47;
const DivertPowerUpperEngineSecond = 48;
const FixWiringCafeteria = 49;
const FixWiringNavigation = 50;
const FixWiringAdmin = 51;
const FixWiringStorage = 52;
const FixWiringElectric = 53;
const FixWiringSecurity = 54;
const InspectSampleFirst = 55;
const InspectSampleSecond = 56;

const GAME_NUMBER_OF_TASKS = 5;

//default cooldown times
const DEFAULT_KILL_COOLDOWN = 25;
const START_KILL_COOLDOWN = 15;
const DEFAULT_SABOTAGE_COOLDOWN = 30;
const DEFAULT_DOOR_COOLDOWN = 25;

//default sabotage times
const DEFAULT_DOOR_SABOTAGE = 10;
const DEFAULT_OXYGEN_DEPLETED = 30;
const DEFAULT_REACTOR_MELTDOWN = 30;

//default emergency button cooldown time
const DEFAULT_EMERGENCY_BUTTON_COOLDOWN = 35;
const START_EMERGENCY_BUTTON_COOLDOWN = 35;


int NumberOfImpostors;

//voting vars
int TotalVotes[MAXPLAYERS+1];
int ExecutionVotes[3];
int SoonToBeDeceased = 0;

//voting timers
Handle VotingTimer = INVALID_HANDLE;
Handle DiscussionTimer = INVALID_HANDLE;

//total number of tasks left, to keep track of progress bar > float to make division easier
float TotalNumberOfTasks = 0.0;
float NumberOfTasksLeft = 0.0;

char Colours[12][11]; //number of colours, max length

//arrays for player flags 
//assuming there will be max 64 players, just use MAXPLAYERS+1
bool Crewmate[MAXPLAYERS+1];
bool CrewmateGhost[MAXPLAYERS+1];
bool Impostor[MAXPLAYERS+1];
bool ImpostorGhost[MAXPLAYERS+1];
bool Execution[MAXPLAYERS+1];

Handle KillCooldownTimers[MAXPLAYERS+1];

//for checking if impostor can kill again
bool KillCooldown[MAXPLAYERS+1];
//kill cooldown seconds left
int KillCooldownLeft[MAXPLAYERS+1];
Handle UpdateKillCooldownTimer[MAXPLAYERS+1];
//for checking if major sabotage is available


//all sabotages have a cooldown of 30 secs AFTER they are resolved. - all major sabos get that cooldown
//Sabotages are resolved by reporting a body, EXCEPT Comms and Lights
//All sabotages (except doors) deny use of emergency button
//Comms disables security cameras

//a door sabotage disables other sabotages, other than door
//any other sabotages disables all other sabotages, putting doors on cooldown instead, but still disabled...

bool DoorSabotageActive = false; //bool true if ANY door is active
bool DoorSabotageCooldown[7]; //bool tells if the door is on cooldown
bool DoorSabotage[7]; //bool tells wether it is currently sabotaged
Handle DoorSabotageTimers[7]; 
Handle DoorSabotageCooldownTimers[7]; 

bool SabotageActive = false;
bool SabotageCooldown = false;
//sabotage cooldown seconds left
int SabotageCooldownLeft = false;
Handle SabotageCooldownTimer = INVALID_HANDLE;
Handle SabotageCooldownUpdateTimer = INVALID_HANDLE;
//Sabotage Timers
Handle OxygenSabotageTimer = INVALID_HANDLE;
Handle ReactorSabotageTimer = INVALID_HANDLE;

//Sabotage vars
int OxygenTimeLeft = 0;
int ReactorTimeLeft = 0;

//true if O2 or Reactor sabotage is active -- RESET AFTER MEETING
bool OxygenSabotageActive = false;
bool ReactorSabotageActive = false;
//true if Lights or Comms sabotage is active -- CONTINUE AFTER MEETING
bool LightsSabotageActive = false;
bool CommsSabotageActive = false;

//Reactor button booleans
bool ReactorButton1Pressed = false;
bool ReactorButton2Pressed = false;

//Oxygen sabotage variables
bool OxygenTask1Done = false;
bool OxygenTask2Done = false;

//Comms sabotage vars
int CurrentDegree = 0;
int GoalDegree = 0;
bool PlayersInCommsMenu[MAXPLAYERS + 1]; //used to update all players at same time

int TodaysCode[5];
char TodaysCodeString[20];
int OxygenPlayerProgressO2[MAXPLAYERS + 1];
int OxygenPlayerProgressAdmin[MAXPLAYERS + 1];

//Lights sabotage variables
bool LightSwitches[5]; //represents which are switched on/off
int RandomLightsArr[9] =  { 1, 1, 1, 1, 0, 0, 0, 0, 0 }; //a random int arr of 9, sorted randomly will give above arr random set of bools with AT LEAST 1 false
bool PlayersInLightsMenu[MAXPLAYERS + 1]; //used to update all players at same time

//door sabotage: for 10 seconds, then open. Cooldown is 25 seconds. Other sabotages are disabled for 10 seconds, other doors are not!.

//Emergency button bool
bool EmergencyButtonEnabled = false;
Handle EmergencyButtonTimer = INVALID_HANDLE;


//Crewmate task variables

//Submit Scan
bool CrewmateEnteredScanner = false;
int CrewmateOnScanner = 0;
Handle ScannerTimer = INVALID_HANDLE; 
int ScannerEntID = 0;

//Inspect Sample
int SampleTimeLeft[MAXPLAYERS+1];
Handle SampleTimer[MAXPLAYERS+1];
Handle SampleUpdateTimer[MAXPLAYERS+1];


//Fuel Engines
//0-100 fuel in can for each player
int FuelInCan[MAXPLAYERS+1];
//bool to check if player is touching trigger
bool TouchingCans[MAXPLAYERS+1];
bool TouchingLEng[MAXPLAYERS+1];
bool TouchingUEng[MAXPLAYERS+1];
bool Fueling[MAXPLAYERS+1];

//Upload Data
bool TouchingUp[MAXPLAYERS+1];
Handle UploadTimers[MAXPLAYERS+1];
int UploadTimeLeft[MAXPLAYERS+1];

//Prime Shields
int ShieldsStage[MAXPLAYERS + 1][4];

//Clean Filter
bool FilterArray[MAXPLAYERS + 1][20];

//Clean Asteroid Field
bool AsteroidArray[MAXPLAYERS + 1][20];

//Start Reactor
int StartReactorNumbers[4];
int StartReactorPlayerProgress[MAXPLAYERS + 1];
int StartReactorStages[10];

//Unlock Manifolds
int ManifoldsPlayerProgress[MAXPLAYERS + 1];
int NumberArray[8] =  {1,2,3,4,5,6,7,8}; //array to sort randomly later

//Chart Course
char Coordinates1[10];
char Coordinates2[10];
int ChartCourseCoordinates[6];
int ChartCoursePlayerProgress[MAXPLAYERS + 1];

//Stabilize Steering
int SteeringPlayerAngle[MAXPLAYERS + 1];
int SteeringGoalAngle;

//Align Engine Upper + Lower
int UpperEngineAngleGoal = 0;
int UpperEnginePlayerAngle[MAXPLAYERS + 1];
int LowerEngineAngleGoal = 0;
int LowerEnginePlayerAngle[MAXPLAYERS + 1];

//Calibrate Distribtor
int DistributorPlayerAngle[MAXPLAYERS + 1];
int DistributorGoalAngle = 0;
Handle DistributorTimers[MAXPLAYERS + 1]; 

//Fix Wires in X
int WiresPlayerLocation[MAXPLAYERS + 1]; //location which tells which wire task to complete
bool WiresPlayerProgress[MAXPLAYERS + 1][4];
int PlayerNextWire[MAXPLAYERS + 1];
char ColoursArray[4][20] =  { "Red wire to: ", "Blue wire to: ", "Green wire to: ", "Yellow wire to: " };

//task list tracker
bool[MAXPLAYERS+1][57] PlayerTasks;
bool[MAXPLAYERS+1][57] CompletedTasks;
new String:TaskNames[57][37] = 
{
"Clear Asteroids",
"Clean O2 Filter",
"Chart Course",
"Stabilise Steering",
"Swipe Card",
"Prime Shields",
"Calibrate Distributor",
"Align Upper Engine",
"Align Lower Engine",
"Start Reactor",
"Unlock Manifolds",
"Submit Scan",
"Inspect Sample",
"Empty Garbage",
"Empty Chute",
"Fuel Upper Engine",
"Fuel Lower Engine",
"Download Data",
"Divert Power",
"Fix Wiring",
"Empty Garbage 1/2",
"Empty Chute  1/2",
"Empty Airlock 2/2",
"Fuel Upper Engine 1/2",
"Fuel Upper Engine 2/2",
"Fuel Lower Engine 1/2",
"Fuel Lower Engine 2/2",
"Download Data from Cafeteria 1/2",
"Download Data from Weapons 1/2",
"Download Data from Navigation 1/2",
"Download Data from Communications 1/2",
"Download Data from Electrical 1/2",
"Upload Data in Admin 2/2",
"Divert Power to Security 1/2",
"Divert Power to Weapons 1/2",
"Divert Power to O2 1/2",
"Divert Power to Navigation 1/2",
"Divert Power to Shields 1/2",
"Divert Power to Communications 1/2",
"Divert Power to Lower Engine 1/2",
"Divert Power to Upper Engine 1/2",
"Divert Power to Security 2/2",
"Divert Power to Weapons 2/2",
"Divert Power to O2 2/2",
"Divert Power to Navigation 2/2",
"Divert Power to Shields 2/2",
"Divert Power to Communications 2/2",
"Divert Power to Lower Engine 2/2",
"Divert Power to Upper Engine 2/2",
"Fix Wiring in Cafeteria",
"Fix Wiring in Navigation",
"Fix Wiring in Admin",
"Fix Wiring in Storage",
"Fix Wiring in Electrical",
"Fix Wiring in Security",
"Inspect Sample 1/2",
"Collect Sample Results"
};

//Door sabotage buttons
//0 = cafeteria, 1 = medbay, 2 = storage, 3 = electrical, 4 = security, 5 = lower engine, 6 = upper engine
new String:DoorButtonNames[7][20] = 
{
	"CafeDoor_Button",
	"MedDoor_Button",
	"StorageDoor_Button",
	"EleDoor_Button",
	"SecDoor_Button",
	"LEngDoor_Button",
	"UEngDoor_Button",
};


public Plugin:myinfo = 
{
	name = "BG3 Among Us Plugin",
	author = "ChrisK112",
	description = "A plugin that handles the execution of an among us mode on the correct map, on a server.",
	version = PLUGIN_VERSION,
	url = "https://chrisk112.github.io/portfolio/#/"
};

public OnPluginStart()
{
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (g_offsCollisionGroup == -1)
	{
		PrintToServer("* FATAL ERROR: Failed to get offset for CBaseEntity::m_CollisionGroup");
	}
	
	NumberOfImpostors = 1;
	
	Colours[0] = "black";
	Colours[1] = "blue";
	Colours[2] = "red";
	Colours[3] = "yellow";
	Colours[4] = "green";
	Colours[5] = "purple";
	Colours[6] = "cyan";
	Colours[7] = "orange";
	Colours[8] = "normal";
	Colours[9] = "indigo";
	Colours[10] = "lightblue";
	Colours[11] = "saddlebrown";
	
	TotalNumberOfTasks = 0.0;
	NumberOfTasksLeft = 0.0;
	
	/*
	The format is [clientID][TaskID], [clientID][TaskID] for CompletedTasks 
	so if [1][3] is true, client [1] has task [3] as one of his tasks. And if [1][3] in CompletedTasks is true, then client [1] has completed the task.
	TaskIDs:
	
	0:	Clear Asteroids
	1:	Clean O2  Filter
	2:	Chart Course
	3:	Stabilise Steering
	4:	Swipe Card
	5:	Prime Shields
	6:	Calibrate Distributor
	7:	Align Upper Engine
	8:	Align Lower Engine
	9:	Start Reactor
	10:	Unlock Manifolds
	11: Submit Scan				11 Its time based, needs special code
	12: Inspect Sample			12 onwards are multi-tasks, need special code
	13: Empty Garbage
	14: Empty Chute
	15: Fuel Upper Engine
	16: Fuel Lower Engine
	17:	Download Data			on 17 being chosen, run  rand no 0-4 to teremine 1/2 task
	18:	Divert Power			On 18 being chosen, run a ran no 0-7 to determine 2/2 task
	19: Fix Wiring				On 19 being chosen, run a rand no to simulate start> 0-5, 1 = Cafe, 2 = Wep...
								
	20: Empty Garbage 1/2
	21: Empty Chute  1/2
	22: Empty Airlock 2/2
	
	23: Fuel Upper Engine 1/2
	24: Fuel Upper Engine 2/2
	
	25: Fuel Lower Engine 1/2
	26: Fuel Lower Engine 2/2
	
	27: Download Data from Cafeteria 1/2
	28: Download Data from Weapons 1/2
	29: Download Data from Navigation 1/2
	30: Download Data from Communications 1/2
	31: Download Data from Electrical 1/2
	32: Upload Data in Admin 2/2
	
	33: Divert Power to Security 1/2
	34: Divert Power to Weapons 1/2
	35:	Divert Power to O2 1/2
	36:	Divert Power to Navigation 1/2
	37:	Divert Power to Shields 1/2
	38:	Divert Power to Communications 1/2
	39:	Divert Power to Lower Engine 1/2
	40:	Divert Power to Upper Engine 1/2
	vvvv
	41: Divert Power to Security 2/2
	42: Divert Power to Weapons 2/2
	43:	Divert Power to O2 2/2
	44:	Divert Power to Navigation 2/2
	45:	Divert Power to Shields 2/2
	46:	Divert Power to Communications 2/2
	47:	Divert Power to Lower Engine 2/2
	48:	Divert Power to Upper Engine 2/2

	49: Fix Wiring in Cafeteria
	50: Fix Wiring in Navigation
	51: Fix Wiring in Admin
	52: Fix Wiring in Storage
	53: Fix Wiring in Electrical
	54: Fix Wiring in Security
	
	55: Inspect Sample 1/2
	56: Inspect Sample 2/2

	*/
	
	
	RegAdminCmd("sm_austart", Start_AmongUs, ADMFLAG_ROOT, "Starts the among us mode");
	RegAdminCmd("sm_austop", Stop_AmongUs, ADMFLAG_ROOT, "Stops and clears the mod.");
	
	//player commands
	RegConsoleCmd("tasks", ShowMyTasks, "Shows your current tasks");
	RegConsoleCmd("i", ImpostorMenu, "Open impostor menu.");
	
	// Create the rest of the cvar's
	CreateConVar("sm_auver", PLUGIN_VERSION, "BG3 Among Us version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

}


//unhook stuff on map end
public void OnMapEnd()
{
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	UnhookEvent("player_spawn", SpawnEvent, EventHookMode_Post);
	UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	ResetPlugin();
	
}

//not much needed here really, just making sure plugin doesnt carry over to next map
public void OnMapStart()
{
	AddSoundsToDL();
	AddMaterialsToDL();
	OnMapEnd();
}

// on player death
public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	//clear up if player disconnects.
	//cleanup user stuff
	new client;
	new clientid;
	clientid = GetEventInt(event,"userid");
	client = GetClientOfUserId(clientid);
    
	CleanClient(client);
	
	return Plugin_Handled;
		
}

// on player death
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	char pname[64];
	int client = event.GetInt("userid");
	new clientp = GetClientOfUserId(client);
	
	GetClientName(clientp, pname, sizeof(pname));

	if(IsClientValid(clientp))
	{	
	
		if(CrewmateGhost[clientp] || ImpostorGhost[clientp]) 
		{ 
			SpawnGhost(clientp);
			return Plugin_Handled;
		}
		else 
		{
			CreateTimer(1.0, CheckDeath, clientp);
		}

	}
	return Plugin_Handled;
		
} 

//player spawn
public Action SpawnEvent(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
	
}

stock CleanClient(client)
{
	Crewmate[client] = false;
	Impostor[client] = false;
	CrewmateGhost[client] = false;
	ImpostorGhost[client] = false;
	Execution[client] = false;
	
	SampleTimeLeft[client] = 0;
	FuelInCan[client] = 0;

	TouchingCans[client] = false;
	TouchingLEng[client] = false;
	TouchingUEng[client] = false;
	Fueling[client] = false;

	
	TouchingUp[client] = false;
	if(UploadTimers[client] != INVALID_HANDLE) 
	{
		KillTimer(UploadTimers[client]);
		UploadTimers[client] = INVALID_HANDLE;
	}
	UploadTimeLeft[client] = 0;
	
	OxygenPlayerProgressAdmin[client] = 0;
	OxygenPlayerProgressO2[client] = 0;
	
	
	WiresPlayerLocation[client] = 0; //location which tells which wire task to complete
	WiresPlayerProgress[client][0] = false;
	WiresPlayerProgress[client][1] = false;
	WiresPlayerProgress[client][2] = false;
	WiresPlayerProgress[client][3] = false;
	PlayerNextWire[client] = 0;
	
	PlayersInCommsMenu[client] = false;
	
	if(DistributorTimers[client] != INVALID_HANDLE) 
	{
		KillTimer(DistributorTimers[client]);
		DistributorTimers[client] = INVALID_HANDLE;
	}
	
	if(KillCooldownTimers[client] != INVALID_HANDLE) 
	{
		KillTimer(KillCooldownTimers[client]);
		KillCooldownTimers[client] = INVALID_HANDLE;
	}
	if(UpdateKillCooldownTimer[client] != INVALID_HANDLE)
	{
		KillTimer(UpdateKillCooldownTimer[client]);
		UpdateKillCooldownTimer[client] = INVALID_HANDLE;
	}
	
	for(int i = 0; i < 57; i++)
	{
		PlayerTasks[client][i] = false;
		CompletedTasks[client][i] = false;
	}
	
	ClientCommand(client, "hud_deathnotice_time 6");
	
	TurnVisible(client);

	
	//fix up tasks so crewmates are not blocked from finishing... do that later
	//PlayerTasks
	
}


/*********************** START PLUGIN *********************/
//Called first when the plugin is started
public Action Start_AmongUs(client, args)
{
	PrintToChatAll("Started Plugin!");
	
	//reset stuff first
	ResetPlugin();
	
	//set commands for gamemode
	SetCommandsOn();
	
	//set all Handle arrays
	SetHandleArrays();
	
	//Hook events
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", SpawnEvent, EventHookMode_Post);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	
	//events round_win or round_end or teamplay_round... etc not visible or dont exist or dont get fired
	HookHammerTriggersAndButtons();
	
	CreateTimer(0.5, AmongUs_Setup);
	
	return Plugin_Handled;
	
		
}

/*********************** SERVER CVARS *********************/
//commands on
stock SetCommandsOn()
{
	//notify spawns OFF
	ServerCommand("mp_comp_notifications 0");
	
	//notify sm commands OFF
	ServerCommand("sm_show_activity 0");
	
	//weapons + melee off
	ServerCommand("mp_disable_firearms 1");
	ServerCommand("mp_disable_melee 1");
	
	//FF on
	ServerCommand("mp_friendlyfire 1");
	
	//respawn time def
	ServerCommand("mp_respawntime 14");
	
	//silence everyone
	ServerCommand("sm_silence @all");
	
}

//commands on
stock SetCommandsOff()
{
	//notify spawns ON
	ServerCommand("mp_comp_notifications 1");
	
	//notify sm commands ON
	ServerCommand("sm_show_activity 13");
	
	//weapons + melee on
	ServerCommand("mp_disable_firearms 0");
	ServerCommand("mp_disable_melee 0");
	
	//FF off
	ServerCommand("mp_friendlyfire 0");
	
	//respawn time def
	ServerCommand("mp_respawntime 14");
	
	//unsilence everyone
	ServerCommand("sm_unsilence @all");
	
	
}

/***********************  DL TABLE *********************/
//add game sounds to DL table
stock AddSoundsToDL()
{
	decl String:buffer[80];
	for (int i = 0; i < 3; i++)
    {
		PrecacheSound(soundNames[i], true);
		Format(buffer, sizeof(buffer), "sound/%s", soundNames[i]);
		AddFileToDownloadsTable(buffer);
    }
	
}

//add game materials to DL table
stock AddMaterialsToDL()
{
	decl String:buffer[80];
	for (int i = 0; i < 2; i++)
    {
		Format(buffer, sizeof(buffer), "%s", scoreboard[i]);
		AddFileToDownloadsTable(buffer);
    }
	
}

/*********************** STOP PLUGIN *********************/
public Action Stop_AmongUs(client, args)
{
	StopPlugin();
	
}

stock StopPlugin()
{
	OnMapEnd();
}

/*********************** RESET PLUGIN *********************/
stock ResetPlugin()
{
	//clear task numbers
	TotalNumberOfTasks = 0.0;
	NumberOfTasksLeft = 0.0;
	
	//resolve sabotages
	ResolveOxygenSabotage(false);
	ResolveReactorSabotage(false);
	
	SabotageCooldown = false;
	
	if(SabotageCooldownUpdateTimer != INVALID_HANDLE)
	{
		KillTimer(SabotageCooldownUpdateTimer);
		SabotageCooldownUpdateTimer = INVALID_HANDLE;
	}
	if(SabotageCooldownTimer != INVALID_HANDLE)
	{
		KillTimer(SabotageCooldownTimer);
		SabotageCooldownTimer = INVALID_HANDLE;
	}
	if(VotingTimer != INVALID_HANDLE)
	{
		KillTimer(VotingTimer);
		VotingTimer = INVALID_HANDLE;
	}
	if(DiscussionTimer != INVALID_HANDLE)
	{
		KillTimer(DiscussionTimer);
		DiscussionTimer = INVALID_HANDLE;
	}
	
	
	//unblind crewmates if light sabotage was active
	ServerCommand("sm_blind @all 0");

	//clear clients
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			CleanClient(i);	
			
			//unhide names
			ClientCommand(i, "hud_showtargetid 1");
		}
		
	}
	
	//collision off
	CollOff();
	
	//vars that need resetting
	MeetingTime = false;
	ExecutionTime = false;
	DoorSabotageActive = false;

	//unhook any button that should be around
	UnhookKillButtons();
	ClearDeadBodyButtons();
	//unhook all other buttons and trigger
	UnhookButtons();
	
	//set commands back to default
	SetCommandsOff();
	
}

stock SetHandleArrays()
{
	//KillCooldownTimers, UpdateKillCooldownTimer, UploadTimers
	for(int i = 1; i <= MaxClients; i++)
	{
		KillCooldownTimers[i] = INVALID_HANDLE;
		UpdateKillCooldownTimer[i] = INVALID_HANDLE;
		UploadTimers[i] = INVALID_HANDLE;
		DistributorTimers[i] = INVALID_HANDLE;
		
	}
	
	//DoorSabotageTimers, DoorSabotageCooldownTimers
	for(int i = 0; i < 7; i++)
	{
		DoorSabotageTimers[i] = INVALID_HANDLE;
		DoorSabotageCooldownTimers[i] = INVALID_HANDLE;
	}
}


stock UnhookKillButtons()
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_door")) != -1) //search until it goes through all
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); 
		if(strncmp(buffer, "KillButton", 10) == 0) 
		{
			UnhookSingleEntityOutput(ent, "OnUser1", KillButton_Pressed); 
			FireEntityOutput(ent, "OnUser3", -1, 0.0); // kill button
			continue;
		}        
	}
}	


/*********************** ROUND START CYCLE *********************/
public Action AmongUs_Setup(Handle timer)
{
	
	//choose impostors
	
	//get number of players to determine how many impostors will play >=7 people then 2 impostors!
	NumberOfImpostors = 0;
	int clientsNum = GetNumberOfPlayers();
	if(clientsNum >= 7)
	{
		NumberOfImpostors = 2;
	} 
	//dont forget to either make a config, or setup commands here too!
	
	//set player colours and crewmate flags
	SetupPlayers();
	//first create one impostor
	char impostor_name[64];
	int impostor_id = GetRandomPlayer();
	GetClientName(impostor_id, impostor_name, sizeof(impostor_name));
	StartKillCooldown(impostor_id, START_KILL_COOLDOWN);
	
	//unhide names
	ClientCommand(impostor_id, "hud_showtargetid 1");
	
	//if we need another impostor
	if(NumberOfImpostors == 2)
	{
		char impostor_name_2[64];
		int impostor_id_2 = GetRandomPlayer();
		GetClientName(impostor_id_2, impostor_name_2, sizeof(impostor_name_2));
		StartKillCooldown(impostor_id_2, START_KILL_COOLDOWN);
		
		//print to chat saying who other impostors are
		PrintToChat(impostor_id_2, "The other impostor is: %s", impostor_name);
		PrintToChat(impostor_id, "The other impostor is: %s", impostor_name_2);
		
		//unhide names
		ClientCommand(impostor_id_2, "hud_showtargetid 1");
		
	}
	
	
	//sabotage cooldown
	StartSabotageCooldown();
	
	//emergancy button reset
	EmergencyButtonTimer = CreateTimer(float(START_EMERGENCY_BUTTON_COOLDOWN), EmergecyButtonCooldownOver);
	EmergencyButtonEnabled = false;
	//give out tasks
	SetupTasks();
	NumberOfTasksLeft = TotalNumberOfTasks;
	
	//spawn @all here? SPAWNING RESETS THE DISPLAYED TEXT! Spawn, then display tasks.
	PrintToChatAll("Among Us Mode Started!"); 
	SpawnEveryone();
	
	//setup kill buttons
	CreateTimer(0.5, SetupKillButtons);
	
	//display chosen role, and tasks. Small timer delay to make sure the spawn doesnt fire after/during
	CreateTimer(1.0, DisplayNewRoundInfo);
	
	
	//create "Today's number" used for oxygen sabotage
	CreateTodaysCode();
	
	//create degrees for comms sabotage
	CreateCommsDegree();
	
	//create task variables
	CreateStartReactorNumbers();
	CreateChartCourseNumbers();
	CreateSteeringAngle();
	CreateLowerEngineAngle();
	CreateUpperEngineAngle();
	CreateDistributorAngle();
	
	//open up the doors
	OpenUpDoors();
	
	
	//enable camera
	EnableCameras();
	
	return Plugin_Handled;
	
} 

//display chosen role, and tasks to all players
public Action DisplayNewRoundInfo(Handle timer)
{
	for(int i = 0; i<=MaxClients; i++)
	{
		if(Crewmate[i]) 
		{
			DisplayCrewmateMessage(i);
			DisplayTasksToClient(i);		
		}
		if(Impostor[i]) DisplayImpostorMessage(i);
	}
}

/*********************************************** IMPOSTOR STUFF *********************************************/

//MENU STUFF
public Action ImpostorMenu(client, args)
{
	if(!(Impostor[client] || ImpostorGhost[client])) return Plugin_Handled;
	
	//draw menu
	Menu menu = new Menu(Impostor_Callback);
	menu.SetTitle("Choose a Sabotage");

	menu.AddItem("lights", "Sabotage Lights");
	menu.AddItem("comms", "Distrupt Comms");
	menu.AddItem("reactor", "Reactor Meltdown");
	menu.AddItem("oxygen", "Oxygen Depleted");
	menu.AddItem("door", "Doors (pick)");

	
	//Display Manu to client
	menu.Display(client, 10);
	
	return Plugin_Continue;
	
}

public int Impostor_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item, "lights"))   
			{
				SabotageLights(param1);
			}
			else if(StrEqual(item, "comms"))
			{
				SabotageComms(param1);
			}
			
			else if(StrEqual(item, "reactor"))
			{
				SabotageReactor(param1);
			}
			
			else if(StrEqual(item, "oxygen"))
			{
				SabotageOxygen(param1);
			}
			
			else if(StrEqual(item, "door"))
			{
				DoorMenu(param1);
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock DoorMenu(client)
{
	////0 = cafeteria, 1 = medbay, 2 = storage, 3 = electrical, 4 = security, 5 = lower engine, 6 = upper engine
	//SabotageDoor(client, doorno)
	
	//draw menu
	Menu menu = new Menu(Door_Callback);
	menu.SetTitle("Choose a Door Location");

	menu.AddItem("cafe", "Cafeteria");
	menu.AddItem("med", "Medbay");
	menu.AddItem("storage", "Storage");
	menu.AddItem("ele", "Electrical");
	menu.AddItem("sec", "Security");
	menu.AddItem("leng", "Lower Engine");
	menu.AddItem("ueng", "Upper Engine");

	
	//Display Manu to client
	menu.Display(client, 10);
	
}

public int Door_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			char item[10];
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item, "cafe"))   
			{
				SabotageDoor(param1, 0);
			}

			else if(StrEqual(item, "med"))
			{
				SabotageDoor(param1, 1);
			}

			else if(StrEqual(item, "storage"))
			{
				SabotageDoor(param1, 2);
			}

			else if(StrEqual(item, "ele"))
			{
				SabotageDoor(param1, 3);
			}

			else if(StrEqual(item, "sec"))
			{
				SabotageDoor(param1, 4);
			}

			else if(StrEqual(item, "leng"))
			{
				SabotageDoor(param1, 5);
			}

			else if(StrEqual(item, "ueng"))
			{
				SabotageDoor(param1, 6);
			}

		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


/*********************** START SABOTAGE COOLDOWN *********************/
//shared between all impostors
stock StartSabotageCooldown()
{
	
	SabotageCooldown = true;
	
	//update values
	SabotageCooldownLeft = DEFAULT_SABOTAGE_COOLDOWN-1;

	SabotageCooldownUpdateTimer = CreateTimer(0.0, UpdateSabotageCooldown);

	//create timer for full length;
	SabotageCooldownTimer = CreateTimer(float(DEFAULT_SABOTAGE_COOLDOWN), SabotageCooldownOver);
	

}


/*********************** UPDATE SABOTAGE COOLDOWN *********************/
public Action UpdateSabotageCooldown(Handle timer)
{
	int timeLeft = SabotageCooldownLeft;

	//cooldown over
	if(!SabotageCooldown || timeLeft <= 0)
	{
		if (SabotageCooldownUpdateTimer != INVALID_HANDLE)KillTimer(SabotageCooldownUpdateTimer);
		SabotageCooldownUpdateTimer = INVALID_HANDLE;
		return Plugin_Handled;
	}
	//otherwise its not
		
	char msg[64];
	msg = "Sabotage Cooldown: ";
	char msg2[10];
	IntToString(timeLeft, msg2, sizeof(msg2));
	StrCat(msg, sizeof(msg), msg2);
	
	//update cooldwon var
	SabotageCooldownLeft--;
		
	//call next timer
	SabotageCooldownUpdateTimer = CreateTimer(1.0, UpdateSabotageCooldown);
	
	new Handle:hHudText = CreateHudSynchronizer();
	SetHudTextParams(0.0, 0.4, 0.9, 0, 0, 255, 255);
	
	//Wish it would be easier to make this, maybe send DATA PACKS to the timer instead...
	for(int i = 0; i<=MaxClients; i++)
	{
		if(Impostor[i])
		{
			ShowSyncHudText(i, hHudText, msg);
		}
	}
	
	CloseHandle(hHudText);
	
	return Plugin_Continue;
	
}

/*********************** SABOTAGE COOLDOWN OVER *********************/
public Action SabotageCooldownOver(Handle timer)
{
	if (SabotageCooldownTimer != INVALID_HANDLE)KillTimer(SabotageCooldownTimer);
	SabotageCooldownTimer = INVALID_HANDLE;
	
	//set flags
	SabotageCooldown = false;
	SabotageCooldownLeft = 0;
	SabotageCooldownTimer = INVALID_HANDLE;

}

/*********************** START KILL COOLDOWN *********************/
stock StartKillCooldown(client, time)
{
	float timef = float(time);
	
	//update values
	KillCooldown[client] = true;
	KillCooldownLeft[client] = time - 1; //time -1
	KillCooldownTimers[client] = CreateTimer(timef, KillCooldownOver, client); //time
	
	//create countdown timer for client
	UpdateKillCooldownTimer[client] = CreateTimer(0.0, UpdateKillCooldown, client);

}

/*********************** UPDATE KILL COOLDOWN *********************/
public Action UpdateKillCooldown(Handle timer, client)
{
	
	if(!KillCooldown[client])
	{
		if (UpdateKillCooldownTimer[client] != INVALID_HANDLE)KillTimer(UpdateKillCooldownTimer[client]);
		UpdateKillCooldownTimer[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}

	int timeLeft = KillCooldownLeft[client];

	//cooldown over
	if(timeLeft <= 0)
	{
		if (UpdateKillCooldownTimer[client] != INVALID_HANDLE)KillTimer(UpdateKillCooldownTimer[client]);
		UpdateKillCooldownTimer[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	//otherwise its not
		
	char msg[64];
	msg = "Kill Cooldown: ";
	char msg2[10];
	IntToString(timeLeft, msg2, sizeof(msg2));
	StrCat(msg, sizeof(msg), msg2);
	
	KillCooldownLeft[client]--;

	//call next timer
	UpdateKillCooldownTimer[client] = CreateTimer(1.0, UpdateKillCooldown, client);

	new Handle:hHudText = CreateHudSynchronizer();
	SetHudTextParams(0.0, 0.2, 0.9, 255, 0, 0, 255);
	ShowSyncHudText(client, hHudText, msg);
	CloseHandle(hHudText);
	
	return Plugin_Continue;
	

}

/*********************** KILL COOLDOWN OVER *********************/
public Action KillCooldownOver(Handle timer, client)
{
	if (KillCooldownTimers[client] != INVALID_HANDLE)KillTimer(KillCooldownTimers[client]);
	KillCooldownTimers[client] = INVALID_HANDLE;
	
	char ktimermsg[64] = "Kill Ability off Cooldown!";
	PrintToChat(client, ktimermsg); 
	KillCooldown[client] = false;
}

/*********************** SABOTAGE LIGHTS *********************/
//call button that toggles lights OR set their brightness low. also "blind" all crewmates with commands
//same button called when crewmates finish repair? maybe toggle will work
stock SabotageLights(impostor)
{

	if(!Impostor[impostor] && !ImpostorGhost[impostor])
	{
		return;
	}

	
	if(SabotageCooldown || SabotageActive || DoorSabotageActive)
	{
		PrintToChat(impostor, "Another Sabotage is active or still on Cooldown!"); 
		return;
	}
	
	//set up switch array to random, with at least ONE "Off"/false position
	SetupLightsSwitches();
	
	//blind crewmates
	for(int i = 0; i<=MaxClients; i++)
	{
		if(Crewmate[i]) BlindPlayer(i);
		if (Impostor[i])UnBlindPlayer(i);
	}
	
	ServerCommand("msay The Lights have been sabotaged!");
	
	SabotageActive = true;
	LightsSabotageActive = true;
	
	//disable emergency meeting
	EmergencyButtonEnabled = false;
	
	return;
}

stock SetupLightsSwitches()
{
	//sort rand array randomly
	SortIntegers(RandomLightsArr, 9, Sort_Random);
	
	//set first 5 values to light switches array

	for(int i = 0; i < 5; i++)    
	{
		(RandomLightsArr[i] == 1) ? (LightSwitches[i] = true):(LightSwitches[i] = false);
	}
}

/*********************** SABOTAGE REACTOR *********************/
stock SabotageReactor(impostor)
{
	if(!Impostor[impostor] && !ImpostorGhost[impostor])
	{
		return;
	}
	
	if(SabotageCooldown || SabotageActive || DoorSabotageActive)
	{
		PrintToChat(impostor, "Another Sabotage is active or still on Cooldown!"); 
		return;
	}
	
	ServerCommand("msay The Reactor has been sabotaged!");
	
	SabotageActive = true;
	ReactorSabotageActive = true;
	TurnOnWarningLights();
	
	//start timer countdown
	ReactorTimeLeft = DEFAULT_OXYGEN_DEPLETED;
	ReactorSabotageTimer = CreateTimer(1.0, ReactorSabotageCountdown);
	
	//disable emergency meeting
	EmergencyButtonEnabled = false;
	
	return;
}

public Action ReactorSabotageCountdown(Handle timer)
{
	//decrement timer
	ReactorTimeLeft -= 1;
	
	if(ReactorTimeLeft == 0)
	{
		if (ReactorSabotageTimer != INVALID_HANDLE)KillTimer(ReactorSabotageTimer);
		ReactorSabotageTimer = INVALID_HANDLE;
		DeclareWinner(1); //1 is impostor
		return Plugin_Handled;
	}
	
	char msg[64];
	char timeleft[6];
	IntToString(ReactorTimeLeft, timeleft, sizeof(timeleft));
	msg = "Reactor Meltdown in: ";
	StrCat(msg, sizeof(msg), timeleft);

	//setup msg on HUD
	new Handle:hHudText = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.2, 1.0, 255, 0, 0, 255);
	
	//show all client the msg
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			ShowSyncHudText(i, hHudText, msg);
		}
	}
	CloseHandle(hHudText);
	
	ReactorSabotageTimer = CreateTimer(1.0, ReactorSabotageCountdown);
	
	return Plugin_Continue;
}

/*********************** SABOTAGE OXYGEN *********************/
stock SabotageOxygen(impostor)
{
	if(!Impostor[impostor] && !ImpostorGhost[impostor])
	{
		return;
	}
	
	if(SabotageCooldown || SabotageActive || DoorSabotageActive)
	{
		PrintToChat(impostor, "Another Sabotage is active or still on Cooldown!"); 
		return;
	}
	
	ServerCommand("msay Oxygen has been sabotaged!");
	
	SabotageActive = true;
	OxygenSabotageActive = true;
	TurnOnWarningLights();
	
	//start timer countdown
	OxygenTimeLeft = DEFAULT_OXYGEN_DEPLETED;
	OxygenSabotageTimer = CreateTimer(1.0, OxygenSabotageCountdown);
	
	//disable emergency meeting
	EmergencyButtonEnabled = false;
	
	return;
}

public Action OxygenSabotageCountdown(Handle timer)
{
	//decrement timer
	OxygenTimeLeft -= 1;
	
	if(OxygenTimeLeft == 0)
	{
		if (OxygenSabotageTimer != INVALID_HANDLE)KillTimer(OxygenSabotageTimer);
		OxygenSabotageTimer = INVALID_HANDLE;
		DeclareWinner(1); //1 is impostor
		return Plugin_Handled;
	}
	
	char msg[64];
	char timeleft[6];
	IntToString(OxygenTimeLeft, timeleft, sizeof(timeleft));
	msg = "Oxygen Depleted in: ";
	StrCat(msg, sizeof(msg), timeleft);

	//setup msg on HUD
	new Handle:hHudText = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.2, 1.0, 255, 0, 0, 255);
	
	//show all client the msg
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			ShowSyncHudText(i, hHudText, msg);
		}
	}
	CloseHandle(hHudText);
	
	OxygenSabotageTimer = CreateTimer(1.0, OxygenSabotageCountdown);
	
	return Plugin_Continue;
}


/*********************** SABOTAGE COMMS *********************/
stock SabotageComms(impostor)
{
	if(!Impostor[impostor] && !ImpostorGhost[impostor])
	{
		return;
	}
	
	if(SabotageCooldown || SabotageActive || DoorSabotageActive)
	{
		PrintToChat(impostor, "Another Sabotage is active or still on Cooldown!"); 
		return;
	}
	
	
	SabotageActive = true;
	CommsSabotageActive = true;
	ServerCommand("msay Comms have been sabotaged!");
	StartCommsSabotage();
	
	//disable cameras
	DisableCameras();
	
	//disable emergency meeting
	EmergencyButtonEnabled = false;
	
	return;
}

/*********************** SABOTAGE DOORS *********************/
stock SabotageDoor(impostor, doorno)    //0 = cafeteria, 1 = medbay, 2 = storage, 3 = electrical, 4 = security, 5 = lower engine, 6 = upper engine
{
	if(!Impostor[impostor] && !ImpostorGhost[impostor])
	{
		return;
	}
	
	if(DoorSabotage[doorno] || DoorSabotageCooldown[doorno])
	{
		PrintToChat(impostor, "Door is active, or still on Cooldown!"); 
		return;
	}
	
	if(SabotageActive)
	{
		PrintToChat(impostor, "Another sabotage is active!"); 
		return;
	}
	
	StartDoorSabotage(doorno);
	
	return;
}

stock StartDoorSabotage(doorno)
{
	DoorSabotage[doorno] = true;
	DoorSabotageActive = true;
	DoorSabotageTimers[doorno] = CreateTimer(float(DEFAULT_DOOR_SABOTAGE), DoorSabotageOver, doorno);
	
	CloseDoor(doorno);
	
}

public Action DoorSabotageOver(Handle timer, doorno)
{
	if (DoorSabotageTimers[doorno] != INVALID_HANDLE)KillTimer(DoorSabotageTimers[doorno]);
	DoorSabotageTimers[doorno] = INVALID_HANDLE;
	
	DoorSabotageCooldown[doorno] = true; //for now, we dont even decrement it...
	DoorSabotage[doorno] = false;
	DoorSabotageCooldownTimers[doorno] = CreateTimer(float(DEFAULT_DOOR_COOLDOWN), DoorCooldownOver, doorno);
	
	bool temp = false;
	for(int i = 0; i < 7; i++)
	{
		if(DoorSabotage[i]) temp = true;
	}
	DoorSabotageActive = temp;
}

stock OpenUpDoors()
{
	for(int i = 0; i < 7; i++)
	{
		OpenDoor(i);
	}
}

public Action DoorCooldownOver(Handle timer, doorno)
{
	if (DoorSabotageCooldownTimers[doorno] != INVALID_HANDLE)KillTimer(DoorSabotageCooldownTimers[doorno]);
	DoorSabotageCooldownTimers[doorno] = INVALID_HANDLE;
	DoorSabotageCooldown[doorno] = false;
}

stock CloseDoor(doorno)
{
	//get button name
	char bname[64];
	bname = DoorButtonNames[doorno]; //0 = cafeteria, 1 = medbay, 2 = storage, 3 = electrical, 4 = security, 5 = lower engine, 6 = upper engine
	
	//find button and fire its output
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1) // Find button
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, bname, false)) // targetname match
		{
			FireEntityOutput(ent, "OnUser1", 0, 0.0); //  trigger the output
			break; // Stop loop since we done here
		}        
	}
	return;
	
}

stock CloseDoorMeeting()
{
	//get button name
	char bname[64];
	bname = DoorButtonNames[0]; //0 = cafeteria
	
	//find button and fire its output
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1) // Find button
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, bname, false)) // targetname match
		{
			FireEntityOutput(ent, "OnUser3", 0, 0.0); //  trigger the output
			break; // Stop loop since we done here
		}        
	}
	return;
	
}

//only called at start to open up the doors
stock OpenDoor(doorno)
{
	//get button name
	char bname[64];
	bname = DoorButtonNames[doorno]; //0 = cafeteria, 1 = medbay, 2 = storage, 3 = electrical, 4 = security, 5 = lower engine, 6 = upper engine
	
	//find button and fire its output
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1) // Find button
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, bname, false)) // targetname match
		{
			FireEntityOutput(ent, "OnUser2", 0, 0.0); //  trigger the output
			break; // Stop loop since we done here
		}        
	}
	return;
	
}

/*********************** SABOTAGE HANDLING *********************/

stock CreateCommsDegree()
{
	int rand = GetRandomInt(0, 71);
	CurrentDegree = rand * 5;
}

stock StartCommsSabotage()
{
	bool diff = false;
	while(!diff)
	{
		int rand = GetRandomInt(0, 71);
		rand = rand * 5;
		if(CurrentDegree != rand )
		{
			GoalDegree = rand;
			diff = true; //simply to stop shit errors
			break;
		}
	}
	
}

stock SendCommsSabotageMenu(client)
{
	if(!CommsSabotageActive)
	{
		return;
	}
	
	//label player as "in-menu"
	PlayersInCommsMenu[client] = true;
	
	Menu menu = new Menu(CommsSabotage_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	
	char stCAng[8];
	char stGAng[8];
	IntToString(CurrentDegree, stCAng, sizeof(stCAng));
	IntToString(GoalDegree, stGAng, sizeof(stGAng));
	
	char title[100];
	title = "Set angle to: \nCurrent: ";
	StrCat(title, sizeof(title), stCAng);
	StrCat(title, sizeof(title), "°\nGoal: ");
	StrCat(title, sizeof(title), stGAng);
	StrCat(title, sizeof(title), "°");
 
	menu.SetTitle(title);
	

	menu.AddItem("plus5", "+ 5°");
	menu.AddItem("plus10", "+ 10°");
	menu.AddItem("minus5", "- 5°");
	menu.AddItem("minus10", "- 10°");

	
	menu.Display(client, 5);
}

public int CommsSabotage_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!CommsSabotageActive)
			{
				return;
			}
			switch(param2)
			{
				case(0):
				{
					int newAng = CurrentDegree + 5;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					CurrentDegree = newAng;
					if(!CheckCommsAngle())
					{
						UpdateCommsClients();
						return;
					}
					ClearCommsMenu();
				}
				case(1):
				{
					int newAng = CurrentDegree + 10;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					CurrentDegree = newAng;
					if(!CheckCommsAngle())
					{
						UpdateCommsClients();
						return;
					}
					ClearCommsMenu();
				}
				case(2):
				{
					int newAng = CurrentDegree - 5;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					CurrentDegree = newAng;
					if(!CheckCommsAngle())
					{
						UpdateCommsClients();
						return;
					}
					ClearCommsMenu();
				}
				case(3):
				{
					int newAng = CurrentDegree - 10;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					CurrentDegree = newAng;
					if(!CheckCommsAngle())
					{
						UpdateCommsClients();
						return;
					}
					ClearCommsMenu();
				}
			}
		}
		case MenuAction_End:
		{
		delete menu;
		}
	}
}

stock UpdateCommsClients()
{
		for(int i = 1; i <= MaxClients; i++)
	{
		if(PlayersInCommsMenu[i]) 
		{
			//cancel menu - not sure if it works
			CancelClientMenu(i);
			SendCommsSabotageMenu(i);
		}
	}
}

stock bool CheckCommsAngle()
{
	if(CurrentDegree == GoalDegree)
	{
		ResolveCommsSabotage();
		return true;
	}
	return false;
}

stock ClearCommsMenu()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(PlayersInCommsMenu[i]) 
		{
			//cancel menu - not sure if it works
			CancelClientMenu(i);
		}
	}
}



stock CreateTodaysCode()
{
	//total numbers is 5
	for(int i = 0; i < 5; i++)
	{
		TodaysCode[i] = GetRandomInt(1, 8); //unfortunatly, sourcemod menus + panels only support 8 menu items at a time for valve style ;/
	}
	
	//convert to String
	char code[20];
	code = "Today's code: ";
	
	for(int i = 0; i < 5; i++)
	{
		char num[5];
		IntToString(TodaysCode[i], num, sizeof(num));
		StrCat(code, sizeof(code), num);
	}
	TodaysCodeString = code;
}

//send PERSONAL button menu for O2 sabotage button
stock SendOxygenO2Menu(client)
{
	if(OxygenTask2Done || !OxygenSabotageActive)
	{
		return;
	}
	
	char code[20];
	code = TodaysCodeString;
	//create menu
	Menu menu = new Menu(O2_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	menu.SetTitle(code);
	
	char button[12];
	button = "Button ";
	
	for(int i = 0; i < 8; i++)
	{
		button = "Button ";
		char num[3];
		IntToString(i+1, num, sizeof(num));
		StrCat(button, sizeof(button), num);
		menu.AddItem(num, button);
		
	}
	
	//Display Manu to client
	menu.Display(client, 4);
}

public int O2_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if(OxygenTask2Done || !OxygenSabotageActive)
	{
		return;
	}
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			char number[10];
			IntToString(TodaysCode[OxygenPlayerProgressO2[param1]], number, sizeof(number));   //IntToString(TodaysCode[OxygenPlayerProgressAdmin[param1]], number, sizeof(number));
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item, number))   //if its right choice > Code[PlayerStage[Player]] 
			{
				OxygenPlayerProgressO2[param1]++;
				if(OxygenPlayerProgressO2[param1] == 5)
				{
					OxygenPlayerProgressO2[param1] = 0;
					OxygenTask2Done = true;
					CheckOxygenSabotage();
					return;
				}
				SendOxygenO2Menu(param1);
			}
			else //else they got it wrong, so force restart
			{
				OxygenPlayerProgressO2[param1] = 0;
				return;
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

//send PERSONAL button menu for Admin sabotage button
stock SendOxygenAdminMenu(client)
{
	if(OxygenTask1Done || !OxygenSabotageActive)
	{
		return;
	}
	
	char code[20];
	code = TodaysCodeString;
	//create menu
	Menu menu = new Menu(Admin_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	menu.SetTitle(code);
	
	char button[12];
	button = "Button ";
	
	for(int i = 0; i < 8; i++)
	{
		button = "Button ";
		char num[3];
		IntToString(i+1, num, sizeof(num));
		StrCat(button, sizeof(button), num);
		menu.AddItem(num, button);
	}
	
	//Display Manu to client
	menu.Display(client, 4);
}

public int Admin_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if(OxygenTask1Done || !OxygenSabotageActive)
	{
		return;
	}
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			char number[10];
			IntToString(TodaysCode[OxygenPlayerProgressAdmin[param1]], number, sizeof(number));
			char item[32];
			menu.GetItem(param2, item, sizeof(item));		
			if(StrEqual(item, number))   //if its right choice > Code[PlayerStage[Player]] 
			{
				OxygenPlayerProgressAdmin[param1]++;
				if(OxygenPlayerProgressAdmin[param1] == 5)
				{
					OxygenPlayerProgressAdmin[param1] = 0;
					OxygenTask1Done = true;
					CheckOxygenSabotage();
					return;
				}
				SendOxygenAdminMenu(param1);
			}
			else //else they got it wrong, so force restart
			{
				OxygenPlayerProgressAdmin[param1] = 0;
				return;
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock CheckOxygenSabotage()
{
	if(!OxygenSabotageActive) return;
	
	if(OxygenTask1Done && OxygenTask2Done)
	{
		ResolveOxygenSabotage(true);
	}
}

//send PUBLIC swtich menu for light sabotage button
stock SendLightsMenu(client)
{
	if(!LightsSabotageActive)
	{
		return;
	}
	
	//label player as "in-menu"
	PlayersInLightsMenu[client] = true;
	
	//create menu
	Menu menu = new Menu(Lights_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	menu.SetTitle("Flip all switches to 'On'");
	
	
	for(int i = 0; i < 5; i++)
	{
		char next[5];
		char num[3];
		IntToString(i, num, sizeof(num));
		(LightSwitches[i])?(next = "On"):(next = "Off");
		menu.AddItem(num, next);
	}
	
	//Display Manu to client
	menu.Display(client, 4);
}

public int Lights_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			//flip switch
			LightSwitches[param2] = !LightSwitches[param2];
			for(int i = 0; i < 5; i++)
			{
				if(!LightSwitches[i]) //if a switch if "Off", send updated menus to all players viewing them
				{
					ResendLightsMenu();
					return;
				}
			}
			//if we get here, all switches are "On"
			ClearLightsMenu();
			ResolveLightsSabotage();
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock ResendLightsMenu()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(PlayersInLightsMenu[i]) 
		{
			//cancel menu - not sure if it works, or is even needed
			CancelClientMenu(i);
			SendLightsMenu(i); // maybe just try this... should work.
		}
	}
}

stock ClearLightsMenu()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(PlayersInLightsMenu[i]) 
		{
			//cancel menu - not sure if it works
			CancelClientMenu(i);
		}
	}
}


/*********************** RESOLVE SABOTAGES *********************/
stock ResolveOxygenSabotage(bool cooldown)
{
	OxygenTask1Done = false;
	OxygenTask2Done = false;
	OxygenSabotageActive = false;
	SabotageActive = false;
	
	if(OxygenSabotageTimer != INVALID_HANDLE)
	{
		KillTimer(OxygenSabotageTimer);
		OxygenSabotageTimer = INVALID_HANDLE;
	}
	
	//turn off warning lights	
	TurnOffWarningLights();
	
	//start impostor cooldown
	if(cooldown) StartSabotageCooldown();
	
	//clear player arrays of progress
	for(int i = 1; i <= MaxClients; i++)
	{
		OxygenPlayerProgressAdmin[i] = 0;
		OxygenPlayerProgressO2[i] = 0;
	}
	
	//enable emergency meeting
	EmergencyButtonEnabled = true;
}

stock ResolveReactorSabotage(bool cooldown)
{
	ReactorSabotageActive = false;
	ReactorButton1Pressed = false;
	ReactorButton2Pressed = false;
	SabotageActive = false;
	
	if(ReactorSabotageTimer != INVALID_HANDLE)
	{
		KillTimer(ReactorSabotageTimer);
		ReactorSabotageTimer = INVALID_HANDLE;
	}
	//turn off warning lights	
	TurnOffWarningLights();
	//start impostor cooldown
	if(cooldown) StartSabotageCooldown();
	
	
	//enable emergency meeting
	EmergencyButtonEnabled = true;
	
}

stock ResolveLightsSabotage()
{
	LightsSabotageActive = false;
	SabotageActive = false;
	//start impostor cooldown
	StartSabotageCooldown();
	
	//unblind crewmates
	for(int i = 0; i<=MaxClients; i++)
	{
		if(Crewmate[i]) UnBlindPlayer(i);
		if(Impostor[i]) UnBlindPlayer(i);
	}
	
	//enable emergency meeting
	EmergencyButtonEnabled = true;
}

stock ResolveCommsSabotage()
{
	CommsSabotageActive = false;
	SabotageActive = false;
	//turn off warning lights	
	TurnOffWarningLights();
	//start impostor cooldown
	StartSabotageCooldown();
	
	//enable emergency meeting
	EmergencyButtonEnabled = true;
	
	//enable cameras
	EnableCameras();
	
}

//sabotage buttons

public Action UnpressReactor1Button(Handle timer)
{
	ReactorButton1Pressed = false;
}

public Action UnpressReactor2Button(Handle timer)
{
	ReactorButton2Pressed = false;
}


/*********************** CAMERAS *********************/

stock EnableCameras()
{
	//enable cameras ToggleCamerasButton
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "ToggleCamerasButton", false)) // targetname match
		{
			FireEntityOutput(ent, "OnUser1", -1, 1.0); //  trigger the output on an entity, with activator as client (clientid == entityid)		
			break; // Stop loop
		}        
	}
	return;
	
}

stock DisableCameras()
{
	//disable cameras ToggleCamerasButton
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "ToggleCamerasButton", false)) // targetname match
		{
			FireEntityOutput(ent, "OnUser2", -1, 1.0); //  trigger the output on an entity, with activator as client (clientid == entityid)		
			break; // Stop loop
		}        
	}
	return;
	
}

/*********************** BLIND PLAYER *********************/
stock BlindPlayer(victim)
{

	//blind crewmate
	char victim_name[64];
	GetClientName(victim, victim_name, sizeof(victim_name));
	ServerCommand("sm_blind \"%s\" 253", victim_name);
	
}

/*********************** UNBLIND PLAYER *********************/
stock UnBlindPlayer(victim)
{

	//unblind crewmate
	char victim_name[64];
	GetClientName(victim, victim_name, sizeof(victim_name));
	ServerCommand("sm_blind \"%s\" 0", victim_name);
	
}

/*********************** KILL CREWMATE *********************/
public Action CrewmateDeath(Handle timer, victim)
{
	//inform the crewmate that he has been killed
	//? prolly not needed
	
	//slay crewmate
	//char victim_name[64];
	//GetClientName(victim, victim_name, sizeof(victim_name));
	ClientCommand(victim, "kill");
	
}


/*********************** GET PLAYER LOCATION *********************/
stock float[3] GetPlayerLocation(client)
{
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	return pos;
}

/*********************** SETUP TASKS *********************/
stock SetupTasks()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(Crewmate[i])
			{
				GivePlayerTasks(i);
			}			
		}
	}
	
}

/*********************** SETUP KILL BUTTONS *********************/
public Action SetupKillButtons(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(Crewmate[i])
			{
				//create button
				SpawnKillButton(i);
				CreateTimer(0.5, FindButtons, i);

			}			
		}
	}
	
}


public Action FindButtons(Handle timer, client)
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_door")) != -1) // Find the maker
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(strncmp(buffer, "KillButton", 10) == 0) // the right button type match
		{
			//get entity parent, which by now should be the client inside it :>
			if(GetEntPropEnt(ent, Prop_Data, "m_hMoveParent") == client)
			{						
				//rename button
				//CreateTimer(0.5, RenameButton, client);
				//Hook its output
				HookSingleEntityOutput(ent, "OnUser1", KillButton_Pressed, false); // Hook trigger output
				break; // Stop loop
			}					
		}        
	}
}				

public Action RenameButton(Handle timer, client)
{
	//no need for this?
	return Plugin_Continue;
}



/*********************** GIVE TASKS *********************/
//lets start with 5 random tasks, no matter the length
stock GivePlayerTasks(client)
{
	for (int i = 0; i < GAME_NUMBER_OF_TASKS; i++)
	{
		//get random number 0-19 task
		int task = GetRandomInt(0, 19);
	
		//check if he has the task already
		if(PlayerTasks[client][task]) 
		{
			i--;
			continue;
		}
		
		//we can now add the task to list
		PlayerTasks[client][task] = true;
		
		//Increment the TotalTasks
		TotalNumberOfTasks += 1.0;
		
		//check if its NOT multi-step task, then we can skip to next cycle
		if(task <= 11)
		{
			continue;
		}
		
		//otherwise check which multi task it is
		switch(task)
		{
			//Inspect Sample
			case 12:
			{
				PlayerTasks[client][InspectSampleFirst] = true;
				//total gets +1 task. TaskID 2/2 will be +1
				TotalNumberOfTasks += 1.0;
			}
			
			//Empty Garbage
			case 13:
			{
				PlayerTasks[client][EmptyGarbageFirst] = true;
				//total gets +1 task. TaskID 2/2 will be +2
				TotalNumberOfTasks += 1.0;
			}
			
			//Empty Chute
			case 14:
			{
				PlayerTasks[client][EmptyChuteFirst] = true;
				//total gets +1 task. TaskID 2/2 will be +1
				TotalNumberOfTasks += 1.0;
			}
			
			//Fuel L Engine
			case 15:
			{
				PlayerTasks[client][FuelLowerEngineFirst] = true;
				//total gets +1 task. TaskID 2/2 will be +1
				TotalNumberOfTasks += 1.0;
			}
			
			//Fuel U Engine
			case 16:
			{
				PlayerTasks[client][FuelUpperEngineFirst] = true;
				//total gets +1 task. TaskID 2/2 will be +1
				TotalNumberOfTasks += 1.0;
			}
			
			//Download Data
			case 17:
			{
				//get random location
				int loc = GetRandomInt(0, 4);
				//Tasks numbers are 27-31, so +27
				PlayerTasks[client][loc + 27] = true;
				
				//total gets +1 task. TaskID 2/2 will be ALWAYS 32
				TotalNumberOfTasks += 1.0;
			}
			
			//Divert Power
			case 18:
			{
				//get random location
				int loc = GetRandomInt(0, 7);
				//Tasks numbers are 33-40, so +33
				PlayerTasks[client][loc + 33] = true;
				
				//total gets +1 task. Task 2/2 will be TaskID + 8
				TotalNumberOfTasks += 1.0;
			}
			
			//Fix Wiring
			case 19:
			{
				//get random start wire box
				int loc = GetRandomInt(0,5);
				//Tasks numbers are 49-54, so +49
				PlayerTasks[client][loc + 49] = true;
				
				//if no need to loop back to first wire
				if(loc <= 3)
				{
					PlayerTasks[client][loc + 49 + 1] = true;
					PlayerTasks[client][loc + 49 + 2] = true;
				}
				if(loc == 4)
				{
					PlayerTasks[client][loc + 49 +1] = true;
					PlayerTasks[client][loc + 49 -4] = true;
				}
				if(loc == 5)
				{
					PlayerTasks[client][loc + 49 -4] = true;
					PlayerTasks[client][loc + 49 -3] = true;
				}
				
				//total gets +2 tasks. All Tasks will be displayed from start. EZ 4 ME
				TotalNumberOfTasks += 2.0;
			}
		}
		
		
	}
}

/*********************** DISPLAY TASKS TO PLAYER *********************/

public Action ShowMyTasks(client, args)
{
	if (Crewmate[client] || CrewmateGhost[client])
	{
		DisplayTasksToClient(client);
	}
}

stock DisplayTasksToClient(client)
{
	if(Crewmate[client] || CrewmateGhost[client])
	{
		char tasks[400];
		char newtask[50];
		char newline[4];
		newline = " \n";
		char taskno[10];
		int taskCounter = 0;
		for(int i=0; i<57; i++)
		{
			//skip the stump tasks
			if(i>=12 && i<=19)
			{
				continue;
			}
			if(PlayerTasks[client][i])
			{
				taskCounter++;
				char task[37];
				task = TaskNames[i];
				
				IntToString(taskCounter, taskno, sizeof(taskno));
				newtask = "";
				
				//add number
				StrCat(newtask, sizeof(newtask), taskno);
				StrCat(newtask, sizeof(newtask), ". ");
				//add task
				StrCat(newtask, sizeof(newtask), task);
				//add newline
				StrCat(newtask, sizeof(newtask), newline);
				//add to main string
				StrCat(tasks, sizeof(tasks), newtask);
				
			}
			
			
		}

		//show tasks on HUD
		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(0.0, 0.0, 5.0, 255, 255, 255, 255);
		ShowSyncHudText(client, hHudText, tasks);
		CloseHandle(hHudText);
		
	}
	else
	{
		PrintToChat(client, "You are not a crewmate!");
	}

	
}

//show starting impostor message to client
stock DisplayImpostorMessage(client)
{
	if(Impostor[client])
	{
		char msg[64];
		
		msg = "You are an Impostor!";

		//show tasks on HUD
		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.3, 5.0, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudText, msg);
		CloseHandle(hHudText);
		
	}

}

//show starting impostor message to client
stock DisplayCrewmateMessage(client)
{
	if(Crewmate[client])
	{
		char msg[64];
		
		msg = "You are a Crewmate!";

		//show tasks on HUD
		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.3, 5.0, 0, 0, 255, 255);
		ShowSyncHudText(client, hHudText, msg);
		CloseHandle(hHudText);
		
	}

}


/*********************** COMPLETE TASK *********************/
//to start off with, just send message
stock CompleteTask(client, task)
{
	PlayerTasks[client][task] = false;
	CompletedTasks[client][task] = true;	
	NumberOfTasksLeft -= 1.0;
	
	CreateTimer(0.5, DisplayTaskDelay, client);
	DisplayTaskCompletionToPlayers();
	
	
}

public Action DisplayTaskDelay(Handle timer, client)
{
	DisplayTasksToClient(client);
}

stock DisplayTaskCompletionToPlayers()
{
	for(int i = 1; i <= MaxClients; i ++)
	{
		if(IsClientValid(i))
		{
			float percentage = (100.0 - (NumberOfTasksLeft/TotalNumberOfTasks)*100.0);
			//%.2f
			char per[3];
			Format(per, sizeof(per), "%.0f", percentage);
			
			char msg[64];
			msg = "Task completion at: ";
			
			StrCat(msg, sizeof(msg), per);
			StrCat(msg, sizeof(msg), "%");
			
			new Handle:hHudText = CreateHudSynchronizer();
			SetHudTextParams(-1.0, 0.1, 1.0, 0, 255, 0, 255);
			ShowSyncHudText(i, hHudText, msg);
			CloseHandle(hHudText);
		}
		
	}
}

/*********************** ADD TASK *********************/
stock AddTask(client, task)
{
	PlayerTasks[client][task] = true;
}

/*********************** VALID PLAYER *********************/
stock bool:IsClientValid(i)
{
	if(i > 0 && i <= MaxClients && IsClientInGame(i))
	{
		return true;
	}
	
	return false;
}

/*********************** SETUP COLOURS AND PLAYERS *********************/
stock SetupPlayers() 
{
	int colourCounter = 0;
	for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) != SPEC_TEAM)
        {
			//Hide kill HUD for player
			ClientCommand(i, "hud_deathnotice_time 0");
			
			//reset counter if needed
			if(colourCounter > 11) colourCounter = 0;
			
			char client_name[64];
			GetClientName(i, client_name, sizeof(client_name));
			char colour_name[64];
			colour_name = Colours[colourCounter];
			ServerCommand("sm_colorize \"%s\" \"%s\"", client_name, colour_name);
			//update counter
			colourCounter++;
			//set client index flag to crewmate
			Crewmate[i] = true;
			
			//hide names
			ClientCommand(i, "hud_showtargetid 0");
        }
    }
	
	
	return;
} 

/*********************** NUMBER OF PLAYERS *********************/ 
//wtf am I doing here?
stock int GetNumberOfPlayers() 
{
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i))
		{
			clientCount++;
		}
	}
	return clientCount;
} 

/*********************** RANDOM PLAYER AS IMPOSTOR *********************/
stock int GetRandomPlayer() 
{
	int[] clients = new int[MaxClients];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			clients[clientCount++] = i;
		}
	}
	
	bool choosing = true;
	int chosenClient = 0;
	while(choosing)
	{
		chosenClient = clients[GetRandomInt(0, clientCount-1)];
		
		//if client isnt already an impostor
		if(!Impostor[chosenClient]) 
		{
			Crewmate[chosenClient] = false;
			Impostor[chosenClient] = true;
			choosing = false;
		}
	}
	return (clientCount == 0) ? -1 : chosenClient;
}


/*********************** SET EXECUTION FLAG *********************/
stock SetExecutionFlag(client)
{
	Execution[client] = true;

	//other flags will need to be changed AFTER the execution!!!
}

/*********************** POST EXECUTION SETUP *********************/
//called if a player dies while having the execution flag OR when exeuction is finished?
stock PostExecution(client)
{
	
	//send Message about what role executed person had
	ExecutionMessage(client);
	 
	//set flags
	Execution[client] = false;
	
	//check if its game over after a small delay. Flags will also be set there
	// no need as its called on every player death? CreateTimer(3.0, CheckDeath, client);

}

/*********************** EXECUTION MESSAGE *********************/
stock ExecutionMessage(client)
{
	char role[64];
	if(Crewmate[client])
	{
		role = " was NOT an Impostor!";
	}
	
	if(Impostor[client])
	{ 
		role = " was an Impostor!";
	}
	
	char message[64];
	GetClientName(client, message, sizeof(message));
		
	StrCat(message, sizeof(message), role);
	
	ServerCommand("msay %s", message);
}

/*********************** CHECK DEATH OF PLAYER *********************/
public Action CheckDeath(Handle timer, victim)
{
	
	//prevent death changing player stats during meetings
	if(MeetingTime) return;
	
	//prevent death changing player stats during execution IF they're not the execution target
	if(ExecutionTime && !Execution[victim])
	{
		return;
	}
	//set execution flags, if needed
	if(Execution[victim])
	{
		PostExecution(victim);
		ExecutionTargetDead();
	}
	//for game to be over, no impostors remain, or impostor number == crewmate number AFTER flag change
	
	//find out who died, go from there
	if(Impostor[victim])
	{
		Impostor[victim] = false;
		ImpostorGhost[victim] = true;
	}
	
	if(Crewmate[victim])
	{
		Crewmate[victim] = false;
		CrewmateGhost[victim] = true;
	}
	
	//get numbers for crewmates and impostors
	int crewmateNum = 0;
	int impostorNum = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Crewmate[i]) crewmateNum++;
		if(Impostor[i]) impostorNum++;
	}

	//Crew wins
	if(impostorNum == 0) 
	{
		DeclareWinner(0); // 0 = crew
	}
	
	//Impostors win
	if(impostorNum >= crewmateNum)
	{
		DeclareWinner(1); // 1 = impostors
	}
	
	
	//Carry on folks
	SpawnGhost(victim);
	return;
}

/*********************** SPAWN GHOST *********************/   
// NEEDS A TRIGGER MULTIPLE WITH NAME:"StripTrigger" TO WORK
stock SpawnGhost(ghost) 
{
	//get ghost name
	char gname[64];
	GetClientName(ghost, gname, sizeof(gname));
	
	//spawn ghost
	ServerCommand("spawn \"%s\"", gname);
	
	//Strip Weapons
	Strip(ghost);
	
	//Turn Invisible
	TurnInvisible(ghost);
	
	//turn collision off
	CreateTimer(0.5, CollGhostDelay, ghost);
	
	//unhide names
	ClientCommand(ghost, "hud_showtargetid 1");
	
	//done
	return;
} 



/*********************** ALPHA SETTINGS *********************/   
//invis
stock TurnInvisible(client) 
{
	char name[64];
	GetClientName(client, name, sizeof(name));
	//int userid = GetClientUserId(client);
	ServerCommand("sm_invis \"%s\" 1", name);
	
	return;
} 

//undo invis
stock TurnVisible(client) 
{
	char name[64];
	GetClientName(client, name, sizeof(name));
	//int userid = GetClientUserId(client);
	ServerCommand("sm_invis \"%s\" 0", name);
	
	return;
}

/*********************** COLLISION SETTINGS *********************/   
public Action CollDelay(Handle timer)
{
	CollOff();
}

public Action CollGhostDelay(Handle timer, int client)
{
	CollOffForOne(client);
}

stock CollOffForOne(int client) 
{
	
	SetEntData(client, g_offsCollisionGroup, 2, 4, true);
	return;
} 

stock CollOff() 
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetEntData(i, g_offsCollisionGroup, 2, 4, true);
		}
	}
	return;
} 

//for some reason, grenades fall through floor after turning collisions off lol
stock CollOn() 
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetEntData(i, g_offsCollisionGroup, 2, 4, false);
		}
	}
	return;
}

/*********************** ROUND OVER METHODS *********************/   
//0 = crew, 1 = impostors
stock DeclareWinner(int winner)
{
	char winmsg[32];
	int winsound = 0;
	if(winner == 0)
	{
		winmsg = "Crewmates win!";
		winsound = 3; //3 is crew win sound
	}
	if(winner == 1)
	{
		winmsg = "Impostors win!";
		winsound = 4; //4 is impostors win sound
	}
	
	ServerCommand("msay %s", winmsg);
	PlaySound(winsound);
	OnMapEnd();
	
}


/*********************** DISPLAY OVERLAY *********************/   
// displays an overlay to all players
stock DisplayOverlay(choice) 
{	
	char entName[32];
	
	if(choice == 1) //body found
	{
		entName = "BodyFoundOverlay";
	}
	if(choice == 2) //emergency button pressed
	{
		entName = "EmergencyButtonOverlay";
	}
	
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "env_screenoverlay")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); 
		if(StrEqual(buffer, entName, false))
		{
			FireEntityOutput(ent, "OnUser1", -1, 0.0); 
			break; // Stop loop
		}        
	}
	
	return;
} 

/*********************** PLAY SOUND *********************/   
// plays sound to all players depending on num passed
stock PlaySound(choice) 
{
	char entName[32];
	
	if(choice == 1) //body found
	{
		entName = "BodyFoundSound";
	}
	if(choice == 2) //emergency button pressed
	{
		entName = "EmergencyButtonSound";
	}
	if(choice == 3) //CrewmateWin sound
	{
		entName = "CrewmateWin";
	}
	if(choice == 4) //ImpostorWin sound
	{
		entName = "ImpostorWin";
	}
	if(choice == 5)
	{
		entName = "MedbayScanSound";
	}
	
		//find the camera  AirlockCamera
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "ambient_generic")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); 
		if(StrEqual(buffer, entName, false))
		{
			FireEntityOutput(ent, "OnUser1", -1, 0.0); 
			break; // Stop loop
		}        
	}
	
	return;
} 

stock UnsilencePlayers()
{
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientValid(i) && (Crewmate[i] || Impostor[i]))
		{
			//unsilence client
			ServerCommand("sm_unsilence %i", i);
		}
		
	}
}

stock UnhideAllNames()
{
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			//unhide names
			ClientCommand(i, "hud_showtargetid 1");
		}
		
	}
}

stock HideNamesForCrewmates()
{
	for(int i = 1; i < MaxClients; i++)
	{
		if(Crewmate[i] && IsClientValid(i))
		{
			//hide names
			ClientCommand(i, "hud_showtargetid 0");
		}
		
	}
}

/******************************************************* MEETING SYSTEMS *****************************************************/   
//start meeting
stock Meeting(type, whoCalled)
{
	//clear prop ragdolls and buttons
	ClearProp_Ragdolls();
	ClearDeadBodyButtons();
	UnhideAllNames();
	UnsilencePlayers();
	
	//Disable the emergency button
	EmergencyButtonEnabled = false;
	if(EmergencyButtonTimer != INVALID_HANDLE)
	{
		KillTimer(EmergencyButtonTimer);
		EmergencyButtonTimer = INVALID_HANDLE;
	}
	EmergencyButtonEnabled = false;
	
	//close door in cafeteria
	CloseDoorMeeting();
	

	//set meeting boolean to true
	MeetingTime = true;
	
	float voteTime = 30.0; //30
	float discussionTime = 45.0; //45
	
	//spawn players and freeze them
	SpawnEveryone();
	//ServerCommand("sm_freeze @all %i", 999);
	
	//display overlay
	DisplayOverlay(type);
	PlaySound(type);
	
	//Display who called the meeting
	char msg[60];
	msg = "Meeting called by: ";
	
	//getname
	char name[60];
	GetClientName(whoCalled, name, sizeof(name));
	
	//format
	StrCat(msg, sizeof(msg), name);
	
	//display message	
	
	ServerCommand("msay %s", msg);
	//ServerCommand("msay \"%s\"", msg);
	
	//discussion timer
	CreateTimer(discussionTime, DiscussionOver, voteTime);
	//stop other game systems
	//stop kill cooldown timers - so impostors dont kill in middle of meeting lol
	//and disable killing in general
	for (int i = 1; i <= MaxClients; i++)
	{
		if(Impostor[i])
		{
			if(KillCooldownTimers[i] != INVALID_HANDLE) KillTimer(KillCooldownTimers[i]);
			KillCooldownTimers[i] = INVALID_HANDLE;
			KillCooldown[i] = true; //dont allow them to kill
			KillCooldownLeft[i] = 0; //just reset it	
		}
	}
	//reset and stop sabotages
	
	SabotageCooldown = true; //dont allow them to sabotage
	SabotageCooldownLeft = 0;  //just reset it
	
	//we'll just ignore door timers. They'll run out before the meeting is over anyway
	
	//resolve sabotages
	ResolveOxygenSabotage(false);
	ResolveReactorSabotage(false);
	
	//unblind crewmates if light sabotage is active
	if(LightsSabotageActive) 
	{
		/*/unblind crewmates
		for(int i = 1; i<=MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				if(Crewmate[i]) UnBlindPlayer(i);
			}
			
		}
		*/
		ServerCommand("sm_blind @all 0");
	}
	
	
	//display discussion time left
	DiscussionTimer = CreateTimer(1.0, DiscussionTimeLeft, 45);
}

public Action DiscussionTimeLeft(Handle timer, int timeleft)
{
	if(timeleft <= 0)
	{
		if(DiscussionTimer != INVALID_HANDLE)
		{
			KillTimer(DiscussionTimer);
			DiscussionTimer = INVALID_HANDLE;
			return;
		}
	}
	
	timeleft--;
	
	char msg[64];
	msg = "Discussion time left: ";
	char msg2[10];
	IntToString(timeleft, msg2, sizeof(msg2));
	StrCat(msg, sizeof(msg), msg2);
	
	new Handle:hHudText = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.8, 1.0, 255, 255, 255, 255);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			ShowSyncHudText(i, hHudText, msg);
		}
	}
	
	CloseHandle(hHudText);
	DiscussionTimer = CreateTimer(1.0, DiscussionTimeLeft, timeleft);
	
}

public Action DiscussionOver(Handle timer, float voteTimef)
{
	if(DiscussionTimer != INVALID_HANDLE)
	{
		KillTimer(DiscussionTimer);
		DiscussionTimer = INVALID_HANDLE;
	}
	
	//in case we end plugin during meeting
	if (!MeetingTime) return;
	
	int voteTime = RoundToNearest(voteTimef);
	voteTime -= 1;
	char msg[20];
	msg = "It is time to vote!";
	ServerCommand("msay %s", msg);
	
	//create menu
	Menu menu = new Menu(Voting_Menu_Callback);
	menu.SetTitle("Cast Your Vote!");
	menu.ExitButton = false;
	menu.VoteResultCallback = VoteOver;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && (Crewmate[i] || Impostor[i]))
		{
			char index[3];
			IntToString(i, index, sizeof(index));
			char name[30];
			GetClientName(i, name, sizeof(name));
			menu.AddItem(index, name);
		}
	}
	menu.AddItem("skip", "Skip");
	
	int clients[MAXPLAYERS + 1];
	int counter = 0;
	//Display Manu to current alive players
	for(int j = 1; j <= MaxClients; j++)
	{
		if(IsClientValid(j) && (!IsFakeClient(j)))
		{
			if(Crewmate[j] || Impostor[j])
			{
				clients[counter] = j;
				counter++;
			}
		}
		
	}
	
	menu.DisplayVote(clients, counter, voteTime);
	
	//Vote timer -- later on make it a handle so you can interrupt it, and call VoteOver() anyway
	//CreateTimer(voteTimef, VoteTimerOver);
	
	VotingTimer = CreateTimer(1.0, VotingTimeLeft, 30);
}

public Action VotingTimeLeft(Handle timer, int timeleft)
{
	if(timeleft <= 0)
	{
		if(VotingTimer != INVALID_HANDLE)
		{
			KillTimer(VotingTimer);
			VotingTimer = INVALID_HANDLE;
			return;
		}
	}
	
	timeleft--;
	
	char msg[64];
	msg = "Voting time left: ";
	char msg2[10];
	IntToString(timeleft, msg2, sizeof(msg2));
	StrCat(msg, sizeof(msg), msg2);
	
	new Handle:hHudText = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.8, 1.0, 255, 255, 255, 255);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			ShowSyncHudText(i, hHudText, msg);
		}
		
	}
	
	CloseHandle(hHudText);
	
	VotingTimer = CreateTimer(1.0, VotingTimeLeft, timeleft);
	
}

public int Voting_Menu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action){
		case MenuAction_Select:
		{
			char item[32];
			char name[64];
			GetClientName(param1, name, sizeof(name));
			PrintToChatAll("%s has voted.", name);
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item, "skip"))
			{
				AddVote("Skip"); //0 is the skip option
			}
			else
			{
				
				AddVote(item); //send string of name over
			}
			
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

//add vote to total
stock AddVote(char votefor[32])
{
	if(StrEqual(votefor, "Skip"))
	{
		TotalVotes[0]++;
		return;
	}
	//get target client index
	int vote = StringToInt(votefor);
	
	if(vote != -1)
	{
		//check if its userid or client index later.....
		TotalVotes[vote]++;
		return;
	}
	PrintToChatAll("This should NOT happen!!! Maybe a client disconnected?");
}

public Action VoteTimerOver(Handle timer)
{
	//in case plugin ends during voting
	if (!MeetingTime)return;
	//VoteOver();
}

public void VoteOver(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	//kill timer
	if(VotingTimer != INVALID_HANDLE)
	{
		KillTimer(VotingTimer);
		VotingTimer = INVALID_HANDLE;
	}
	
	//get results, calculate them
	int voteTotal = TotalVotes[0];
	int voteResult = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		int temp = TotalVotes[i];
		if (temp > voteTotal)
		{
			voteTotal = temp;
			voteResult = i;
		}
	}
	
	//in case skip and execute match, set to skip
	if (voteTotal == TotalVotes[0]) voteResult = 0;
	
	//check for tie between 2 players
	bool tie = false;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (i == voteResult) continue; //skip itself
		if(voteTotal == TotalVotes[i])
		{
			tie = true;
			PrintToChatAll("There was a tie in the voting!");
			break;
		}
	}
	
	//if a tie, vote is skipped
	if(tie) voteResult = 0;
	
	//announce results
	AnnounceVoteResult(voteResult);
	
	//clear vote array
	for (int i = 1; i <= MaxClients; i++)
	{
		TotalVotes[i] = 0;
	}
	
	
	//set execution flags (if needed)
	
	//unfreeze players and let them decide execution, or continue
	//ServerCommand("sm_freeze @all 1");
}

stock AnnounceVoteResult(result)
{
	if(result == 0) //Skip
	{
		//announce skip
		ServerCommand("msay Vote Skipped!");
		MeetingTime = false;
		CreateTimer(3.0, ResumeGame);
	}
	else
	{
		char name[32];
		char msg[32];
		char command[64];
		command = "msay ";
		msg = " was voted out!";
		GetClientName(result, name, sizeof(name));
		StrCat(name, sizeof(name), msg);
		StrCat(command, sizeof(command), name);
		ServerCommand(command);
		SoonToBeDeceased = result;
		ChooseExecution(result);
	}
	
	
}

stock ChooseExecution(soonToBeDeceased)
{	
	//set execution flag
	SetExecutionFlag(soonToBeDeceased);
	
	//create vote menu for execution type
	Menu menu = new Menu(Execution_Menu_Callback);
	menu.SetTitle("Choose Execution Method!");
	menu.AddItem("firingline", "Firing Line");
	menu.AddItem("airlock", "Airlock");
	menu.AddItem("instadeath", "Instant Death");
	menu.ExitButton = false;
	menu.VoteResultCallback = ExecutionResult;
	
	//Display Manu to current alive players
	/*
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && !IsFakeClient(i) && (Crewmate[i] || Impostor[i]))
		{
			menu.Display(i, 10);
		}
	}
	*/
	
	int clients[MAXPLAYERS + 1];
	int counter = 0;
	//Display Manu to current alive players
	for(int j = 1; j <= MaxClients; j++)
	{
		if(IsClientValid(j) && (!IsFakeClient(j)))
		{
			if(Crewmate[j] || Impostor[j])
			{
				clients[counter] = j;
				counter++;
			}
		}
		
	}
	
	menu.DisplayVote(clients, counter, 10);
	
	//Vote timer -- later on make it a handle so you can interrupt it, and call VoteOver() anyway
	//CreateTimer(10.0, ExecutionResult, soonToBeDeceased);
	
}

public int Execution_Menu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action){
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item, "firingline"))
			{
				ExecutionVotes[0]++; //0 is firingline
			}
			else if(StrEqual(item, "airlock"))
			{
				ExecutionVotes[1]++; //1 is airlock
			}
			else if(StrEqual(item, "instadeath"))
			{
				ExecutionVotes[2]++; //2 is instadeath
			}
		}
		case MenuAction_End:
		{
			//dostuff - dunno if it works
			delete menu;
		}
	}
}

public void ExecutionResult(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	//Meeting over at this point
	MeetingTime = false;
	
	//Start Execution boolean -- in case idiots try to kill each other..
	ExecutionTime = true;
	
	//get results, calculate them
	int voteTotal = 0;
	int voteResult = 2; //just assume insta death if noone votes
	for (int i = 0; i <= 2; i++)
	{
		int temp = ExecutionVotes[i];
		if (temp > voteTotal)
		{
			voteTotal = temp;
			voteResult = i;
		}
	}
	

	//clear vote array
	ExecutionVotes[0] = 0;
	ExecutionVotes[1] = 0;
	ExecutionVotes[2] = 0;

	//determine what to do
	switch(voteResult)
	{
		case 0: //firing line
		{
			FiringLineExecution(SoonToBeDeceased);
		}
		case 1: //airlock
		{
			AirlockExecution(SoonToBeDeceased);
		}
		case 2: //instadeath
		{
			//slay SoonToBeDeceased
			InstantDeathExecution(SoonToBeDeceased);
		}
	}
}

stock FiringLineExecution(soonToBeDeceased)
{
	//ServerCommand("sm_freeze @all 1");
	
	//change spawns
	SwitchSpawnsTo_ExecutionRoom();
	
	//spawn all
	SpawnEveryone();
	//ServerCommand("spawn @all");
	
	//teleport soonToBeDeceased to spot
	TeleportToDeathSpot(soonToBeDeceased);
	
	//change spawns back
	CreateTimer(1.0, SwitchSpawnsTo_MeetingRoom);
	
	//enable firearms :>
	ServerCommand("mp_disable_firearms 0");
	
}


stock AirlockExecution(soonToBeDeceased)
{
	//ServerCommand("sm_freeze @all 1");
	
	//teleport soonToBeDeceased
	TeleportToAirlock(soonToBeDeceased);
	//switch everyones view, except soonToBeDeceased
	SwitchToAirlockView(soonToBeDeceased);
	
	//after 10 seconds, switch back to default view
	CreateTimer(10.0, DisableAirlockView);

}

stock InstantDeathExecution(soonToBeDeceased)
{
	ClientCommand(soonToBeDeceased, "kill");
	//after 5 seconds, resume game
	CreateTimer(3.0, ResumeGame);

}

stock TeleportToAirlock(client)
{
	//AirlockExecTeleport
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "point_teleport")) != -1) 
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); 
		if(StrEqual(buffer, "AirlockExecTeleport", false))
		{
			FireEntityOutput(ent, "OnUser1", client, 1.0); 
			break;
		}        
	}
	return;
}

//for showing the airlock execution option
stock SwitchToAirlockView(soonToBeDeceased)
{
	//find the camera  AirlockCamera
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "point_viewcontrol")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); 
		if(StrEqual(buffer, "AirlockCamera", false))
		{
			break; // Stop loop
		}        
	}
	
	//switch to view
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && i != soonToBeDeceased)
		{
			FireEntityOutput(ent, "OnUser1", i, 0.0);
		}
	}
}

public Action DisableAirlockView(Handle timer)
{
	//find the camera AirlockCamera
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "point_viewcontrol")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); 
		if(StrEqual(buffer, "AirlockCamera", false))
		{
			break; // Stop loop
		}        
	}
	
	//timer variable
	float delay = 0.0;
	float delay2 = 0.1;
	//switch to view
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			FireEntityOutput(ent, "OnUser1", i, delay);
			FireEntityOutput(ent, "OnUser2", i, delay2);
			delay += 0.15;
			delay2 += 0.15;
		}
	}
	//the entity might work by itself by using hammer, so no need to code switching back?
}

stock SwitchSpawnsTo_ExecutionRoom()
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1) 
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); 
		if(StrEqual(buffer, "SwitchSpawnButton", false))
		{
			FireEntityOutput(ent, "OnUser1", -1, 0.0);
			break; // Stop loop
		}        
	}
	return;
} 

public Action SwitchSpawnsTo_MeetingRoom(Handle timer)
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(StrEqual(buffer, "SwitchSpawnButton", false))
		{
			FireEntityOutput(ent, "OnUser2", -1, 1.0);
			break; // Stop loop
		}        
	}
	return;
} 

stock TeleportToDeathSpot(client)
{
	//ExecutionTeleport
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "point_teleport")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); 
		if(StrEqual(buffer, "ExecutionTeleport", false))
		{
			FireEntityOutput(ent, "OnUser1", client, 1.0); 
			break;
		}        
	}
	return;
}




//called when the executed is dead
ExecutionTargetDead()
{
	//give, lets say 5 secs, and go back to normal
	CreateTimer(5.0, ExecutionOver);
}

public Action ExecutionOver(Handle timer)
{
	ExecutionTime = false;
	CreateTimer(1.0, ResumeGame);
	ServerCommand("mp_disable_firearms 1");
	//ServerCommand("spawn @all");
}

//fix 
public Action ResumeGame(Handle timer)
{
	
	//open doors
	OpenDoor(0);

	for (int i = 1; i <= MaxClients; i++)
	{
		if(Impostor[i])
		{
			StartKillCooldown(i, DEFAULT_KILL_COOLDOWN);
		}
	}
	
	//reset and stop sabotages
	if(!(LightsSabotageActive || CommsSabotageActive || ReactorSabotageActive || OxygenSabotageActive)) StartSabotageCooldown();
	
	
	//blind crewmates if light sabotage is active
	if(LightsSabotageActive) 
	{
		//blind crewmates back
		for(int i = 1; i <= MaxClients; i++)
		{
			if(Crewmate[i]) BlindPlayer(i);
			if(Impostor[i]) UnBlindPlayer(i);
		}
	}
	
	HideNamesForCrewmates();
	//silence all
	ServerCommand("sm_silence @all");
	
	//start emergency button cooldown
	EmergencyButtonTimer = CreateTimer(float(DEFAULT_EMERGENCY_BUTTON_COOLDOWN), EmergecyButtonCooldownOver);
	EmergencyButtonEnabled = false;

	//finish by spawning all
	SpawnEveryone();
	
	//unfreeze players
	//ServerCommand("sm_freeze @all 1");
}

stock SpawnEveryone()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			if(Crewmate[i] || Impostor[i])
			{
				//get name
				char gname[64];
				GetClientName(i, gname, sizeof(gname));
				
				//spawn
				ServerCommand("spawn \"%s\"", gname);
			}
			if(CrewmateGhost[i] || ImpostorGhost[i])
			{
				SpawnGhost(i);
			}
		}
		
	}
	CreateTimer(0.5, CollDelay);
}


/***************************************** EMERGENCY BUTTON ***************************************/

public Action EmergecyButtonCooldownOver(Handle timer)
{
	if (EmergencyButtonTimer != INVALID_HANDLE)KillTimer(EmergencyButtonTimer);
	EmergencyButtonTimer = INVALID_HANDLE;
	if(SabotageActive)return; //no need to do anything, sabotage resolved will enable the button
	
	EmergencyButtonEnabled = true;
}


/***************************************** CREWMANTE TASKS ***************************************/
//
/*********************** CALIBRATE DISTRIBUTOR *********************/   
//DistributorGoalAngle
CreateDistributorAngle()
{
	int rand = GetRandomInt(0, 11);
	DistributorGoalAngle = rand * 30;  //0,30,60,90,120,180,210,240,270,300,330
}

StartCalibrateDistributor(client)
{
	bool diff = false;
	while(!diff)
	{
		int rand = GetRandomInt(0, 11);
		if(rand != DistributorGoalAngle *30)
		{
			DistributorPlayerAngle[client] = rand * 30;
			diff = true; //simply to stop shit errors
			break;
		}
	}
	SendCalibrateDistributorMenu(client);
}

SendCalibrateDistributorMenu(client)
{
	Menu menu = new Menu(CalibrateDistributor_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	
	int curAng = DistributorPlayerAngle[client];
	int goalAng = DistributorGoalAngle;
	
	char stCAng[8];
	char stGAng[8];
	IntToString(curAng, stCAng, sizeof(stCAng));
	IntToString(goalAng, stGAng, sizeof(stGAng));
	
	char title[100];
	title = "Stop when angles match: \nCurrent: ";
	StrCat(title, sizeof(title), stCAng);
	StrCat(title, sizeof(title), "°\nGoal: ");
	StrCat(title, sizeof(title), stGAng);
	StrCat(title, sizeof(title), "°");
 
	menu.SetTitle(title);
	
	menu.AddItem("stop", "STOP");

	menu.Display(client, 1);
	DistributorTimers[client] = CreateTimer(1.2, UpdateDistributor, client);
	
}

public Action UpdateDistributor(Handle timer, client)
{
	if (DistributorTimers[client] != INVALID_HANDLE)KillTimer(DistributorTimers[client]);
	DistributorTimers[client] = INVALID_HANDLE;
	
	DistributorPlayerAngle[client] += 30;
	if(DistributorPlayerAngle[client] >= 360)
	{
		DistributorPlayerAngle[client] = 0;
	}
	SendCalibrateDistributorMenu(client);
}


public int CalibrateDistributor_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			if(DistributorTimers[param1] != INVALID_HANDLE)
			{
				KillTimer(DistributorTimers[param1]);
				DistributorTimers[param1] = INVALID_HANDLE;
			}
			
			if(DistributorPlayerAngle[param1] == DistributorGoalAngle)
			{
				CompleteTask(param1, CalibrateDistributor);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


/*********************** ALIGN LOWER ENGINE *********************/   
// 
CreateLowerEngineAngle()
{
	int rand = GetRandomInt(0, 35);
	LowerEngineAngleGoal = rand * 10;
}

StartAlignLEngine(client)
{
	bool diff = false;
	while(!diff)
	{
		int rand = GetRandomInt(0, 35);
		rand = rand * 10;
		if(rand != LowerEngineAngleGoal)
		{
			LowerEnginePlayerAngle[client] = rand;
			diff = true; //simply to stop shit errors
			break;
		}
	}
	SendAlignLowerEngineMenu(client);
	
}

//SteeringPlayerAngle[client] and SteeringGoalAngle
SendAlignLowerEngineMenu(client)
{
	Menu menu = new Menu(LowerEngineAngle_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	
	int curAng = LowerEnginePlayerAngle[client];
	int goalAng = LowerEngineAngleGoal;
	
	char stCAng[8];
	char stGAng[8];
	IntToString(curAng, stCAng, sizeof(stCAng));
	IntToString(goalAng, stGAng, sizeof(stGAng));
	
	char title[100];
	title = "Align engine to angle: \nCurrent: ";
	StrCat(title, sizeof(title), stCAng);
	StrCat(title, sizeof(title), "°\nGoal: ");
	StrCat(title, sizeof(title), stGAng);
	StrCat(title, sizeof(title), "°");
 
	menu.SetTitle(title);
	

	menu.AddItem("plus10", "+ 10°");
	menu.AddItem("plus40", "+ 40°");
	menu.AddItem("plus100", "+ 100°");
	menu.AddItem("minus10", "- 10°");
	menu.AddItem("minus40", "- 40°");
	menu.AddItem("minus100", "- 100°");

	
	menu.Display(client, 5);
	
}

public int LowerEngineAngle_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			switch(param2)
			{
				case(0): //+10
				{
					int newAng = LowerEnginePlayerAngle[param1] + 10;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					LowerEnginePlayerAngle[param1] = newAng;
					if(!CheckLowerEngineAngle(param1))
					{
						SendAlignLowerEngineMenu(param1);
					}
					
				}
				case(1): //+40
				{
					int newAng = LowerEnginePlayerAngle[param1] + 40;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					LowerEnginePlayerAngle[param1] = newAng;
					if(!CheckLowerEngineAngle(param1))
					{
						SendAlignLowerEngineMenu(param1);
					}
				}
				case(2): //+100
				{
					int newAng = LowerEnginePlayerAngle[param1] + 100;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					LowerEnginePlayerAngle[param1] = newAng;
					if(!CheckLowerEngineAngle(param1))
					{
						SendAlignLowerEngineMenu(param1);
					}
				}
				case(3): //-10
				{
					int newAng = LowerEnginePlayerAngle[param1] - 10;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					LowerEnginePlayerAngle[param1] = newAng;
					if(!CheckLowerEngineAngle(param1))
					{
						SendAlignLowerEngineMenu(param1);
					}
				}
				case(4): //-40
				{
					int newAng = LowerEnginePlayerAngle[param1] - 40;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					LowerEnginePlayerAngle[param1] = newAng;
					if(!CheckLowerEngineAngle(param1))
					{
						SendAlignLowerEngineMenu(param1);
					}
				}
				case(5): //-100
				{
					int newAng = LowerEnginePlayerAngle[param1] - 100;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					LowerEnginePlayerAngle[param1] = newAng;
					if(!CheckLowerEngineAngle(param1))
					{
						SendAlignLowerEngineMenu(param1);
					}
				}
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock bool CheckLowerEngineAngle(client)
{
	if(LowerEnginePlayerAngle[client] == LowerEngineAngleGoal)
	{
		CompleteTask(client, AlignLowerEngine);
		LowerEnginePlayerAngle[client] = 0;
		return true;
	}
	return false;
}

/*********************** ALIGN UPPER ENGINE *********************/   
// 
CreateUpperEngineAngle()
{
	int rand = GetRandomInt(0, 35);
	UpperEngineAngleGoal = rand * 10;
}

StartAlignUEngine(client)
{
	bool diff = false;
	while(!diff)
	{
		int rand = GetRandomInt(0, 35);
		rand = rand * 10;
		if(rand != UpperEngineAngleGoal)
		{
			UpperEnginePlayerAngle[client] = rand;
			diff = true; //simply to stop shit errors
			break;
		}
	}
	SendAlignUpperEngineMenu(client);
	
}

//SteeringPlayerAngle[client] and SteeringGoalAngle
SendAlignUpperEngineMenu(client)
{
	Menu menu = new Menu(UpperEngineAngle_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	
	int curAng = UpperEnginePlayerAngle[client];
	int goalAng = UpperEngineAngleGoal;
	
	char stCAng[8];
	char stGAng[8];
	IntToString(curAng, stCAng, sizeof(stCAng));
	IntToString(goalAng, stGAng, sizeof(stGAng));
	
	char title[100];
	title = "Align engine to angle: \nCurrent: ";
	StrCat(title, sizeof(title), stCAng);
	StrCat(title, sizeof(title), "°\nGoal: ");
	StrCat(title, sizeof(title), stGAng);
	StrCat(title, sizeof(title), "°");
 
	menu.SetTitle(title);
	

	menu.AddItem("plus10", "+ 10°");
	menu.AddItem("plus40", "+ 40°");
	menu.AddItem("plus100", "+ 100°");
	menu.AddItem("minus10", "- 10°");
	menu.AddItem("minus40", "- 40°");
	menu.AddItem("minus100", "- 100°");

	
	menu.Display(client, 5);
	
}

public int UpperEngineAngle_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			switch(param2)
			{
				case(0): //+10
				{
					int newAng = UpperEnginePlayerAngle[param1] + 10;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					UpperEnginePlayerAngle[param1] = newAng;
					if(!CheckUpperEngineAngle(param1))
					{
						SendAlignUpperEngineMenu(param1);
					}
					
				}
				case(1): //+40
				{
					int newAng = UpperEnginePlayerAngle[param1] + 40;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					UpperEnginePlayerAngle[param1] = newAng;
					if(!CheckUpperEngineAngle(param1))
					{
						SendAlignUpperEngineMenu(param1);
					}
				}
				case(2): //+100
				{
					int newAng = UpperEnginePlayerAngle[param1] + 100;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					UpperEnginePlayerAngle[param1] = newAng;
					if(!CheckUpperEngineAngle(param1))
					{
						SendAlignUpperEngineMenu(param1);
					}
				}
				case(3): //-10
				{
					int newAng = UpperEnginePlayerAngle[param1] - 10;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					UpperEnginePlayerAngle[param1] = newAng;
					if(!CheckUpperEngineAngle(param1))
					{
						SendAlignUpperEngineMenu(param1);
					}
				}
				case(4): //-40
				{
					int newAng = UpperEnginePlayerAngle[param1] - 40;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					UpperEnginePlayerAngle[param1] = newAng;
					if(!CheckUpperEngineAngle(param1))
					{
						SendAlignUpperEngineMenu(param1);
					}
				}
				case(5): //-100
				{
					int newAng = UpperEnginePlayerAngle[param1] - 100;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					UpperEnginePlayerAngle[param1] = newAng;
					if(!CheckUpperEngineAngle(param1))
					{
						SendAlignUpperEngineMenu(param1);
					}
				}
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock bool CheckUpperEngineAngle(client)
{
	if(UpperEnginePlayerAngle[client] == UpperEngineAngleGoal)
	{
		CompleteTask(client, AlignUpperEngine);
		UpperEnginePlayerAngle[client] = 0;
		return true;
	}
	return false;
}

/*********************** STABILIZE STEERING *********************/   
// 
CreateSteeringAngle()
{
	int rand = GetRandomInt(0, 35);
	SteeringGoalAngle = rand * 10;
}

StartStabiliseSteering(client)
{
	bool diff = false;
	while(!diff)
	{
		int rand = GetRandomInt(0, 35);
		rand = rand * 10;
		if(rand != SteeringGoalAngle)
		{
			SteeringPlayerAngle[client] = rand;
			diff = true; //simply to stop shit errors
			break;
		}
	}
	SendStabiliseSteeringMenu(client);
	
}

//SteeringPlayerAngle[client] and SteeringGoalAngle
SendStabiliseSteeringMenu(client)
{
	Menu menu = new Menu(StabilizeSteering_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	
	int curAng = SteeringPlayerAngle[client];
	int goalAng = SteeringGoalAngle;
	
	char stCAng[8];
	char stGAng[8];
	IntToString(curAng, stCAng, sizeof(stCAng));
	IntToString(goalAng, stGAng, sizeof(stGAng));
	
	char title[100];
	title = "Match the angle: \nCurrent: ";
	StrCat(title, sizeof(title), stCAng);
	StrCat(title, sizeof(title), "°\nGoal: ");
	StrCat(title, sizeof(title), stGAng);
	StrCat(title, sizeof(title), "°");
 
	menu.SetTitle(title);
	

	menu.AddItem("plus10", "+ 10°");
	menu.AddItem("plus40", "+ 40°");
	menu.AddItem("plus100", "+ 100°");
	menu.AddItem("minus10", "- 10°");
	menu.AddItem("minus40", "- 40°");
	menu.AddItem("minus100", "- 100°");

	
	menu.Display(client, 5);
	
}

stock int IntAbs(val)
{
    if(val < 0)
    {
        return -val;
    }
    return val;
}

public int StabilizeSteering_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			switch(param2)
			{
				case(0): //+10
				{
					int newAng = SteeringPlayerAngle[param1] + 10;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					SteeringPlayerAngle[param1] = newAng;
					if(!CheckSteering(param1))
					{
						SendStabiliseSteeringMenu(param1);
					}
					
				}
				case(1): //+40
				{
					int newAng = SteeringPlayerAngle[param1] + 40;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					SteeringPlayerAngle[param1] = newAng;
					if(!CheckSteering(param1))
					{
						SendStabiliseSteeringMenu(param1);
					}
				}
				case(2): //+100
				{
					int newAng = SteeringPlayerAngle[param1] + 100;
					if (newAng > 359)
					{
						newAng = IntAbs(newAng - 360);
					}
					SteeringPlayerAngle[param1] = newAng;
					if(!CheckSteering(param1))
					{
						SendStabiliseSteeringMenu(param1);
					}
				}
				case(3): //-10
				{
					int newAng = SteeringPlayerAngle[param1] - 10;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					SteeringPlayerAngle[param1] = newAng;
					if(!CheckSteering(param1))
					{
						SendStabiliseSteeringMenu(param1);
					}
				}
				case(4): //-40
				{
					int newAng = SteeringPlayerAngle[param1] - 40;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					SteeringPlayerAngle[param1] = newAng;
					if(!CheckSteering(param1))
					{
						SendStabiliseSteeringMenu(param1);
					}
				}
				case(5): //-100
				{
					int newAng = SteeringPlayerAngle[param1] - 100;
					if (newAng < 0)
					{
						newAng = newAng + 360;
					}
					SteeringPlayerAngle[param1] = newAng;
					if(!CheckSteering(param1))
					{
						SendStabiliseSteeringMenu(param1);
					}
				}
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock bool CheckSteering(client)
{
	if(SteeringPlayerAngle[client] == SteeringGoalAngle)
	{
		CompleteTask(client, StabiliseSteering);
		SteeringPlayerAngle[client] = 0;
		return true;
	}
	return false;
}


/*********************** CHART COURSE *********************/   
// 
//input coords style: 154,265 
CreateChartCourseNumbers()
{
	char coords1[10];
	char coords2[10];
	
	for(int i = 0; i < 3; i++)
	{
		int rand = GetRandomInt(1, 8);
		char temp[3];
		IntToString(rand, temp, sizeof(temp));
		StrCat(coords1, sizeof(coords1), temp);
		
		ChartCourseCoordinates[i] = rand;
	}
	for(int i = 0; i < 3; i++)
	{
		int rand = GetRandomInt(1, 8);
		char temp[3];
		IntToString(rand, temp, sizeof(temp));
		StrCat(coords2, sizeof(coords2), temp);
		
		ChartCourseCoordinates[i+3] = rand;
	}
	Coordinates1 = coords1;
	Coordinates2 = coords2;
	
}

stock SendChartCourseMenu(client)
{
	Menu menu = new Menu(ChartCourse_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	
	char title[35];
	title = "Input coordinates: ";
	StrCat(title, sizeof(title), Coordinates1);
	StrCat(title, sizeof(title), ", ");
	StrCat(title, sizeof(title), Coordinates2);
 
	menu.SetTitle(title);
	
	for(int i = 1; i <= 8; i++)
	{
		char text[10];
		text = "Input ";
		char num[3];
		IntToString(i, num, sizeof(num));
		StrCat(text, sizeof(text), num);
		
		menu.AddItem(num, text);
	}
	
	menu.Display(client, 5);
}

public int ChartCourse_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			int choice = param2 + 1;
			int plprg = ChartCoursePlayerProgress[param1];
			int courcoord = ChartCourseCoordinates[plprg];
			if(choice == courcoord)
			{
				ChartCoursePlayerProgress[param1]++;
				
				if(ChartCoursePlayerProgress[param1] == 6)
				{
					ChartCoursePlayerProgress[param1] = 0;
					CompleteTask(param1, ChartCourse);
				}
				else
				{
					SendChartCourseMenu(param1);
				}
			}
			else
			{
				
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

/*********************** FIXING WIRES *********************/   
//
stock SendWiresMenu(client)
{//WiresPlayerProgress
	
	Menu menu = new Menu(Wires_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	
	int nextCol = -1;
	bool found = true;
	while(found)
	{
		int rand = GetRandomInt(0, 3);
		if(!WiresPlayerProgress[client][rand])
		{
			nextCol = rand;
			PlayerNextWire[client] = rand;
			found = false; //simply to get rid of that shitty warning
			break;
		}
	}
	
	char colName[20];
	colName = ColoursArray[nextCol];
	
	char title[40];
	title = "Connect the ";
	StrCat(title, sizeof(title), colName);
	menu.SetTitle(title);
	
	//randomise number array
	SortIntegers(NumberArray, 8, Sort_Random);
	
	menu.AddItem("0", "Red Wire");
	menu.AddItem("1", "Blue Wire");
	menu.AddItem("2", "Green Wire");
	menu.AddItem("3", "Yellow Wire");
	
	menu.Display(client, 5);
	
}

public int Wires_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			if(param2 == PlayerNextWire[param1])   
			{
				WiresPlayerProgress[param1][param2] = true;
				bool done = true;
				for(int i = 0; i < 4; i++)
				{
					if(!WiresPlayerProgress[param1][i]) 
					{
						done = false;
						break;
					}
				}
				
				if(done)
				{
					CompleteTask(param1, WiresPlayerLocation[param1]);
					WiresPlayerProgress[param1][0] = false;
					WiresPlayerProgress[param1][1] = false;
					WiresPlayerProgress[param1][2] = false;
					WiresPlayerProgress[param1][3] = false;
				}
				else
				{
					SendWiresMenu(param1);
				}
			}
			else
			{
				//play wrong sound? 
				SendWiresMenu(param1);
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


/*********************** UNLOCK MANIFOLDS *********************/   
//
stock SendManifoldsMenu(client)
{
	
	Menu menu = new Menu(Manifolds_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
 
	menu.SetTitle("Select buttons in order");
	
	//randomise number array
	SortIntegers(NumberArray, 8, Sort_Random);
	
	for(int i = 0; i < 8; i++)
	{
		char text[10];
		text = "Button ";
		char num[3];
		IntToString(NumberArray[i], num, sizeof(num));
		StrCat(text, sizeof(text), num);
		
		menu.AddItem(num, text);
	}
	
	menu.Display(client, 5);
	
}

public int Manifolds_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			char item[10];
			char rightchoice[10];
			int correctChoice = ManifoldsPlayerProgress[param1] + 1;
			IntToString(correctChoice, rightchoice, sizeof(rightchoice));
			menu.GetItem(param2, item, sizeof(item));

			if(StrEqual(item, rightchoice))   
			{
				ManifoldsPlayerProgress[param1]++;
				if(StrEqual(rightchoice, "8"))
				{
					CompleteTask(param1, UnlockManifolds);
					ManifoldsPlayerProgress[param1] = 0;
				}
				else
				{
					SendManifoldsMenu(param1);
				}
			}
			else
			{
				//play wrong sound? 
				ManifoldsPlayerProgress[param1] = 0;
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

/*********************** START REACTOR *********************/   
//

stock CreateStartReactorNumbers()
{
	int string[4];
	for(int i = 0; i < 4 ; i++)
	{
		int rand = GetRandomInt(1, 8);
		string[i] = rand;
	}
	StartReactorNumbers = string;
	
	//now fill in the stages     1,2,3,4 > 1>1,1,2>1,1,2,1,2,3>1,1,2,1,2,3,1,2,3,4 TOTAL STEPS = 1+3+6+10 = 20   n^2 - (n-1)^2   OR 1,> 1,2 > 1,2,3 > 1,2,3,4 = 10
	int counter = 0;
	for(int i = 0; i < 4; i++) //i = 3  srn 0 1 2 3
	{
		for(int j = 0; j <= i; j++) //i3j0c1,i3j1c2,
		{
			StartReactorStages[counter] = StartReactorNumbers[j];
			counter++;  //1, 1,2, 1,2,3 1,2,3,4
		}
	}
}

stock char GetStartReactorTitle(client)
{
	int progress = StartReactorPlayerProgress[client];
	char title[10];
	if(progress == 0)  //1
	{
		IntToString(StartReactorNumbers[progress], title, sizeof(title));
	}
	else if (progress > 0 && progress < 3)  //1,2
	{
		for(int i = 0; i < 2; i++)
		{
			char temp[3];
			IntToString(StartReactorNumbers[i], temp, sizeof(temp));
			StrCat(title, sizeof(title), temp);
		}
		
	}
	else if (progress >= 3 && progress < 6) //1,2,3
	{
		for(int i = 0; i < 3; i++)
		{
			char temp[3];
			IntToString(StartReactorNumbers[i], temp, sizeof(temp));
			StrCat(title, sizeof(title), temp);
		}
	}
	else  if (progress >= 6) //1,2,3,4
	{
		for(int i = 0; i < 4; i++)
		{
			char temp[3];
			IntToString(StartReactorNumbers[i], temp, sizeof(temp));
			StrCat(title, sizeof(title), temp);
		}
	}
	return title;
}

stock StartReactorTask(client)
{
	SendStartReactorMenu(client);
}

stock SendStartReactorMenu(client)
{
	
	Menu menu = new Menu(Reactor_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	char title[10];  
	title = GetStartReactorTitle(client);
	menu.SetTitle("Input: %s", title);
	
	for(int i = 1; i <= 8; i++)
	{
		char text[10];  
		text = "Button ";
		char button[3];
		IntToString(i, button, sizeof(button));
		StrCat(text, sizeof(text), button);
		
		menu.AddItem(button, text);
	}
	
	menu.Display(client, 5);
	
}

public int Reactor_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{

			int progress = StartReactorPlayerProgress[param1];
			int correctChoiceI = StartReactorStages[progress];
			int choice = param2 + 1;
			
			if(choice == correctChoiceI)
			{
				progress++;
				StartReactorPlayerProgress[param1]++;
				if(progress >= 10)
				{
					CompleteTask(param1, StartReactor);
					StartReactorPlayerProgress[param1] = 0;
				}
				else
				{
					SendStartReactorMenu(param1);
				}
			}
			else
			{
				//play wrong sound? 
				StartReactorPlayerProgress[param1] = 0;
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


/*********************** CLEAR ASTEROIDS *********************/   
//
stock StartClearAsteroids(client)
{
	//get random filter values
	for(int i = 0; i < 20 ; i++)
	{
		int rand = GetRandomInt(0, 2);
		if(rand == 0)
		{
			AsteroidArray[client][i] = true; //☄   false = ⭐⋆✯✦☆✶ set of
		}
		
	}
	AsteroidArray[client][4] = true;
	SendAsteroidsMenu(client);
}

stock SendAsteroidsMenu(client)
{
	
	Menu menu = new Menu(Asteroid_Callback);
	menu.SetTitle("☄ Clear out the asteroids ☄");
	
	char space[30];

	//⭐⋆⭐☄⋆
	
	for(int i = 0; i < 20; i++)
	{
		space = "";
		if(AsteroidArray[client][i]) 
		{
			int rpos = GetRandomInt(0, 5);
			for(int j = 0; j < 6; j++)
			{
				if(j == rpos)
				{
					StrCat(space, sizeof(space), "☄");
				}
				else
				{
					StrCat(space, sizeof(space), "✶");
				}
			}
			menu.AddItem("asteroid", space);
		}
		else 
		{
			menu.AddItem("empty", "✶✶✶✶✶✶");
		}
	}
	
	menu.Display(client, 5);
	
}

public int Asteroid_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item, "empty"))   
			{
				SendAsteroidsMenu(param1);
			}
			else if(StrEqual(item, "asteroid"))
			{
				AsteroidArray[param1][param2] = false;
				CheckAsteroid(param1);
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock CheckAsteroid(client)
{
	for(int i = 0; i < 20; i++)
	{
		if(AsteroidArray[client][i])
		{
			SendAsteroidsMenu(client);
			return;
		}
	}
	CompleteTask(client, ClearAsteroids);
}

/*********************** O2 *********************/   
//
stock StartFilterMenu(client)
{
	//get random filter values
	for(int i = 0; i < 20 ; i++)
	{
		int rand = GetRandomInt(0, 4);
		if(rand == 0)
		{
			FilterArray[client][i] = true; //##の##
		}
		
		
	}
	FilterArray[client][6] = true;
	
	SendFilterMenu(client);
}

stock SendFilterMenu(client)
{
	
	Menu menu = new Menu(Filter_Callback);
	menu.SetTitle("の Clean up the leaves の");
	
	char filter[30];
	//char leaf[3] = "の";
	
	for(int i = 0; i < 20; i++)
	{
		filter = "";
		if(FilterArray[client][i]) 
		{
			int rpos = GetRandomInt(0, 5);
			for(int j = 0; j < 6; j++)
			{
				if(j == rpos)
				{
					StrCat(filter, sizeof(filter), "の");
				}
				else
				{
					StrCat(filter, sizeof(filter), "#");
				}
			}
			menu.AddItem("leaf", filter);
		}
		else 
		{
			menu.AddItem("empty", "######");
		}
	}
	
	menu.Display(client, 5);
	
}

public int Filter_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item, "empty"))   
			{
				SendFilterMenu(param1);
			}
			else if(StrEqual(item, "leaf"))
			{
				FilterArray[param1][param2] = false;
				CheckFilter(param1);
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock CheckFilter(client)
{
	for(int i = 0; i < 20; i++)
	{
		if(FilterArray[client][i])
		{
			SendFilterMenu(client);
			return;
		}
	}
	CompleteTask(client, CleanO2Filter);
}


/*********************** SHIELDS *********************/   
//
stock StartShieldMenu(client)
{
	//get random shields values
	for(int i = 0; i < 4; i++)
	{
		int rand = GetRandomInt(0, 4) * 25;
		ShieldsStage[client][i] = 100 - rand;
	}
	
	SendShieldMenu(client);
	
}

stock SendShieldMenu(client)
{
	
	Menu menu = new Menu(Shields_Callback);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	menu.SetTitle("Shield Power");
	
	char percent[5] = "%";
	
	for(int i = 0; i < 4; i++)
	{
		char display[10];
		IntToString(ShieldsStage[client][i], display, sizeof(display));
		StrCat(display, sizeof(display), percent);
		
		menu.AddItem("", display);
	}
	
	menu.Display(client, 4);
	
}


public int Shields_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	//param1 is client, param2 is choice
	switch(action){
		case MenuAction_Select:
		{	
			if(param2 <= 4)
			{
				if (ShieldsStage[param1][param2] < 100){ShieldsStage[param1][param2] += 25;}
				CheckShields(param1);
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock CheckShields(client)
{
	for(int i = 0; i < 4; i++)
	{
		if(ShieldsStage[client][i] != 100)
		{
			SendShieldMenu(client);
			return;
		}
	}
	CompleteTask(client, PrimeShields);
}

/*********************** MEDBAY SCANNER *********************/   
//
public Action ScannerTimerOver(Handle timer, client)
{
	if (ScannerTimer != INVALID_HANDLE)KillTimer(ScannerTimer);
	ScannerTimer = INVALID_HANDLE;
	
	//timer will get killed if crewmate leaves early.
	//if not it means task is complete.
	CompleteTask(client, SubmitScan);
	
	CrewmateEnteredScanner = false;
	CrewmateOnScanner = -1;
	
	//turn off light
	FireEntityOutput(ScannerEntID, "OnUser3", client, 0.1); //  trigger the output on an entity
	
	return Plugin_Continue;
}


/*********************** MEDBAY SAMPLE *********************/   
//
public Action SampleTimerOver(Handle timer, client)
{
	if (SampleTimer[client] != INVALID_HANDLE)KillTimer(SampleTimer[client]);
	SampleTimer[client] = INVALID_HANDLE;
	
	PrintToChat(client, "Sample data is ready!");
	AddTask(client, InspectSampleSecond);

	return Plugin_Continue;
}

//called every second to update time on player's hud
public Action SampleTimerUpdate(Handle timer, client)
{
	//SampleTimeLeft
	if(SampleTimeLeft[client] <= 0 || PlayerTasks[client][InspectSampleSecond])
	{
		if (SampleUpdateTimer[client] != INVALID_HANDLE)KillTimer(SampleUpdateTimer[client]);
		SampleUpdateTimer[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	
	char msg[64];
	msg = "Sample Data ready in: ";
	char msg2[10];
	IntToString(SampleTimeLeft[client], msg2, sizeof(msg2));
	StrCat(msg, sizeof(msg), msg2);

	new Handle:hHudText = CreateHudSynchronizer();
	SetHudTextParams(0.0, 0.5, 1.0, 0, 0, 255, 255);
	ShowSyncHudText(client, hHudText, msg);
	CloseHandle(hHudText);
	
	SampleTimeLeft[client]--;
	//call next timer
	CreateTimer(1.0, SampleTimerUpdate, client);

	return Plugin_Continue;
}

/*********************** FUELING TASKS*********************/   

public Action TryToFillCanLEng(Handle timer, client)
{
	int PlayerFuel = FuelInCan[client];
	if(!TouchingCans[client] || PlayerFuel >= 100)
	{
		return Plugin_Handled;
	}
	else
	{
		FuelInCan[client] += 20;
		//call next timer only if can isnt full now
		if(FuelInCan[client] < 100)
		{
			CreateTimer(1.0, TryToFillCanLEng, client);
		}
		//else complete task
		else
		{
			CompleteTask(client, FuelLowerEngineFirst);
			AddTask(client, FuelLowerEngineSecond);
		}
		
		
		//show progress on HUD
		char msg[64];
		msg = "Fuel Progress: ";
		char msg2[10];
		IntToString(FuelInCan[client], msg2, sizeof(msg2));
		StrCat(msg, sizeof(msg), msg2);
		char msg3[3];
		msg3 = "%%";
		StrCat(msg, sizeof(msg), msg3);

		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.2, 1.0, 255, 0, 255, 255);
		ShowSyncHudText(client, hHudText, msg);
		CloseHandle(hHudText);
		
	}
	
	return Plugin_Continue;
}
public Action TryToFillCanUEng(Handle timer, client)
{

	int PlayerFuel = FuelInCan[client];
	if(!TouchingCans[client] || PlayerFuel >= 100)
	{
		return Plugin_Handled;
	}
	else
	{
		FuelInCan[client] += 20;
		//call next timer only if can isnt full now
		if(FuelInCan[client] < 100)
		{
			CreateTimer(1.0, TryToFillCanUEng, client);
		}
		//else complete task
		else
		{
			CompleteTask(client, FuelUpperEngineFirst);
			AddTask(client, FuelUpperEngineSecond);
		}
		
		
		//show progress on HUD
		char msg[64];
		msg = "Fuel Progress: ";
		char msg2[10];
		IntToString(FuelInCan[client], msg2, sizeof(msg2));
		StrCat(msg, sizeof(msg), msg2);
		char msg3[3];
		msg3 = "%%";
		StrCat(msg, sizeof(msg), msg3);

		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.2, 1.0, 255, 0, 255, 255);
		ShowSyncHudText(client, hHudText, msg);
		CloseHandle(hHudText);
		
	}
	
	return Plugin_Continue;
}

public Action TryToFillUpperEng(Handle timer, client)
{
	if(!TouchingUEng[client])
	{
		return Plugin_Handled;
	}
	else
	{
		FuelInCan[client] -= 10;
		//call next timer only if can isnt full now
		if(FuelInCan[client] > 0)
		{
			CreateTimer(1.0, TryToFillUpperEng, client);
		}
		//else complete task
		else
		{
			Fueling[client] = false;
			CompleteTask(client, FuelUpperEngineSecond);
		}
		
		
		//show progress on HUD
		char msg[64];
		msg = "Fuel Progress: ";
		char msg2[10];
		int adjFuel = 100 - FuelInCan[client];
		IntToString(adjFuel, msg2, sizeof(msg2));
		StrCat(msg, sizeof(msg), msg2);
		char msg3[3];
		msg3 = "%%";
		StrCat(msg, sizeof(msg), msg3);

		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.2, 1.0, 255, 0, 255, 255);
		ShowSyncHudText(client, hHudText, msg);
		CloseHandle(hHudText);
		
	}
	
	return Plugin_Continue;
}

public Action TryToFillLowerEng(Handle timer, client)
{
	if(!TouchingLEng[client])
	{
		return Plugin_Handled;
	}
	else
	{
		FuelInCan[client] -= 10;
		//call next timer only if can isnt empty
		if(FuelInCan[client] > 0)
		{
			CreateTimer(1.0, TryToFillLowerEng, client);
		}
		//else complete task
		else
		{
			Fueling[client] = false;
			CompleteTask(client, FuelLowerEngineSecond);
		}
		
		
		//show progress on HUD
		char msg[64];
		msg = "Fuel Progress: ";
		char msg2[10];
		IntToString(FuelInCan[client], msg2, sizeof(msg2));
		StrCat(msg, sizeof(msg), msg2);
		char msg3[3];
		msg3 = "%%";
		StrCat(msg, sizeof(msg), msg3);

		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.2, 1.0, 255, 0, 255, 255);
		ShowSyncHudText(client, hHudText, msg);
		CloseHandle(hHudText);
		
	}
	
	return Plugin_Continue;
}
//
/*********************** UPLOAD TASKS*********************/   
public Action UploadFinished(Handle timer, client)
{
	if (UploadTimers[client] != INVALID_HANDLE)KillTimer(UploadTimers[client]);
	UploadTimers[client] = INVALID_HANDLE;
	
	AddTask(client, UploadDataAdmin);
	for(int i = DownloadDataCafeteria; i<DownloadDataElectric; i++)
	{
		if(PlayerTasks[client][i])
		{
			CompleteTask(client, i);
		}
	}

	return Plugin_Continue;
}

public Action UploadUpdate(Handle timer, client)
{
	if(!TouchingUp[client] || UploadTimeLeft[client] < 0)
	{
		if(UploadTimers[client] != INVALID_HANDLE) KillTimer(UploadTimers[client]);
		UploadTimers[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	else
	{
		int timeleft = UploadTimeLeft[client];
		UploadTimeLeft[client]--;
		//call next timer only if can isnt empty
		if(timeleft > 0)
		{
			CreateTimer(1.0, UploadUpdate, client);
		}
		
		
		//show progress on HUD
		char msg[64];
		msg = "Download Progress: ";
		char msg2[10];
		timeleft = (9 - UploadTimeLeft[client])*10;
		IntToString(timeleft, msg2, sizeof(msg2));
		StrCat(msg, sizeof(msg), msg2);
		char msg3[3];
		msg3 = "%%";
		StrCat(msg, sizeof(msg), msg3);

		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.2, 1.0, 255, 0, 255, 255);
		ShowSyncHudText(client, hHudText, msg);
		CloseHandle(hHudText);
		
	}
	
	return Plugin_Continue;
}

public Action AdminUploadFinished(Handle timer, client)
{
	if(UploadTimers[client] != INVALID_HANDLE) KillTimer(UploadTimers[client]);
	UploadTimers[client] = INVALID_HANDLE;

	CompleteTask(client, UploadDataAdmin);
	return Plugin_Continue;
}

public Action AdminUploadUpdate(Handle timer, client)
{
	if(!TouchingUp[client])
	{
		if(UploadTimers[client] != INVALID_HANDLE) KillTimer(UploadTimers[client]);
		UploadTimers[client] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	else
	{
		int timeleft = UploadTimeLeft[client];
		UploadTimeLeft[client]--;
		//call next timer only if can isnt empty
		if(timeleft > 0)
		{
			CreateTimer(1.0, AdminUploadUpdate, client);
		}
		
		
		//show progress on HUD
		char msg[64];
		msg = "Upload Progress: ";
		char msg2[10];
		timeleft = (9 - UploadTimeLeft[client])*10;
		IntToString(timeleft, msg2, sizeof(msg2));
		StrCat(msg, sizeof(msg), msg2);
		char msg3[3];
		msg3 = "%%";
		StrCat(msg, sizeof(msg), msg3);

		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.2, 1.0, 255, 0, 255, 255);
		ShowSyncHudText(client, hHudText, msg);
		CloseHandle(hHudText);
		
	}
	
	return Plugin_Continue;
}


/***************************************** HAMMER PROPS ***************************************/

/*********************** KILL BUTTONS *********************/  
public KillButton_Pressed(const String:output[], caller, activator, Float:delay)
{
	int victim = 0;
	if(Impostor[activator] && !KillCooldown[activator])
	{
		//get parent (the victim)
		victim = GetEntPropEnt(caller, Prop_Data, "m_hMoveParent");
		
		//call dead prop + button ent maker to location
		SpawnDeadBodyButton(caller);
		
		//Hook new button
		CreateTimer(0.5, HookDeadBodyButton);

		
		//destroy this button - probably easiest to just call output with kill command. Give time for above timer to finish...
		FireEntityOutput(caller, "OnUser3", victim, 1.0); //  trigger the output on an entity
		
		//kill player
		CreateTimer(0.2, CrewmateDeath, victim);
		CreateTimer(0.5, DestroyPlayerRagdolls);

		//Set KillCooldown
		StartKillCooldown(activator, DEFAULT_KILL_COOLDOWN);
		
		//play sound
		PlayKillSound(activator);
		
	}
} 

stock PlayKillSound(client)
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "point_clientcommand")) != -1) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "clientcommands", false)) // targetname match
		{
			FireEntityOutput(ent, "OnUser1", client, 0.0); //  trigger the output on an entity, with activator as client (clientid == entityid)		
			break; // Stop loop
		}        
	}
	return;
}

public Action DestroyPlayerRagdolls(Handle timer)
{
	ServerCommand("destroy_ragdolls");
}


/*********************** DEAD BODY BUTTONS *********************/  
public DeadBodyButton_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(Crewmate[activator] || Impostor[activator])
	{
		Meeting(1, activator); //type of overlay, who called meeting
	}

	//BODY FOUND CALL MEETING
	
	//clear dead body ragdolls and the buttons > we can clear all of them without worry.
	//ClearProp_Ragdolls();
	//ClearDeadBodyButtons();  NO NEED AS THIS IS DONE IN THE MEETING METHOD ANYWAY
	
	//Display dead body found overlay -- this is done in MEETING()
	//DisplayOverlay(1); //1 = dead body found 2 = meeting called 3 = Crew win 4 = Impostors win
	
	//Start meeting
	
	
} 


public Action HookDeadBodyButton(Handle timer)
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1) // Find the maker
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(strncmp(buffer, "DeadBodyButton", 14) == 0) // the right button type match
		{
			//Hook its output
			HookSingleEntityOutput(ent, "OnPressed", DeadBodyButton_Pressed, false); // Hook trigger output					
		}        
	}
}

/*********************** STRIP CLIENT *********************/   
// NEEDS A TRIGGER MULTIPLE WITH NAME:"StripTrigger" TO WORK
stock Strip(client) 
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "StripTrigger", false)) // targetname match
		{
			FireEntityOutput(ent, "OnTrigger", client, 1.0); //  trigger the output on an entity, with activator as client (clientid == entityid)		
			break; // Stop loop
		}        
	}
	return;
} 

/*********************** TOGGLE WARNING LIGHTS *********************/   
//
stock TurnOnWarningLights() 
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "WarningLightsButton", false)) // targetname match
		{
			FireEntityOutput(ent, "OnUser1", -1, 1.0); //  trigger the output on an entity, with activator as client (clientid == entityid)		
			break; // Stop loop
		}        
	}
	return;
} 

stock TurnOffWarningLights() 
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "WarningLightsButton", false)) // targetname match
		{
			FireEntityOutput(ent, "OnUser2", 0, 1.0); //  trigger the output on an entity, with activator as client (clientid == entityid)		
			break; // Stop loop
		}        
	}
	return;
} 



/*************************************** UPLOAD DATA *************************************/

/*********************** CAFETARIA *********************/

//Upload_Cafeteria
public Upload_Cafeteria_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(PlayerTasks[activator][DownloadDataCafeteria] && TouchingUp[activator])
	{
		UploadTimers[activator] = CreateTimer(10.0, UploadFinished, activator);
		UploadTimeLeft[activator] = 10;
		CreateTimer(0.0, UploadUpdate, activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** WEAPONS *********************/

//Upload_Weapons
public Upload_Weapons_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(PlayerTasks[activator][DownloadDataWeapons] && TouchingUp[activator])
	{
		UploadTimers[activator] = CreateTimer(10.0, UploadFinished, activator);
		UploadTimeLeft[activator] = 10;
		CreateTimer(0.0, UploadUpdate, activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** NAVIGATION *********************/

//Upload_Navigation
public Upload_Navigation_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(PlayerTasks[activator][DownloadDataNavigation] && TouchingUp[activator])
	{
		UploadTimers[activator] = CreateTimer(10.0, UploadFinished, activator);
		UploadTimeLeft[activator] = 10;
		CreateTimer(0.0, UploadUpdate, activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** ADMIN *********************/

//Upload_Admin
public Upload_Admin_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(PlayerTasks[activator][UploadDataAdmin] && TouchingUp[activator])
	{
		UploadTimers[activator] = CreateTimer(10.0, AdminUploadFinished, activator);
		UploadTimeLeft[activator] = 10;
		CreateTimer(0.0, AdminUploadUpdate, activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** COMMS *********************/

// Upload_Comms
public Upload_Comms_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][DownloadDataCommunications] && TouchingUp[activator])
	{
		UploadTimers[activator] = CreateTimer(10.0, UploadFinished, activator);
		UploadTimeLeft[activator] = 10;
		CreateTimer(0.0, UploadUpdate, activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** ELECTRIC *********************/

// Upload_Electric
public Upload_Electric_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][DownloadDataElectric] && TouchingUp[activator])
	{
		UploadTimers[activator] = CreateTimer(10.0, UploadFinished, activator);
		UploadTimeLeft[activator] = 10;
		CreateTimer(0.0, UploadUpdate, activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 


/*************************************** DIVERT POWER *************************************/

/*********************** WEAPONS *********************/
// 
public AcceptPower_Weapons_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][DivertPowerWeaponsSecond])
	{
		CompleteTask(activator, DivertPowerWeaponsSecond);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** SECURITY *********************/
// 
public AcceptPower_Security_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][DivertPowerSecuritySecond])
	{
		CompleteTask(activator, DivertPowerSecuritySecond);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** O2 *********************/
// 
public AcceptPower_O2_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][DivertPowerO2Second])
	{
		CompleteTask(activator, DivertPowerO2Second);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** NAVIGATION *********************/
// 
public AcceptPower_Navigation_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][DivertPowerNavigationSecond])
	{
		CompleteTask(activator, DivertPowerNavigationSecond);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** SHIELDS *********************/
// 
public AcceptPower_Shields_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][DivertPowerShieldsSecond])
	{
		CompleteTask(activator, DivertPowerShieldsSecond);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** COMMS *********************/
// 
public AcceptPower_Comms_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][DivertPowerCommunicationsSecond])
	{
		CompleteTask(activator, DivertPowerCommunicationsSecond);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** LOWER ENGINE *********************/
// 
public AcceptPower_LEngine_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][DivertPowerLowerEngineSecond])
	{
		CompleteTask(activator, DivertPowerLowerEngineSecond);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** UPPER ENGINE *********************/
// 
public AcceptPower_UEngine_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][DivertPowerUpperEngineSecond])
	{
		CompleteTask(activator, DivertPowerUpperEngineSecond);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** ELECTRIC *********************/
// 
public DivertPower_Electric_Pressed(const String:output[], caller, activator, Float:delay)
{
	bool hasTask = false;
	for(int i = DivertPowerSecurityFirst; i<DivertPowerUpperEngineFirst; i++)
	{
		if(PlayerTasks[activator][i])
		{
			hasTask = true;
			
			AddTask(activator, i+8);
			CompleteTask(activator, i);
			break;
		}
	}

	if(!hasTask)
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*************************************** FIX WIRES *************************************/

/*********************** CAFETARIA *********************/
// 
public Wiring_Cafeteria_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][FixWiringCafeteria])
	{
		WiresPlayerLocation[activator] = FixWiringCafeteria;
		SendWiresMenu(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** NAVIGATION *********************/
// 
public Wiring_Navigation_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][FixWiringNavigation])
	{
		WiresPlayerLocation[activator] = FixWiringNavigation;
		SendWiresMenu(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** ADMIN *********************/
// 
public Wiring_Admin_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][FixWiringAdmin])
	{
		WiresPlayerLocation[activator] = FixWiringAdmin;
		SendWiresMenu(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** STORAGE *********************/
// 
public Wiring_Storage_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][FixWiringStorage])
	{
		WiresPlayerLocation[activator] = FixWiringStorage;
		SendWiresMenu(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** ELECTRIC *********************/
// 
public Wiring_Electric_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][FixWiringElectric])
	{
		WiresPlayerLocation[activator] = FixWiringElectric;
		SendWiresMenu(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** SECURITY *********************/
// 
public Wiring_Security_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][FixWiringSecurity])
	{
		CompleteTask(activator, FixWiringSecurity);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*************************************** EMPTY TRASH *************************************/

/*********************** EMPTY GARBAGE *********************/
// 
public EmptyGarbage_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(PlayerTasks[activator][EmptyGarbageFirst])
	{
		CompleteTask(activator, EmptyGarbageFirst);
		AddTask(activator, EmptyAirlockSecond);
		FireEntityOutput(caller, "OnUser2", activator, 0.1); //  trigger the output on an entity
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 



/*********************** EMPTY CHUTE *********************/
// 
public EmptyChute_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(PlayerTasks[activator][EmptyChuteFirst])
	{
		CompleteTask(activator, EmptyChuteFirst);
		AddTask(activator, EmptyAirlockSecond);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** EMPTY STORAGE AIRLOCK *********************/
// 
public EmptyStorage_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][EmptyAirlockSecond])
	{
		if(CompletedTasks[activator][EmptyAirlockSecond])
		{
			CompleteTask(activator, EmptyAirlockSecond);
		}
		else if(CompletedTasks[activator][EmptyChuteFirst] && CompletedTasks[activator][EmptyGarbageFirst])
		{
			NumberOfTasksLeft -= 1.0;
			CompleteTask(activator, EmptyAirlockSecond);
		}
		else
		{
			CompleteTask(activator, EmptyAirlockSecond);
		}
		FireEntityOutput(caller, "OnUser2", activator, 0.1); //  trigger the output on an entity
		
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*************************************** OTHER *************************************/

/*********************** WEAPONS *********************/
//
public ClearAsteroids_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][ClearAsteroids])
	{
		StartClearAsteroids(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** O2 *********************/
//
public CleanFilter_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][CleanO2Filter])
	{
		StartFilterMenu(activator); 
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** NAVIGATION *********************/
//
public ChartCourse_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][ChartCourse])
	{
		SendChartCourseMenu(activator); 
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 
//
public StabilizeSteering_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][StabiliseSteering])
	{
		StartStabiliseSteering(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** ADMIN *********************/
//
public SwipeCard_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(PlayerTasks[activator][SwipeCard])
	{
		CompleteTask(activator, SwipeCard);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
}  


/*********************** SHIELDS *********************/
//
public Shields_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][PrimeShields])
	{
		StartShieldMenu(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** STORAGE *********************/
//
public FuelEngines_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	
	//if he doesnt have task, reject
	if(!PlayerTasks[activator][FuelLowerEngineFirst] && !PlayerTasks[activator][FuelUpperEngineFirst])
		{
			PrintToChat(activator, "You do not have the task!");
		}
	
	//if he has
	
	//if he isnt in middle of doing one of the other fueling tasks
	if(!(PlayerTasks[activator][FuelLowerEngineSecond] || PlayerTasks[activator][FuelUpperEngineSecond]))
	{
		//if he has both, give him the lower engine task first
		if(PlayerTasks[activator][FuelLowerEngineFirst] && PlayerTasks[activator][FuelUpperEngineFirst])
		{
			CreateTimer(1.0, TryToFillCanLEng, activator);

		}
		//if he has just lower engine
		else if(PlayerTasks[activator][FuelLowerEngineFirst])
		{
			CreateTimer(1.0, TryToFillCanLEng, activator);
		}
		//if he has just upper engine
		else if(PlayerTasks[activator][FuelUpperEngineFirst])
		{
			CreateTimer(1.0, TryToFillCanUEng, activator);

		}
	}
	else
	{
		PrintToChat(activator, "You can only carry 1 can at a time!");
	}
	
} 

/*********************** ELECTRIC *********************/
//
public CalibrateDistributor_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][CalibrateDistributor])
	{
		StartCalibrateDistributor(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** LOWER ENGINE *********************/
//
public LEngineFuel_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][FuelLowerEngineSecond] && !Fueling[activator])
	{
		Fueling[activator] = true;
		CreateTimer(1.0, TryToFillLowerEng, activator);

	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

//
public LEngineOutput_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][AlignLowerEngine])
	{
		StartAlignLEngine(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** UPPER ENGINE *********************/
//
public UEngineFuel_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][FuelUpperEngineSecond] && !Fueling[activator])
	{
		Fueling[activator] = true;
		CreateTimer(1.0, TryToFillUpperEng, activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

//
public UEngineOutput_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][AlignUpperEngine])
	{
		StartAlignUEngine(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** REACTOR *********************/
//
public StartReactor_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][StartReactor])
	{
		StartReactorTask(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

//
public UnlockManifolds_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][UnlockManifolds])
	{
		SendManifoldsMenu(activator);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

/*********************** MEDICAL BAY *********************/
//
public InspectSample_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][InspectSampleFirst])
	{
		CompleteTask(activator, InspectSampleFirst);
		SampleTimeLeft[activator] = 30;
		SampleTimer[activator] = CreateTimer(30.0, SampleTimerOver, activator);
		SampleUpdateTimer[activator] = CreateTimer(0.0, SampleTimerUpdate, activator);
	}
	else if(PlayerTasks[activator][InspectSampleSecond])
	{
		CompleteTask(activator, InspectSampleSecond);
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

public StartScan_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][SubmitScan] && CrewmateEnteredScanner && CrewmateOnScanner == activator)
	{
		PrintToChat(activator, "Scan Started!");
		
		//turn scanner light on
		FireEntityOutput(caller, "OnUser2", activator, 0.1); //  trigger the output on an entity
		
		//save ent id for global use (for turning off light)
		ScannerEntID = caller;
		
		//create time for scanner and light
		ScannerTimer = CreateTimer(13.0, ScannerTimerOver, activator);
		
		//Play Scanner sound
		//PlaySound(5); //5 is MedbayScanSound
	}
	else
	{
		//PrintToChatAll("activator %i does not have the task, isnt the person on scanner or isnt ON the scanner!", activator);
	}
	
} 
/*************************************** MEDBAY TRIGGERS *************************************/
//
public SubmitScan_Trigger_OnStartTouchAll(const String:output[], caller, activator, Float:delay)
{
	
	if(PlayerTasks[activator][SubmitScan])
	{
		CrewmateEnteredScanner = true;
		CrewmateOnScanner = activator;
	}
	else
	{
		PrintToChat(activator, "You do not have the task!");
	}
	
} 

//
public SubmitScan_Trigger_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	if(activator == CrewmateOnScanner)
	{
		PrintToChat(activator, "Scan Interrupted!");
		if(ScannerTimer != INVALID_HANDLE) KillTimer(ScannerTimer);
		ScannerTimer = INVALID_HANDLE;
		CrewmateEnteredScanner = false;
		CrewmateOnScanner = -1;
		
		//turn off light
		FireEntityOutput(caller, "OnUser2", activator, 0.1); //  trigger the output on an entity
	}
	
} 

/*************************************** FUEL TRIGGERS *************************************/
//
public FuelCan_Trigger_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingCans[activator] = true;
	
} 

public FuelCan_Trigger_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingCans[activator] = false;
	
} 

//
public FuelLEngine_Trigger_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingLEng[activator] = true;
	
} 

public FuelLEngine_Trigger_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingLEng[activator] = false;
	Fueling[activator] = false;
	
} 

//
public FuelUEngine_Trigger_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUEng[activator] = true;
	
} 

public FuelUEngine_Trigger_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	Fueling[activator] = false;
	TouchingUEng[activator] = false;
	
} 

/*************************************** UPLOAD TRIGGERS *************************************/
//
public UploadCafe_Trigger_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = true;
} 

public UploadCafe_Trigger_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = false;
	
}

public UploadComms_Trigger_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = true;
} 

public UploadComms_Trigger_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = false;
	
}

public UploadAdmin_Trigger_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = true;
} 

public UploadAdmin_Trigger_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = false;
}

public UploadWep_Trigger_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = true;
} 

public UploadWep_Trigger_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = false;
	
}

public UploadNav_Trigger_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = true;
} 

public UploadNav_Trigger_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = false;
	
}

public UploadEle_Trigger_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = true;
} 

public UploadEle_Trigger_OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	TouchingUp[activator] = false;
	
}

/*************************************** VENTS **************************************/
//

public Vent_Pressed(const String:output[], caller, activator, Float:delay)
{
		if(Impostor[activator])
		{
			//teleport
			FireEntityOutput(caller, "OnUser2", activator, 0.1); //  trigger the output on an entity
		}
		
		//return Plugin_Continue;
} 


/*************************************** EMERGENCY BUTTON *************************************/
//
public EmergencyButton_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(EmergencyButtonEnabled && !SabotageActive && !MeetingTime)
	{
		if(Crewmate[activator] || Impostor[activator])
		{
			Meeting(2, activator); //2 is emergency button type
			FireEntityOutput(caller, "OnUser2", -1, 0.0); // play button sound
		}
		
	}
} 

/*************************************** SABOTAGE FIXING *************************************/
//
public FixLights_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(LightsSabotageActive && (Crewmate[activator] || Impostor[activator]))
	{
		SendLightsMenu(activator);
	}
} 

public SabotageCommsButton_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(CommsSabotageActive && (Crewmate[activator] || Impostor[activator]))
	{
		SendCommsSabotageMenu(activator);
	}
} 

public SabotageOxygenAdmin_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(OxygenSabotageActive && (Crewmate[activator] || Impostor[activator]))
	{
		SendOxygenAdminMenu(activator);
	}
	
} 

public SabotageOxygenO2_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(OxygenSabotageActive && (Crewmate[activator] || Impostor[activator]))
	{
		SendOxygenO2Menu(activator);
	}
} 

public SabotageReactor1_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(ReactorSabotageActive && (Crewmate[activator] || Impostor[activator]))
	{
		ReactorButton1Pressed = true;
		if (ReactorButton2Pressed) ResolveReactorSabotage(true);
		CreateTimer(1.0, UnpressReactor1Button);
	}
} 

public SabotageReactor2_Button_Pressed(const String:output[], caller, activator, Float:delay)
{
	if(ReactorSabotageActive && (Crewmate[activator] || Impostor[activator]))
	{
		ReactorButton2Pressed = true;
		if (ReactorButton1Pressed) ResolveReactorSabotage(true);
		CreateTimer(1.0, UnpressReactor2Button);
	}
} 





/*************************************** HOOK PROPS *****************************************************/
stock HookHammerTriggersAndButtons() 
{
	new String:buffer[60], ent = -1;
	int buttonCounter = 0;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1 || buttonCounter != ButtonNum) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		/*
		Emergency button
		SabotageLights button
		Sabotatage lights entity buttons
		Fix Light button
		Fix O2 button + Fix O2 admin button
		fix Reactor button x2


		Scanner light button
		
		21 EXTRA BUTTONS?
		
		21+40 = 61
		*/

		if(StrEqual(buffer, "Upload_Cafeteria", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnPressed", Upload_Cafeteria_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Upload_Weapons", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Upload_Weapons_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Upload_Navigation", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Upload_Navigation_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Upload_Admin", false))
		{	
			HookSingleEntityOutput(ent, "OnPressed", Upload_Admin_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Upload_Comms", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Upload_Comms_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Upload_Electric", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Upload_Electric_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_Weapons", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", AcceptPower_Weapons_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_O2", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", AcceptPower_O2_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_Navigation", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", AcceptPower_Navigation_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_Shields", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", AcceptPower_Shields_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_Comms", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", AcceptPower_Comms_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "DivertPower_Electric", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", DivertPower_Electric_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_LEngine", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", AcceptPower_LEngine_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_UEngine", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", AcceptPower_UEngine_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_Security", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", AcceptPower_Security_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Cafeteria", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Wiring_Cafeteria_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Navigation", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Wiring_Navigation_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Admin", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Wiring_Admin_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Storage", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Wiring_Storage_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Electric", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Wiring_Electric_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Security", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Wiring_Security_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "EmptyGarbage_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", EmptyGarbage_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "EmptyChute_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", EmptyChute_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "EmptyStorage_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", EmptyStorage_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "ClearAsteroids_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", ClearAsteroids_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "CleanFilter_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", CleanFilter_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "ChartCourse_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", ChartCourse_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "StabilizeSteering_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", StabilizeSteering_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Shields_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Shields_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "FuelEngines_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", FuelEngines_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "InspectSample_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", InspectSample_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "StartScan_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", StartScan_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "CalibrateDistributor_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", CalibrateDistributor_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "LEngineOutput_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", LEngineOutput_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "LEngineFuel_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", LEngineFuel_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "UEngineOutput_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", UEngineOutput_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "UEngineFuel_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", UEngineFuel_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "StartReactor_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", StartReactor_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "UnlockManifolds_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", UnlockManifolds_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		} //VENTS = 14
		else if(StrEqual(buffer, "NavVent1", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "NavVent2", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "WepVent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "CorrVent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AdminVent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "CafeVent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "ShieldsVent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "EleVent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SecVent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Reac1Vent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Reac2Vent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "LEngVent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "UEngVent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "MedVent", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", Vent_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "EmergencyButton", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", EmergencyButton_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageCommsButton", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", SabotageCommsButton_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "FixLights_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", FixLights_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageOxygenAdmin_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", SabotageOxygenAdmin_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageOxygenO2_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", SabotageOxygenO2_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageReactor1_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", SabotageReactor1_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageReactor2_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", SabotageReactor2_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageReactor2_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", SabotageReactor2_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SwipeCard_Button", false))
		{
			HookSingleEntityOutput(ent, "OnPressed", SwipeCard_Button_Pressed, false); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		

	}
	//Triggers
	//Scanner = 1
	//Fuel can + 2 engine fuel = 3
	//upload + 6
	//total = 10
	int triggerCounter = 0;
	ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1 || triggerCounter != TriggerNum) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "SubmitScan_Trigger", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnStartTouchAll", SubmitScan_Trigger_OnStartTouchAll, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnEndTouch", SubmitScan_Trigger_OnEndTouch, false); // Hook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}     
		else if(StrEqual(buffer, "FuelCan_Trigger", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnStartTouch", FuelCan_Trigger_OnStartTouch, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnEndTouch", FuelCan_Trigger_OnEndTouch, false); // Hook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}  
		else if(StrEqual(buffer, "FuelLEngine_Trigger", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnStartTouch", FuelLEngine_Trigger_OnStartTouch, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnEndTouch", FuelLEngine_Trigger_OnEndTouch, false); // Hook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}  
		else if(StrEqual(buffer, "FuelUEngine_Trigger", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnStartTouch", FuelUEngine_Trigger_OnStartTouch, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnEndTouch", FuelUEngine_Trigger_OnEndTouch, false); // Hook trigger output
			triggerCounter++;
			continue; // next iteration loop
		} 
		else if(StrEqual(buffer, "UploadCafe_Trigger", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnStartTouch", UploadCafe_Trigger_OnStartTouch, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnEndTouch", UploadCafe_Trigger_OnEndTouch, false); // Hook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
  		else if(StrEqual(buffer, "UploadAdmin_Trigger", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnStartTouch", UploadAdmin_Trigger_OnStartTouch, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnEndTouch", UploadAdmin_Trigger_OnEndTouch, false); // Hook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
  		else if(StrEqual(buffer, "UploadComms_Trigger", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnStartTouch", UploadComms_Trigger_OnStartTouch, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnEndTouch", UploadComms_Trigger_OnEndTouch, false); // Hook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
  		else if(StrEqual(buffer, "UploadNav_Trigger", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnStartTouch", UploadNav_Trigger_OnStartTouch, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnEndTouch", UploadNav_Trigger_OnEndTouch, false); // Hook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
  		else if(StrEqual(buffer, "UploadEle_Trigger", false)) // targetname match
		{	
			HookSingleEntityOutput(ent, "OnStartTouch", UploadEle_Trigger_OnStartTouch, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnEndTouch", UploadEle_Trigger_OnEndTouch, false); // Hook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "UploadWep_Trigger", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnStartTouch", UploadWep_Trigger_OnStartTouch, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnEndTouch", UploadWep_Trigger_OnEndTouch, false); // Hook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
	}
	
} 

//spawn killbutton
stock SpawnKillButton(client)
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "env_entity_maker")) != -1) // Find the maker
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "KillButtonMaker", false)) // targetname match
		{
			FireEntityOutput(ent, "OnUser1", client, 0.1); //  fire the entity maker to make ents on client
			break; // Stop loop
		}        
	}
	return;
}

//spawn dead body button
stock SpawnDeadBodyButton(client)
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "env_entity_maker")) != -1) // Find the maker
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "DeadBodyButtonMaker", false)) // targetname match
		{
			FireEntityOutput(ent, "OnUser1", client, 0.1); //  fire the entity maker to make ents on client
			break; // Stop loop
		}        
	}
	return;
}

//Clear all Prop_Ragdolls
stock ClearProp_Ragdolls()
{
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "prop_ragdoll")) != -1) // Find the maker
	{
		FireEntityOutput(ent, "OnUser1", 0, 0.1); //  fire the entity maker to make ents on client
	}        
	return;
}

//Clear all DeadBodyButtons
stock ClearDeadBodyButtons()
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1) // Find the maker
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(strncmp(buffer, "DeadBodyButton", 14) == 0) // targetname match
		{
			FireEntityOutput(ent, "OnUser2", 0, 0.1); //  fire the entity maker to make ents on client
		}        
	}
	return;
}


//Unhook all those buttons and triggers
stock UnhookButtons()
{
	new String:buffer[60], ent = -1;
	int buttonCounter = 0;
	while((ent = FindEntityByClassname(ent, "func_button")) != -1 || buttonCounter != ButtonNum) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		/*
		Emergency button
		SabotageLights button
		Sabotatage lights entity buttons
		Fix Light button
		Fix O2 button + Fix O2 admin button
		fix Reactor button x2


		Scanner light button
		
		21 EXTRA BUTTONS?
		
		21+40 = 61
		*/

		if(StrEqual(buffer, "Upload_Cafeteria", false)) // targetname match
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Upload_Cafeteria_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Upload_Weapons", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Upload_Weapons_Pressed); // Hook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Upload_Navigation", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Upload_Navigation_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Upload_Admin", false))
		{	
			UnhookSingleEntityOutput(ent, "OnPressed", Upload_Admin_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Upload_Comms", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Upload_Comms_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Upload_Electric", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Upload_Electric_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_Weapons", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", AcceptPower_Weapons_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_O2", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", AcceptPower_O2_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_Navigation", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", AcceptPower_Navigation_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_Shields", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", AcceptPower_Shields_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_Comms", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", AcceptPower_Comms_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "DivertPower_Electric", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", DivertPower_Electric_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_LEngine", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", AcceptPower_LEngine_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_UEngine", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", AcceptPower_UEngine_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AcceptPower_Security", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", AcceptPower_Security_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Cafeteria", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Wiring_Cafeteria_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Navigation", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Wiring_Navigation_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Admin", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Wiring_Admin_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Storage", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Wiring_Storage_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Electric", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Wiring_Electric_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Wiring_Security", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Wiring_Security_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "EmptyGarbage_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", EmptyGarbage_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "EmptyChute_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", EmptyChute_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "EmptyStorage_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", EmptyStorage_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "ClearAsteroids_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", ClearAsteroids_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "CleanFilter_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", CleanFilter_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "ChartCourse_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", ChartCourse_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "StabilizeSteering_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", StabilizeSteering_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Shields_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Shields_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "FuelEngines_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", FuelEngines_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "InspectSample_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", InspectSample_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "StartScan_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", StartScan_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "CalibrateDistributor_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", CalibrateDistributor_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "LEngineOutput_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", LEngineOutput_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "LEngineFuel_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", LEngineFuel_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "UEngineOutput_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", UEngineOutput_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "UEngineFuel_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", UEngineFuel_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "StartReactor_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", StartReactor_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "UnlockManifolds_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", UnlockManifolds_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		} //VENTS = 14
		else if(StrEqual(buffer, "NavVent1", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "NavVent2", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "WepVent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "CorrVent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "AdminVent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "CafeVent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "ShieldsVent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "EleVent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SecVent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Reac1Vent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "Reac2Vent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "LEngVent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "UEngVent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "MedVent", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", Vent_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "EmergencyButton", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", EmergencyButton_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageCommsButton", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", SabotageCommsButton_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "FixLights_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", FixLights_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageOxygenAdmin_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", SabotageOxygenAdmin_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageOxygenO2_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", SabotageOxygenO2_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageReactor1_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", SabotageReactor1_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageReactor2_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", SabotageReactor2_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SabotageReactor2_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", SabotageReactor2_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "SwipeCard_Button", false))
		{
			UnhookSingleEntityOutput(ent, "OnPressed", SwipeCard_Button_Pressed); // Unhook trigger output
			buttonCounter++;
			continue; // next iteration loop
		}
		
	}
	//Triggers
	//Scanner = 1
	//Fuel can + 2 engine fuel = 3
	//upload + 6
	//total = 10
	int triggerCounter = 0;
	ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1 || triggerCounter != TriggerNum) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "SubmitScan_Trigger", false)) // targetname match
		{
			UnhookSingleEntityOutput(ent, "OnStartTouchAll", SubmitScan_Trigger_OnStartTouchAll); // Unhook trigger output
			UnhookSingleEntityOutput(ent, "OnEndTouch", SubmitScan_Trigger_OnEndTouch); // Unhook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}     
		else if(StrEqual(buffer, "FuelCan_Trigger", false)) // targetname match
		{
			UnhookSingleEntityOutput(ent, "OnStartTouch", FuelCan_Trigger_OnStartTouch); // Unhook trigger output
			UnhookSingleEntityOutput(ent, "OnEndTouch", FuelCan_Trigger_OnEndTouch); // Unhook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}  
		else if(StrEqual(buffer, "FuelLEngine_Trigger", false)) // targetname match
		{
			UnhookSingleEntityOutput(ent, "OnStartTouch", FuelLEngine_Trigger_OnStartTouch); // Unhook trigger output
			UnhookSingleEntityOutput(ent, "OnEndTouch", FuelLEngine_Trigger_OnEndTouch); // Unhook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}  
		else if(StrEqual(buffer, "FuelUEngine_Trigger", false)) // targetname match
		{
			UnhookSingleEntityOutput(ent, "OnStartTouch", FuelUEngine_Trigger_OnStartTouch); // Unhook trigger output
			UnhookSingleEntityOutput(ent, "OnEndTouch", FuelUEngine_Trigger_OnEndTouch); // Unhook trigger output
			triggerCounter++;
			continue; // next iteration loop
		} 
		else if(StrEqual(buffer, "UploadCafe_Trigger", false)) // targetname match
		{
			UnhookSingleEntityOutput(ent, "OnStartTouch", UploadCafe_Trigger_OnStartTouch); // Unhook trigger output
			UnhookSingleEntityOutput(ent, "OnEndTouch", UploadCafe_Trigger_OnEndTouch); // Unhook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
  		else if(StrEqual(buffer, "UploadAdmin_Trigger", false)) // targetname match
		{
			UnhookSingleEntityOutput(ent, "OnStartTouch", UploadAdmin_Trigger_OnStartTouch); // Unhook trigger output
			UnhookSingleEntityOutput(ent, "OnEndTouch", UploadAdmin_Trigger_OnEndTouch); // Unhook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
  		else if(StrEqual(buffer, "UploadComms_Trigger", false)) // targetname match
		{
			UnhookSingleEntityOutput(ent, "OnStartTouch", UploadComms_Trigger_OnStartTouch); // Unhook trigger output
			UnhookSingleEntityOutput(ent, "OnEndTouch", UploadComms_Trigger_OnEndTouch); // Unhook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
  		else if(StrEqual(buffer, "UploadNav_Trigger", false)) // targetname match
		{
			UnhookSingleEntityOutput(ent, "OnStartTouch", UploadNav_Trigger_OnStartTouch); // Unhook trigger output
			UnhookSingleEntityOutput(ent, "OnEndTouch", UploadNav_Trigger_OnEndTouch); // Unhook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
  		else if(StrEqual(buffer, "UploadEle_Trigger", false)) // targetname match
		{	
			UnhookSingleEntityOutput(ent, "OnStartTouch", UploadEle_Trigger_OnStartTouch); // Unhook trigger output
			UnhookSingleEntityOutput(ent, "OnEndTouch", UploadEle_Trigger_OnEndTouch); // Unhook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
		else if(StrEqual(buffer, "UploadWep_Trigger", false)) // targetname match
		{
			UnhookSingleEntityOutput(ent, "OnStartTouch", UploadWep_Trigger_OnStartTouch); // Unhook trigger output
			UnhookSingleEntityOutput(ent, "OnEndTouch", UploadWep_Trigger_OnEndTouch); // Unhook trigger output
			triggerCounter++;
			continue; // next iteration loop
		}
	}
	
} 