new Handle:hDatabase												=	INVALID_HANDLE;

MySQL_Init()
{
	SQL_TConnect(DBConnect, GetConfigValue("database prefix?"));
}

public DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Unable to connect to database: %s", error);
		return;
	}

	hDatabase = hndl;

	if (StringToInt(GetConfigValue("generate database?")) == 1) {

		SQL_FastQuery(hDatabase, "SET NAMES \"UTF8\"");

		decl String:tquery[PLATFORM_MAX_PATH];
		decl String:text[64];

		Format(tquery, sizeof(tquery), "CREATE TABLE IF NOT EXISTS `%s` (`steam_id` varchar(32) NOT NULL, PRIMARY KEY (`steam_id`)) ENGINE=MyISAM;", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `player name` varchar(32) NOT NULL DEFAULT 'none';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `strength` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `luck` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `agility` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `technique` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `endurance` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);

		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `experience` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `experience overall` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `upgrade cost` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `level` int(32) NOT NULL DEFAULT '1';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), GetConfigValue("sky points menu name?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `time played` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `talent points` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `total upgrades` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `free upgrades` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);
		Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `slate points` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"));
		SQL_TQuery(hDatabase, QueryResults, tquery);

		/*new size			=	GetArraySize(a_Database_Talents);

		for (new i = 0; i < size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}*/

		ClearArray(Handle:a_Database_Talents_Defaults);
		ClearArray(Handle:a_Database_Talents_Defaults_Name);

		new size2			=	0;
		decl String:key[64];
		decl String:value[64];

		new size			=	GetArraySize(a_Menu_Talents_Survivor);
		for (new i = 0; i < size; i++) {

			DatabaseKeys			=	GetArrayCell(a_Menu_Talents_Survivor, i, 0);
			DatabaseValues			=	GetArrayCell(a_Menu_Talents_Survivor, i, 1);
			DatabaseSection			=	GetArrayCell(a_Menu_Talents_Survivor, i, 2);

			GetArrayString(Handle:DatabaseSection, 0, text, sizeof(text));
			PushArrayString(Handle:a_Database_Talents_Defaults_Name, text);

			size2					=	GetArraySize(DatabaseKeys);
			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:DatabaseKeys, ii, key, sizeof(key));
				GetArrayString(Handle:DatabaseValues, ii, value, sizeof(value));

				if (StrEqual(key, "ability inherited?")) {

					PushArrayString(Handle:a_Database_Talents_Defaults, value);

					if (StringToInt(value) == 1) Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), text);
					else Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '-1';", GetConfigValue("database prefix?"), text);
					SQL_TQuery(hDatabase, QueryResults, tquery);

					break;
				}
			}
		}

		size			=	GetArraySize(a_Menu_Talents_Infected);
		for (new i = 0; i < size; i++) {

			DatabaseKeys			=	GetArrayCell(a_Menu_Talents_Infected, i, 0);
			DatabaseValues			=	GetArrayCell(a_Menu_Talents_Infected, i, 1);
			DatabaseSection			=	GetArrayCell(a_Menu_Talents_Infected, i, 2);

			GetArrayString(Handle:DatabaseSection, 0, text, sizeof(text));
			PushArrayString(Handle:a_Database_Talents_Defaults_Name, text);

			size2					=	GetArraySize(DatabaseKeys);
			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:DatabaseKeys, ii, key, sizeof(key));
				GetArrayString(Handle:DatabaseValues, ii, value, sizeof(value));

				if (StrEqual(key, "ability inherited?")) {

					PushArrayString(Handle:a_Database_Talents_Defaults, value);
					if (StringToInt(value) == 1) Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), text);
					else Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '-1';", GetConfigValue("database prefix?"), text);
					SQL_TQuery(hDatabase, QueryResults, tquery);

					break;
				}
			}
		}

		size				=	GetArraySize(a_DirectorActions);

		for (new i = 0; i < size; i++) {

			DatabaseSection			=	GetArrayCell(a_DirectorActions, i, 2);
			GetArrayString(Handle:DatabaseSection, 0, text, sizeof(text));
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}

		size				=	GetArraySize(a_Store);

		for (new i = 0; i < size; i++) {

			DatabaseSection			=	GetArrayCell(a_Store, i, 2);
			GetArrayString(Handle:DatabaseSection, 0, text, sizeof(text));
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}

		size				=	GetArraySize(a_WeaponLevels);

		for (new i = 0; i < size; i++) {

			DatabaseSection			=	GetArrayCell(a_WeaponLevels, i, 2);
			GetArrayString(Handle:DatabaseSection, 0, text, sizeof(text));
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s` int(32) NOT NULL DEFAULT '0';", GetConfigValue("database prefix?"), text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
			Format(tquery, sizeof(tquery), "ALTER TABLE `%s` ADD `%s level` int(32) NOT NULL DEFAULT '1';", GetConfigValue("database prefix?"), text);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}
	}

	new size = GetArraySize(a_Database_Talents);

	ResizeArray(Handle:a_Database_PlayerTalents_Bots, size);
	ResizeArray(Handle:PlayerAbilitiesCooldown_Bots, size);

	//IsSaveDirectorPriority = false;		// By default, director priorities ARE NOT saved. Must be toggled by an admin.

	Format(CurrentTalentLoading_Bots, sizeof(CurrentTalentLoading_Bots), "-1");
	ClearAndLoadBot();
}

public QueryResults(Handle:owner, Handle:hndl, const String:error[], any:client) { }

public ClearAndLoadBot() {

	PlayerLevel_Bots = 0;
	decl String:tquery[512];
	decl String:key[64];
	LoadPos_Bots = 0;
	Format(key, sizeof(key), GetConfigValue("director steam id?"));
	Format(CurrentTalentLoading_Bots, sizeof(CurrentTalentLoading_Bots), "-1");

	Format(tquery, sizeof(tquery), "SELECT `strength`, `luck`, `agility`, `technique`, `endurance`, `experience`, `experience overall`, `upgrade cost`, `level`, `talent points` FROM `%s` WHERE (`steam_id` = '%s');", GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, QueryResults_LoadBot, tquery, -1);

	LoadDirectorActions();
}

stock ResetData(client) {

	Points[client]					= 0.0;
	SlatePoints[client]				= 0;
	FreeUpgrades[client]			= 0;
	b_IsDirectorTalents[client]		= false;
	b_IsJumping[client]				= false;
	ModifyGravity(client);
	ResetCoveredInBile(client);
	SpeedMultiplierBase[client]		= 1.0;
	if (IsLegitimateClientAlive(client) && !IsGhost(client)) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplierBase[client]);
	TimePlayed[client]				= 0;
	t_Distance[client]				= 0;
	t_Healing[client]				= 0;
	b_IsBlind[client]				= false;
	b_IsImmune[client]				= false;
	DamageMultiplier[client]		= 0.0;
	DamageMultiplierBase[client]	= 1.0;
	GravityBase[client]				= 1.0;
	CommonKills[client]				= 0;
	CommonKillsHeadshot[client]		= 0;
}

stock ClearAndLoad(client)
{
	b_IsLoading[client] = true;
	PlayerLevel[client] = 0;
	ResetData(client);

	decl String:tquery[512];
	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));
	LoadPos[client] = 0;

	new size = GetArraySize(Handle:a_Database_Talents);

	if (!b_IsArraysCreated[client]) {

		b_IsArraysCreated[client]			= true;
		/*ClearArray(Handle:MenuKeys[client]);
		ClearArray(Handle:MenuValues[client]);
		ClearArray(Handle:MenuSection[client]);
		ClearArray(Handle:TriggerKeys[client]);
		ClearArray(Handle:TriggerValues[client]);
		ClearArray(Handle:TriggerSection[client]);
		ClearArray(Handle:AbilityKeys[client]);
		ClearArray(Handle:AbilityValues[client]);
		ClearArray(Handle:AbilitySection[client]);
		ClearArray(Handle:ChanceKeys[client]);
		ClearArray(Handle:ChanceValues[client]);
		ClearArray(Handle:ChanceSection[client]);
		ClearArray(Handle:a_Database_PlayerTalents[client]);
		ClearArray(Handle:PlayerAbilitiesCooldown[client]);*/
	}

	if (GetArraySize(a_Database_PlayerTalents[client]) != size) {

		ResizeArray(a_Database_PlayerTalents[client], size);
		ResizeArray(PlayerAbilitiesCooldown[client], size);
	}

	if (GetArraySize(a_Store_Player[client]) != GetArraySize(a_Store)) {

		ResizeArray(a_Store_Player[client], GetArraySize(a_Store));
	}

	for (new i = 0; i < GetArraySize(a_Store); i++) {

		SetArrayString(a_Store_Player[client], i, "0");				// We clear all players arrays for the store.
	}

	size				= GetArraySize(a_WeaponLevels);

	if (GetArraySize(a_WeaponLevels_Experience[client]) != size) {

		ResizeArray(a_WeaponLevels_Experience[client], size);
		ResizeArray(a_WeaponLevels_Level[client], size);
	}

	for (new i = 0; i < size; i++) {

		SetArrayString(Handle:a_WeaponLevels_Experience[client], i, "0");
		SetArrayString(Handle:a_WeaponLevels_Level[client], i, "1");
	}

	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `strength`, `luck`, `agility`, `technique`, `endurance`, `experience`, `experience overall`, `upgrade cost`, `level`, `%s`, `time played`, `talent points`, `total upgrades`, `free upgrades`, `slate points` FROM `%s` WHERE (`steam_id` = '%s');", GetConfigValue("sky points menu name?"), GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, QueryResults_Load, tquery, client);
}

stock CreateNewPlayer(client, bool:bot = false) {

	if (!bot && IsLegitimateClient(client)) {

		Strength[client]				=	StringToInt(GetConfigValue("strength?"));
		Luck[client]					=	StringToInt(GetConfigValue("luck?"));
		Agility[client]					=	StringToInt(GetConfigValue("agility?"));
		Technique[client]				=	StringToInt(GetConfigValue("technique?"));
		Endurance[client]				=	StringToInt(GetConfigValue("endurance?"));
		ExperienceLevel[client]			=	0;
		ExperienceOverall[client]		=	0;
		PlayerLevelUpgrades[client]		=	0;
		PlayerLevel[client]				=	1;
		SkyPoints[client]				=	0;
		TotalTalentPoints[client]		=	0;
		TimePlayed[client]				=	0;
		PlayerUpgradesTotal[client]		=	0;
		FreeUpgrades[client]			=	0;
		SlatePoints[client]				=	0;

		new size = GetArraySize(Handle:a_Database_Talents);

		ResizeArray(PlayerAbilitiesCooldown[client], size);
		ResizeArray(a_Database_PlayerTalents[client], size);

		decl String:text[64];

		for (new i = 0; i < size; i++) {

			GetArrayString(a_Database_Talents_Defaults, i, text, sizeof(text));
			Format(text, sizeof(text), "%d", StringToInt(text) - 1);
			SetArrayString(a_Database_PlayerTalents[client], i, text);
		}

		if (GetArraySize(a_Store_Player[client]) != GetArraySize(a_Store)) {

			ResizeArray(a_Store_Player[client], GetArraySize(a_Store));
		}

		for (new i = 0; i < GetArraySize(a_Store); i++) {

			SetArrayString(a_Store_Player[client], i, "0");				// We clear all players arrays for the store.
		}

		size				= GetArraySize(a_WeaponLevels);

		if (GetArraySize(a_WeaponLevels_Experience[client]) != size) {

			ResizeArray(a_WeaponLevels_Experience[client], size);
			ResizeArray(a_WeaponLevels_Level[client], size);
		}

		for (new i = 0; i < size; i++) {

			SetArrayString(Handle:a_WeaponLevels_Experience[client], i, "0");
			SetArrayString(Handle:a_WeaponLevels_Level[client], i, "1");
		}

		decl String:tquery[512];
		decl String:key[64];
		GetClientAuthString(client, key, sizeof(key));
		Format(tquery, sizeof(tquery), "INSERT INTO `%s` (`steam_id`, `strength`, `luck`, `agility`, `technique`, `endurance`, `experience`, `experience overall`, `upgrade cost`, `level`, `%s`, `time played`, `talent points`, `total upgrades`, `free upgrades`, `slate points`) VALUES ('%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", GetConfigValue("database prefix?"), GetConfigValue("sky points menu name?"), key, Strength[client], Luck[client], Agility[client], Technique[client], Endurance[client], ExperienceLevel[client], ExperienceOverall[client], PlayerLevelUpgrades[client], PlayerLevel[client], SkyPoints[client], TimePlayed[client], TotalTalentPoints[client], PlayerUpgradesTotal[client], FreeUpgrades[client], SlatePoints[client]);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
	}
	else {

		Strength_Bots				=	StringToInt(GetConfigValue("strength?"));
		Luck_Bots					=	StringToInt(GetConfigValue("luck?"));
		Agility_Bots				=	StringToInt(GetConfigValue("agility?"));
		Technique_Bots				=	StringToInt(GetConfigValue("technique?"));
		Endurance_Bots				=	StringToInt(GetConfigValue("endurance?"));
		ExperienceLevel_Bots		=	0;
		ExperienceOverall_Bots		=	0;
		PlayerLevelUpgrades_Bots	=	0;
		PlayerLevel_Bots			=	1;
		TotalTalentPoints_Bots		=	0;

		new size = GetArraySize(Handle:a_Database_Talents);
		for (new i = 0; i < size; i++) {

			SetArrayString(a_Database_PlayerTalents_Bots, i, "0");
		}
		decl String:tquery[512];
		decl String:key[64];
		Format(key, sizeof(key), GetConfigValue("director steam id?"));
		Format(tquery, sizeof(tquery), "INSERT INTO `%s` (`steam_id`, `strength`, `luck`, `agility`, `technique`, `endurance`, `experience`, `experience overall`, `upgrade cost`, `level`, `talent points`) VALUES ('%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", GetConfigValue("database prefix?"), key, Strength_Bots, Luck_Bots, Agility_Bots, Technique_Bots, Endurance_Bots, ExperienceLevel_Bots, ExperienceOverall_Bots, PlayerLevelUpgrades_Bots, PlayerLevel_Bots, TotalTalentPoints_Bots);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);
	}
}

stock SaveAndClear(client, bool:bot = false) {

	decl String:tquery[512];
	decl String:key[64];
	decl String:text[512];
	decl String:text2[512];

	new size = GetArraySize(a_Database_Talents);

	if (!bot) {

		b_IsDirectorTalents[client] = false;
		GetClientAuthString(client, key, sizeof(key));
		if (PlayerUpgradesTotal[client] == 0 && FreeUpgrades[client] == 0 && PlayerLevel[client] <= 1) {

			Format(tquery, sizeof(tquery), "DELETE FROM `%s` WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), key);
			SQL_TQuery(hDatabase, QueryResults, tquery, client);
			return;
		}

		decl String:Name[64];
		GetClientName(client, Name, sizeof(Name));

		//if (PlayerLevel[client] < 1) return;		// Clearly, their data hasn't loaded, so we don't save.
		Format(tquery, sizeof(tquery), "UPDATE `%s` SET `strength` = '%d', `luck` = '%d', `agility` = '%d', `technique` = '%d', `endurance` = '%d', `experience` = '%d', `experience overall` = '%d', `upgrade cost` = '%d', `level` = '%d', `%s` = '%d', `time played` = '%d', `talent points` = '%d', `total upgrades` = '%d', `free upgrades` = '%d', `slate points` = '%d' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), Strength[client], Luck[client], Agility[client], Technique[client], Endurance[client], ExperienceLevel[client], ExperienceOverall[client], PlayerLevelUpgrades[client], PlayerLevel[client], GetConfigValue("sky points menu name?"), SkyPoints[client], TimePlayed[client], TotalTalentPoints[client], PlayerUpgradesTotal[client], FreeUpgrades[client], SlatePoints[client], key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);

		Format(tquery, sizeof(tquery), "UPDATE `%s` SET `player name` = '%s' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), Name, key);
		SQL_TQuery(hDatabase, QueryResults, tquery, client);

		for (new i = 0; i < size; i++) {

			GetArrayString(a_Database_Talents, i, text, sizeof(text));
			GetArrayString(a_Database_PlayerTalents[client], i, text2, sizeof(text2));
			Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%s' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), text, text2, key);
			SQL_TQuery(hDatabase, QueryResults, tquery, client);
		}

		size				=	GetArraySize(a_Store);

		for (new i = 0; i < size; i++) {

			SaveSection[client]			=	GetArrayCell(a_Store, i, 2);
			GetArrayString(Handle:SaveSection[client], 0, text, sizeof(text));
			GetArrayString(a_Store_Player[client], i, text2, sizeof(text2));
			Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%s' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), text, text2, key);
			SQL_TQuery(hDatabase, QueryResults, tquery, client);
		}

		size				=	GetArraySize(a_WeaponLevels);

		decl String:weaponexperience[64];
		decl String:weaponlevel[64];

		for (new i = 0; i < size; i++) {

			SaveSection[client]			=	GetArrayCell(a_WeaponLevels, i, 2);
			GetArrayString(Handle:SaveSection[client], 0, text, sizeof(text));
			GetArrayString(Handle:a_WeaponLevels_Experience[client], i, weaponexperience, sizeof(weaponexperience));
			GetArrayString(Handle:a_WeaponLevels_Level[client], i, weaponlevel, sizeof(weaponlevel));
			Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%s', `%s level` = '%s' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), text, weaponexperience, text, weaponlevel, key);
			SQL_TQuery(hDatabase, QueryResults, tquery, client);
		}
	}
	else if (bot && IsSaveDirectorPriority) {

		Format(key, sizeof(key), GetConfigValue("director steam id?"));
		Format(tquery, sizeof(tquery), "UPDATE `%s` SET `strength` = '%d', `luck` = '%d', `agility` = '%d', `technique` = '%d', `endurance` = '%d', `experience` = '%d', `experience overall` = '%d', `upgrade cost` = '%d', `level` = '%d', `talent points` = '%d' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), Strength_Bots, Luck_Bots, Agility_Bots, Technique_Bots, Endurance_Bots, ExperienceLevel_Bots, ExperienceOverall_Bots, PlayerLevelUpgrades_Bots, PlayerLevel_Bots, TotalTalentPoints_Bots, key);
		SQL_TQuery(hDatabase, QueryResults, tquery);

		for (new i = 0; i < size; i++) {

			GetArrayString(a_Database_Talents, i, text, sizeof(text));
			GetArrayString(a_Database_PlayerTalents_Bots, i, text2, sizeof(text2));
			Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%s' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), text, text2, key);
			SQL_TQuery(hDatabase, QueryResults, tquery);
		}
	}
	if (bot && IsSaveDirectorPriority) {

		size				=	GetArraySize(a_DirectorActions);

		decl String:key_t[64];
		decl String:value_t[64];

		for (new i = 1; i < size; i++) {

			BotSaveKeys				=	GetArrayCell(a_DirectorActions, i, 0);
			BotSaveValues			=	GetArrayCell(a_DirectorActions, i, 1);
			BotSaveSection			=	GetArrayCell(a_DirectorActions, i, 2);

			GetArrayString(Handle:BotSaveSection, 0, text, sizeof(text));
			new size2		=	GetArraySize(BotSaveKeys);
			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:BotSaveKeys, ii, key_t, sizeof(key_t));
				GetArrayString(Handle:BotSaveValues, ii, value_t, sizeof(value_t));

				if (StrEqual(key_t, "priority?")) {

					Format(tquery, sizeof(tquery), "UPDATE `%s` SET `%s` = '%d' WHERE `steam_id` = '%s';", GetConfigValue("database prefix?"), text, StringToInt(value_t), key);
					SQL_TQuery(hDatabase, QueryResults, tquery);
				}
			}
		}
	}
}

stock LoadDirectorActions() {

	decl String:key[64];
	decl String:section_t[64];
	decl String:tquery[512];
	Format(key, sizeof(key), GetConfigValue("director steam id?"));
	LoadPos_Director = 0;

	LoadDirectorSection					=	GetArrayCell(a_DirectorActions, LoadPos_Director, 2);
	GetArrayString(Handle:LoadDirectorSection, 0, section_t, sizeof(section_t));

	Format(tquery, sizeof(tquery), "SELECT `%s` FROM `%s` WHERE (`steam_id` = '%s');", section_t, GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, QueryResults_LoadDirector, tquery, -1);
}

public QueryResults_LoadDirector(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[64];
		decl String:key[64];
		decl String:key_t[64];
		decl String:value_t[64];
		decl String:section_t[64];
		decl String:tquery[512];

		new bool:NoLoad						=	false;

		Format(key, sizeof(key), GetConfigValue("director steam id?"));

		while (SQL_FetchRow(hndl)) {

			SQL_FetchString(hndl, 0, text, sizeof(text));

			if (StrEqual(text, "0")) NoLoad = true;
			if (LoadPos_Director < GetArraySize(a_DirectorActions)) {

				QueryDirectorSection						=	GetArrayCell(a_DirectorActions, LoadPos_Director, 2);
				GetArrayString(Handle:QueryDirectorSection, 0, section_t, sizeof(section_t));

				QueryDirectorKeys							=	GetArrayCell(a_DirectorActions, LoadPos_Director, 0);
				QueryDirectorValues							=	GetArrayCell(a_DirectorActions, LoadPos_Director, 1);

				new size							=	GetArraySize(QueryDirectorKeys);

				for (new i = 0; i < size && !NoLoad; i++) {

					GetArrayString(Handle:QueryDirectorKeys, i, key_t, sizeof(key_t));
					GetArrayString(Handle:QueryDirectorValues, i, value_t, sizeof(value_t));

					if (StrEqual(key_t, "priority?")) {

						SetArrayString(Handle:QueryDirectorValues, i, text);
						SetArrayCell(Handle:a_DirectorActions, LoadPos_Director, QueryDirectorValues, 1);
						break;
					}
				}
				LoadPos_Director++;
				if (LoadPos_Director < GetArraySize(a_DirectorActions) && !NoLoad) {

					QueryDirectorSection						=	GetArrayCell(a_DirectorActions, LoadPos_Director, 2);
					GetArrayString(Handle:QueryDirectorSection, 0, section_t, sizeof(section_t));

					Format(tquery, sizeof(tquery), "SELECT `%s` FROM `%s` WHERE (`steam_id` = '%s');", section_t, GetConfigValue("database prefix?"), key);
					SQL_TQuery(hDatabase, QueryResults_LoadDirector, tquery, -1);
				}
				else if (NoLoad) FirstUserDirectorPriority();
			}
		}
	}
}

stock FirstUserDirectorPriority() {

	new size						=	GetArraySize(a_Points);

	new sizer						=	0;

	decl String:s_key[64];
	decl String:s_value[64];

	for (new i = 0; i < size; i++) {

		FirstDirectorKeys						=	GetArrayCell(a_Points, i, 0);
		FirstDirectorValues						=	GetArrayCell(a_Points, i, 1);
		FirstDirectorSection					=	GetArrayCell(a_Points, i, 2);

		new size2					=	GetArraySize(FirstDirectorKeys);
		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(Handle:FirstDirectorKeys, ii, s_key, sizeof(s_key));
			GetArrayString(Handle:FirstDirectorValues, ii, s_value, sizeof(s_value));

			if (StrEqual(s_key, "model?")) PrecacheModel(s_value, false);
			else if (StrEqual(s_key, "director option?") && StrEqual(s_value, "1")) {

				sizer				=	GetArraySize(a_DirectorActions);

				ResizeArray(a_DirectorActions, sizer + 1);
				SetArrayCell(a_DirectorActions, sizer, FirstDirectorKeys, 0);
				SetArrayCell(a_DirectorActions, sizer, FirstDirectorValues, 1);
				SetArrayCell(a_DirectorActions, sizer, FirstDirectorSection, 2);

				ResizeArray(a_DirectorActions_Cooldown, sizer + 1);
				SetArrayString(a_DirectorActions_Cooldown, sizer, "0");						// 0 means not on cooldown. 1 means on cooldown. This resets every map.
			}
		}
	}
}

stock FindClientWithAuthString(String:key[]) {

	decl String:AuthId[64];
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i)) {

			GetClientAuthString(i, AuthId, sizeof(AuthId));
			if (StrEqual(key, AuthId)) return i;
		}
	}
	return -1;
}

public QueryResults_Load(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( hndl != INVALID_HANDLE )
	{
		decl String:key[64];
		if (!IsClientActual(client) || !IsClientInGame(client)) return;

		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, key, sizeof(key));
			client = FindClientWithAuthString(key);

			Strength[client]			=	SQL_FetchInt(hndl, 1);
			Luck[client]				=	SQL_FetchInt(hndl, 2);
			Agility[client]				=	SQL_FetchInt(hndl, 3);
			Technique[client]			=	SQL_FetchInt(hndl, 4);
			Endurance[client]			=	SQL_FetchInt(hndl, 5);
			ExperienceLevel[client]		=	SQL_FetchInt(hndl, 6);
			ExperienceOverall[client]	=	SQL_FetchInt(hndl, 7);
			PlayerLevelUpgrades[client]	=	SQL_FetchInt(hndl, 8);
			PlayerLevel[client]			=	SQL_FetchInt(hndl, 9);
			SkyPoints[client]			=	SQL_FetchInt(hndl, 10);
			TimePlayed[client]			=	SQL_FetchInt(hndl, 11);
			TotalTalentPoints[client]	=	SQL_FetchInt(hndl, 12);
			PlayerUpgradesTotal[client]	=	SQL_FetchInt(hndl, 13);
			FreeUpgrades[client]		=	SQL_FetchInt(hndl, 14);
			SlatePoints[client]			=	SQL_FetchInt(hndl, 15);

			if (PlayerLevel[client] == 0) {

				ResetData(client);
				CreateNewPlayer(client);
			}
			else {

				// Now load their talents. Because the database is modular; i.e. it loads and saves talents that are created modularly, we have to be sly about how we do this!
				LoadTalentTrees(client);
			}
		}
		b_IsLoading[client] = false;
		//if (!bFound && IsLegitimateClient(client)) {
		if (PlayerLevel[client] < 1) {

			ResetData(client);
			CreateNewPlayer(client);
		}
	}
	else
	{
		SetFailState("Error: %s", error);
		return;
	}
}

public QueryResults_LoadTalentTrees(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[512];
		decl String:tquery[512];
		decl String:key[64];
		if (!IsClientActual(client) || !IsClientInGame(client)) return;

		while (SQL_FetchRow(hndl)) {

			SQL_FetchString(hndl, 0, key, sizeof(key));
			client = FindClientWithAuthString(key);

			if (LoadPos[client] < GetArraySize(a_Database_Talents)) {

				SQL_FetchString(hndl, 1, text, sizeof(text));
				SetArrayString(a_Database_PlayerTalents[client], LoadPos[client], text);

				LoadPos[client]++;
				if (LoadPos[client] < GetArraySize(a_Database_Talents)) {

					GetArrayString(Handle:a_Database_Talents, LoadPos[client], text, sizeof(text));
					Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
					SQL_TQuery(hDatabase, QueryResults_LoadTalentTrees, tquery, client);
				}
				else {

					b_IsLoadingTrees[client] = false;
					LoadStoreData(client);
				}
			}
			else {

				b_IsLoadingTrees[client] = false;
				LoadStoreData(client);
			}
		}
	}
	else {
		
		SetFailState("Error: %s", error);
		return;
	}
}

public QueryResults_LoadTalentTreesBot(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[512];
		decl String:tquery[512];
		decl String:key[64];
		Format(key, sizeof(key), GetConfigValue("director steam id?"));

		while (SQL_FetchRow(hndl)) {

			if (LoadPos_Bots < GetArraySize(a_Database_Talents)) {

				SQL_FetchString(hndl, 0, text, sizeof(text));
				SetArrayString(a_Database_PlayerTalents_Bots, LoadPos_Bots, text);

				LoadPos_Bots++;
				if (LoadPos_Bots < GetArraySize(a_Database_Talents)) {

					GetArrayString(Handle:a_Database_Talents, LoadPos_Bots, text, sizeof(text));
					Format(tquery, sizeof(tquery), "SELECT `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
					SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesBot, tquery, -1);
				}
			}
		}
	}
	else {
		
		SetFailState("Error: %s", error);
		return;
	}
}

stock LoadTalentTreesBot() {

	decl String:text[64];
	decl String:tquery[512];
	decl String:key[64];

	Format(key, sizeof(key), GetConfigValue("director steam id?"));
	LoadPos_Bots = 0;

	GetArrayString(Handle:a_Database_Talents, 0, text, sizeof(text));
	Format(tquery, sizeof(tquery), "SELECT `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, QueryResults_LoadTalentTreesBot, tquery, -1);
}

stock LoadTalentTrees(client) {

	if (!IsLegitimateClient(client)) return;

	decl String:text[64];
	decl String:tquery[512];
	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));

	b_IsLoadingTrees[client] = true;
	LoadPos[client] = 0;

	GetArrayString(Handle:a_Database_Talents, 0, text, sizeof(text));
	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, QueryResults_LoadTalentTrees, tquery, client);
}

stock LoadWeaponLevels(client) {

	if (!IsLegitimateClient(client)) return;

	new size				= GetArraySize(a_WeaponLevels);

	if (GetArraySize(a_WeaponLevels_Experience[client]) != size) {

		ResizeArray(a_WeaponLevels_Experience[client], size);
		ResizeArray(a_WeaponLevels_Level[client], size);
	}

	decl String:text[64];
	decl String:tquery[512];
	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));

	b_IsLoadingWeapons[client] = true;
	LoadPosWeapons[client] = 0;

	LoadWeaponsSection[client]		=	GetArrayCell(a_WeaponLevels, 0, 2);
	GetArrayString(Handle:LoadWeaponsSection[client], 0, text, sizeof(text));
	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s`, `%s level` FROM `%s` WHERE (`steam_id` = '%s');", text, text, GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, QueryResults_LoadWeaponsData, tquery, client);
}

public QueryResults_LoadWeaponsData(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[512];
		decl String:tquery[512];
		decl String:key[64];
		if (!IsClientActual(client) || !IsClientInGame(client)) return;

		while (SQL_FetchRow(hndl)) {

			SQL_FetchString(hndl, 0, key, sizeof(key));
			client = FindClientWithAuthString(key);

			if (LoadPosWeapons[client] < GetArraySize(a_WeaponLevels)) {

				SQL_FetchString(hndl, 1, text, sizeof(text));
				SetArrayString(a_WeaponLevels_Experience[client], LoadPosWeapons[client], text);
				SQL_FetchString(hndl, 2, text, sizeof(text));
				SetArrayString(a_WeaponLevels_Level[client], LoadPosWeapons[client], text);

				LoadPosWeapons[client]++;
				if (LoadPosWeapons[client] < GetArraySize(a_WeaponLevels)) {

					LoadWeaponsSection[client]		=	GetArrayCell(a_WeaponLevels, LoadPosWeapons[client], 2);
					GetArrayString(Handle:LoadWeaponsSection[client], 0, text, sizeof(text));
					Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s`, `%s level` FROM `%s` WHERE (`steam_id` = '%s');", text, text, GetConfigValue("database prefix?"), key);
					SQL_TQuery(hDatabase, QueryResults_LoadWeaponsData, tquery, client);
				}
				else {

					b_IsLoadingWeapons[client] = false;
				}
			}
			else {

				b_IsLoadingWeapons[client] = false;
			}
		}
	}
	else {
		
		SetFailState("Error: %s", error);
		return;
	}
}

stock LoadStoreData(client) {

	if (!IsLegitimateClient(client)) return;

	if (GetArraySize(a_Store_Player[client]) != GetArraySize(a_Store)) ResizeArray(a_Store_Player[client], GetArraySize(a_Store));

	decl String:text[64];
	decl String:tquery[512];
	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));

	b_IsLoadingStore[client] = true;
	LoadPosStore[client] = 0;

	LoadStoreSection[client]		=	GetArrayCell(a_Store, 0, 2);
	GetArrayString(Handle:LoadStoreSection[client], 0, text, sizeof(text));
	Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
	SQL_TQuery(hDatabase, QueryResults_LoadStoreData, tquery, client);
}

public QueryResults_LoadStoreData(Handle:owner, Handle:hndl, const String:error[], any:client) {

	if (hndl != INVALID_HANDLE) {

		decl String:text[512];
		decl String:tquery[512];
		decl String:key[64];
		if (!IsClientActual(client) || !IsClientInGame(client)) return;

		while (SQL_FetchRow(hndl)) {

			SQL_FetchString(hndl, 0, key, sizeof(key));
			client = FindClientWithAuthString(key);

			if (LoadPosStore[client] == 0) {

				for (new i = 0; i < GetArraySize(a_Store); i++) {

					SetArrayString(a_Store_Player[client], i, "0");
				}
			}

			if (LoadPosStore[client] < GetArraySize(a_Store)) {

				SQL_FetchString(hndl, 1, text, sizeof(text));
				SetArrayString(a_Store_Player[client], LoadPosStore[client], text);

				LoadPosStore[client]++;
				if (LoadPosStore[client] < GetArraySize(a_Store)) {

					LoadStoreSection[client]		=	GetArrayCell(a_Store, LoadPosStore[client], 2);
					GetArrayString(Handle:LoadStoreSection[client], 0, text, sizeof(text));
					Format(tquery, sizeof(tquery), "SELECT `steam_id`, `%s` FROM `%s` WHERE (`steam_id` = '%s');", text, GetConfigValue("database prefix?"), key);
					SQL_TQuery(hDatabase, QueryResults_LoadStoreData, tquery, client);
				}
				else {

					b_IsLoadingStore[client] = false;
					LoadWeaponLevels(client);
				}
			}
			else {

				b_IsLoadingStore[client] = false;
				LoadWeaponLevels(client);
			}
		}
	}
	else {
		
		SetFailState("Error: %s", error);
		return;
	}
}

stock TryLoadTalents(client, String:tquery[], String:key[]) {

	SQL_TQuery(hDatabase, QueryResults_Load, tquery, client);
}

public QueryResults_LoadBot(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if ( hndl != INVALID_HANDLE )
	{
		decl String:text[64];
		decl String:key[64];
		Format(key, sizeof(key), GetConfigValue("director steam id?"));
		while ( SQL_FetchRow(hndl) )
		{
			if (StrEqual(CurrentTalentLoading_Bots, "-1")) {

				SQL_FetchString(hndl, 0, text, sizeof(text));
				Strength_Bots			=	StringToInt(text);
				SQL_FetchString(hndl, 1, text, sizeof(text));
				Luck_Bots				=	StringToInt(text);
				SQL_FetchString(hndl, 2, text, sizeof(text));
				Agility_Bots			=	StringToInt(text);
				SQL_FetchString(hndl, 3, text, sizeof(text));
				Technique_Bots			=	StringToInt(text);
				SQL_FetchString(hndl, 4, text, sizeof(text));
				Endurance_Bots			=	StringToInt(text);
				SQL_FetchString(hndl, 5, text, sizeof(text));
				ExperienceLevel_Bots	=	StringToInt(text);
				SQL_FetchString(hndl, 6, text, sizeof(text));
				ExperienceOverall_Bots	=	StringToInt(text);
				SQL_FetchString(hndl, 7, text, sizeof(text));
				PlayerLevelUpgrades_Bots	=	StringToInt(text);
				SQL_FetchString(hndl, 8, text, sizeof(text));
				PlayerLevel_Bots			=	StringToInt(text);
				//SQL_FetchString(hndl, 9, text, sizeof(text));
				//SkyPoints_Bots			=	StringToInt(text);
				SQL_FetchString(hndl, 9, text, sizeof(text));
				TotalTalentPoints_Bots	=	StringToInt(text);

				if (PlayerLevel_Bots == 0) CreateNewPlayer(-1, true);
				else LoadTalentTreesBot();
			}
		}
		if (PlayerLevel_Bots == 0) CreateNewPlayer(-1, true);
	}
	else
	{
		SetFailState("Error: %s", error);
		return;
	}
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && b_IsArraysCreated[client]) {

		b_IsArraysCreated[client] = false;
		ResetData(client);
		PlayerLevel[client] = 0;
	}
}

public ReadyUp_IsClientLoaded(client) { 

	CreateTimer(1.0, Timer_LoadData, client, TIMER_FLAG_NO_MAPCHANGE);
}