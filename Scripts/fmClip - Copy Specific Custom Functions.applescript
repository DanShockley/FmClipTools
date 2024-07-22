-- fmClip - Copy Specific Custom Functions
-- version 2024-07-22

(*

	Asks for a list of custom function names, copies the existing custom functions from an ALREADY-OPEN Manage Custom Functions window in the "source" file, then modifies clipboard to contain ONLY the specified functions.  

HISTORY: 
	2024-07-22 ( danshockley ): The removeFunctionsFromXML handler now preserves CDATA tags, isntead of converting to escaped entities. 
	2024-07-22 ( danshockley ): The snippetHead and snippetFoot properties are no longer needed. 
	2024-07-22 ( danshockley ): Added more error handling info. Says how many were copied at end of script.
	2024-07-22 ( danshockley ): Fixed description. Updated the removeFunctionsFromXML handler. 
	2024-07-15 ( danshockley ): Target the FileMaker app by process ID, NOT by a reference to a process, since the dereference loses the intended target. 
	2024-03-15 ( danshockley ): Removed parens around "the clipboard" when setting, since that was causing an error - ugh. 
	2023-05-24 ( danshockley ): Added getFmAppProc to avoid being tied to one specific "FileMaker" app name, and to avoid going by the bundle ID. 
	2023-03-10 ( danshockley ): remove embedded fmObjectTranslator. 
	2023-02-07 ( danshockley ): first created. 

*)


use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

property debugMode : false
property ScriptName : "Copy Specific Custom Functions"

property winNameManageCFs : "Manage Custom Functions"


on run
	
	try
		
		-- load the translator library:
		set transPath to (((((path to me as text) & "::") as alias) as string) & "fmObjectTranslator.applescript")
		set objTrans to run script (transPath as alias)
		(* If you need a self-contained script, copy the code from fmObjectTranslator into this script and use the following instead of the run script step above:
			set objTrans to fmObjectTranslator_Instantiate({})
		*)
		
		try
			-- DESIRED FUNCTIONS: get the list of desired function names:
			set dialogTitle to "Clipboard FileMaker - Copy Which Functions?"
			
			set searchForDialog to (display dialog "Enter the list of custom functions names you want to copy. The list can be return-delimited or comma-delimited." with title dialogTitle default answer "" buttons {"Cancel", "Copy"} default button "Copy")
			
			set desiredFunctionNames to text returned of searchForDialog
			set desiredFunctionNames to replaceSimple({desiredFunctionNames, ", ", return})
			set desiredFunctionNames to replaceSimple({desiredFunctionNames, ",", return})
			set desiredFunctionNames to paragraphs of desiredFunctionNames
		on error errMsg number errNum
			set errMsg to errMsg & " [DESIRED FUNCTIONS]."
			error errMsg number errNum
		end try
		
		
		try
			-- COPY FUNCTIONS:
			tell application "System Events"
				-- get the target's existing functions into the clipboard:
				set fmAppProcID to my getFmAppProcessID()
				tell process id fmAppProcID
					set frontmost to true
					set frontWinName to name of window 1
					if frontWinName does not start with winNameManageCFs then
						error "You must have the " & winNameManageCFs & " window open in your target database." number -1024
					end if
					delay 0.5
					
					(* NOTE: IDEALLY, we would select only the functions specified, but UI Scripting has a bug where setting selected=true for one row ALWAYS deselects other rows. So, instead we must SELECT ALL, COPY, REMOVE unwanted, SET CLIPBOARD. 
				*)
					click menu item "Select All" of menu "Edit" of menu bar 1
					click menu item "Copy" of menu "Edit" of menu bar 1
					delay 2
				end tell
			end tell
		on error errMsg number errNum
			set errMsg to errMsg & " [COPY FUNCTIONS]."
			error errMsg number errNum
		end try
		
		try
			-- CHECK CLIPBOARD: make sure functions were copied:
			checkClipboardForObjects({}) of objTrans
			if currentCode of objTrans is not "XMFN" then
				error "The clipboard does not contain FileMaker custom functions - unable to copy existing functions." number -1024
			end if
		on error errMsg number errNum
			set errMsg to errMsg & " [CHECK CLIPBOARD]."
			error errMsg number errNum
		end try
		
		try
			-- SOURCE FUNCTIONS INFO:
			set sourceTextXML to clipboardGetObjectsasXML({}) of objTrans
			
			tell application "System Events"
				-- get the NAMEs of the source functions:
				set sourceXMLData to make new XML data with properties {text:sourceTextXML}
				set sourceFunctionNames to value of XML attribute "name" of (every XML element of XML element 1 of sourceXMLData whose name is "CustomFunction")
			end tell
		on error errMsg number errNum
			set errMsg to errMsg & " [SOURCE FUNCTIONS INFO]."
			error errMsg number errNum
		end try
		
		try
			-- REDUCE FUNCTIONS: get the (possibly) reduced set of functions, then put only those desired objects into the clipboard:
			-- just the list of functions we do NOT want from the source:
			set removeFunctionNames to listRemoveFromFirstList({sourceFunctionNames, desiredFunctionNames})
			
			set justDesiredFunctionsXML to removeFunctionsFromXML(sourceTextXML, removeFunctionNames)
			
			tell application "System Events"
				set the clipboard to justDesiredFunctionsXML
			end tell
			set convertResult to clipboardConvertToFMObjects({}) of objTrans
			
		on error errMsg number errNum
			set errMsg to errMsg & " [REDUCE FUNCTIONS]."
			error errMsg number errNum
		end try
		
		set copiedFunctionNames to listRemoveFromFirstList({sourceFunctionNames, removeFunctionNames})
		set missingFunctionNames to listRemoveFromFirstList({desiredFunctionNames, copiedFunctionNames})
		try
			set countCopied to count of copiedFunctionNames
			set countMissing to count of missingFunctionNames
			set dialogMsg to "There were " & countCopied & " functions were copied to your clipboard"
			if countMissing is greater than 0 then
				set dialogMsg to dialogMsg & ". WARNING! " & countMissing & " of your desired functions did NOT exist in the source file, so they will NOT be available to paste/update in target file: " & return & my unParseChars(missingFunctionNames, return)
				set dialogBtn to "Understood"
			else
				set dialogMsg to dialogMsg & ", so you can go paste into a target file."
				set dialogBtn to "OK"
			end if
			display dialog dialogMsg buttons {dialogBtn} default button dialogBtn
		end try
		return result
		
		
	on error errMsg number errNum
		if errNum is -128 then
			-- user canceled, so no need to show that to them.
		else
			display dialog errMsg
		end if
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

on replaceSimple(prefs)
	-- version 1.4
	
	set defaultPrefs to {considerCase:true}
	
	if class of prefs is list then
		if (count of prefs) is greater than 3 then
			-- get any parameters after the initial 3
			set prefs to {sourceTEXT:item 1 of prefs, oldChars:item 2 of prefs, newChars:item 3 of prefs, considerCase:item 4 of prefs}
		else
			set prefs to {sourceTEXT:item 1 of prefs, oldChars:item 2 of prefs, newChars:item 3 of prefs}
		end if
		
	else if class of prefs is not equal to (class of {someKey:3}) then
		-- Test by matching class to something that IS a record to avoid FileMaker namespace conflict with the term "record"
		
		error "The parameter for 'replaceSimple()' should be a record or at least a list. Wrap the parameter(s) in curly brackets for easy upgrade to 'replaceSimple() version 1.3. " number 1024
		
	end if
	
	
	set prefs to prefs & defaultPrefs
	
	
	set considerCase to considerCase of prefs
	set sourceTEXT to sourceTEXT of prefs
	set oldChars to oldChars of prefs
	set newChars to newChars of prefs
	
	set sourceTEXT to sourceTEXT as string
	
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to the oldChars
	if considerCase then
		considering case
			set the parsedList to every text item of sourceTEXT
			set AppleScript's text item delimiters to the {(newChars as string)}
			set the newText to the parsedList as string
		end considering
	else
		ignoring case
			set the parsedList to every text item of sourceTEXT
			set AppleScript's text item delimiters to the {(newChars as string)}
			set the newText to the parsedList as string
		end ignoring
	end if
	set AppleScript's text item delimiters to oldDelims
	return newText
	
end replaceSimple


on unParseChars(thisList, newDelim)
	-- version 1.2, Daniel A. Shockley, http://www.danshockley.com
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





