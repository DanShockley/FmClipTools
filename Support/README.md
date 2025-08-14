# Support files for this project

## ClipboardXmlToFmObjects.fmfn

This is the calculation for a custom function that can run entirely within FileMaker to convert clipboard XML text into the appropriate FM objects for pasting. It relies on the [BaseElements plugin](https://docs.baseelementsplugin.com/collection/374-general) to read/convert the clipboard. You can either create a custom function using this calculation, then call it from a single-step button, or use this calculation directly IN a single step button that, for example, does a Show Custom Dialog with the function's resulting message.


## custom-functions.xml

Custom functions that can be used alongside FmClipTools. 

For example, the script `Params as JSON Script Steps to Template Calc.applescript`  converts clipboard script steps (that pull multiple parameters out of JSON-encoded `Get ( ScriptParameter )` text) into a template calculation for calling a script. It expects that each script step will be setting a script variable to the value for a JSON key extracted from the incoming script parameter JSON using the custom function GetJParam. That custom function depends on the custom function `JSON.ContainsProperty`, by Todd Geist (found at https://github.com/geistinteractive/fm-json-additions). 

## FmClipTools Demo.fmp12

A demo file showing how to install, setup, and use FmClipTools. 
