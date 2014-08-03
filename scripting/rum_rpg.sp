#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3
#define MAX_ENTITIES		2048
#define MAX_CHAT_LENGTH		1024
#define PLUGIN_VERSION		"1.18 ORV"
#define PLUGIN_CONTACT		"Sky"
#define PLUGIN_NAME			"RPG"
#define PLUGIN_DESCRIPTION	"A modular RPG plugin that reads user-generated config files"
#define CONFIG_MAIN					"rpg/config.cfg"
#define CONFIG_EVENTS				"rpg/events.cfg"
#define CONFIG_MAINMENU				"rpg/mainmenu.cfg"
#define CONFIG_MENUSURVIVOR			"rpg/survivormenu.cfg"
#define CONFIG_MENUINFECTED			"rpg/infectedmenu.cfg"
#define CONFIG_POINTS				"rpg/points.cfg"
#define CONFIG_MAPRECORDS			"rpg/maprecords.cfg"
#define CONFIG_STORE				"rpg/store.cfg"
#define CONFIG_WEAPONLEVELS			"rpg/weapon_levels.cfg"
#define CONFIG_TRAILS				"rpg/trails.cfg"
#define LOGFILE				"rum_rpg.txt"
#define DEBUG				false
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN
#define ZOMBIECLASS_SMOKER											1
#define ZOMBIECLASS_BOOMER											2
#define ZOMBIECLASS_HUNTER											3
#define ZOMBIECLASS_SPITTER											4
#define ZOMBIECLASS_JOCKEY											5
#define ZOMBIECLASS_CHARGER											6
#define ZOMBIECLASS_TANK											8
#define ZOMBIECLASS_SURVIVOR										0
#define EXT					1406505600

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include "wrap.inc"
#include "left4downtown.inc"
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

new String:PurchaseSurvEffects[MAXPLAYERS + 1][64];
new String:PurchaseTalentName[MAXPLAYERS + 1][64];
new PurchaseTalentPoints[MAXPLAYERS + 1];
new Handle:a_Trails;
new Handle:TrailsKeys[MAXPLAYERS + 1];
new Handle:TrailsValues[MAXPLAYERS + 1];
new bool:b_IsFinaleActive;
new RoundDamage[MAXPLAYERS + 1];
new String:MVPName[64];
new MVPDamage;
new RoundDamageTotal;
new SpecialsKilled;
new CommonsKilled;
new SurvivorsKilled;
new Handle:WeaponExperienceKeys[MAXPLAYERS + 1];
new Handle:WeaponExperienceValues[MAXPLAYERS + 1];
new Handle:LoadWeaponsSection[MAXPLAYERS + 1];
new bool:b_IsLoadingWeapons[MAXPLAYERS + 1];
new LoadPosWeapons[MAXPLAYERS + 1];
new Handle:WeaponLevelKeys[MAXPLAYERS + 1];
new Handle:WeaponLevelValues[MAXPLAYERS + 1];
new Handle:WeaponLevelSection[MAXPLAYERS + 1];
new Handle:a_WeaponLevels;
new Handle:a_WeaponLevels_Experience[MAXPLAYERS + 1];
new Handle:a_WeaponLevels_Level[MAXPLAYERS + 1];
new Handle:StoreChanceKeys[MAXPLAYERS + 1];
new Handle:StoreChanceValues[MAXPLAYERS + 1];
new Handle:StoreItemNameSection[MAXPLAYERS + 1];
new Handle:StoreItemSection[MAXPLAYERS + 1];
new String:PathSetting[64];
new Handle:SaveSection[MAXPLAYERS + 1];
new OriginalHealth[MAXPLAYERS + 1];
new bool:b_IsLoadingStore[MAXPLAYERS + 1];
new LoadPosStore[MAXPLAYERS + 1];
new Handle:LoadStoreSection[MAXPLAYERS + 1];
new SlatePoints[MAXPLAYERS + 1];
new FreeUpgrades[MAXPLAYERS + 1];
new Handle:StoreTimeKeys[MAXPLAYERS + 1];
new Handle:StoreTimeValues[MAXPLAYERS + 1];
new Handle:StoreKeys[MAXPLAYERS + 1];
new Handle:StoreValues[MAXPLAYERS + 1];
new Handle:StoreMultiplierKeys[MAXPLAYERS + 1];
new Handle:StoreMultiplierValues[MAXPLAYERS + 1];
new Handle:a_Store_Player[MAXPLAYERS + 1];
new bool:b_IsLoadingTrees[MAXPLAYERS + 1];
new bool:b_IsArraysCreated[MAXPLAYERS + 1];
new Handle:a_Store;
new PlayerUpgradesTotal[MAXPLAYERS + 1];
new Float:f_TankCooldown;
new Float:DeathLocation[MAXPLAYERS + 1][3];
new TimePlayed[MAXPLAYERS + 1];
new bool:b_IsLoading[MAXPLAYERS + 1];
new bool:IsSaveDirectorPriority;
new LastLivingSurvivor;
new Float:f_OriginEnd[MAXPLAYERS + 1][3];
new Float:f_OriginStart[MAXPLAYERS + 1][3];
new t_Distance[MAXPLAYERS + 1];
new t_Healing[MAXPLAYERS + 1];
new bool:b_IsActiveRound;
new bool:b_IsFirstPluginLoad;
new String:s_rup[32];
new bool:b_ClearedAdt;
new Handle:MainKeys;
new Handle:MainValues;
new Handle:a_Menu_Talents_Survivor;
new Handle:a_Menu_Talents_Infected;
new Handle:a_Menu_Talents_Passives;
new Handle:a_Menu_Main;
new Handle:a_Events;
new Handle:a_Points;
new Handle:a_Database_Talents;
new Handle:a_Database_Talents_Defaults;
new Handle:a_Database_Talents_Defaults_Name;
new Handle:MenuKeys[MAXPLAYERS + 1];
new Handle:MenuValues[MAXPLAYERS + 1];
new Handle:MenuSection[MAXPLAYERS + 1];
new Handle:TriggerKeys[MAXPLAYERS + 1];
new Handle:TriggerValues[MAXPLAYERS + 1];
new Handle:TriggerSection[MAXPLAYERS + 1];
new Handle:AbilityKeys[MAXPLAYERS + 1];
new Handle:AbilityValues[MAXPLAYERS + 1];
new Handle:AbilitySection[MAXPLAYERS + 1];
new Handle:ChanceKeys[MAXPLAYERS + 1];
new Handle:ChanceValues[MAXPLAYERS + 1];
new Handle:ChanceSection[MAXPLAYERS + 1];
new Handle:EventSection;
new Handle:HookSection;
new Handle:CallKeys;
new Handle:CallValues;
//new Handle:CallSection;
new Handle:DirectorKeys;
new Handle:DirectorValues;
//new Handle:DirectorSection;
new Handle:DatabaseKeys;
new Handle:DatabaseValues;
new Handle:DatabaseSection;
new Handle:a_Database_PlayerTalents_Bots;
new Handle:PlayerAbilitiesCooldown_Bots;
new Handle:BotSaveKeys;
new Handle:BotSaveValues;
new Handle:BotSaveSection;
new Handle:LoadDirectorSection;
new Handle:QueryDirectorKeys;
new Handle:QueryDirectorValues;
new Handle:QueryDirectorSection;
new Handle:FirstDirectorKeys;
new Handle:FirstDirectorValues;
new Handle:FirstDirectorSection;
new Handle:a_Database_PlayerTalents[MAXPLAYERS + 1];
new Handle:PlayerAbilitiesName;
new Handle:PlayerAbilitiesCooldown[MAXPLAYERS + 1];
//new Handle:PlayerInventory[MAXPLAYERS + 1];
new Handle:a_DirectorActions;
new Handle:a_DirectorActions_Cooldown;
new PlayerLevel[MAXPLAYERS + 1];
new PlayerLevelUpgrades[MAXPLAYERS + 1];
new TotalTalentPoints[MAXPLAYERS + 1];
new ExperienceLevel[MAXPLAYERS + 1];
new SkyPoints[MAXPLAYERS + 1];
new String:MenuSelection[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
new Float:Points[MAXPLAYERS + 1];
new DamageAward[MAXPLAYERS + 1][MAXPLAYERS + 1];
new DefaultHealth[MAXPLAYERS + 1];
new String:white[4];
new String:green[4];
new String:blue[4];
new String:orange[4];
new bool:b_IsBlind[MAXPLAYERS + 1];
new bool:b_IsImmune[MAXPLAYERS + 1];
new Float:DamageMultiplier[MAXPLAYERS + 1];
new Handle:DamageMultiplierTimer[MAXPLAYERS + 1];
new Float:DamageMultiplierBase[MAXPLAYERS + 1];
new Float:SpeedMultiplier[MAXPLAYERS + 1];
new Handle:SpeedMultiplierTimer[MAXPLAYERS + 1];
new Float:SpeedMultiplierBase[MAXPLAYERS + 1];
new bool:b_IsJumping[MAXPLAYERS + 1];
new Handle:g_hEffectAdrenaline = INVALID_HANDLE;
new Handle:g_hCallVomitOnPlayer = INVALID_HANDLE;
new Handle:hRevive = INVALID_HANDLE;
new Handle:hRoundRespawn = INVALID_HANDLE;
new Handle:g_hCreateAcid = INVALID_HANDLE;
new Handle:SlowMultiplierTimer[MAXPLAYERS + 1];
new Handle:ZeroGravityTimer[MAXPLAYERS + 1];
new Float:GravityBase[MAXPLAYERS + 1];
new bool:b_GroundRequired[MAXPLAYERS + 1];
new CoveredInBile[MAXPLAYERS + 1][MAXPLAYERS + 1];
new CommonKills[MAXPLAYERS + 1];
new CommonKillsHeadshot[MAXPLAYERS + 1];
new String:OpenedMenu[MAXPLAYERS + 1][64];
new Strength[MAXPLAYERS + 1];
new Luck[MAXPLAYERS + 1];
new Agility[MAXPLAYERS + 1];
new Technique[MAXPLAYERS + 1];
new Endurance[MAXPLAYERS + 1];
new ExperienceOverall[MAXPLAYERS + 1];
new String:CurrentTalentLoading_Bots[64];
//new Handle:a_Database_PlayerTalents_Bots;
//new Handle:PlayerAbilitiesCooldown_Bots;				// Because [designation] = ZombieclassID
new Strength_Bots;
new Luck_Bots;
new Agility_Bots;
new Technique_Bots;
new Endurance_Bots;
new ExperienceLevel_Bots;
new ExperienceOverall_Bots;
new PlayerLevelUpgrades_Bots;
new PlayerLevel_Bots;
new TotalTalentPoints_Bots;
new Float:Points_Director;
new Handle:CommonInfectedQueue;
new g_oAbility = 0;
new Handle:g_hSetClass = INVALID_HANDLE;
new Handle:g_hCreateAbility = INVALID_HANDLE;
new Handle:gd = INVALID_HANDLE;
//new Handle:DirectorPurchaseTimer = INVALID_HANDLE;
new bool:b_IsDirectorTalents[MAXPLAYERS + 1];
new LoadPos_Bots;
new LoadPos[MAXPLAYERS + 1];
new LoadPos_Director;
new Handle:g_Steamgroup;
new Handle:g_Tags;
new RoundTime;
new g_iSprite = 0;
new g_BeaconSprite = 0;

public Action:CMD_DropWeapon(client, args) {

	new CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	decl String:EntityName[64];
	GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));

	new Entity					=	CreateEntityByName(EntityName);
	DispatchSpawn(Entity);

	new Float:Origin[3];
	GetClientAbsOrigin(client, Origin);

	Origin[2] += 64.0;

	TeleportEntity(Entity, Origin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(Entity, MOVETYPE_VPHYSICS);

	if (GetWeaponSlot(Entity) < 2) SetEntProp(Entity, Prop_Send, "m_iClip1", GetEntProp(CurrentEntity, Prop_Send, "m_iClip1"));
	if (!AcceptEntityInput(CurrentEntity, "Kill")) RemoveEdict(CurrentEntity);

	return Plugin_Handled;
}

public Action:CMD_OpenRPGMenu(client, args) {

	BuildMenu(client);
	//SaveAndClear(-1, true);
	return Plugin_Handled;
}

public Action:CMD_LoadBotData(client, args) {

	if (HasCommandAccess(client, GetConfigValue("director talent flags?"))) ClearAndLoadBot();
	return Plugin_Handled;
}

public Action:CMD_LoadData(client, args) {

	ClearAndLoad(client);
	return Plugin_Handled;
}

public Action:CMD_SaveData(client, args) {

	SaveAndClear(client);
	return Plugin_Handled;
}

public OnPluginEnd() {

	LogMessage("Plugin is unloading... maybe you should check the logs.");
	/*SaveAndClear(-1, true);
	for (new i = 0; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && b_IsActiveRound) SaveAndClear(i);
	}*/
}

public OnPluginStart()
{
	if (GetTime() > EXT) return;
	CreateConVar("rum_rpg", PLUGIN_VERSION, "version header", CVAR_SHOW);
	SetConVarString(FindConVar("rum_rpg"), PLUGIN_VERSION);

	g_Steamgroup = FindConVar("sv_steamgroup");
	SetConVarFlags(g_Steamgroup, GetConVarFlags(g_Steamgroup) & ~FCVAR_NOTIFY);
	g_Tags = FindConVar("sv_tags");
	SetConVarFlags(g_Tags, GetConVarFlags(g_Tags) & ~FCVAR_NOTIFY);

	SetConVarFlags(FindConVar("z_common_limit"), GetConVarFlags(FindConVar("z_common_limit")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("z_reserved_wanderers"), GetConVarFlags(FindConVar("z_reserved_wanderers")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("z_mega_mob_size"), GetConVarFlags(FindConVar("z_mega_mob_size")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("z_mob_spawn_max_size"), GetConVarFlags(FindConVar("z_mob_spawn_max_size")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("z_mob_spawn_finale_size"), GetConVarFlags(FindConVar("z_mob_spawn_finale_size")) & ~FCVAR_NOTIFY);
	SetConVarFlags(FindConVar("z_mega_mob_spawn_max_interval"), GetConVarFlags(FindConVar("z_mega_mob_spawn_max_interval")) & ~FCVAR_NOTIFY);
	if (ReadyUp_GetGameMode() == 2) SetConVarFlags(FindConVar("z_tank_health"), GetConVarFlags(FindConVar("z_tank_health")) & ~FCVAR_NOTIFY);

	//LoadTranslations("common.phrases");
	LoadTranslations("rum_rpg.phrases");

	MainKeys										= CreateArray(64);
	MainValues										= CreateArray(64);
	a_Menu_Talents_Survivor							= CreateArray(3);
	a_Menu_Talents_Infected							= CreateArray(3);
	a_Menu_Talents_Passives							= CreateArray(3);
	a_Menu_Main										= CreateArray(3);
	a_Events										= CreateArray(3);
	a_Points										= CreateArray(3);
	a_Store											= CreateArray(3);
	a_WeaponLevels									= CreateArray(3);
	a_Trails										= CreateArray(3);
	a_Database_Talents								= CreateArray(64);
	a_Database_Talents_Defaults						= CreateArray(64);
	a_Database_Talents_Defaults_Name				= CreateArray(64);
	EventSection									= CreateArray(64);
	HookSection										= CreateArray(64);
	CallKeys										= CreateArray(64);
	CallValues										= CreateArray(64);
	DirectorKeys									= CreateArray(64);
	DirectorValues									= CreateArray(64);
	DatabaseKeys									= CreateArray(64);
	DatabaseValues									= CreateArray(64);
	DatabaseSection									= CreateArray(64);
	a_Database_PlayerTalents_Bots					= CreateArray(64);
	PlayerAbilitiesCooldown_Bots					= CreateArray(64);
	BotSaveKeys										= CreateArray(64);
	BotSaveValues									= CreateArray(64);
	BotSaveSection									= CreateArray(64);
	LoadDirectorSection								= CreateArray(64);
	QueryDirectorKeys								= CreateArray(64);
	QueryDirectorValues								= CreateArray(64);
	QueryDirectorSection							= CreateArray(64);
	FirstDirectorKeys								= CreateArray(64);
	FirstDirectorValues								= CreateArray(64);
	FirstDirectorSection							= CreateArray(64);
	PlayerAbilitiesName								= CreateArray(64);
	a_DirectorActions								= CreateArray(3);
	a_DirectorActions_Cooldown						= CreateArray(64);

	for (new i = 1; i <= MAXPLAYERS; i++) {

		MenuKeys[i]								= CreateArray(64);
		MenuValues[i]							= CreateArray(64);
		MenuSection[i]							= CreateArray(64);
		TriggerKeys[i]							= CreateArray(64);
		TriggerValues[i]						= CreateArray(64);
		TriggerSection[i]						= CreateArray(64);
		AbilityKeys[i]							= CreateArray(64);
		AbilityValues[i]						= CreateArray(64);
		AbilitySection[i]						= CreateArray(64);
		ChanceKeys[i]							= CreateArray(64);
		ChanceValues[i]							= CreateArray(64);
		ChanceSection[i]						= CreateArray(64);
		a_Database_PlayerTalents[i]				= CreateArray(64);
		PlayerAbilitiesCooldown[i]				= CreateArray(64);
		a_Store_Player[i]						= CreateArray(64);
		StoreKeys[i]							= CreateArray(64);
		StoreValues[i]							= CreateArray(64);
		StoreMultiplierKeys[i]					= CreateArray(64);
		StoreMultiplierValues[i]				= CreateArray(64);
		StoreTimeKeys[i]						= CreateArray(64);
		StoreTimeValues[i]						= CreateArray(64);
		LoadStoreSection[i]						= CreateArray(64);
		SaveSection[i]							= CreateArray(64);
		StoreChanceKeys[i]						= CreateArray(64);
		StoreChanceValues[i]					= CreateArray(64);
		StoreItemNameSection[i]					= CreateArray(64);
		StoreItemSection[i]						= CreateArray(64);
		a_WeaponLevels_Level[i]					= CreateArray(64);
		a_WeaponLevels_Experience[i]			= CreateArray(64);
		WeaponLevelKeys[i]						= CreateArray(64);
		WeaponLevelValues[i]					= CreateArray(64);
		WeaponLevelSection[i]					= CreateArray(64);
		LoadWeaponsSection[i]					= CreateArray(64);
		WeaponExperienceKeys[i]					= CreateArray(64);
		WeaponExperienceValues[i]				= CreateArray(64);
		TrailsKeys[i]							= CreateArray(64);
		TrailsValues[i]							= CreateArray(64);
	}

	RegAdminCmd("resettpl", Cmd_ResetTPL, ADMFLAG_KICK);
	// These are mandatory because of quick commands, so I hardcode the entries.
	RegConsoleCmd("say", CMD_ChatCommand);
	RegConsoleCmd("say_team", CMD_TeamChatCommand);

	Format(white, sizeof(white), "\x01");
	Format(orange, sizeof(orange), "\x04");
	Format(green, sizeof(green), "\x05");
	Format(blue, sizeof(blue), "\x03");

	gd = LoadGameConfigFile("rum_rpg");
	if (gd != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "SetClass");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSetClass = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CreateAbility");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hCreateAbility = EndPrepSDKCall();

		g_oAbility = GameConfGetOffset(gd, "oAbility");

		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CSpitterProjectile_Detonate");
		g_hCreateAcid = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CTerrorPlayer_OnAdrenalineUsed");
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		g_hEffectAdrenaline = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hCallVomitOnPlayer = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CTerrorPlayer_OnRevived");
		hRevive = EndPrepSDKCall();
	}
	else {

		SetFailState("Error: Unable to load Gamedata rum_rpg.txt");
	}
}

public ReadyUp_TrueDisconnect(client) {

	if (IsLegitimateClient(client) && !IsFakeClient(client)) {

		b_IsLoading[client] = false;
		if (b_IsActiveRound) SaveAndClear(client);
	}
}

public OnMapStart() {

	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/props_interiors/toaster.mdl", true);
	g_iSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_BeaconSprite = PrecacheModel("materials/sprites/halo01.vmt");
	b_IsActiveRound = false;

	Points_Director = 0.0;
}

public OnMapEnd() {

	SubmitEventHooks(0);
	b_ClearedAdt									= false;
	SaveAndClear(-1, true);
	Format(PathSetting, sizeof(PathSetting), "none");		// reset when a map ends.
}

public OnConfigsExecuted() {

	// This can call more than once, and we only want it to fire once.
	// The variable resets to false when a map ends.
	if (!b_ClearedAdt) {

		b_ClearedAdt								= true;

		ClearArray(Handle:MainKeys);
		ClearArray(Handle:MainValues);
		ClearArray(Handle:a_Menu_Talents_Survivor);
		ClearArray(Handle:a_Menu_Talents_Infected);
		ClearArray(Handle:a_Menu_Talents_Passives);
		ClearArray(Handle:a_Menu_Main);
		ClearArray(Handle:a_Events);
		ClearArray(Handle:a_Points);
		ClearArray(Handle:a_Store);
		ClearArray(Handle:a_WeaponLevels);
		ClearArray(Handle:a_Trails);
		ClearArray(Handle:a_Database_Talents);
		ClearArray(Handle:EventSection);
		ClearArray(Handle:HookSection);
		ClearArray(Handle:CallKeys);
		ClearArray(Handle:CallValues);
		ClearArray(Handle:DirectorKeys);
		ClearArray(Handle:DirectorValues);
		ClearArray(Handle:DatabaseKeys);
		ClearArray(Handle:DatabaseValues);
		ClearArray(Handle:DatabaseSection);
		ClearArray(Handle:a_Database_PlayerTalents_Bots);
		ClearArray(Handle:PlayerAbilitiesCooldown_Bots);
		ClearArray(Handle:BotSaveKeys);
		ClearArray(Handle:BotSaveValues);
		ClearArray(Handle:BotSaveSection);
		ClearArray(Handle:LoadDirectorSection);
		ClearArray(Handle:QueryDirectorKeys);
		ClearArray(Handle:QueryDirectorValues);
		ClearArray(Handle:QueryDirectorSection);
		ClearArray(Handle:FirstDirectorKeys);
		ClearArray(Handle:FirstDirectorValues);
		ClearArray(Handle:FirstDirectorSection);
		ClearArray(Handle:PlayerAbilitiesName);
		ClearArray(Handle:a_DirectorActions);
		ClearArray(Handle:a_DirectorActions_Cooldown);

		CreateTimer(0.1, Timer_ExecuteConfig, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_ExecuteConfig(Handle:timer) {

	if (ReadyUp_NtvConfigProcessing() == 0) {

		ReadyUp_ParseConfig(CONFIG_MAIN);
		ReadyUp_ParseConfig(CONFIG_EVENTS);
		ReadyUp_ParseConfig(CONFIG_MENUSURVIVOR);
		ReadyUp_ParseConfig(CONFIG_MENUINFECTED);
		ReadyUp_ParseConfig(CONFIG_POINTS);
		ReadyUp_ParseConfig(CONFIG_STORE);
		ReadyUp_ParseConfig(CONFIG_WEAPONLEVELS);
		ReadyUp_ParseConfig(CONFIG_TRAILS);
		ReadyUp_ParseConfig(CONFIG_MAINMENU);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

stock RemoveMeleeWeapons() {

	new ent = -1;
	//decl String:Model[64];
	while ((ent = FindEntityByClassname(ent, "weapon_defibrillator")) != -1) {

		LogMessage("Removing Defibrillators");
		if (!AcceptEntityInput(ent, "Kill")) RemoveEdict(ent);
	}
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "weapon_defibrillator_spawn")) != -1) {

		LogMessage("Removing Defibrillators");
		if (!AcceptEntityInput(ent, "Kill")) RemoveEdict(ent);
	}
}

public ReadyUp_ReadyUpEnd() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && !b_IsArraysCreated[i]) CreateTimer(0.1, Timer_LoadData, i, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_LoadData(Handle:timer, any:client) {

	if (IsClientInGame(client) && !IsFakeClient(client)) {

		ResetData(client);
		ClearAndLoad(client);
	}
	return Plugin_Stop;
}

public ReadyUp_CheckpointDoorStartOpened() {

	RoundTime					=	GetTime();

	PrintToChatAll("%t", "Round Statistics", white, green, AddCommasToString(CommonsKilled), orange, green, AddCommasToString(SpecialsKilled), blue, green, AddCommasToString(SurvivorsKilled), white, green, AddCommasToString(RoundDamageTotal), white, blue, MVPName, white, green, AddCommasToString(MVPDamage));

	SpecialsKilled				=	0;
	CommonsKilled				=	0;
	SurvivorsKilled				=	0;
	RoundDamageTotal			=	0;
	MVPDamage					=	0;
	b_IsFinaleActive			=	false;

	if (IsSaveDirectorPriority) PrintToChatAll("%t", "Director Priority Save Enabled", white, green);

	if (!StrEqual(GetConfigValue("path setting?"), "none")) {

		if (!StrEqual(GetConfigValue("path setting?"), "random")) ServerCommand("sm_forcepath %s", GetConfigValue("path setting?"));
		else {

			if (StrEqual(PathSetting, "none") && ReadyUp_GetGameMode() == 2 || ReadyUp_GetGameMode() != 2) {

				new random = GetRandomInt(1, 100);
				if (random <= 33) Format(PathSetting, sizeof(PathSetting), "easy");
				else if (random <= 66) Format(PathSetting, sizeof(PathSetting), "medium");
				else Format(PathSetting, sizeof(PathSetting), "hard");
			}
			ServerCommand("sm_forcepath %s", PathSetting);
		}
	}

	b_IsActiveRound = true;	
	f_TankCooldown				=	-1.0;
	Points_Director = 0.0;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i)) {

			RoundDamage[i] = 0;
			ResetCoveredInBile(i);
		}
	}

	if (ReadyUp_GetGameMode() != 2) {

		// It destroys itself when a round ends.
		CreateTimer(1.0, Timer_DirectorPurchaseTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	CreateTimer(StringToFloat(GetConfigValue("settings check interval?")), Timer_SettingsCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, Timer_DeductStoreTime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Timer_PeriodicTalents, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	if (StringToInt(GetConfigValue("rpg mode?")) > 0) CreateTimer(1.0, Timer_AwardSkyPoints, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	RemoveMeleeWeapons();
	ClearRelevantData();
	LastLivingSurvivor = 1;

	new size = GetArraySize(a_DirectorActions);
	ResizeArray(a_DirectorActions_Cooldown, size);
	for (new i = 0; i < size; i++) SetArrayString(a_DirectorActions_Cooldown, i, "0");

	if (CommonInfectedQueue == INVALID_HANDLE) CommonInfectedQueue = CreateArray(64);
	ClearArray(CommonInfectedQueue);

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			DefaultHealth[i] = 100;
			PlayerSpawnAbilityTrigger(i);
			ExecCheatCommand(i, "give", "health");
			GiveMaximumHealth(i);

			SpeedMultiplierBase[i] = 1.0;
			if (IsValidEntity(i)) SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplierBase[i]);
			Points[i] = 0.0;

			ResetCoveredInBile(i);
		}
	}
}

stock ResetCoveredInBile(client) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i)) {

			CoveredInBile[client][i] = -1;
			CoveredInBile[i][client] = -1;
		}
	}
}

public Action:CMD_GiveStorePoints(client, args)
{
	if (!HasCommandAccess(client, GetConfigValue("director talent flags?"))) return Plugin_Handled;
	if (args < 2)
	{
		PrintToChat(client, "%T", "Give Store Points Syntax", client, orange, white);
		return Plugin_Handled;
	}
	decl String:arg[MAX_NAME_LENGTH], String:arg2[4];
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	new targetclient;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++) targetclient = target_list[i];
		decl String:Name[MAX_NAME_LENGTH];
		GetClientName(targetclient, Name, sizeof(Name));

		SkyPoints[targetclient] += StringToInt(arg2);

		PrintToChat(client, "%T", "Store Points Award Given", client, white, green, arg2, white, orange, Name);
		PrintToChat(targetclient, "%T", "Store Points Award Received", client, white, green, arg2, white);
	}

	return Plugin_Handled;
}

public ReadyUp_CampaignComplete() {

	b_IsActiveRound = false;
	Points_Director = 0.0;

	new Seconds			= GetTime() - RoundTime;
	new Minutes			= 0;

	while (Seconds >= 60) {

		Minutes++;
		Seconds -= 60;
	}

	PrintToChatAll("%t", "Round Time", orange, blue, Minutes, white, blue, Seconds, white);
	if (CommonInfectedQueue == INVALID_HANDLE) CommonInfectedQueue = CreateArray(64);
	ClearArray(CommonInfectedQueue);

	SaveAndClear(-1, true);
	for (new i = 0; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i)) {

			SaveAndClear(i);
		}
	}
	PrintToChatAll("%t", "Data Saved", white, orange);
}

public ReadyUp_RoundIsOver(gamemode) {

	b_IsActiveRound = false;
	Points_Director = 0.0;

	new Seconds			= GetTime() - RoundTime;
	new Minutes			= 0;

	while (Seconds >= 60) {

		Minutes++;
		Seconds -= 60;
	}

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i)) {

			if (RoundDamage[i] > MVPDamage) {

				GetClientName(i, MVPName, sizeof(MVPName));
				MVPDamage = RoundDamage[i];
			}
		}
	}

	PrintToChatAll("%t", "Round Time", orange, blue, Minutes, white, blue, Seconds, white);
	if (CommonInfectedQueue == INVALID_HANDLE) CommonInfectedQueue = CreateArray(64);
	ClearArray(CommonInfectedQueue);

	SaveAndClear(-1, true);
	for (new i = 0; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i)) {

			SaveAndClear(i);
		}
	}
	PrintToChatAll("%t", "Data Saved", white, orange);
}

public ReadyUp_ParseConfigFailed(String:config[], String:error[]) {

	if (StrEqual(config, CONFIG_MAIN) ||
		StrEqual(config, CONFIG_EVENTS) ||
		StrEqual(config, CONFIG_MENUSURVIVOR) ||
		StrEqual(config, CONFIG_MENUINFECTED) ||
		StrEqual(config, CONFIG_MAINMENU) ||
		StrEqual(config, CONFIG_POINTS) ||
		StrEqual(config, CONFIG_STORE) ||
		StrEqual(config, CONFIG_WEAPONLEVELS) ||
		StrEqual(config, CONFIG_TRAILS)) {
	
		SetFailState("%s , %s", config, error);
	}
}

public ReadyUp_LoadFromConfigEx(Handle:key, Handle:value, Handle:section, String:configname[], keyCount) {

	//PrintToChatAll("Size: %d config: %s", GetArraySize(Handle:key), configname);

	if (!StrEqual(configname, CONFIG_MAIN) &&
		!StrEqual(configname, CONFIG_EVENTS) &&
		!StrEqual(configname, CONFIG_MENUSURVIVOR) &&
		!StrEqual(configname, CONFIG_MENUINFECTED) &&
		!StrEqual(configname, CONFIG_MAINMENU) &&
		!StrEqual(configname, CONFIG_POINTS) &&
		!StrEqual(configname, CONFIG_STORE) &&
		!StrEqual(configname, CONFIG_WEAPONLEVELS) &&
		!StrEqual(configname, CONFIG_TRAILS)) return;

	decl String:s_key[64];
	decl String:s_value[64];
	decl String:s_section[64];

	new Handle:TalentKeys		=					CreateArray(64);
	new Handle:TalentValues		=					CreateArray(64);
	new Handle:TalentSection	=					CreateArray(64);

	new lastPosition = 0;
	new counter = 0;

	if (keyCount > 0) {

		if (StrEqual(configname, CONFIG_MENUSURVIVOR)) ResizeArray(a_Menu_Talents_Survivor, keyCount);
		else if (StrEqual(configname, CONFIG_MENUINFECTED)) ResizeArray(a_Menu_Talents_Infected, keyCount);
		else if (StrEqual(configname, CONFIG_MAINMENU)) ResizeArray(a_Menu_Main, keyCount);
		else if (StrEqual(configname, CONFIG_EVENTS)) ResizeArray(a_Events, keyCount);
		else if (StrEqual(configname, CONFIG_POINTS)) ResizeArray(a_Points, keyCount);
		else if (StrEqual(configname, CONFIG_STORE)) ResizeArray(a_Store, keyCount);
		else if (StrEqual(configname, CONFIG_WEAPONLEVELS)) ResizeArray(a_WeaponLevels, keyCount);
		else if (StrEqual(configname, CONFIG_TRAILS)) ResizeArray(a_Trails, keyCount);
	}

	//PrintToChatAll("CONFIG: %s", configname);

	new a_Size						= GetArraySize(key);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:key, i, s_key, sizeof(s_key));
		GetArrayString(Handle:value, i, s_value, sizeof(s_value));

		PushArrayString(TalentKeys, s_key);
		PushArrayString(TalentValues, s_value);

		if (StrEqual(configname, CONFIG_MAIN)) {

			PushArrayString(Handle:MainKeys, s_key);
			PushArrayString(Handle:MainValues, s_value);
		}
		//} else {
		if (StrEqual(s_key, "EOM")) {

			GetArrayString(Handle:section, i, s_section, sizeof(s_section));
			PushArrayString(TalentSection, s_section);

			if (StrEqual(configname, CONFIG_MENUSURVIVOR)) SetConfigArrays(configname, a_Menu_Talents_Survivor, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Menu_Talents_Survivor), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_MENUINFECTED)) SetConfigArrays(configname, a_Menu_Talents_Infected, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Menu_Talents_Infected), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_MAINMENU)) SetConfigArrays(configname, a_Menu_Main, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Menu_Main), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_EVENTS)) SetConfigArrays(configname, a_Events, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Events), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_POINTS)) SetConfigArrays(configname, a_Points, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Points), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_STORE)) SetConfigArrays(configname, a_Store, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Store), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_WEAPONLEVELS)) SetConfigArrays(configname, a_WeaponLevels, TalentKeys, TalentValues, TalentSection, GetArraySize(a_WeaponLevels), lastPosition - counter);
			else if (StrEqual(configname, CONFIG_TRAILS)) SetConfigArrays(configname, a_Trails, TalentKeys, TalentValues, TalentSection, GetArraySize(a_Trails), lastPosition - counter);
			
			lastPosition = i + 1;
			//counter++;
		}
	}
	//ClearArray(TalentKeys);
	//ClearArray(TalentValues);
	//ClearArray(TalentSection);


	if (StrEqual(configname, CONFIG_POINTS)) {

		if (a_DirectorActions != INVALID_HANDLE) ClearArray(a_DirectorActions);
		a_DirectorActions			=	CreateArray(3);
		if (a_DirectorActions_Cooldown != INVALID_HANDLE) ClearArray(a_DirectorActions_Cooldown);
		a_DirectorActions_Cooldown	=	CreateArray(64);

		new size						=	GetArraySize(a_Points);
		new Handle:Keys					=	CreateArray(64);
		new Handle:Values				=	CreateArray(64);
		new Handle:Section				=	CreateArray(64);
		new sizer						=	0;

		for (new i = 0; i < size; i++) {

			Keys						=	GetArrayCell(a_Points, i, 0);
			Values						=	GetArrayCell(a_Points, i, 1);
			Section						=	GetArrayCell(a_Points, i, 2);

			new size2					=	GetArraySize(Keys);
			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:Keys, ii, s_key, sizeof(s_key));
				GetArrayString(Handle:Values, ii, s_value, sizeof(s_value));

				if (StrEqual(s_key, "model?")) PrecacheModel(s_value, false);
				else if (StrEqual(s_key, "director option?") && StrEqual(s_value, "1")) {

					sizer				=	GetArraySize(a_DirectorActions);

					ResizeArray(a_DirectorActions, sizer + 1);
					SetArrayCell(a_DirectorActions, sizer, Keys, 0);
					SetArrayCell(a_DirectorActions, sizer, Values, 1);
					SetArrayCell(a_DirectorActions, sizer, Section, 2);

					ResizeArray(a_DirectorActions_Cooldown, sizer + 1);
					SetArrayString(a_DirectorActions_Cooldown, sizer, "0");						// 0 means not on cooldown. 1 means on cooldown. This resets every map.
				}
			}
		}
		MySQL_Init();	// Testing to see if it works this way.
		//LogMessage("DIRECTOR ACTIONS SIZE: %d", GetArraySize(a_DirectorActions));
	}

	if (StrEqual(configname, CONFIG_MAIN) && !b_IsFirstPluginLoad) {

		b_IsFirstPluginLoad = true;
		RegConsoleCmd(GetConfigValue("rpg menu command?"), CMD_OpenRPGMenu);
		RegConsoleCmd(GetConfigValue("rpg data force load?"), CMD_LoadData);
		RegConsoleCmd(GetConfigValue("rpg data force save?"), CMD_SaveData);
		RegConsoleCmd(GetConfigValue("drop weapon command?"), CMD_DropWeapon);
		RegConsoleCmd(GetConfigValue("director talent command?"), CMD_DirectorTalentToggle);
		RegConsoleCmd(GetConfigValue("rpg data force load bot?"), CMD_LoadBotData);
		RegConsoleCmd(GetConfigValue("director priority save toggle?"), CMD_DirectorSaveToggle);
		RegConsoleCmd(GetConfigValue("rpg data erase?"), CMD_DataErase);
		RegConsoleCmd(GetConfigValue("give store points command?"), CMD_GiveStorePoints);
	}

	if (StrEqual(configname, CONFIG_EVENTS)) SubmitEventHooks(1);
	ReadyUp_NtvGetHeader();

	if (StrEqual(configname, CONFIG_MAIN)) {

		PrecacheModel(GetConfigValue("slate item model?"), true);
		PrecacheModel(GetConfigValue("store item model?"), true);
		PrecacheModel(GetConfigValue("locked talent model?"), true);
	}
}

public Action:CMD_DataErase(client, args) {

	CreateNewPlayer(client, false);
	return Plugin_Handled;
}

public Action:CMD_DirectorSaveToggle(client, args) {

	if (HasCommandAccess(client, GetConfigValue("director talent flags?"))) {

		if (IsSaveDirectorPriority) {

			IsSaveDirectorPriority				= false;
			PrintToChatAll("%t", "Director Priority Save Disabled", white, green);
		}
		else {

			IsSaveDirectorPriority				= true;
			PrintToChatAll("%t", "Director Priority Save Enabled", white, green);
		}
	}
	return Plugin_Handled;
}

public Action:CMD_DirectorTalentToggle(client, args) {

	if (HasCommandAccess(client, GetConfigValue("director talent flags?"))) {

		if (b_IsDirectorTalents[client]) {

			b_IsDirectorTalents[client]			= false;
			PrintToChat(client, "%T", "Director Talents Disabled", client, white, green);
		}
		else {

			b_IsDirectorTalents[client]			= true;
			PrintToChat(client, "%T", "Director Talents Enabled", client, white, green);
		}
	}
	return Plugin_Handled;
}

stock SetConfigArrays(String:Config[], Handle:Main, Handle:Keys, Handle:Values, Handle:Section, size, last) {

	decl String:text[64];
	//GetArrayString(Section, 0, text, sizeof(text));

	new Handle:TalentKey = CreateArray(64);
	new Handle:TalentValue = CreateArray(64);
	new Handle:TalentSection = CreateArray(64);

	decl String:key[64];
	decl String:value[64];
	new a_Size = GetArraySize(Keys);

	for (new i = last; i < a_Size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		GetArrayString(Handle:Values, i, value, sizeof(value));
		//if (DEBUG) PrintToChatAll("\x04Key: \x01%s \x04Value: \x01%s", key, value);

		PushArrayString(TalentKey, key);
		PushArrayString(TalentValue, value);
	}

	GetArrayString(Handle:Section, size, text, sizeof(text));
	PushArrayString(TalentSection, text);
	if (StrEqual(Config, CONFIG_MENUSURVIVOR) || StrEqual(Config, CONFIG_MENUINFECTED)) PushArrayString(a_Database_Talents, text);

	ResizeArray(Main, size + 1);
	SetArrayCell(Main, size, TalentKey, 0);
	SetArrayCell(Main, size, TalentValue, 1);
	SetArrayCell(Main, size, TalentSection, 2);
}

public ReadyUp_FwdGetHeader(const String:header[]) {

	strcopy(s_rup, sizeof(s_rup), header);
}

#include "rpg/rpg_menu.sp"
#include "rpg/rpg_menu_points.sp"
#include "rpg/rpg_menu_store.sp"
#include "rpg/rpg_menu_director.sp"
#include "rpg/rpg_timers.sp"
#include "rpg/rpg_functions.sp"
#include "rpg/rpg_events.sp"
#include "rpg/rpg_database.sp"