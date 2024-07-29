-- fmClip - Open Snippets Folder
-- version 1.0.0, Matt Petrowsky

(*
	Simply opens the Snippets folder for the purpose of managing snippet files.

HISTORY:
	1.0 - initial commit
*)


-- Create path to Snippets folder.
set myFolder to ((((path to me as text) & "::") as alias) as string)
set stripLevel to text 1 thru ((length of myFolder) - 1) of myFolder -- strip trailing ":"
set parentFolder to text 1 thru -((offset of ":" in (reverse of characters of stripLevel) as string) + 1) of stripLevel

set snippetsFolder to parentFolder & ":Snippets:" as alias
set snippetsPath to POSIX path of snippetsFolder

set command to "open " & snippetsPath

try
    set commandResult to do shell script command
on error errMsg
    display dialog "An error occurred: " & errMsg buttons {"OK"} default button "OK" with icon stop
end try
