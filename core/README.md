# dolib CORE module

This is the kernel of the dolib, below it will be described how it works and how to develop for it.

## Functions
Different functions are provided in different parts of `dolibs` we will check the provided functions on each section below, but let see some definitions:

There are 3 types of functions:
|Starts with|Description|
|-|-|
|_[function]|Bash does not provide private functions, but when a function start with `_` it means that it needs to be threated as|
|_dolib[function]|All core functions start with `dolibs`, this will maintain a clrear view of core functions|
|[namespace].[lib].[function]|All the functions imported and managed by `dolibs` starts with a namespace (which can contain sub sections) and then the function name|

## Variables
Because `dolibs` requires some global variables in order to operate, the following variables are defined as part of the core:

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

## Coding style

- **Funtions:** functions are written in camelCase
- **local variables:** local scope variables are written in camelCase
- **exported variables:** exported variables are written in UPPERCASE separated by underscore

# Boostrap

In order to start `dolibs`, there is a key component named `boostrap`. This component is implemented in the `boostrap.sh` file and is the core initializer script. \
Its execution will define and perform several functionalities:

### Code import 
When the boostrap is initiated, it will get the code from where it was requested depending on the above configurations.

|Source|Description|
|-|-|
|**GIT** (default)|It will use the Git repository as source of dolib|
|**Local**|It will use a local folder as source of dolib (usefull for a lib development)|

When sourcing from Git, after cloning/update the code, the `.source.state` will be created with all the details of the source (including hash). This will allow dolibs to validate source when required. \
Another important file is the `.source.cfg` which defines the source of the code, it will be managed by the `do lib` (described below) but is still very important for 3rd party libraries being imported and managed by the boostrap functions.

### Operation mode
The operation mode will define how code and source are managed, the following modes are available:

|Mode|Description|
|-|-|
|**offline**|Will use the code from where it's placed, if it does not exist, it fails|
|**auto** (default)|Will source the code (copy) from where it placed, but if not found, it will try to copy from source|
|**online**|Will check if code is up-to-date in respect to source, if not, it will source it (copy)|

### Code validation
Once boostrap is executed, it will check the integrity of the files by checking it last import `.source.shasum` created file, it contains a `sha1sum` result for all the files. Depending on the operation mode, it will trigger the update of the code from the defined source.

|Function|Description|Usage|
|-|-|-|
|**_dolibGitClone()**|Clone a lib code from a GIT repository|`_dolibGitClone <GIT_REPO> <GIT_BRANCH> <GIT_DIR> <LIB_ROOT_DIR>`|
|**_dolibGitOutDated()**|Indicate if the lib code is outdated compared to its GIT origin|`_dolibGitOutDated <LIB_ROOT_DIR>`|
|**_dolibGitWrongBranch()**|Indicate if the lib code branch has changed|`_dolibGitWrongBranch <LIB_ROOT_DIR> <GIT_BRANCH>`|
|**_dolibSourceUpdated()**|Indicate if the local source (or cache) is different than the lib|`_dolibSourceUpdated <SOURCE_DIR> <LIB_DIR>`|
|**_dolibImportFiles()**|Import Lib files (i.e: create dir, copy files, hash)|`_dolibImportFiles <SOURCE_DIR> <LIB_DIR>`|
|**_dolibNotIntegral()**|Check if the libs files are valid|`_dolibNotIntegral <LIB_DIR>`|
|**_dolibUpdate()**|Update the a lib code if it is required|`_dolibUpdate <MODE> <SOURCE_DIR> <TARGET_DIR> [GIT_DIR]`|

# Core
The core itself is the mechanism to source (import) other code and modify it to add the embeeded functionalities which are defined on the `core modules`.

### Library import
When a library is requested to be imported, the core library will source the library `main.sh` file, this will allow to the library to execute any validation, definition, etc on its `main.sh` body (even used to source other files). \
After the library `main.sh` file is source, the core will get all imported functions from this and will rename them to respect the folder convention (e.g: mylib/test/main.sh -> will be mylib.test.[function])

> Check the [library development section](../libs/README.md)

### Function rework
As mentioned above, when library is imported, the imported functions are reworked, this means that its name will be updated to include the library namespace and additionally all the core modules will be executed to process their body. Check below the `code modules` section.


|Function|Description|Usage|
|-|-|-|
|**_dolibReworkCode()**|Empty function that receives the function/code rework from module's __rework()|`_dolibReworkCode`|
|**_dolibImportModule()**|Import a core module|`_dolibImportModule <MODULE_PATH>`|
|**dolibReworkFunction()**|Rework a function to enable dolibs features|`dolibReworkFunction <FUNC> <NEW_FUNC>`|
|**dolibImportLib()**|Import a library from its files and rework functions as required|`dolibImportLib <LIB> <LIB_DIR>`|

## CORE modules
`dolibs` implements a feature called **core modules**. These modules are names as `mod-<name>.sh` and placed at same folder as the core's code.\
A `core module` is a piece of core functionality that will be loaded when core is bootstraped, currently there are some `core modules` already packgaged and are cucial for the internal libs functionalities. 

Modules can modify/update the imported lib functions in order to add functionalities to the imported code, for that, when a module is imported to the core, the `__rework()` function is invoked. This function will receive the libs function's code every time one is imported. In this way the module can update the function code accordingly. When this function is invoked, the following values are available:

|Variable|Description|
|-|-|
|**_funct**|Current function name|
|**_newFunc**|New function name (if changing)|
|**_file**|File from where the function comes from|
|**_body**|Function's body (this variable will be rewriten back to function, so that needs to be updated with changes)|
|**_lib**|Library namespace|
|**_libDir**|Library folder|

### Current build-in core modules:

|Module|Description|
|-|-|
|**mod-args**|Manages arguments|
|**mod-check**|Validation functions (e.g: to check libs dependencies)|
|**mod-error**|Error management|
|**mod-except**|Exception management|
|**mod-output**|Text output functionalities|

> Check all the modules functionalities at [core function documentation](../docs/core.md)

# The do lib
Once the core is loaded, the `do` lib is loaded by the core. This lib will enable final-user friendly usage for using the libs.

## Import libs
This lib include the management of other libs, including the built-in (`do.use`) and 3rd party libs (`do.import`), which for them, the `.souce.cfg` configuration file is put in place. \
This file can contain the bellow informations depending of the type of source:

``` sh
TYPE:<type>
NAMESPACE:<namespace provided>
```

Additionally per each type, you will find:

|Type|Values|Description|
|-|-|-|
|**GIT**|`SOURCE_REPO`<br>`SOURCE_BRANCH`<br>`SOURCE_DIR`<br>`GIT_DIR`|Will source (copy) the code based on the definitions|
|**LOCAL**|`SOURCE_DIR`|Will source (copy) the code based on the definitions|
|**OFFLINE**|`LIB_DIR`|Will use the code directly from it is hosted based on the definitions|

## Documentation
When `do` lib import others libs (built-in or 3rd party) it will generate automatically the documentation for them. \
The documentation is created based in all `*.sh` files found starting at the root namespace (e.g: when importing `example.of.lib` will documenta all starting at `example`) \
This documentation is by using a modified version of [shdoc](https://github.com/reconquest/shdoc) by following [this conventions](../libs/do/README.md)


> Check **do library** [here](../docs/do.md)