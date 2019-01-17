methodmap Log
{
	public static void Info(char[] text, any ...)
	{
		char buff[MAX_ERROR_BUFF];
		VFormat(buff, sizeof(buff), text, 2);
		
		ReplyToCommand(GetClientOfUserId(g_clientUserId), buff);
	}
	
	public static void Error(char[] text, any ...)
	{
		char buff[MAX_ERROR_BUFF];
		VFormat(buff, sizeof(buff), text, 2);
		Log.Info(SNAME..." %s", buff);
		
		if(g_cvLogErrors.BoolValue)
		{
			FrameIterator fi = new FrameIterator();
			char trace[256], fname[64];
			int counter;
			
			fi.Next();
			
			if(g_bisNewSM)
			{
				while(fi.Next())
				{
					fi.GetFunctionName(fname, sizeof(fname));
					if(fname[0] == '\0')
						continue;
					
					Format(trace, sizeof(trace), "%s%s%s", trace, (!counter ? "" : " <- "), fname);
					
					counter++;
				}
			}
			else
			{
				if(fi.Next())
				{
					fi.GetFunctionName(fname, sizeof(fname));
					strcopy(trace, sizeof(trace), fname);
				}
			}
			
			LogError("[%s] %s", trace, buff);
			
			delete fi;
		}
	}
}

methodmap Args
{
	public static ARG_PARSE ParseSortType(char[] buff)
	{
		char copybuff[8];
		strcopy(copybuff, sizeof(copybuff), buff);
		
		if(copybuff[0] != '+' && copybuff[0] != '-')
			g_sortorder = Sort_Ascending;
		else 
		{
			if (copybuff[0] == '+')
				g_sortorder = Sort_Ascending;
			else
				g_sortorder = Sort_Descending;
			
			strcopy(copybuff, sizeof(copybuff), copybuff[1]);
		}
		
		if(StrEqual(copybuff, "pln"))
		{
			g_sortfield = Sort_PluginNames;
			return ARG_PARSE_OK;
		}
		else if (StrEqual(copybuff, "hn"))
		{
			g_sortfield = Sort_HandleNames;
			return ARG_PARSE_OK;
		}
		else if (StrEqual(copybuff, "h"))
		{
			g_sortfield = Sort_Handles;
			return ARG_PARSE_OK;
		}
		else if (StrEqual(copybuff, "m"))
		{
			g_sortfield = Sort_Memory;
			return ARG_PARSE_OK;
		}
		
		return ARG_PARSE_FAILED;
	}
	
	public static ARG_PARSE ParseMemType(char[] buff)
	{
		if(StrEqual(buff, "kb", false))
		{
			g_memtype = MemType_KB;
			return ARG_PARSE_OK;
		}
		else if (StrEqual(buff, "mb", false))
		{
			g_memtype = MemType_MB;
			return ARG_PARSE_OK;
		}
		else if (StrEqual(buff, "gb", false))
		{
			g_memtype = MemType_GB;
			return ARG_PARSE_OK;
		}
		else
			return ARG_PARSE_FAILED;
	}
	
	public static ARG_PARSE ParseArgument(int client, char[] buff, int length, char[] buff2)
	{
		if(StrEqual(buff, "-h"))
		{
			Log.Info(SNAME..." All available arguments for sm_checkhandles:\n \
			* -h - print help list;\n \
			* -sh - print sort help list;\n \
			* -th - print all available memory output types;\n \
			* -sd - save handle dump under the directory specified in hdf_handledumps_savefolder cvar;\n \
			* -so <path to file> - save output to a specific file;\n \
			* -c <path to file> - compare currect handle dump to another dump; (You can also use words \"lastsaved\" and \"lastcreated\" to get the appropriate files)\n \
			* -d <path to file> - set different path for raw handle dump;\n \
			* -st <sort type> - set custom sort type;\n \
			* -mt <memory type> - set custom memory output type (eg. KB, MB, GB);");
			
			return ARG_PARSE_HELP;
		}
		else if(StrEqual(buff, "-sh"))
		{
			Log.Info(SNAME..." All available sort types:\n \
			* -[SORT_FIELD] - sort in descending order;\n \
			* +[SORT_FIELD] - sort in ascending order;\n \
			* If no order specified, ascending order will be used as default;\n \
			[SORT_FIELDS]:\n \
			* pln - plugin name;\n \
			* hn - handle name;\n \
			* h - handle count;\n \
			* m - memory count;");
			
			return ARG_PARSE_HELP;
		}
		else if(StrEqual(buff, "-th"))
		{
			Log.Info(SNAME..." All available memory output types:\n \
			* kb - KiloByte;\n \
			* mb - MegaByte;\n \
			* gb - GigaByte;");
			
			return ARG_PARSE_HELP;
		}
		else if(StrEqual(buff, "-sd"))
		{
			g_eargs |= Args_SaveDump;
			
			return ARG_PARSE_OK;
		}
		else if(StrEqual(buff, "-so"))
		{
			g_eargs |= Args_SaveOutPut;
			strcopy(g_sOutputPath, sizeof(g_sOutputPath), buff2);
			
			return ARG_PARSE_SKIPNEXT;
		}
		else if(StrEqual(buff, "-c"))
		{
			g_eargs |= Args_Compare;
			
			if(StrEqual(buff2, "lastsaved"))
			{
				if(g_sLastSaved[0] == '\0')
				{
					Log.Error("There's no lastsaved dump.");
					return ARG_PARSE_FAILED_SILENT;
				}
				else
					strcopy(g_sComparePath, sizeof(g_sComparePath), g_sLastSaved);
			}
			else if(StrEqual(buff2, "lastcreated"))
			{
				if(g_sLastCreated[0] == '\0')
				{
					Log.Error("There's no lastcreated dump.");
					return ARG_PARSE_FAILED_SILENT;
				}
				else
					strcopy(g_sComparePath, sizeof(g_sComparePath), g_sLastCreated);
			}
			else
				strcopy(g_sComparePath, sizeof(g_sComparePath), buff2);
			
			return ARG_PARSE_SKIPNEXT;
		}
		else if(StrEqual(buff, "-d"))
		{
			g_eargs |= Args_Destination;
			strcopy(g_sDistPath, sizeof(g_sDistPath), buff2);
			
			return ARG_PARSE_SKIPNEXT;
		}
		else if(StrEqual(buff, "-st"))
		{
			g_eargs |= Args_Sort;
			if(Args.ParseSortType(buff2) == ARG_PARSE_FAILED)
			{
				Log.Error("Invalid sort type specified \"%s\"!", buff2);
				return ARG_PARSE_FAILED_SILENT;
			}
			
			return ARG_PARSE_SKIPNEXT;
		}
		else if(StrEqual(buff, "-mt"))
		{
			g_eargs |= Args_MemType;
			if(Args.ParseMemType(buff2) == ARG_PARSE_FAILED)
			{
				Log.Error("Invalid memory output type specified \"%s\"!", buff2);
				return ARG_PARSE_FAILED_SILENT;
			}
			
			return ARG_PARSE_SKIPNEXT;
		}
		else
			return ARG_PARSE_FAILED;
	}
}

methodmap Dump
{
	public static void FormatMemory(char[] buff, int length, int mem, int memdiff = 0)
	{
		float fbuff;
		
		switch(g_memtype)
		{
			case MemType_KB:
			{
				if(memdiff == 0)
					Format(buff, length, "%.2f KB", float(mem)/1024.0);
				else
				{
					fbuff = float(memdiff)/1024.0;
					Format(buff, length, "%.2f (%s%.2f) KB", float(mem)/1024.0, (fbuff > 0.0 ? "+" : ""), fbuff);
				}
			}
			
			case MemType_MB:
			{
				if(memdiff == 0)
					Format(buff, length, "%.2f MB", float(mem)/1048576.0);
				else
				{
					fbuff = float(memdiff)/1048576.0;
					Format(buff, length, "%.2f (%s%.2f) MB", float(mem)/1048576.0, (fbuff > 0.0 ? "+" : ""), fbuff);
				}
			}
			
			case MemType_GB:
			{
				if(memdiff == 0)
					Format(buff, length, "%.2f GB", float(mem)/1073741824.0);
				else
				{
					fbuff = float(memdiff)/1073741824.0;
					Format(buff, length, "%.2f (%s%.2f) GB", float(mem)/1073741824.0, (fbuff > 0.0 ? "+" : ""), fbuff);
				}
			}
			
			case MemType_Default:
			{
				if(memdiff == 0)
					Format(buff, length, "%i bytes", mem);
				else
					Format(buff, length, "%i (%s%i) bytes", mem, (memdiff > 0 ? "+" : ""), memdiff);
			}
		}
	}
	
	public static bool DeleteOld(char[] path)
	{
		DirectoryListing dir = OpenDirectory(path, true);
		char file[PLATFORM_MAX_PATH];
		FileType type;
		int counter;
		
		if (dir == null)
		{
			Log.Error("Can't open \"%s\" directory.", path);
			return false;
		}
		
		while(dir.GetNext(file, sizeof(file), type))
		{
			if(type != FileType_File)
				continue;
			
			counter++;
		}
		
		delete dir;
		counter -= g_cvDumpsAmount.IntValue - 1;
		
		if(counter > 0)
		{
			dir = OpenDirectory(path, true);
			
			while (counter > 0)
			{
				dir.GetNext(file, sizeof(file), type);
				
				if(type != FileType_File)
					continue;
				
				Format(file, sizeof(file), "%s/%s", path, file);
				DeleteFile(file, true);
				counter--;
			}
		}
		
		delete dir;
		return true;
	}
	
	public static bool FolderExists(char[] path)
	{
		if(!DirExists(path, true))
		{
			CreateDirectory(path, 511, true);
			return false;
		}
		else
			return true;
	}
	
	public static bool GetPath(char[] path, int length)
	{
		char folderpath[PLATFORM_MAX_PATH];
		
		if(g_eargs & Args_Destination)
		{
			File file = OpenFile(g_sDistPath, "w", true);
			
			if(file == null)
			{
				Log.Error("Invalid path was specified for dump destination \"%s\".", g_sDistPath);
				return false;
			}
			
			strcopy(path, length, g_sDistPath);
			
			delete file;
			
			return true;
		}
		else if(g_eargs & Args_SaveDump)
			g_cvSaveFolder.GetString(folderpath, sizeof(folderpath));
		else
			g_cvMainFolder.GetString(folderpath, sizeof(folderpath));
		
		if(Dump.FolderExists(folderpath) && !(g_eargs & Args_SaveDump) && !(g_eargs & Args_Destination))
			if (!Dump.DeleteOld(folderpath))
			{
				Log.Error("Can't delete old dumps, check other error logs for more information.");
				return false;
			}
		
		char fprefix[32];
		g_cvDumpsPrefix.GetString(fprefix, sizeof(fprefix));
		
		int len = strlen(folderpath);
		if(folderpath[len - 1] != '\\' || folderpath[len - 1] != '/')
		{
			if(len + 1 > PLATFORM_MAX_PATH)
			{
				Log.Error("Path buffer exceeded, try to use smaller path for handle dumps.");
				return false;
			}
			
			folderpath[len] = '\\';
			folderpath[len + 1] = '\0';
		}
		
		if(StrContains(fprefix, "\\") != -1 || StrContains(fprefix, "/") != -1)
		{
			Log.Error("Please remove \"\\\" or \"/\" from handle dump prefix cvar.");
			return false;
		}
		
		Format(path, length, "%s%s%i.txt", folderpath, fprefix, GetTime());
		
		File file = OpenFile(path, "w", true);
		
		if(file == null)
		{
			Log.Error("Can't create handle dump, check path \"%s\" for errors and try again.", path);
			return false;
		}
		
		delete file;
		
		return true;
	}
	
	public static void PrintInfo(KeyValues kv, char[] entryName, File file = null, ArrayList sortedlist = null)
	{
		if(kv == null)
		{
			Log.Error("KeyValues handle is null.");
			return;
		}
		
		kv.Rewind();
		if(!kv.JumpToKey(entryName))
		{
			Log.Error("Wrong entryName was specified or key does not exists \"%s\".", entryName);
			return;
		}
		
		char buff[64], buff2[32], buff3[64], buff4[32];
		bool toFile = (file == null ? false : true),
			isSorted = (sortedlist == null ? false : true);
		
		if(toFile)
		{
			file.WriteLine(FORMAT_HEADER_FILE);
			file.WriteLine(FORMAT_NEWLINE);
		}
		else
		{
			Log.Info(FORMAT_HEADER_MSG);
			Log.Info(FORMAT_NEWLINE);
		}
		
		if(!isSorted)
		{
			kv.GotoFirstSubKey();
			
			do
			{
				kv.GetString("name", buff, sizeof(buff));
				kv.GotoFirstSubKey();
				
				do
				{
					kv.GetString("name", buff2, sizeof(buff2));
					
					Format(buff3, sizeof(buff3), "%s - %s", buff, buff2);
					FillString(buff3, FORMAT_MAXCHARS_COLUMN1);
					Format(buff2, sizeof(buff2), " %i handles", kv.GetNum("count"));
					FillString(buff2, FORMAT_MAXCHARS_COLUMN2);
					
					Dump.FormatMemory(buff4, sizeof(buff4), kv.GetNum("mem"));
					
					if(toFile)
						file.WriteLine(FORMAT_RULE_FILE, buff3, buff2, buff4);
					else
						Log.Info(FORMAT_RULE_MSG, buff3, buff2, buff4);
					
				} while(kv.GotoNextKey())
				
				if(toFile)
					file.WriteLine(FORMAT_NEWLINE);
				else
					Log.Info(FORMAT_NEWLINE);
				
				kv.GoBack();
				
			} while(kv.GotoNextKey())
		}
		else
		{
			int idx;
			
			for(int i = 0; i < sortedlist.Length; i++)
			{
				idx = sortedlist.Get(i);
				if(!kv.JumpToKeySymbol(idx))
				{
					Log.Error("Something went wrong, can't jump to \"%i\" key in kv tree.", idx);
					return;
				}
				
				kv.GetString("name", buff, sizeof(buff));
				idx = sortedlist.Get(i, 1);
				if(!kv.JumpToKeySymbol(idx))
				{
					Log.Error("Something went wrong, can't jump to \"%i\" subkey in kv tree.", idx);
					return;
				}
				
				kv.GetString("name", buff2, sizeof(buff2));
				
				Format(buff3, sizeof(buff3), "%s - %s", buff, buff2);
				FillString(buff3, FORMAT_MAXCHARS_COLUMN1);
				Format(buff2, sizeof(buff2), " %i handles", kv.GetNum("count"));
				FillString(buff2, FORMAT_MAXCHARS_COLUMN2);
				
				Dump.FormatMemory(buff4, sizeof(buff4), kv.GetNum("mem"));
				
				if(toFile)
					file.WriteLine(FORMAT_RULE_FILE, buff3, buff2, buff4);
				else
					Log.Info(FORMAT_RULE_MSG, buff3, buff2, buff4);
				
				kv.GoBack();
				kv.GoBack();
			}
			
			if(toFile)
				file.WriteLine(FORMAT_NEWLINE);
			else
				Log.Info(FORMAT_NEWLINE);
		}
	}
	
	public static bool Analyze(char[] path, KeyValues &kv, char[] entryName)
	{
		File file = OpenFile(path, "r", true);
		
		if(file == null)
		{
			Log.Error("Can't open handle dumps file \"%s\". Try to rise hdf_handledumps_timeout cvar and try again!", path);
			return false;
		}
		
		char regerror[128], buff[FILE_BUFFER], smallbuff[64], smallbuff2[32];
		RegexError err;
		Regex reg = new Regex("0x[\\w\\d]+\\s*([\\w\\ \\\\\\/\\[\\]\\;\\'\\.\\,\\{\\}\\(\\)\\-\\=\\+\\-\\&\\^\\%\\$\\#\\@\\!\\~\\`]+)\\s+([a-zA-Z]+)\\s+([\\-\\d]+)", .error = regerror, .maxLen = sizeof(regerror), .errcode = err); 
			//OLD Reg: 0x[\\w\\d]+\\s([^\\s]+)\\s+([a-zA-Z]+)\\s+([\\-\\d]+) [Does not match plugin name with space in it :(]
		int bytesreaded, offs, mem;
		
		if(err != REGEX_ERROR_NONE)
		{
			Log.Error("%s (errcode: %i)", regerror, err);
			delete file;
			delete kv;
			return false;
		}
		
		if(kv == null)
		{
			kv = new KeyValues("Dumps");
			kv.JumpToKey(entryName, true);
		}
		else
		{
			kv.Rewind();
			if(kv.JumpToKey(entryName, true))
			{
				kv.DeleteThis();
				kv.JumpToKey(entryName, true);
			}
		}
		
		do
		{
			bytesreaded = file.ReadString(buff, sizeof(buff));
			offs = 0;
			
			while(reg.Match(buff, err, offs) > 0)
			{
				if(err != REGEX_ERROR_NONE)
				{
					Log.Error("Regex failed to match. (errcode: %i)", err);
					delete file;
					delete kv;
					delete reg;
					return false;
				}
				
				reg.GetSubString(1, smallbuff, sizeof(smallbuff), 0);
				reg.GetSubString(2, smallbuff2, sizeof(smallbuff2), 0);
				
				TrimString(smallbuff);
				kv.JumpToKey(smallbuff, true);
				kv.SetString("name", smallbuff);
				kv.JumpToKey(smallbuff2, true);
				kv.SetString("name", smallbuff2);
				
				kv.SetNum("count", kv.GetNum("count") + 1);
				
				reg.GetSubString(3, smallbuff2, sizeof(smallbuff2), 0);
				mem = StringToInt(smallbuff2);
				
				if(mem != -1)
					kv.SetNum("mem", kv.GetNum("mem") + mem);
				else
					kv.SetNum("mem", -1);
				
				kv.GoBack();
				kv.GoBack();
				
				offs = reg.MatchOffset() - 1;
			}
			
		} while (bytesreaded == MAX_READ_BYTES)
		
		if(offs <= 0)
		{
			Log.Error("Invalid file? Nothing to parse were found in \"%s\".", path);
			delete file;
			delete kv;
			delete reg;
			return false;
		}
		
		delete file;
		delete reg;
		
		return true;
	}
	
	public static void Compare(KeyValues &kv, char[] entryName1, char[] entryName2, File file = null, ArrayList sortedlist = null)
	{
		if(kv == null)
		{
			Log.Error("KeyValues handle is null.");
			return;
		}
		
		kv.Rewind();
		if(!kv.JumpToKey(entryName1))
		{
			Log.Error("Wrong entryName1 was specified or key does not exists \"%s\".", entryName1);
			return;
		}
		
		KeyValues kv2 = new KeyValues(entryName1);
		kv2.Import(kv);
		
		kv.Rewind();
		if(!kv.JumpToKey(entryName2))
		{
			Log.Error("Wrong entryName2 was specified or key does not exists \"%s\".", entryName2);
			delete kv2;
			return;
		}
		
		char buff[64], buff2[32], buff3[32], buff4[64];
		bool toFile = (file == null ? false : true),
			isSorted = (sortedlist == null ? false : true);
		int ibuff, ibuff2;
		
		if(toFile)
		{
			file.WriteLine(FORMAT_HEADER_FILE);
			file.WriteLine(FORMAT_NEWLINE);
		}
		else
		{
			Log.Info(FORMAT_HEADER_MSG);
			Log.Info(FORMAT_NEWLINE);
		}
		
		if(!isSorted)
		{
			kv.GotoFirstSubKey();
			
			do
			{
				kv.GetString("name", buff, sizeof(buff));
				
				if(!kv2.JumpToKey(buff))
					continue;
				
				kv.GotoFirstSubKey();
				
				do
				{
					kv.GetString("name", buff2, sizeof(buff2));
					
					if(!kv2.JumpToKey(buff2))
						continue;
					
					Format(buff4, sizeof(buff4), "%s - %s", buff, buff2);
					FillString(buff4, FORMAT_MAXCHARS_COLUMN1);
					ibuff = kv.GetNum("count");
					ibuff2 = ibuff - kv2.GetNum("count");
					
					if(ibuff2 == 0)
						Format(buff2, sizeof(buff2), " %i handles", ibuff);
					else
						Format(buff2, sizeof(buff2), " %i (%s%i) handles", ibuff, (ibuff2 > 0 ? "+" : ""), ibuff2);
					
					FillString(buff2, FORMAT_MAXCHARS_COLUMN2);
					ibuff = kv.GetNum("mem");
					Dump.FormatMemory(buff3, sizeof(buff3), ibuff, ibuff - kv2.GetNum("mem"));
					
					if(toFile)
						file.WriteLine(FORMAT_RULE_FILE, buff4, buff2, buff3);
					else
						Log.Info(FORMAT_RULE_MSG, buff4, buff2, buff3);
					
					kv2.GoBack();
					
				} while(kv.GotoNextKey())
				
				if(toFile)
					file.WriteLine(FORMAT_NEWLINE);
				else
					Log.Info(FORMAT_NEWLINE);
				
				kv.GoBack();
				kv2.GoBack();
				
			} while(kv.GotoNextKey())
		}
		else
		{
			int idx;
			bool isKeyExists;
			
			for(int i = 0; i < sortedlist.Length; i++)
			{
				isKeyExists = true;
				idx = sortedlist.Get(i);
				if(!kv.JumpToKeySymbol(idx))
				{
					Log.Error("Something went wrong, can't jump to \"%i\" key in kv tree.", idx);
					continue;
				}
				
				kv.GetString("name", buff, sizeof(buff));
				if(!kv2.JumpToKey(buff))
					isKeyExists = false;
				
				idx = sortedlist.Get(i, 1);
				if(!kv.JumpToKeySymbol(idx))
				{
					Log.Error("Something went wrong, can't jump to \"%i\" subkey in kv tree.", idx);
					return;
				}
				
				kv.GetString("name", buff2, sizeof(buff2));
				if(!kv2.JumpToKey(buff2))
					isKeyExists = false;
				
				Format(buff4, sizeof(buff4), "%s - %s", buff, buff2);
				FillString(buff4, FORMAT_MAXCHARS_COLUMN1);
				ibuff = kv.GetNum("count");
				ibuff2 = (isKeyExists ? ibuff - kv2.GetNum("count") : ibuff);
				
				if(ibuff2 == 0)
					Format(buff2, sizeof(buff2), " %i handles", ibuff);
				else
					Format(buff2, sizeof(buff2), " %i (%s%i) handles", ibuff, (ibuff2 > 0 ? "+" : ""), ibuff2);
				
				FillString(buff2, FORMAT_MAXCHARS_COLUMN2);
				ibuff = kv.GetNum("mem");
				ibuff2 = (isKeyExists ? ibuff - kv2.GetNum("mem") : ibuff);
				Dump.FormatMemory(buff3, sizeof(buff3), ibuff, ibuff2);
				
				if(toFile)
					file.WriteLine(FORMAT_RULE_FILE, buff4, buff2, buff3);
				else
					Log.Info(FORMAT_RULE_MSG, buff4, buff2, buff3);
				
				kv.GoBack();
				kv.GoBack();
				
				kv2.GoBack();
				kv2.GoBack();
			}
			
			if(toFile)
				file.WriteLine(FORMAT_NEWLINE);
			else
				Log.Info(FORMAT_NEWLINE);
		}
		
		delete kv2;
	}
	
	public static void Sort(KeyValues &kv, char[] entryName, ArrayList &sortedlist)
	{
		if(kv == null)
		{
			Log.Error("KeyValues handle is null.");
			return;
		}
		
		kv.Rewind();
		if(!kv.JumpToKey(entryName))
		{
			Log.Error("Wrong entryName was specified or key does not exists \"%s\".", entryName);
			return;
		}
		
		if (sortedlist != null)
			delete sortedlist;
		
		int ibuff, ibuff2, idx;
		sortedlist = new ArrayList(2);
		
		kv.GotoFirstSubKey();
		
		do
		{
			kv.GetSectionSymbol(ibuff);
			
			kv.GotoFirstSubKey();
			
			do
			{
				idx = sortedlist.Push(ibuff);
				kv.GetSectionSymbol(ibuff2);
				sortedlist.Set(idx, ibuff2, 1);
				
			} while(kv.GotoNextKey())
			
			kv.GoBack();
			
		} while(kv.GotoNextKey())
		
		kv.Rewind();
		kv.JumpToKey(entryName);
		
		SortADTArrayCustom(sortedlist, CustomSortFunc, kv);
	}
}

public int CustomSortFunc(int index1, int index2, Handle array, Handle hndl)
{
	ArrayList al = view_as<ArrayList>(array);
	KeyValues kv = view_as<KeyValues>(hndl);
	
	char buff[64], buff2[64];
	int ibuff, ibuff2,
		order = (g_sortorder == Sort_Ascending ? -1 : 1);
	
	switch(g_sortfield)
	{
		case Sort_PluginNames:
		{
			kv.JumpToKeySymbol(al.Get(index1));
			kv.GetString("name", buff, sizeof(buff));
			
			kv.GoBack();
			
			kv.JumpToKeySymbol(al.Get(index2));
			kv.GetString("name", buff2, sizeof(buff2));
			
			kv.GoBack();
			
			int i, len1 = strlen(buff), len2 = strlen(buff2);
			while(buff[i] == buff2[i] && i < len1 && i < len2)
				i++;
			
			if(i == len1 || i == len2)
			{
				if(len1 > len2)
					return -order;
				else if (len1 < len2)
					return order;
				else
					return 0;
			}
			
			if(buff[i] > buff2[i])
				return -order;
			else if(buff[i] < buff2[i])
				return order;
			else
				return 0;
		}
		
		case Sort_HandleNames:
		{
			kv.JumpToKeySymbol(al.Get(index1));
			kv.JumpToKeySymbol(al.Get(index1, 1));
			kv.GetString("name", buff, sizeof(buff));
			
			kv.GoBack();
			kv.GoBack();
			
			kv.JumpToKeySymbol(al.Get(index2));
			kv.JumpToKeySymbol(al.Get(index2, 1));
			kv.GetString("name", buff2, sizeof(buff2));
			
			kv.GoBack();
			kv.GoBack();
			
			int i, len1 = strlen(buff), len2 = strlen(buff2);
			while(buff[i] == buff2[i] && i < len1 && i < len2)
				i++;
			
			if(i == len1 || i == len2)
			{
				if(len1 > len2)
					return -order;
				else if (len1 < len2)
					return order;
				else
					return 0;
			}
			
			if(buff[i] > buff2[i])
				return -order;
			else if(buff[i] < buff2[i])
				return order;
			else
				return 0;
		}
		
		case Sort_Handles:
		{
			kv.JumpToKeySymbol(al.Get(index1));
			kv.JumpToKeySymbol(al.Get(index1, 1));
			
			ibuff = kv.GetNum("count");
			
			kv.GoBack();
			kv.GoBack();
			
			kv.JumpToKeySymbol(al.Get(index2));
			kv.JumpToKeySymbol(al.Get(index2, 1));
			
			ibuff2 = kv.GetNum("count");
			
			kv.GoBack();
			kv.GoBack();
			
			if(ibuff > ibuff2)
				return -order;
			else if(ibuff < ibuff2)
				return order;
			else
				return 0;
		}
		
		case Sort_Memory:
		{
			kv.JumpToKeySymbol(al.Get(index1));
			kv.JumpToKeySymbol(al.Get(index1, 1));
			
			ibuff = kv.GetNum("mem");
			
			kv.GoBack();
			kv.GoBack();
			
			kv.JumpToKeySymbol(al.Get(index2));
			kv.JumpToKeySymbol(al.Get(index2, 1));
			
			ibuff2 = kv.GetNum("mem");
			
			kv.GoBack();
			kv.GoBack();
			
			if(ibuff > ibuff2)
				return -order;
			else if(ibuff < ibuff2)
				return order;
			else
				return 0;
		}
	}
	
	return 0;
}
