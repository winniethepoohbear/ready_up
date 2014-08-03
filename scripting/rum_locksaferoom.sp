#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define MAX_ENTITIES		2048

#define PLUGIN_VERSION		"1.21"
#define PLUGIN_CONTACT		"skyyplugins@gmail.com"

#define PLUGIN_NAME			"[RUM][Anti-Rushing] Locked Saferoom Door"
#define PLUGIN_DESCRIPTION	"Locks end of map Saferoom door until all eligible Survivors are nearby."
#define CONFIG				"locksaferoom.cfg"
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN

#include <sourcemod>
#include <sdktools>
#include "wrap.inc"
#undef REQUIRE_PLUGIN
#include "readyup.inc"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_CONTACT,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT,
};

new SaferoomDoor					=	-1;
new bool:IsRoundLive;
new String:white[16];
new String:blue[16];
new String:s_rup[32];
new Float:f_UnlockSaferoomDoorRange;

public OnPluginStart()
{
	CreateConVar("rum_locksaferoom", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("rum_locksaferoom"), PLUGIN_VERSION);

	Format(white, sizeof(white), "\x01");
	Format(blue, sizeof(blue), "\x03");

	LoadTranslations("common.phrases");
	LoadTranslations("rum_antirush.phrases");
}

public OnConfigsExecuted() {

	CreateTimer(0.1, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ExecuteConfig(Handle:timer) {

	if (ReadyUp_NtvConfigProcessing() == 0) {

		ReadyUp_ParseConfig(CONFIG);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public ReadyUp_ParseConfigFailed(String:config[], String:error[]) {

	if (StrEqual(config, CONFIG)) {
	
		SetFailState("%s , %s", config, error);
	}
}

public ReadyUp_LoadFromConfig(Handle:key, Handle:value) {

	decl String:s_key[32];
	decl String:s_value[32];

	new a_Size						= GetArraySize(key);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:key, i, s_key, sizeof(s_key));
		GetArrayString(Handle:value, i, s_value, sizeof(s_value));
		
		if (StrEqual(s_key, "unlock range?")) f_UnlockSaferoomDoorRange	= StringToFloat(s_value);
	}

	ReadyUp_NtvGetHeader();
}

public ReadyUp_FwdGetHeader(const String:header[]) {

	strcopy(s_rup, sizeof(s_rup), header);
}

public ReadyUp_CheckpointDoorStartOpened()
{
	IsRoundLive	=	true;
	if (SaferoomDoor > -1)
	{
		AcceptEntityInput(SaferoomDoor, "Close");
		DispatchKeyValue(SaferoomDoor, "spawnflags", "32768");
		CreateTimer(0.1, Timer_UnlockSaferoom, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public ReadyUp_RoundIsOver() { IsRoundLive	=	false; SaferoomDoor		=	-1; }

stock bool:IsTanksAlive() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && FindZombieClass(i) == ZOMBIECLASS_TANK) return true;
	}
	return false;
}

public Action:Timer_UnlockSaferoom(Handle:timer)
{
	if (!IsRoundLive || !IsValidEntity(SaferoomDoor)) return Plugin_Stop;
	if (!PlayersOutOfRange(SaferoomDoor, f_UnlockSaferoomDoorRange) && IsActiveSurvivors() && !IsTanksAlive())
	{
		PrintToChatAll("%s %t", s_rup, "Saferoom Door Open", white, blue);
		DispatchKeyValue(SaferoomDoor, "spawnflags", "8192");
		AcceptEntityInput(SaferoomDoor, "Open");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public ReadyUp_SaferoomLocked()
{
	new Size = GetEntityCount();
	for (new i = MaxClients + 1; i <= Size && SaferoomDoor < 0; i++)
	{
		if (!IsValidEntity(i)) continue;
		decl String:CName[128];
		GetEntityClassname(i, CName, sizeof(CName));
		if (!StrEqual(CName, "prop_door_rotating_checkpoint")) continue;
		if (GetEntProp(i, Prop_Send, "m_eDoorState") == 2) SaferoomDoor = i;
	}
}

stock bool:IsActiveSurvivors() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) return true;
	}

	return false;
}