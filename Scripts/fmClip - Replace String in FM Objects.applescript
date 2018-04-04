-- Clipboard - Replace String in FileMaker Objects
-- version 4.0, Daniel A. Shockley, Erik Shagdar
-- Translates FileMaker clipboard objects to XML, performs a string replace within, then back to objects.


-- 4.0 - 2018-04-04 ( dshockley/eshagdar ): load fmObjectTranslator code by reference instead of embedded.
-- 3.9.2 - 2017-08-09 ( eshagdar ): renamed 'Clipboard - Replace String in FileMaker Objects' to 'fmClip - Replace String in FM Objects' to match other handler name pattern
-- 3.7 - show count when choosing ReplaceWith and then immediately replace (no 3rd dialog). 
-- 3.1.1 - the Replace With dialog now shows what you just chose to SearchFor. 
-- 2.7 - fixed parameter calls to replaceSimple and patternCount (multi-params => list)
-- 2.3 - turn off prettify, since not needed (XML is intermediary only)
-- 1.8 - "clipboard convert" now ADDs the other data, not replace clipboard
-- 1.7 - handles UTF-8 properly now


property debugMode : false

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
	
	
	set dialogTitle to "Clipboard FileMaker Objects Search and Replace"
	
	set searchForDialog to (display dialog "Enter the text that should be searched for (and then replaced): " with title dialogTitle default answer "" buttons {"Cancel", "SearchFor"} default button "SearchFor")
	
	set searchFor to text returned of searchForDialog
	
	set foundCount to patternCount({clipboardObjectStringXML, searchFor}) of objTrans
	
	set replaceWithDialog to (display dialog "There are " & foundCount & " occurrences of \"" & searchFor & "\" in your clipboard. What should they all be replaced with?" with title dialogTitle default answer "" buttons {"Cancel", "Replace With"} default button "Replace With")
	
	set replaceWith to text returned of replaceWithDialog
	
	
	set newXML to replaceSimple({clipboardObjectStringXML, searchFor, replaceWith}) of objTrans
	
	set the clipboard to newXML
	
	clipboardConvertToFMObjects({}) of objTrans
	
	return newXML
	
end run





