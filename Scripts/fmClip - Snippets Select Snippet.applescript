-- fmClip - Select from Snippets
-- version 1.0.0, Matt Petrowsky

(*
	Presents a list of available snippet files from the dedicated Snippets folder and calls XML to FM Objects.

HISTORY:
	1.0 - initial commit
*)
property scriptPath : ""
property scriptName : "fmClip - Clipboard XML to FM Objects.applescript"
property myFolder : alias


-- Create path to Snippets folder.
set myFolder to ((((path to me as text) & "::") as alias) as string)
set stripLevel to text 1 thru ((length of myFolder) - 1) of myFolder -- strip trailing ":"
set parentFolder to text 1 thru -((offset of ":" in (reverse of characters of stripLevel) as string) + 1) of stripLevel

set snippetsFolder to parentFolder & ":Snippets:" as alias
set snippetsPath to POSIX path of snippetsFolder

(*
-- Present a simple list of files in the Snippets folder
set fileList to {}

tell application "System Events"
	set fileNames to name of files of folder snippetsPath
	repeat with fileName in fileNames
		if fileName as string is not equal to ".DS_Store" then
			set end of fileList to (snippetsPath & fileName) as string
		end if
	end repeat
end tell

-- Prompt user for which snippet to put onto the clipboard.
try
	tell application "System Events"
		set fmAppProc to my getFmAppProc()
		tell fmAppProc
			set frontmost to true
			set chosenFile to choose from list fileList with prompt "Select a snippet file:" without multiple selections allowed
			set xmlFile to (item 1 of chosenFile)
			set filePath to xmlFile as POSIX file as alias
		end tell
	end tell
on error
	return
end try
*)

-- Or, an easier option of just using a file chooser.

try
	set fmAppProc to my getFmAppProc()
	tell fmAppProc
		set frontmost to true
	end tell
	
	tell me to activate
	set chosenFile to choose file default location snippetsFolder without multiple selections allowed
	fmClipboardObject(chosenFile)
	
on error errMsg number errNum
	if errNum is -128 then return -- user canceled
	error errMsg number errNum
end try

-- Read file contents, set to clipboard and call script.
on fmClipboardObject(filePath)
	try
		tell application "System Events"
			set scriptPath to myFolder & scriptName
			set fileContents to read filePath as Çclass utf8È
			set the clipboard to fileContents
			if run script alias scriptPath then
				display notification "Snippet is on the clipboard." with title "FileMaker Clipboard" sound name "Funk"
			end if
		end tell
		set fmAppProc to my getFmAppProc()
		tell fmAppProc
			set frontmost to true
		end tell
	on error errMsg
		display dialog "File read error: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end fmClipboardObject

-- Helper function to target the FileMaker app process.
on getFmAppProc()
	-- Gets the frontmost "FileMaker" app (if any), otherwise the 1st one available.
	tell application "System Events"
		set fmAppProc to first application process whose frontmost is true
		if name of fmAppProc does not contain "FileMaker" then
			-- frontmost is not FileMaker, so just get the 1st one we can find 
			-- (if multiple copies running, must make the one you want is frontmost to be sure it is used)
			try
				set fmAppProc to get first application process whose name contains "FileMaker"
			on error errMsg number errNum
				if errNum is -1719 then return false
				error errMsg number errNum
			end try
		end if
		return fmAppProc
	end tell
end getFmAppProc

