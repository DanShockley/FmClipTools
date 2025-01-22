-- fmClip - Duplicate ButtonBar Segment
-- version 2025-01-21, Daniel A. Shockley

(*
	Takes a return-delimited list of strings (optionally tab-delimited for multiple columns), then takes a FileMaker object in the clipboard and replicates it for each list item, then converts to multiple objects.
	
HISTORY:
	2025-01-21 ( danshockley ): Created.

*)

property ScriptName : "Duplicate FileMaker ButtonBar Segment"
property debugMode : false
property colSep : tab
property rowSep : return
global objTrans



on run
		
	set objTrans to run script alias (((((path to me as text) & "::") as alias) as string) & "fmObjectTranslator.applescript")
	(* If you need a self-contained script, copy the code from fmObjectTranslator into this script and use the following instead of the run script step above:
			set objTrans to fmObjectTranslator_Instantiate({})
		*)
	
	
	try
		
		-- init Translator properties:
		set shouldPrettify of objTrans to false
		set debugMode of objTrans to debugMode
		
		
		---------------------------------
		-- Look at clipboard and ask possible initial questions about it:
		
		set clipboardType to checkClipboardForObjects({}) of objTrans
		
		if clipboardType is false then
			display dialog "The clipboard does not contain a FileMaker ButtonBar Object, nor FileMaker objects of any type. Please copy a buttonbar into the clipboard." buttons {" Cancel "} default button " Cancel "
			return false
		end if
		
		set origXML to clipboardGetObjectsAsXML({}) of objTrans
		
		if currentCode of objTrans is not "XML2" then
			display dialog "The clipboard does not contain a ButtonBar Object, nor even layout objects. Please copy a buttonbar into the clipboard." buttons {" Cancel "} default button " Cancel "
			return false
		end if
		
		
		---------------------------------
		-- ASK which segment to duplicate:
		
		try
			tell application "System Events"
				set xmlDocument to make new XML data with data origXML
				set buttonBarObject to XML element "ButtonBarObj" of XML element "Object" of XML element "Layout" of XML element "fmxmlsnippet" of xmlDocument
				set segmentNodes to every XML element of buttonBarObject whose name is "Object"
				set countOrigSegments to count of segmentNodes
			end tell
		on error errMsg number errNum
			display dialog "The clipboard does not contain a ButtonBar Object. Please copy a buttonbar into the clipboard." buttons {" Cancel "} default button " Cancel "
			return false
		end try
		
		tell me to activate
		
		set segDialog to (display dialog "Which segment should be duplicated?" with title ScriptName default answer "" buttons {"Cancel", "Duplicate"} default button "Duplicate")
		set chosenSegNum to (text returned of segDialog) as number
		
		---------------------------------
		-- Duplicate the chosen segment:
		
		set xPath to "/fmxmlsnippet/Layout/Object/ButtonBarObj/Object[@type='Button'][" & chosenSegNum & "]"
		
		set newXML to xmlDuplicateNode({origXML:origXML, xPath:xPath})
		
		
		---------------------------------
		-- Put the new objects into the clipboard:
		
		set the clipboard to newXML
		
		clipboardConvertToFMObjects({}) of objTrans
		
		return newXML
		
	on error errMsg number errNum
		display dialog errMsg & " ErrNum: " & errNum
		return false
	end try
	
	
end run


on xmlDuplicateNode(prefs)
	-- version 2025-01-21
	
	script xdNode
		use framework "Foundation"
		use scripting additions
		
		set defaultPrefs to {origXML:"", xPath:""}
		set prefs to prefs & defaultPrefs
		set origXML to origXML of prefs
		set xPath to xPath of prefs
		
		try
			
			-- Convert the XML string to NSData
			set xmlNSString to current application's NSString's stringWithString:origXML
			set xmlData to xmlNSString's dataUsingEncoding:(current application's NSUTF8StringEncoding)
			
			-- Parse the XML from NSData
			set xmlDoc to current application's NSXMLDocument's alloc()'s initWithData:xmlData options:0 |error|:(missing value)
			
			set targetNodes to (xmlDoc's nodesForXPath:xPath |error|:(missing value))
			if (targetNodes's |count|() = 0) then error "Target node not found."
			
			-- Get the target node (2nd Object node with type="Button")
			set targetNode to targetNodes's firstObject()
			
			-- Duplicate the target node
			set duplicatedNode to targetNode's |copy|()
			
			-- Get the parent of the target node
			set parentNode to targetNode's |parent|()
			
			-- Find the index of the target node within its parent's children
			set children to parentNode's children()
			set targetIndex to (children's indexOfObject:targetNode)
			
			-- Insert the duplicated node immediately after the target node
			parentNode's insertChild:duplicatedNode atIndex:(targetIndex + 1)
			
			-- Retrieve the modified XML as a string
			set modifiedXML to (xmlDoc's XMLString()) as text
			
			
		on error errMsg number errNum
			error "Unable to xmlDuplicateNode - " & errMsg number errNum
		end try
		
	end script
	
	run xdNode
	return result
	
end xmlDuplicateNode



on getTextBefore(sourceTEXT, stopHere)
	-- version 1.1
	
	try
		set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, stopHere}
		if (count of text items of sourceTEXT) is 1 then
			set AppleScript's text item delimiters to oldDelims
			return ""
		else
			set the finalResult to text item 1 of sourceTEXT
		end if
		set AppleScript's text item delimiters to oldDelims
		return finalResult
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldDelims
		return "" -- return nothing if the stop text is not found
	end try
end getTextBefore




on getTextAfter(sourceTEXT, afterThis)
	-- version 1.2
	
	try
		set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {afterThis}}
		
		if (count of text items of sourceTEXT) is 1 then
			-- the split-string didn't appear at all
			set AppleScript's text item delimiters to oldDelims
			return ""
		else
			set the resultAsList to text items 2 thru -1 of sourceTEXT
		end if
		set AppleScript's text item delimiters to {afterThis}
		set finalResult to resultAsList as string
		set AppleScript's text item delimiters to oldDelims
		return finalResult
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldDelims
		return "" -- return nothing if the stop text is not found
	end try
end getTextAfter


on getTextUntilLast(sourceTEXT, stopHere)
	-- version 1.0
	
	try
		set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, stopHere}
		if (count of text items of sourceTEXT) is 1 then
			set AppleScript's text item delimiters to oldDelims
			-- not found, so return nothing:
			return ""
		else
			set the itemsBeforeLast to text items 1 thru -2 of sourceTEXT
		end if
		set finalResult to itemsBeforeLast as string
		set AppleScript's text item delimiters to oldDelims
		return finalResult
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldDelims
		return "" -- return nothing if the stop text is not found
	end try
end getTextUntilLast



