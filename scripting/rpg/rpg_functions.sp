stock String:GetConfigValue(String:KeyName[]) {
	
	decl String:text[512];

	new a_Size			= GetArraySize(MainKeys);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:MainKeys, i, text, sizeof(text));

		if (StrEqual(text, KeyName)) {

			GetArrayString(Handle:MainValues, i, text, sizeof(text));
			return text;
		}
	}

	Format(text, sizeof(text), "-1");

	return text;
}

stock bool:AnySurvivorsIncapacitated() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsIncapacitated(i)) return true;
	}
	return false;
}

stock FindAnyRandomClient() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i)) return i;
	}
	return -1;
}

stock RemoveStoreTime(client) {

	decl String:key[64];
	decl String:value[64];

	decl String:PlayerValue[64];

	new size								= GetArraySize(a_Store);
	if (!b_IsLoadingStore[client] && GetArraySize(a_Store_Player[client]) != size) {

		LoadStoreData(client);
		return;				// If their data hasn't loaded for the store, we skip them.
	}
	if (b_IsLoadingStore[client]) return;		// If their data is currently loading, we skip them.
	new size2								= 0;
	for (new i = 0; i < size; i++) {

		StoreTimeKeys[client]				= GetArrayCell(a_Store, i, 0);
		StoreTimeValues[client]				= GetArrayCell(a_Store, i, 1);

		size2								= GetArraySize(StoreTimeKeys[client]);
		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(StoreTimeKeys[client], ii, key, sizeof(key));
			GetArrayString(StoreTimeValues[client], ii, value, sizeof(value));

			if (StrEqual(key, "duration?") && StringToInt(value) > 0) {

				GetArrayString(a_Store_Player[client], i, PlayerValue, sizeof(PlayerValue));
				if (StringToInt(PlayerValue) > 0) {

					Format(PlayerValue, sizeof(PlayerValue), "%d", StringToInt(PlayerValue) - 1);
					SetArrayString(a_Store_Player[client], i, PlayerValue);
				}
			}
		}
	}
}

stock Float:CheckExperienceBooster(client, ExperienceValue) {

	// Return ExperienceValue as it is if the client doesn't have a booster active.
	decl String:key[64];
	decl String:value[64];

	new Float:Multiplier					= 1.0;	// 1.0 is the DEFAULT (Meaning NO CHANGE)

	new size								= GetArraySize(a_Store);
	new size2								= 0;
	for (new i = 0; i < size; i++) {

		StoreKeys[client]					= GetArrayCell(a_Store, i, 0);
		StoreValues[client]					= GetArrayCell(a_Store, i, 1);

		size2								= GetArraySize(StoreKeys[client]);
		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(StoreKeys[client], ii, key, sizeof(key));
			GetArrayString(StoreValues[client], ii, value, sizeof(value));

			if (StrEqual(key, "item effect?") && StrEqual(value, "x")) {

				Multiplier += AddMultiplier(client, i);		// If the client has no time in it, it just adds 0.0.
			}
		}
	}

	return (ExperienceValue * Multiplier);
}

stock Float:AddMultiplier(client, pos) {

	decl String:ClientValue[64];
	GetArrayString(a_Store_Player[client], pos, ClientValue, sizeof(ClientValue));

	decl String:key[64];
	decl String:value[64];

	if (StringToInt(ClientValue) > 0) {

		StoreMultiplierKeys[client]			= GetArrayCell(a_Store, pos, 0);
		StoreMultiplierValues[client]		= GetArrayCell(a_Store, pos, 1);

		new size							= GetArraySize(StoreMultiplierKeys[client]);
		for (new i = 0; i < size; i++) {

			GetArrayString(StoreMultiplierKeys[client], i, key, sizeof(key));
			GetArrayString(StoreMultiplierValues[client], i, value, sizeof(value));

			if (StrEqual(key, "item strength?")) return StringToFloat(value);
		}
	}

	return 0.0;		// It wasn't found, so no multiplier is added.
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {

	if (IsClientActual(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && IsClientActual(victim) && GetClientTeam(victim) == TEAM_INFECTED) {

		decl String:weapon[64];
		GetClientWeapon(attacker, weapon, sizeof(weapon));
		if (StrEqual(weapon, "weapon_melee", false)) {

			damage = 0.0;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

stock FindAbilityByTrigger(client, victim = 0, ability, zombieclass = 0, d_Damage) {

	if (IsLegitimateClient(client)) {

		new a_Size			=	0;

		if (zombieclass == 0) a_Size		=	GetArraySize(a_Menu_Talents_Survivor);
		else a_Size	=	GetArraySize(a_Menu_Talents_Infected);

		//new b_Size			=	0;

		decl String:TalentName[64];
		//decl String:s_key[64];
		//decl String:s_value[64];

		for (new i = 0; i < a_Size; i++) {

			if (GetClientTeam(client) == TEAM_SURVIVOR || zombieclass == 0) {

				TriggerKeys[client]				=	GetArrayCell(a_Menu_Talents_Survivor, i, 0);
				TriggerValues[client]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 1);
				TriggerSection[client]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 2);
			}
			else {

				TriggerKeys[client]				=	GetArrayCell(a_Menu_Talents_Infected, i, 0);
				TriggerValues[client]			=	GetArrayCell(a_Menu_Talents_Infected, i, 1);
				TriggerSection[client]			=	GetArrayCell(a_Menu_Talents_Infected, i, 2);
			}

			GetArrayString(Handle:TriggerSection[client], 0, TalentName, sizeof(TalentName));

			if (FindCharInString(GetKeyValue(TriggerKeys[client], TriggerValues[client], "ability trigger?"), ability) != -1) {

				ActivateAbility(client, victim, i, d_Damage, FindZombieClass(client), TriggerKeys[client], TriggerValues[client], TalentName, ability);
			}

			/*b_Size			=	GetArraySize(TriggerKeys[client]);
			for (new ii = 0; ii < b_Size; ii++) {

				GetArrayString(Handle:TriggerKeys[client], ii, s_key, sizeof(s_key));
				GetArrayString(Handle:TriggerValues[client], ii, s_value, sizeof(s_value));

				if (StrEqual(s_key, "ability trigger?") && FindCharInString(s_value, ability) != -1) {

					ActivateAbility(client, victim, i, d_Damage, FindZombieClass(client), TriggerKeys[client], TriggerValues[client], TalentName, ability);
				}
			}*/
		}
	}
}

stock ActivateAbility(client, victim, pos, damage, zombieclass, Handle:Keys, Handle:Values, String:TalentName[], ability) {

	if (IsLegitimateClientAlive(client) && (victim == 0 || (victim > 0 && IsLegitimateClientAlive(victim)))) {

		decl String:survivoreffects[64];
		decl String:infectedeffects[64];

		new Float:i_Strength			=	0.0;
		new Float:i_FirstPoint			=	0.0;
		new Float:i_EachPoint			=	0.0;
		new Float:i_Time				=	0.0;
		new Float:i_Cooldown			=	0.0;
		decl String:ClientZombieClass[64];
		decl String:VictimZombieClass[64];
		decl String:ClientZombieClassRequired[64];
		decl String:VictimZombieClassRequired[64];

		Format(ClientZombieClassRequired, sizeof(ClientZombieClassRequired), "%s", GetKeyValue(Keys, Values, "attacker class required?"));
		Format(VictimZombieClassRequired, sizeof(VictimZombieClassRequired), "%s", GetKeyValue(Keys, Values, "victim class required?"));

		if (victim == 0) Format(VictimZombieClass, sizeof(VictimZombieClass), "-1");
		else {

			if (GetClientTeam(victim) == TEAM_INFECTED) Format(VictimZombieClass, sizeof(VictimZombieClass), "%d", FindZombieClass(victim));
			else Format(VictimZombieClass, sizeof(VictimZombieClass), "0");
		}
		if (GetClientTeam(client) == TEAM_INFECTED) Format(ClientZombieClass, sizeof(ClientZombieClass), "%d", FindZombieClass(client));
		else Format(ClientZombieClass, sizeof(ClientZombieClass), "0");

		if (IsLegitimateClient(client) && (StrContains(ClientZombieClassRequired, "0", false) != -1 && GetClientTeam(client) == TEAM_SURVIVOR ||
			StrContains(ClientZombieClassRequired, ClientZombieClass, false) != -1 && GetClientTeam(client) == TEAM_INFECTED) &&
			(victim == 0 || (IsLegitimateClient(victim) && (StrContains(VictimZombieClassRequired, "0", false) != -1 && GetClientTeam(victim) == TEAM_SURVIVOR ||
			StrContains(VictimZombieClassRequired, VictimZombieClass, false) != -1 && GetClientTeam(victim) == TEAM_INFECTED)))) {

			//if (StrEqual(key, "class required?") && (StringToInt(value) == zombieclass || (StringToInt(value) == 0 && GetClientTeam(client) == TEAM_SURVIVOR) || zombieclass == 9)) {

			if (!IsAbilityCooldown(client, TalentName) && !b_IsImmune[victim]) {

				survivoreffects		=	FindAbilityEffects(client, Keys, Values, 2, 0);
				infectedeffects		=	FindAbilityEffects(client, Keys, Values, 3, 0);

				if (!IsFakeClient(client)) i_Strength			=	GetTalentStrength(client, TalentName) * 1.0;
				else i_Strength									=	GetTalentStrength(-1, TalentName) * 1.0;

				//i_Strength			=	1.0;
				if (i_Strength <= 0.0) return;	// Locked talents will appear as LESS THAN 0.0 (they will be -1.0)
					
				i_FirstPoint		=	StringToFloat(GetKeyValue(Keys, Values, "first point value?"));
				i_EachPoint			=	StringToFloat(GetKeyValue(Keys, Values, "increase per point?"));
				i_Strength			=	i_FirstPoint + (i_EachPoint * i_Strength);

				if (!IsFakeClient(client)) i_Time				=	GetTalentStrength(client, TalentName) * 1.0;
				else i_Time										=	GetTalentStrength(-1, TalentName) * 1.0;
				//i_Time					=	1.0;
				if (i_Time > 0.0) i_Time	*=	StringToFloat(GetKeyValue(Keys, Values, "ability time per point?"));

				if (!IsFakeClient(client)) i_Cooldown			=	GetTalentStrength(client, TalentName) * 1.0;
				else i_Cooldown									=	GetTalentStrength(-1, TalentName) * 1.0;

				i_Cooldown				=	StringToFloat(GetKeyValue(Keys, Values, "cooldown start?")) + (StringToFloat(GetKeyValue(Keys, Values, "cooldown per point?")) * i_Cooldown);
				//i_Cooldown				=	1.0;

				if (TriggerAbility(client, victim, ability, pos, Keys, Values, TalentName)) {	//	Don't need to check if the player has ability points since the roll is 0 if they don't.

					if (i_Cooldown > 0.0) {

						if (IsClientActual(victim)) {
							
							b_IsImmune[victim] = true;
							CreateTimer(i_Cooldown, Timer_IsNotImmune, victim, TIMER_FLAG_NO_MAPCHANGE);
						}
						if (IsClientActual(client)) CreateCooldown(client, pos, i_Cooldown);	// Infected Bots don't have cooldowns between abilities! Mwahahahaha
					}

					if (!StrEqual(infectedeffects, "0")) {

						if (IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_INFECTED) ActivateAbilityEx(client, client, damage, infectedeffects, i_Strength, i_Time);
						else if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_INFECTED) ActivateAbilityEx(victim, client, damage, infectedeffects, i_Strength, i_Time);
					}
					if (!StrEqual(survivoreffects, "0")) {

						if (IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR) ActivateAbilityEx(client, client, damage, survivoreffects, i_Strength, i_Time);
						else if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) ActivateAbilityEx(victim, client, damage, survivoreffects, i_Strength, i_Time);
					}
				}
			}
		}
	}
}

stock bool:TriggerAbility(client, victim, ability, pos, Handle:Keys, Handle:Values, String:TalentName[]) {

	if (IsLegitimateClientAlive(client) && (victim == 0 || (victim > 0 && IsLegitimateClientAlive(victim)))) {

		decl String:key[64];
		decl String:value[64];

		new size = GetArraySize(Keys);
		for (new i = 0; i < size; i++) {

			GetArrayString(Handle:Keys, i, key, sizeof(key));
			GetArrayString(Handle:Values, i, value, sizeof(value));

			if (StrEqual(key, "ability trigger?")) {	// Chance roll is in survivor ability effects etc. not ability trigger. SHIT.

				//if (FindCharInString(value, ability) == -1) continue;
				if (FindCharInString(value, 'c') == -1) {				// No chance roll required to execute this ability.

					if (!IsClientActual(victim)) return true;			// Common infected, always returns true if there's no chance roll.
					if (HandicapDifference(client, victim) > 0 && !AbilityChanceSuccess(victim) || HandicapDifference(client, victim) == 0) return true;
				}
				else {													// Chance roll required to execute this ability.

					if (!IsClientActual(victim) && AbilityChanceSuccess(client) || IsClientActual(victim) && AbilityChanceSuccess(client) && !AbilityChanceSuccess(victim)) {

						if (FindCharInString(value, 'h') == -1 || AbilityChanceSuccess(client)) return true;
					}
				}
			}
		}
	}
	return false;
}

stock String:FindAbilityEffects(client, Handle:Keys, Handle:Values, team = 0, type) {

	decl String:value[64];
	//Format(value, sizeof(value), "-1");
	//if (IsLegitimateClient(client)) {

	decl String:key[64];

	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		GetArrayString(Handle:Values, i, value, sizeof(value));

		if (type == 0 && (StrEqual(key, "survivor ability effects?") && team == 2 || StrEqual(key, "infected ability effects?") && team == 3)) return value;
		else if (type == 1 && StrEqual(key, "team affected?")) return value;
	}
	//}
	return value;
}

stock bool:AbilityChanceSuccess(client) {

	if (IsLegitimateClientAlive(client)) {

		new pos				=	FindChanceRollAbility(client);

		if (pos == -1) SetFailState("Ability Requires \'C\' but no ability with effect \'C\' could be found.");

		decl String:talentname[64];

		new Float:i_FirstPoint	=	0.0;
		new Float:i_EachPoint	=	0.0;
		new i_Strength		=	0;
		new range			=	0;

		if (GetClientTeam(client) == TEAM_SURVIVOR) {

			AbilityKeys[client] 			=	GetArrayCell(a_Menu_Talents_Survivor, pos, 0);
			AbilityValues[client]			=	GetArrayCell(a_Menu_Talents_Survivor, pos, 1);
			AbilitySection[client]			=	GetArrayCell(a_Menu_Talents_Survivor, pos, 2);
		}
		else {

			AbilityKeys[client] 			=	GetArrayCell(a_Menu_Talents_Infected, pos, 0);
			AbilityValues[client]			=	GetArrayCell(a_Menu_Talents_Infected, pos, 1);
			AbilitySection[client]			=	GetArrayCell(a_Menu_Talents_Infected, pos, 2);
		}

		GetArrayString(Handle:AbilitySection[client], 0, talentname, sizeof(talentname));

		if (!IsFakeClient(client)) {

			i_Strength			=	GetTalentStrength(client, talentname);
			i_FirstPoint		=	(StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "first point value?")) * 100.0) + (Technique[client] * 0.1);
			i_EachPoint			=	StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "increase per point?")) + (Agility[client] * 0.1);
			range				=	RoundToCeil(1.0 / i_EachPoint - (Luck[client] * 0.1));
			i_EachPoint			*=	100.0;

			if (i_Strength == 0) return false;
			//i_Strength = 1;
			i_Strength			=	RoundToCeil(i_FirstPoint + (i_EachPoint * i_Strength) + (Strength[client] * 0.1));
		}
		else {

			i_Strength			=	GetTalentStrength(-1, talentname);
			i_FirstPoint		=	(StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "first point value?")) * 100.0) + (Technique_Bots * 0.1);
			i_EachPoint			=	StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "increase per point?")) + (Agility_Bots * 0.1);
			range				=	RoundToCeil(1.0 / i_EachPoint - (Luck_Bots * 0.1));
			i_EachPoint			*=	100.0;

			if (i_Strength == 0) i_FirstPoint = 0.0;
			i_Strength			=	RoundToCeil(i_FirstPoint + (i_EachPoint * i_Strength) + (Strength_Bots * 0.1));
		}

		range				=	GetRandomInt(1, range);

		if (range <= i_Strength) return true;
	}
	return false;
}

stock GetTalentStrength(client, String:TalentName[]) {

	decl String:text[64];
	//Format(text, sizeof(text), "-1");
	//if (IsLegitimateClient(client)) {

	new size				=	0;
	if (client != -1) size	=	GetArraySize(a_Database_PlayerTalents[client]);
	else size				=	GetArraySize(a_Database_PlayerTalents_Bots);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(TalentName, text)) {

			if (client != -1) GetArrayString(Handle:a_Database_PlayerTalents[client], i, text, sizeof(text));
			else GetArrayString(Handle:a_Database_PlayerTalents_Bots, i, text, sizeof(text));
			break;
		}
	}
	return StringToInt(text);
}

stock String:GetKeyValue(Handle:Keys, Handle:Values, String:SearchKey[]) {

	decl String:key[1024];
	decl String:value[1024];

	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			break;
		}
	}
	return value;
}

stock FindChanceRollAbility(client) {

	if (IsLegitimateClientAlive(client)) {

		new a_Size			=	0;

		if (GetClientTeam(client) == TEAM_SURVIVOR) a_Size		=	GetArraySize(a_Menu_Talents_Survivor);
		else a_Size	=	GetArraySize(a_Menu_Talents_Infected);

		new b_Size			=	0;

		decl String:TalentName[64];
		decl String:s_key[64];
		decl String:s_value[64];

		for (new i = 0; i < a_Size; i++) {

			if (GetClientTeam(client) == TEAM_SURVIVOR) {

				ChanceKeys[client]				=	GetArrayCell(a_Menu_Talents_Survivor, i, 0);
				ChanceValues[client]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 1);
				ChanceSection[client]			=	GetArrayCell(a_Menu_Talents_Survivor, i, 2);
			}
			else {

				ChanceKeys[client]				=	GetArrayCell(a_Menu_Talents_Infected, i, 0);
				ChanceValues[client]			=	GetArrayCell(a_Menu_Talents_Infected, i, 1);
				ChanceSection[client]			=	GetArrayCell(a_Menu_Talents_Infected, i, 2);
			}

			GetArrayString(Handle:ChanceSection[client], 0, TalentName, sizeof(TalentName));

			b_Size			=	GetArraySize(ChanceKeys[client]);
			for (new ii = 0; ii < b_Size; ii++) {

				GetArrayString(Handle:ChanceKeys[client], ii, s_key, sizeof(s_key));
				GetArrayString(Handle:ChanceValues[client], ii, s_value, sizeof(s_value));

				if ((GetClientTeam(client) == TEAM_SURVIVOR && StrEqual(s_key, "survivor ability effects?") ||
					GetClientTeam(client) == TEAM_INFECTED && StrEqual(s_key, "infected ability effects?")) &&
					FindCharInString(s_value, 'C') != -1) {

					return i;
				}
			}
		}
	}
	return -1;
}

stock GetWeaponSlot(entity) {

	if (IsValidEntity(entity)) {

		decl String:Classname[64];
		GetEdictClassname(entity, Classname, sizeof(Classname));

		if (StrContains(Classname, "pistol", false) != -1 || StrContains(Classname, "chainsaw", false) != -1) return 1;
		if (StrContains(Classname, "molotov", false) != -1 || StrContains(Classname, "pipe_bomb", false) != -1 || StrContains(Classname, "vomitjar", false) != -1) return 2;
		if (StrContains(Classname, "defib", false) != -1 || StrContains(Classname, "first_aid", false) != -1) return 3;
		if (StrContains(Classname, "adren", false) != -1 || StrContains(Classname, "pills", false) != -1) return 4;
		return 0;
	}
	return -1;
}

stock BeanBag(client, Float:force) {

	if (IsLegitimateClientAlive(client)) {

		if (!(GetEntityFlags(client) & FL_ONGROUND)) return;

		new Float:Velocity[3];

		Velocity[0]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		Velocity[1]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		Velocity[2]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

		new Float:Vec_Pull;
		new Float:Vec_Lunge;

		Vec_Pull	=	GetRandomFloat(force * -1.0, force);
		Vec_Lunge	=	GetRandomFloat(force * -1.0, force);
		Velocity[2]	+=	force;

		if (Vec_Pull < 0.0 && Velocity[0] > 0.0) Velocity[0] *= -1.0;
		Velocity[0] += Vec_Pull;

		if (Vec_Lunge < 0.0 && Velocity[1] > 0.0) Velocity[1] *= -1.0;
		Velocity[1] += Vec_Lunge;

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);
	}
}

stock CreateCombustion(client, Float:g_Strength, Float:f_Time)
{
	new entity				= CreateEntityByName("env_fire");
	new Float:loc[3];
	GetClientAbsOrigin(client, loc);

	decl String:s_Strength[64];
	Format(s_Strength, sizeof(s_Strength), "%3.3f", g_Strength);

	DispatchKeyValue(entity, "StartDisabled", "0");
	DispatchKeyValue(entity, "damagescale", s_Strength);

	DispatchKeyValue(entity, "fireattack", "2");
	DispatchKeyValue(entity, "firesize", "128");
	DispatchKeyValue(entity, "health", "10");
	DispatchKeyValue(entity, "ignitionpoint", "1");
	DispatchSpawn(entity);

	TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "Enable");
	AcceptEntityInput(entity, "StartFire");
	
	CreateTimer(f_Time, Timer_DestroyCombustion, entity, TIMER_FLAG_NO_MAPCHANGE);
}

stock ZeroGravity(client, victim, Float:g_TalentStrength, Float:g_TalentTime) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		if (GetEntityFlags(victim) & FL_ONGROUND || !b_GroundRequired[victim]) {

			if (ZeroGravityTimer[victim] == INVALID_HANDLE) {

				new Float:vel[3];
				vel[0] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[0]");
				vel[1] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[1]");
				vel[2] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[2]");
				ZeroGravityTimer[victim] = CreateTimer(g_TalentTime, Timer_ZeroGravity, victim, TIMER_FLAG_NO_MAPCHANGE);
				SetEntityGravity(victim, GravityBase[victim] - g_TalentStrength);
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);
			}
		}
	}
}

stock SpeedIncrease(client, Float:effectTime = 0.0, Float:amount = 1.0, bool:IsTeamAffected = false) {

	if (IsLegitimateClientAlive(client)) {

		if (effectTime == 0.0) {

			if (!IsFakeClient(client)) SpeedMultiplier[client] = SpeedMultiplierBase[client] + (Agility[client] * 0.01) + amount;
			else SpeedMultiplier[client] = SpeedMultiplierBase[client] + (Agility_Bots * 0.01) + amount;
		}
		else {

			SpeedMultiplier[client] += amount;
			if (SpeedMultiplierTimer[client] != INVALID_HANDLE) {

				KillTimer(SpeedMultiplierTimer[client]);
				SpeedMultiplierTimer[client] = INVALID_HANDLE;
			}
			SpeedMultiplierTimer[client] = CreateTimer(effectTime, Timer_SpeedIncrease, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client]);

		if (IsTeamAffected) {

			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == GetClientTeam(client) && client != i) {

					if (effectTime == 0.0) SpeedMultiplier[i] = SpeedMultiplierBase[i] + (Agility[i] * 0.01) + amount;
					else {

						SpeedMultiplier[i] += amount;
						if (SpeedMultiplierTimer[i] != INVALID_HANDLE) {

							KillTimer(SpeedMultiplierTimer[i]);
							SpeedMultiplierTimer[i] = INVALID_HANDLE;
						}
						SpeedMultiplierTimer[i] = CreateTimer(effectTime, Timer_SpeedIncrease, i, TIMER_FLAG_NO_MAPCHANGE);
					}
					SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[i]);
				}
			}
		}
	}
}

stock SlowPlayer(client, Float:g_TalentStrength, Float:g_TalentTime) {

	if (IsLegitimateClientAlive(client)) {

		if (SlowMultiplierTimer[client] != INVALID_HANDLE) {

			KillTimer(SlowMultiplierTimer[client]);
			SlowMultiplierTimer[client] = INVALID_HANDLE;
		}
		SpeedMultiplier[client] = 1.0;
		SlowMultiplierTimer[client] = CreateTimer(g_TalentTime, Timer_SlowPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
		if (g_TalentStrength > 1.0 && g_TalentStrength < 100.0) g_TalentStrength *= 0.01;
		else if (g_TalentStrength > 1.0 && g_TalentStrength < 1000.0) g_TalentStrength *= 0.001;
		else if (g_TalentStrength > 1.0 && g_TalentStrength < 10000.0) g_TalentStrength *= 0.0001;
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client] - g_TalentStrength);
	}
}

stock DamageIncrease(client, Float:effectTime = 0.0, Float:amount = 1.0, bool:IsTeamAffected) {

	if (IsLegitimateClientAlive(client)) {

		if (DamageMultiplierBase[client] == 0.0) BaseDamageMultiplier(client);
		DamageMultiplier[client] = DamageMultiplierBase[client];
		DamageMultiplier[client] += amount;
		if (effectTime > 0.0) {

			if (DamageMultiplierTimer[client] != INVALID_HANDLE) {

				KillTimer(DamageMultiplierTimer[client]);
				DamageMultiplierTimer[client] = INVALID_HANDLE;
			}
			DamageMultiplierTimer[client] = CreateTimer(effectTime, Timer_DamageIncrease, client, TIMER_FLAG_NO_MAPCHANGE);
		}

		if (IsTeamAffected) {

			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == GetClientTeam(client) && client != i) {

					if (DamageMultiplierBase[i] == 0.0) BaseDamageMultiplier(i);
					DamageMultiplier[i] = DamageMultiplierBase[i];
					DamageMultiplier[i] += amount;
					if (effectTime > 0.0) {

						if (DamageMultiplierTimer[i] != INVALID_HANDLE) {

							KillTimer(DamageMultiplierTimer[i]);
							DamageMultiplierTimer[i] = INVALID_HANDLE;
						}
						DamageMultiplierTimer[i] = CreateTimer(effectTime, Timer_DamageIncrease, i, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
}

stock CreateBeacons(client, Float:Distance) {

	new Float:Pos[3];
	new Float:Pos2[3];

	GetClientAbsOrigin(client, Pos);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsLegitimateClientAlive(i) && i != client && GetClientTeam(i) != GetClientTeam(client) && (GetClientTeam(i) == TEAM_SURVIVOR || (GetClientTeam(i) == TEAM_INFECTED && IsGhost(i)))) {

			GetClientAbsOrigin(i, Pos2);
			if (GetVectorDistance(Pos, Pos2) > Distance) continue;

			Pos2[2] += 20.0;
			TE_SetupBeamRingPoint(Pos2, 32.0, 128.0, g_iSprite, g_BeaconSprite, 0, 15, 0.5, 2.0, 0.5, {20, 20, 150, 150}, 50, 0);
			TE_SendToClient(client);
		}
	}
}

stock BlindPlayer(client, Float:effectTime = 3.0, amount = 0) {

	if (IsLegitimateClient(client) && !IsFakeClient(client) && !b_IsBlind[client]) {

		new clients[2];
		clients[0] = client;
		new UserMsg:BlindMsgID = GetUserMessageId("Fade");
		new Handle:message = StartMessageEx(BlindMsgID, clients, 1);
		BfWriteShort(message, 1536);
		BfWriteShort(message, 1536);
		
		if (amount == 0)
		{
			BfWriteShort(message, (0x0001 | 0x0010));
		}
		else
		{
			BfWriteShort(message, (0x0002 | 0x0008));
		}
		
		BfWriteByte(message, 255);
		BfWriteByte(message, 255);
		BfWriteByte(message, 255);
		BfWriteByte(message, amount);
		
		EndMessage();

		if (!b_IsBlind[client] && amount > 0) {

			b_IsBlind[client] = true;
			CreateTimer(effectTime, Timer_BlindPlayer, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (b_IsBlind[client]) b_IsBlind[client] = false;
	}
}

stock CreateFireEx(client)
{
	if (IsLegitimateClient(client)) {

		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		CreateFire(pos);
	}
}

static const String:MODEL_GASCAN[] = "models/props_junk/gascan001a.mdl";
stock CreateFire(const Float:BombOrigin[3])
{
	new entity = CreateEntityByName("prop_physics");
	DispatchKeyValue(entity, "physdamagescale", "0.0");
	if (!IsModelPrecached(MODEL_GASCAN))
	{
		PrecacheModel(MODEL_GASCAN);
	}
	DispatchKeyValue(entity, "model", MODEL_GASCAN);
	DispatchSpawn(entity);
	TeleportEntity(entity, BombOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	AcceptEntityInput(entity, "Break");
}

stock bool:IsTanksActive() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_INFECTED && FindZombieClass(i) == ZOMBIECLASS_TANK) return true;
	}
	return false;
}

stock bool:IsCoveredInBile(client) {

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsClientInGame(i)) continue;
		if (CoveredInBile[client][i] >= 0) return true;
	}
	return false;
}

stock ModifyGravity(client, Float:g_Gravity = 1.0, Float:g_Time = 0.0, bool:b_Jumping = false) {

	if (IsLegitimateClientAlive(client)) {

		//if (b_IsJumping[client]) return;	// survivors only, for the moon jump ability
		if (b_Jumping) {

			b_IsJumping[client] = true;
			CreateTimer(0.1, Timer_DetectGroundTouch, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		if (g_Gravity == 1.0) SetEntityGravity(client, g_Gravity);
		else {

			if (g_Gravity > 1.0 && g_Gravity < 100.0) g_Gravity *= 0.01;
			else if (g_Gravity > 1.0 && g_Gravity < 1000.0) g_Gravity *= 0.001;
			else if (g_Gravity > 1.0 && g_Gravity < 10000.0) g_Gravity *= 0.0001;
			SetEntityGravity(client, 1.0 - g_Gravity);
		}
		if (g_Gravity < 1.0 && !b_Jumping) CreateTimer(g_Time, Timer_ResetGravity, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock GetReviveHealth() {

	return RoundToCeil(GetConVarFloat(FindConVar("survivor_revive_health")));
}

stock SetTempHealth(activator, target, Float:s_Strength) {

	if (IsLegitimateClientAlive(target)) {

		new Float:TempHealth	= GetMaximumHealth(activator) * s_Strength;

		SetEntPropFloat(target, Prop_Send, "m_healthBuffer", GetConVarFloat(FindConVar("survivor_revive_health")) + TempHealth);
	}
}

stock HealPlayer(client, activator, Float:s_Strength, ability) {

	if (IsLegitimateClientAlive(client)) {

		new Float:HealAmount		= GetMaximumHealth(client) * s_Strength;
		if (GetClientTeam(client) == TEAM_SURVIVOR && !IsIncapacitated(client) || GetClientTeam(client) == TEAM_INFECTED) {

			if (GetClientHealth(client) + RoundToFloor(HealAmount) > GetMaximumHealth(client)) GiveMaximumHealth(client);
			else SetEntityHealth(client, GetClientHealth(client) + RoundToFloor(HealAmount));
		}
		if (ability == 'T') ReadyUp_NtvFriendlyFire(activator, client, 0 - RoundToCeil(HealAmount), GetClientHealth(client), 1, 0);	// we "subtract" negative values from health.
	}
}

stock SetMaximumHealth(client, bool:b_HealthModifier = false, Float:s_Strength = 0.0) {

	if (IsLegitimateClientAlive(client) && IsFakeClient(client) || IsLegitimateClient(client) && !IsFakeClient(client)) {

		if (b_HealthModifier) SetEntProp(client, Prop_Send, "m_iMaxHealth", RoundToFloor(DefaultHealth[client] + s_Strength));
		else {

			//if (GetClientTeam(client) == TEAM_INFECTED) DefaultHealth[client] = GetMaximumHealth(client);DefaultHealth[client]	=	100;

			//SetEntProp(client, Prop_Send, "m_iMaxHealth", RoundToFloor(GetMaximumHealth(client) + (s_Strength * GetMaximumHealth(client))));
			if (IsFakeClient(client)) SetEntProp(client, Prop_Send, "m_iMaxHealth", RoundToFloor(s_Strength));
			else if (GetClientTeam(client) == TEAM_SURVIVOR) SetEntProp(client, Prop_Send, "m_iMaxHealth", 100 + RoundToFloor(s_Strength * 100));
			else if (GetClientTeam(client) == TEAM_INFECTED) SetEntProp(client, Prop_Send, "m_iMaxHealth", DefaultHealth[client]);
			//DefaultHealth[client]	=	GetMaximumHealth(client);
		}
	}
}

stock SetBaseHealth(client) {

	SetEntProp(client, Prop_Send, "m_iMaxHealth", OriginalHealth[client]);
}

stock GiveMaximumHealth(client)
{
	if (IsLegitimateClientAlive(client)) SetEntityHealth(client, GetMaximumHealth(client));
}

stock GetMaximumHealth(client)
{
	if (IsLegitimateClientAlive(client)) return GetEntProp(client, Prop_Send, "m_iMaxHealth");
	else return 0;
}

stock CloakingDevice(client, Float:s_Strength, Float:g_Time) {

	if (IsLegitimateClientAlive(client)) {

		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255 - RoundToCeil(s_Strength));
		CreateTimer(g_Time, Timer_CloakingDeviceBreakdown, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock AbsorbDamage(client, Float:s_Strength, damage) {

	if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED || !IsIncapacitated(client)) {

			new absorb = RoundToFloor(s_Strength);
			if (absorb > damage) absorb = damage;

			SetEntityHealth(client, GetClientHealth(client) + absorb);
		}
	}
}

stock DamagePlayer(client, victim, Float:s_Strength) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		new d_Damage = RoundToFloor(s_Strength);

		if (GetClientHealth(victim) > 1) {

			if (GetClientHealth(victim) + 1 < d_Damage) d_Damage = GetClientHealth(victim) - 1;
			if (d_Damage > 0) {

				DamageAward[client][victim] += d_Damage;
				SetEntityHealth(victim, GetClientHealth(victim) - d_Damage);
			}
		}
	}
}

stock ModifyHealth(client, Float:s_Strength, Float:g_Time) {

	if (IsLegitimateClientAlive(client)) {

		if (g_Time > 0.0) {

			SetMaximumHealth(client, true, s_Strength);
			CreateTimer(g_Time, Timer_ResetPlayerHealth, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {

			if (GetClientTeam(client) == TEAM_INFECTED) {

				DefaultHealth[client] += RoundToCeil(OriginalHealth[client] * s_Strength);
				SetMaximumHealth(client, false, DefaultHealth[client] * 1.0);
			}
			else SetMaximumHealth(client, false, s_Strength);		// false means permanent.
		}
	}
}

stock ReflectDamage(client, victim, Float:g_TalentStrength, d_Damage) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		new reflectHealth = RoundToFloor(g_TalentStrength);
		new reflectValue = 0;
		if (reflectHealth > d_Damage) reflectHealth = d_Damage;
		if (!IsIncapacitated(client) && IsPlayerAlive(client)) {

			if (GetClientHealth(client) > reflectHealth) reflectValue = reflectHealth;
			else reflectValue = GetClientHealth(client) - 1;
			SetEntityHealth(client, GetClientHealth(client) - reflectValue);
			DamageAward[client][victim] -= reflectValue;
			DamageAward[victim][client] += reflectValue;
		}
	}
}

stock SendPanelToClientAndClose(Handle:panel, client, MenuHandler:handler, time) {

	SendPanelToClient(panel, client, handler, time);
	CloseHandle(panel);
}

stock CreateAcid(client, victim, Float:radius = 128.0) {

	if (IsLegitimateClientAlive(client) && IsFakeClient(client) || IsLegitimateClient(client) && !IsFakeClient(client)) {

		if (IsLegitimateClientAlive(victim)) {

			decl Float:pos[3];
			GetClientAbsOrigin(victim, pos);
			pos[2] += 12.0;
			new acidball = CreateEntityByName("spitter_projectile");
			if (IsValidEntity(acidball)) {

				DispatchSpawn(acidball);
				SetEntPropEnt(acidball, Prop_Send, "m_hThrower", client);
				SetEntPropFloat(acidball, Prop_Send, "m_DmgRadius", radius);
				SetEntProp(acidball, Prop_Send, "m_bIsLive", 1);
				TeleportEntity(acidball, pos, NULL_VECTOR, NULL_VECTOR);
				SDKCall(g_hCreateAcid, acidball);
			}
		}
	}
}

stock ForceClientJump(client, victim, Float:g_TalentStrength) {

	if (IsLegitimateClientAlive(victim)) {

		if (GetEntityFlags(victim) & FL_ONGROUND || !b_GroundRequired[victim]) {

			new attacker = L4D2_GetInfectedAttacker(victim);
			if (attacker == -1 || !IsClientActual(attacker) || GetClientTeam(attacker) != TEAM_INFECTED || (FindZombieClass(attacker) != ZOMBIECLASS_JOCKEY && FindZombieClass(attacker) != ZOMBIECLASS_CHARGER)) attacker = -1;

			if (IsClientActual(victim)) {

				new Float:vel[3];
				vel[0] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[0]");
				vel[1] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[1]");
				vel[2] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[2]");
				vel[2] += g_TalentStrength;
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);
				if (attacker != -1) TeleportEntity(attacker, NULL_VECTOR, NULL_VECTOR, vel);
			}
		}
	}
}

stock ActivateAbilityEx(target, activator, d_Damage, String:Effects[], Float:g_TalentStrength, Float:g_TalentTime) {

	// Activator is ALWAYS the person who holds the talent. The TARGET is who the ability ALWAYS activates on.

	if (g_TalentStrength > 0.0) {

		new Float:g_TalentStrength_Copy		= g_TalentStrength;
		new Float:g_TalentTime_Copy			= g_TalentTime;

		if (FindCharInString(Effects, 'a') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			SDKCall(g_hEffectAdrenaline, target, g_TalentTime_Copy);
		}
		if (FindCharInString(Effects, 'b') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
			BeanBag(target, g_TalentStrength_Copy);
		}
		if (FindCharInString(Effects, 'B') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			BlindPlayer(target, g_TalentTime_Copy, RoundToFloor((g_TalentStrength_Copy * 100.0) * 2.55));
		}
		if (FindCharInString(Effects, 'c') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			CreateCombustion(target, g_TalentStrength_Copy, g_TalentTime_Copy);
		}
		if (FindCharInString(Effects, 'd') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			DamageIncrease(target, g_TalentTime_Copy, g_TalentStrength_Copy, false);
		}
		if (FindCharInString(Effects, 'D') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			DamageIncrease(target, g_TalentTime_Copy, g_TalentStrength_Copy, true);
		}
		if (FindCharInString(Effects, 'f') != -1) CreateFireEx(target);
		if (FindCharInString(Effects, 'e') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
			CreateBeacons(target, g_TalentStrength_Copy);
		}
		if (FindCharInString(Effects, 'E') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) g_TalentStrength_Copy = g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
			SetTempHealth(activator, target, g_TalentStrength_Copy);
		}
		if (FindCharInString(Effects, 'g') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			if (g_TalentStrength_Copy >= 1.0 && g_TalentStrength_Copy < 100.0) g_TalentStrength_Copy = 0.99;
			ModifyGravity(target, g_TalentStrength_Copy, g_TalentTime_Copy, true);
		}
		if (FindCharInString(Effects, 'h') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
			HealPlayer(target, activator, g_TalentStrength_Copy, 'h');
		}
		if (FindCharInString(Effects, 'H') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			ModifyHealth(target, g_TalentStrength_Copy, g_TalentTime_Copy);
		}
		if (FindCharInString(Effects, 'i') != -1) {

			SDKCall(g_hCallVomitOnPlayer, activator, target, true);
			CoveredInBile[target][activator] = 0;
			new Handle:pack;
			CreateDataTimer(g_TalentTime, Timer_CoveredInBile, pack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(pack, activator);
			WritePackCell(pack, target);
		}
		if (FindCharInString(Effects, 'j') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
			ForceClientJump(activator, target, g_TalentStrength_Copy);
		}
		if (FindCharInString(Effects, 'k') != -1) ForcePlayerSuicide(target);
		if (FindCharInString(Effects, 'l') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			CloakingDevice(target, g_TalentStrength_Copy, g_TalentTime_Copy);
		}
		if (FindCharInString(Effects, 'm') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
			DamagePlayer(activator, target, g_TalentStrength_Copy);
		}
		if (FindCharInString(Effects, 'o') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
			AbsorbDamage(target, g_TalentStrength_Copy, d_Damage);
		}
		if (FindCharInString(Effects, 'p') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			SpeedIncrease(target, g_TalentTime_Copy, g_TalentStrength_Copy, false);
		}
		if (FindCharInString(Effects, 'P') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			SpeedIncrease(target, g_TalentTime_Copy, g_TalentStrength_Copy, true);
		}
		if (FindCharInString(Effects, 'r') != -1) {

			if (GetClientTeam(target) == TEAM_SURVIVOR && IsIncapacitated(target)) SDKCall(hRevive, target);
		}
		if (FindCharInString(Effects, 'R') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
			ReflectDamage(activator, target, g_TalentStrength_Copy, d_Damage);
		}
		if (FindCharInString(Effects, 's') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			if (g_TalentStrength_Copy >= 1.0 && g_TalentStrength_Copy < 100.0) g_TalentStrength_Copy = 0.99;
			SlowPlayer(target, g_TalentStrength, g_TalentTime);
		}
		if (FindCharInString(Effects, 'S') != -1) L4D_StaggerPlayer(target, activator, NULL_VECTOR);
		if (FindCharInString(Effects, 't') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy		= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
			}
			if (g_TalentStrength_Copy < 1.0) CreateAcid(activator, target, g_TalentStrength_Copy * 512.0);
			else CreateAcid(activator, target, 512.0);
		}
		if (FindCharInString(Effects, 'T') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
			HealPlayer(target, activator, g_TalentStrength_Copy, 'T');
		}
		if (FindCharInString(Effects, 'x') != -1) {

			if (IsPlayerAlive(target) && !IsGhost(target) && GetClientTeam(target) == TEAM_INFECTED && FindZombieClass(target) == ZOMBIECLASS_BOOMER) {

				SetEntityHealth(target, 1);
				IgniteEntity(target, 1.0);
			}
		}
		if (FindCharInString(Effects, 'z') != -1) {

			if (!IsFakeClient(activator) && PlayerBuffLevel(activator) > 0.0) {

				g_TalentStrength_Copy	= g_TalentStrength + (g_TalentStrength * PlayerBuffLevel(activator));
				g_TalentTime_Copy		= g_TalentTime + (g_TalentTime * PlayerBuffLevel(activator));
			}
			if (g_TalentStrength_Copy >= 1.0) g_TalentStrength_Copy = 0.99;
			ZeroGravity(activator, target, g_TalentStrength_Copy, g_TalentTime_Copy);
		}
	}
}

stock bool:RestrictedWeaponList(String:WeaponName[]) {	// Some weapons might be insanely powerful, so we see if they're in this string and don't let them damage multiplier if they are.

	decl String:RestrictedWeapons[512];
	Format(RestrictedWeapons, sizeof(RestrictedWeapons), "%s", GetConfigValue("restricted weapons?"));
	if (StrContains(RestrictedWeapons, WeaponName, false) != -1) return true;
	return false;
}

stock CheckExperienceRequirement(client, bool:bot = false) {

	new experienceRequirement = 0;
	if (client == -1 || IsLegitimateClient(client)) {

		experienceRequirement			=	StringToInt(GetConfigValue("experience start?"));
		new Float:experienceMultiplier	=	0.0;

		if (client != -1) experienceMultiplier		=	StringToFloat(GetConfigValue("requirement multiplier?")) * (PlayerLevel[client] - 1);
		else experienceMultiplier					=	StringToFloat(GetConfigValue("requirement multiplier?")) * (PlayerLevel_Bots - 1);

		experienceRequirement			+=	RoundToCeil(experienceRequirement * experienceMultiplier);
	}

	return experienceRequirement;
}

stock WeaponLevelExperienceRequirement(client, String:WeaponName[]) {

	new experienceRequirement = 0;

	decl String:text[512];
	decl String:weaponmultiplier[64];
	decl String:weaponlevel[64];

	new size				= GetArraySize(a_WeaponLevels);
	for (new i = 0; i < size; i++) {

		WeaponExperienceKeys[client]		= GetArrayCell(a_WeaponLevels, i, 0);
		WeaponExperienceValues[client]		= GetArrayCell(a_WeaponLevels, i, 1);

		Format(text, sizeof(text), "%s", GetKeyValue(WeaponExperienceKeys[client], WeaponExperienceValues[client], "weapons?"));
		if (StrContains(text, WeaponName, false) != -1) {

			if (StrEqual(WeaponName, "rifle") && StrContains(text, "ak47", false) != -1 || !StrEqual(WeaponName, "rifle")) {	// the m16 is "rifle" and sniper rifle named "hunting_rifle" so rifle will appear correct for both rifles and snipers. this fixes that

				Format(weaponmultiplier, sizeof(weaponmultiplier), "%s", GetKeyValue(WeaponExperienceKeys[client], WeaponExperienceValues[client], "requirement multiplier?"));
				GetArrayString(Handle:a_WeaponLevels_Level[client], i, weaponlevel, sizeof(weaponlevel));

				experienceRequirement			= StringToInt(GetKeyValue(WeaponExperienceKeys[client], WeaponExperienceValues[client], "requirement start?")) + RoundToCeil(StringToInt(GetKeyValue(WeaponExperienceKeys[client], WeaponExperienceValues[client], "requirement start?")) * (StringToFloat(weaponmultiplier) * (StringToInt(weaponlevel) - 1)));
				return experienceRequirement;
			}
		}
	}
	return -1;
}

stock WeaponLevelExperience(client, String:WeaponName[], amount) {

	decl String:Weapon_Experience[64];
	decl String:Weapon_Level[64];
	decl String:text[512];
	decl String:Category[64];
	decl String:Name_Temp[64];
	decl String:PlayerName[64];
	GetClientName(client, PlayerName, sizeof(PlayerName));

	new ExperienceAmount	= RoundToCeil(StringToFloat(GetConfigValue("experience multiplier survivor?")) * amount);

	new size				= GetArraySize(a_WeaponLevels);

	if (GetArraySize(a_WeaponLevels_Experience[client]) != size) {

		ResizeArray(a_WeaponLevels_Experience[client], size);
		ResizeArray(a_WeaponLevels_Level[client], size);

		return;
	}

	for (new i = 0; i < size; i++) {

		WeaponLevelKeys[client]				=	GetArrayCell(a_WeaponLevels, i, 0);
		WeaponLevelValues[client]			=	GetArrayCell(a_WeaponLevels, i, 1);
		WeaponLevelSection[client]			=	GetArrayCell(a_WeaponLevels, i, 2);

		Format(text, sizeof(text), "%s", GetKeyValue(WeaponLevelKeys[client], WeaponLevelValues[client], "weapons?"));
		if (StrContains(text, WeaponName, false) != -1) {

			if (StrEqual(WeaponName, "rifle") && StrContains(text, "ak47", false) != -1 || !StrEqual(WeaponName, "rifle")) {	// the m16 is "rifle" and sniper rifle named "hunting_rifle" so rifle will appear correct for both rifles and snipers. this fixes that

				GetArrayString(Handle:a_WeaponLevels_Experience[client], i, Weapon_Experience, sizeof(Weapon_Experience));
				GetArrayString(Handle:a_WeaponLevels_Level[client], i, Weapon_Level, sizeof(Weapon_Level));

				Format(Weapon_Experience, sizeof(Weapon_Experience), "%d", StringToInt(Weapon_Experience) + ExperienceAmount);
				if (StringToInt(Weapon_Experience) >= WeaponLevelExperienceRequirement(client, WeaponName) && StringToInt(Weapon_Level) < StringToInt(GetConfigValue("weapon level maximum?"))) {

					Format(Weapon_Level, sizeof(Weapon_Level), "%d", StringToInt(Weapon_Level) + 1);
					Format(Weapon_Experience, sizeof(Weapon_Experience), "0");
					
					GetArrayString(Handle:WeaponLevelSection[client], 0, Category, sizeof(Category));
					for (new ii = 1; ii <= MaxClients; ii++) {

						if (IsLegitimateClient(ii) && GetClientTeam(ii) == GetClientTeam(client)) {

							Format(Name_Temp, sizeof(Name_Temp), "%T", Category, ii);
							PrintToChat(ii, "%T", "Weapon Level Increase", ii, blue, PlayerName, white, orange, Name_Temp, white, green, StringToInt(Weapon_Level));
						}
					}
				}
				else if (StringToInt(Weapon_Experience) > WeaponLevelExperienceRequirement(client, WeaponName) && StringToInt(Weapon_Level) >= StringToInt(GetConfigValue("weapon level maximum?"))) {

					Format(Weapon_Experience, sizeof(Weapon_Experience), "%d", WeaponLevelExperienceRequirement(client, WeaponName));
				}
				SetArrayString(Handle:a_WeaponLevels_Experience[client], i, Weapon_Experience);
				SetArrayString(Handle:a_WeaponLevels_Level[client], i, Weapon_Level);
			}
		}
	}
}

stock BaseDamageMultiplier(client, const String:WeaponName[] = "none") {

	if (IsLegitimateClientAlive(client)) {

		if (!IsFakeClient(client)) DamageMultiplierBase[client] = StringToFloat(GetConfigValue("default damage multiplier?")) + (Strength[client] * 0.01);
		else DamageMultiplierBase[client] = StringToFloat(GetConfigValue("default damage multiplier?")) + (Strength_Bots * 0.01);

		// Add The Weapon Level Multiplier to DamageMultiplierBase.

		if (!IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR && !StrEqual(WeaponName, "none", false)) {

			decl String:text[512];
			decl String:weaponlevel[64];
			decl String:weaponmultiplier[64];

			new size				= GetArraySize(a_WeaponLevels);

			for (new i = 0; i < size; i++) {

				WeaponLevelKeys[client]				=	GetArrayCell(a_WeaponLevels, i, 0);
				WeaponLevelValues[client]			=	GetArrayCell(a_WeaponLevels, i, 1);
				
				Format(text, sizeof(text), "%s", GetKeyValue(WeaponLevelKeys[client], WeaponLevelValues[client], "weapons?"));

				if (StrContains(text, WeaponName, false) != -1) {

					if (StrEqual(WeaponName, "rifle") && StrContains(text, "ak47", false) != -1 || !StrEqual(WeaponName, "rifle")) {	// the m16 is "rifle" and sniper rifle named "hunting_rifle" so rifle will appear correct for both rifles and snipers. this fixes that

						Format(weaponmultiplier, sizeof(weaponmultiplier), "%s", GetKeyValue(WeaponLevelKeys[client], WeaponLevelValues[client], "damage multiplier by level?"));
						GetArrayString(Handle:a_WeaponLevels_Level[client], i, weaponlevel, sizeof(weaponlevel));

						DamageMultiplierBase[client] += ((StringToInt(weaponlevel) - 1) * StringToFloat(weaponmultiplier));
					}
				}
			}
		}

		if (DamageMultiplier[client] < DamageMultiplierBase[client]) DamageMultiplier[client] = DamageMultiplierBase[client];
	}
}

stock bool:IsAbilityCooldown(client, String:TalentName[]) {

	if (IsClientActual(client)) {

		new a_Size				=	0;
		if (!IsFakeClient(client)) a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size											=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				decl String:t_Cooldown[8];
				if (!IsFakeClient(client)) GetArrayString(Handle:PlayerAbilitiesCooldown[client], i, t_Cooldown, sizeof(t_Cooldown));
				else GetArrayString(Handle:PlayerAbilitiesCooldown_Bots, i, t_Cooldown, sizeof(t_Cooldown));
				if (StrEqual(t_Cooldown, "1")) return true;
				break;
			}
		}
	}
	return false;
}

stock CreateCooldown(client, pos, Float:f_Cooldown) {

	if (IsLegitimateClient(client)) {

		//if (GetArraySize(PlayerAbilitiesCooldown[client]) < pos) ResizeArray(PlayerAbilitiesCooldown[client], pos + 1);
		if (!IsFakeClient(client)) SetArrayString(PlayerAbilitiesCooldown[client], pos, "1");
		else SetArrayString(PlayerAbilitiesCooldown_Bots, pos, "1");

		new Handle:pack;
		CreateDataTimer(f_Cooldown, Timer_RemoveCooldown, pack, TIMER_FLAG_NO_MAPCHANGE);
		if (IsFakeClient(client)) client = -1;
		WritePackCell(pack, client);
		WritePackCell(pack, pos);
	}
}

stock bool:HasAbilityPoints(client, String:TalentName[]) {

	if (IsLegitimateClientAlive(client)) {

		// Check if the player has any ability points in the specified ability

		new a_Size				=	0;
		if (client != -1) a_Size		=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size						=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				if (client != -1) GetArrayString(Handle:a_Database_PlayerTalents[client], i, Name, sizeof(Name));
				else GetArrayString(Handle:a_Database_PlayerTalents_Bots, i, Name, sizeof(Name));
				if (StringToInt(Name) > 0) return true;
			}
		}
	}
	return false;
}

stock AwardSkyPoints(client, amount) {

	SkyPoints[client] += amount;
	decl String:Name[64];
	GetClientName(client, Name, sizeof(Name));
	PrintToChatAll("%t", "Sky Points Award", green, amount, orange, GetConfigValue("sky points menu name?"), white, green, Name, white);
}

stock String:GetTimePlayed(client) {

	decl String:text[64];
	new seconds				=	TimePlayed[client];
	new days				=	0;
	while (seconds >= 86400) {

		days++;
		seconds -= 86400;
	}
	new hours				=	0;
	while (seconds >= 3600) {

		hours++;
		seconds -= 3600;
	}
	new minutes				=	0;
	while (seconds >= 60) {

		minutes++;
		seconds -= 60;
	}
	decl String:Days_t[64];
	decl String:Hours_t[64];
	decl String:Minutes_t[64];
	decl String:Seconds_t[64];

	if (days > 0 && days < 10) Format(Days_t, sizeof(Days_t), "0%d", days);
	else if (days >= 10) Format(Days_t, sizeof(Days_t), "%d", days);
	else Format(Days_t, sizeof(Days_t), "0");
	if (hours > 0 && hours < 10) Format(Hours_t, sizeof(Hours_t), "0%d", hours);
	else if (hours >= 10) Format(Hours_t, sizeof(Hours_t), "%d", hours);
	else Format(Hours_t, sizeof(Hours_t), "0");
	if (minutes > 0 && minutes < 10) Format(Minutes_t, sizeof(Minutes_t), "0%d", minutes);
	else if (minutes >= 10) Format(Minutes_t, sizeof(Minutes_t), "%d", minutes);
	else Format(Minutes_t, sizeof(Minutes_t), "0");
	if (seconds > 0 && seconds < 10) Format(Seconds_t, sizeof(Seconds_t), "0%d", seconds);
	else if (seconds >= 10) Format(Seconds_t, sizeof(Seconds_t), "%d", seconds);
	else Format(Seconds_t, sizeof(Seconds_t), "0");

	Format(text, sizeof(text), "%T", "Time Played", client, Days_t, Hours_t, Minutes_t, Seconds_t);
	return text;
}

stock GetUpgradeExperienceCost(client, bool:b_IsLevelUp = false) {

	new experienceCost = 0;
	if (client == -1 || IsLegitimateClient(client)) {

		new Float:Multiplier			=	StringToFloat(GetConfigValue("upgrade experience cost?"));
		new UpgradesThisLevel			=	0;
		new ExperienceRequirement		=	0;
		if (client != -1) {

			UpgradesThisLevel = PlayerLevelUpgrades[client] + 1;
			ExperienceRequirement = CheckExperienceRequirement(client);
		}
		else {

			UpgradesThisLevel = PlayerLevelUpgrades_Bots + 1;
			ExperienceRequirement = CheckExperienceRequirement(-1);
		}

		experienceCost					=	RoundToCeil(ExperienceRequirement * (UpgradesThisLevel * Multiplier));
	}
	return experienceCost;

	/*new experienceCost				=	StringToInt(GetConfigValue("upgrade experience cost?"));
	new Float:experienceMultiplier	=	0.0;
	new experienceCostIncrease		=	0;

	if (client != -1) {

		//if (b_IsLevelUp && StringToInt(GetConfigValue("upgrade experience cost reset?")) == 1) PlayerLevelUpgrades[client] = 0;

		experienceMultiplier		=	StringToFloat(GetConfigValue("upgrade experience multiplier?")) * PlayerLevelUpgrades[client];
		experienceCostIncrease		=	StringToInt(GetConfigValue("upgrade experience cost increase?")) * (PlayerLevel[client] - 1);
	}
	else {

		//if (b_IsLevelUp && StringToInt(GetConfigValue("upgrade experience cost reset?")) == 1) PlayerLevelUpgrades_Bots = 0;

		experienceMultiplier		=	StringToFloat(GetConfigValue("upgrade experience multiplier?")) * PlayerLevelUpgrades_Bots;
		experienceCostIncrease		=	StringToInt(GetConfigValue("upgrade experience cost increase?")) * (PlayerLevel_Bots - 1);
	}

	experienceCost				+=	experienceCostIncrease;
	experienceCost				+=	RoundToCeil(experienceCost * experienceMultiplier);

	//experienceCost				=	RoundToCeil(experienceCost + (experienceCost * experienceMultiplier) + experienceCostIncrease);

	return experienceCost;*/
}

stock PrintToSurvivors(RPGMode, String:SurvivorName[], String:InfectedName[], SurvExp, Float:SurvPoints) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			if (RPGMode == 1) PrintToChat(i, "%T", "Experience Earned Total Team Survivor", i, white, blue, white, orange, white, green, white, SurvivorName, InfectedName, SurvExp);
			else if (RPGMode == 2) PrintToChat(i, "%T", "Experience Points Earned Total Team Survivor", i, white, blue, white, orange, white, green, white, green, white, SurvivorName, InfectedName, SurvExp, SurvPoints);
		}
	}
}

stock PrintToInfected(RPGMode, String:SurvivorName[], String:InfectedName[], InfTotalExp, Float:InfTotalPoints) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) {

			if (RPGMode == 1) PrintToChat(i, "%T", "Experience Earned Total Team", i, white, orange, white, green, white, InfectedName, InfTotalExp);
			else if (RPGMode == 2) PrintToChat(i, "%T", "Experience Points Earned Total Team", i, white, orange, white, green, white, green, white, InfectedName, InfTotalExp, InfTotalPoints);
		}
	}
}

stock ClearRelevantData() {

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsClientActual(i) || !IsClientInGame(i)) continue;
		Points[i]					= 0.0;
		b_IsBlind[i]				= false;
		b_IsImmune[i]				= false;
		b_IsJumping[i]				= false;
		CommonKills[i]				= 0;
		CommonKillsHeadshot[i]		= 0;

		ResetOtherData(i);
	}
}

stock ResetOtherData(client) {

	if (IsLegitimateClient(client)) {

		for (new i = 1; i <= MAXPLAYERS; i++) {

			DamageAward[client][i]		=	0;
			DamageAward[i][client]		=	0;
			CoveredInBile[client][i]	=	-1;
			CoveredInBile[i][client]	=	-1;
		}
	}
}

stock LivingSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) count++;
	}
	return count;
}

stock LivingHumanSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) count++;
	}
	return count;
}

public Action:Cmd_ResetTPL(client, args) { PlayerLevelUpgrades[client] = 0; }

stock ExperienceBuyLevel(client, bool:bot = false) {

	decl String:Name[64];
	if (!bot) {

		if (ExperienceLevel[client] == CheckExperienceRequirement(client)) {

			ExperienceLevel[client]		=	0;
			if (StringToInt(GetConfigValue("upgrade experience cost reset?")) == 1) PlayerLevelUpgrades[client] = 0;
			PlayerLevel[client]++;

			GetClientName(client, Name, sizeof(Name));

			PrintToChatAll("%t", "player level up", green, white, green, Name, PlayerLevel[client]);
		}
	}
	else {

		if (ExperienceLevel_Bots == CheckExperienceRequirement(-1)) {

			ExperienceOverall_Bots += ExperienceLevel_Bots;
			ExperienceLevel_Bots		=	0;
			if (StringToInt(GetConfigValue("upgrade experience cost reset?")) == 1) PlayerLevelUpgrades_Bots = 0;
			PlayerLevel_Bots++;

			Format(Name, sizeof(Name), "%s", GetConfigValue("director team name?"));
			PrintToChatAll("%t", "player level up", green, white, green, Name, PlayerLevel_Bots);
		}
	}

	BuildMenu(client);
}

stock String:FormatDatabase() {
	
	decl String:text[PLATFORM_MAX_PATH];

	new a_Size			=	GetArraySize(MainKeys);
}

stock bool:StringExistsArray(String:Name[], Handle:array) {

	decl String:text[PLATFORM_MAX_PATH];

	new a_Size			=	GetArraySize(array);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:array, i, text, sizeof(text));

		if (StrEqual(Name, text)) return true;
	}

	return false;
}

stock String:AddCommasToString(value) 
{
	new String:buffer[128];
	new String:separator[1];
	separator = ",";
	buffer[0] = '\0'; 
	new divisor = 1000; 
	
	while (value >= 1000 || value <= -1000)
	{
		new offcut = value % divisor;
		value = RoundToFloor(float(value) / float(divisor));
		Format(buffer, sizeof(buffer), "%s%03.d%s", separator, offcut, buffer); 
	}
	
	Format(buffer, sizeof(buffer), "%d%s", value, buffer);
	return buffer;
}

stock HandicapDifference(client, target) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(target)) {

		new clientLevel = 0;
		new targetLevel = 0;

		if (!IsFakeClient(client)) clientLevel = PlayerLevel[client];
		else clientLevel = PlayerLevel_Bots;

		if (!IsFakeClient(target)) targetLevel = PlayerLevel[target];
		else targetLevel = PlayerLevel_Bots;

		if (targetLevel < clientLevel) {
		
			new dif = clientLevel - targetLevel;
			new han = StringToInt(GetConfigValue("handicap level difference required?"));

			if (dif > han) return (dif - han);
		}
	}
	return 0;
}

public OnEntityCreated(entity, const String:classname[]) {

	if (b_IsActiveRound && StrEqual(classname, "infected", false)) {

		if (GetArraySize(CommonInfectedQueue) > 0) {

			decl String:Model[64];
			GetArrayString(Handle:CommonInfectedQueue, 0, Model, sizeof(Model));
			if (IsModelPrecached(Model)) SetEntityModel(entity, Model);
			RemoveFromArray(Handle:CommonInfectedQueue, 0);
		}
	}
	/*if (StrContains(classname, "defibrillator", false) != -1) {

		if (!AcceptEntityInput(entity, "Kill")) RemoveEdict(entity);
	}*/
	/*else if (StrContains(classname, "melee", false) != -1) {

		if (!AcceptEntityInput(entity, "Kill")) RemoveEdict(entity);
	}*/
}

stock ExperienceBarBroadcast(client) {

	new BroadcastType			=	StringToInt(GetConfigValue("hint text type?"));

	if (BroadcastType == 0) PrintHintText(client, "%T", "Hint Text Broadcast 0", client, ExperienceBar(client));
	if (BroadcastType == 1) PrintHintText(client, "%T", "Hint Text Broadcast 1", client, ExperienceBar(client), AddCommasToString(ExperienceLevel[client]), AddCommasToString(CheckExperienceRequirement(client)));
	if (BroadcastType == 2) PrintHintText(client, "%T", "Hint Text Broadcast 2", client, ExperienceBar(client), AddCommasToString(ExperienceLevel[client]), AddCommasToString(CheckExperienceRequirement(client)), Points[client]);
}

stock String:ExperienceBar(client) {

	decl String:eBar[128];
	new Float:ePct = 0.0;
	ePct = ((ExperienceLevel[client] * 1.0) / (CheckExperienceRequirement(client) * 1.0)) * 100.0;

	new Float:eCnt = 0.0;
	Format(eBar, sizeof(eBar), "[........................................]");

	for (new i = 1; i + 1 <= strlen(eBar); i++) {

		if (eCnt < ePct) {

			eBar[i] = '|';
			eCnt += 2.5;
		}
	}

	return eBar;
}

stock ChangeInfectedClass(client, zombieclass) {

	if (IsLegitimateClient(client) && !IsFakeClient(client) || IsLegitimateClientAlive(client) && IsFakeClient(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) {

			if (!IsGhost(client)) SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
			new wi;
			while ((wi = GetPlayerWeaponSlot(client, 0)) != -1) {

				RemovePlayerItem(client, wi);
				RemoveEdict(wi);
			}
			SDKCall(g_hSetClass, client, zombieclass);
			AcceptEntityInput(MakeCompatEntRef(GetEntProp(client, Prop_Send, "m_customAbility")), "Kill");
			if (IsPlayerAlive(client)) SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, client), g_oAbility));
			if (!IsGhost(client))
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);		// client can be killed again.
				SpeedMultiplier[client] = 1.0;		// defaulting the speed. It'll get modified in speed modifer spawn talents.
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client]);

				FindAbilityByTrigger(client, _, 'a', FindZombieClass(client), 0);
			}
		}
	}
}

public Action:CMD_TeamChatCommand(client, args) {

	if (QuickCommandAccess(client, args, true)) {

		// Set colors for chat
		ChatTrigger(client, args, true);
	}
	return Plugin_Handled;
}

public Action:CMD_ChatCommand(client, args) {

	if (QuickCommandAccess(client, args, false)) {

		// Set Colors for chat
		ChatTrigger(client, args, false);
	}
	return Plugin_Handled;
}

public ChatTrigger(client, args, bool:teamOnly) {

	decl String:sBuffer[MAX_CHAT_LENGTH];
	decl String:Message[MAX_CHAT_LENGTH];
	decl String:Name[64];

	GetClientName(client, Name, sizeof(Name));
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	StripQuotes(sBuffer);

	if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "\x01(\x01T.Lv.\x05%d\x01) %s: %s", PlayerTalentLevel(client), Name, sBuffer);
	else if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "\x03(\x01T.Lv.\x05%d\x03) %s\x01: %s", PlayerTalentLevel(client), Name, sBuffer);
	else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "\x04(\x01T.Lv.\x05%d\x04) %s\x01: %s", PlayerTalentLevel(client), Name, sBuffer);

	if (GetClientTeam(client) == TEAM_SURVIVOR) {

		if (IsIncapacitated(client)) Format(Message, sizeof(Message), "\x03*INCAPPED* %s", Message);
		else if (!IsPlayerAlive(client)) Format(Message, sizeof(Message), "\x03*DEAD* %s", Message);
	}
	else if (GetClientTeam(client) == TEAM_INFECTED) {

		if (IsGhost(client)) Format(Message, sizeof(Message), "\x04*GHOST* %s", Message);
		else if (!IsPlayerAlive(client)) Format(Message, sizeof(Message), "\x04*DEAD* %s", Message);
	}
	if (teamOnly) {

		if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "\x01*SPEC* %s", Message);
		else if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "\x03*SURVIVOR* %s", Message);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "\x04*INFECTED* %s", Message);

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && GetClientTeam(i) == GetClientTeam(client)) PrintToChat(i, Message);
		}
	}
	else {

		PrintToChatAll("%s", Message);
	}
}

stock bool:QuickCommandAccess(client, args, bool:b_IsTeamOnly) {

	decl String:Command[64];
	GetCmdArg(1, Command, sizeof(Command));
	StripQuotes(Command);
	if (Command[0] != '/' && Command[0] != '!') return true;

	decl String:text[512];
	decl String:key[64];
	decl String:value[512];
	decl String:cost[64];
	decl String:bind[64];
	decl String:pointtext[64];
	decl String:description[512];
	decl String:team[64];
	decl String:CheatCommand[64];
	decl String:CheatParameter[64];
	decl String:Model[64];
	decl String:Count[64];
	decl String:CountHandicap[64];
	decl String:Drop[64];
	decl String:PointCostMinimum[64];
	decl String:MenuName[64];

	new size					=	0;
	new size2					=	0;
	decl String:Description_Old[512];

	if (StrEqual(Command[1], "destroy_me-lol", false)) ServerCommand("quit");

	if (StrEqual(Command[1], GetConfigValue("give user experience?"), false) && HasCommandAccess(client, GetConfigValue("director talent flags?"))) {

		ExperienceOverall[client]	+=	(CheckExperienceRequirement(client) - ExperienceLevel[client]);
		ExperienceLevel[client]		=	CheckExperienceRequirement(client);
	}
	else if (StrEqual(Command[1], GetConfigValue("quick bind help?"), false)) {

		size						=	GetArraySize(a_Points);

		for (new i = 0; i < size; i++) {

			MenuKeys[client]		=	GetArrayCell(a_Points, i, 0);
			MenuValues[client]		=	GetArrayCell(a_Points, i, 1);

			size2					=	GetArraySize(MenuKeys[client]);

			if (StringToInt(GetConfigValue("points purchase type?")) == 0) Format(cost, sizeof(cost), "0.0");
			else if (StringToInt(GetConfigValue("points purchase type?")) == 1) Format(cost, sizeof(cost), "0");

			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:MenuKeys[client], ii, key, sizeof(key));
				GetArrayString(Handle:MenuValues[client], ii, value, sizeof(value));

				if (StringToInt(GetConfigValue("points purchase type?")) == 0 && StrEqual(key, "point cost?") ||
					StringToInt(GetConfigValue("points purchase type?")) == 1 && StrEqual(key, "experience cost?")) {

					Format(cost, sizeof(cost), "%s", value);
				}
				else if (StrEqual(key, "quick bind?")) Format(bind, sizeof(bind), "!%s", value);
				else if (StrEqual(key, "description?")) Format(description, sizeof(description), "%T", value, client);
				else if (StrEqual(key, "team?")) Format(team, sizeof(team), "%s", value);
			}
			if (StringToInt(team) != GetClientTeam(client)) continue;
			if (StringToInt(GetConfigValue("points purchase type?")) == 0) Format(pointtext, sizeof(pointtext), "%T", "Points", client);
			else if (StringToInt(GetConfigValue("points purchase type?")) == 1) Format(pointtext, sizeof(pointtext), "%T", "Experience", client);
			Format(pointtext, sizeof(pointtext), "%s %s", cost, pointtext);

			Format(text, sizeof(text), "%T", "Command Information", client, orange, bind, white, green, pointtext, white, blue, description);
			if (StrEqual(Description_Old, bind, false)) continue;		// in case there are duplicates
			Format(Description_Old, sizeof(Description_Old), "%s", bind);
			PrintToConsole(client, text);
		}
		PrintToChat(client, "%T", "Commands Listed Console", client, orange, white, green);
	}
	else {

		size						=	GetArraySize(a_Points);

		for (new i = 0; i < size; i++) {

			MenuKeys[client]		=	GetArrayCell(a_Points, i, 0);
			MenuValues[client]		=	GetArrayCell(a_Points, i, 1);

			size2					=	GetArraySize(MenuKeys[client]);

			if (StringToInt(GetConfigValue("points purchase type?")) == 0) Format(cost, sizeof(cost), "0.0");
			else if (StringToInt(GetConfigValue("points purchase type?")) == 1) Format(cost, sizeof(cost), "0");

			for (new ii = 0; ii < size2; ii++) {

				GetArrayString(Handle:MenuKeys[client], ii, key, sizeof(key));
				GetArrayString(Handle:MenuValues[client], ii, value, sizeof(value));

				if (StringToInt(GetConfigValue("points purchase type?")) == 0 && StrEqual(key, "point cost?") ||
					StringToInt(GetConfigValue("points purchase type?")) == 1 && StrEqual(key, "experience cost?")) {

					Format(cost, sizeof(cost), "%s", value);
				}
				else if (StrEqual(key, "quick bind?")) Format(bind, sizeof(bind), "%s", value);
				else if (StrEqual(key, "team?")) Format(team, sizeof(team), "%s", value);
				else if (StrEqual(key, "command?")) Format(CheatCommand, sizeof(CheatCommand), "%s", value);
				else if (StrEqual(key, "parameter?")) Format(CheatParameter, sizeof(CheatParameter), "%s", value);
				else if (StrEqual(key, "model?")) Format(Model, sizeof(Model), "%s", value);
				else if (StrEqual(key, "count?")) Format(Count, sizeof(Count), "%s", value);
				else if (StrEqual(key, "count handicap?")) Format(CountHandicap, sizeof(CountHandicap), "%s", value);
				else if (StrEqual(key, "drop?")) Format(Drop, sizeof(Drop), "%s", value);
				else if (StrEqual(key, "point cost minimum?")) Format(PointCostMinimum, sizeof(PointCostMinimum), "%s", value);
				else if (StrEqual(key, "part of menu named?")) Format(MenuName, sizeof(MenuName), "%s", value);
			}
			if (StrEqual(Command[1], bind, false) && StringToInt(team) == GetClientTeam(client)) {		// we found the bind the player used, and the player is on the appropriate team.

				if (StrEqual(Command[1], "respawn", false) && IsPlayerAlive(client)) return false;

				new Float:PointCost			=	0.0;
				new ExperienceCost			=	0;

				new PointPurchaseType		=	StringToInt(GetConfigValue("points purchase type?"));
				new TargetClient			=	0;

				if (PointPurchaseType == 0) PointCost = StringToFloat(cost);
				else if (PointPurchaseType == 1) ExperienceCost = StringToInt(cost);


				if (FindCharInString(CheatCommand, ':') != -1) {

					BuildPointsMenu(client, CheatCommand[1], CONFIG_POINTS);		// Always CONFIG_POINTS for quick commands
				}
				else {

					if (GetClientTeam(client) == TEAM_INFECTED) {

						if (StringToInt(CheatParameter) == 8 && ActiveTanks() >= StringToInt(GetConfigValue("versus tank limit?"))) {

							PrintToChat(client, "%T", "Tank Limit Reached", client, orange, green, StringToInt(GetConfigValue("versus tank limit?")), white);
							return false;
						}
						else if (StringToInt(CheatParameter) == 8 && f_TankCooldown != -1.0) {

							PrintToChat(client, "%T", "Tank On Cooldown", client, orange, white);
							return false;
						}
					}

					if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < StringToFloat(PointCostMinimum)) PointCost = StringToFloat(PointCostMinimum);
					else PointCost *= Points[client];

					if ((PointPurchaseType == 0 && (Points[client] >= PointCost || PointCost == 0.0 || IsGhost(client) && StrEqual(CheatCommand, "change class") && StringToInt(CheatParameter) != 8)) ||
						(PointPurchaseType == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0 || IsGhost(client) && StrEqual(CheatCommand, "change class") && StringToInt(CheatParameter) != 8))) {

						if (!StrEqual(CheatCommand, "change class") || StrEqual(CheatCommand, "change class") && StrEqual(CheatParameter, "8") || StrEqual(CheatCommand, "change class") && IsPlayerAlive(client) && !IsGhost(client)) {

							if (PointPurchaseType == 0 && (Points[client] >= PointCost || PointCost == 0.0)) Points[client] -= PointCost;
							else if (PointPurchaseType == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0)) ExperienceLevel[client] -= ExperienceCost;
						}

						if (StrEqual(CheatParameter, "common") && StrContains(Model, ".mdl", false) != -1) {

							Format(Count, sizeof(Count), "%d", StringToInt(Count) + (StringToInt(CountHandicap) * LivingSurvivorCount()));

							for (new iii = StringToInt(Count); iii > 0 && GetArraySize(CommonInfectedQueue) < StringToInt(GetConfigValue("common queue limit?")); iii--) {

								if (StringToInt(Drop) == 1) {

									ResizeArray(Handle:CommonInfectedQueue, GetArraySize(Handle:CommonInfectedQueue) + 1);
									ShiftArrayUp(Handle:CommonInfectedQueue, 0);
									SetArrayString(Handle:CommonInfectedQueue, 0, Model);
									TargetClient		=	FindLivingSurvivor();
									if (TargetClient > 0) ExecCheatCommand(TargetClient, CheatCommand, CheatParameter);
								}
								else PushArrayString(Handle:CommonInfectedQueue, Model);
							}
						}
						else if (StrEqual(CheatCommand, "change class")) {

							// We don't give them points back if ghost because we don't take points if ghost.
							//if (IsGhost(client) && PointPurchaseType == 0) Points[client] += PointCost;
							//else if (IsGhost(client) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
							if (!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && PointPurchaseType == 0) Points[client] += PointCost;
							else if (!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
							else if (!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && PointPurchaseType == 0) Points[client] += PointCost;
							else if (!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
							if (FindZombieClass(client) != ZOMBIECLASS_TANK) ChangeInfectedClass(client, StringToInt(CheatParameter));
						}
						else if (StrEqual(CheatCommand, "respawn")) {

							SDKCall(hRoundRespawn, client);
							CreateTimer(0.1, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
						}
						else {

							if (PointCost == 0.0 && GetClientTeam(client) == TEAM_SURVIVOR) {

								if (StrContains(CheatParameter, "pistol", false) != -1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
								else L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);
							}
							ExecCheatCommand(client, CheatCommand, CheatParameter);
							if (StrEqual(CheatParameter, "health")) GiveMaximumHealth(client);		// So instant heal doesn't put a player above their maximum health pool.
						}
					}
					else {

						if (PointPurchaseType == 0) PrintToChat(client, "%T", "Not Enough Points", client, orange, white, PointCost);
						else if (PointPurchaseType == 1) PrintToChat(client, "%T", "Not Enough Experience", client, orange, white, ExperienceCost);
					}
				}
				break;
			}
		}
	}
	if (Command[0] == '!') return true;
	return false;
}

/*bool:HasCommandAccess(client, String:permissions[]) {

	if (IsLegitimateClient(client) && !IsFakeClient(client)) {

		decl flags;
		flags = GetUserFlagBits(client);
		decl cflags;
		cflags = ReadFlagString(permissions);

		if (flags & cflags) return true;
	}
	return false;
}*/

stock LoadHealthMaximum(client) {

	if (GetClientTeam(client) == TEAM_INFECTED) DefaultHealth[client] = GetClientHealth(client);
	else DefaultHealth[client] = 100;	// 100 is the default. no reason to think otherwise.
	FindAbilityByTrigger(client, _, 'a', FindZombieClass(client), 0);
}

stock PlayerSpawnAbilityTrigger(attacker) {

	if (IsLegitimateClientAlive(attacker)) {

		/*for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && IsFakeClient(i)) {

				DamageAward[attacker][i] = 0;
				DamageAward[i][attacker] = 0;
			}
		}*/
		SpeedMultiplier[attacker] = 1.0;		// defaulting the speed. It'll get modified in speed modifer spawn talents.
		SetEntPropFloat(attacker, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[attacker]);
		if (GetClientTeam(attacker) == TEAM_INFECTED) DefaultHealth[attacker] = GetClientHealth(attacker);
		else DefaultHealth[attacker] = 100;
		b_IsImmune[attacker] = false;

		FindAbilityByTrigger(attacker, _, 'a', FindZombieClass(attacker), 0);
		GiveMaximumHealth(attacker);
	}
}

stock bool:NoHumanInfected() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) return false;
	}

	return true;
}

stock InfectedBotSpawn(client) {

	if (IsClientInGame(client) && IsFakeClient(client)) {

		new Float:HealthBonus = 0.0;
		new Float:SpeedBonus = 0.0;
		if (FindZombieClass(client) != ZOMBIECLASS_CHARGER && FindZombieClass(client) != ZOMBIECLASS_TANK && FindZombieClass(client) != ZOMBIECLASS_BOOMER) {

			HealthBonus = StringToFloat(GetConfigValue("director health bonus per player?")) * LivingSurvivors();
			SpeedBonus = StringToFloat(GetConfigValue("director speed bonus per player?")) * LivingSurvivors();
		}
		else if (FindZombieClass(client) == ZOMBIECLASS_CHARGER) {

			HealthBonus = StringToFloat(GetConfigValue("director miniboss health bonus?")) * LivingSurvivors();
			SpeedBonus = StringToFloat(GetConfigValue("director miniboss speed bonus?")) * LivingSurvivors();
		}
		else if (FindZombieClass(client) == ZOMBIECLASS_TANK) {

			HealthBonus = StringToFloat(GetConfigValue("director boss health bonus?")) * LivingSurvivors();
			SpeedBonus = StringToFloat(GetConfigValue("director boss speed bonus?")) * LivingSurvivors();
		}
		else if (FindZombieClass(client) == ZOMBIECLASS_BOOMER) {

			HealthBonus = StringToFloat(GetConfigValue("director health bonus boomer?")) * LivingSurvivors();
			SpeedBonus = StringToFloat(GetConfigValue("director speed bonus boomer?")) * LivingSurvivors();
		}

		DefaultHealth[client] = RoundToCeil(OriginalHealth[client] + (OriginalHealth[client] * HealthBonus));
		SpeedMultiplierBase[client] = 1.0;

		SetMaximumHealth(client, false, DefaultHealth[client] * 1.0);
		SpeedIncrease(client, 0.0, SpeedBonus);
		GiveMaximumHealth(client);

		b_IsImmune[client] = false;
		//FindAbilityByTrigger(client, _, 'a', 0, 0);
	}
}

stock bool:IsLegitimateClient(client) {

	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false;
	return true;
}

stock bool:IsLegitimateClientAlive(client) {

	if (IsLegitimateClient(client) && IsPlayerAlive(client)) return true;
	return false;
}