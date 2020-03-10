# DEVOPS Bash libraries #

## Introduction
**dolibs** is an small bash framework with a built-in set of common functionatilities and templates to accelerate DevOps setup processes.

Example:
``` sh
INFO:   Initializing dolibs (v0.2)
INFO:   (online) from GIT source - branch 'develop'
INFO:   dolibs started!

        Hello DevOps Libs from local!
```

# Using Libraries
In order to use this library (i.e: local execution or in GitLab Pipeline) you need to include the DevOps Libs in your project.
For that you need to follow the steps:

#### 1. Download the library entrypoint
Download the file `dolibs.sh` placed in a folder whitin your code, example: `<YOUR_REPO>/dolibs.sh`

This is the entry point of the library, once executed (see below) it will automatically retrieve (depending one the operational mode) the **dolibs** code and include for you in your project at `${DOLIBS_DIR}` folder

``` sh
# Command to download dolibs.sh
curl https://raw.githubusercontent.com/masterleros/bash-devops-libs/master/dolibs.sh -o dolibs.sh
```

#### 2. Include and use **dolibs**
> **Obs:** In the default operation mode (auto) it will add its own code into your current `dolibs.sh` folder at `./dolibs` (i.e: to redistribute with your code).

**my-script.sh**
``` sh
#!/bin/bash
# This line of code will source the dolibs entrypoint, this format help to find dolibs.sh 
# file relative to the current script path, regardesless of where it was executed
source $(dirname ${BASH_SOURCE[0]})/<relative path to>/dolibs.sh

# Import required lib
do.use gcp

# Use the lib
gcp.useSA ${GOOGLE_APPLICATION_CREDENTIALS}
```

#### 3. Configure the library regarding your needs

You can pass some options to the library to change its behaviour.

**Example:** The below example will use the lib in offline mode located in the specified <path>

**my-script.sh**
``` sh
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/<relative path to>/dolibs.sh --offline -f <path>
...
```

# dolibs Options

The following options are available when you include **dolibs** by passing them as arguments:

- **Operation Mode:** Indicate how updated are managed
- **Folder:** dolibs working folder
- **Local Source (optional):** Use a local dolibs source insted of remote (i.e: development)
- **Debug:** Run in debug mode, it will print additional debugging information
- **Debug Core:** Run in core debug mode, it will print additional debugging information from the core engine

Other options are global and will change **dolibs** for any include, to change them, you need to edit the `dolibs.sh` file:

- **DOLIBS_MODE:** Default operation mode (default: auto)
- **DOLIBS_BRANCH:** dolibs branch (default: master)

### OPTION: Operation Mode
This mode indicate how `dolibs` will manage the updates, there are 3 operation modes:

|Mode|Argument|Description|
|-|-|-|
|**Auto (default)**|N/A|This mode will download/copy the libraries if not found locally or if there is consistency|
|**Online**|--online|This mode will check the source's updates and will download/copy and update the libraries automatically|
|**Offline**|--offline|This Mode will use available libraries, if it is not found nor consistent, it will fail|

Example using the lib in **offline** mode:
``` yaml
#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/<relative path to>/dolibs.sh --offline
```
> **Tip:** To change default operation mode, update `DOLIBS_MODE` variable value editing `dolibs.sh` file.

### OPTION: Folder (-f)
By default, `dolibs.sh` will use the `<dolibs.sh dir>/dolibs` folder to download/copy and install all the requested libs. \
It is possible to use **dolibs** in a custom directory, to do so, you need to specify the `-f <path>` argument when sourcing `dolibs.sh`.

### OPTION: Local Source (-l)
By default, when in `auto` or `online` mode, **dolibs** will clone its own code from GIT. \
Instead, it is possible to specify a local source (folder) to copy from the `dolibs` code. Using in that way it is possible to develop `dolibs` libraries locally and test without the need of commit your `dolibs` code all the times.

### OPTION: Debug (--debug)
This will enable `echoDebug` calls from libs or even from final developer code

### OPTION: Debug (--debug-core)
This will enable code debugging logs

# Libraries Sources
`dolibs` allows to add external sources to be used whitin same scripts. \
To include them, you need first to add your custom sources and then import their libraries.

Currently there are 2 custom sources:
- **GIT Source** will download and incorporate libs from a public GIT repo
- **Local Source:** will copy the libs from a local folder (example: your custom libs)
- **Local Libraries:** will use the libs directly from the specified path (i.e: libs included in whitin your code)

> **Tip:** It you are planni

## GIT Source

To include a custom GIT source, you can use the function `do.addGitSource`:

**example.sh**
``` sh
# Enable dolibs (clone to /tmp/dolibs)
source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh

# Set the remote lib source
do.addGitSource myremotelib "https://github.com/masterleros/bash-devops-libs.git" master

# Import the required lib from custom namespace
do.import myremotelib.dummy

# Use the needed lib
myremotelib.dummy.doIt "Hello DevOps Libs!"
```

## Local Source

To include a custom local source, you can use the function `do.addLocalSource`:

**example.sh**
``` sh
# Enable dolibs (clone to /tmp/dolibs)
source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh

# Set the local lib source
do.addLocalSource $(dirname ${BASH_SOURCE[0]})/../../libs

# Import the required lib from custom namespace
do.import mylocallib.dummy

# Use the custom lib
mylocallib.dummy.doIt "Hello DevOps Libs!"
```

## Local Libraries

To include local libraries (will be used from where they are specified, i.e: offline), you can use the function `do.addLocalLib`:

**example.sh**
``` sh
# Enable dolibs (clone to /tmp/dolibs)
source $(dirname ${BASH_SOURCE[0]})/../../dolibs.sh

# Set the local lib source
do.addLocalLib "<my source>/mylibs"

# Import the required lib from custom namespace
do.import mylibs.dummy

# Use the custom lib
mylibs.dummy.doIt "Hello DevOps Libs!"
```

# Good Practices

## Global definitions
As a good practice for your own scripts centralize your project's configurations/validations. `dolibs` provides the **globals** lib which will source your script defined in `DOLIBS_GLOBALS_PATH` variable, if not defined, the default value is `globals.sh` file placed in the `dolibs.sh` folder \
This is very usefull to define validations/functions/variables/definitions accesibles to your project's scripts globaly. Example:

**globals.sh**
``` sh
checkVars A_VARIABLE
checkBins a_binary

export MY_PROJECT_DESCRIPTION="My cool project!"

function customFunct() {
  getArgs "arg" "${@}"
  echo "My arg is: '${arg}'"
}
```

The above environment variable `MY_PROJECT_DESCRIPTION` and custom function `customFunct()` will be accesibles from you script once you include it:

**my-script.sh**
``` sh
do.use globals
globals.customFunct "${MY_PROJECT_DESCRIPTION}"

# Output: My arg is: 'My cool project!'
```

# Libraries documentation
Once a library is imported, its documentation will be generated in the `dolibs/docs` folder in a file named as its namespace (example: `utils` lib will be documented as `dolibs/docs/utils.md`)

# Developing libraries
Check the libraries development at: [Development](libs/README.md)