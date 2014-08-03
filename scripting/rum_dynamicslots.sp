#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define MAX_ENTITIES		2048

#define PLUGIN_VERSION		"1.1"
#define PLUGIN_CONTACT		"skyyplugins@gmail.com"

#define PLUGIN_NAME			"[RUM][Server Mgmt] Dynamic Slots"
#define PLUGIN_DESCRIPTION	"Automatically adjusts max slots based on spectator count, manages reserve slots."
#define CONFIG				"dynamicslots.cfg"
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

new i_PlayerSlots;
new i_ReserveSlots;
new i_InfectedSlots;
new i_SurvivorSlots;

new String:s_rup[32];

public OnPluginStart()
{
	CreateConVar("rum_dynamicslots", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("rum_dynamicslots"), PLUGIN_VERSION);

	LoadTranslations("common.phrases");
	LoadTranslations("rum_dynamicslots.phrases");
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
		
		if (StrEqual(s_key, "actual player slots?")) i_PlayerSlots				= StringToInt(s_value);
		else if (StrEqual(s_key, "number reserve slots?")) i_ReserveSlots		= StringToInt(s_value);
	}

	if (ReadyUp_GetGameMode() == 2) {

		i_InfectedSlots		= i_PlayerSlots / 2;
		i_SurvivorSlots		= i_PlayerSlots / 2;
	}
	else {

		i_InfectedSlots		= i_PlayerSlots;
		i_SurvivorSlots		= i_PlayerSlots;
	}

	ReadyUp_NtvGetHeader();
}

public ReadyUp_FwdGetHeader(const String:header[]) {

	strcopy(s_rup, sizeof(s_rup), header);
	Now_ManageSlots();
}

public ReadyUp_FwdChangeTeam(client, team) {

	CreateTimer(3.0, Timer_ManageSlots, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ManageSlots(Handle:timer) {

	Now_ManageSlots();
	return Plugin_Stop;
}

public ReadyUp_TrueDisconnect(client) {

	Now_ManageSlots();
}

public ReadyUp_IsClientLoaded(client) {

	Now_ManageSlots();

	new count																	= 0;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientActual(i) && IsClientHuman(i) && client != i && GetClientTeam(i) != TEAM_SPECTATOR) {

			count++;
		}
	}
	if (count < i_PlayerSlots || IsReserve(client)) {

		decl String:text[64];

		if (count >= i_PlayerSlots && !IsReserve(client)) {

			Format(text, sizeof(text), "%T", "reservation kick", client);
			KickClient(client, "%s", text);

			ReadyUp_NtvEntryDenied();

			return;
		}
		else if (count >= i_PlayerSlots && IsReserve(client)) {

			new target															= -1;
			
			if (KickableClient(client) < 1) {

				Format(text, sizeof(text), "%T", "no reservation available", client);
				KickClient(client, "%s", text);

				ReadyUp_NtvEntryDenied();

				return;
			}
			else {

				new bool:b_SlotAvailable										= false;

				while (target == -1 && KickableClient(client) > 0) {

					target														= GetRandomInt(1, MaxClients);

					if (IsClientActual(target) && IsClientHuman(target) && !IsReserve(target)) {
					
						Format(text, sizeof(text), "%T", "reservation fill", target);
						KickClient(target, "%s", text);

						count--;

						b_SlotAvailable											= true;
					}
					else target													= -1;
				}

				if (!b_SlotAvailable) {

					Format(text, sizeof(text), "%T", "no reservation available", client);
					KickClient(client, "%s", text);

					ReadyUp_NtvEntryDenied();

					return;
				}
			}
		}
		if (count < i_PlayerSlots) {

			ReadyUp_NtvEntryAllowed(client);
		}
	}
}

stock KickableClient(client) {

	new count																	= 0;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientActual(i) && IsClientHuman(i) && !IsReserve(i) && i != client) count++;
	}
	
	return count;
}

stock Now_ManageSlots() {

	SetConVarInt(FindConVar("sv_maxplayers"), i_PlayerSlots + i_ReserveSlots + GetSpectatorCount());
	SetConVarInt(FindConVar("sv_visiblemaxplayers"), i_PlayerSlots + i_ReserveSlots + GetSpectatorCount());
	if (i_SurvivorSlots < 0 || i_InfectedSlots < 0) {

		SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, true, (i_PlayerSlots / 2) * 1.0);
		SetConVarInt(FindConVar("z_max_player_zombies"), i_PlayerSlots / 2);
		SetConVarBounds(FindConVar("survivor_limit"), ConVarBound_Upper, true, (i_PlayerSlots / 2) * 1.0);
		SetConVarInt(FindConVar("survivor_limit"), i_PlayerSlots / 2);
	}
	else {

		SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, true, i_InfectedSlots * 1.0);
		SetConVarInt(FindConVar("z_max_player_zombies"), i_InfectedSlots);
		SetConVarBounds(FindConVar("survivor_limit"), ConVarBound_Upper, true, i_SurvivorSlots * 1.0);
		SetConVarInt(FindConVar("survivor_limit"), i_SurvivorSlots);
	}
	ReadyUp_SlotChangeSuccess();
}

stock GetSpectatorCount() {

	new count																	= 0;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SPECTATOR) count++;
	}
	
	return count;
}

stock bool:IsReserve(client) {

	if (HasCommandAccess(client, "z") || HasCommandAccess(client, "a")) return true;
	return false;
}