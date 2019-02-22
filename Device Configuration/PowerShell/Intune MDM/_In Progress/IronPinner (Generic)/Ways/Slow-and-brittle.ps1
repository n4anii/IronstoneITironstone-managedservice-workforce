#Powershell script

#WARNING:
#Sends keystrokes to the start menu, so this technique is very brittle 
#compared to all the other ways. You should avoid unless you 
#know that the start menu is available when you run this script
#It is slow: it takes about 1 second to add a pinned program

#Only good thing about this script: doesn't require any outside exe. 

#You should NEVER use this script on an already pinned program.
#There is no way for this script to detect that a link is already pinned.
#(if you know of a way, please share.)

#if an app is already pinned when this runs, it will either:
#a. pin it to start menu
#b. unpin it from the taskbar when it's already on the start menu.

function Pin-ToTaskbar
{ 
    param 
    (
        [parameter(position=1,mandatory=$true)] $appName
    ) 

    Add-Type -AssemblyName System.Windows.Forms

    
    [System.Windows.Forms.SendKeys]::SendWait("^{ESC}") # Ctrl-Esc to call start menu 
    start-sleep -Milliseconds 200
    [System.Windows.Forms.SendKeys]::SendWait($appname) # type app name 
    start-sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("+{F10}") # Shift-F10 to call right-click menu
    start-sleep -Milliseconds 200
    [System.Windows.Forms.SendKeys]::SendWait("{DOWN 4}") # down 4 times,
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}") # enter
    [System.Windows.Forms.SendKeys]::SendWait("{ESC}")    # escape to close start menu
}

#examples:

Pin-ToTaskbar "Google Chrome"
Pin-ToTaskbar "Mozilla Firefox"
Pin-ToTaskbar "Opera"
Pin-ToTaskbar "Internet Explorer"
Pin-ToTaskbar "Visual Studio 2015"
Pin-ToTaskbar "Word 2016"
Pin-ToTaskbar "Excel 2016"
Pin-ToTaskbar "Outlook 2016"