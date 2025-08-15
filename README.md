# FmClipTools

Tools for converting, modifying, and saving FileMaker Pro clipboard objects. Coded in AppleScript (so, macOS only). 

Objects that you can copy/paste in FileMaker (Scripts, Script Steps, Fields/Tables in Manage Database, Layout Objects, Custom Functions, Value Lists) are essentially XML data, but stored in the clipboard in such a way that you cannot just paste that XML into a text editor. This project includes scripts to easily convert those objects to/from XML, replace within the clipboard objects, replicate an object in bulk, and much more. 

## Install Process

You can install FmClipTools by doing a git clone of this repo to your desired location. If you don't already have one, you could create a ~/Code folder and clone there. 
Alternatively, you could just download a zip file of the project, unzip it, and put it somewhere useful (maybe in a ~/Code folder), but to update you would have to download a fresh zip occasionally.  

To put these to good use, you can execute them from some keyboard-shortcut or macro tool like Keyboard Maestro, Alfred, Quicksilver, etc. 
If you do that, you could add a step that performs a copy (on the currently-selected FileMaker script steps), and perhaps even a delete-and-paste afterwards, if you'd like. 


## Setup and Usage

First, there is a DEMO file: [FmClipTools_Demo.fmp12](https://github.com/DanShockley/FmClipTools/blob/master/Support/FmClipTools_Demo.fmp12). It shows how to use FmClipTools, including examples. 

To use them without any third-party software, you can also call them from the macOS menu-bar by activating the "Scripts" menu. 
To do that: 
* Open up /Applications/Script Editor.app and go into its Preferences. 
* Activate the checkbox for "Show Script menu in menu bar"
* Click the (AppleScript) menubar item that should have just appeared (an icon of an S-shaped sheet of paper), then pick "Open Scripts Folder". 
* This will open `~/Library/Scripts/` in the Finder.  I prefer to have these available from any application context, so I keep them at the top level. 
* Put an alias to each of the `fmClip - {whatever}` scripts into that folder. 
* (optional) If you want to call FmObjectTranslator functions by "telling" an app, which can be useful for external scripts where you don't want to reference the separate .applescript file, you can run the `./recompile.sh` shell script to build/rebuild it, after you do a git pull.

2025-08-15 update: fixed the description of the Duplicate ButtonBar Segment script and added an example for it in the [FmClipTools Demo.fmp12](https://github.com/DanShockley/FmClipTools/blob/master/Support/FmClipTools Demo.fmp12) file.

2025-08-14 update: improved documentation, made some code updates, added the [FmClipTools Demo.fmp12](https://github.com/DanShockley/FmClipTools/blob/master/Support/FmClipTools Demo.fmp12) file.

2025-01-21 update: Added the `fmClip - Duplicate ButtonBar Segment` script. Basically, you copy an entire button bar object, run this script, tell it which segment (by number) to duplicate, it does that, putting the entire new button bar back into your clipboard. Back in FileMaker, delete the original button bar (*before* pasting to avoid object name collisions!), then paste the new button bar.

2024-09-14 update: Added the `fmClip - Fields Drop Unused AE_or_VAL calcs` script, which removes from Field definition objects any "phantom" (unused) calculations or lookups for AutoEnter, or calculation or valueLists for Validation.

2024-07-16 update: Added the `fmClip - Custom Function Paste Or Update` script, so you can now copy a bunch of custom functions from a good/current source file, go to a target file's Manage Custom Functions, and run this script. It will paste any that do not yet exist in the target, then update any existing functions that do not match the source. NOTE: It will not (yet) rename/add/remove parameters, so that would get an error when it tries to save the modified calculation. 

2024-01-18 update: If you are using the `Params as JSON Script Steps to Template Calc` script, it now will take a hint from which variable data type you specified when setting params in your script steps using GetJParam custom function, and the template calc will set the appropriate JSON data type for that. Also added the GetJParam custom function (and a dependency) into a `Support` sub-folder in this project. 

2024-01-11 update: Now supports copy/paste of FileMaker themes from the Manage Themes window. Got some help at MacScripter.net for how to handle the weird way FileMaker puts the Theme data into the clipboard. Claris didn’t use the same technique as other objects (hex-encoded XML as data), nor what custom menus use (straight XML text). I had to use AppleScript’s ability to call on AppKit/Objective-C functions like NSPasteBoard. That meant re-working some of the other code in the fmObjectTranslator library, since “use Foundation” conflicts with some older AppleScript techniques. Note that you cannot copy the themes in square brackets. And, pasting adds a new theme - no way to update an existing theme via paste. But, in my brief testing, I took the Apex Blue theme, converted the clipboard to XML using FmClipTools, pasted the XML into BBEdit, converted Helvetica Neue (and HelveticaNeue) to Verdana, modified the theme name, then pasted back into Manage Themes. When I applied that theme to a layout, all the objects changed from Helvetica Neue to Verdana. Now, that’s a pretty shallow test of “how can I cause problems in FileMaker by tinkering with the Theme XML?” But, FmCliptools doesn’t keep us from injuring ourselves. As I’ve heard a Claris engineer say “Knives are sharp.” I also did some basic testing to make sure the update didn’t break any previous functionality for other data types, but of course post an issue here on GitHub if you come across any problems. 

2023-03-12 update: for anyone who has been using FmClipTools, there was a change to the script that converts objects to XML. In the past, it also made the XML "pretty" (indentation, basically) by default. However, that made it slower and also could introduce slight differences that can cause problems for FileMaker when pasting back. So, the default is now to leave the XML "ugly", with a separate script to "Prettify XML in Clipboard", which should operate on any XML in the clipboard. Technical note: it is using **tidy** for that formatting, with tidy's options set to do as little extra modification as possible. 
