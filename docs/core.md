
* [do.validateVars()](#dovalidatevars)
* [do.verifyDeps()](#doverifydeps)
* [do.valueInArray()](#dovalueinarray)
* [do.configInFile()](#doconfiginfile)
* [do.document()](#dodocument)


# do.validateVars()

Validate if the specified variables are defined

### Arguments

* **...** (list): variables names to be validated

### Exit codes

* **0**: If all are defined
* **>0**: Amount of variables not defined

### Output on stdout

* Variables not declared

### Example

```bash
validateVars <var1> <var2> ... <varN>
```

# do.verifyDeps()

Verify if the specified binaries dependencies are available

### Arguments

* **...** (list): binaries to be verified

### Exit codes

* **0**: If all are found
* **>0**: Amount of binaries not found

### Output on stdout

* Binaries not found

### Example

```bash
verifyDeps <bin1> <bin2> ... <binN>
```

# do.valueInArray()

Check if a value exists in an array

### Arguments

* **value** (value): Value to look for
* **array** (array): Array to look for the value

### Return value

* Found value position

### Exit codes

* **0**: Value was found
* **1**: Value not found

### Example

```bash
assign valPos=valueInArray <value> <array>
```

# do.configInFile()

Get a value from a config file in format <key>:<value>

### Arguments

* **file** (path): Path to the file
* **key** (Key): of the required value

### Return value

* Value of the key

### Exit codes

* **0**: Key found
* **1**: Key not found

### Example

```bash
assign myVar=configInFile <file> <key>
```

# do.document()

Generate the markdown documentation of a lib

### Arguments

* **dir** (path): Directory of the library to be documented
* **doc** (path): md file (markdown) to be generated
* **namespace** (string): (optional) library's namespace

### Example

```bash
document <dir> <file> <namespace>
```








* [do.use()](#douse)
* [do.import()](#doimport)
* [do.addGitSource()](#doaddgitsource)
* [do.addLocalSource()](#doaddlocalsource)
* [do.addLocalLib()](#doaddlocallib)


# do.use()

Use build-in libraries to be used in a script

### Arguments

* **...** (list): List of libraries names

### Example

```bash
use <lib1> <lib2> ... <libN>
```

# do.import()

Import libraries from configured sources to be used in a script

### Arguments

* **...** (list): List of libraries names

### Example

```bash
import <lib1> <lib2> ... <libN>
```

# do.addGitSource()

Add a git repository source of lib

### Arguments

* **namespace** (string): Namespace to import the source's libraries
* **repo** (string): Github repository path (i.e: owner/repo)
* **branch** (string): Branch name
* **dir** (path): Relative path for the lib folder (if libs are in root, use '.')

### Example

```bash
addGitSource <namespace> <repo> <branch> <dir>
```

# do.addLocalSource()

Add a local source of libs (to be copied)

### Arguments

* **namespace** (string): Namespace to import the source's libraries
* **path** (path): Path to the local directory where the libs are hosted

### Example

```bash
addLocalSource <namespace> <path>
```

# do.addLocalLib()

Add local libs (to be used from where they are)

### Arguments

* **namespace** (string): Namespace to import the source's libraries
* **path** (path): Path to the local directory where the libs are hosted

### Example

```bash
addLocalSource <namespace> <path>
```

