# Changelog
## v1.1.0.0 191008
### Additions
### Bugfixes
### Improvements
* ValidateSet on parameters is now case sensitive.
* Much more detailed error message if failing.
* Will not try to install different architecture over existing version of Firefox (x64 over x86 and visa versa).
* Logging to ProgramData, so we don't need special permissions to neither view or create logs.
* More relevant troubleshooting info.


## v1.0.2.0 190911
### Additions
* Added all supported languages to ValidateSet as per Firefox v69.
* Now has a changelog.
### Fixes
* Download fail would not get proper exit code, had to put it in a Try Catch to make sure it failing did not cause premature exit.
### Improvements
* Logs custom exit code in the error message, just to see if it actually gets set.
* Moved exit $ExitCode to the Finally bracket.
* Send logs to $env:LOCALAPPDATA instead of $env:ProgramW6432


## v1.0.1.0 190709
* Various (not logged, so forgot what)


## v1.0.2.0 190704
* Initial release