-- fmClip - Custom Function Paste As Needed
-- version 2025-08-20

(*

	Takes whatever custom functions are in the clipboard, copies the existing custom functions from an ALREADY-OPEN Manage Custom Functions window in the "target" file, then removes whatever functions that target already has, then pastes.  
	Restores the clipboard at end of script, if it was modified. 

HISTORY: 
	2025-08-20 ( danshockley ): Updated to work with Custom Function "Group" sub-folders by keeping desired functions, instead of a removal of those not in the desired list. Also improved the everything-already-there dialog.
	2024-07-22 ( danshockley ): The removeFunctionsFromXML handler now preserves CDATA tags, instead of converting to escaped entities. 
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
		
		
		-- get the NAMEs of the source functions:
		set sourceFunctionNames to listCustomFunctionNamesFromXML(sourceTextXML)
		
		tell application "System Events"
			
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
		set targetFunctionNames to listCustomFunctionNamesFromXML(targetTextXML)
		
		
		if debugMode then log "targetFunctionNames: " & targetFunctionNames
		
		-- get the (possibly) reduced set of functions, then put those in clipboard:
		set keepFunctionNames to listRemoveFromFirstList({sourceFunctionNames, targetFunctionNames})
		
		if (count of keepFunctionNames) is 0 then
			display dialog "All " & countSource & " custom functions from the clipboard already exist in the target." buttons {"OK"} default button "OK"
			set convertResult to true
		else
			-- there are CFs we need to paste
			-- So, modify the XML to keep only those needed:
			set keepResult to keepOnlyTheseFunctionsInXML(sourceTextXML, keepFunctionNames)
			set justPasteFunctionsXML to outputXML of keepResult
			
			-- put the XML into the clipboard
			set the clipboard to justPasteFunctionsXML
			
			-- modify the clipboard to include the objects to paste: 
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

on listCustomFunctionNamesFromXML(sourceStringXML)
	-- version 2025-08-20
	
	-- Returns a list of all @name values of CustomFunction nodes, at any depth
	
	set xmlDoc to current application's NSXMLDocument's alloc()'s initWithXMLString:sourceStringXML options:(current application's NSXMLNodePreserveCDATA) |error|:(missing value)
	
	-- Get all CustomFunction nodes anywhere
	set funcNodes to (xmlDoc's nodesForXPath:"//CustomFunction" |error|:(missing value))
	
	set funcNames to {}
	repeat with oneNode in funcNodes
		set nodeObj to contents of oneNode
		set nameAttr to (nodeObj's attributeForName:"name")
		if nameAttr is not missing value then
			set funcName to (nameAttr's stringValue()) as text
			set end of funcNames to funcName
		end if
	end repeat
	
	return funcNames
end listCustomFunctionNamesFromXML



on keepOnlyTheseFunctionsInXML(sourceStringXML, keepTheseNames)
	-- version 2025-08-20
	
	(* 
		Keeps only the CustomFunction nodes whose @name is in keepTheseNames.
		Groups are retained only if they contain (directly or indirectly) at least one kept function.
		Groups with no kept functions under them are removed, even if their parent Group survives.
		Returns {outputXML:"...", missingNodeNames:{...}}
		
	HISTORY: 
		2025-08-20 ( danshockley ): Created, interacting with ChatGPT.	
	*)
	
	
	set xmlDoc to current application's NSXMLDocument's alloc()'s initWithXMLString:sourceStringXML options:(current application's NSXMLNodePreserveCDATA) |error|:(missing value)
	
	-- Prepare a mutable list of found names
	set foundNames to {}
	
	-- Prune from root
	pruneChildren(xmlDoc's rootElement(), keepTheseNames, foundNames)
	
	-- Compute missing names
	set missingNodeNames to {}
	repeat with oneName in keepTheseNames
		if foundNames does not contain (oneName as text) then
			set end of missingNodeNames to (oneName as text)
		end if
	end repeat
	
	-- Return modified XML
	set rootElement to xmlDoc's rootElement()
	set modifiedXMLString to (rootElement's XMLStringWithOptions:(0)) as text
	
	return {outputXML:modifiedXMLString, missingNodeNames:missingNodeNames}
end keepOnlyTheseFunctionsInXML


on pruneChildren(parentNode, keepTheseNames, foundNames)
	set children to parentNode's children()
	repeat with child in children
		set childNode to contents of child
		
		-- Skip non-element nodes
		if ((childNode's |kind|()) as integer) = (current application's NSXMLElementKind) then
			set nodeName to (childNode's |name|()) as text
			
			if nodeName = "CustomFunction" then
				set nameAttr to (childNode's attributeForName:"name")
				if nameAttr is missing value then
					set funcName to ""
				else
					set funcName to (nameAttr's stringValue()) as text
				end if
				
				if keepTheseNames contains funcName then
					-- record that we saw this one
					if foundNames does not contain funcName then
						set end of foundNames to funcName
					end if
				else
					(childNode's detach())
				end if
				
			else if nodeName = "Group" then
				my pruneChildren(childNode, keepTheseNames, foundNames)
				-- Drop group if empty of CustomFunction descendants
				set keptFunctions to (childNode's nodesForXPath:".//CustomFunction" |error|:(missing value))
				if (count of keptFunctions) = 0 then
					(childNode's detach())
				end if
			end if
		end if
	end repeat
end pruneChildren


on listRemoveFromFirstList(prefs)
	-- version 1.2.1
	
	set {mainList, listOfItemsToRemove} to prefs
	
	set absentList to {}
	repeat with oneItem in mainList
		set oneItem to contents of oneItem
		if listOfItemsToRemove does not contain oneItem then copy oneItem to end of absentList
	end repeat
	
	return absentList
end listRemoveFromFirstList





