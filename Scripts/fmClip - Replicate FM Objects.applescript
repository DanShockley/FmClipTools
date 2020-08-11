-- Clipboard - Replicate FileMaker Objects
-- version 1.2, Daniel A. Shockley

(*
	Takes a return-delimited list of strings (optionally tab-delimited for multiple columns), then takes a FileMaker object in the clipboard and replicates it for each list item, then converts to multiple objects.
	
HISTORY:
	1.3 - 2020-08-11 ( dshockley ): Fix to at least be ABLE to replicate layout objects generally (they will be srtacked on top of each other in the same location), since simplistic replication failed to work. Improved comments, dialog message. 
	1.2 - 2018-04-04 ( dshockley/eshagdar ): load fmObjectTranslator code by reference instead of embedded.
	1.1 - 2017-12-18 ( dshockley ): updated fmObjTrans to 3.9.4 to support layout objects. Can now replicate ButtonBar segments. 
	1.0.1 - 2017-08-09 ( eshagdar ): renamed 'Clipboard - Replace String in FileMaker Objects' to 'fmClip - Replicate FM Objects' to match other handler name pattern
	1.0 - 2017-04-25 ( dshockley ): first created, based off of Replace String in FileMaker Objects.

*)


property debugMode : false
property colSep : tab
property rowSep : return
property xmlButtonbarObj_Start : "<ButtonBarObj flags=\""
property xmlButtonbarObj_End : "</ButtonBarObj>"

property xmlLayoutObjectList : "<fmxmlsnippet type=\"LayoutObjectList\">"
property xmlLayoutOpenTag_Start : "<Layout "
property xmlLayoutOpenTag_After : "<"
property xmlLayoutCloseTag : "</Layout>"

on run
	
	-- INITIALIZE VARS:
	set isLayoutObjects to false
	set doButtonBarSegments to false
	
	
	set objTrans to run script alias (((((path to me as text) & "::") as alias) as string) & "fmObjectTranslator.applescript")
	(* If you need a self-contained script, copy the code from fmObjectTranslator into this script and use the following instead of the run script step above:
			set objTrans to fmObjectTranslator_Instantiate({})
	*)
	
	-- init Translator properties:
	set shouldPrettify of objTrans to false
	set debugMode of objTrans to debugMode
	
	
	---------------------------------
	-- Look at clipboard and ask possible initial questions about it:
	
	set clipboardType to checkClipboardForObjects({}) of objTrans
	
	if clipboardType is false then
		display dialog "The clipboard did not contain any FileMaker objects."
		return false
	end if
	
	set clipboardObjectStringXML to clipboardGetObjectsAsXML({}) of objTrans
	
	-- Check whether or not to replicate buttonbar segments, instead of usual entire object: 
	if clipboardObjectStringXML contains xmlButtonbarObj_Start and clipboardObjectStringXML contains xmlButtonbarObj_End then
		set buttonbarSegmentsDialog to (display dialog "Your clipboard appears to contain a ButtonBar Object - replicate Segments, or run as Normal?" with title "ButtonBar Replicator?" buttons {"Cancel", "Normal", "Segments"} default button "Segments")
		if button returned of buttonbarSegmentsDialog is "Segments" then set doButtonBarSegments to true
	end if
	
	
	if ((text 1 thru 400 of clipboardObjectStringXML) contains xmlLayoutObjectList) and not doButtonBarSegments then
		-- These are Layout Objects (and either are not button bar segments, or user chose to handle segments like normal layout objects), so need special handling:
		set isLayoutObjects to true
	end if
	
	
	---------------------------------
	-- Get the list of what the replicated output items should be:
	
	set dialogTitle to "Replicate FileMaker Objects"
	set mergeSourceDataDialog to (display dialog "Enter a return-delimited list of what each replicated item should be. Each line will be swapped in where the placeholder currently is in your template object(s) in the clipboard (use tabs for multiple columns): " with title dialogTitle default answer "" buttons {"Cancel", "Replicate"} default button "Replicate")
	set mergeSourceDelimData to text returned of mergeSourceDataDialog
	
	set mergeSourceRows to paragraphs of mergeSourceDelimData
	
	set countOfRows to count of mergeSourceRows
	set firstRowData to item 1 of mergeSourceRows
	set countOfColumns to (objTrans's patternCount({firstRowData, colSep})) + 1
	
	set totalColumns to (objTrans's patternCount({mergeSourceDelimData, colSep})) + countOfRows
	
	if totalColumns / countOfRows is not equal to countOfColumns then
		error "Error: Each row has to have the same number of column delimiters." number 1024
		return false
	end if
	
	set firstRowParsed to objTrans's parseChars({firstRowData, colSep})
	
	
	
	---------------------------------
	-- Set up what portion of the source XML should actually be replicated (aka the "templateObject"):
	
	if doButtonBarSegments then
		set beforeButtonBarXML to getTextBefore(clipboardObjectStringXML, xmlButtonbarObj_Start)
		set afterButtonBarXML to getTextAfter(clipboardObjectStringXML, xmlButtonbarObj_End)
		set templateObjectXML to xmlButtonbarObj_Start & objTrans's getTextBetween({clipboardObjectStringXML, xmlButtonbarObj_Start, xmlButtonbarObj_End}) & xmlButtonbarObj_End
		
		
	else if isLayoutObjects then
		-- Special handling for LAYOUT OBJECTS:
		
		-- * Remove the XML header and footer (same as Normal handling). 
		-- * Extract the Layout tag so it can be restored (special!).
		-- * Remove the Layout open and close tags (special!).
		-- * Then continue with the "Normal" replication code below (special handling restore will happen after that).		
		
		-- strip off the XML header/footer
		set templateObjectXML to objTrans's removeHeaderFooter(clipboardObjectStringXML)
		
		-- Extract and store the opening Layout tag:
		set layoutOpenTagXML to xmlLayoutOpenTag_Start & objTrans's getTextBetween({templateObjectXML, xmlLayoutOpenTag_Start, xmlLayoutOpenTag_After})
		
		-- Strip off the Layout OPEN tag: 
		set templateObjectXML to getTextAfter(templateObjectXML, layoutOpenTagXML)
		
		-- Strip off the Layout CLOSE tag: 
		set templateObjectXML to getTextUntilLast(templateObjectXML, xmlLayoutCloseTag)
		
		
		
	else -- ANY other (non-layout) objects:
		set templateObjectXML to objTrans's removeHeaderFooter(clipboardObjectStringXML)
	end if
	
	
	
	
	
	---------------------------------
	-- Replicate the templateObject:
	
	set mergePlaceholderStrings to {}
	repeat with colNum from 1 to countOfColumns
		set nextButtonName to "Next"
		if colNum is equal to countOfColumns then set nextButtonName to "Replicate"
		set mergePlaceholderDialog to (display dialog "Please strip away the code until you have only the 'merge placeholder string' for column " & colNum & ", where the 1st value that will take its place is '" & item colNum of firstRowParsed & "'." with title dialogTitle default answer templateObjectXML buttons {"Cancel", nextButtonName} default button nextButtonName)
		set oneMergePlaceholderString to text returned of mergePlaceholderDialog
		
		copy oneMergePlaceholderString to end of mergePlaceholderStrings
		
	end repeat
	
	
	
	set newXML to ""
	-- Loop over the 'replicate' list rows:
	repeat with oneRowData in mergeSourceRows
		set oneRowData to contents of oneRowData
		set oneRowParsed to objTrans's parseChars({oneRowData, colSep})
		set oneNewObjectXML to templateObjectXML
		-- Need to find and replace each merge placeholder with this row's matching column string:
		repeat with colNum from 1 to countOfColumns
			set oneNewObjectXML to replaceSimple({oneNewObjectXML, item colNum of mergePlaceholderStrings, item colNum of oneRowParsed}) of objTrans
		end repeat
		-- add this new object to the final XML:
		set newXML to newXML & return & oneNewObjectXML
	end repeat
	
	
	---------------------------------
	-- Restore the XML surrounding the multiple replicated objects
	
	if doButtonBarSegments then
		set newXML to beforeButtonBarXML & newXML & afterButtonBarXML
		
	else if isLayoutObjects then
		-- Special handling for LAYOUT OBJECTS:
		
		-- Restore the Layout OPEN and CLOSE tags: 
		set newXML to layoutOpenTagXML & newXML & xmlLayoutCloseTag
		
		-- Put the header/footer back on the list of XML objects (same code here as Normal, objTrans will do the layout-object-specific headers):
		set newXML to objTrans's addHeaderFooter(newXML)
		
	else
		-- Put the header/footer back on the list of XML objects:
		set newXML to objTrans's addHeaderFooter(newXML)
	end if
	
	
	---------------------------------
	-- Put the new objects into the clipboard:
	
	set the clipboard to newXML
	
	clipboardConvertToFMObjects({}) of objTrans
	
	return newXML
	
	
end run




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



