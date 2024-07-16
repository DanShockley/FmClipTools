-- fmClip - Custom Function Paste Or Update
-- version 2024-07-16

(*

	Takes whatever custom functions are in the clipboard, and then:
	 - Pastes every custom function that does not yet exist in the target (like the As Needed script)
	 - For every function that DOES already exist, compare it to what was in the clipboard, then loop over those, opening up the existing function and pasting in the “new” calculation code for each, then saving.
	 Includes a dialog at the end saying how many were pasted and how many were updated.
	Restores the clipboard at end of script, if it was modified. 

HISTORY: 
	2024-07-16 ( danshockley ): Finished building first version. 
	2024-07-15 ( danshockley ): first created. 

*)

use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

property winNameManageCFs : "Manage Custom Functions"
property snippetHead : "<fmxmlsnippet type=\"FMObjectList\">"
property snippetFoot : "</fmxmlsnippet>"


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
		
		set fmProcID to my getFmAppProcessID()
		tell application "System Events"
			-- get the NAMEs of the source functions:
			set sourceXMLData to make new XML data with properties {text:sourceTextXML}
			set sourceFunctionNames to value of XML attribute "name" of (every XML element of XML element 1 of sourceXMLData whose name is "CustomFunction")
			
			-- get the target's existing functions into the clipboard:
			tell process id fmProcID
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
		
		-- now, read out what functions the target already has:
		checkClipboardForObjects({}) of objTrans
		set targetTextXML to clipboardGetObjectsasXML({}) of objTrans
		tell application "System Events"
			set targetXMLData to make new XML data with properties {text:targetTextXML}
			set targetFunctionNames to value of XML attribute "name" of (every XML element of XML element 1 of targetXMLData whose name is "CustomFunction")
		end tell
		
		-- get the (possibly) reduced set of functions, then put those in clipboard:
		set pasteXML to removeFunctionsFromXML(sourceTextXML, targetFunctionNames)
		
		tell application "System Events"
			set pasteXMLData to make new XML data with properties {text:pasteXML}
			set pasteFunctionNames to value of XML attribute "name" of (every XML element of XML element 1 of pasteXMLData whose name is "CustomFunction")
		end tell
		
		if (count of pasteFunctionNames) is greater than 0 then
			-- NEED TO PASTE SOME:		
			set the clipboard to pasteXML
			set convertResult to clipboardConvertToFMObjects({}) of objTrans
			
			tell application "System Events"
				tell process id fmProcID
					set frontmost to true
					delay 0.5
					click menu item "Paste" of menu "Edit" of menu bar 1
				end tell
			end tell
			set oneResultMsg to ("Pasted " & (count of pasteFunctionNames) & " functions.") as string
			copy oneResultMsg to end of resultMsgList
			
		end if
		
		
		-- ANY TO UPDATE? 
		-- see which functions, if any, need to be updated:
		tell application "System Events"
			-- loop over the SOURCE functions, seeing if they need to be updated:
			set sourceNodes to (every XML element of XML element 1 of sourceXMLData whose name is "CustomFunction")
			
			set countUpdated to 0
			repeat with oneSourceNode in sourceNodes
				set oneSourceName to value of XML attribute "name" of oneSourceNode
				if oneSourceName is in targetFunctionNames then
					-- ALREADY existed, so see if we need to update:
					set oneSourceCALC to (value of XML element "Calculation" of oneSourceNode)
					
					set targetFunctionCALC to (value of XML element "Calculation" of (first XML element of XML element 1 of targetXMLData whose value of XML attribute "name" is oneSourceName))
					if oneSourceCALC is not equal to targetFunctionCALC then
						-- DIFF, SO NEED TO UPDATE THIS CALC:
						my updateExistingCustomFunction({functionName:oneSourceName, calcCode:oneSourceCALC, fmProcID:fmProcID})
						set countUpdated to countUpdated + 1
					end if
				end if
			end repeat
			if countUpdated is greater than 0 then
				set oneResultMsg to ("Updated " & (countUpdated) & " functions.") as string
				copy oneResultMsg to end of resultMsgList
			end if
		end tell
		
		if restoreClipboard then
			set the clipboard to sourceTextXML
			clipboardConvertToFMObjects({}) of objTrans
		end if
		
		set resultDialogMsg to unParseChars(resultMsgList, return)
		display dialog resultDialogMsg buttons {"OK"} default button "OK"
		
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
	-- version 2024-07-15
	
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
				select (first row of (table 1 of scroll area 1 of window 1) whose name of static text 1 is functionName of prefs)
				delay 0.05
				set selectedFunctionName to value of static text 1 of (first row of table 1 of scroll area 1 of window 1 whose selected is true)
				if functionName of prefs is not equal to selectedFunctionName then
					error "failed to select function even though function exists" number -1024
				end if
				
				set editButton to first button of window 1 whose name begins with "Edit"
				
				click editButton
				delay 0.1
				if name of window 1 is not "Edit Custom Function" then
					error "failed to OPEN Edit window?" number -1024
				end if
				
				-- SET THE CALCULATION CODE:
				set value of text area 1 of scroll area 4 of window 1 to calcCode of prefs
				
				-- SAVE the CALC EDIT:
				click (first button of window 1 whose name begins with "OK")
				delay 0.1
				
				if name of window 1 is not "Edit Custom Function" then
					error "failed to CLOSE Edit window?" number -1024
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



on removeFunctionsFromXML(sourceStringXML, removeNames)
	
	-- now, generate a (possibly) REDUCED XML block:
	set {theXMLDoc, theError} to current application's NSXMLDocument's alloc()'s initWithXMLString:sourceStringXML options:0 |error|:(reference)
	if theXMLDoc is missing value then error (theError's localizedDescription() as text)
	set snippetNode to theXMLDoc's childAtIndex:0
	set sourceCount to snippetNode's childCount as integer
	set newXML to snippetHead
	repeat with nodeIndex from 0 to sourceCount - 1
		set oneNode to (snippetNode's childAtIndex:nodeIndex)
		set nameAttr to (oneNode's attributeForName:"name")
		set functionName to nameAttr's stringValue as text
		if functionName is not in removeNames then
			set functionXML to oneNode's XMLString as text
			set newXML to newXML & return & functionXML
		end if
	end repeat
	set newXML to newXML & return & snippetFoot
	
	if newXML is equal to snippetHead & return & snippetFoot then
		return ""
	else
		return newXML
	end if
	
end removeFunctionsFromXML


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
