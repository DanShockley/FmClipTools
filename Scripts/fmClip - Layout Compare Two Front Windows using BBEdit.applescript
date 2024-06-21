-- Layout Compare Two Front Windows using BBEdit

(*

	In the current/frontmost copy of FileMaker (if running multiple copies/versions of the app), copy the layout objects of the two frontmost windows (BOTH MUST BE IN LAYOUT MODE!), then compare the XML, saving each XML to temporary items director, opening in BBEdit, stripping away superficial differences (internal unique keys), then running a BBEdit comparison to show any differences.

HISTORY:
	2024-06-21 ( danshockley ): Created. 
	
*)
property debugMode : true

-- search/replace pairs for things to ignore:
property grepReplacePairs : {{" key=\"[0-9]+\"", " key=\"9999\""}, Â
	{" visPanelKey=\"[0-9]+\"", " visPanelKey=\"9999\""}, Â
	{" LabelKey=\"[0-9]+\"", " LabelKey=\"9999\""}}


on run
	
	
	-- try
	
	-- load the translator library:
	set transPath to (((((path to me as text) & "::") as alias) as string) & "fmObjectTranslator.applescript")
	set objTrans to run script (transPath as alias)
	(* If you need a self-contained script, copy the code from fmObjectTranslator into this script and use the following instead of the run script step above:
			set objTrans to fmObjectTranslator_Instantiate({})
		*)
	
	
	
	tell application "System Events"
		set frontAppName to get name of first application process whose frontmost is true
		set frontAppID to id of first application process whose frontmost is true
		if frontAppName does not contain "FileMaker" then
			try
				set firstFmApp to first application process whose name contains "FileMaker"
			on error errMsg number errNum
				return false
			end try
			set frontAppName to name of firstFmApp
			set frontAppID to id of firstFmApp
		end if
		tell process id frontAppID
			set frontmost to true
			delay 0.2
			--			properties of first window whose subrole is not "AXFloatingWindow"
			set stdWindows to every window whose subrole is "AXStandardWindow"
			if debugMode then log stdWindows
			if debugMode then log {name of item 1 of stdWindows, name of item 2 of stdWindows}
			
			set win1 to item 1 of stdWindows
			set win2 to item 2 of stdWindows
			
			
			-- LAYOUT MODE for two front windows??
			try
				button "Exit Layout" of win1
			on error errMsg number errNum
				if errNum is -1728 then
					set errMsg to "FileMaker's first window is NOT in Layout Mode. Please set the front two windows to compare into Layout Mode."
				else
					set errMsg to "Error trying to talk to FileMaker's windows: " & errMsg
				end if
				error errMsg number errNum
			end try
			try
				button "Exit Layout" of win2
			on error errMsg number errNum
				if errNum is -1728 then
					set errMsg to "FileMaker's second window is NOT in Layout Mode. Please set the front two windows to compare into Layout Mode."
				else
					set errMsg to "Error trying to talk to FileMaker's windows: " & errMsg
				end if
				error errMsg number errNum
			end try
			
			
			-- get the LAYOUT NAMES:
			tell win1
				set layoutName1 to title of first button whose accessibility description is "Layout Menu"
			end tell
			tell win2
				set layoutName2 to title of first button whose accessibility description is "Layout Menu"
			end tell
			
			
			
			-- COPY all objects from window 1:
			click menu item "Select All" of menu "Edit" of menu bar 1
			delay 0.2
			click menu item "Copy" of menu "Edit" of menu bar 1
			delay 0.2
		end tell
	end tell
	-- make sure layout objects were copied:
	checkClipboardForObjects({}) of objTrans
	if currentCode of objTrans is not "XML2" then
		error "Could not get FileMaker layout objects from the clipboard, unclear why copying failed." number -1024
	end if
	-- get the layout objects:
	set layoutObjectsXML_1 to clipboardGetObjectsasXML({}) of objTrans
	
	
	
	-- COPY all objects from window 2:
	
	-- need to bring it to front first:
	tell application "System Events"
		tell process id frontAppID
			-- bring window 2 to front
			tell win2
				perform action "AXRaise"
				delay 0.2
			end tell
			
			-- COPY all objects from window 2:
			click menu item "Select All" of menu "Edit" of menu bar 1
			delay 0.2
			click menu item "Copy" of menu "Edit" of menu bar 1
			delay 0.2
			-- restore window 1 to front (leave things as we found them):
			tell win1
				perform action "AXRaise"
				delay 0.2
			end tell
			
		end tell
	end tell
	-- make sure layout objects were copied:
	checkClipboardForObjects({}) of objTrans
	if currentCode of objTrans is not "XML2" then
		error "Could not get FileMaker layout objects from the clipboard, unclear why copying failed." number -1024
	end if
	-- get the layout objects:
	set layoutObjectsXML_2 to clipboardGetObjectsasXML({}) of objTrans
	
	
	-- SAVE XML of layout objects:
	set filePathLayout1 to ((path to temporary items) as string) & layoutName1 & ".xml"
	writeToFile({targetFile:filePathLayout1, writeData:layoutObjectsXML_1, writeAs:Çclass utf8È})
	set filePathLayout2 to ((path to temporary items) as string) & layoutName2 & ".xml"
	writeToFile({targetFile:filePathLayout2, writeData:layoutObjectsXML_2, writeAs:Çclass utf8È})
	
	
	tell application "BBEdit"
		activate
		-- Open the first XML file
		set doc1 to open filePathLayout1
		-- Open the second XML file
		set doc2 to open filePathLayout2
		
		repeat with onePair in grepReplacePairs
			set oneSearch to item 1 of onePair
			set oneReplace to item 2 of onePair
			tell doc1
				replace oneSearch using oneReplace options {search mode:grep, starting at top:true}
			end tell
			tell doc2
				replace oneSearch using oneReplace options {search mode:grep, starting at top:true}
			end tell
		end repeat
		
		
		-- Use BBEdit's compare feature
		set comparisonResults to compare doc1 against doc2 options {case sensitive:true}
		
		if differences found of comparisonResults is false then
			display dialog reason for no differences of comparisonResults buttons {"OK"} default button "OK"
		end if
		
	end tell
	
	
	
	
	(*
	on error errMsg number errNum
	showError({errMsg: errMsg})
	end
*)
	
end run



on showError(prefs)
	
	set defaultPrefs to {errMsg:"Error: unspecified.", buttonList:{"OK"}, defButton:"OK"}
	-- first, if prefs are not AppleScript record, assume it is just text and convert:
	if class of prefs is not class of {a:"a"} then set prefs to {errMsg:prefs}
	set prefs to prefs & defaultPrefs
	
	try
		display alert errMsg of prefs buttons buttonList of prefs default button defButton of prefs
		return true
	on error errMsg number errNum
		error "unable to showError - " & errMsg number errNum
	end try
end showError






on writeToFile(prefs)
	-- version 1.3
	(* 
		Generic write-to-file wrapper: should handle any writing location, append, etc.
		
		HISTORY: 
			1.3 - 2024-06-21 ( danshockley ): if opened using targetFile, defaults to closeHandle, unless specified not to.
			1.2 - 2024-01-16 ( danshockley ): added support for writeAs param.
			1.1 - 2024-01-16 ( danshockley ): BUG-FIX: if closeHandle not specified, it should be FALSE (not True) to leave file open. 
			1.0 - writes data to file, starting at options, append choice, keep-open choice; returns handle if still open, otherwise true
	*)
	
	set defaultPrefs to {targetHandle:"", writeData:"", targetFile:"", startingAt:"", writeFor:"", writeAs:"", append:false, closeHandle:false}
	-- if targetFile specified without specifying closeHandle, default to TRUE:
	try
		exists targetFile of prefs
		try
			closeHandle of prefs
		on error
			set closeHandle of defaultPrefs to true
		end try
	end try
	
	set prefs to prefs & defaultPrefs
	
	try
		set targetHandle to targetHandle of prefs -- if handle is passed, it must be with write permission!
		-- also, it will not be closed, unless closeHandle is true
		set writeData to writeData of prefs -- the data to write to file
		set targetFile to targetFile of prefs -- will create, if needed -- if passed, closeHandle default is true
		set startingAt to startingAt of prefs -- the byte in file to start at - first byte is startingAt:1
		-- if startingAt is greater than length of file, ERROR; also, 0 will be changed to 1
		set writeFor to writeFor of prefs -- NOT YET
		set writeAs to writeAs of prefs -- the class (type) of data to write to the file
		set append to append of prefs -- default is false, startingAt overrides append
	end try
	
	if targetHandle is "" and targetFile is "" then error "writeToFile(): Missing required parameter: either targetHandle or targetFile must be specified."
	if targetHandle is "" then
		-- no target handle, try to open the targetFile for writing
		set targetFile to targetFile as string
		set targetHandle to open for access file targetFile with write permission
		try
			set closeHandle to closeHandle of prefs
		on error --closeHandle was not specified, leave OPEN (so close=false)
			set closeHandle to false
		end try
		
		-- now we have a targetHandle to write to
	else -- target handle WAS passed
		try
			set closeHandle to closeHandle of prefs
		on error --closeHandle was not specified, leave OPEN (so close=false)
			set closeHandle to false
		end try
	end if
	
	try
		if startingAt is 0 then set startingAt to 1
		log startingAt
		set currentEOF to (get eof targetHandle)
		if currentEOF is 1 then
			set currentEOF to 1
		else
			set currentEOF to currentEOF + 1 -- eof returns LENGTH of file, so +1 is new write location
		end if
		log currentEOF
		
		
		if append and (startingAt is "") then
			set startingAt to (currentEOF)
		else -- NOT append, write to end or specified location	
			
			if startingAt is "" then
				-- start at beginning of file
				set startingAt to 1
				set eof targetHandle to 1
			else
				if startingAt is greater than currentEOF then
					error "writeToFile() ERROR: startingAt is past the end of the file."
				end if
				set eof targetHandle to startingAt
			end if --startingAt empty?
		end if -- append?
		
		-- startingAt now tells us where to start, whether beginning, end, or arbitrary
		
		if writeAs is "" and writeFor is "" then
			set writeResult to write writeData to targetHandle starting at startingAt
		else if writeAs is not "" then
			set writeResult to write writeData to targetHandle starting at startingAt as writeAs
		else
			error "writeToFile(): writeFor NOT yet implemented."
		end if
		
		if closeHandle then
			try
				close access targetHandle
			end try
			return true
		else -- do NOT close
			return targetHandle
		end if
	on error errMsg number errNum
		if closeHandle then
			try
				close access targetHandle
			end try
		end if
		error errMsg number errNum
	end try
end writeToFile



