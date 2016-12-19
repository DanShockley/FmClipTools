-- Set Fields IF not same
-- version 3.9.1, Daniel A. Shockley

-- Takes Set Field script step objects in clipboard and puts in those same steps wrapped in IF step that sees if they aren't already the same.

-- VERSION HISTORY: 
-- 3.9.1 - updated fmObjectTranslator code
-- 1.1 - if the Set To was empty string (NULL, ""), then check for Not IsEmpty instead of simplistic comparison.
-- 1.0 - initial version

property ScriptName : "SetFieldsIfNotSame"

property debugMode : false


-- PARSING CLIPS: 
property stepStart : "<Step enable=\"True\" id=\""
property stepSetFieldStart : "<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA["
property cdataThruTable : "]]></Calculation><Field table=\""
property tableThruId : "\" id=\""
property idThruName : "\" name=\""
property nameThruEndStep : "\"></Field></Step>"

property finalXML : "</fmxmlsnippet>"

on run
	
	
	set objTrans to fmObjectTranslator_Instantiate({})
	
	
	-- IMPORTANT!!!  	-- IMPORTANT!!!  	-- IMPORTANT!!!  
	-- IMPORTANT!!!  	-- IMPORTANT!!!  	-- IMPORTANT!!!  
	-- The search/replace needs to be able to assume extra whitespace wasn't added.
	-- IMPORTANT!!!  	-- IMPORTANT!!!  	-- IMPORTANT!!!  
	set shouldPrettify of objTrans to false
	-- IMPORTANT!!!  	-- IMPORTANT!!!  	-- IMPORTANT!!!  
	-- IMPORTANT!!!  	-- IMPORTANT!!!  	-- IMPORTANT!!!  
	
	-- Set Variable Script Step XML:
	--
	set startingXML to clipboardGetObjectsAsXML({}) of objTrans
	-- DEBUG: set startingXML to sampleXML()
	
	
	
	tell objTrans to set scriptStepsWithoutStart to parseChars({startingXML, stepStart})
	
	
	if debugMode then logConsole(ScriptName, "TEST") of objTrans
	
	set newListOFXML to {}
	set addFinalXML to false
	
	set countSetFieldSteps to 0
	repeat with i from 1 to count of scriptStepsWithoutStart
		if i is equal to 1 then
			set oneScriptStep to item i of scriptStepsWithoutStart
			copy oneScriptStep to end of newListOFXML
			
			if debugMode then logConsole(ScriptName, i & ": " & oneScriptStep) of objTrans
			
		else
			
			set oneScriptStep to stepStart & item i of scriptStepsWithoutStart
			
			
			if debugMode then logConsole(ScriptName, i & ": " & oneScriptStep) of objTrans
			
			if oneScriptStep ends with finalXML then
				-- handle the closing XML tag for the whole thing.
				set oneScriptStep to getTextBefore(oneScriptStep, finalXML)
				set addFinalXML to true
			end if
			
			
			
			if oneScriptStep begins with stepSetFieldStart then
				-- this is a SET FIELD step, so add IF/END IF before/after:
				
				set countSetFieldSteps to countSetFieldSteps + 1
				
				set setFieldToThisCalc to my getTextBetweenChoice({oneScriptStep, stepSetFieldStart, cdataThruTable})
				
				set tableFieldPart to my getTextBetweenChoice({oneScriptStep, cdataThruTable, nameThruEndStep})
				set tableName to my getTextBefore(tableFieldPart, tableThruId)
				set fieldName to my getTextAfter(tableFieldPart, idThruName)
				
				if setFieldToThisCalc is "\"\"" or setFieldToThisCalc is "NULL" then
					-- if clearing the field, then use "Not IsEmpty" in the IF step, instead of not-equals comparison operator:
					set testCalc to "Not IsEmpty ( " & tableName & "::" & fieldName & " )"
				else
					set testCalc to tableName & "::" & fieldName & " � " & setFieldToThisCalc
				end if
				
				set step_IF to makeStep_IF(testCalc)
				
				copy step_IF to end of newListOFXML
				copy oneScriptStep to end of newListOFXML
				copy makeStep_EndIF() to end of newListOFXML
				
				if addFinalXML then
					-- handle the closing XML tag for the whole thing.
					copy finalXML to end of newListOFXML
				end if
				
				
			else -- some OTHER kind of script step:
				copy oneScriptStep to end of newListOFXML
			end if
			
			
		end if
	end repeat
	
	
	set newXML to unParseChars(newListOFXML, return)
	
	
	set the clipboard to newXML
	
	
	set clipHasXML to checkClipboardForValidXML({}) of objTrans
	
	
	clipboardConvertToFMObjects({}) of objTrans
	
	tell application "FileMaker Pro Advanced"
		display dialog "Converted " & countSetFieldSteps & " Set Field steps to be wrapped in IF-not-same test." buttons {"OK"} default button "OK"
	end tell
	
	return newXML
	
	
	
	
end run








on makeStep_IF(testCalcString)
	
	set templateStep to "<Step enable=\"True\" id=\"68\" name=\"If\"><Calculation><![CDATA[###TESTCALC###]]></Calculation></Step>"
	
	return replaceSimple({templateStep, "###TESTCALC###", testCalcString})
	
	
end makeStep_IF

on makeStep_EndIF()
	
	return "<Step enable=\"True\" id=\"70\" name=\"End If\"></Step>"
	
end makeStep_EndIF



on sampleXML()
	
	return "<fmxmlsnippet type=\"FMObjectList\"><Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::a15A_RelatedActivityID1]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"124\" name=\"aAC_RelatedActivityID1\"></Field></Step><Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::a15A_RelatedActivityID2]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"125\" name=\"aAC_RelatedActivityID2\"></Field></Step><Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::a15A_SupportOfActivity_ActivityID]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"126\" name=\"aAC_SupportOfActivity_ActivityID\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ActivityCategory]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32769\" name=\"bAC_ActivityCategory\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ActivityEndDt]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32770\" name=\"bAC_ActivityEndDt\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ActivityEndTm]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32771\" name=\"bAC_ActivityEndTm\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ActivityNm]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32772\" name=\"bAC_ActivityNm\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ActivityNt]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32773\" name=\"bAC_ActivityNt\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ActivityStage]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32774\" name=\"bAC_ActivityStage\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ActivityStatus]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32775\" name=\"bAC_ActivityStatus\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ActivityStrtDt]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32776\" name=\"bAC_ActivityStrtDt\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ActivityStrtTm]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32777\" name=\"bAC_ActivityStrtTm\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ActivityType]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32778\" name=\"bAC_ActivityType\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_Adr]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32779\" name=\"bAC_Adr\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ConfirmationGoal]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32788\" name=\"bAC_ConfirmationGoal\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_ConfirmGoalDouble]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32789\" name=\"bAC_ConfirmGoalDouble\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_Desc]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32790\" name=\"bAC_Desc\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_Local]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32804\" name=\"bAC_Local\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_MapURL]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32805\" name=\"bAC_MapURL\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_Political]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32825\" name=\"bAC_Political\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_Question1]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32858\" name=\"bAC_Question1\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_Question1_Label]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32859\" name=\"bAC_Question1_Label\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_Question2]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32860\" name=\"bAC_Question2\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_Question2_Label]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32861\" name=\"bAC_Question2_Label\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_Question3]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32862\" name=\"bAC_Question3\"></Field></Step>

<Step enable=\"True\" id=\"76\" name=\"Set Field\"><Calculation><![CDATA[_ext_15A_ACTIVITY::b15A_Question3_Label]]></Calculation><Field table=\"_ext_15A.AC_ACTIVITY_UpdateCreate\" id=\"32863\" name=\"bAC_Question3_Label\"></Field></Step></fmxmlsnippet>"
	
end sampleXML








on getTextBetweenChoice(prefs)
	-- version 1.6
	-- gets the text between specified occurrence of beforeText and afterText in sourceText
	-- the default textItemNum should be 1, NOT 2
	set defaultPrefs to {textItemNum:1}
	
	if (class of prefs is not list) and (class of prefs is not record) then
		error "getTextBetween FAILED: parameter should be a record or list. If it is multiple items, just make it into a list to upgrade to this handler." number 1024
	end if
	if class of prefs is list then
		if (count of prefs) is 4 then
			set textItemNum of defaultPrefs to item 4 of prefs
		end if
		set prefs to {sourceText:item 1 of prefs, beforeText:item 2 of prefs, afterText:item 3 of prefs}
	end if
	set prefs to prefs & defaultPrefs -- add on default preferences, if needed
	
	set sourceText to sourceText of prefs
	set beforeText to beforeText of prefs
	set afterText to afterText of prefs
	set textItemNum to textItemNum of prefs
	try
		set oldDelims to AppleScript's text item delimiters
		set AppleScript's text item delimiters to the beforeText
		set the prefixRemoved to text item (textItemNum + 1) of sourceText
		
		set AppleScript's text item delimiters to afterText
		set the finalResult to text item 1 of prefixRemoved
		
		set AppleScript's text item delimiters to oldDelims
		
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldDelims
		-- 	tell me to log "Error in getTextBetween() : " & errMsg
		set the finalResult to "" -- return nothing if the surrounding text is not found
	end try
	
	return finalResult
	
end getTextBetweenChoice




on getTextAfter(sourceText, afterThis)
	-- version 1.2, Daniel A. Shockley, http://www.danshockley.com
	
	-- gets ALL text from source after marker, not just through next occurrence
	-- 1.2 - changed to get ALL, not thru next occurrence, which changes behavior to match handler NAME
	
	try
		set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {afterThis}}
		
		if (count of text items of sourceText) is 1 then
			-- the split-string didn't appear at all
			set AppleScript's text item delimiters to oldDelims
			return ""
		else
			set the resultAsList to text items 2 thru -1 of sourceText
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




on getTextBefore(sourceText, stopHere)
	-- version 1.1, Daniel A. Shockley, http://www.danshockley.com
	-- gets the text before the first occurrence stopHere
	try
		set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, stopHere}
		if (count of text items of sourceText) is 1 then
			set AppleScript's text item delimiters to oldDelims
			return ""
		else
			set the finalResult to text item 1 of sourceText
		end if
		set AppleScript's text item delimiters to oldDelims
		return finalResult
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldDelims
		return "" -- return nothing if the stop text is not found
	end try
end getTextBefore






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



on trimWhitespace(inputString)
	-- version 1.1: 
	
	-- 1.1 - changed to correctly handle when the whole input string is whitespace
	-- 1.0 - loop actually works, since the ASTIDs method fails with return / ascii character 13
	-- note also that the "contains" AppleScript function breaks with ASCII character 13
	-- that is why a list of ASCII numbers is used, instead of a list of strings
	set whiteSpaceAsciiNumbers to {13, 10, 32, 9}
	
	set textLength to length of inputString
	if textLength is 0 then return ""
	set endSpot to -textLength -- if only whitespace is found, will chop whole string
	
	-- chop from end
	set i to -1
	repeat while -i is less than or equal to textLength
		set testChar to text i thru i of inputString
		if whiteSpaceAsciiNumbers does not contain (ASCII number testChar) then
			set endSpot to i
			exit repeat
		end if
		set i to i - 1
	end repeat
	
	
	if -endSpot is equal to textLength then
		if whiteSpaceAsciiNumbers contains (ASCII number testChar) then return ""
	end if
	
	set inputString to text 1 thru endSpot of inputString
	set textLength to length of inputString
	set newStart to 1
	
	-- chop from beginning
	set i to 1
	repeat while i is less than or equal to textLength
		set testChar to text i thru i of inputString
		if whiteSpaceAsciiNumbers does not contain (ASCII number testChar) then
			set newStart to i
			exit repeat
		end if
		set i to i + 1
	end repeat
	
	set inputString to text newStart thru textLength of inputString
	
	return inputString
	
end trimWhitespace






on replaceSimple(prefs)
	-- version 1.4, Daniel A. Shockley http://www.danshockley.com
	
	-- 1.4 - Convert sourceText to string, since the previous version failed on numbers. 
	-- 1.3 - The class record is specified into a variable to avoid a namespace conflict when run within FileMaker. 
	-- 1.2 - changes parameters to a record to add option to CONSIDER CASE, since the default changed to ignoring case with Snow Leopard. This handler defaults to CONSIDER CASE = true, since that was what older code expected. 
	-- 1.1 - coerces the newChars to a STRING, since other data types do not always coerce
	--     (example, replacing "nine" with 9 as number replaces with "")
	
	set defaultPrefs to {considerCase:true}
	
	if class of prefs is list then
		if (count of prefs) is greater than 3 then
			-- get any parameters after the initial 3
			set prefs to {sourceText:item 1 of prefs, oldChars:item 2 of prefs, newChars:item 3 of prefs, considerCase:item 4 of prefs}
		else
			set prefs to {sourceText:item 1 of prefs, oldChars:item 2 of prefs, newChars:item 3 of prefs}
		end if
		
	else if class of prefs is not equal to (class of {someKey:3}) then
		-- Test by matching class to something that IS a record to avoid FileMaker namespace conflict with the term "record"
		
		error "The parameter for 'replaceSimple()' should be a record or at least a list. Wrap the parameter(s) in curly brackets for easy upgrade to 'replaceSimple() version 1.3. " number 1024
		
	end if
	
	
	set prefs to prefs & defaultPrefs
	
	
	set considerCase to considerCase of prefs
	set sourceText to sourceText of prefs
	set oldChars to oldChars of prefs
	set newChars to newChars of prefs
	
	set sourceText to sourceText as string
	
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to the oldChars
	if considerCase then
		considering case
			set the parsedList to every text item of sourceText
			set AppleScript's text item delimiters to the {(newChars as string)}
			set the newText to the parsedList as string
		end considering
	else
		ignoring case
			set the parsedList to every text item of sourceText
			set AppleScript's text item delimiters to the {(newChars as string)}
			set the newText to the parsedList as string
		end ignoring
	end if
	set AppleScript's text item delimiters to oldDelims
	return newText
	
	
end replaceSimple








on fmObjectTranslator_Instantiate(prefs)
	
	script fmObjectTranslator
		-- version 3.9.1, Daniel A. Shockley
		
		-- 3.9.1 - 2016-11-02 ( dshockley/eshagdar ): always reset currentCode before reading clipboard; debugMode now logs the tempDataPosix in dataObjectToUTF8; add more error-trapping and error-handling.
		-- 3.9 - fixed bug where simpleFormatXML would fail on layout objects.
		-- 3.8 - default for shouldPrettify is now FALSE; added shouldSimpleFormat option for simpleFormatXML() (modifies text XML in minor, but useful, ways) - as of 3.8, adds line-returns inside the fmxmlsnippet tags; 
		-- 3.7 - updated dataObjectToUTF8 to indicate non-FM object can be converted; added clipboardPatternCount method; updated logConsole to 1.9; added coerceToString 1.8; 
		-- 3.6 - currentCode needed to be evaluated WHEN USED, since translator object retains previous operations; added error-trapping; labeled more handlers as 'Public Methods'
		-- 3.5 - moved a file write operation out of unneeded tell System Events block to avoid AppleEvents/sandbox errAEPrivilegeError; CHANGED clipboardSetObjectsUsingXML to actually completely SET clipboard; original behavior now named clipboardAddObjectsUsingXML; brought back handling of FM10 ASCII-10 bug, for backwards compatibility.
		-- 3.4 - added clipboardGetObjectsToXmlFilePath; updated dataObjectToUTF8 to 2.6
		-- 3.3 - tweaked clipboardSetObjectsUsingXML to use a single 'set clipboard'
		-- 3.2 - added clipboardSetObjectsUsingXML
		-- 3.1 - updated Layout Objects to work with both FM11 and FM12 (XMLO and XML2)
		-- 3.0 - updated Layout Objects to use XML2 for use with FileMaker 12 - use pre-3.0 for FileMaker 11 and earlier
		-- 2.6 - completely turned off indent in tidy since no clear way to protect CDATA blocks during indent.
		-- 2.5 - adds DebugMode property; more safety options in tidy to prevent unexpected EDITING of the XML during prettify.
		-- 2.4 - use newer versions of parseChars and replaceSimple.
		-- 2.3 - prettify can be turned off - useful when the conversion to XML is used for a replacement, and XML will not be viewed
		-- 2.2 - prettify fails gracefully - if it cannot prettify, it returns the original unmodified
		-- 2.1 - modified the "tidy" command to essentially NEVER wrap (set to petabyte-long lines) to avoid breaking certain HexData tags for layout objects
		-- 2.0 - added prettify code when converting to XML (uses -raw switch to avoid any HTML entity encoding); added a tell System Events block around file read/write code to avoid name-space conflict when compiling in FileMaker; added support for Script Folders that use the "Group" tag but are still XMSC data type
		-- 1.9 - remove the extraneous Ascii 10 after the Layout tag that FM10 adds when copying layout objects; dropped unused code for dataObjectToString()
		-- 1.8 - do not REPLACE what is in the clipboard when doing "clipboardConvert" - instead, ADD the XML string or FM Objects
		-- 1.7 - handles clipboard data as UTF-8 to avoid mangling special characters
		-- 1.6 - handles the FileMaker line return character (when converting from HEX, it became ASCII 194, 182, rather than ASCII 166)
		-- 1.5.1 - bug fix: hexToAscii now properly returns content of XML file
		-- 1.5 - writes data to temp files to improve reliability
		-- 1.4 - added more debugging; renamed handlers for clarity
		
		property ScriptName : "FM Object Translator"
		
		property fmObjectList : {}
		property tempDataName : "temp.data"
		property tempXMLName : "temp.xml"
		
		-- the "bad" and "good" layout tag start code deals with a bug in FileMaker 10: 
		property badLayoutCodeStart : "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" & (ASCII character 10) & "<Layout" & (ASCII character 10) & " enclosingRectTop=\""
		property goodLayoutCodeStart : "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" & (ASCII character 10) & "<Layout enclosingRectTop=\""
		
		property fmObjCodes : {�
			{objName:"Step", objCode:"XMSS"}, �
			{objName:"Layout", objCode:"XML2", secondaryNode:"NOT ObjectStyle"}, �
			{objName:"Layout", objCode:"XMLO", secondaryNode:"HAS ObjectStyle"}, �
			{objName:"Group", objCode:"XMSC"}, �
			{objName:"Script", objCode:"XMSC"}, �
			{objName:"Field", objCode:"XMFD"}, �
			{objName:"CustomFunction", objCode:"XMFN"}, �
			{objName:"BaseTable", objCode:"XMTB"} �
				}
		
		property currentCode : ""
		property debugMode : false
		property codeAsXML : ""
		property codeAsObjects : ""
		
		property shouldPrettify : false
		property shouldSimpleFormat : false
		
		on run
			-- initialize properties of this script object:
			
			-- turn the objCodes into class objects for fmObjectList
			set fmObjectList to {}
			repeat with oneObject in fmObjCodes
				set oneCode to objCode of oneObject
				set oneClass to classFromCode(oneCode)
				set oneSecondaryNode to ""
				try
					set oneSecondaryNode to secondaryNode of oneObject
				end try
				copy {objName:objName of oneObject, objCode:objCode of oneObject, objClass:oneClass, secondaryNode:oneSecondaryNode} to end of fmObjectList
			end repeat
		end run
		
		
		
		-----------------------------------
		------ PUBLIC METHODS ------
		-----------------------------------
		
		on clipboardGetTextBetween(prefs)
			-- version 1.0
			
			-- Extracts text between two strings from the first item in clipboard.
			set defaultPrefs to {beforeString:null, afterString:null}
			set prefs to prefs & defaultPrefs
			
			if beforeString of prefs is null then
				error "clipboardGetTextBetween failed: Missing search criteria: beforeString." number 1024
			end if
			if afterString of prefs is null then
				error "clipboardGetTextBetween failed: Missing search criteria: afterString." number 1024
			end if
			
			if beforeString of prefs is not null then
				set clipboardObject to get the clipboard
				set rawText to dataObjectToUTF8({someObject:clipboardObject})
				return getTextBetween({sourceText:rawText, beforeText:beforeString of prefs, afterText:afterString of prefs})
			end if
			
		end clipboardGetTextBetween
		
		
		
		on clipboardPatternCount(prefs)
			-- version 1.0
			
			-- Checks the first item in clipboard for the specified string
			set defaultPrefs to {searchString:null, searchHex:null}
			set prefs to prefs & defaultPrefs
			
			if searchString of prefs is not null then
				set clipboardObject to get the clipboard
				set rawText to dataObjectToUTF8({someObject:clipboardObject})
				return patternCount({rawText, searchString of prefs})
				
			else if searchHex of prefs is not null then
				set clipboardObject to get the clipboard
				set textAsHex to coerceToString(clipboardObject)
				return patternCount({textAsHex, searchHex of prefs})
				
			else
				error "clipboardPatternCount failed: No search specified." number 1024
				
			end if
			
		end clipboardPatternCount
		
		
		
		on clipboardSetObjectsUsingXML(prefs)
			-- version 3.6
			
			-- 3.6 - some error-trapping added
			-- changed in 3.5 to ACTUALLY replace of existing clipboard instead of ADDing objects to whatever was already in clipboard.
			-- sets the clipboard to FM Objects from specified XML string
			
			if class of prefs is string then
				set stringFmXML to prefs
			else if class of prefs is equal to class of {test:"TEST"} then
				set stringFmXML to stringFmXML of prefs
			end if
			
			if debugMode then logConsole(ScriptName, "clipboardSetObjectsUsingXML: START")
			if not checkStringForValidXML(stringFmXML) then
				if debugMode then logConsole(ScriptName, "clipboardSetObjectsUsingXML: Specified XML does not validly represent FileMaker objects.")
				return false
			end if
			
			if debugMode then logConsole(ScriptName, "clipboardSetObjectsUsingXML : currentCode: " & currentCode)
			
			try
				set fmObjects to convertXmlToObjects(stringFmXML)
			on error errMsg number errNum
				return false
			end try
			set the clipboard to fmObjects
			
			return true
			
		end clipboardSetObjectsUsingXML
		
		
		
		on clipboardAddObjectsUsingXML(prefs)
			
			-- ADDS FM Objects for the specified XML string TO the clipboard
			
			-- 3.6 - some error-trapping added
			
			if class of prefs is string then
				set stringFmXML to prefs
			else if class of prefs is equal to class of {test:"TEST"} then
				set stringFmXML to stringFmXML of prefs
			end if
			
			if debugMode then logConsole(ScriptName, "clipboardAddObjectsUsingXML: START")
			if not checkStringForValidXML(stringFmXML) then
				if debugMode then logConsole(ScriptName, "clipboardAddObjectsUsingXML: Specified XML does not validly represent FileMaker objects.")
				return false
			end if
			
			if debugMode then logConsole(ScriptName, "clipboardAddObjectsUsingXML : currentCode: " & currentCode)
			
			try
				set fmObjects to convertXmlToObjects(stringFmXML)
			on error errMsg number errNum
				return false
			end try
			
			set fmClass to classFromCode(currentCode)
			
			set newClip to {string:stringFmXML} & recordFromList({fmClass, fmObjects})
			
			set the clipboard to newClip
			
			return true
			
		end clipboardAddObjectsUsingXML
		
		
		
		on clipboardConvertToFMObjects(prefs)
			-- version 3.6
			-- converts the specified XML string to FM Objects and puts BOTH in clipboard
			
			-- 3.6 - updated for currentCode issue; some error-trapping added
			
			if debugMode then logConsole(ScriptName, "clipboardConvertToFMObjects: START")
			
			set stringFmXML to get the clipboard
			
			try
				set fmObjects to convertXmlToObjects(stringFmXML)
			on error errMsg number errNum
				if debugMode then logConsole(ScriptName, "clipboardSetToTranslatedFMObjects: ERROR: " & errMsg & ".")
				return false
			end try
			
			set the clipboard to fmObjects
			
			set fmClipboard to get the clipboard
			
			set newClip to {string:stringFmXML} & fmClipboard
			
			set the clipboard to newClip
			
			return true
			
		end clipboardConvertToFMObjects
		
		
		
		on clipboardConvertToXML(prefs)
			-- version 3.6
			
			-- 3.6 - updated to deal with currentCode issue
			-- 1.9 - remove the extraneous ASCII 10 added after Layout tag by FM10
			-- 1.8 - ADD XML string to FM objects in clipboard, not replace
			-- converts the contents of the clipboard from FM Objects to XML string
			
			if debugMode then logConsole(ScriptName, "clipboardConvertToXML: START")
			
			set fmClipboard to get the clipboard -- get it now, so we can ADD XML to it.
			
			try
				set xmlTranslation to clipboardGetObjectsAsXML({}) -- as string
			on error errMsg number errNum
				if debugMode then logConsole(ScriptName, "clipboardConvertToXML: ERROR: " & errMsg & ".")
				return false
			end try
			
			
			if currentCode is "XMLO" then
				-- if pre-12 FileMaker layout code, check/fix it for bug if copied from FM 10:
				set xmlTranslation to replaceSimple({xmlTranslation, badLayoutCodeStart, goodLayoutCodeStart})
				
				set testChar to text 44 thru 48 of xmlTranslation
				
				if debugMode then logConsole(ScriptName, "clipboardConvertToXML : FileMaker 10 BUG ASCII-10 check: Char:" & testChar & return & "currentCode:" & currentCode & return & "ASCII:" & (ASCII number of testChar))
			end if
			
			set newClip to {string:xmlTranslation} & fmClipboard
			
			set the clipboard to newClip
			
			return true
			
		end clipboardConvertToXML
		
		
		
		on clipboardGetObjectsAsXML(prefs)
			-- version 1.1
			-- returns the XML translation of FM objects in the clipboard
			
			-- 1.1 - 2016-11-02 ( dshockley/eshagdar ): always check/set currentCode before using; renamed variable, use currentClass() handler.
			
			
			if debugMode then logConsole(ScriptName, "clipboardGetObjectsAsXML: START")
			set clipboardDoesContainFmObjects to checkClipboardForObjects({}) -- return boolean, also sets currentCode property.
			if not clipboardDoesContainFmObjects then
				error "clipboardGetObjectsAsXML : Clipboard does not contain valid FileMaker objects." number 1024
			end if
			
			if length of currentCode is 0 then return ""
			
			set fmClass to currentClass()
			set fmObjects to get the clipboard as fmClass
			
			return convertObjectsToXML(fmObjects)
			
		end clipboardGetObjectsAsXML
		
		
		on clipboardGetXMLAsObjects(prefs)
			-- returns the FM object translation of XML string in the clipboard
			
			if debugMode then logConsole(ScriptName, "clipboardGetXMLAsObjects: START")
			
			set stringFmXML to get the clipboard as string
			
			try
				set fmObjects to convertXmlToObjects(stringFmXML)
			on error errMsg number errNum
				if debugMode then logConsole(ScriptName, "clipboardGetXMLAsObjects: ERROR: " & errMsg & ".")
				return false
			end try
			
			return fmObjects
			
		end clipboardGetXMLAsObjects
		
		
		
		on clipboardGetObjectsToXmlFilePath(prefs)
			-- version 1.1
			-- returns the PATH to an XML translation of FM objects in the clipboard
			
			-- 1.1 - 2016-11-02 ( dshockley/eshagdar ): always check/set currentCode before using; renamed variable, use currentClass() handler.
			
			set defaultPrefs to {outputFilePath:"__TEMP__", resultType:"MacPath"}
			set prefs to prefs & defaultPrefs
			
			if debugMode then logConsole(ScriptName, "clipboardGetObjectsToXmlFilePath: START")
			
			set clipboardDoesContainFmObjects to checkClipboardForObjects({}) -- return boolean, also sets currentCode property.			
			if not clipboardDoesContainFmObjects then return ""
			
			set fmClass to currentClass()
			set fmObjects to get the clipboard as fmClass
			
			set xmlConverted to dataObjectToUTF8({fmObjects:fmObjects, resultType:resultType of prefs, outputFilePath:outputFilePath of prefs})
			
			return xmlConverted
			
			
		end clipboardGetObjectsToXmlFilePath
		
		
		
		
		on checkClipboardForValidXML(prefs)
			-- checks clipboard for XML that represents FM objects
			-- returns true if it does, false if not
			
			if debugMode then logConsole(ScriptName, "checkClipboardForValidXML: START")
			
			set testClipboard to get the clipboard
			
			return checkStringForValidXML(testClipboard)
			
		end checkClipboardForValidXML
		
		
		on checkClipboardForObjects(prefs)
			-- version 1.1
			-- Checks clipboard for FM Objects (as classes, not XML). Returns true if it does, false if not. 
			
			-- 1.1 - 2016-11-02 ( dshockley/eshagdar ): added comment, changed test to length of instead of empty string.
			
			if debugMode then logConsole(ScriptName, "checkClipboardForObjects: START")
			
			set clipboardClasses to clipboard info
			
			set clipboardType to ""
			repeat with oneTypeAndLength in clipboardClasses
				set oneTypeAndLength to contents of oneTypeAndLength
				
				repeat with oneClass in fmObjectList
					set {className, classType} to {objName of oneClass, objClass of oneClass}
					if (item 1 of oneTypeAndLength) is classType then
						set clipboardType to objCode of oneClass
						exit repeat
					end if
				end repeat
			end repeat
			
			if debugMode then logConsole(ScriptName, "checkClipboardForObjects: clipboardType: " & clipboardType)
			
			-- now, save _whatever_ it was into currentCode.
			set currentCode to clipboardType
			
			if length of currentCode is 0 then
				return false
			else
				return true
			end if
			
		end checkClipboardForObjects
		
		
		on convertObjectsToXML(fmObjects)
			
			if debugMode then logConsole(ScriptName, "convertObjectsToXML: START")
			
			set objectsAsXML to dataObjectToUTF8({fmObjects:fmObjects})
			
			if shouldPrettify then set objectsAsXML to prettifyXML(objectsAsXML)
			if shouldSimpleFormat then set objectsAsXML to simpleFormatXML(objectsAsXML)
			
			return objectsAsXML
			
		end convertObjectsToXML
		
		
		
		on convertXmlToObjects(stringFmXML)
			-- version 3.7
			
			-- 3.7 - 2016-11-02 ( dshockley/eshagdar ): separate test into a variable; renamed variables.
			-- 3.6 - need to SET currentCode for this object - always.
			-- 3.5 - no need for file write�to be in tell System Events block
			-- converts some string of XML into fmObjects as FM data type
			
			if debugMode then logConsole(ScriptName, "convertXmlToObjects: START")
			
			set stringIsValidXML to checkStringForValidXML(stringFmXML) -- return boolean, also sets currentCode property.			
			if not stringIsValidXML then
				-- if not valid, give an error.
				if debugMode then logConsole(ScriptName, "convertXmlToObjects: no valid XML")
				error "XML does not contain valid FileMaker objects." number 1024
			end if
			
			set fmClass to currentClass()
			
			set stringLength to length of stringFmXML
			
			if debugMode then logConsole(ScriptName, "convertXmlToObjects: stringLength: " & stringLength)
			
			set tempXMLPosix to (makeTempDirPosix() & tempXMLName)
			set xmlFilePath to (POSIX file tempXMLPosix) as string
			if debugMode then logConsole(ScriptName, "convertXmlToObjects: xmlFilePath: " & xmlFilePath)
			set xmlHandle to open for access file xmlFilePath with write permission
			write stringFmXML to xmlHandle as �class utf8�
			close access xmlHandle
			set fmObjects to read alias xmlFilePath as fmClass
			
			return fmObjects
			
		end convertXmlToObjects
		
		
		
		on checkStringForValidXML(someString)
			-- version 1.1
			-- Checks someString for XML that represents FM objects. Returns true if it does, false if not. 
			
			-- 1.1 - 2016-11-02 ( dshockley/eshagdar ): added comment, changed test to length of instead of empty string.
			
			if debugMode then logConsole(ScriptName, "checkStringForValidXML: START")
			
			try
				tell application "System Events"
					set xmlData to make new XML data with data someString
					set fmObjectName to name of XML element 1 of XML element 1 of xmlData
				end tell
			on error errMsg number errNum
				if debugMode then logConsole(ScriptName, "checkStringForValidXML: ERROR: " & errMsg & "(" & errNum & ")")
				if errNum is -1719 then
					-- couldn't find an XML element, so NOT valid XML
					return false
				else if errNum is -2753 then
					-- couldn't create XML from someString, so NOT valid XML
					return false
				else
					error errMsg number errNum
				end if
			end try
			
			if debugMode then logConsole(ScriptName, "checkStringForValidXML: fmObjectName: " & fmObjectName)
			
			set currentCode to ""
			repeat with oneObjectType in fmObjectList
				
				if debugMode then logConsole(ScriptName, objName of oneObjectType)
				if (fmObjectName is objName of oneObjectType) then
					
					-- Now, the XMLO and XML2 are both "Layout" so we need to check a secondary node to know which objCode:
					if fmObjectName is "Layout" then
						set secondaryNode to word 2 of secondaryNode of oneObjectType
						if word 1 of secondaryNode of oneObjectType is "HAS" then
							set secondaryNodeShouldExist to true
						else
							set secondaryNodeShouldExist to false
						end if
						
						-- see if secondary node exists: 
						tell application "System Events"
							set secondaryNodeDoesExist to exists (first XML element of XML element 1 of XML element 1 of xmlData whose name is "ObjectStyle")
						end tell
						
						-- if it should AND does, or should not and does not, then this is the one we want:
						if secondaryNodeShouldExist is equal to secondaryNodeDoesExist then
							set currentCode to objCode of oneObjectType
							set objectType to objClass of oneObjectType
							exit repeat
						end if
						
					else
						-- NOT Layout, so just use this one:
						set currentCode to objCode of oneObjectType
						set objectType to objClass of oneObjectType
						exit repeat
					end if
					
				end if
			end repeat
			
			if debugMode then logConsole(ScriptName, "checkStringForValidXML: currentCode: " & currentCode)
			
			if length of currentCode is 0 then
				return false
			else
				return true
			end if
			
		end checkStringForValidXML
		
		
		
		
		
		
		-----------------------------------
		------ PRIVATE METHODS ------
		-----------------------------------
		
		
		
		
		
		on currentClass()
			return classFromCode(currentCode)
		end currentClass
		
		
		on classFromCode(objCode)
			return run script "�class " & objCode & "�"
		end classFromCode
		
		
		on makeTempDirPosix()
			set dirPosix to (do shell script "mktemp -d -t tempFMObject") & "/"
			return dirPosix
		end makeTempDirPosix
		
		
		on simpleFormatXML(someXML)
			-- version 1.1
			
			set xmlHeader to "<fmxmlsnippet type=\"FMObjectList\">"
			set xmlFooter to "</fmxmlsnippet>"
			
			if debugMode then logConsole(ScriptName, "simpleFormatXML: START")
			try
				
				
				if someXML begins with xmlHeader and someXML ends with xmlFooter then
					try
						set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, xmlHeader}
						set modifiedXML to (text items 2 thru -1 of someXML) as string
						set AppleScript's text item delimiters to xmlFooter
						set modifiedXML to ((text items 1 thru -2 of modifiedXML) as string)
						set modifiedXML to xmlHeader & return & modifiedXML & return & xmlFooter
						set AppleScript's text item delimiters to oldDelims
					on error errMsg number errNum
						-- trap here so we can restore ASTIDs, then pass out the actual error: 
						set AppleScript's text item delimiters to oldDelims
						error errMsg number errNum
					end try
					
					return modifiedXML
				else
					return someXML
				end if
			on error errMsg number errNum
				-- any error above should fail gracefully and just return the original code
				if debugMode then logConsole(ScriptName, "simpleFormatXML: ERROR: " & errMsg & "(" & errNum & ")")
				return someXML
				
			end try
			
			
		end simpleFormatXML
		
		
		on prettifyXML(someXML)
			-- version 1.4, Daniel A. Shockley
			if debugMode then logConsole(ScriptName, "prettifyXML: START")
			try
				-- the "other" options turn off tidy defaults that result in unexpected modification of the XML:
				set otherTidyOptions to " --literal-attributes yes --drop-empty-paras no --fix-backslash no --fix-bad-comments no --fix-uri no --ncr no --quote-ampersand no --quote-nbsp no "
				set tidyShellCommand to "echo " & quoted form of someXML & " | tidy -xml -m -raw -wrap 999999999999999" & otherTidyOptions
				-- NOTE: wrapping of lines needs to NEVER occur, so cover petabyte-long lines 
				set prettyXML to do shell script tidyShellCommand
				
			on error errMsg number errNum
				-- any error above should fail gracefully and just return the original code
				if debugMode then logConsole(ScriptName, "prettifyXML: ERROR: " & errMsg & "(" & errNum & ")")
				return someXML
				
			end try
			
			return prettyXML
			
		end prettifyXML
		
		
		on dataObjectToUTF8(prefs)
			-- version 2.7
			
			-- 2.8 - 2016-11-02 ( dshockley/eshagdar ): debugMode now logs the tempDataPosix
			-- 2.7 - by default, look for someObject instead of 'fmObjects' (but allow calling code to specify 'fmObjects' for backwards compatibility).
			-- 2.6 - can return the UTF8 ITSELF, or instead a path to the temp file this creates.
			-- 2.5 - added debugMode logging
			-- 2.0 - wrapped read/write commands in System Events tell block to avoid name-space conflicts in FileMaker; handled posix/path/file differences to avoid errors (seemed to have error converting from Posix before file existed?)
			
			set defaultPrefs to {resultType:"utf8", outputFilePath:"__TEMP__", fmObjects:null, someObject:null}
			set prefs to prefs & defaultPrefs
			
			set someObject to someObject of prefs
			set resultType to resultType of prefs
			set outputFilePath to outputFilePath of prefs
			if someObject is null and fmObjects of prefs is not null then
				set someObject to fmObjects of prefs
			end if
			
			
			if debugMode then logConsole(ScriptName, "dataObjectToUTF8: START")
			
			try
				
				if outputFilePath is "__TEMP__" then
					set tempDataFolderPosix to my makeTempDirPosix()
					set tempDataFolderPath to (POSIX file tempDataFolderPosix) as string
					
					set tempDataPosix to tempDataFolderPosix & tempDataName
					set tempDataPath to tempDataFolderPath & tempDataName
					
				else
					set tempDataPath to outputFilePath
					set tempDataPosix to POSIX path of tempDataPath
				end if
				
				
				try
					close access file tempDataPath
				end try
				
				set someHandle to open for access file tempDataPath with write permission
				
				tell application "System Events"
					write someObject to someHandle
				end tell
				
				try
					close access file tempDataPath
				end try
				
			on error errMsg number errNum
				if debugMode then my logConsole(ScriptName, "dataObjectToUTF8: ERROR: " & errMsg & "(" & errNum & ")")
				try
					close access tempDataFile
				end try
				error errMsg number errNum
			end try
			
			if debugMode then my logConsole(ScriptName, "dataObjectToUTF8: tempDataPosix: " & tempDataPosix)
			
			if resultType is "utf8" then
				
				tell application "System Events"
					read file tempDataPath as �class utf8�
				end tell
				
				return result
				
			else if resultType is "MacPath" then
				return tempDataPath
				
			else if resultType is "Posix" then
				return POSIX path of tempDataPosix
				
			end if
			
		end dataObjectToUTF8
		
		
		
		
		
		-----------------------------------
		------ LIBRARY METHODS ------
		-----------------------------------
		
		-- Included to make certain useful functions available to scripts that use fmObjectTranslator, even when not used internally.
		
		
		
		
		on parseChars(prefs)
			-- version 1.3, Daniel A. Shockley, http://www.danshockley.com
			
			-- 1.3 - default is to consider case
			
			set defaultPrefs to {considerCase:true}
			
			
			if class of prefs is list then
				if (count of prefs) is greater than 2 then
					-- get any parameters after the initial 3
					set prefs to {sourceText:item 1 of prefs, parseString:item 2 of prefs, considerCase:item 3 of prefs}
				else
					set prefs to {sourceText:item 1 of prefs, parseString:item 2 of prefs}
				end if
				
			else if class of prefs is not equal to (class of {someKey:3}) then
				-- Test by matching class to something that IS a record to avoid FileMaker namespace conflict with the term "record"
				
				error "The parameter for 'parseChars()' should be a record or at least a list. Wrap the parameter(s) in curly brackets for easy upgrade to 'parseChars() version 1.3. " number 1024
				
			end if
			
			set prefs to prefs & defaultPrefs
			
			set sourceText to sourceText of prefs
			set parseString to parseString of prefs
			set considerCase to considerCase of prefs
			
			set oldDelims to AppleScript's text item delimiters
			try
				set AppleScript's text item delimiters to the {parseString as string}
				
				if considerCase then
					considering case
						set the parsedList to every text item of sourceText
					end considering
				else
					ignoring case
						set the parsedList to every text item of sourceText
					end ignoring
				end if
				
				set AppleScript's text item delimiters to oldDelims
				return parsedList
			on error errMsg number errNum
				try
					set AppleScript's text item delimiters to oldDelims
				end try
				error "ERROR: parseChars() handler: " & errMsg number errNum
			end try
		end parseChars
		
		
		
		on replaceSimple(prefs)
			-- version 1.4, Daniel A. Shockley http://www.danshockley.com
			
			-- 1.4 - Convert sourceText to string, since the previous version failed on numbers. 
			-- 1.3 - The class record is specified into a variable to avoid a namespace conflict when run within FileMaker. 
			-- 1.2 - changes parameters to a record to add option to CONSIDER CASE, since the default changed to ignoring case with Snow Leopard. This handler defaults to CONSIDER CASE = true, since that was what older code expected. 
			-- 1.1 - coerces the newChars to a STRING, since other data types do not always coerce
			--     (example, replacing "nine" with 9 as number replaces with "")
			
			set defaultPrefs to {considerCase:true}
			
			if class of prefs is list then
				if (count of prefs) is greater than 3 then
					-- get any parameters after the initial 3
					set prefs to {sourceText:item 1 of prefs, oldChars:item 2 of prefs, newChars:item 3 of prefs, considerCase:item 4 of prefs}
				else
					set prefs to {sourceText:item 1 of prefs, oldChars:item 2 of prefs, newChars:item 3 of prefs}
				end if
				
			else if class of prefs is not equal to (class of {someKey:3}) then
				-- Test by matching class to something that IS a record to avoid FileMaker namespace conflict with the term "record"
				
				error "The parameter for 'replaceSimple()' should be a record or at least a list. Wrap the parameter(s) in curly brackets for easy upgrade to 'replaceSimple() version 1.3. " number 1024
				
			end if
			
			set prefs to prefs & defaultPrefs
			
			set considerCase to considerCase of prefs
			set sourceText to sourceText of prefs
			set oldChars to oldChars of prefs
			set newChars to newChars of prefs
			
			set sourceText to sourceText as string
			
			set oldDelims to AppleScript's text item delimiters
			set AppleScript's text item delimiters to the oldChars
			if considerCase then
				considering case
					set the parsedList to every text item of sourceText
					set AppleScript's text item delimiters to the {(newChars as string)}
					set the newText to the parsedList as string
				end considering
			else
				ignoring case
					set the parsedList to every text item of sourceText
					set AppleScript's text item delimiters to the {(newChars as string)}
					set the newText to the parsedList as string
				end ignoring
			end if
			set AppleScript's text item delimiters to oldDelims
			return newText
			
		end replaceSimple
		
		
		on patternCount(prefs)
			-- version 1.2   -   default is to consider case
			
			
			set defaultPrefs to {considerCase:true}
			
			
			if class of prefs is list then
				if (count of prefs) is greater than 2 then
					-- get any parameters after the initial 3
					set prefs to {sourceText:item 1 of prefs, searchString:item 2 of prefs, considerCase:item 3 of prefs}
				else
					set prefs to {sourceText:item 1 of prefs, searchString:item 2 of prefs}
				end if
				
			else if class of prefs is not equal to (class of {someKey:3}) then
				-- Test by matching class to something that IS a record to avoid FileMaker namespace conflict with the term "record"
				
				error "The parameter for 'patternCount()' should be a record or at least a list. Wrap the parameter(s) in curly brackets for easy upgrade to 'patternCount() version 1.2. " number 1024
				
			end if
			
			
			set prefs to prefs & defaultPrefs
			
			set searchString to searchString of prefs
			set sourceText to sourceText of prefs
			set considerCase to considerCase of prefs
			
			set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, searchString as string}
			try
				if considerCase then
					considering case
						set patternCountResult to (count of (text items of sourceText)) - 1
					end considering
				else
					ignoring case
						set patternCountResult to (count of (text items of sourceText)) - 1
					end ignoring
				end if
				
				set AppleScript's text item delimiters to oldDelims
				
				return patternCountResult
			on error errMsg number errNum
				try
					set AppleScript's text item delimiters to oldDelims
				end try
				error "ERROR: patternCount() handler: " & errMsg number errNum
			end try
		end patternCount
		
		
		on logConsole(processName, consoleMsg)
			-- version 1.9 - Daniel A. Shockley, http://www.danshockley.com
			
			-- 1.9 - REQUIRES coerceToString to enable logging of objects not directly coercible to string.
			-- 1.8 - coerces to string first (since numbers would not directly convert for 'quoted form'
			-- 1.7 - now works with Leopard by using the "logger" command instead of just appending to log file
			-- 1.6 - the 'space' constant instead of literal spaces for readability, removed trailing space from the hostname command
			-- 1.5 - uses standard date-stamp format	
			
			set shellCommand to "logger" & space & "-t" & space & quoted form of processName & space & quoted form of coerceToString(consoleMsg)
			
			do shell script shellCommand
			return shellCommand
		end logConsole
		
		
		
		
		on coerceToString(incomingObject)
			-- version 1.8, Daniel A. Shockley, http://www.danshockley.com
			-- 1.8 - instead of trying to store the error message use, generate it
			-- 1.7 -  added "Can't make " with a curly single-quote. 
			-- 1.6 -  can add additional errMsg parts (just add to lists to handle other languages. 
			--             Currently handles English in both 10.3 and 10.4 (10.3 uses " into a number." 
			--             while 10.4 uses " into type number.")
			-- 1.5 -  added Unicode Text
			
			set errMsgLeadList to {"Can't make ", "Can�t make "}
			set errMsgTrailList to {" into a number.", " into type number."}
			
			if class of incomingObject is string then
				set {text:incomingObject} to (incomingObject as string)
				return incomingObject
			else if class of incomingObject is integer then
				set {text:incomingObject} to (incomingObject as string)
				return incomingObject as string
			else if class of incomingObject is real then
				set {text:incomingObject} to (incomingObject as string)
				return incomingObject as string
			else if class of incomingObject is Unicode text then
				set {text:incomingObject} to (incomingObject as string)
				return incomingObject as string
			else
				-- LIST, RECORD, styled text, or unknown
				try
					try
						"XXXX" as number
						-- GENERATE the error message for a known string so we can get 
						-- the 'lead' and 'trail' part of the error message
					on error errMsg number errNum
						set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {"\"XXXX\""}}
						set {errMsgLead, errMsgTrail} to text items of errMsg
						set AppleScript's text item delimiters to oldDelims
					end try
					
					
					set testMultiply to 1 * incomingObject -- now, generate error message for OUR item
					
					-- what items is THIS used for?
					-- how does script ever get past the above step??
					set listText to (first character of incomingObject)
					
				on error errMsg
					--tell me to log errMsg
					set objectString to errMsg
					
					if objectString contains errMsgLead then
						set {od, AppleScript's text item delimiters} to {AppleScript's text item delimiters, errMsgLead}
						set objectString to text item 2 of objectString
						set AppleScript's text item delimiters to od
					end if
					
					if objectString contains errMsgTrail then
						set {od, AppleScript's text item delimiters} to {AppleScript's text item delimiters, errMsgTrail}
						set AppleScript's text item delimiters to errMsgTrail
						set objectString to text item 1 of objectString
						set AppleScript's text item delimiters to od
					end if
					
					
					set {text:objectString} to (objectString as string)
				end try
				
				return objectString
			end if
		end coerceToString
		
		
		
		
		
		on getTextBetween(prefs)
			-- version 1.6, Daniel A. Shockley <http://www.danshockley.com>
			
			-- gets the text between specified occurrence of beforeText and afterText in sourceText
			-- the default textItemNum should be 2
			
			-- 1.6 - option to INCLUDE the before and after strings. Default is FALSE. Must use record parameter to use this feature. 
			-- 1.5 - use 'class of prefs as string' to test, since FileMaker wrecks the term record
			
			-- USAGE1: getTextBetween({sourceTEXT, beforeTEXT, afterTEXT})
			-- USAGE2: getTextBetween({sourceText: sourceTEXT, beforeText: beforeTEXT, afterText: afterTEXT})
			
			
			set defaultPrefs to {textItemNum:2, includeMarkers:false}
			
			if (class of prefs is not list) and ((class of prefs) as string is not "record") then
				error "getTextBetween FAILED: parameter should be a record or list. If it is multiple items, just make it into a list to upgrade to this handler." number 1024
			end if
			if class of prefs is list then
				if (count of prefs) is 4 then
					set textItemNum of defaultPrefs to item 4 of prefs
				end if
				set prefs to {sourceText:item 1 of prefs, beforeText:item 2 of prefs, afterText:item 3 of prefs}
			end if
			set prefs to prefs & defaultPrefs -- add on default preferences, if needed
			set sourceText to sourceText of prefs
			set beforeText to beforeText of prefs
			set afterText to afterText of prefs
			set textItemNum to textItemNum of prefs
			set includeMarkers to includeMarkers of prefs
			
			try
				set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, beforeText}
				set the prefixRemoved to text item textItemNum of sourceText
				set AppleScript's text item delimiters to afterText
				set the finalResult to text item 1 of prefixRemoved
				set AppleScript's text item delimiters to oldDelims
				
				if includeMarkers then set finalResult to beforeText & finalResult & afterText
				
			on error errMsg number errNum
				set AppleScript's text item delimiters to oldDelims
				-- 	tell me to log "Error in getTextBetween() : " & errMsg
				set the finalResult to "" -- return nothing if the surrounding text is not found
			end try
			
			
			return finalResult
			
		end getTextBetween
		
		
		on recordFromList(assocList)
			-- version 2003-11-06, Nigel Garvey, AppleScript-Users mailing list
			try
				{�class usrf�:assocList}'s x
			on error msg
				return msg
				run script text 16 thru -2 of msg
			end try
		end recordFromList
		
		
		
		
		
	end script
	
	run fmObjectTranslator
	
	return fmObjectTranslator
	
	
end fmObjectTranslator_Instantiate










