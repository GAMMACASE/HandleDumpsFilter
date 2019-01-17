# HandleDumpsFilter (HDF)

Sourcemod plugin that allows you to fiter handle dumps (sm_dump_handles).

## Basic usage and examples:

HDF provides a lot of ways how you can filter your handle dump, and by using ``sm_checkhandles -h`` you can see whole list of available arguments.

To filter handle dump use ``sm_checkhandles`` command. That command is not meant to be executed by multiple clients at the same time!

Feel free to submit an issue if you found one, or if you want to suggest something.

_NOTE: Output of that command may not fit in the console/chat in game, so I suggest to use that command through server console, that way output should be shown correcty._

_Known issues: You may get **``Script execution timed out``** error if you are trying to filter or compare big handle dump(s), to fix that, you need to set ``"SlowScriptTimeout"`` in ``addons/sourcemod/configs/core.cfg`` to something higher then default values is, 60 may be a good one._

### Available cvars:

* **hdf_handledumps_folder** - Folder where all handle dumps will be stored, path relative to game folder;
* **hdf_handledumps_savefolder** - Folder where all handle dumps will be stored if -sd param was used;
* **hdf_handledumps_amount** - Amount of handle dumps stored in the specified folder;
* **hdf_handledumps_fileprefix** - Prefix that will be used for created dumps;
* **hdf_handledumps_timeout** - Time to wait for handle dump to be created;
* **hdf_logerrors** - Set to 1 if you want to log every occurred error;

### All available arguments:

* **-h** - print help list;
* **-sh** - print sort help list;
* **-th** - print all available memory output types;
* **-sd** - save handle dump under the directory specified in ``hdf_handledumps_savefolder`` cvar;
* **-so \<path to file>** - save output to a specific file;
* **-c \<path to file>** - compare currect handle dump to another dump; (You can also use words \"lastsaved\" and \"lastcreated\" to get the appropriate files);
* **-d \<path to file>** - set different path for raw handle dump;
* **-st \<sort type>** - set custom sort type;
* **-mt \<memory type>** - set custom memory output type (eg. KB, MB, GB);
	
You can use any amount of arguments at a time, there's no limit for that. If you use same argument twice or more then last one will be used.

### Examples:

* ``sm_checkhandles`` - basic usage of a command, that will create handle dump in temp directory specified in ``hdf_handledumps_folder`` cvar, and will filter that dump. Here's how output will look like:
![example1](https://i.imgur.com/VxBIYry.png)

* ``sm_checkhandles -st -m`` - that will create handle dump in temp directory specified in ``hdf_handledumps_folder`` cvar, and will filter that dump using custom sorting type ``-m`` (sort descending by memory). Here's how output will look like:
![example2](https://i.imgur.com/mgOxaLp.png)

* ``sm_checkhandles -sd -st pln -mt kb`` - that will create handle dump in save directory specified in ``hdf_handledumps_savefolder`` cvar, and will filter that dump using custom sorting type ``pln`` (sort ascending by plugin name) and will use KiloBytes as memory type. Here's how output will look like:
![example3](https://i.imgur.com/0ARWpuG.png)

* ``sm_checkhandles -c lastsaved -d handles/dump.txt -st -h -so dumpoutput.txt`` - that will create handle dump in specified directory ``handles/dump.txt`` (Note: it will not auto create directory), and will filter that dump using custom sorting type ``-h`` (sort descending by handle count), also it will compare newly created dump relative to specified one ``lastsaved`` (In that case ``lastsaved`` means that it will use dump that was last saved using ``-sd`` argument during plugin lifetime) and finally it will create file ``dumpoutput.txt`` with output. Here's how output will look like:
![example4](https://i.imgur.com/S7FyWm8.png)

	and the ``dumpoutput.txt`` file:

	![example4.2](https://i.imgur.com/Iw5OxdC.png)
