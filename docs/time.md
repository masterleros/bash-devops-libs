* [time.startTimer()](#timestarttimer)
* [time.elapsed()](#timeelapsed)
* [time.human()](#timehuman)



# time.startTimer()

Set a named timer to calculate future elapsed seconds

### Arguments

* **name** (string): Timer's name

### Example

```bash
startTimer <name>
```

# time.elapsed()

Get the elapsed seconds from a named timer

### Arguments

* **name** (string): Timer's name

### Return value

* Seconds since the timer was set

### Example

```bash
elapsed <name>
```

# time.human()

Create a human timing description from seconds

### Arguments

* **seconds** (int): Seconds

### Return value

* Text with the time description

### Example

```bash
human <seconds>
```

