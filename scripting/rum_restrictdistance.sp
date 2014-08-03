#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define MAX_ENTITIES		2048

#define PLUGIN_VERSION		"1.0"
#define PLUGIN_CONTACT		"skyyplugins@gmail.com"

#define PLUGIN_NAME			"[RUM][Anti-Rushing] Restrict Distance"
#define PLUGIN_DESCRIPTION	"Restricts survivors from moving too far ahead of their team."
#define CONFIG				"restrictdistance.cfg"
#define CONFIG_MAPS			"restrictdistance/"
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>
#include "wrap.inc"
#include "l4d_stocks.inc"
#undef REQUIRE_PLUGIN
#include "readyup.inc"

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_CONTACT,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT,
};

new bool:IsPluginLoaded;
new bool:IsRoundLive;
new bool:Ensnared[MAXPLAYERS + 1];
new bool:DistanceWarning[MAXPLAYERS + 1];
new bool:IsLagging[MAXPLAYERS + 1];
new g_WarningCounter[MAXPLAYERS + 1];
new configLoadCount;
new Float:g_NoticeDistance;
new Float:g_WarningDistance;
new Float:g_IgnoreDistance;
new Float:g_OldDistance[MAXPLAYERS + 1];
new Float:g_MapFlowDistance;
new String:white[4];
new String:blue[4];
new String:orange[4];
new String:green[4];
new String:s_rup[32];

new i_InfractionLimit;
new i_SurvivorsRequired;
new i_IgnoreIncapacitated;
new i_IgnoreStraggler;
new i_InfractionResult;

public OnPluginStart() {

	CreateConVar("rum_restrictdistance", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("rum_restrictdistance"), PLUGIN_VERSION);

	Format(white, sizeof(white), "\x01");
	Format(blue, sizeof(blue), "\x03");
	Format(orange, sizeof(orange), "\x04");
	Format(green, sizeof(green), "\x05");

	LoadTranslations("common.phrases");
	LoadTranslations("rum_rushdistance.phrases");
}

public OnConfigsExecuted() {

	if (ReadyUp_GetGameMode() != 3) {

		IsPluginLoaded			= true;
		g_NoticeDistance		= 0.0;
		g_WarningDistance		= 0.0;
		g_IgnoreDistance		= 0.0;

		decl String:s_Path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, s_Path, sizeof(s_Path), "configs/readyup/%s", CONFIG_MAPS);

		if (!DirExists(s_Path)) CreateDirectory(s_Path, 511);

		configLoadCount			= 0;
		CreateTimer(0.1, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else IsPluginLoaded			= false;
}

public Action:Timer_ExecuteConfig(Handle:timer) {

	if (ReadyUp_NtvConfigProcessing() == 0) {

		ReadyUp_ParseConfig(CONFIG);
		decl String:mapname[64];
		GetCurrentMap(mapname, sizeof(mapname));
		Format(mapname, sizeof(mapname), "%s%s.cfg", CONFIG_MAPS, mapname);
		ReadyUp_ParseConfig(mapname);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public ReadyUp_FirstClientLoaded() { g_MapFlowDistance	=	L4D2Direct_GetMapMaxFlowDistance(); }

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		DistanceWarning[client]			=	false;
		g_WarningCounter[client]		=	0;
		Ensnared[client]				=	false;
		g_OldDistance[client]			=	0.0;
		IsLagging[client]				=	false;
	}
}

public ReadyUp_CheckpointDoorStartOpened() {

	if (ReadyUp_GetGameMode() != 3 && IsPluginLoaded)
	{
		IsRoundLive	=	true;
		CreateTimer(0.1, Timer_DistanceCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public ReadyUp_RoundIsOver() {

	IsRoundLive	=	false;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && IsClientInGame(i)) {

			DistanceWarning[i]		=	false;
			g_WarningCounter[i]		=	0;
			Ensnared[i]			=	false;
			g_OldDistance[i]		=	0.0;
			IsLagging[i]			=	false;
		}
	}
}

public Action:Timer_DistanceCheck(Handle:timer) {

	if (!IsRoundLive) return Plugin_Stop;

	if (ActiveSurvivors() < i_SurvivorsRequired) return Plugin_Continue;

	new Float:g_TeamDistance		=	0.0;
	new Float:g_PlayerDistance		=	0.0;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i)) {

			if ((L4D2_GetInfectedAttacker(i) != -1 || IsIncapacitated(i)) && !Ensnared[i]) {

				Ensnared[i]			=	true;
				CreateTimer(0.1, Timer_IsEnsnared, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			if (IsClientLaggingBehind(i)) {

				if (!i_IgnoreStraggler) {

					PrintToChat(i, "%T", "Lagging Behind", i, white, green, white);
					TeleportLaggingPlayer(i);
					IsLagging[i]	=	false;
				}
				else IsLagging[i]		=	true;
			}
			if (!IsLagging[i] || !i_IgnoreStraggler && !IsClientLaggingBehind(i)) {

				if (!Ensnared[i] && !AnyClientsLaggingBehind()) {

					g_TeamDistance		=	CalculateTeamDistance(i);
					g_PlayerDistance	=	(L4D2Direct_GetFlowDistance(i) / g_MapFlowDistance);

					if (DistanceWarning[i] && g_TeamDistance + g_WarningDistance < g_PlayerDistance) {

						if (g_WarningCounter[i] + 1 < i_InfractionLimit) {

							g_WarningCounter[i]++;
							PrintToChat(i, "%s %T", s_rup, "Rushing Notice", i, white, orange, green, white, green, g_WarningCounter[i], i_InfractionLimit);
							TeleportRushingPlayer(i);
						}
						else {

							decl String:nClient[MAX_NAME_LENGTH];
							decl String:AuthId[MAX_NAME_LENGTH];
							GetClientName(i, nClient, sizeof(nClient));
							GetClientAuthString(i, AuthId, sizeof(AuthId));
							if (i_InfractionResult > 0) {
							
								PrintToChatAll("%s %t", s_rup, "Rushing Violation", blue, white, orange, nClient);
								if (i_InfractionResult == 1) {

									ForcePlayerSuicide(i);
								}
								else if (i_InfractionResult == 2) {

									KickClient(i);
								}
							}
							DistanceWarning[i]		=	false;

						}
					}
					else if (!DistanceWarning[i] && g_TeamDistance + g_NoticeDistance < g_PlayerDistance) {

						DistanceWarning[i]	=	true;
						PrintToChat(i, "%s %T", s_rup, "Rushing Warning", i, white, orange);
					}
					else if (DistanceWarning[i] && g_TeamDistance + g_NoticeDistance >= g_PlayerDistance) {

						DistanceWarning[i]		=	false;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_IsEnsnared(Handle:timer, any:client) {

	if (IsRoundLive && !IsSurvival() && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client)) {

		if (L4D2_GetInfectedAttacker(client) != -1 || IsIncapacitated(client) || IsClientLaggingBehind(client)) return Plugin_Continue;

		new Float:g_PlayerDistance	=	(L4D2Direct_GetFlowDistance(client) / g_MapFlowDistance);
		new Float:g_TeamDistance		=	CalculateTeamDistance(client);

		if (g_TeamDistance + g_NoticeDistance < g_PlayerDistance) {

			if (g_OldDistance[client] == 0.0) {

				g_OldDistance[client]	=	g_PlayerDistance;
				return Plugin_Continue;
			}
			if (g_PlayerDistance > g_OldDistance[client]) {

				g_OldDistance[client]	=	0.0;
				Ensnared[client]		=	false;
				return Plugin_Stop;
			}
			else {

				g_OldDistance[client]	=	g_PlayerDistance;
				return Plugin_Continue;
			}
		}
		else {

			g_OldDistance[client]		=	0.0;
			Ensnared[client]			=	false;
			return Plugin_Stop;
		}
	}
	return Plugin_Stop;
}

public ReadyUp_ParseConfigFailed(String:config[], String:error[]) {

	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	Format(mapname, sizeof(mapname), "%s%s.cfg", CONFIG_MAPS, mapname);
	
	if (StrContains(config, CONFIG) && configLoadCount == 0 || StrContains(config, mapname) && configLoadCount == 1) {

		IsPluginLoaded = false;
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
		
		if (StrEqual(s_key, "distance_notice")) g_NoticeDistance					= StringToFloat(s_value);
		else if (StrEqual(s_key, "distance_warning")) g_WarningDistance				= StringToFloat(s_value);
		else if (StrEqual(s_key, "distance_ignore")) g_IgnoreDistance				= StringToFloat(s_value);
		else if (StrEqual(s_key, "infraction limit?")) i_InfractionLimit			= StringToInt(s_value);
		else if (StrEqual(s_key, "survivors required?")) i_SurvivorsRequired		= StringToInt(s_value);
		else if (StrEqual(s_key, "ignore incapacitated?")) i_IgnoreIncapacitated	= StringToInt(s_value);
		else if (StrEqual(s_key, "ignore stragglers?")) i_IgnoreStraggler			= StringToInt(s_value);
		else if (StrEqual(s_key, "ignore, kill, or kick?")) i_InfractionResult		= StringToInt(s_value);
	}
	configLoadCount				= 1;

	ReadyUp_NtvGetHeader();
}

public ReadyUp_FwdGetHeader(const String:header[]) {

	strcopy(s_rup, sizeof(s_rup), header);
}

stock bool:IsClientLaggingBehind(client) {

	new Float:g_TeamDistance	=	CalculateTeamDistance(client);
	new Float:g_PlayerDistance	=	(L4D2Direct_GetFlowDistance(client) / g_MapFlowDistance);

	if (g_IgnoreDistance == 0.0 || g_PlayerDistance + g_IgnoreDistance >= g_TeamDistance || Ensnared[client] || IsIncapacitated(client)) return false;
	return true;
}

stock bool:AnyClientsLaggingBehind() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && IsClientLaggingBehind(i)) return true;
	}
	return false;
}

stock ActiveSurvivors() {

	new count						=	0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i)) count++;
	}
	return count;
}

stock TeleportLaggingPlayer(client) {

	new Float:g_TargetDistance;
	new Float:g_PlayerDistance;
	new target				=	-1;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && i != client) {

			g_PlayerDistance		=	(L4D2Direct_GetFlowDistance(i) / g_MapFlowDistance);
			
			if (g_PlayerDistance > g_TargetDistance) {

				g_TargetDistance	=	g_PlayerDistance;
				target			=	i;
			}
		}
	}
	if (target > 0) {

		new Float:g_Origin[3];
		GetClientAbsOrigin(target, g_Origin);
		TeleportEntity(client, g_Origin, NULL_VECTOR, NULL_VECTOR);
		DistanceWarning[client]		=	false;
	}
}

stock TeleportRushingPlayer(client) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && !DistanceWarning[i] && i != client) {

			new Float:g_Origin[3];
			GetClientAbsOrigin(i, g_Origin);
			TeleportEntity(client, g_Origin, NULL_VECTOR, NULL_VECTOR);
			DistanceWarning[client]		=	false;
			break;
		}
	}
}

stock Float:CalculateTeamDistance(client) {

	new Float:g_TeamDistance		=	0.0;
	new counter				=	0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && i != client && !IsLagging[i]) {

			if (i_IgnoreIncapacitated && !IsIncapacitated(i) || !i_IgnoreIncapacitated) {

				g_TeamDistance	+=	(L4D2Direct_GetFlowDistance(i) / g_MapFlowDistance);
				counter++;
			}
		}
	}
	g_TeamDistance /= counter;
	return g_TeamDistance;
}