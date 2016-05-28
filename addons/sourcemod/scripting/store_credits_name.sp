#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "1.00"

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

ConVar g_cTime;
ConVar g_cCredits;
ConVar g_cMessage;
ConVar g_cTag;

public void OnPluginStart()
{	
	g_cTime = CreateConVar("store_credits_name_time", "1.0", "After which should they recieve the credits");
	g_cCredits = CreateConVar("store_credits_name_credits", "1", "How much credits should the recieve");
	g_cMessage = CreateConVar("store_credits_name_messages", "1", "Display a message when a client recieves credits");
	g_cTag = CreateConVar("store_credits_name_tag", "painlessgaming.eu", "The tag the user should have in the name");
	
	AutoExecConfig(true);
	CreateTimer(g_cTime.FloatValue, Timer_Callback, TIMER_REPEAT);
	LoadTranslations("store_credits_name.phrases");
}

public Action Timer_Callback(Handle timer, any userid)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && g_bHasTag[i])
		{
			Store_SetClientCredits(i, Store_GetClientCredits(i) + g_cCredits.IntValue);
			if(g_cMessage.BoolValue)
				CPrintToChat(i, "%T", "Recieved Credits", i, g_cCredits.IntValue);
		}
	}
}

public void OnClientPutInServer(int client)
{
	char buffer[MAX_NAME_LENGTH];
	g_cTag.GetString(buffer, sizeof(buffer));
	
	char name[MAX_NAME_LENGTH];
	if(!GetClientName(client, name, sizeof(name)))
		return;
	
	if(strcmp(name, buffer, false) != -1)
		g_bHasTag[client] = true;
}

public void OnClientDisconnect(int client)
{
	g_bHasTag[client] = false;
}

public bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return false;
	
	return true;
}