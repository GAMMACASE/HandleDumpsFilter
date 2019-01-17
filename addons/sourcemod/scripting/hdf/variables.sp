enum Args_e (<<= 1)
{
	Args_None = 0,
	Args_SaveDump = 1,
	Args_SaveOutPut,
	Args_Compare,
	Args_Destination,
	Args_Sort,
	Args_MemType
}

enum SortField
{
	Sort_PluginNames = 0,
	Sort_HandleNames = 1, 
	Sort_Handles,
	Sort_Memory
}

enum MemoryType
{
	MemType_Default = -1,
	MemType_KB = 0,
	MemType_MB = 1,
	MemType_GB
}

enum ARG_PARSE
{
	ARG_PARSE_FAILED_SILENT = -2,
	ARG_PARSE_FAILED = -1,
	ARG_PARSE_OK = 0,
	ARG_PARSE_HELP,
	ARG_PARSE_SKIPNEXT
}

Args_e g_eargs;
char g_sDistPath[PLATFORM_MAX_PATH],
	g_sComparePath[PLATFORM_MAX_PATH],
	g_sOutputPath[PLATFORM_MAX_PATH],
	g_sLastSaved[PLATFORM_MAX_PATH],
	g_sLastCreated[PLATFORM_MAX_PATH];
SortOrder g_sortorder;
SortField g_sortfield;
MemoryType g_memtype;
ConVar g_cvMainFolder,
	g_cvSaveFolder,
	g_cvDumpsAmount,
	g_cvDumpsPrefix,
	g_cvDumpTimeout,
	g_cvLogErrors;
int g_clientUserId;
bool g_bisNewSM;