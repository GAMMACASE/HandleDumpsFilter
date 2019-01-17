#include <sourcemod>
#include <regex>
#pragma dynamic 131072

#define SNAME "[HDF]"
#define MAX_ERROR_BUFF 512
#define FILE_BUFFER 131020
#define MAX_READ_BYTES FILE_BUFFER - 1

#define FORMAT_HEADER_MSG "Plugin Name - Handle Type\t\t| Handle count\t\t  | Memory"
#define FORMAT_HEADER_FILE "Plugin Name - Handle Type\t\t\t\t| Handle count\t\t\t  | Memory"
#define FORMAT_RULE_MSG "%s|%s| %s"
#define FORMAT_RULE_FILE "%s|%s| %s"
#define FORMAT_NEWLINE "----------------------------------------------------------------------------------"

#define FORMAT_MAXCHARS_COLUMN1 40 //Max: 64
#define FORMAT_MAXCHARS_COLUMN2 25 //Max: 32

public Plugin myinfo = 
{
	name = "Handle dump filter",
	author = "GAMMA CASE",
	description = "Filters handle dump output file",
	version = "1.0.0",
	url = "https://github.com/GAMMACASE/HandleDumpsFilter"
}

#include "hdf/variables.sp"
#include "hdf/methodmaps.sp"

public void OnPluginStart()
{
	RegConsoleCmd("sm_checkhandles", SM_Checkhandles, "Dump all handles and print info about them, use -h to see full list of available arguments.");
	
	g_cvMainFolder = CreateConVar("hdf_handledumps_folder", "handle_dumps/temp", "Folder where all handle dumps will be stored, path relative to game folder.");
	g_cvSaveFolder = CreateConVar("hdf_handledumps_savefolder", "handle_dumps/save", "Folder where all handle dumps will be stored if -sd param was used.");
	g_cvDumpsAmount = CreateConVar("hdf_handledumps_amount", "3", "Amount of handle dumps stored in the specified folder.", .hasMin = true, .min = 1.0);
	g_cvDumpsPrefix = CreateConVar("hdf_handledumps_fileprefix", "handledump_", "Prefix that will be used for created dumps.");
	g_cvDumpTimeout = CreateConVar("hdf_handledumps_timeout", "1.0", "Time to wait for handle dump to be created.", .hasMin = true, .min = 0.2);
	g_cvLogErrors = CreateConVar("hdf_logerrors", "1", "Log every occurred error?", .hasMin = true, .min = 0.0, .hasMax = true, .max = 1.0);
	
	AutoExecConfig();
	
	ConVar cvSMVer = FindConVar("sourcemod_version");
	
	if(cvSMVer != null)
	{
		char sver[4][8], buff[32];
		int ver[2];
		
		cvSMVer.GetString(buff, sizeof(buff));
		if(ExplodeString(buff, ".", sver, 4, 8) == 4)
		{
			//ver[0] = StringToInt(sver[0]);
			ver[0] = StringToInt(sver[1]);
			//ver[2] = StringToInt(sver[2]);
			ver[1] = StringToInt(sver[3]);
			
			if((ver[0] == 9 && ver[1] >= 6274) || (ver[0] == 10 && ver[1] >= 6378) || ver[0] > 10)
				g_bisNewSM = true;
		}
		
		delete cvSMVer;
	}
}

public Action SM_Checkhandles(int client, int args)
{
	g_clientUserId = client == 0 ? 0 : GetClientUserId(client);
	g_eargs = Args_None;
	g_memtype = MemType_Default;
	char buff[8], buff2[PLATFORM_MAX_PATH];
	for(int i = 1; i <= args; i++)
	{
		GetCmdArg(i, buff, sizeof(buff));
		GetCmdArg(i+1, buff2, sizeof(buff2));
		
		ARG_PARSE arg_parse = Args.ParseArgument(client, buff, sizeof(buff), buff2);
		if(arg_parse == ARG_PARSE_FAILED)
		{
			Log.Error("Wrong argument (%i) was passed \"%s\".", i, buff);
			return Plugin_Handled;
		}
		else if (arg_parse == ARG_PARSE_HELP || arg_parse == ARG_PARSE_FAILED_SILENT)
			return Plugin_Handled;
		else if (arg_parse == ARG_PARSE_SKIPNEXT)
			i++;
	}
	
	char path[PLATFORM_MAX_PATH];
	if (!Dump.GetPath(path, sizeof(path)))
		return Plugin_Handled;
	
	ServerCommand("sm_dump_handles %s", path);
	strcopy(g_sLastCreated, sizeof(g_sLastCreated), path);
	if(g_eargs & Args_SaveDump)
		strcopy(g_sLastSaved, sizeof(g_sLastSaved), path);
	
	DataPack dp;
	CreateDataTimer(g_cvDumpTimeout.FloatValue, Timer_StartAnalyze, dp, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
	dp.WriteString(path);
	
	return Plugin_Handled;
}

public Action Timer_StartAnalyze(Handle timer, DataPack dp)
{
	KeyValues kv;
	ArrayList sortedlist;
	char path[PLATFORM_MAX_PATH];
	dp.Reset();
	dp.ReadString(path, sizeof(path));
	
	if (!Dump.Analyze(path, kv, "Dump1"))
		return Plugin_Continue;
	
	if (g_eargs & Args_Compare)
	{
		if (!FileExists(g_sComparePath, true))
		{
			Log.Error("Compare file does not exist or incorrect file path specified \"%s\".", g_sComparePath);
			delete kv;
			return Plugin_Continue;
		}
		
		if(!Dump.Analyze(g_sComparePath, kv, "Dump2"))
			return Plugin_Continue;
	}
	
	if(g_eargs & Args_Sort)
		Dump.Sort(kv, "Dump1", sortedlist);
	
	if(g_eargs & Args_SaveOutPut)
	{
		File file = OpenFile(g_sOutputPath, "w", true);
		
		if(file == null)
		{
			Log.Error("Wrong or invalid file path specified as an output file \"%s\"!", g_sOutputPath);\
			delete kv;
			delete sortedlist;
			return Plugin_Continue;
		}
		
		if(g_eargs & Args_Compare)
			Dump.Compare(kv, "Dump2", "Dump1", file, sortedlist);
		else
			Dump.PrintInfo(kv, "Dump1", file, sortedlist);
		
		Log.Info(SNAME..." File was successfully created \"%s\"", g_sOutputPath);
		
		delete file;
	}
	else
		if(g_eargs & Args_Compare)
			Dump.Compare(kv, "Dump2", "Dump1", .sortedlist = sortedlist);
		else
			Dump.PrintInfo(kv, "Dump1", .sortedlist = sortedlist);
	
	delete kv;
	delete sortedlist;
	
	return Plugin_Continue;
}

stock void FillString(char[] buff, int length)
{
	int start = strlen(buff);
	for(int i = start; i < length; i++)
		buff[i] = ' ';
	
	buff[length] = '\0';
}