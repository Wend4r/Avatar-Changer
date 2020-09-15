#pragma semicolon 1

#include <sourcemod>
#include <PTaH>

#pragma newdecls required

#if !defined SPPP_COMPILER
	#define decl static
#endif

int       g_iAllPlayersAvatarIndex = -1,
          g_iPlayerAvatarIndex[MAXPLAYERS + 1] = {-1, ...};

char      g_sAvatarContentBuffer[PTaH_AVATAR_SIZE];

ArrayList g_hAvatarFileContent;

StringMap g_hAvatarSteamIDs,
          g_hAvatarFileNames;

public Plugin myinfo =
{
	name = "Avatar Changer",
	author = "Wend4r",
	version = "1.0 Beta 1",
	url = "Discord: Wend4r#0001 | VK: vk.com/wend4r"
};

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] sError, int iErrorSize)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		strcopy(sError, iErrorSize, "This plugin works only on CS:GO.");

		return APLRes_SilentFailure;
	}

	CreateNative("SetPlayerAvatar", SetPlayerAvatar);
	CreateNative("SetPlayerAvatarFromFile", SetPlayerAvatarFromFile);
	CreateNative("GetPlayerAvatar", GetPlayerAvatar);
	CreateNative("LoadAvatarFromFile", LoadAvatarFromFile);
	CreateNative("RefreshAvatarFileCache", RefreshAvatarFileCache);

	RegPluginLibrary("avatar_changer");

	return APLRes_Success;
}

int SetPlayerAvatar(Handle hPlugin, int iArgs)
{
	int iClient = GetNativeCell(1);

	if(g_iPlayerAvatarIndex[iClient] == -1 || GetNativeCell(3))
	{
		GetNativeString(2, g_sAvatarContentBuffer, sizeof(g_sAvatarContentBuffer));

		SetPlayerAvatarForAllFromIndex(iClient, g_hAvatarFileContent.PushString(g_sAvatarContentBuffer));
	}

	return true;
}

int SetPlayerAvatarFromFile(Handle hPlugin, int iArgs)
{
	decl int iAvatarIndex;

	int iClient = GetNativeCell(1);

	if(g_iPlayerAvatarIndex[iClient] == -1 || GetNativeCell(3))
	{
		decl char sAvatarFile[PLATFORM_MAX_PATH];

		GetNativeString(2, sAvatarFile, sizeof(sAvatarFile));

		if(!g_hAvatarFileNames.GetValue(sAvatarFile, iAvatarIndex))
		{
			if(LoadAvatarFile(sAvatarFile, g_sAvatarContentBuffer))
			{
				iAvatarIndex = g_hAvatarFileContent.PushString(g_sAvatarContentBuffer);
			}
			else
			{
				return false;
			}

			g_hAvatarFileNames.SetValue(sAvatarFile, iAvatarIndex);
		}

		SetPlayerAvatarForAllFromIndex(iClient, iAvatarIndex);
	}

	return true;
}

int GetPlayerAvatar(Handle hPlugin, int iArgs)
{
	int iClient = GetNativeCell(1);

	bool bResult = g_iPlayerAvatarIndex[iClient] != -1 && g_hAvatarFileContent.GetString(g_iPlayerAvatarIndex[iClient], g_sAvatarContentBuffer, sizeof(g_sAvatarContentBuffer));

	if(bResult)
	{
		SetNativeString(2, g_sAvatarContentBuffer, sizeof(g_sAvatarContentBuffer));
	}

	return bResult;
}

int LoadAvatarFromFile(Handle hPlugin, int iArgs)
{
	decl char sFile[PLATFORM_MAX_PATH];

	GetNativeString(1, sFile, sizeof(sFile));

	bool bResult = LoadAvatarFile(sFile, g_sAvatarContentBuffer);

	if(bResult)
	{
		SetNativeString(2, g_sAvatarContentBuffer, sizeof(g_sAvatarContentBuffer));
	}

	return bResult;
}

int RefreshAvatarFileCache(Handle hPlugin, int iArgs)
{
	decl int iAvatarIndex;

	decl char sAvatarFile[PLATFORM_MAX_PATH];

	GetNativeString(1, sAvatarFile, sizeof(sAvatarFile));

	if(LoadAvatarFile(sAvatarFile, g_sAvatarContentBuffer))
	{
		if(g_hAvatarFileNames.GetValue(sAvatarFile, iAvatarIndex))
		{
			g_hAvatarFileContent.SetString(iAvatarIndex, g_sAvatarContentBuffer);
		}
		else
		{
			g_hAvatarFileNames.SetValue(sAvatarFile, g_hAvatarFileContent.PushString(g_sAvatarContentBuffer));
		}
	}
}

public void OnPluginStart()
{
	RegAdminCmd("sm_reload_avatars", OnReloadCommand, ADMFLAG_CONFIG);

	g_hAvatarFileContent = new ArrayList(PTaH_AVATAR_SIZE / 4);

	g_hAvatarSteamIDs = new StringMap();
	g_hAvatarFileNames = new StringMap();
}

Action OnReloadCommand(int iClient, int iArgs)
{
	LoadSettings(true);
}

public void OnMapStart()
{
	LoadSettings(false);
}

void LoadSettings(bool bLoadPlayers)
{
	static char sPath[PLATFORM_MAX_PATH];

	static SMCParser hParser = null;

	if(hParser)
	{
		g_hAvatarFileContent.Clear();
		g_hAvatarSteamIDs.Clear();
		g_hAvatarFileNames.Clear();
	}
	else
	{
		(hParser = new SMCParser()).OnKeyValue = OnSettingsKeyValue;

		BuildPath(Path_SM, sPath, sizeof(sPath), "configs/avatars.ini");
	}

	SMCParseFile(hParser, sPath);
}

void SMCParseFile(SMCParser hParser, const char[] sPath)		// I also use it in other plugins :P.
{
	decl int iLine, iColumn;

	SMCError iError = hParser.ParseFile(sPath, iLine, iColumn);

	if(iError != SMCError_Okay)
	{
		decl char sError[64];

		SMC_GetErrorString(iError, sError, sizeof(sError));
		LogError("[SM] Fatal error encountered parsing configuration file \"%s\"", sPath);
		LogError("[SM] Error (line %d, column %d) %s", iLine, iColumn, sError);
	}
}

SMCResult OnSettingsKeyValue(SMCParser hParser, const char[] sSteamID, const char[] sFileName, bool bIsKeyQuotes, bool bIsValueQuotes)
{
	decl int iAvatarIndex;

	if(!g_hAvatarFileNames.GetValue(sFileName, iAvatarIndex))
	{
		if(LoadAvatarFile(sFileName, g_sAvatarContentBuffer))
		{
			iAvatarIndex = g_hAvatarFileContent.PushString(g_sAvatarContentBuffer);
		}
		else
		{
			return SMCParse_Continue;		// But better SMCParse_Halt.
		}
	}

	if(strcmp(sSteamID, "ALL", false))		// sSteamID != "ALL"
	{
		g_hAvatarSteamIDs.SetValue(sSteamID, iAvatarIndex);
	}
	else
	{
		g_iAllPlayersAvatarIndex = iAvatarIndex;
	}

	// iAvatarIndex dependent on
	// g_hAvatarFileNames.GetValue() and g_hAvatarFileContent.PushString()
	g_hAvatarFileNames.SetValue(sFileName, iAvatarIndex);

	return SMCParse_Continue;
}

bool LoadAvatarFile(const char[] sFile, char sAvatarContent[PTaH_AVATAR_SIZE])
{
	bool bState = false;

	File hFile = OpenFile(sFile, "rb");

	if(hFile)
	{
		hFile.Seek(0, SEEK_END);

		if(hFile.Position == PTaH_AVATAR_SIZE)
		{
			hFile.Seek(0, SEEK_SET);

			decl int iUint8;

			int i = 0;

			while(hFile.ReadUint8(iUint8))
			{
				sAvatarContent[i++] = iUint8;
			}

			bState = true;
		}
		else
		{
			LogError("\"%s\" - avatar file size is invalid", sFile);
		}

		hFile.Close();
	}
	else
	{
		LogError("\"%s\" - avatar file couldn't open", sFile);
	}

	return bState;
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if(strcmp(sAuth, "BOT"))		// aka !IsFakeClient(iClient)
	{
		decl int iAvatarIndex;

		if(g_hAvatarSteamIDs.GetValue(sAuth, iAvatarIndex) || (iAvatarIndex = g_iAllPlayersAvatarIndex) != -1)
		{
			SetPlayerAvatarForAllFromIndex(iClient, iAvatarIndex);
		}
	}
}

void SetPlayerAvatarForAllFromIndex(int iClient, int iAvatarIndex)
{
	int   iTargetsCount = 0;

	int[] iTargets = new int[MaxClients];		// We won't have GOTV.

	for(int i = MaxClients + 1; --i;)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			iTargets[iTargetsCount++] = i;
		}
	}

	if(g_hAvatarFileContent.GetString(iAvatarIndex, g_sAvatarContentBuffer, sizeof(g_sAvatarContentBuffer)))
	{
		g_iPlayerAvatarIndex[iClient] = iAvatarIndex;
		PTaH_SetPlayerAvatar(iClient, iTargets, iTargetsCount, g_sAvatarContentBuffer);
	}
}

public void OnClientConnected(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		decl int iTargets[1];

		iTargets[0] = iClient;

		for(int i = MaxClients + 1; --i;)
		{
			if(g_iPlayerAvatarIndex[i] != -1 && g_hAvatarFileContent.GetString(g_iPlayerAvatarIndex[i], g_sAvatarContentBuffer, sizeof(g_sAvatarContentBuffer)))
			{
				PTaH_SetPlayerAvatar(i, iTargets, sizeof(iTargets), g_sAvatarContentBuffer);
			}
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	g_iPlayerAvatarIndex[iClient] = -1;
}