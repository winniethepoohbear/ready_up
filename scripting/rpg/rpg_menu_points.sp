stock BuildPointsMenu(client, String:MenuName[], String:ConfigName[]) {

	new Handle:menu					=	CreateMenu(BuildPointsMenuHandle);
	decl String:OpenedMenu_t[64];
	Format(OpenedMenu_t, sizeof(OpenedMenu_t), "%s", MenuName);
	OpenedMenu[client]				=	OpenedMenu_t;

	decl String:text[PLATFORM_MAX_PATH];
	decl String:Name[64];
	decl String:Name_Temp[64];

	new Float:PointCost				=	0.0;
	new Float:PointCostMinimum		=	0.0;
	new ExperienceCost				=	0;
	new menuPos						=	-1;
	decl String:Command[64];
	decl String:IsCooldown[64];
	Format(IsCooldown, sizeof(IsCooldown), "0");
	decl String:key[64];
	decl String:value[64];
	decl String:quickCommand[64];


	new size						=	GetArraySize(a_Points);
	if (size < 1) LogMessage("POINT MENU SIZE COULD NOT BE FOUND!!!");

	for (new i = 0; i < size; i++) {

		MenuKeys[client]						=	GetArrayCell(a_Points, i, 0);
		MenuValues[client]						=	GetArrayCell(a_Points, i, 1);
		MenuSection[client]						=	GetArrayCell(a_Points, i, 2);

		GetArrayString(Handle:MenuSection[client], 0, Name, sizeof(Name));
		if (!TalentListingFound(client, MenuKeys[client], MenuValues[client], MenuName)) continue;
		menuPos++;

		Format(quickCommand, sizeof(quickCommand), "none");
		new size2					=	GetArraySize(MenuKeys[client]);
		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(Handle:MenuKeys[client], ii, key, sizeof(key));
			GetArrayString(Handle:MenuValues[client], ii, value, sizeof(value));

			if (StrEqual(key, "point cost?"))		PointCost			=	StringToFloat(value);
			else if (StrEqual(key, "experience cost?"))	ExperienceCost	=	StringToInt(value);
			else if (StrEqual(key, "command?")) Command					=	value;
			else if (StrEqual(key, "point cost minimum?"))	PointCostMinimum	=	StringToFloat(value);
			else if (StrEqual(key, "quick bind?")) Format(quickCommand, sizeof(quickCommand), "!%s", value);
		}

		if (StrEqual(Command, "respawn") && IsPlayerAlive(client)) {

			menuPos--;
			continue;
		}

		Format(Name_Temp, sizeof(Name_Temp), "%T", Name, client);
		if (FindCharInString(Command, ':') != -1) Format(text, sizeof(text), "%T", "Buy Menu Option 1", client, Name_Temp, quickCommand);
		else {

			if (StrEqual(MenuName, "director menu")) {

				PointCost				+= (StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "cost handicap?")) * LivingHumanSurvivors());
				if (PointCost > 1.0) PointCost = 1.0;
				PointCostMinimum		+=	(StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "min cost handicap?")) * LivingHumanSurvivors());

				if (Points_Director > 0.0) PointCost *= Points_Director;
				if (PointCost < PointCostMinimum) PointCost = PointCostMinimum;

				if (menuPos < GetArraySize(a_DirectorActions_Cooldown)) GetArrayString(a_DirectorActions_Cooldown, menuPos, IsCooldown, sizeof(IsCooldown));
			}
			if (StringToInt(IsCooldown) > 0) Format(text, sizeof(text), "%T", "Buy Menu Option Cooldown", client, Name_Temp);
			else {

				if (!StrEqual(MenuName, "director menu")) {

					if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostMinimum) PointCost = PointCostMinimum;
					else PointCost *= Points[client];
				}

				if (StringToInt(GetConfigValue("points purchase type?")) == 0) Format(text, sizeof(text), "%T", "Buy Menu Option 2", client, Name_Temp, PointCost, quickCommand);
				else if (StringToInt(GetConfigValue("points purchase type?")) == 1) Format(text, sizeof(text), "%T", "Buy Menu Option 3", client, Name_Temp, ExperienceCost, quickCommand);
			}
		}
		AddMenuItem(menu, text, text);
	}

	if (!StrEqual(MenuName, "director menu")) BuildMenuTitle(client, menu);
	else BuildMenuTitle(client, menu, -1);

	SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public BuildPointsMenuHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		decl String:ConfigName[64];
		Format(ConfigName, sizeof(ConfigName), "%s", MenuSelection[client]);
		decl String:MenuName[64];
		Format(MenuName, sizeof(MenuName), "%s", OpenedMenu[client]);

		decl String:Name[64];
		decl String:Command[64];
		decl String:Parameter[64];

		new Float:PointCost				=	0.0;
		new Float:PointCostMinimum		=	0.0;
		new ExperienceCost				=	0;
		new Count						=	0;
		new CountHandicap				=	0;
		new Drop						=	0;
		decl String:Model[64];
		decl String:IsCooldown[64];
		Format(IsCooldown, sizeof(IsCooldown), "0");
		decl String:key[64];
		decl String:value[64];
		new TargetClient				=	-1;

		new size						=	GetArraySize(a_Points);

		new menuPos						=	0;

		for (new i = 0; i < size; i++) {

			MenuKeys[client]						=	GetArrayCell(a_Points, i, 0);
			MenuValues[client]						=	GetArrayCell(a_Points, i, 1);
			MenuSection[client]						=	GetArrayCell(a_Points, i, 2);

			GetArrayString(Handle:MenuSection[client], 0, Name, sizeof(Name));

			if (!TalentListingFound(client, MenuKeys[client], MenuValues[client], MenuName)) continue;
			menuPos++;

			new size2					=	GetArraySize(MenuKeys[client]);
			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:MenuKeys[client], ii, key, sizeof(key));
				GetArrayString(Handle:MenuValues[client], ii, value, sizeof(value));

				if (StrEqual(key, "point cost?"))		PointCost			=	StringToFloat(value);
				else if (StrEqual(key, "experience cost?"))	ExperienceCost	=	StringToInt(value);
				else if (StrEqual(key, "command?"))		Command				=	value;
				else if (StrEqual(key, "parameter?"))	Parameter			=	value;
				else if (StrEqual(key, "model?"))		Format(Model, sizeof(Model), "%s", value);
				else if (StrEqual(key, "count?"))		Count				=	StringToInt(value);
				else if (StrEqual(key, "count handicap?")) CountHandicap	=	StringToInt(value);
				else if (StrEqual(key, "drop?"))		Drop				=	StringToInt(value);
				else if (StrEqual(key, "point cost minimum?")) PointCostMinimum	=	StringToFloat(value);
			}

			if (StrEqual(Command, "respawn") && IsPlayerAlive(client)) {

				menuPos--;
				continue;
			}

			//PrintToChatAll("Item name: %s Menu Position: %d Slot: %d", Name, menuPos, slot);
			//PrintToChatAll("menuPos: %d Slot+1: %d", menuPos, slot+1);
			if (menuPos == slot + 1) break;
		}
		//PrintToChatAll("Item name: %s Menu Position: %d Slot: %d", Name, menuPos, slot);
		if (FindCharInString(Command, ':') != -1) {

			if (StrEqual(MenuName, "director menu")) BuildPointsMenu(client, Command[1], ConfigName);
			else if (StrEqual(Command[1], "director priority")) BuildDirectorPriorityMenu(client);
			else BuildPointsMenu(client, Command[1], ConfigName);
		}
		else {

			if (!StrEqual(MenuName, "director menu")) {

				if (GetClientTeam(client) == TEAM_INFECTED) {

					if (StringToInt(Parameter) == 8 && ActiveTanks() >= StringToInt(GetConfigValue("versus tank limit?"))) {

						PrintToChat(client, "%T", "Tank Limit Reached", client, orange, green, StringToInt(GetConfigValue("versus tank limit?")), white);
						BuildPointsMenu(client, MenuName, ConfigName);
						return;
					}
					else if (StringToInt(Parameter) == 8 && f_TankCooldown != -1.0) {

						PrintToChat(client, "%T", "Tank On Cooldown", client, orange, white);
						BuildPointsMenu(client, MenuName, ConfigName);
						return;
					}
				}

				if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostMinimum) PointCost = PointCostMinimum;
				else PointCost *= Points[client];

				if ((StringToInt(GetConfigValue("points purchase type?")) == 0 && (Points[client] >= PointCost || PointCost == 0.0 || IsGhost(client) && StrEqual(Command, "change class") && StringToInt(Parameter) != 8)) ||
					(StringToInt(GetConfigValue("points purchase type?")) == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0 || IsGhost(client) && StrEqual(Command, "change class") && StringToInt(Parameter) != 8))) {

					if (!StrEqual(Command, "change class") || StrEqual(Command, "change class") && StrEqual(Parameter, "8") || StrEqual(Command, "change class") && IsPlayerAlive(client) && !IsGhost(client)) {

						if (StringToInt(GetConfigValue("points purchase type?")) == 0 && (Points[client] >= PointCost || PointCost == 0.0)) Points[client] -= PointCost;
						else if (StringToInt(GetConfigValue("points purchase type?")) == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0)) ExperienceLevel[client] -= ExperienceCost;
					}

					if (StrEqual(Parameter, "common") && StrContains(Model, ".mdl", false) != -1) {

						Count = Count + (CountHandicap * LivingSurvivorCount());

						for (new i = Count; i > 0 && GetArraySize(CommonInfectedQueue) < StringToInt(GetConfigValue("common queue limit?")); i--) {

							if (Drop == 1) {

								ResizeArray(Handle:CommonInfectedQueue, GetArraySize(Handle:CommonInfectedQueue) + 1);
								ShiftArrayUp(Handle:CommonInfectedQueue, 0);
								SetArrayString(Handle:CommonInfectedQueue, 0, Model);
								TargetClient		=	FindLivingSurvivor();
								if (TargetClient > 0) ExecCheatCommand(TargetClient, Command, Parameter);
							}
							else PushArrayString(Handle:CommonInfectedQueue, Model);
						}
					}
					else if (StrEqual(Command, "change class")) {

						//if (IsGhost(client) && StringToInt(GetConfigValue("points purchase type?")) == 0) Points[client] += PointCost;
						//else if (IsGhost(client) && StringToInt(GetConfigValue("points purchase type?")) == 1) ExperienceLevel[client] += ExperienceCost;
						if (!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && StringToInt(GetConfigValue("points purchase type?")) == 0) Points[client] += PointCost;
						else if (!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && StringToInt(GetConfigValue("points purchase type?")) == 1) ExperienceLevel[client] += ExperienceCost;
						else if (!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && StringToInt(GetConfigValue("points purchase type?")) == 0) Points[client] += PointCost;
						else if (!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && StringToInt(GetConfigValue("points purchase type?")) == 1) ExperienceLevel[client] += ExperienceCost;
						if (FindZombieClass(client) != ZOMBIECLASS_TANK) ChangeInfectedClass(client, StringToInt(Parameter));
					}
					else if (StrEqual(Command, "respawn")) {

						SDKCall(hRoundRespawn, client);
						CreateTimer(0.1, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
					}
					else {

						if (PointCost == 0.0 && GetClientTeam(client) == TEAM_SURVIVOR) {

							if (StrContains(Parameter, "pistol", false) != -1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
							else L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);
						}

						ExecCheatCommand(client, Command, Parameter);
						if (StrEqual(Parameter, "health")) GiveMaximumHealth(client);		// So instant heal doesn't put a player above their maximum health pool.
					}
				}
			}
			else {

				if (menuPos < GetArraySize(a_DirectorActions_Cooldown)) GetArrayString(a_DirectorActions_Cooldown, menuPos, IsCooldown, sizeof(IsCooldown));
				if (StringToInt(IsCooldown) > 0) PrintToChat(client, "%T", "Menu Option is On Cooldown", client, green, Name, white);
				else {

					if (Points_Director == 0.0 || Points_Director > 0.0 && (Points_Director * PointCost) < PointCostMinimum) PointCost = PointCostMinimum;
					else PointCost *= Points_Director;

					if (Points_Director >= PointCost) {

						Points_Director -= PointCost;

						if (StrEqual(Parameter, "common") && StrContains(Model, ".mdl", false) != -1) {

							for (new i = Count; i > 0 && GetArraySize(CommonInfectedQueue) < StringToInt(GetConfigValue("common queue limit?")); i--) {

								if (Drop == 1) {

									ResizeArray(Handle:CommonInfectedQueue, GetArraySize(Handle:CommonInfectedQueue) + 1);
									ShiftArrayUp(Handle:CommonInfectedQueue, 0);
									SetArrayString(Handle:CommonInfectedQueue, 0, Model);
									TargetClient		=	FindLivingSurvivor();
									if (TargetClient > 0) ExecCheatCommand(TargetClient, Command, Parameter);
								}
								else PushArrayString(Handle:CommonInfectedQueue, Model);
							}
						}
						else ExecCheatCommand(client, Command, Parameter);
					}
				}
			}
			BuildPointsMenu(client, MenuName, ConfigName);
		}
	}
	else if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}