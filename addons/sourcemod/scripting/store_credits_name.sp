#pragma semicolon 1


#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "1.0.1"

#include <sourcemod>
#include <sdktools>
#include <store>
#include <multicolors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Store Credits - Name",
	author = PLUGIN_AUTHOR,
	description = "Gives the clients with a special tag in the name extra credits",
	version = PLUGIN_VERSION,
	url = "painlessgaming.eu"
};

bool g_bHasTag[MAXPLAYERS + 1] =  { false, ... };

Handle g_hTimer[MAXPLAYERS + 1] =  { INVALID_HANDLE, ... };

ConVar g_cTime;
ConVar g_cCredits;
ConVar g_cMessage;
ConVar g_cTag;

public void OnPluginStart()
{	
	g_cTime = CreateConVar("store_credits_name_time", "60.0", "After how much time should they recieve the credits");
	g_cCredits = CreateConVar("store_credits_name_credits", "1", "How much credits should they recieve");
	g_cMessage = CreateConVar("store_credits_name_messages", "1", "Display a message when a client recieves credits");
	g_cTag = CreateConVar("store_credits_name_tag", "painlessgaming.eu", "The tag the user should have in the name");
	
	HookEvent("player_changename", Event_ChangeName);
	
	AutoExecConfig(true);

	LoadTranslations("store_credits_name.phrases");
}

public void OnClientPostAdminCheck(int client)
{
	if(IsValidClient(client))
	{
		if(g_hTimer[client] != INVALID_HANDLE)
			KillTimer(g_hTimer[client]);
		
		g_hTimer[client] = CreateTimer(g_cTime.FloatValue, Timer_Callback, GetClientUserId(client), TIMER_REPEAT);
		
		g_bHasTag[client] = false;
		char buffer[128];
		g_cTag.GetString(buffer, sizeof(buffer));
		
		char name[128];
		if(!GetClientName(client, name, sizeof(name)))
			return;
		if(StrContains(name, buffer, true) != -1)
			g_bHasTag[client] = true;
	}
}

public Action Timer_Callback(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client))
	{
		g_hTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	if(g_bHasTag[client])
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) + g_cCredits.IntValue);
		if(g_cMessage.BoolValue)
			CPrintToChat(client, "%T", "Recieved Credits", client, g_cCredits.IntValue);
		char Path[526];
		BuildPath(Path_SM, Path, sizeof(Path), "logs/store_name.txt");
		LogToFile(Path, "%L recieved %d credits for having the tag in his name.", client, g_cCredits.IntValue);
	}
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	g_bHasTag[client] = false;
	if(g_hTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimer[client]);
		g_hTimer[client] = INVALID_HANDLE;
	}
}

public bool IsValidClient(int client)
{	
	return (0 < client <= MaxClients && IsClientInGame(client));
}

public Action Event_ChangeName(Handle event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
		return;
	
	g_bHasTag[client] = false;
	char buffer[128];
	g_cTag.GetString(buffer, sizeof(buffer));
	
	char sName[128];
	GetEventString(event, "newname", sName, sizeof(sName));
	if(StrContains(sName, buffer, true) != -1)
		g_bHasTag[client] = true;
}
