# custom functions

Custom functions that can be used alongside FmClipTools. 

For example, the script `Params as JSON Script Steps to Template Calc.applescript`  converts clipboard script steps (that pull multiple parameters out of JSON-encoded `Get ( ScriptParameter )` text) into a template calculation for calling a script. It expects that each script step will be setting a script variable to the value for a JSON key extracted from the incoming script parameter JSON using the custom function GetJParam. That custom function depends on the custom function `JSON.ContainsProperty`, by Todd Geist (found at https://github.com/geistinteractive/fm-json-additions). 
