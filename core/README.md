# dolib CORE module

This is the kernel of the dolib, below it will be described how it works and how to develop for it.

## Variables
dolibs requires some global variables in order to operate, the following variables are defined as part of the core:

|Variable|Description|Possible Values|Required beforehand|Exported|
|-|-|-|-|-|
|DOLIBS_LOADED|Indicates that dolib was `already` loaded|`true`|No|Yes|
|DOLIBS_VER|Defines the dolibs version|N/A|No|Yes|
|DOLIBS_MODE|Operation mode|`online`, `auto` or `offine`|Yes|Yes|
|DOLIBS_DEBUG|Debug flag|`libs`, `core` or `libs core`|Yes|Yes|
|DOLIBS_REPO|Source GIT repository|*name*|Yes|Yes|
|DOLIBS_BRANCH|Source GIT repository branch|*url*|No|Yes|
|DOLIBS_DIR|`dolibs` working folder|*path*|Yes|Yes|
|DOLIBS_ROOTDIR|`dolibs` root folder (where dolibs.sh is placed)|*path*|Yes|Yes|
|DOLIBS_CORE_DIR|`dolibs` core code folder|*default: [root]/core*|Yes|No|
|DOLIBS_GIT_DIR|GIT cache dir|*default: [root]/.libtmp/[branch]*|No|No|
|DOLIBS_LOCAL_SOURCE_DIR|Local source of code when local source|(optional) *path*|No|No|
|DOLIBS_SOURCE_DIR|Local source of code (if GIT sourced, it's the cache folder) |*default: [root]/.libtmp/[branch]*|No|No|
|DOLIBS_SOURCE_CORE_DIR|`dolibs` core source code folder|*default: [DOLIBS_SOURCE_DIR]/core*|No|No|
|DOLIBS_SOURCE_LIBS_DIR|`dolibs` lib source code folder|*default: [DOLIBS_SOURCE_DIR]/libs*|No|Yes|
|DOLIBS_LIBS_DIR|`dolibs` built-in libs folder|*default: [root]/libs*|No|Yes|
|DOLIBS_TMPDIR|Temporary folder for GIT clone (added to .gitignore)|*default: [root]/.libtmp*|No|Yes|

## The boostrap

In order to start `dolibs`, there is a key component named `boostrap`. This component is implemented in the `boostrap.sh` file and is the core initializer script. \
Its execution will define and perform several functionalities:

|Function|Description|Usage|
|-|-|-|
|**_dolibGitClone()**|Clone a lib code from a GIT repository|`_dolibGitClone <GIT_REPO> <GIT_BRANCH> <GIT_DIR> <LIB_ROOT_DIR>`|
|**_dolibGitOutDated()**|Indicate if the lib code is outdated compared to its GIT origin|`_dolibGitOutDated <LIB_ROOT_DIR>`|
|**_dolibGitWrongBranch()**|Indicate if the lib code branch has changed|`_dolibGitWrongBranch <LIB_ROOT_DIR> <GIT_BRANCH>`|
|**_dolibSourceUpdated()**|Indicate if the local source (or cache) is different than the lib|`_dolibSourceUpdated <SOURCE_DIR> <LIB_DIR>`|
|**_dolibImportFiles()**|Import Lib files (i.e: create dir, copy files, hash)|`_dolibImportFiles <SOURCE_DIR> <LIB_DIR>`|
|**_dolibNotIntegral()**|Check if the libs files are valid|`_dolibNotIntegral <LIB_DIR>`|
|**_dolibUpdate()**|Update the a lib code if it is required|`_dolibUpdate <MODE> <SOURCE_DIR> <TARGET_DIR> [GIT_DIR]`|

## The Core

|Function|Description|Usage|
|-|-|-|
|**_dolibReworkCode()**|Empty function that receives the function/code rework from module's __rework()|`_dolibReworkCode`|
|**_dolibImportModule()**|Import a core module|`_dolibImportModule <MODULE_PATH>`|
|**dolibReworkFunction()**|Rework a function to enable dolibs features|`dolibReworkFunction <FUNC> <NEW_FUNC>`|
|**dolibImportLib()**|Import a library from its files and rework functions as required|`dolibImportLib <LIB> <LIB_DIR>`|

## CORE modules
`dolibs` implements a feature called **core modules**. These modules are names as `mod-<name>.sh` and placed at same folder as the core's code.\
A `core module` is a piece of core functionality that will be loaded when core is bootstraped, currently there are some `core modules` already packgaged and are cucial for the internal libs functionalities.

|Module|Description|
|-|-|
|**mod-args**|Manages arguments|
|**mod-check**|Validation functions (e.g: to check libs dependencies)|
|**mod-error**|Error management|
|**mod-except**|Exception management|
|**mod-output**|Text output functionalities|

> Check all the modules functionalities at [core function documentation](../docs/core.md)

## The do lib
Once the core is loaded, the `do` lib is loaded by the core. This lib will enable final-user friendly usage for using the libs.

> Check **do library** [here](../docs/do.md)