-- fmClip - Fields Drop Unused AE_or_VAL calcs
-- version 2024-09-14, Daniel A. Shockley

(*  
	Drops any unused auto-enter or validation calculations from Field objects in the clipboard. 

HISTORY:
	2024-09-14 ( danshockley ): Additional sub-node removal for when AutoEnter lookup is false and for when Validation valuelist is false (thanks Chris Irvine). Renamed handler to "stripUnusedSubNodes" instead of "stripUnusedCalcs".
	2024-09-13 ( danshockley ): Created. 
*)


use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

property debugMode : false


on run
	
	-- load the translator library:
	set transPath to (((((path to me as text) & "::") as alias) as string) & "fmObjectTranslator.applescript")
	set objTrans to run script (transPath as alias)
	(* If you need a self-contained script, copy the code from fmObjectTranslator into this script and use the following instead of the run script step above:
			set objTrans to fmObjectTranslator_Instantiate({})
		*)
	
	set debugMode of objTrans to true -- ONLY enable this while developing/testing
	
	try
		if debugMode then my logConsole(ScriptName, "Starting.")
		
		try
			set someXML to clipboardGetObjectsAsXML({}) of objTrans
			-- will get error 1024 if no FM objects of any kind.
			set originalClipboardFormat to currentCode of objTrans
			set clipboardWasText to false
			if originalClipboardFormat is "XMFD" then
				set nameNode1 to "Field"
			else if originalClipboardFormat is "XMTB" then
				set nameNode1 to "BaseTable"
			else
				error "The clipboard did not contain field/table objects." number 1025
			end if
			
		on error errMsg number errNum
			if errNum is 1024 then
				-- not FM objects, so try for plain text XML:
				set someXML to get the clipboard
				tell application "System Events"
					set xmlData to make new XML data with data someXML
					set nameNode1 to name of first XML element of first XML element of xmlData
					if nameNode1 is not "Field" and nameNode1 is not "BaseTable" then
						error "The clipboard did not contain field/table objects." number 1025
					end if
				end tell
				set clipboardWasText to true
			end if
		end try
		
		set modXML to stripUnusedSubNodes(someXML)
		
		set the clipboard to modXML
		
		if not clipboardWasText then
			-- put objects back into the clipboard (in addition to the text), to match what was incoming:
			clipboardConvertToFMObjects({}) of objTrans
		end if
		
		return modXML
		
	on error errMsg number errNum
		if errNum is -1700 then
			-- is not something that can be treated as text, so cannot have XML:
			return false
		else
			error errMsg number errNum
		end if
	end try
	
end run


on stripUnusedSubNodes(sourceStringXML)
	-- version 2024-09-14
	-- Either BaseTable or Field objects in XML Data.
	-- Loop over every field object, removing unused sub-nodes (calculation, valuelist, lookup) that are not used from AutoEnter or Validation nodes.
	
	-- Parse the XML and preserve CDATA sections
	set xmlDoc to current application's NSXMLDocument's alloc()'s initWithXMLString:sourceStringXML options:(current application's NSXMLNodePreserveCDATA) |error|:(missing value)
	
	set xpath to "//AutoEnter[@calculation='False']/Calculation"
	set nodesToRemove to (xmlDoc's nodesForXPath:xpath |error|:(missing value))
	repeat with node in nodesToRemove
		node's detach()
	end repeat
	
	set xpath to "//AutoEnter[@lookup='False']/Lookup"
	set nodesToRemove to (xmlDoc's nodesForXPath:xpath |error|:(missing value))
	repeat with node in nodesToRemove
		node's detach()
	end repeat
	
	set xpath to "//Validation[@calculation='False']/Calculation"
	set nodesToRemove to (xmlDoc's nodesForXPath:xpath |error|:(missing value))
	repeat with node in nodesToRemove
		node's detach()
	end repeat
	
	set xpath to "//Validation[@valuelist='False']/ValueList"
	set nodesToRemove to (xmlDoc's nodesForXPath:xpath |error|:(missing value))
	repeat with node in nodesToRemove
		node's detach()
	end repeat
	
	-- Extract inner XML of the root element
	set rootElement to xmlDoc's rootElement()
	set modifiedXMLString to (rootElement's XMLStringWithOptions:(0))
	
	return modifiedXMLString as text
	
end stripUnusedSubNodes









