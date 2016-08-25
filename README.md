# fresponse-flexdisk-securitylogs
Powershell Script to Pull Security Event Logs Using F-Response FlexDisk API

This is a simple Powershell script I wrote that is designed to work with F-Response FlexDisk API (tested on F-Response Enterprise latest version as of August 1st 2016) to pull down the Windows Security Event log from a list of machines. Some of the recommended documentation from F-Response was to pull a master CSV derived from the MFT that provides a node value you can use to query directly for the security event logs but this involved downloading a dynamically rendered (and thus slow) 300 MB file on average. This was hefty and slow so I decided to query the root volume in FlexDisk - parse the HTML page itself, and use the HREF tag to construct a subsequent query. Using this technique you can rapidly query through a series of folders and reach a file for download in a timely fashion, so long as you know the path and file name.

A few caveats:
- The username and password are hard coded in the script, change those to match your F-Response configuration (or better yet don't hardcode them and prompt the user for them as a better security practice)
- The variable $MachineArray has a hardcoded path to a list of machine names, update this to include the machines you want to iterate through
- My configuration is using port 3261, if you are listening on a different port in F-Response, change this in the script
- If you want to download something other than the Security.evtx log then change the '&name=' values in the script for each folder in the files path, and the file name itself

This could definitely be expanded upon to prompt the user for a path and filename so that an analyst could easily download files without having to modify the script. The www.f-response.com team are pretty awesome and helpful, this script uses a bunch of code they have shared, check them out.

Cheers!
GKC
