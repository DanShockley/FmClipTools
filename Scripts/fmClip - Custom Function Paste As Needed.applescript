-- fmClip - Custom Function Paste As Needed
-- version 2024-07-22

(*

	Takes whatever custom functions are in the clipboard, copies the existing custom functions from an ALREADY-OPEN Manage Custom Functions window in the "target" file, then removes whatever functions that target already has, then pastes.  
	Restores the clipboard at end of script, if it was modified. 

HISTORY: 
	2024-07-22 ( danshockley ): The removeFunctionsFromXML handler now preserves CDATA tags, isntead of converting to escaped entities. 
	2024-07-22 ( danshockley ): The snippetHead and snippetFoot properties are no longer needed. 
	2024-07-22 ( danshockley ): Updated comments. 
	2024-07-16 ( danshockley ): Better variable names for "source" values. 
	2024-07-16 ( danshockley ): Restore original clipboard objects at end of script, if it was modified. 
	2024-07-15 ( danshockley ): Target the FileMaker app by process ID, NOT by a reference to a process, since the dereference loses the intended target. In removeFunctionsFromXML, if none left, return empty string, not header/footer with no functions in between. 
	2023-05-24 ( danshockley ): Added getFmAppProc to avoid being tied to one specific "FileMaker" app name. 
	2022-08-16 ( danshockley ): first created. 

*)

use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

property debugMode : false
property ScriptName : "Custom Function Paste As Needed"

property winNameManageCFs : "Manage Custom Functions"

on run
	
	try
		set restoreClipboard to false
		-- load the translator library:
		set transPath to (((((path to me as text) & "::") as alias) as string) & "fmObjectTranslator.applescript")
		set objTrans to run script (transPath as alias)
		(* If you need a self-contained script, copy the code from fmObjectTranslator into this script and use the following instead of the run script step above:
			set objTrans to fmObjectTranslator_Instantiate({})
		*)
		
		-- check for source functions:
		checkClipboardForObjects({}) of objTrans
		if currentCode of objTrans is not "XMFN" then
			error "The clipboard does not contain FileMaker custom functions." number -1024
		end if
		
		-- get the source functions:
		set sourceTextXML to clipboardGetObjectsasXML({}) of objTrans
		
		tell application "System Events"
			-- get the NAMEs of the source functions:
			set sourceXMLData to make new XML data with properties {text:sourceTextXML}
			set sourceFunctionNames to value of XML attribute "name" of (every XML element of XML element 1 of sourceXMLData whose name is "CustomFunction")
			
			-- get the target's existing functions into the clipboard:
			set fmAppProcID to my getFmAppProcessID()
			tell process id fmAppProcID
				set frontmost to true
				set frontWinName to name of window 1
				if frontWinName does not start with winNameManageCFs then
					error "You must have the " & winNameManageCFs & " window open in your target database." number -1024
				end if
				
				click menu item "Select All" of menu "Edit" of menu bar 1
				click menu item "Copy" of menu "Edit" of menu bar 1
				delay 0.5
				set restoreClipboard to true -- just modified clipboard, so should restore at end
			end tell
		end tell
		
		set countSource to count of sourceFunctionNames
		
		-- now, read out what functions the target already has:
		checkClipboardForObjects({}) of objTrans
		set targetTextXML to clipboardGetObjectsasXML({}) of objTrans
		tell application "System Events"
			set targetXMLData to make new XML data with properties {text:targetTextXML}
			set targetFunctionNames to value of XML attribute "name" of (every XML element of XML element 1 of targetXMLData whose name is "CustomFunction")
		end tell
		
		if debugMode then log "targetFunctionNames: " & targetFunctionNames
		
		-- get the (possibly) reduced set of functions, then put those in clipboard:
		set justFunctionsXML to removeFunctionsFromXML(sourceTextXML, targetFunctionNames)
		
		if length of justFunctionsXML is 0 then
			display dialog "All " & countSource & " custom functions from the clipboard already exist in the target."
		else
			set the clipboard to justFunctionsXML
			
			set convertResult to clipboardConvertToFMObjects({}) of objTrans
			
			-- PASTE only the needed functions:
			tell application "System Events"
				tell process id fmAppProcID
					set frontmost to true
					delay 0.5
					click menu item "Paste" of menu "Edit" of menu bar 1
					delay 0.5
				end tell
			end tell
		end if
		
		if restoreClipboard then
			set the clipboard to sourceTextXML
			clipboardConvertToFMObjects({}) of objTrans
		end if
		
		return convertResult
		
	on error errMsg number errNum
		if restoreClipboard then
			set the clipboard to sourceTextXML
			clipboardConvertToFMObjects({}) of objTrans
		end if
		display dialog errMsg
		return false
	end try
	
	
end run

on getFmAppProcessID()
	-- version 2024-07-15
	-- Gets process ID of "FileMaker" app that is frontmost (if any), otherwise the 1st one available.
	set appNameMatchString to "FileMaker"
	-- [ NOTE: the code below is identical to the function "getAppProcessID" ]
	
	tell application "System Events"
		set frontAppName to name of first application process whose frontmost is true
		set appProcID to id of first application process whose frontmost is true
		-- ^^^ we MUST get this HERE - we MUST NOT try to get a reference to the frontmost app, since the dereference will then talk to some OTHER app.
		if frontAppName does not contain appNameMatchString then
			-- frontmost does not match, so just get the 1st one we can find.
			-- (when using, you should probably tell it to set frontmost to true, to be sure)
			try
				set appProcID to id of first application process whose name contains appNameMatchString
			on error errMsg number errNum
				error errMsg number errNum
			end try
		end if
		return appProcID
	end tell
	
end getFmAppProcessID



on removeFunctionsFromXML(sourceStringXML, removeNames)
	-- version 2024-07-22
	
	-- Removes any CustomFunction nodes with one of the names to remove.
	
	-- Parse the XML and preserve CDATA sections
	set xmlDoc to current application's NSXMLDocument's alloc()'s initWithXMLString:sourceStringXML options:(current application's NSXMLNodePreserveCDATA) |error|:(missing value)
	
	repeat with oneRemoveName in removeNames
		set xpath to "//CustomFunction[@name='" & oneRemoveName & "']"
		set nodesToRemove to (xmlDoc's nodesForXPath:xpath |error|:(missing value))
		repeat with node in nodesToRemove
			node's detach()
		end repeat
	end repeat
	-- Extract inner XML of the root element
	set rootElement to xmlDoc's rootElement()
	set modifiedXMLString to (rootElement's XMLStringWithOptions:(0))
	
	return modifiedXMLString as text
	
end removeFunctionsFromXML






