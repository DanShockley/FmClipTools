-- FM-XML Objects to Multi-Objects
-- version 3.9.3, Daniel A. Shockley
-- Takes objects in the clipboard and adds multiple types of FileMaker objects into clipboard (plus return-delimited text). 


-- 3.9.3 - 2017-08-09 ( eshagdar ): renamed 'FM-XML Objects to Multi-Objects' to 'fmClip - FM Objects to Multi-Objects' to match other handler name pattern
-- 3.9.2 - if the clipboard is text without double-colons then assume those aren't fields, but rather Variable names; Also, if the clipboard contains Set Variable script steps, extract the variable Name and Value into tab-separated columns. 
-- 3.9.1 - now works if the clipboard contains text (assumes those are fully-qualified field names).
-- 3.9 (skipped version numbers) - uses fmObjectTranslator 3.9.
-- 2.2 - extract field objects _wthin_ other layout objects
-- 2.1 - updated flattenList to avoid namespace conflict; 
-- 2.0 - modified to INCLUDE FM12 Layout Objects (as well as FM11, not instead of).
-- 1.8 - asking for table name actually ASKS for table name.
-- 1.7 - trims off extraneous line return at end of original text source, rather than silently failing. 
-- 1.6 - added error-trapping during the conversions to different FM objects. 
-- 1.5 - when original is BaseTables, look at the fields of each BaseTable and then process. BUT, do NOT try to create BaseTable objects from other sources. BaseTable is source-only, and just treated like a bunch of fields. 
-- 1.4 - when original is TEXT, preserve and add back that, rather than only plain. 
-- 1.3 - bug fix: if original format is clipboard, need to SET to others first, then add text last, or only the last 'set' FM object actually sticks. 
-- 1.2 - bug fix: when source is script steps, process ANY script step that has a FIELD, but flatten list.
-- 1.1 - fixed default NumFormat for field to "As Entered"
-- 1.0 - initial version, which generates LayoutObjects, FieldDefs, ScriptSteps(SetField), and plain text.


property ScriptName : "FMXML Multi"

property debugMode : false

property fieldTableSep : "::"
property targetValueSep : ASCII character 9

on run
	
	
	if debugMode then my logConsole(ScriptName, "Starting.")
	
	set objTrans to fmObjectTranslator_Instantiate({})
	
	try
		set someXML to clipboardGetObjectsAsXML({}) of objTrans
	on error errMsg number errNum
		set someXML to ""
	end try
	
	set originalClipboardFormat to currentCode of objTrans
	
	if debugMode then my logConsole(ScriptName, "original clip: " & originalClipboardFormat)
	
	if originalClipboardFormat is "" then
		-- PLAIN TEXT??  (assume it is)
		set fieldNames to get the clipboard
		set fieldNames to my trimWhitespace(fieldNames)
		set fieldNames to my parseChars({fieldNames, return})
		
		if class of fieldNames is not class of {1, 2} then set fieldNames to {fieldNames}
		
		set firstListItem to item 1 of fieldNames
		if firstListItem does not contain fieldTableSep then
			set varNamesOptionalValues to fieldNames
			set fieldNames to ""
		end if
		
		
		set originalClipboardFormat to "TEXT"
		
		-- END:		PLAIN TEXT. 
		
	else if originalClipboardFormat is "XML2" or originalClipboardFormat is "XMLO" then
		-- FM12 LAYOUT OBJECTS: 
		-- or FM11 LAYOUT OBJECTS: 
		
		tell application "System Events"
			set fieldDefXmlData to make new XML data with data someXML
			
			set foundFieldObjects to my getXMLElementsByName("FieldObj", XML element 1 of fieldDefXmlData)
			
			set fieldNames to {}
			repeat with oneFieldObject in foundFieldObjects
				set oneFieldName to (value of first XML element of oneFieldObject whose name is "Name")
				copy oneFieldName to end of fieldNames
			end repeat
		end tell
		
		-- result MIGHT BE nested lists, so flatten that list: 
		set fieldNames to flattenList(fieldNames)
		
		-- END:		FM11/12 LAYOUT OBJECTS. 		
		
	else if originalClipboardFormat is "XMFD" then
		-- FIELD DEFINITIONS: 
		
		tell application "System Events"
			set fieldDefXmlData to make new XML data with data someXML
			
			set fieldShortNames to value of XML attribute "name" of (every XML element of XML element 1 of fieldDefXmlData whose name is "Field")
		end tell
		-- result DOES NOT INCLUDE THE TABLE!
		tell application "System Events"
			if name of window 1 of application process "FileMaker Pro Advanced" starts with "Manage Database for" then
				set tableName to value of pop up button 1 of tab group 1 of window 1 of application process "FileMaker Pro Advanced"
			else
				set tableName to text returned of (display dialog "Please enter the table name for these field objects." default answer "")
			end if
		end tell
		
		set fieldNames to tableName & "::" & my unParseChars(fieldShortNames, return & tableName & "::")
		set fieldNames to my parseChars({fieldNames, return})
		
		-- END:		FIELD DEFS. 
		
		
	else if originalClipboardFormat is "XMSS" then
		-- SCRIPT STEPS: 
		tell application "System Events"
			set fieldDefXmlData to make new XML data with data someXML
			
			set fieldShortNames to value of XML attribute "name" of (every XML element of (every XML element of XML element 1 of fieldDefXmlData whose name is "Step") whose name is "Field")
			set fieldTableNames to value of XML attribute "table" of (every XML element of (every XML element of XML element 1 of fieldDefXmlData whose name is "Step") whose name is "Field")
			
			set fieldShortNames to my flattenList(fieldShortNames)
			set fieldTableNames to my flattenList(fieldTableNames)
			
			
			set fieldNames to {}
			repeat with i from 1 to count of fieldShortNames
				
				set oneFieldShortName to item i of fieldShortNames
				set oneTableName to item i of fieldTableNames
				
				copy (oneTableName & "::" & oneFieldShortName) as string to end of fieldNames
				
			end repeat
			
			
			if (count of fieldShortNames) is 0 then
				
				-- Look for Set Variable script steps, then put their names and values into text for the clipboard. 
				
				set varXmlData to make new XML data with data someXML
				
				set varNames to value of every XML element of (every XML element of (every XML element of (XML element 1 of varXmlData) whose name is "Step") whose name is "Name")
				set varValues to value of XML element "Calculation" of (every XML element of (every XML element of (every XML element of (XML element 1 of varXmlData) whose name is "Step") whose name is "Value"))
				
				set varNames to my flattenList(varNames)
				set varValues to my flattenList(varValues)
				
				
				set varNamesOptionalValues to {}
				repeat with i from 1 to count of varNames
					
					set oneVarName to item i of varNames
					set oneVarValue to item i of varValues
					
					
					copy (oneVarName & targetValueSep & oneVarValue) as string to end of varNamesOptionalValues
					
				end repeat
				
				
				
				
				-- END OF: didn't find Set Field, so tried Set Variable. 
			end if
			
			
		end tell
		
		-- END:		SCRIPT STEPS. 
		
	else if originalClipboardFormat is "XMTB" then
		-- TABLES (so get their fields): 
		
		tell application "System Events"
			set fieldDefXmlData to make new XML data with data someXML
			
			set baseTableNames to value of XML attribute "name" of (every XML element of XML element 1 of fieldDefXmlData whose name is "BaseTable")
			
			if debugMode then my logConsole(ScriptName, "Tables: " & my unParseChars(baseTableNames, ", "))
			
			set fieldNames to {}
			
			repeat with oneBaseTable in baseTableNames
				set oneBaseTable to contents of oneBaseTable
				
				set oneTableFieldShortNames to value of XML attribute "name" of (every XML element of (first XML element of XML element 1 of fieldDefXmlData whose value of XML attribute "name" is oneBaseTable) whose name is "Field")
				
				set oneTableFieldRefs to oneBaseTable & "::" & my unParseChars(oneTableFieldShortNames, return & oneBaseTable & "::")
				set oneTableFieldRefs to my parseChars({oneTableFieldRefs, return})
				
				repeat with oneFieldRef in oneTableFieldRefs
					set oneFieldRef to contents of oneFieldRef
					copy oneFieldRef to end of fieldNames
				end repeat
			end repeat
		end tell
		-- END:		TABLES. 
		
	end if
	
	
	
	
	
	
	if originalClipboardFormat is "TEXT" then
		set textClipboard to my preserveClipboard()
	end if
	
	
	if originalClipboardFormat is not "XMLO" or originalClipboardFormat is "TEXT" then
		
		if (count of fieldNames) is not 0 then
			
			set layoutObjectsFm11_XML to addFieldsAsLayoutObjectsFM11(fieldNames)
			
			if originalClipboardFormat is "TEXT" then
				-- NOTE: if original is TEXT, need to wipe out original clipboard by setting to FM Objects FIRST, then add TEXT at end of script:
				
				set currentCode of objTrans to "XMLO"
				
				set newObjects to convertXmlToObjects(layoutObjectsFm11_XML) of objTrans
				
				set newClip to {Çclass XMLOÈ:newObjects}
				
				set the clipboard to newClip
				
			end if
		end if
		
	end if
	
	
	if originalClipboardFormat is not "XML2" then
		
		if (count of fieldNames) is not 0 then
			set layoutObjectsFm12_XML to addFieldsAsLayoutObjectsFM12(fieldNames)
		end if
		
	end if
	
	
	
	
	if originalClipboardFormat is not "XMSS" then
		
		if (count of fieldNames) is not 0 then
			-- they DID have table::field notation, so make Set Field steps:
			set scriptStepsXML to addFieldsAsScriptSteps(fieldNames)
			
		else if (count of varNamesOptionalValues) is not 0 then
			-- try using as variable names instead:
			-- 3.9.2 - check whether we should use the source text as variables (with optional values) instead of hoping they are field references 	
			
			set scriptStepsXML to addTextToVariableScriptSteps(varNamesOptionalValues)
			
			get the clipboard as Çclass XMSSÈ
			return result
			
		end if
		
	end if
	
	
	if originalClipboardFormat is not "XMFD" and originalClipboardFormat is not "XMTB" then
		-- treat Table like Fields (so don't add fields if it was either). 
		
		if (count of fieldNames) is not 0 then
			set fieldDefsXML to addFieldsAsFieldDefs(fieldNames)
		end if
		
	end if
	
	
	-- NOW, add them in as text, too, even if already there: 
	set fmClipboard to get the clipboard
	
	if originalClipboardFormat is "TEXT" then
		-- RESTORE what was saved above: 
		set newClip to textClipboard & fmClipboard
	else if (count of fieldNames) is not 0 then
		
		set fieldNamesListAsText to unParseChars(fieldNames, return)
		set newClip to {string:fieldNamesListAsText} & fmClipboard
	else if (count of varNamesOptionalValues) is not 0 then
		set varNamesValuesListAsText to unParseChars(varNamesOptionalValues, return)
		set newClip to {string:varNamesValuesListAsText} & fmClipboard
	end if
	set the clipboard to newClip
	
	return originalClipboardFormat
	
	
	
end run





on addTextToVariableScriptSteps(nameOptionalValueList)
	
	script textToVariableScriptSteps
		
		property headerScriptStepsXML : "<fmxmlsnippet type=\"FMObjectList\">"
		property footerScriptStepsXML : "</fmxmlsnippet>"
		property stepStartXML : "<Step enable=\"True\" id=\"141\" name=\"Set Variable\">"
		property varValuePrefixXML : "<Value>"
		property valueCalcPrefixXML : "<Calculation><![CDATA["
		property valueCalcSuffixXML : "]]></Calculation>"
		property varValueSuffixXML : "</Value>"
		property repPrefixXML : "<Repetition><Calculation><![CDATA["
		property repSuffixXML : "]]></Calculation></Repetition>"
		property varNamePrefixXML : "<Name>"
		property varNameSuffixXML : "</Name>"
		property stepEndXML : "</Step>"
		
		on run
			set objTrans to fmObjectTranslator_Instantiate({})
			
			set colSep to ASCII character 9
			
			if item 1 of nameOptionalValueList contains colSep then
				set hasVarValue to true
			else
				set hasVarValue to false
			end if
			
			set buildingXML to headerScriptStepsXML
			
			
			repeat with oneStep in nameOptionalValueList
				set oneStepRAW to contents of oneStep
				
				if hasVarValue then
					set {varName, varValue} to parseChars({oneStepRAW, colSep})
				else
					set varName to oneStepRAW
					set varValue to "\"\""
				end if
				
				if varName contains "[" and varName contains "]" then
					set repNum to getTextBetweenMultiple(varName, "[", "]")
					set varName to item 1 of parseChars({varName, "["})
				else
					set repNum to 1
				end if
				
				if varName does not start with "$" then set varName to "$" & varName
				
				
				
				if length of varName is greater than 0 then
					
					set oneScriptStep to ""
					set oneScriptStep to oneScriptStep & stepStartXML
					set oneScriptStep to oneScriptStep & varValuePrefixXML
					set oneScriptStep to oneScriptStep & valueCalcPrefixXML
					set oneScriptStep to oneScriptStep & varValue
					set oneScriptStep to oneScriptStep & valueCalcSuffixXML
					set oneScriptStep to oneScriptStep & varValueSuffixXML
					set oneScriptStep to oneScriptStep & repPrefixXML
					set oneScriptStep to oneScriptStep & repNum
					set oneScriptStep to oneScriptStep & repSuffixXML
					set oneScriptStep to oneScriptStep & varNamePrefixXML
					set oneScriptStep to oneScriptStep & varName
					set oneScriptStep to oneScriptStep & varNameSuffixXML
					set oneScriptStep to oneScriptStep & stepEndXML
					
					set buildingXML to buildingXML & return & oneScriptStep
				end if
				
			end repeat
			
			
			set buildingXML to buildingXML & return & footerScriptStepsXML
			
			set currentCode of objTrans to "XMSS"
			
			set scriptStepsObjects to convertXmlToObjects(buildingXML) of objTrans
			
			
			set fmClipboard to get the clipboard
			
			set newClip to {Çclass XMSSÈ:scriptStepsObjects} & fmClipboard
			
			set the clipboard to newClip
			
			return buildingXML
			
			
			
		end run
		
	end script
	
	
	run textToVariableScriptSteps
	
end addTextToVariableScriptSteps









on addFieldsAsLayoutObjectsFM12(fieldNameList)
	
	script fieldsToLayoutObjects
		
		property pixelLayoutTop : 10
		property pixelsVerticalBetweenFields : 22
		property pixelLabelTopStart : pixelLayoutTop + 3
		property pixelLabelHeight : 16
		property pixelFieldTopStart : 10
		property pixelFieldHeight : 20
		
		property headerXML : "<?xml version=\"1.0\" encoding=\"utf-8\"?>" & return & "<fmxmlsnippet type=\"LayoutObjectList\">"
		property footerXML : "</fmxmlsnippet>"
		property templateLayoutOpenXML : "<Layout enclosingRectTop =\"###LAYOUT_TOP###\" enclosingRectLeft =\" 3.000000\" enclosingRectBottom =\"###LAYOUT_BOTTOM###\" enclosingRectRight =\"367.000000\">"
		
		property layoutFooterXML : "</Layout>"
		
		
		(*  ##################################################################### *)
		(*  ##################################################################### *)
		
		
		property templateLabelXML : "<Object type=\"Text\" key=\"###OBJECT_KEY###\" LabelKey=\"0\" flags=\"0\" rotation=\"0\">
<Bounds top=\"###LABEL_TOP###\" left=\" 3.000000\" bottom=\"###LABEL_BOTTOM###\" right=\"203.000000\"/>
<TextObj flags=\"0\">
<ExtendedAttributes fontHeight=\"12\" graphicFormat=\"0\">
<NumFormat flags=\"0\" charStyle=\"0\" negativeStyle=\"0\" currencySymbol=\"\" thousandsSep=\"0\" decimalPoint=\"0\" negativeColor=\"#0\" decimalDigits=\"0\" trueString=\"\" falseString=\"\"/>
<DateFormat format=\"0\" charStyle=\"0\" monthStyle=\"0\" dayStyle=\"0\" separator=\"0\">
<DateElement>0</DateElement>
<DateElement>0</DateElement>
<DateElement>0</DateElement>
<DateElement>0</DateElement>
<DateElementSep index=\"0\"></DateElementSep>
<DateElementSep index=\"1\"></DateElementSep>
<DateElementSep index=\"2\"></DateElementSep>
<DateElementSep index=\"3\"></DateElementSep>
<DateElementSep index=\"4\"></DateElementSep>
</DateFormat>
<TimeFormat flags=\"0\" charStyle=\"0\" hourStyle=\"0\" minsecStyle=\"0\" separator=\"0\" amString=\"\" pmString=\"\" ampmString=\"\"/>
</ExtendedAttributes>
<Styles>
<LocalCSS>
self&#10;{&#10;&#09;font-family: -fm-font-family(arial,sans-serif,roman);&#10;&#09;font-weight: normal;&#10;&#09;font-stretch: normal;&#10;&#09;font-style: normal;&#10;&#09;font-variant: normal;&#10;&#09;font-size: 11pt;&#10;&#09;color: rgba(40.3922%,40.3922%,40.3922%,1);&#10;&#09;line-height: 1line;&#10;&#09;text-align: right;&#10;&#09;text-transform: none;&#10;&#09;-fm-strikethrough: false;&#10;&#09;-fm-underline: none;&#10;&#09;-fm-glyph-variant: ;&#10;&#09;-fm-highlight-color: rgba(0%,0%,0%,0);&#10;}&#10;</LocalCSS>
</Styles>
<CharacterStyleVector>
<Style>
<Data>###LABEL_TEXT###</Data>
<CharacterStyle mask=\"32695\">
<Font-family codeSet=\"Roman\" fontId=\"21\">arial,sans-serif</Font-family>
<Font-size>11</Font-size>
<Face>0</Face>
<Color>#676767</Color>
</CharacterStyle>
</Style>
</CharacterStyleVector>
<ParagraphStyleVector>
<Style>
<Data>###LABEL_TEXT###</Data>
<ParagraphStyle mask=\"0\">
</ParagraphStyle>
</Style>
</ParagraphStyleVector>
</TextObj>
</Object>" & return
		
		property templateFieldXML : "<Object type=\"Field\" key=\"###OBJECT_KEY###\" LabelKey=\"###LABEL_KEY###\" flags=\"0\" rotation=\"0\">
<Bounds top=\"###FIELD_TOP###\" left=\"207.000000\" bottom=\"###FIELD_BOTTOM###\" right=\"367.000000\"/>
<FieldObj numOfReps=\"1\" flags=\"32\" inputMode=\"0\" displayType=\"0\" quickFind=\"1\" pictFormat=\"5\">
<Name>###TOCNAME###::###FIELDNAMESHORT###</Name>
<ExtendedAttributes fontHeight=\"12\" graphicFormat=\"5\">
<NumFormat flags=\"2304\" charStyle=\"0\" negativeStyle=\"0\" currencySymbol=\"$\" thousandsSep=\"44\" decimalPoint=\"46\" negativeColor=\"#DD000000\" decimalDigits=\"2\" trueString=\"Yes\" falseString=\"No\"/>
<DateFormat format=\"0\" charStyle=\"0\" monthStyle=\"0\" dayStyle=\"0\" separator=\"47\">
<DateElement>3</DateElement>
<DateElement>6</DateElement>
<DateElement>1</DateElement>
<DateElement>8</DateElement>
<DateElementSep index=\"0\"></DateElementSep>
<DateElementSep index=\"1\">, </DateElementSep>
<DateElementSep index=\"2\"> </DateElementSep>
<DateElementSep index=\"3\">, </DateElementSep>
<DateElementSep index=\"4\"></DateElementSep>
</DateFormat>
<TimeFormat flags=\"143\" charStyle=\"0\" hourStyle=\"0\" minsecStyle=\"1\" separator=\"58\" amString=\" AM\" pmString=\" PM\" ampmString=\"\"/>
</ExtendedAttributes>
<DDRInfo>
<Field name=\"###FIELDNAMESHORT###\" id=\"1\" repetition=\"1\" maxRepetition=\"1\" table=\"###TOCNAME###\"/>
</DDRInfo>
</FieldObj>
</Object>
"
		
		
		on fmPrecisionCoordString(someNumber)
			
			set integerPart to someNumber div 1
			
			set decimalPart to someNumber - integerPart
			
			set decimalPartAsString to (decimalPart as string)
			if decimalPartAsString contains "." then
				set decimalPartAsString to text 3 thru -1 of decimalPartAsString
			end if
			
			set decimalPartAsString to text 1 thru 6 of (decimalPartAsString & "000000")
			
			return (integerPart as string) & "." & decimalPartAsString
			
		end fmPrecisionCoordString
		
		
		
		
		
		on run
			set objTrans to fmObjectTranslator_Instantiate({})
			
			
			
			set buildingXML to headerXML
			
			(*
		property pixelLayoutTop : 10
		property pixelsVerticalBetweenFields : 24
		property pixelLabelTopStart : pixelLayoutTop + 2
		property pixelLabelHeight : 13
		property pixelFieldTopStart : pixelLayoutTop
		property pixelFieldHeight : 16
*)
			
			
			-- Need to build FIELD (and label) OBJECTs XML first, so we know the total bounding dimensions (bottom)
			set objectKey to 0
			set objectsXML to ""
			repeat with i from 1 to count of fieldNameList
				set oneFieldName to item i of fieldNameList
				set oneFieldName to oneFieldName as string
				
				if length of oneFieldName is greater than 0 then
					
					set pixelLabelTop to pixelLabelTopStart + (i - 1) * pixelsVerticalBetweenFields
					set pixelLabelBottom to pixelLabelTop + pixelLabelHeight
					
					set pixelFieldTop to pixelFieldTopStart + (i - 1) * pixelsVerticalBetweenFields
					set pixelFieldBottom to pixelFieldTop + pixelFieldHeight
					
					set {tocName, fieldNameShort} to parseChars({oneFieldName, "::"})
					
					
					set objectKey to objectKey + 1 -- increment the objectKey for this next object
					
					
					set oneLabelXML to templateLabelXML
					set oneLabelXML to my replaceSimple({oneLabelXML, "###OBJECT_KEY###", objectKey})
					set oneLabelXML to my replaceSimple({oneLabelXML, "###LABEL_TOP###", fmPrecisionCoordString(pixelLabelTop)})
					set oneLabelXML to my replaceSimple({oneLabelXML, "###LABEL_BOTTOM###", fmPrecisionCoordString(pixelLabelBottom)})
					set oneLabelXML to my replaceSimple({oneLabelXML, "###LABEL_TEXT###", fieldNameShort})
					
					
					set labelKey to objectKey
					set objectKey to objectKey + 1 -- increment the objectKey for this next object
					
					set oneFieldXML to templateFieldXML
					set oneLabelXML to my replaceSimple({oneLabelXML, "###OBJECT_KEY###", objectKey})
					set oneLabelXML to my replaceSimple({oneLabelXML, "###LABEL_KEY###", labelKey})
					set oneFieldXML to my replaceSimple({oneFieldXML, "###FIELD_TOP###", fmPrecisionCoordString(pixelFieldTop)})
					set oneFieldXML to my replaceSimple({oneFieldXML, "###FIELD_BOTTOM###", fmPrecisionCoordString(pixelFieldBottom)})
					set oneFieldXML to my replaceSimple({oneFieldXML, "###FIELDNAMESHORT###", fieldNameShort})
					set oneFieldXML to my replaceSimple({oneFieldXML, "###TOCNAME###", tocName})
					
					
					set objectsXML to objectsXML & return & oneLabelXML & return & oneFieldXML
				end if
				
			end repeat
			
			set pixelLayoutBottom to pixelFieldBottom -- bottom of final field is bottom of LAYOUT bounds
			
			
			set layoutHeaderXML to templateLayoutOpenXML
			set layoutHeaderXML to my replaceSimple({layoutHeaderXML, "###LAYOUT_TOP###", fmPrecisionCoordString(pixelLayoutTop)})
			set layoutHeaderXML to my replaceSimple({layoutHeaderXML, "###LAYOUT_BOTTOM###", fmPrecisionCoordString(pixelLayoutBottom)})
			
			
			set buildingXML to buildingXML & return & layoutHeaderXML
			
			
			set buildingXML to buildingXML & return & objectsXML
			
			
			set buildingXML to buildingXML & return & layoutFooterXML
			
			set buildingXML to buildingXML & return & footerXML
			
			
			-- DONE BUILDING XML: 
			
			set currentCode of objTrans to "XML2"
			
			set newObjects to convertXmlToObjects(buildingXML) of objTrans
			
			
			set fmClipboard to get the clipboard
			
			set newClip to {Çclass XML2È:newObjects} & fmClipboard
			
			set the clipboard to newClip
			
			return buildingXML
			
			
			
		end run
		
		
		
		
		
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
		
		
	end script
	
	
	run fieldsToLayoutObjects
	
end addFieldsAsLayoutObjectsFM12











on addFieldsAsLayoutObjectsFM11(fieldNameList)
	
	script fieldsToLayoutObjects
		
		property pixelLayoutTop : 10
		property pixelsVerticalBetweenFields : 18
		property pixelLabelTopStart : pixelLayoutTop + 2
		property pixelLabelHeight : 13
		property pixelFieldTopStart : 10
		property pixelFieldHeight : 16
		
		property headerXML : "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" & return & "<fmxmlsnippet type=\"LayoutObjectList\">"
		property footerXML : "</fmxmlsnippet>"
		property templateLayoutOpenXML : "<Layout enclosingRectTop =\"###LAYOUT_TOP###\" enclosingRectLeft =\" 3.000000\" enclosingRectBottom =\"###LAYOUT_BOTTOM###\" enclosingRectRight =\"367.000000\">"
		
		property layoutFooterXML : "</Layout>"
		
		property layoutObjectStylesXML : return & Â
			"<ObjectStyle id=\"0\" fontHeight=\"11\" graphicFormat=\"5\" fieldBorders=\"15\">
<CharacterStyle mask=\"32695\">
<Font-family codeSet=\"Roman\" fontId=\"13\">Arial</Font-family>
<Font-size>10</Font-size>
<Face>256</Face>
<Color>#000000</Color>
</CharacterStyle>
<ParagraphStyle mask=\"1983\">
<Justification>3</Justification>
</ParagraphStyle>
<NumFormat flags=\"13\" charStyle=\"0\" negativeStyle=\"0\" currencySymbol=\"#\" thousandsSep=\"44\" decimalPoint=\"46\" negativeColor=\"#DD000000\" decimalDigits=\"0\" trueString=\"Yes\" falseString=\"No\"/>
<DateFormat format=\"0\" charStyle=\"0\" monthStyle=\"0\" dayStyle=\"0\" separator=\"47\">
<DateElement>3</DateElement>
<DateElement>6</DateElement>
<DateElement>1</DateElement>
<DateElement>8</DateElement>
<DateElementSep index=\"0\"></DateElementSep>
<DateElementSep index=\"1\">, </DateElementSep>
<DateElementSep index=\"2\"> </DateElementSep>
<DateElementSep index=\"3\">, </DateElementSep>
<DateElementSep index=\"4\"></DateElementSep>
</DateFormat>
<TimeFormat flags=\"143\" charStyle=\"0\" hourStyle=\"0\" minsecStyle=\"1\" separator=\"58\" amString=\" AM\" pmString=\" PM\" ampmString=\"\"/>
<DrawStyle linePat=\"2\" lineWidth=\"1\" lineColor=\"#0\" fillPat=\"1\" fillEffect=\"0\" fillColor=\"#FFFFFF00\"/>
<AltLineStyle linePat=\"7\" lineWidth=\"1\" lineColor=\"#0\"/>
</ObjectStyle>" & return & return & "<ObjectStyle id=\"1\" fontHeight=\"14\" graphicFormat=\"5\" fieldBorders=\"15\">
<CharacterStyle mask=\"32695\">
<Font-family codeSet=\"Roman\" fontId=\"13\">Arial</Font-family>
<Font-size>12</Font-size>
<Face>0</Face>
<Color>#000000</Color>
</CharacterStyle>
<ParagraphStyle mask=\"1983\">
<LeftMargin>  1.000000</LeftMargin>
<RightMargin>  1.000000</RightMargin>
</ParagraphStyle>
<NumFormat flags=\"13\" charStyle=\"0\" negativeStyle=\"0\" currencySymbol=\"#\" thousandsSep=\"44\" decimalPoint=\"46\" negativeColor=\"#DD000000\" decimalDigits=\"0\" trueString=\"Yes\" falseString=\"No\"/>
<DateFormat format=\"0\" charStyle=\"0\" monthStyle=\"0\" dayStyle=\"0\" separator=\"47\">
<DateElement>3</DateElement>
<DateElement>6</DateElement>
<DateElement>1</DateElement>
<DateElement>8</DateElement>
<DateElementSep index=\"0\"></DateElementSep>
<DateElementSep index=\"1\">, </DateElementSep>
<DateElementSep index=\"2\"> </DateElementSep>
<DateElementSep index=\"3\">, </DateElementSep>
<DateElementSep index=\"4\"></DateElementSep>
</DateFormat>
<TimeFormat flags=\"143\" charStyle=\"0\" hourStyle=\"0\" minsecStyle=\"1\" separator=\"58\" amString=\" AM\" pmString=\" PM\" ampmString=\"\"/>
<DrawStyle linePat=\"2\" lineWidth=\"1\" lineColor=\"#0\" fillPat=\"1\" fillEffect=\"0\" fillColor=\"#FFFFFF00\"/>
<AltLineStyle linePat=\"7\" lineWidth=\"1\" lineColor=\"#0\"/>
</ObjectStyle>" & return
		
		
		property templateLabelXML : "<Object type=\"Text\" flags=\"0\" portal=\"-1\" rotation=\"0\">
<StyleId>0</StyleId>
<Bounds top=\"###LABEL_TOP###\" left=\" 3.000000\" bottom=\"###LABEL_BOTTOM###\" right=\"203.000000\"/>
<DrawStyle linePat=\"1\" lineWidth=\"0\" lineColor=\"#FFFFFF00\" fillPat=\"1\" fillEffect=\"0\" fillColor=\"#FFFFFF00\"/>
<TextObj flags=\"0\">
<CharacterStyleVector>
<Style>
<Data>###LABEL_TEXT###</Data>
<CharacterStyle mask=\"32695\">
<Font-family codeSet=\"Roman\" fontId=\"13\">Arial</Font-family>
<Font-size>10</Font-size>
<Face>256</Face>
<Color>#000000</Color>
</CharacterStyle>
</Style>
</CharacterStyleVector>
<ParagraphStyleVector>
<Style>
<Data>###LABEL_TEXT###</Data>
<ParagraphStyle mask=\"0\">
</ParagraphStyle>
</Style>
</ParagraphStyleVector>
</TextObj>
</Object>" & return
		
		property templateFieldXML : "<Object type=\"Field\" flags=\"0\" portal=\"-1\" rotation=\"0\">
<StyleId>1</StyleId>
<Bounds top=\"###FIELD_TOP###\" left=\"207.000000\" bottom=\"###FIELD_BOTTOM###\" right=\"367.000000\"/>
<FieldObj numOfReps=\"1\" flags=\"32\" inputMode=\"0\" displayType=\"0\" quickFind=\"1\">
<Name>###TOCNAME###::###FIELDNAMESHORT###</Name>
<DDRInfo>
<Field name=\"###FIELDNAMESHORT###\" id=\"25\" repetition=\"1\" maxRepetition=\"1\" table=\"###TOCNAME###\"/>
</DDRInfo>
</FieldObj>
</Object>
"
		
		
		on fmPrecisionCoordString(someNumber)
			
			set integerPart to someNumber div 1
			
			set decimalPart to someNumber - integerPart
			
			set decimalPartAsString to (decimalPart as string)
			if decimalPartAsString contains "." then
				set decimalPartAsString to text 3 thru -1 of decimalPartAsString
			end if
			
			set decimalPartAsString to text 1 thru 6 of (decimalPartAsString & "000000")
			
			return (integerPart as string) & "." & decimalPartAsString
			
		end fmPrecisionCoordString
		
		
		
		
		
		on run
			set objTrans to fmObjectTranslator_Instantiate({})
			
			
			
			set buildingXML to headerXML
			
			(*
		property pixelLayoutTop : 10
		property pixelsVerticalBetweenFields : 24
		property pixelLabelTopStart : pixelLayoutTop + 2
		property pixelLabelHeight : 13
		property pixelFieldTopStart : pixelLayoutTop
		property pixelFieldHeight : 16
*)
			
			
			logConsole(ScriptName, count of fieldNameList)
			
			-- Need to build FIELD (and label) OBJECTs XML first, so we know the total bounding dimensions (bottom)
			set objectsXML to ""
			repeat with i from 1 to count of fieldNameList
				set oneFieldName to item i of fieldNameList
				set oneFieldName to oneFieldName as string
				
				if length of oneFieldName is greater than 0 then
					
					set pixelLabelTop to pixelLabelTopStart + (i - 1) * pixelsVerticalBetweenFields
					set pixelLabelBottom to pixelLabelTop + pixelLabelHeight
					
					set pixelFieldTop to pixelFieldTopStart + (i - 1) * pixelsVerticalBetweenFields
					set pixelFieldBottom to pixelFieldTop + pixelFieldHeight
					
					
					set {tocName, fieldNameShort} to parseChars({oneFieldName, "::"})
					
					
					set oneLabelXML to templateLabelXML
					set oneLabelXML to my replaceSimple({oneLabelXML, "###LABEL_TOP###", fmPrecisionCoordString(pixelLabelTop)})
					set oneLabelXML to my replaceSimple({oneLabelXML, "###LABEL_BOTTOM###", fmPrecisionCoordString(pixelLabelBottom)})
					set oneLabelXML to my replaceSimple({oneLabelXML, "###LABEL_TEXT###", fieldNameShort})
					
					set oneFieldXML to templateFieldXML
					set oneFieldXML to my replaceSimple({oneFieldXML, "###FIELD_TOP###", fmPrecisionCoordString(pixelFieldTop)})
					set oneFieldXML to my replaceSimple({oneFieldXML, "###FIELD_BOTTOM###", fmPrecisionCoordString(pixelFieldBottom)})
					set oneFieldXML to my replaceSimple({oneFieldXML, "###FIELDNAMESHORT###", fieldNameShort})
					set oneFieldXML to my replaceSimple({oneFieldXML, "###TOCNAME###", tocName})
					
					
					set objectsXML to objectsXML & return & oneLabelXML & return & oneFieldXML
				end if
				
			end repeat
			
			set pixelLayoutBottom to pixelFieldBottom -- bottom of final field is bottom of LAYOUT bounds
			
			
			set layoutHeaderXML to templateLayoutOpenXML
			set layoutHeaderXML to my replaceSimple({layoutHeaderXML, "###LAYOUT_TOP###", fmPrecisionCoordString(pixelLayoutTop)})
			set layoutHeaderXML to my replaceSimple({layoutHeaderXML, "###LAYOUT_BOTTOM###", fmPrecisionCoordString(pixelLayoutBottom)})
			
			
			set buildingXML to buildingXML & return & layoutHeaderXML
			
			set buildingXML to buildingXML & return & layoutObjectStylesXML
			
			set buildingXML to buildingXML & return & objectsXML
			
			set buildingXML to buildingXML & return & layoutFooterXML
			
			set buildingXML to buildingXML & return & footerXML
			
			
			-- DONE BUILDING XML: 
			
			set currentCode of objTrans to "XMLO"
			
			set newObjects to convertXmlToObjects(buildingXML) of objTrans
			
			
			set fmClipboard to get the clipboard
			
			set newClip to {Çclass XMLOÈ:newObjects} & fmClipboard
			
			set the clipboard to newClip
			
			return buildingXML
			
			
			
		end run
		
		
		
		
		
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
		
		
	end script
	
	
	run fieldsToLayoutObjects
	
end addFieldsAsLayoutObjectsFM11



















on addFieldsAsFieldDefs(fieldNameList)
	
	script fieldsToFieldDefs
		
		property headerXML : "<fmxmlsnippet type=\"FMObjectList\">"
		property footerXML : "</fmxmlsnippet>"
		property templateFieldDefStartXML : "<Field id=\"1\" dataType=\"Text\" fieldType=\"Normal\" name=\""
		
		property templateFieldDefEndXML : "\"><Comment></Comment><AutoEnter allowEditing=\"True\" constant=\"False\" furigana=\"False\" lookup=\"False\" calculation=\"False\"><ConstantData></ConstantData></AutoEnter><Validation message=\"False\" maxLength=\"False\" valuelist=\"False\" calculation=\"False\" alwaysValidateCalculation=\"False\" type=\"OnlyDuringDataEntry\"><NotEmpty value=\"False\"></NotEmpty><Unique value=\"False\"></Unique><Existing value=\"False\"></Existing><StrictValidation value=\"False\"></StrictValidation></Validation><Storage autoIndex=\"True\" index=\"None\" indexLanguage=\"English\" global=\"False\" maxRepetition=\"1\"></Storage></Field>"
		
		on run
			set objTrans to fmObjectTranslator_Instantiate({})
			
			
			
			set buildingXML to headerXML
			
			
			repeat with oneFieldName in fieldNameList
				set oneFieldName to contents of oneFieldName
				set oneFieldName to oneFieldName as string
				
				if length of oneFieldName is greater than 0 then
					
					set {tocName, fieldNameShort} to parseChars({oneFieldName, "::"})
					
					set oneFieldDefXML to templateFieldDefStartXML & fieldNameShort & templateFieldDefEndXML
					
					set buildingXML to buildingXML & return & oneFieldDefXML
				end if
			end repeat
			
			
			set buildingXML to buildingXML & return & footerXML
			
			set currentCode of objTrans to "XMFD"
			
			set newObjects to convertXmlToObjects(buildingXML) of objTrans
			
			
			set fmClipboard to get the clipboard
			
			set newClip to {Çclass XMFDÈ:newObjects} & fmClipboard
			
			set the clipboard to newClip
			
			return buildingXML
			
			
			
		end run
		
	end script
	
	
	run fieldsToFieldDefs
	
end addFieldsAsFieldDefs







on addFieldsAsScriptSteps(fieldNameList)
	
	script fieldsToScriptSteps
		
		property headerScriptStepsXML : "<fmxmlsnippet type=\"FMObjectList\">"
		property footerScriptStepsXML : "</fmxmlsnippet>"
		property stepStartXML : "<Step enable=\"True\" id=\"76\" name=\"Set Field\">"
		property stepEndXML : "</Step>"
		property calcPrefixXML : "<Calculation><![CDATA["
		property calcSuffixXML : "]]></Calculation>"
		property setFieldPrefixXML : "<Field table=\""
		property setFieldBetweenTableAndFieldNameXML : "\" id=\"19\" name=\""
		property setFieldSuffixXML : "\"></Field>"
		
		on run
			set objTrans to fmObjectTranslator_Instantiate({})
			
			
			set fieldNamesListAsText to unParseChars(fieldNameList, return)
			
			set buildingXML to headerScriptStepsXML
			
			
			repeat with oneFieldName in fieldNameList
				set oneFieldName to contents of oneFieldName
				set oneFieldName to oneFieldName as string
				
				if length of oneFieldName is greater than 0 then
					
					set {tocName, fieldNameShort} to parseChars({oneFieldName, "::"})
					
					set oneScriptStep to ""
					set oneScriptStep to oneScriptStep & stepStartXML
					set oneScriptStep to oneScriptStep & calcPrefixXML
					set oneScriptStep to oneScriptStep & oneFieldName
					set oneScriptStep to oneScriptStep & calcSuffixXML
					set oneScriptStep to oneScriptStep & setFieldPrefixXML
					set oneScriptStep to oneScriptStep & tocName
					set oneScriptStep to oneScriptStep & setFieldBetweenTableAndFieldNameXML
					set oneScriptStep to oneScriptStep & fieldNameShort
					set oneScriptStep to oneScriptStep & setFieldSuffixXML
					set oneScriptStep to oneScriptStep & stepEndXML
					
					set buildingXML to buildingXML & return & oneScriptStep
				end if
				
			end repeat
			
			
			set buildingXML to buildingXML & return & footerScriptStepsXML
			
			set currentCode of objTrans to "XMSS"
			
			set scriptStepsObjects to convertXmlToObjects(buildingXML) of objTrans
			
			
			set fmClipboard to get the clipboard
			
			set newClip to {Çclass XMSSÈ:scriptStepsObjects} & fmClipboard
			
			set the clipboard to newClip
			
			return buildingXML
			
			
			
		end run
		
	end script
	
	
	run fieldsToScriptSteps
	
end addFieldsAsScriptSteps







on preserveClipboard()
	
	set clipInfo to (clipboard info)
	set savedClipboard to {}
	set alreadySavedClasses to {}
	repeat with oneClip in clipInfo
		set oneClipClass to get item 1 of oneClip
		
		if alreadySavedClasses does not contain oneClipClass then
			set oneClipData to (get the clipboard as oneClipClass)
			set oneClipDataAsString to coerceToString(oneClipData)
			
			if oneClipClass is string then
				set savedClipboard to savedClipboard & {string:oneClipData}
				
			else if oneClipClass is Çclass utf8È then
				set savedClipboard to savedClipboard & {Çclass utf8È:oneClipData}
				
			else if oneClipClass is Unicode text then
				set savedClipboard to savedClipboard & {Unicode text:oneClipData}
				
			else if oneClipClass is Çclass ut16È then
				set savedClipboard to savedClipboard & {Çclass ut16È:oneClipData}
				
			else if oneClipClass is Çclass furlÈ then
				-- SKIP FOR NOW - CAUSES ERRORS!!!
				--set savedClipboard to savedClipboard & {Çclass furlÈ:oneClipData}
				
			else
				set oneClipClassAsString to coerceToString(oneClipClass)
				if oneClipClassAsString does not start with "Çclass " then
					set oneClipClassAsString to "Çclass " & text 7 thru 10 of oneClipDataAsString & "È"
				end if
				
				set scriptCode to Â
					"set savedClipboard to " & coerceToString(savedClipboard) & return Â
					& "set savedClipboard to savedClipboard & {" & oneClipClassAsString & ": " & oneClipDataAsString & "}" & return Â
					& "return savedClipboard"
				
				set savedClipboard to run script scriptCode
			end if
			
		end if
		
	end repeat
	
	return savedClipboard
	
	
	
end preserveClipboard





on coerceToString(incomingObject)
	-- version 1.8, Daniel A. Shockley, http://www.danshockley.com
	-- 1.8 - instead of trying to store the error message use, generate it
	-- 1.7 -  added "Can't make " with a curly single-quote. 
	-- 1.6 -  can add additional errMsg parts (just add to lists to handle other languages. 
	--             Currently handles English in both 10.3 and 10.4 (10.3 uses " into a number." 
	--             while 10.4 uses " into type number.")
	-- 1.5 -  added Unicode Text
	
	set errMsgLeadList to {"Can't make ", "CanÕt make "}
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



on getTextBetweenMultiple(sourceText, beforeText, afterText)
	-- version 1.2
	-- gets the text between all occurrences of beforeText and afterText in sourceText, and returns a list of strings
	-- the beforeText and afterText cannot overlap (ie. cannot parse "<LI>Apple<LI>Orange</UL>" using "<LI>" and "<")
	-- NEEDs parseChars()
	try
		
		set parsedByBefore to my parseChars({sourceText, beforeText})
		if length of parsedByBefore is 1 then return {}
		set parsedByBefore to items 2 through -1 of parsedByBefore
		
		set foundTextList to {}
		repeat with oneParsedSection in parsedByBefore
			set parsedList to my parseChars({oneParsedSection as string, afterText})
			if length of parsedList is not 1 then
				copy (item 1 of parsedList) as string to end of foundTextList
			end if
			
		end repeat
		
		return foundTextList
	on error errMsg number errNum
		-- will not error if parsing datum not found, will return empty list (see above)
		error "getTextBetweenMultiple FAILED: " & errMsg number errNum
		
	end try
end getTextBetweenMultiple








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



on logConsole(processName, consoleMsg)
	-- version 1.8 - Daniel A. Shockley, http://www.danshockley.com
	
	-- 1.8 - coerces to string first (since numbers would not directly convert for 'quoted form'
	-- 1.7 - now works with Leopard by using the "logger" command instead of just appending to log file
	-- 1.6- the 'space' constant instead of literal spaces for readability, removed trailing space from the hostname command
	-- 1.5- uses standard date-stamp format	
	
	set shellCommand to "logger" & space & "-t" & space & quoted form of processName & space & quoted form of (consoleMsg as string)
	
	do shell script shellCommand
	return shellCommand
end logConsole



on getXMLElementsByName(search_name, search_xml_element)
	-- version 2014-12-10-dshockley
	-- based on code by adamh on stackoverflow.com, 2014-01-22, http://stackoverflow.com/a/21282921
	
	set foundElems to {}
	
	using terms from application "System Events"
		tell search_xml_element
			set c to the count of XML elements
			repeat with i from 1 to c
				if (the name of XML element i is search_name) then
					copy XML element i to end of foundElems
				end if
				
				if (the (count of XML elements of XML element i) > 0) then
					set children_found to my getXMLElementsByName(search_name, XML element i)
					if (the (count of children_found) > 0) then
						set foundElems to foundElems & children_found
					end if
				end if
				
			end repeat
		end tell
	end using terms from
	
	return foundElems
	
end getXMLElementsByName





on flattenList(nestedList)
	-- version 1.1, Daniel A. Shockley, http://www.danshockley.com
	
	(* 
	VERSION HISTORY
	1.1 - had to stop using variable sublist due to namespace conflict; added error-trapping.
	*)
	
	try
		set newList to {}
		repeat with anItem in nestedList
			set anItem to contents of anItem
			if class of anItem is list then
				set partialSubList to my flattenList(anItem)
				repeat with oneSubItem in partialSubList
					set oneSubItem to contents of oneSubItem
					copy oneSubItem to end of newList
				end repeat
			else
				
				copy anItem to end of newList
			end if
		end repeat
		
		return newList
		
	on error errMsg number errNum
		error "ERROR: flattenList() handler: " & errMsg number errNum
	end try
end flattenList


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













on fmObjectTranslator_Instantiate(prefs)
	
	script fmObjectTranslator
		-- version 3.9, Daniel A. Shockley
		
		-- 3.9 - fixed bug where simpleFormatXML would fail on layout objects.
		-- 3.8 - default for shouldPrettify is now FALSE; added shouldSimpleFormat option for simpleFormatXML() (modifies text XML in minor, but useful, ways) - as of 3.8, adds line-returns inside the fmxmlsnippet tags; 
		-- 3.7 - updated dataObjectToUTF8 to indicate non-FM object can be converted; added clipboardPatternCount method; updated logConsole to 1.9; added coerceToString 1.8; 
		-- 3.6 - currentCode needed to be evaluated WHEN USED, since translator objects retains previous operations; added error-trapping; labeled more handlers as 'Public Methods'
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
		
		property fmObjCodes : {Â
			{objName:"Step", objCode:"XMSS"}, Â
			{objName:"Layout", objCode:"XML2", secondaryNode:"NOT ObjectStyle"}, Â
			{objName:"Layout", objCode:"XMLO", secondaryNode:"HAS ObjectStyle"}, Â
			{objName:"Group", objCode:"XMSC"}, Â
			{objName:"Script", objCode:"XMSC"}, Â
			{objName:"Field", objCode:"XMFD"}, Â
			{objName:"CustomFunction", objCode:"XMFN"}, Â
			{objName:"BaseTable", objCode:"XMTB"} Â
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
			-- returns the XML translation of FM objects in the clipboard
			
			if debugMode then logConsole(ScriptName, "clipboardGetObjectsAsXML: START")
			if currentCode is "" then
				if not checkClipboardForObjects({}) then
					error "clipboardGetObjectsAsXML : Clipboard does not contain valid FileMaker objects." number 1024
				end if
			end if
			if currentCode is "" then
				return ""
			end if
			
			set thisClass to classFromCode(currentCode)
			set fmObjects to get the clipboard as thisClass
			
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
			-- returns the PATH to an XML translation of FM objects in the clipboard
			
			set defaultPrefs to {outputFilePath:"__TEMP__", resultType:"MacPath"}
			set prefs to prefs & defaultPrefs
			
			if debugMode then logConsole(ScriptName, "clipboardGetObjectsToXmlFilePath: START")
			
			if not checkClipboardForObjects({}) then
				return ""
			end if
			
			set thisClass to classFromCode(currentCode)
			set fmObjects to get the clipboard as thisClass
			
			
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
			-- checks clipboard for FM Objects (as classes, not XML)
			-- returns true if it does, false if not
			
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
			
			set currentCode to clipboardType
			if clipboardType is "" then
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
			-- version 3.6
			
			-- 3.6 - need to SET currentCode for this object - always.
			-- 3.5 - no need for file writeÊto be in tell System Events block
			-- converts some string of XML into fmObjects as FM data type
			
			if debugMode then logConsole(ScriptName, "convertXmlToObjects: START")
			
			-- 3.6: the check also sets currentCode to correct value: 
			if not checkStringForValidXML(stringFmXML) then
				-- if not valid, give an error.
				if debugMode then logConsole(ScriptName, "convertXmlToObjects: no valid XML")
				error "XML does not contain valid FileMaker objects." number 1024
			end if
			
			set thisClass to currentClass()
			
			set stringLength to length of stringFmXML
			
			if debugMode then logConsole(ScriptName, "convertXmlToObjects: stringLength: " & stringLength)
			
			set tempXMLPosix to (makeTempDirPosix() & tempXMLName)
			set xmlFilePath to (POSIX file tempXMLPosix) as string
			if debugMode then logConsole(ScriptName, "convertXmlToObjects: xmlFilePath: " & xmlFilePath)
			set xmlHandle to open for access file xmlFilePath with write permission
			write stringFmXML to xmlHandle as Çclass utf8È
			close access xmlHandle
			set fmObjects to read alias xmlFilePath as thisClass
			
			return fmObjects
			
		end convertXmlToObjects
		
		
		
		
		on checkStringForValidXML(someString)
			-- checks someString for XML that represents FM objects
			-- returns true if it does, false if not
			
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
			
			if currentCode is "" then
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
			return run script "Çclass " & objCode & "È"
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
			
			
			
			if resultType is "utf8" then
				
				tell application "System Events"
					read file tempDataPath as Çclass utf8È
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
			
			set errMsgLeadList to {"Can't make ", "CanÕt make "}
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
				{Çclass usrfÈ:assocList}'s x
			on error msg
				return msg
				run script text 16 thru -2 of msg
			end try
		end recordFromList
		
		
		
		
		
	end script
	
	run fmObjectTranslator
	
	return fmObjectTranslator
	
	
end fmObjectTranslator_Instantiate










