-- Script Step Transmutator
-- version 2025-08-10

(* 
	The idea would be to convert one type of scripts steps into some other type. 
	So, this script could check what type of steps are in the clipboard, 
	and provide a list of possible transmutations. 
	Example: 
	 ¥ a collected of script steps that do: "Set Variable [ $someVar ; MyTable::SomeField ]"
		The possible operations could be to: 
		 - convert those to: "Set Field [ MyTable::SomeField ; $someVar ]"
		 - convert those to: "If [ $someVar ­ MyTable::SomeField ], End If" blocks
		 - Éand so on.


HISTORY: 
	2025-08-10 ( danshockley ): Updated documentation to explain what the intended purpose was, still not built.  
	2017-01-17 ( danshockley ): Original concept - not fleshed out. Had code from "Perform Find to Script Steps". 

*)






property debugMode : false


on run
	
	
	
	
	
	if debugMode then
		-- DEBUGGING CODE!!!!!!
		set sampleFilePath to ((path to desktop) as string) & "sample-script-steps.xml"
		set origXML to read file sampleFilePath
		
	else
		set objTrans to fmObjectTranslator_Instantiate({})
		set origXML to clipboardGetObjectsAsXML({}) of objTrans
		
	end if
	
	
	
	
	
	
	
	
end run

