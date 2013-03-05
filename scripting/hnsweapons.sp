#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

new Handle:gH_Enabled = INVALID_HANDLE;
new Handle:gH_Buyzones = INVALID_HANDLE;
new Handle:gH_RestrictCT = INVALID_HANDLE;
new Handle:gH_RestrictT = INVALID_HANDLE;

new bool:gB_Enabled;
new bool:gB_Buyzones;
new bool:gB_RestrictCT;
new bool:gB_RestrictT;

new gI_Entity = -1;

public Plugin:myinfo = 
{
	name = "HnS Weapons",
	author = "ml/shavit",
	description = "Players shouldn't have weapons in CS 1.6 HnS style.",
	version = PLUGIN_VERSION,
	url = "not vgames"
}

public OnPluginStart()
{
	CreateConVar("sm_hnsweapons_version", PLUGIN_VERSION, "Plugin version.", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	gH_Enabled = CreateConVar("sm_hnsweapons_enabled", "1", "Enable the plugin?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_Enabled = true;
	
	gH_Buyzones = CreateConVar("sm_hnsweapons_buyzones", "1", "Should the plugin disable all the buyzones?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_Buyzones = true;
	
	gH_RestrictCT = CreateConVar("sm_hnsweapons_ct", "1", "Should the plugin restrict the Counter-Terrorists from using any weapon but knife?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_RestrictCT = true;
	
	gH_RestrictT = CreateConVar("sm_hnsweapons_t", "1", "Should the plugin restrict the Terrorists from using any weapon but knife and grenades?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_RestrictT = true;
	
	HookConVarChange(gH_Enabled, OnConVarChanged);
	HookConVarChange(gH_Buyzones, OnConVarChanged);
	HookConVarChange(gH_RestrictCT, OnConVarChanged);
	HookConVarChange(gH_RestrictT, OnConVarChanged);
	
	HookEvent("round_start", EnableBuyzones);
	HookEvent("round_end", EnableBuyzones);
	
	AutoExecConfig(true, "hnsweapons");
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = bool:StringToInt(newVal);
		
		EnableBuyzones(INVALID_HANDLE, "auto", true);
	}
	
	else if(cvar == gH_Buyzones)
	{
		gB_Buyzones = bool:StringToInt(newVal);
		
		EnableBuyzones(INVALID_HANDLE, "auto", true);
	}
	
	else if(cvar == gH_RestrictCT)
	{
		gB_RestrictCT = bool:StringToInt(newVal);
	}
	
	else if(cvar == gH_RestrictT)
	{
		gB_RestrictT = bool:StringToInt(newVal);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public Action:WeaponCanUse(client, weapon)
{
	if(!gB_Enabled || !IsValidClient(client, true))
	{
		return Plugin_Continue;
	}
	
	decl String:sWeapon[64];
	GetEntityClassname(weapon, sWeapon, 64);
	
	switch(GetClientTeam(client))
	{
		case CS_TEAM_CT:
		{
			if(gB_RestrictCT)
			{
				if(!StrEqual(sWeapon, "weapon_knife"))
				{
					return Plugin_Handled;
				}
			}
		}
		
		case CS_TEAM_T:
		{
			if(gB_RestrictT)
			{
				if(!StrEqual(sWeapon, "weapon_knife") && StrContains(sWeapon, "grenade", false) == -1 && StrContains(sWeapon, "flash", false) == -1)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if(!gB_Enabled)
	{
		return;
	}
	
	if(StrEqual(classname, "func_buyzone"))
	{
		if(!gB_Buyzones)
		{
			AcceptEntityInput(entity, "Disable");
		}
	}
}

public Action:EnableBuyzones(Handle:event, const String:name[], bool:dB)
{
	while((gI_Entity = FindEntityByClassname(gI_Entity, "func_buyzone")) != -1)
	{
		if(gI_Entity != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(gI_Entity, gB_Buyzones? "Enable":"Disable");
		}
	}
	
	return Plugin_Continue;
}

stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (!alive || IsPlayerAlive(client)));
}
