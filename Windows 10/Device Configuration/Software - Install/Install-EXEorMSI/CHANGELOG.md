# Changelog
## v1.0.2.1 200812
### Additions
* Moved most examples to seperate file
	* The script should not be changed every time I find a new program that can be installed witht the script.

### Fixes
* Ability to pass no arguments what so ever.

### Improvements
* Added BITS transfer as secondary method of downloading if .NET WebClient fails.
	* Makes it possible to download FileZilla, got 403 forbidden with WebClient.


## v1.0.2.0 200615
### Additions
* Better logic for logging
* Optional if script should check for install success by providing a path: Sometimes one probably want to handle that from the MDM instead (detection rules).

### Fixes

### Improvements



## v1.0.1.0 200423
### Additions
* Added input parameter $UserContext, can now install in user context as well
* Added workaround to re-launch script as 64 bit process if running as 32 bit process on 64 bit OS

### Fixes

### Improvements
* More exit codes



## v1.0.0.0 200329
* Initial release
