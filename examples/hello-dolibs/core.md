* [do.checkVars()](#docheckvars)
* [do.checkBins()](#docheckbins)












# do.checkVars()

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
checkVars <var1> <var2> ... <varN>
```

# do.checkBins()

Verify if the specified binaries dependencies are available

### Arguments

* **...** (list): binaries to be verified

### Exit codes

* **0**: If all are found
* **>0**: Amount of binaries not found

### Output on stderr

* Binaries not found

### Example

```bash
checkBins <bin1> <bin2> ... <binN>
```










