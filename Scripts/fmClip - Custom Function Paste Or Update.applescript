-- fmClip - Custom Function Paste Or Update
-- version 2025-08-20

(*

	Takes whatever custom functions are in the clipboard, and then:
	 - Pastes every custom function that does not yet exist in the target (like the As Needed script)
	 - For every function that DOES already exist, compare it to what was in the clipboard, then loop over those, opening up the existing function and pasting in the “new” calculation code for each, then saving.
	Includes a dialog at the end saying how many were pasted and how many were updated.
	Restores the clipboard at end of script, if it was modified. 


HISTORY: 
	2025-08-20 ( danshockley ): Updated to work with Custom Function "Group" sub-folders by keeping desired functions, instead of a removal of those not in the desired list. 
	2025-08-15 ( danshockley ): Added explanation to the Update list picker to use command-click. Tried to bring picker to front, but that did not work. 
	2024-12-03 ( danshockley ): Sometimes the modification of the clipboard to check target was not noticed, so added a "clipboard info" check to force notice of modification.
	2024-07-22 ( danshockley ): The removeFunctionsFromXML handler now preserves CDATA tags, instead of converting to escaped entities. 
	2024-07-22 ( danshockley ): The snippetHead and snippetFoot properties are no longer needed. 
	2024-07-22 ( danshockley ): Updated comments. Added more error handling info. Gather the "update" list, then TELL the user which will be updated so they can confirm/refuse, by picking ALL, or from the list. Added debugMode property for testing purposes (set to false once testing is done).
	2024-07-16 ( danshockley ): Finished building first version. 
	2024-07-15 ( danshockley ): first created. 

*)

use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

property debugMode : false
property ScriptName : "Custom Function Paste Or Update"

property winNameManageCFs : "Manage Custom Functions"


on run
	
	set resultMsgList to {}
	
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
		set countSource to count of sourceFunctionNames
		
		
		set fmProcID to my getFmAppProcessID()
		tell application "System Events"
			-- get the target's existing functions into the clipboard:
			tell process id fmProcID
				set frontmost to true
				set frontWinName to name of window 1
				if frontWinName does not start with winNameManageCFs then
					error "You must have the " & winNameManageCFs & " window open in your target database." number -1024
				end if
				click menu item "Select All" of menu "Edit" of menu bar 1
				delay 1
				click menu item "Copy" of menu "Edit" of menu bar 1
				delay 1
				set restoreClipboard to true -- just modified clipboard, so should restore at end
			end tell
		end tell
		
		clipboard info -- deliberately access the clipboard so the modified content is noticed.
		
		try
			-- Read Target Functions: now, read out what functions the target already has:
			checkClipboardForObjects({}) of objTrans
			set targetTextXML to clipboardGetObjectsasXML({}) of objTrans
			set targetFunctionNames to listCustomFunctionNamesFromXML(targetTextXML)
		on error errMsg number errNum
			set errMsg to errMsg & " [Read Target Functions]."
			error errMsg number errNum
		end try
		
		try
			-- FUNCTIONS TO PASTE: get the (possibly) reduced set of functions, then put those in clipboard:
			set pasteFunctionNames to listRemoveFromFirstList({sourceFunctionNames, targetFunctionNames})
			
			if (count of pasteFunctionNames) is 0 then
				copy "No new functions were pasted." to end of resultMsgList
			else
				-- there are CFs we need to paste
				-- So, modify the XML to keep only those needed:
				set keepResult to keepOnlyTheseFunctionsInXML(sourceTextXML, pasteFunctionNames)
				set pasteFunctionsXML to outputXML of keepResult
				
				-- put the XML into the clipboard
				set the clipboard to pasteFunctionsXML
				
				-- modify the clipboard to include the objects to paste: 
				set convertResult to clipboardConvertToFMObjects({}) of objTrans
				
				-- PASTE only the needed functions:
				tell application "System Events"
					tell process id fmProcID
						set frontmost to true
						delay 0.5
						click menu item "Paste" of menu "Edit" of menu bar 1
						delay 0.5
					end tell
				end tell
				set oneResultMsg to ("Pasted " & (count of pasteFunctionNames) & " functions.") as string
				copy oneResultMsg to end of resultMsgList
			end if
			
		on error errMsg number errNum
			set errMsg to errMsg & " [PASTE FUNCTIONS]."
			error errMsg number errNum
		end try
		
		
		
		try
			-- ANY TO UPDATE? 
			-- see which functions, if any, need to be updated:
			set differentFunctionNames to {}
			repeat with oneSourceName in sourceFunctionNames
				
				if oneSourceName is in targetFunctionNames then
					-- ALREADY existed, so see if we need to update:
					set oneSourceCALC to getCalculationTextForFunction(sourceTextXML, oneSourceName)
					set targetFunctionCALC to getCalculationTextForFunction(targetTextXML, oneSourceName)
					if oneSourceCALC is equal to targetFunctionCALC then
						-- SAME, so no need to do anything. 
						if debugMode then log "oneSourceName (SAME CALCS!): " & oneSourceName
					else
						-- DIFF, so add to the "diff" list:
						copy oneSourceName to end of differentFunctionNames
						if debugMode then log "oneSourceName: " & oneSourceName
						if debugMode then log "oneSourceCALC: " & oneSourceCALC
						if debugMode then log "targetFunctionCALC: " & targetFunctionCALC
						
					end if
				end if
			end repeat
			
		on error errMsg number errNum
			set errMsg to errMsg & " [GET FUNCTIONS TO UPDATE]."
			error errMsg number errNum
		end try
		
		try
			-- UPDATE FUNCTIONS:
			
			set countDiff to count of differentFunctionNames
			if countDiff is 0 then
				copy "No existing functions were different, so none needed to be updated." to end of resultMsgList
				
			else
				set dialogChooseUpdate to choose from list differentFunctionNames with title "Update existing functions?" with prompt "The following " & countDiff & " custom functions already exist in the target file, and are DIFFERENT from the source. By default, those will all be updated, but you can choose to deselect any that should not, or Cancel doing any updates of existing functions." & return & "Command-click to select/deselect items." default items differentFunctionNames OK button name "Update" with multiple selections allowed
				
				if class of dialogChooseUpdate is equal to class of false then
					-- they chose to CANCEL, so do not update any.
					set sourceNamesToUpdate to {}
				else
					set sourceNamesToUpdate to dialogChooseUpdate
				end if
				set countToUpdate to count of sourceNamesToUpdate
				
				set countUpdated to 0
				repeat with oneSourceName in sourceNamesToUpdate
					set oneSourceName to contents of oneSourceName
					set oneSourceCALC to getCalculationTextForFunction(sourceTextXML, oneSourceName)
					
					my updateExistingCustomFunction({functionName:oneSourceName, calcCode:oneSourceCALC, fmProcID:fmProcID})
					set countUpdated to countUpdated + 1
				end repeat
				
				
				if countUpdated is 0 then
					copy "No existing functions were updated." to end of resultMsgList
				else
					set oneResultMsg to ("Updated " & (countUpdated) & " functions.") as string
					copy oneResultMsg to end of resultMsgList
				end if
			end if
			
		on error errMsg number errNum
			set errMsg to errMsg & " [UPDATE FUNCTIONS]."
			error errMsg number errNum
		end try
		
		
		
		try
			-- RESTORE CLIPBOARD: 
			if restoreClipboard then
				set the clipboard to sourceTextXML
				clipboardConvertToFMObjects({}) of objTrans
			end if
		on error errMsg number errNum
			set errMsg to errMsg & " [RESTORE CLIPBOARD]."
			error errMsg number errNum
		end try
		
		set resultDialogMsg to unParseChars(resultMsgList, return)
		display dialog resultDialogMsg with title ScriptName buttons {"OK"} default button "OK"
		
		return true
		
		
	on error errMsg number errNum
		if restoreClipboard then
			set the clipboard to sourceTextXML
			clipboardConvertToFMObjects({}) of objTrans
		end if
		
		display dialog errMsg buttons {" Cancel "} default button " Cancel "
		return false
	end try
	
	
end run


on updateExistingCustomFunction(prefs)
	-- version 2025-08-20
	
	(*
	HISTORY:
		2025-08-20 ( danshockley ): Updated to ALSO work with FileMaker Pro 2025, using its search field to handle outline instead of simple table list, when that is relevant.
	*)
	
	set defaultPrefs to {functionName:null, calcCode:null}
	set prefs to prefs & defaultPrefs
	try
		set fmProcID to fmProcID of prefs
	on error
		set fmProcID to my getFmAppProcessID()
	end try
	
	tell application "System Events"
		tell process id fmProcID
			try
				if not frontmost then
					set frontmost to true
					delay 0.5
				end if
				
				try
					set searchBox to first text field of window 1 whose accessibility description is "Find"
					set useOutline to true
				on error errMsg number errNum
					-- probably older version of FileMaker with a simple table/list:
					set useOutline to false
				end try
				
				if useOutline then
					-- Outline, FileMaker Pro 2025 and later:
					set focused of searchBox to true
					delay 0.3
					keystroke "a" using command down
					keystroke (functionName of prefs)
					delay 0.2
					select (first row of item 1 of outline of scroll area 1 of window 1)
					delay 0.2
					
				else
					-- use the pre-2025 table/list interface:
					select (first row of (table 1 of scroll area 1 of window 1) whose name of static text 1 is functionName of prefs)
					delay 0.1
					set selectedFunctionName to value of static text 1 of (first row of table 1 of scroll area 1 of window 1 whose selected is true)
					if functionName of prefs is not equal to selectedFunctionName then
						error "failed to select function even though function exists" number -1024
					end if
					
				end if
				
				set editButton to first button of window 1 whose name begins with "Edit"
				
				click editButton
				delay 0.2
				
				if name of window 1 is not "Edit Custom Function" then
					error "failed to OPEN Edit window?" number -1024
				end if
				
				-- SET THE CALCULATION CODE:
				set value of text area 1 of scroll area 4 of window 1 to calcCode of prefs
				
				-- SAVE the CALC EDIT:
				click (first button of window 1 whose name begins with "OK")
				delay 0.2
				
				
				if name of window 1 is "Edit Custom Function" then
					error "failed to CLOSE Edit window?" number -1024
				end if
				
				if useOutline then
					-- Outline, FileMaker Pro 2025 and later:
					-- clear the search box
					set focused of searchBox to true
					delay 0.2
					keystroke "a" using command down
					key code 51 -- delete					
				end if
				
			on error
				return false
			end try
		end tell
	end tell
	
end updateExistingCustomFunction


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



on getCalculationTextForFunction(sourceStringXML, functionName)
	-- Returns the text inside the <Calculation> node (usually CDATA) for a given CustomFunction name
	-- Returns missing value if not found
	
	-- Parse XML
	set xmlDoc to current application's NSXMLDocument's alloc()'s initWithXMLString:sourceStringXML options:(current application's NSXMLNodePreserveCDATA) |error|:(missing value)
	
	-- XPath: find the Calculation node under the CustomFunction with given name
	set xpathExpr to "//CustomFunction[@name='" & functionName & "']/Calculation"
	set calcNodes to (xmlDoc's nodesForXPath:xpathExpr |error|:(missing value))
	
	if (count of calcNodes) > 0 then
		set calcNode to item 1 of calcNodes
		-- Return just the string value (CDATA or text content)
		set calcText to (calcNode's stringValue()) as text
		return calcText
	else
		return missing value
	end if
end getCalculationTextForFunction

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







on unParseChars(thisList, newDelim)
	-- version 1.2, Daniel A. Shockley, https://www.danshockley.com
	set oldDelims to AppleScript's text item delimiters
	try
		set AppleScript's text item delimiters to the {newDelim as string}
		set the unparsedText to thisList as string
		set AppleScript's text item delimiters to oldDelims
		return unparsedText
	on error errMsg number errNum
		try
			set AppleScript's text item delimiters to oldDelims
		end try
		error "ERROR: unParseChars() handler: " & errMsg number errNum
	end try
end unParseChars
