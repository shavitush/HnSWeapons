#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1

#pragma newdecls required

#define PLUGIN_VERSION "1.4.0"

ConVar gCV_Enabled = null;
ConVar gCV_Buyzones = null;
ConVar gCV_RestrictCT = null;
ConVar gCV_RestrictT = null;

public Plugin myinfo = 
{
	name = "HnS Weapons",
	author = "shavit",
	description = "Players shouldn't have weapons in CS 1.6 HnS style.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/member.php?u=163134"
}

public void OnPluginStart()
{
	CreateConVar("sm_hnsweapons_version", PLUGIN_VERSION, "Plugin version.", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	gCV_Enabled = CreateConVar("sm_hnsweapons_enabled", "1", "Enable the plugin?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gCV_Buyzones = CreateConVar("sm_hnsweapons_buyzones", "1", "Should the plugin disable all the buyzones?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gCV_RestrictCT = CreateConVar("sm_hnsweapons_ct", "1", "Should the plugin restrict the Counter-Terrorists from using any weapon but knife?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gCV_RestrictT = CreateConVar("sm_hnsweapons_t", "1", "Should the plugin restrict the Terrorists from using any weapon but knife and grenades?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "hnsweapons");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	SDKHook(client, SDKHook_PostThinkPost, PostThinkPost);
}

public void PostThinkPost(int client)  
{
	if(gCV_Enabled.BoolValue && gCV_Buyzones.BoolValue)
	{
		SetEntProp(client, Prop_Send, "m_bInBuyZone", 0);
	}
}

public Action WeaponCanUse(int client, int weapon)
{
	if(!gCV_Enabled.BoolValue || !IsValidClient(client, true))
	{
		return Plugin_Continue;
	}
	
	char sWeapon[64];
	GetEntityClassname(weapon, sWeapon, 64);
	
	int iTeam = GetClientTeam(client);
	
	if(gCV_RestrictCT.BoolValue && iTeam == 3)
	{
		if(!StrEqual(sWeapon, "weapon_knife"))
		{
			return Plugin_Handled;
		}
	}
	
	else if(gCV_RestrictT.BoolValue && iTeam == 2)
	{
		if(!StrEqual(sWeapon, "weapon_knife") && StrContains(sWeapon, "grenade", false) == -1 && StrContains(sWeapon, "flash", false) == -1)
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (!bAlive || IsPlayerAlive(client)));
}
