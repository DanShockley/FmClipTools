-- Clipboard - Replicate FileMaker Objects
-- version 1.2, Daniel A. Shockley

-- Takes a return-delimited list of strings (optionally tab-delimited for multiple columns), then takes a FileMaker object in the clipboard and replicates it for each list item, then converts to multiple objects.

-- 1.2 - 2018-04-04 ( dshockley/eshagdar ): load fmObjectTranslator code by reference instead of embedded.
-- 1.1 - 2017-12-18 ( dshockley ): updated fmObjTrans to 3.9.4 to support layout objects. Can now replicate ButtonBar segments. 
-- 1.0.1 - 2017-08-09 ( eshagdar ): renamed 'Clipboard - Replace String in FileMaker Objects' to 'fmClip - Replicate FM Objects' to match other handler name pattern
-- 1.0 - 2017-04-25 ( dshockley ): first created, based off of Replace String in FileMaker Objects.



property debugMode : false
property colSep : tab
property rowSep : return
property xmlButtonbarObj_Start : "<ButtonBarObj flags=\""
property xmlButtonbarObj_End : "</ButtonBarObj>"

on run
	
	set objTrans to run script alias (((((path to me as text) & "::") as alias) as string) & "fmObjectTranslator.applescript")
	(* If you need a self-contained script, copy the code from fmObjectTranslator into this script and use the following instead of the run script step above:
			set objTrans to fmObjectTranslator_Instantiate({})
	*)
	
	set shouldPrettify of objTrans to false
	
	set debugMode of objTrans to debugMode
	
	set clipboardType to checkClipboardForObjects({}) of objTrans
	
	if clipboardType is false then
		display dialog "The clipboard did not contain any FileMaker objects."
		return false
	end if
	
	set clipboardObjectStringXML to clipboardGetObjectsAsXML({}) of objTrans
	
	-- Check whether or not to replicate buttonbar segments, instead of usual entire object: 
	set doButtonBarSegments to false
	if clipboardObjectStringXML contains xmlButtonbarObj_Start and clipboardObjectStringXML contains xmlButtonbarObj_End then
		set buttonbarSegmentsDialog to (display dialog "Your clipboard appears to contain a ButtonBar Object - replicate Segments, or run as Normal?" with title "ButtonBar Replicator?" buttons {"Cancel", "Normal", "Segments"} default button "Segments")
		if button returned of buttonbarSegmentsDialog is "Segments" then set doButtonBarSegments to true
	end if
	
	
	set dialogTitle to "Replicate FileMaker Objects"
	set mergeSourceDataDialog to (display dialog "Enter a return-delimited list of merge source data to replicate (use tabs for multiple columns): " with title dialogTitle default answer "" buttons {"Cancel", "Replicate"} default button "Replicate")
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
	
	if doButtonBarSegments then
		set beforeButtonBarXML to getTextBefore(clipboardObjectStringXML, xmlButtonbarObj_Start)
		set afterButtonBarXML to getTextAfter(clipboardObjectStringXML, xmlButtonbarObj_End)
		set templateObjectXML to xmlButtonbarObj_Start & objTrans's getTextBetween({clipboardObjectStringXML, xmlButtonbarObj_Start, xmlButtonbarObj_End}) & xmlButtonbarObj_End
		
	else -- ANY other (non-layout) objects:
		set templateObjectXML to objTrans's removeHeaderFooter(clipboardObjectStringXML)
	end if
	
	
	
	
	
	
	
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
	
	if doButtonBarSegments then
		set newXML to beforeButtonBarXML & newXML & afterButtonBarXML
	else
		-- Put the header/footer back on the list of XML objects:
		set newXML to objTrans's addHeaderFooter(newXML)
	end if
	
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



