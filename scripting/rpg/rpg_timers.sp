public Action:Timer_ZeroGravity(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		ModifyGravity(client);
	}
	ZeroGravityTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_TeleportRespawn(Handle:timer, any:client) {

	if (IsLegitimateClient(client) && IsPlayerAlive(client)) {

		GiveMaximumHealth(client);
		TeleportEntity(client, DeathLocation[client], NULL_VECTOR, NULL_VECTOR);
	}

	return Plugin_Stop;
}

public Action:Timer_DestroyCombustion(Handle:timer, any:entity)
{
	if (!IsValidEntity(entity)) return Plugin_Stop;
	AcceptEntityInput(entity, "Kill");
	return Plugin_Stop;
}

/*public Action:Timer_DestroyDiscoveryItem(Handle:timer, any:entity) {

	if (IsValidEntity(entity)) {

		new client				= FindAnyRandomClient();

		if (client == -1) return Plugin_Stop;

		decl String:EName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", EName, sizeof(EName));
		if (StrEqual(EName, "slate") || IsStoreItem(client, EName) || IsTalentExists(EName)) {

			if (!AcceptEntityInput(entity, "Kill")) RemoveEdict(entity);
		}
	}

	return Plugin_Stop;
}*/

public Action:Timer_SlowPlayer(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client]);
	}
	SlowMultiplierTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_AwardSkyPoints(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) CheckSkyPointsAward(i);
	}

	return Plugin_Continue;
}

stock CheckSkyPointsAward(client) {

	new SkyPointsAwardTime		=	StringToInt(GetConfigValue("sky points awarded _"));
	new SkyPointsAwardValue		=	StringToInt(GetConfigValue("sky points time required?"));
	new SkyPointsAwardAmount	=	StringToInt(GetConfigValue("sky points award amount?"));

	new seconds					=	0;
	new minutes					=	0;
	new hours					=	0;
	new days					=	0;
	new oldminutes				=	0;
	new oldhours				=	0;
	new olddays					=	0;

	seconds				=	TimePlayed[client];
	while (seconds >= 86400) {

		olddays++;
		seconds -= 86400;
	}
	while (seconds >= 3600) {

		oldhours++;
		seconds -= 3600;
	}
	while (seconds >= 60) {

		oldminutes++;
		seconds -= 60;
	}

	TimePlayed[client]++;

	seconds = TimePlayed[client];

	while (seconds >= 86400) {

		days++;
		seconds -= 86400;
	}
	while (seconds >= 3600) {

		hours++;
		seconds -= 3600;
	}
	while (seconds >= 60) {

		minutes++;
		seconds -= 60;

	}
	if (SkyPointsAwardTime == 2 && days != olddays && days % SkyPointsAwardValue == 0) AwardSkyPoints(client, SkyPointsAwardAmount);
	if (SkyPointsAwardTime == 1 && hours != oldhours && hours % SkyPointsAwardValue == 0) AwardSkyPoints(client, SkyPointsAwardAmount);
	if (SkyPointsAwardTime == 0 && minutes != oldminutes && minutes % SkyPointsAwardValue == 0) AwardSkyPoints(client, SkyPointsAwardAmount);
}

public Action:Timer_SpeedIncrease(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		SpeedIncrease(client);
	}
	SpeedMultiplierTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_DamageIncrease(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		DamageMultiplier[client] = DamageMultiplierBase[client];
	}
	DamageMultiplierTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_BlindPlayer(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) BlindPlayer(client);
	return Plugin_Stop;
}

public Action:Timer_DetectGroundTouch(Handle:timer, any:client) {

	if (IsClientHuman(client) && IsPlayerAlive(client)) {

		if (GetClientTeam(client) == TEAM_SURVIVOR && !(GetEntityFlags(client) & FL_ONGROUND) && b_IsJumping[client] && L4D2_GetInfectedAttacker(client) == -1 && !IsTanksActive()) return Plugin_Continue;
		b_IsJumping[client] = false;
		ModifyGravity(client);
	}
	return Plugin_Stop;
}

public Action:Timer_ResetGravity(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) ModifyGravity(client);
	return Plugin_Stop;
}

public Action:Timer_CloakingDeviceBreakdown(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	return Plugin_Stop;
}

public Action:Timer_ResetPlayerHealth(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		LoadHealthMaximum(client);
		GiveMaximumHealth(client);
	}
	return Plugin_Stop;
}

public Action:Timer_RemoveCooldown(Handle:timer, Handle:pack) {

	ResetPack(pack);
	new client			=	ReadPackCell(pack);
	new pos				=	ReadPackCell(pack);

	if (client != -1 && IsClientActual(client) && !IsFakeClient(client)) {

		SetArrayString(PlayerAbilitiesCooldown[client], pos, "0");
	}
	else {

		SetArrayString(PlayerAbilitiesCooldown_Bots, pos, "0");
	}
	//PlayerAbilitiesCooldown[client][pos] = 0;

	return Plugin_Stop;
}

public Action:Timer_IsIncapacitated(Handle:timer, any:client) {

	static attacker					=	0;

	if (IsLegitimateClientAlive(client) && IsIncapacitated(client)) {
	
		if (attacker == 0) attacker	=	L4D2_GetInfectedAttacker(client);
	
		if (L4D2_GetInfectedAttacker(client) == -1) {
		
			if (attacker == -1) attacker			=	0;
			FindAbilityByTrigger(client, attacker, 'n', FindZombieClass(client), 0);
			if (attacker > 0 && IsClientInGame(attacker)) FindAbilityByTrigger(attacker, client, 'M', FindZombieClass(attacker), 0);
			attacker								=	0;
			return Plugin_Stop;
		}
		return Plugin_Continue;
	}
	attacker						=	0;
	return Plugin_Stop;
}

public Action:Timer_CoveredInBile(Handle:timer, Handle:pack) {

	ResetPack(pack);
	new client			=	ReadPackCell(pack);
	new victim			=	ReadPackCell(pack);

	new ExperienceEarned = 0;
	new Float:PointsEarned = 0.0;

	if (IsLegitimateClient(client) && IsLegitimateClient(victim)) {

		LogMessage("Timer_CoveredInBile RESULTS: Attacker: %N Victim: %N", client, victim);

		decl String:VictimName[MAX_NAME_LENGTH];
		GetClientName(victim, VictimName, sizeof(VictimName));

		if (GetClientTeam(client) == TEAM_SURVIVOR) {

			ExperienceEarned = RoundToFloor(StringToFloat(GetConfigValue("experience multiplier survivor?")) * CoveredInBile[victim][client]);
			PointsEarned = StringToFloat(GetConfigValue("points multiplier survivor?")) * CoveredInBile[victim][client];
		}
		else if (GetClientTeam(client) == TEAM_INFECTED) {

			ExperienceEarned = RoundToFloor(StringToFloat(GetConfigValue("experience multiplier infected?")) * CoveredInBile[victim][client]);
			PointsEarned = StringToFloat(GetConfigValue("points multiplier infected?")) * CoveredInBile[victim][client];
		}

		new RPGMode					= StringToInt(GetConfigValue("rpg mode?"));

		if (RPGMode > 0) {

			ExperienceLevel[client] += ExperienceEarned;
			if (ExperienceLevel[client] > CheckExperienceRequirement(client)) ExperienceLevel[client] = CheckExperienceRequirement(client);
			if (GetClientTeam(victim) == TEAM_INFECTED) PrintToChat(client, "%T", "Bile Damage Experience", client, white, orange, white, green, white, VictimName, ExperienceEarned);
			else if (GetClientTeam(victim) == TEAM_SURVIVOR) PrintToChat(client, "%T", "Bile Damage Experience", client, white, blue, white, green, white, VictimName, ExperienceEarned);
		}
		if (RPGMode != 1) {

			Points[client] += PointsEarned;
			if (GetClientTeam(victim) == TEAM_INFECTED) PrintToChat(client, "%T", "Bile Damage Points", client, white, orange, white, green, white, VictimName, PointsEarned);
			else if (GetClientTeam(victim) == TEAM_SURVIVOR) PrintToChat(client, "%T", "Bile Damage Points", client, white, blue, white, green, white, VictimName, PointsEarned);
		}

		FindAbilityByTrigger(client, victim, 'b', FindZombieClass(client), 0);
	}

	CoveredInBile[victim][client] = -1;
	return Plugin_Stop;
}

public Action:Timer_IsNotImmune(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) b_IsImmune[client] = false;
	return Plugin_Stop;
}

public Action:Timer_TankCooldown(Handle:timer) {

	static Float:Counter								=	0.0;

	if (!b_IsActiveRound) {

		Counter											=	0.0;
		return Plugin_Stop;
	}
	Counter												+=	1.0;
	f_TankCooldown										-=	1.0;
	if (f_TankCooldown < 1.0) {

		Counter											=	0.0;
		f_TankCooldown									=	-1.0;
		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == TEAM_INFECTED || ReadyUp_GetGameMode() != 2)) {

				PrintToChat(i, "%T", "Tank Cooldown Complete", i, orange, white);
			}
		}

		return Plugin_Stop;
	}
	if (Counter >= StringToFloat(GetConfigValue("versus tank notice?"))) {

		Counter											=	0.0;
		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == TEAM_INFECTED || ReadyUp_GetGameMode() != 2)) {

				PrintToChat(i, "%T", "Tank Cooldown Remaining", i, green, f_TankCooldown, white, orange, white);
			}
		}
	}

	return Plugin_Continue;
}

public Action:Timer_PeriodicTalents(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i)) FindAbilityByTrigger(i, 0, 'p', FindZombieClass(i), 0);
	}

	return Plugin_Continue;
}

public Action:Timer_DeductStoreTime(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i)) RemoveStoreTime(i);
	}

	return Plugin_Continue;
}

public Action:Timer_SettingsCheck(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	SetConVarInt(FindConVar("z_common_limit"), (StringToInt(GetConfigValue("common limit base?")) + (StringToInt(GetConfigValue("common increase per player?")) * LivingHumanSurvivors())));
	SetConVarInt(FindConVar("z_reserved_wanderers"), (StringToInt(GetConfigValue("wanderers limit base?")) + (StringToInt(GetConfigValue("wanderers increase per player?")) * LivingHumanSurvivors())));
	SetConVarInt(FindConVar("z_mega_mob_size"), (StringToInt(GetConfigValue("mega mob size base?")) + (StringToInt(GetConfigValue("mega mob increase per player?")) * LivingHumanSurvivors())));
	SetConVarInt(FindConVar("z_mob_spawn_max_size"), (StringToInt(GetConfigValue("mob size base?")) + (StringToInt(GetConfigValue("mob size increase per player?")) * LivingHumanSurvivors())));
	SetConVarInt(FindConVar("z_mob_spawn_finale_size"), (StringToInt(GetConfigValue("mob finale size base?")) + (StringToInt(GetConfigValue("mob finale increase per player?")) * LivingHumanSurvivors())));
	SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), (StringToInt(GetConfigValue("mega mob max interval base?")) - (StringToInt(GetConfigValue("mega mob interval decrease per player?")) * LivingHumanSurvivors())));
	if (ReadyUp_GetGameMode() == 2) SetConVarInt(FindConVar("z_tank_health"), (StringToInt(GetConfigValue("versus base tank health?")) + (StringToInt(GetConfigValue("versus tank health per player?")) * LivingHumanSurvivors())));

	return Plugin_Continue;
}

public Action:Timer_DirectorPurchaseTimer(Handle:timer) {

	static Counter										=	-1;

	if (!b_IsActiveRound) {

		Counter											=	-1;
		return Plugin_Stop;
	}
	if (Counter == -1) {

		Counter = GetTime() + RoundToCeil(StringToFloat(GetConfigValue("director thought process delay?")) - (LivingSurvivors() * StringToFloat(GetConfigValue("director thought process handicap?"))));
		return Plugin_Continue;
	}
	else if (Counter > GetTime()) {

		// We still spawn specials, out of range of players to enforce the active special limit.
		return Plugin_Continue;
	}
	//PrintToChatAll("%t", "Director Think Process", orange, white);


	Counter = GetTime() + RoundToCeil(StringToFloat(GetConfigValue("director thought process delay?")) - (LivingSurvivors() * StringToFloat(GetConfigValue("director thought process handicap?"))));

	new MaximumPriority = StringToInt(GetConfigValue("director priority maximum?"));

	new size				=	GetArraySize(a_DirectorActions);

	for (new i = 1; i <= MaximumPriority; i++) { CheckDirectorActionPriority(i, size); }

	return Plugin_Continue;
}

stock CheckDirectorActionPriority(pos, size) {

	decl String:text[64];
	for (new i = 0; i < size; i++) {

		if (i < GetArraySize(a_DirectorActions_Cooldown)) GetArrayString(a_DirectorActions_Cooldown, i, text, sizeof(text));
		else break;
		if (StringToInt(text) > 0) continue;			// Purchase still on cooldown.
		
		DirectorKeys					=	GetArrayCell(a_DirectorActions, i, 0);
		DirectorValues					=	GetArrayCell(a_DirectorActions, i, 1);

		if (StringToInt(GetKeyValue(DirectorKeys, DirectorValues, "priority?")) != pos || !DirectorPurchase_Valid(DirectorKeys, DirectorValues, i)) continue;
		DirectorPurchase(DirectorKeys, DirectorValues, i);
	}
}

stock bool:DirectorPurchase_Valid(Handle:Keys, Handle:Values, pos) {

	new Float:PointCost		=	0.0;
	new Float:PointCostMin	=	0.0;
	decl String:Cooldown[64];

	GetArrayString(a_DirectorActions_Cooldown, pos, Cooldown, sizeof(Cooldown));
	if (StringToInt(Cooldown) > 0) return false;

	PointCost				=	StringToFloat(GetKeyValue(Keys, Values, "point cost?")) + (StringToFloat(GetKeyValue(Keys, Values, "cost handicap?")) * LivingHumanSurvivors());
	if (PointCost > 1.0) PointCost = 1.0;
	PointCostMin			=	StringToFloat(GetKeyValue(Keys, Values, "point cost minimum?")) + (StringToFloat(GetKeyValue(Keys, Values, "min cost handicap?")) * LivingHumanSurvivors());

	if (Points_Director > 0.0) PointCost *= Points_Director;
	if (PointCost < PointCostMin) PointCost = PointCostMin;

	if (Points_Director >= PointCost) return true;
	return false;
}

stock ActiveTanks() {

	new Count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && IsPlayerAlive(i) && FindZombieClass(i) == ZOMBIECLASS_TANK) Count++;
	}

	return Count;
}

stock DirectorTankLimit() {

	new Float:count = (LivingSurvivors() / StringToFloat(GetConfigValue("director tanks player multiplier?"))) * StringToInt(GetConfigValue("director tanks per _ players?"));
	if (count < 1.0) count = 1.0;

	return RoundToCeil(count);
}

stock DirectorPurchase(Handle:Keys, Handle:Values, pos) {

	decl String:Command[64];
	decl String:Parameter[64];
	decl String:Model[64];
	new IsPlayerDrop		=	0;
	new Count				=	0;

	new Float:PointCost		=	0.0;
	new Float:PointCostMin	=	0.0;

	new Float:MinimumDelay	=	0.0;

	PointCost				=	StringToFloat(GetKeyValue(Keys, Values, "point cost?")) + (StringToFloat(GetKeyValue(Keys, Values, "cost handicap?")) * LivingHumanSurvivors());
	PointCostMin			=	StringToFloat(GetKeyValue(Keys, Values, "point cost minimum?")) + (StringToFloat(GetKeyValue(Keys, Values, "min cost handicap?")) * LivingHumanSurvivors());
	Format(Parameter, sizeof(Parameter), "%s", GetKeyValue(Keys, Values, "parameter?"));
	Count					=	StringToInt(GetKeyValue(Keys, Values, "count?"));
	Format(Command, sizeof(Command), "%s", GetKeyValue(Keys, Values, "command?"));
	IsPlayerDrop			=	StringToInt(GetKeyValue(Keys, Values, "drop?"));
	Format(Model, sizeof(Model), "%s", GetKeyValue(Keys, Values, "model?"));
	MinimumDelay			=	StringToFloat(GetKeyValue(Keys, Values, "minimum delay?"));

	if (PointCost > 1.0) {

		PointCost			=	1.0;
	}

	if (StrContains(Parameter, "tank", false) != -1 && (ActiveTanks() >= DirectorTankLimit() || f_TankCooldown != -1.0)) return;

	if (StrEqual(Parameter, "common")) {

		if (GetArraySize(CommonInfectedQueue) + Count >= StringToInt(GetConfigValue("common queue limit?"))) {

			LogMessage("Cannot buy commons, it would exceed the limit of the allowed size.");
			return;
		}
	}

	if ((StrEqual(Command, "director_force_panic_event") || IsPlayerDrop) && b_IsFinaleActive) {

		return;
	}

	if (Points_Director > 0.0) PointCost *= Points_Director;
	if (PointCost < PointCostMin) PointCost = PointCostMin;

	if (Points_Director < PointCost) return;

	if (LivingHumanSurvivors() < StringToInt(GetKeyValue(Keys, Values, "living survivors?"))) return;

	new Client				=	FindLivingSurvivor();
	if (Client < 1) return;
	Points_Director -= PointCost;

	if (MinimumDelay > 0.0) {

		SetArrayString(a_DirectorActions_Cooldown, pos, "1");
		MinimumDelay = MinimumDelay - (LivingHumanSurvivors() * StringToFloat(GetConfigValue("director thought process handicap?"))) - (StringToFloat(GetKeyValue(Keys, Values, "delay handicap?")) * LivingHumanSurvivors());
		if (MinimumDelay < 0.0) MinimumDelay = 0.0;
		CreateTimer((StringToFloat(GetConfigValue("director thought process delay?")) - (LivingHumanSurvivors() * StringToFloat(GetConfigValue("director thought process handicap?")))) + MinimumDelay, Timer_DirectorActions_Cooldown, pos, TIMER_FLAG_NO_MAPCHANGE);
	}

	if (!StrEqual(Parameter, "common")) ExecCheatCommand(Client, Command, Parameter);
	else SpawnCommons(Client, Count, Command, Parameter, Model, IsPlayerDrop);
}

stock SpawnCommons(Client, Count, String:Command[], String:Parameter[], String:Model[], IsPlayerDrop) {

	new TargetClient				=	-1;
	if (StrContains(Model, ".mdl", false) != -1) {

		for (new i = Count; i > 0 && GetArraySize(CommonInfectedQueue) < StringToInt(GetConfigValue("common queue limit?")); i--) {

			if (IsPlayerDrop == 1) {

				ResizeArray(Handle:CommonInfectedQueue, GetArraySize(Handle:CommonInfectedQueue) + 1);
				ShiftArrayUp(Handle:CommonInfectedQueue, 0);
				SetArrayString(Handle:CommonInfectedQueue, 0, Model);
				TargetClient		=	FindLivingSurvivor();
				if (TargetClient > 0) ExecCheatCommand(TargetClient, Command, Parameter);
			}
			else PushArrayString(Handle:CommonInfectedQueue, Model);
		}
	}
}

stock FindLivingSurvivor() {


	/*new Client = -1;
	while (Client == -1 && LivingSurvivorCount() > 0) {

		Client = GetRandomInt(1, MaxClients);
		if (!IsClientInGame(Client) || !IsClientHuman(Client) || !IsPlayerAlive(Client) || GetClientTeam(Client) != TEAM_SURVIVOR) Client = -1;
	}
	return Client;*/
	for (new i = LastLivingSurvivor; i <= MaxClients && LivingSurvivorCount() > 0; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			LastLivingSurvivor = i;
			return i;
		}
	}
	LastLivingSurvivor = 1;
	if (LivingSurvivorCount() < 1) return -1;
	return -1;
}

stock LivingSurvivorCount() {

	new Count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) Count++;
	}
	return Count;
}

public Action:Timer_DirectorActions_Cooldown(Handle:timer, any:pos) {

	SetArrayString(a_DirectorActions_Cooldown, pos, "0");
	return Plugin_Stop;
}