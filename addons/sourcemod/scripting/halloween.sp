#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

#define EF_NODRAW (1 << 5)
#define TF_VISION_FILTER_HALLOWEEN (1 << 1)
#define VISION_MODE_HALLOWEEN 2

#define ATTRIB_PUMPKINBOMBS 1007
#define ATTRIB_HALLOWEENFIRE 1008
#define ATTRIB_EXORCISM 1009

#define TOMB_MODEL "models/props_halloween/tombstone_01.mdl"
#define TOMB_SCALE 0.6
#define TOMB_PARTICLE_RED "spell_cast_wheel_red"
#define TOMB_PARTICLE_BLUE "spell_cast_wheel_blue"

#define PROJECTILE_MODEL "models/props_halloween/eyeball_projectile.mdl"
#define CORRECTION_FILE "materials/correction/night.raw"

#define POINT_CAPTURE_SOUND "misc/halloween/strongman_bell_01.wav"

#define MODEL_AMMO_FULL "models/halloween/misc/ammopack_large.mdl"
#define MODEL_AMMO_MEDIUM "models/halloween/misc/ammopack_medium.mdl"
#define MODEL_AMMO_SMALL "models/halloween/misc/ammopack_small.mdl"
#define MODEL_RESUPPLY "models/halloween/misc/resupply_locker.mdl"
#define MODEL_ARMS_ROBOTARM "models/halloween/viewmodels/c_engineer_gunslinger_zombie.mdl"

static const char g_sWelcomeSound[][] =
{
	"ui/quest_turn_in_decode_halloween.wav",
	"ui/quest_turn_in_accepted_halloween.wav",
	"ui/halloween_boss_player_becomes_it.wav",
	"misc/halloween_eyeball/vortex_eyeball_died.wav",
	"vo/halloween_merasmus/sf12_appears09.mp3",
	"vo/halloween_eyeball/eyeball_biglaugh01.mp3"
};

static const char g_sPickupSound[][] =
{
	"misc/halloween/duck_pickup_pos_01.wav",
	"misc/halloween/duck_pickup_neg_01.wav"
};

static const char g_sZombieViewmodel[TFClassType][] =
{
	"",
	"models/halloween/viewmodels/c_scout_arms_zombie.mdl",
	"models/halloween/viewmodels/c_sniper_arms_zombie.mdl",
	"models/halloween/viewmodels/c_soldier_arms_zombie.mdl",
	"models/halloween/viewmodels/c_demo_arms_zombie.mdl",
	"models/halloween/viewmodels/c_medic_arms_zombie.mdl",
	"models/halloween/viewmodels/c_heavy_arms_zombie.mdl",
	"models/halloween/viewmodels/c_pyro_arms_zombie.mdl",
	"models/halloween/viewmodels/c_spy_arms_zombie.mdl",
	"models/halloween/viewmodels/c_engineer_arms_zombie.mdl"	// + Additional model for gunslinger arm (MODEL_ARMS_ROBOTARM)
};

ConVar sm_halloween_voodoo_souls;
ConVar sm_halloween_death_tomb;
ConVar sm_halloween_welcome_sounds;
ConVar sm_halloween_round_sounds;
ConVar sm_halloween_pickup_sounds;
ConVar sm_halloween_weapon_spells;
ConVar sm_halloween_cosmetic_spells;
ConVar sm_halloween_eye_projectiles;
ConVar sm_halloween_soundscapes;
ConVar sm_halloween_skyboxes;
ConVar sm_halloween_colorcorrection;
ConVar sm_halloween_modelreplaces;

int g_iTombRef[MAXPLAYERS];

public Plugin myinfo =
{
	name = "[TF2] Halloween",
	author = "Jughead",
	description = "Makes some halloween atmosphere!",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198241665788"
};

public void OnPluginStart()
{
	sm_halloween_voodoo_souls = CreateConVar("sm_halloween_voodoo_souls", "2", "Toggle zombie souls (1: only zombie cosmetic, 2: cosmetic + zombie viewmodel)", _, true, 0.0, true, 2.0);
	sm_halloween_death_tomb = CreateConVar("sm_halloween_death_tomb", "1", "Toggle tombstone on death", _, true, 0.0, true, 1.0);
	sm_halloween_welcome_sounds = CreateConVar("sm_halloween_welcome_sounds", "1", "Toggle halloween join sounds", _, true, 0.0, true, 1.0);
	sm_halloween_round_sounds = CreateConVar("sm_halloween_round_sounds", "1", "Toggle round start/end sounds replacement", _, true, 0.0, true, 1.0);
	sm_halloween_pickup_sounds = CreateConVar("sm_halloween_pickup_sounds", "1", "Toggle health/ammo pickup sounds", _, true, 0.0, true, 1.0);
	sm_halloween_weapon_spells = CreateConVar("sm_halloween_weapon_spells", "1", "Toggle halloween weapon spells", _, true, 0.0, true, 1.0);
	sm_halloween_cosmetic_spells = CreateConVar("sm_halloween_cosmetic_spells", "0", "Toggle halloween random cosmetic spells", _, true, 0.0, true, 1.0);
	sm_halloween_eye_projectiles = CreateConVar("sm_halloween_eye_projectiles", "1", "Toggle eye projectile replacements", _, true, 0.0, true, 1.0);
	sm_halloween_soundscapes = CreateConVar("sm_halloween_soundscapes", "1", "Toggle halloween soundscapes replacement", _, true, 0.0, true, 1.0);
	sm_halloween_skyboxes = CreateConVar("sm_halloween_skyboxes", "1", "Toggle halloween skyboxes replacement", _, true, 0.0, true, 1.0);
	sm_halloween_colorcorrection = CreateConVar("sm_halloween_colorcorrection", "1", "Toggle night color correction", _, true, 0.0, true, 1.0);
	sm_halloween_modelreplaces = CreateConVar("sm_halloween_modelreplaces", "1", "Toggle ammopack/resupply locker model replacements (works only when full moon or halloween)", _, true, 0.0, true, 1.0);

	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerState);
	HookEvent("player_death", Event_PlayerState);
	HookEvent("post_inventory_application", Event_PostInventory);
	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("teamplay_broadcast_audio", Event_BroadcastAudio, EventHookMode_Pre);
	HookEvent("teamplay_point_captured", Event_PointCaptured);

	AutoExecConfig(true);
	AddNormalSoundHook(SoundHook);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			AddHalloweenVision(i);
	}
}

public void OnMapStart()
{
	PrecacheSound(POINT_CAPTURE_SOUND);

	for (int i = 0; i < sizeof(g_sWelcomeSound); i++)
		PrecacheSound(g_sWelcomeSound[i]);

	for (int i = 0; i < sizeof(g_sPickupSound); i++)
		PrecacheSound(g_sPickupSound[i]);

	PrecacheModel(TOMB_MODEL);
	PrecacheModel(PROJECTILE_MODEL);
}

public void OnConfigsExecuted()
{
	if (sm_halloween_soundscapes.BoolValue && !IsHalloweenMap())
		SetSoundscape("Halloween.Inside", "Halloween.Inside");

	if (sm_halloween_colorcorrection.BoolValue)
		AddFileToDownloadsTable(CORRECTION_FILE);

	if (sm_halloween_modelreplaces.BoolValue)
	{
		PrepareModel(MODEL_AMMO_FULL);
		PrepareModel(MODEL_AMMO_MEDIUM);
		PrepareModel(MODEL_AMMO_SMALL);
		PrepareModel(MODEL_RESUPPLY);

		AddFileToDownloadsTable("materials/models/halloween/misc/ammopack/ammo_pack_halloween.vmt");
		AddFileToDownloadsTable("materials/models/halloween/misc/ammopack/ammo_pack_halloween.vtf");
		AddFileToDownloadsTable("materials/models/halloween/misc/ammopack/ammo_pack_halloween_large.vmt");
		AddFileToDownloadsTable("materials/models/halloween/misc/ammopack/ammo_pack_halloween_large.vtf");
		AddFileToDownloadsTable("materials/models/halloween/misc/resupply_locker/locker.vmt");
		AddFileToDownloadsTable("materials/models/halloween/misc/resupply_locker/locker.vtf");
		AddFileToDownloadsTable("materials/models/halloween/misc/resupply_locker/web.vmt");
		AddFileToDownloadsTable("materials/models/halloween/misc/resupply_locker/web.vtf");
	}

	if (sm_halloween_voodoo_souls.IntValue > 1)
	{
		PrepareModel(MODEL_ARMS_ROBOTARM);

		for (int i = 1; i < sizeof(g_sZombieViewmodel); i++)
			PrepareModel(g_sZombieViewmodel[i]);

		AddFileToDownloadsTable("materials/models/halloween/viewmodels/engineer_handl_zombie.vmt");
		AddFileToDownloadsTable("materials/models/halloween/viewmodels/engineer_handl_zombie.vtf");
		AddFileToDownloadsTable("materials/models/halloween/viewmodels/engineer_handr_red_zombie.vmt");
		AddFileToDownloadsTable("materials/models/halloween/viewmodels/engineer_handr_red_zombie.vtf");
	}
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (StrContains(sClassname, "tf_projectile_") == 0 && sm_halloween_eye_projectiles.BoolValue)
		SDKHook(iEntity, SDKHook_SpawnPost, Hook_ProjectileSpawnPost);

	else if (strcmp(sClassname, "team_control_point") == 0 || strcmp(sClassname, "item_teamflag") == 0 || strcmp(sClassname, "passtime_ball") == 0)
		SDKHook(iEntity, SDKHook_SpawnPost, Hook_ObjectiveSpawnPost);

	else if (sm_halloween_modelreplaces.BoolValue)
	{
		if (StrContains(sClassname, "item_ammopack") == 0 || strcmp(sClassname, "tf_ammo_pack") == 0)
			SDKHook(iEntity, SDKHook_SpawnPost, Hook_AmmopackSpawnPost);

		else if (strcmp(sClassname, "prop_dynamic") == 0)
			SDKHook(iEntity, SDKHook_SpawnPost, Hook_PropSpawnPost);
	}
}

public void OnClientPutInServer(int iClient)
{
	AddHalloweenVision(iClient);

	if (sm_halloween_welcome_sounds.BoolValue)
		EmitSoundToClient(iClient, g_sWelcomeSound[GetURandomInt() % sizeof(g_sWelcomeSound)], .volume = 0.7);
}

public void OnClientDisconnect(int iClient)
{
	Tomb_Kill(iClient);
}

public void TF2_OnConditionRemoved(int iClient, TFCond cond)
{
	// For feign death
	if (cond == TFCond_Cloaked)
		RequestFrame(Frame_KillTomb, GetClientUserId(iClient));
}

void Hook_ProjectileSpawnPost(int iEntity)
{
	SetEntProp(iEntity, Prop_Send, "m_nModelIndexOverrides", GetModelIndex(PROJECTILE_MODEL), VISION_MODE_HALLOWEEN);
}

void Hook_ObjectiveSpawnPost(int iEntity)
{
	// Without delay it will error on map load...
	RequestFrame(Frame_ObjectiveSpawnPost, EntIndexToEntRef(iEntity));
}

void Hook_AmmopackSpawnPost(int iEntity)
{
	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	int iModelIndex = 0;
	if (strcmp(sModel, "models/items/ammopack_large.mdl") == 0)
		iModelIndex = GetModelIndex(MODEL_AMMO_FULL);
	else if (strcmp(sModel, "models/items/ammopack_medium.mdl") == 0)
		iModelIndex = GetModelIndex(MODEL_AMMO_MEDIUM);
	else if (strcmp(sModel, "models/items/ammopack_small.mdl") == 0)
		iModelIndex = GetModelIndex(MODEL_AMMO_SMALL);

	SetEntProp(iEntity, Prop_Send, "m_nModelIndexOverrides", iModelIndex, VISION_MODE_HALLOWEEN);
}

void Hook_PropSpawnPost(int iEntity)
{
	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	if (strcmp(sModel, "models/props_gameplay/resupply_locker.mdl") == 0)
		SetEntProp(iEntity, Prop_Send, "m_nModelIndexOverrides", GetModelIndex(MODEL_RESUPPLY), VISION_MODE_HALLOWEEN);
}

void Event_RoundStart(Event event, const char[] sName, bool bDontBroadcast)
{
	static const char sSkyBoxes[][] =
	{
		"sky_halloween",
		"sky_halloween_night_01",
		"sky_harvest_night_01",
		"sky_night_01"
	};

	for (int i = 1; i <= MaxClients; i++)
		Tomb_Kill(i);

	// Make some ambient on non-halloween maps
	if (!IsHalloweenMap())
	{
		if (sm_halloween_skyboxes.BoolValue)
			SetSkyboxTexture(sSkyBoxes[GetURandomInt() % sizeof(sSkyBoxes)]);

		if (sm_halloween_colorcorrection.BoolValue)
			SetCorrection(CORRECTION_FILE);
	}
}

void Event_PlayerState(Event event, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return;

	if (strcmp(sName[7], "spawn") == 0)
	{
		RequestFrame(Frame_KillTomb, GetClientUserId(iClient));
		AddHalloweenVision(iClient);
	}
	else if (sm_halloween_death_tomb.BoolValue)
		g_iTombRef[iClient] = Tomb_Create(iClient);
}

void Event_PostInventory(Event event, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return;

	SetVariantString("randomnum:100");
	AcceptEntityInput(iClient, "AddContext");

	SetVariantString("IsUnicornHead:1");
	AcceptEntityInput(iClient, "AddContext");

	CreateTimer(0.3, Timer_GiveZombieSoul, GetClientUserId(iClient));

	if (sm_halloween_weapon_spells.BoolValue)
	{
		TF2Attrib_SetByDefIndex(iClient, ATTRIB_EXORCISM, 1.0);

		TFClassType nClass = TF2_GetPlayerClass(iClient);
		switch (nClass)
		{
			case TFClass_Pyro, TFClass_Soldier, TFClass_DemoMan:
			{
				int iWeapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
				if (iWeapon > MaxClients)
					TF2Attrib_SetByDefIndex(iWeapon, (nClass == TFClass_Pyro) ? ATTRIB_HALLOWEENFIRE : ATTRIB_PUMPKINBOMBS, 1.0);

				if (nClass == TFClass_DemoMan || nClass == TFClass_Pyro)
				{
					iWeapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
					if (iWeapon > MaxClients)
						TF2Attrib_SetByDefIndex(iWeapon, (nClass == TFClass_Pyro) ? ATTRIB_HALLOWEENFIRE : ATTRIB_PUMPKINBOMBS, 1.0);
				}
			}
			case TFClass_Engineer:
			{
				int iWeapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
				if (iWeapon > MaxClients)
					TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_PUMPKINBOMBS, 1.0);
			}
		}
	}

	if (sm_halloween_cosmetic_spells.BoolValue)
	{
		float flSpell = float(GetURandomInt() % 5);
		int iWearable = MaxClients + 1;
		while ((iWearable = FindEntityByClassname(iWearable, "tf_wearable")) > MaxClients)
		{
			if (GetEntPropEnt(iWearable, Prop_Send, "m_hOwnerEntity") == iClient && !IsWearableWeapon(iWearable))
			{
				int iItemTint = TF2Attrib_HookValueInt(-1, "set_item_tint_rgb", iWearable);
				int iSpellTint = TF2Attrib_HookValueInt(-1, "set_item_tint_rgb_override", iWearable);
				if (iItemTint == -1 && iSpellTint == -1)
					TF2Attrib_SetByName(iWearable, "SPELL: set item tint RGB", flSpell);
			}
		}
	}
}

void Event_ItemPickup(Event event, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return;

	if (sm_halloween_pickup_sounds.BoolValue)
		EmitSoundToClient(iClient, g_sPickupSound[GetURandomInt() % sizeof(g_sPickupSound)], .volume = 0.6);
}

Action Event_BroadcastAudio(Event event, const char[] sName, bool bDontBroadcast)
{
	static const char sRoundStartSound[][] =
	{
		"Quest.DecodeHalloween",
		"Halloween.PlayerEscapedUnderworld",
		"Halloween.EyeballBossEscaped",
		"Halloween.EyeballBossEscapeSoon",
		"Halloween.EyeballBossEscapeImminent",
		"Halloween.spell_skeleton_horde_cast",
		"Halloween.dance_howl",
		"Halloween.hellride"
	};

	if (!sm_halloween_round_sounds.BoolValue)
		return Plugin_Continue;

	char sAudio[PLATFORM_MAX_PATH];
	event.GetString("sound", sAudio, sizeof(sAudio));

	TFTeam nTeam = view_as<TFTeam>(event.GetInt("team"));

	if (strcmp(sAudio, "Game.YourTeamWon") == 0)
	{
		event.SetString("sound", (nTeam == TFTeam_Red) ? "Announcer.Helltower_Hell_Red_Win" : "Announcer.Helltower_Hell_Blue_Win");
		return Plugin_Changed;
	}
	else if (strcmp(sAudio, "Game.YourTeamLost") == 0)
	{
		event.SetString("sound", (nTeam == TFTeam_Red) ? "Announcer.Helltower_Hell_Red_Lose" : "Announcer.Helltower_Hell_Blue_Lose");
		return Plugin_Changed;
	}
	else if (strcmp(sAudio, "Game.Stalemate") == 0)
	{
		event.SetString("sound", (nTeam == TFTeam_Red) ? "Announcer.Helltower_Hell_Red_Stalemate" : "Announcer.Helltower_Hell_Blue_Stalemate");
		return Plugin_Changed;
	}
	else if (StrContains(sAudio, "RoundStart") != -1)
	{
		event.SetString("sound", sRoundStartSound[GetURandomInt() % sizeof(sRoundStartSound)]);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

void Event_PointCaptured(Event event, const char[] sName, bool bDontBroadcast)
{
	EmitSoundToAll(POINT_CAPTURE_SOUND, .volume = 0.7);

	int iPoint = GetControlPointByIndex(event.GetInt("cp"));
	if (iPoint > MaxClients && !(GetEntProp(iPoint, Prop_Send, "m_fEffects") & EF_NODRAW))
		CreateTempParticle("halloween_boss_summon", iPoint);
}

Action SoundHook(int iClients[MAXPLAYERS], int &iNumClients, char sSound[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags, char sSoundEntry[PLATFORM_MAX_PATH], int &iSeed)
{
	if (strcmp(sSound, "player/sprayer.wav", false) == 0)
	{
		EmitGameSoundToAll("Halloween.GhostBoo", iEntity);

		flVolume = 0.5;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

Action Timer_GiveZombieSoul(Handle hTimer, int iUserid)
{
	int iClient = GetClientOfUserId(iUserid);
	if (!iClient)
		return Plugin_Handled;

	int iEnabled = sm_halloween_voodoo_souls.IntValue;

	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iClient, Prop_Send, "m_iszCustomModel", sModel, sizeof(sModel));

	if (iEnabled && !sModel[0] && GiveZombieSoul(iClient))
		SetEntProp(iClient, Prop_Send, "m_iPlayerSkinOverride", 1);

	TF2Attrib_SetByName(iClient, "voice pitch scale", (iEnabled && !sModel[0]) ? 0.95 : 1.0);
	SetZombieViewmodel(iClient, iEnabled > 1 && !sModel[0]);
	return Plugin_Handled;
}

bool GiveZombieSoul(int iClient)
{
	static const int iVoodoIndex[TFClassType] = { -1, 5617, 5625, 5618, 5620, 5622, 5619, 5624, 5623, 5621 };

	static Handle hEquipWearable;
	if (!hEquipWearable)
	{
		GameData hGameData = new GameData("sm-tf2.games");
		if (!hGameData)
			SetFailState("Could not find sm-tf2.games gamedata!");

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetVirtual(hGameData.GetOffset("RemoveWearable") - 1); // EquipWearable is lower than RemoveWearable by 1
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		hEquipWearable = EndPrepSDKCall();

		delete hGameData;
	}

	// Invalid call or client already has a soul
	if (!hEquipWearable || TF2Attrib_HookValueInt(0, "zombiezombiezombiezombie", iClient))
		return false;

	int iWearable = CreateEntityByName("tf_wearable");

	SetEntProp(iWearable, Prop_Send, "m_iItemDefinitionIndex", iVoodoIndex[TF2_GetPlayerClass(iClient)]);
	SetEntProp(iWearable, Prop_Send, "m_bInitialized", true);
	SetEntData(iWearable, FindSendPropInfo("CTFWearable", "m_iEntityQuality"), 13); // Haunted
	SetEntData(iWearable, FindSendPropInfo("CTFWearable", "m_iEntityLevel"), 1);
	DispatchSpawn(iWearable);

	SetEntProp(iWearable, Prop_Send, "m_bValidatedAttachedEntity", true);
	SDKCall(hEquipWearable, iClient, iWearable);
	return true;
}

void SetZombieViewmodel(int iClient, bool bState)
{
	TFClassType nClass = TF2_GetPlayerClass(iClient);

	int iWeapon, iModelIndex, iRobotArm = TF2Attrib_HookValueInt(0, "wrench_builds_minisentry", iClient);
	for (int i = TFWeaponSlot_Primary; i <= TFWeaponSlot_PDA; i++)
	{
		if ((i > TFWeaponSlot_Melee) && nClass == TFClass_Spy) iModelIndex = 0;
		else if (iRobotArm) iModelIndex = GetModelIndex(MODEL_ARMS_ROBOTARM);
		else iModelIndex = GetModelIndex(g_sZombieViewmodel[nClass]);

		iWeapon = GetPlayerWeaponSlot(iClient, i);
		if (iWeapon > MaxClients)
			SetEntProp(iWeapon, Prop_Send, "m_nCustomViewmodelModelIndex", bState ? iModelIndex : 0);
	}
}

int Tomb_Create(int iClient)
{
	int iRef = INVALID_ENT_REFERENCE;

	float vecStartOrigin[3], vecEndOrigin[3];
	GetClientEyePosition(iClient, vecStartOrigin);

	Handle hTrace = TR_TraceRayFilterEx(vecStartOrigin, {90.0, 0.0, 0.0}, CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE, RayType_Infinite, TraceFilter_WorldOnly);
	if (TR_DidHit(hTrace))
	{
		TR_GetEndPosition(vecEndOrigin, hTrace);

		if (GetVectorDistance(vecStartOrigin, vecEndOrigin) < 1024.0)
		{
			float vecNormal[3], vecNormalAng[3], vecAngles[3];
			TR_GetPlaneNormal(hTrace, vecNormal);
			GetVectorAngles(vecNormal, vecNormalAng);
			GetClientEyeAngles(iClient, vecAngles);

			vecEndOrigin[0] -= vecNormal[0] * 2.0;
			vecEndOrigin[1] -= vecNormal[1] * 2.0;
			vecEndOrigin[2] -= vecNormal[2] * 2.0;

			vecAngles[0] = vecNormalAng[0] - 270.0;
			if (vecNormalAng[0] != 270.0)
				vecAngles[1] = vecNormalAng[1];

			int iTomb = CreateEntityByName("prop_dynamic");
			DispatchKeyValue(iTomb, "solid", "0");
			DispatchKeyValue(iTomb, "disableshadows", "1");
			DispatchKeyValue(iTomb, "model", TOMB_MODEL);
			DispatchKeyValueFloat(iTomb, "modelscale", TOMB_SCALE);
			DispatchSpawn(iTomb);

			TeleportEntity(iTomb, vecEndOrigin, vecAngles);
			CreateTempParticle((TF2_GetClientTeam(iClient) == TFTeam_Red) ? TOMB_PARTICLE_RED : TOMB_PARTICLE_BLUE, iTomb);

			iRef = EntIndexToEntRef(iTomb);
		}
	}

	delete hTrace;
	return iRef;
}

bool TraceFilter_WorldOnly(int iEntity, int iMask)
{
	return (iEntity == 0);
}

void Tomb_Kill(int iClient)
{
	int iTomb = EntRefToEntIndex(g_iTombRef[iClient]);
	if (iTomb > MaxClients)
		RemoveEntity(iTomb);
}

void Frame_ObjectiveSpawnPost(int iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if (!iEntity || GetEntProp(iEntity, Prop_Send, "m_fEffects") & EF_NODRAW)
		return;

	char sClassname[32];
	GetEntityClassname(iEntity, sClassname, sizeof(sClassname));

	if (strcmp(sClassname, "team_control_point") == 0)
	{
		float vecOrigin[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecOrigin);
		CreateParticle("utaunt_hands_purple_parent", vecOrigin);
	}
	else
		CreateTempParticle("ghost_pumpkin_flyingbits", iEntity);
}

void Frame_KillTomb(int iUserid)
{
	int iClient = GetClientOfUserId(iUserid);
	if (!iClient || !IsPlayerAlive(iClient))
		return;

	int iRagdoll = MaxClients + 1;
	while ((iRagdoll = FindEntityByClassname(iRagdoll, "tf_ragdoll")) > MaxClients)
	{
		if (GetEntPropEnt(iRagdoll, Prop_Send, "m_hPlayer") == iClient)
			RemoveEntity(iRagdoll);
	}

	Tomb_Kill(iClient);
}

void CreateTempParticle(const char[] sParticle, int iEntity)
{
	static int iTable = INVALID_STRING_TABLE;
	if (iTable == INVALID_STRING_TABLE)
		iTable = FindStringTable("ParticleEffectNames");

	TE_Start("TFParticleEffect");
	TE_WriteNum("m_iParticleSystemIndex", FindStringIndex(iTable, sParticle));
	TE_WriteNum("entindex", iEntity);
	TE_WriteNum("m_bResetParticles", true);
	TE_SendToAll();
}

int CreateParticle(const char[] sParticle, const float vecOrigin[3])
{
	int iParticle = CreateEntityByName("info_particle_system");

	DispatchKeyValue(iParticle, "effect_name", sParticle);
	DispatchKeyValueVector(iParticle, "origin", vecOrigin);
	DispatchSpawn(iParticle);

	ActivateEntity(iParticle);
	AcceptEntityInput(iParticle, "Start");
	return EntIndexToEntRef(iParticle);
}

void AddHalloweenVision(int iClient)
{
	int iVal = TF2Attrib_HookValueInt(0, "vision_opt_in_flags", iClient);
	TF2Attrib_SetByName(iClient, "vision opt in flags", float(iVal | TF_VISION_FILTER_HALLOWEEN));
}

bool IsWearableWeapon(int iWearable)
{
	switch (GetEntProp(iWearable, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 133, 231, 405, 444, 608, 642:
			return true;
	}

	return false;
}

void SetSoundscape(const char[] sInside, const char[] sOutside)
{
	int iEntity = -1, iProxy = -1, iScape = -1;

	float vecOrigin[3];
	char sTargetName[32];

	while ((iEntity = FindEntityByClassname(iEntity, "env_soundscape_proxy")) != -1)
	{
		iProxy = GetEntDataEnt2(iEntity, FindDataMapInfo(iEntity, "m_hProxySoundscape"));
		if (iProxy == -1)
			continue;

		GetEntPropString(iProxy, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
		if ((StrContains(sTargetName, "inside", false) != -1) || (StrContains(sTargetName, "indoor", false) != -1) || (StrContains(sTargetName, "outside", false) != -1) || (StrContains(sTargetName, "outdoor", false) != -1))
		{
			iScape = CreateEntityByName("env_soundscape");

			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vecOrigin);
			TeleportEntity(iScape, vecOrigin);

			DispatchKeyValueFloat(iScape, "radius", GetEntDataFloat(iEntity, FindDataMapInfo(iEntity, "m_flRadius")));

			if ((StrContains(sTargetName, "inside", false) != -1) || (StrContains(sTargetName, "indoor", false) != -1))
			{
				DispatchKeyValue(iScape, "soundscape", sInside);
				DispatchKeyValue(iScape, "targetname", sInside);
			}
			else if ((StrContains(sTargetName, "outside", false) != -1) || (StrContains(sTargetName, "outdoor", false) != -1))
			{
				DispatchKeyValue(iScape, "soundscape", sOutside);
				DispatchKeyValue(iScape, "targetname", sOutside);
			}

			DispatchSpawn(iScape);
		}

		AcceptEntityInput(iEntity, "Kill");
	}

	while ((iEntity = FindEntityByClassname(iEntity, "env_soundscape")) != -1)
	{
		GetEntPropString(iEntity, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
		if (strcmp(sTargetName, sInside) == 0 || strcmp(sTargetName, sOutside) == 0)
			continue;

		iScape = CreateEntityByName("env_soundscape");

		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vecOrigin);
		TeleportEntity(iScape, vecOrigin);

		DispatchKeyValueFloat(iScape, "radius", GetEntDataFloat(iEntity, FindDataMapInfo(iEntity, "m_flRadius")));

		if ((StrContains(sTargetName, "inside", false) != -1) || (StrContains(sTargetName, "indoor", false) != -1))
		{
			DispatchKeyValue(iScape, "soundscape", sInside);
			DispatchKeyValue(iScape, "targetname", sInside);
		}
		else
		{
			DispatchKeyValue(iScape, "soundscape", sOutside);
			DispatchKeyValue(iScape, "targetname", sOutside);
		}

		DispatchSpawn(iScape);
		AcceptEntityInput(iEntity, "Kill");
	}
}

void SetSkyboxTexture(const char[] sSkyName)
{
	char sCode[64];
	Format(sCode, sizeof(sCode), "SetSkyboxTexture(`%s`)", sSkyName);

	SetVariantString(sCode);
	AcceptEntityInput(0, "RunScriptCode");
}

void SetCorrection(const char[] sFile)
{
	int iCorrection = CreateEntityByName("color_correction");

	DispatchKeyValue(iCorrection, "maxweight", "1.0");
	DispatchKeyValue(iCorrection, "maxfalloff", "-1");
	DispatchKeyValue(iCorrection, "minfalloff", "0.0");
	DispatchKeyValue(iCorrection, "filename", sFile);

	DispatchSpawn(iCorrection);
	ActivateEntity(iCorrection);
	AcceptEntityInput(iCorrection, "Enable");
}

int GetModelIndex(const char[] sModel)
{
	int iTable = FindStringTable("modelprecache");
	return FindStringIndex(iTable, sModel);
}

int GetControlPointByIndex(int iIndex)
{
	int iEntity = MaxClients + 1;
	while ((iEntity = FindEntityByClassname(iEntity, "team_control_point")) > MaxClients)
	{
		if (GetEntProp(iEntity, Prop_Data, "m_iPointIndex") == iIndex)
			return iEntity;
	}

	return -1;
}

void PrepareModel(const char[] sModel)
{
	static const char sFileType[][] = { "dx80.vtx", "dx90.vtx", "mdl", "phy", "sw.vtx", "vvd" };

	char sRoot[PLATFORM_MAX_PATH], sBuffer[PLATFORM_MAX_PATH];
	strcopy(sRoot, sizeof(sRoot), sModel);
	ReplaceString(sRoot, sizeof(sRoot), ".mdl", "");

	for (int i = 0; i < sizeof(sFileType); i++)
	{
		Format(sBuffer, sizeof(sBuffer), "%s.%s", sRoot, sFileType[i]);
		if (FileExists(sBuffer))
			AddFileToDownloadsTable(sBuffer);
	}

	PrecacheModel(sModel);
}

bool IsHalloweenMap()
{
	TFHoliday nHoliday = view_as<TFHoliday>(GameRules_GetProp("m_nMapHolidayType"));
	return (nHoliday == TFHoliday_Halloween);
}