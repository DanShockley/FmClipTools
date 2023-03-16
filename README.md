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

2023-03-12 update: for anyone who has been using FmClipTools, there was a change to the script that converts objects to XML. In the past, it also made the XML "pretty" (indentation, basically) by default. However, that made it slower and also could introduce slight differences that can cause problems for FileMaker when pasting back. So, the default is now to leave the XML "ugly", with a separate script to "Prettify XML in Clipboard", which should operate on any XML in the clipboard. Technical note: it is using **tidy** for that formatting, with tidy's options set to do as little extra modification as possible. 
