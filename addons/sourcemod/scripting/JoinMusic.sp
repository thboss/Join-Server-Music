#include <sdktools>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Join Music",
	author = "TheBO$$",
	description = "Join server music",
	version = "1.0"
	url = "TheBΦ$$♚#2967"
};

Handle g_JM_Cookie = null;
Handle g_JM_Volume_Cookie = null;

public void OnPluginStart()
{

	g_JM_Cookie = RegClientCookie("join_server_music", "Join Music On/Off", CookieAccess_Private);
	g_JM_Volume_Cookie = RegClientCookie("join_music_volume", "join Music volume", CookieAccess_Private);
	
	SetCookieMenuItem(SoundCookieHandler, 0, "Join Server Music");

	RegConsoleCmd("sm_joinmusic", Command_JoinMusic);
	
	LoadTranslations("joinmusic.phrases.txt");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			if(!AreClientCookiesCached(i))
			{
				continue;
			}
			OnClientCookiesCached(i);
		}	
	}	
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/admin_plugin/actions/privet.mp3");

	if (!PrecacheSound("admin_plugin/actions/privet.mp3"))
	{
		return;
	}	
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}

	GetIntCookie(client, g_JM_Cookie);
	GetIntCookie(client, g_JM_Volume_Cookie);
}

public void OnClientPostAdminCheck(int client)
{
    if (IsFakeClient(client))
	{
		return;
	}

	if (GetIntCookie(client, g_JM_Cookie) == 0)
	{
		float selectedVolume = GetClientVolume(client);
		EmitSoundToClient(client, "admin_plugin/actions/privet.mp3", _, _, _, _, selectedVolume);
	}
}

public Action Command_JoinMusic(int client, int args)
{
    if (!IsClientValid(client))
    {
        return Plugin_Handled;
    }

    JoinMusicMenu(client, 0);

    return Plugin_Handled;
}

public void SoundCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	JoinMusicMenu(client, 0);
}

public Action JoinMusicMenu(int client, int args)
{	
	int cookievalue = GetIntCookie(client, g_JM_Cookie);
	Handle g_CookieMenu = CreateMenu(JoinMusicMenuHandler);
	SetMenuTitle(g_CookieMenu, "Join Server Music");
	char Item[128];
	if(cookievalue == 0)
	{
		Format(Item, sizeof(Item), "%t %t", "JOINMUSIC_ON", "SELECTED"); 
		AddMenuItem(g_CookieMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t", "JOINMUSIC_OFF"); 
		AddMenuItem(g_CookieMenu, "OFF", Item);
	}
	else
	{
		Format(Item, sizeof(Item), "%t", "JOINMUSIC_ON");
		AddMenuItem(g_CookieMenu, "ON", Item);
		Format(Item, sizeof(Item), "%t %t", "JOINMUSIC_OFF", "SELECTED"); 
		AddMenuItem(g_CookieMenu, "OFF", Item);
	}

	Format(Item, sizeof(Item), "%t", "VOLUME");
	AddMenuItem(g_CookieMenu, "volume", Item);


	SetMenuExitBackButton(g_CookieMenu, true);
	SetMenuExitButton(g_CookieMenu, true);
	DisplayMenu(g_CookieMenu, client, 30);
	return Plugin_Continue;
}

public int JoinMusicMenuHandler(Handle menu, MenuAction action, int client, int param2)
{
	Handle g_CookieMenu = CreateMenu(JoinMusicMenuHandler);
	if (action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		ShowCookieMenu(client);
	}
	else if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				SetClientCookie(client, g_JM_Cookie, "0");
				JoinMusicMenu(client, 0);
			}
			case 1:
			{
				SetClientCookie(client, g_JM_Cookie, "1");
				JoinMusicMenu(client, 0);
			}
			case 2: 
			{
				VolumeMenu(client);
			}			
		}
		CloseHandle(g_CookieMenu);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void VolumeMenu(int client){
	

	float volumeArray[] = { 1.0, 0.75, 0.50, 0.25, 0.10 };
	float selectedVolume = GetClientVolume(client);

	Menu volumeMenu = new Menu(VolumeMenuHandler);
	volumeMenu.SetTitle("%t", "JMVOLUME");
	volumeMenu.ExitBackButton = true;

	for(int i = 0; i < sizeof(volumeArray); i++)
	{
		char strInfo[10];
		Format(strInfo, sizeof(strInfo), "%0.2f", volumeArray[i]);

		char display[20], selected[5];
		if(volumeArray[i] == selectedVolume)
			Format(selected, sizeof(selected), "%t", "SELECTED");

		Format(display, sizeof(display), "%s %s", strInfo, selected);

		volumeMenu.AddItem(strInfo, display);
	}

	volumeMenu.Display(client, MENU_TIME_FOREVER);
}

public int VolumeMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select){
		char sInfo[10];
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
		SetClientCookie(client, g_JM_Volume_Cookie, sInfo);
		VolumeMenu(client);
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		JoinMusicMenu(client, 0);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

int GetIntCookie(int client, Handle handle)
{
	char sCookieValue[11];
	GetClientCookie(client, handle, sCookieValue, sizeof(sCookieValue));
	return StringToInt(sCookieValue);
}

float GetClientVolume(int client){
	float defaultVolume = 0.75;

	char sCookieValue[11];
	GetClientCookie(client, g_JM_Volume_Cookie, sCookieValue, sizeof(sCookieValue));

	if(StrEqual(sCookieValue, "") || StrEqual(sCookieValue, "0"))
		Format(sCookieValue , sizeof(sCookieValue), "%0.2f", defaultVolume);

	return StringToFloat(sCookieValue);
}


bool IsClientValid(int client)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		return true;
	return false;
}