# FmClipTools

Tools for converting, modifying, and saving FileMaker Pro clipboard objects. Coded in AppleScript (so, macOS only). 

Objects that you can copy/paste in FileMaker (Scripts, Script Steps, Fields/Tables in Manage Database, Layout Objects, Custom Functions, Value Lists) are essentially XML data, but stored in the clipboard in such a way that you cannot just paste that XML into a text editor. This project includes scripts to easily convert those objects to/from XML, replace within the clipboard objects, replicate an object in bulk, and much more. 

To put these to good use, you can execute them from some keyboard-shortcut or macro tool like Keyboard Maestro, Alfred, Quicksilver, etc. 
If you do that, you could add a step that performs a copy (on the currently-selected FileMaker script steps), and perhaps even a delete-and-paste afterwards, if you'd like. 

To use them without any third-party software, you can also call them from the macOS menu-bar by activating the "Scripts" menu. 
To do that: 
* Open up /Applications/Script Editor.app and go into its Preferences. 
* Activate the checkbox for "Show Script menu in menu bar"
* Switch to FileMaker
* Click the Scripts menu, then pick "Open Scripts Folder -> Open FileMaker Pro Advanced Scripts Folder"
* Put an alias to each of the Scripts into that folder. 

2024-01-18 update: If you are using the `Params as JSON Script Steps to Template Calc` script, it now will take a hint from which variable data type you specified when setting params in your script steps using GetJParam custom function, and the template calc will set the appropriate JSON data type for that. Also added the GetJParam custom function (and a dependency) into a `Support` sub-folder in this project. 

2024-01-11 update: Now supports copy/paste of FileMaker themes from the Manage Themes window. Got some help at MacScripter.net for how to handle the weird way FileMaker puts the Theme data into the clipboard. Claris didn’t use the same technique as other objects (hex-encoded XML as data), nor what custom menus use (straight XML text). I had to use AppleScript’s ability to call on AppKit/Objective-C functions like NSPasteBoard. That meant re-working some of the other code in the fmObjectTranslator library, since “use Foundation” conflicts with some older AppleScript techniques. Note that you cannot copy the themes in square brackets. And, pasting adds a new theme - no way to update an existing theme via paste. But, in my brief testing, I took the Apex Blue theme, converted the clipboard to XML using FmClipTools, pasted the XML into BBEdit, converted Helvetica Neue (and HelveticaNeue) to Verdana, modified the theme name, then pasted back into Manage Themes. When I applied that theme to a layout, all the objects changed from Helvetica Neue to Verdana. Now, that’s a pretty shallow test of “how can I cause problems in FileMaker by tinkering with the Theme XML?” But, FmCliptools doesn’t keep us from injuring ourselves. As I’ve heard a Claris engineer say “Knives are sharp.” I also did some basic testing to make sure the update didn’t break any previous functionality for other data types, but of course post an issue here on GitHub if you come across any problems. 

2023-03-12 update: for anyone who has been using FmClipTools, there was a change to the script that converts objects to XML. In the past, it also made the XML "pretty" (indentation, basically) by default. However, that made it slower and also could introduce slight differences that can cause problems for FileMaker when pasting back. So, the default is now to leave the XML "ugly", with a separate script to "Prettify XML in Clipboard", which should operate on any XML in the clipboard. Technical note: it is using **tidy** for that formatting, with tidy's options set to do as little extra modification as possible. 
