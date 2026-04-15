-- SVG Extractor
-- version 2026-04-15, Daniel A. Shockley

(*
	Extracts SVG objects from the clipboard FileMaker objects.
	By default, puts them into the clipboard, separated by multiple empty line returns.
	Note: this does sloppy parsing, not true XML-parsing, for speed and to reduce dependencies. 

	HISTORY: 
		2026-04-15 ( danshockley ): turn off debugMode. 
		2026-03-30 ( danshockley ): Created.
*)

property debugMode : false -- ONLY enable this while developing/testing

on run
	
	-- string to put between blocks of SVG XML, if multiple:
	set sepBlocks to (ASCII character 10) & (ASCII character 10) & (ASCII character 10)
	
	-- load the translator library:
	set transPath to (((((path to me as text) & "::") as alias) as string) & "fmObjectTranslator.applescript")
	set objTrans to run script (transPath as alias)
	(* If you need a self-contained script, copy the code from fmObjectTranslator into this script and use the following instead of the run script step above:
			set objTrans to fmObjectTranslator_Instantiate({})
		*)
	
	set clipboardHasFM to checkClipboardForObjects({}) of objTrans
	
	
	set debugMode of objTrans to debugMode
	set shouldPrettify of objTrans to false
	set shouldSimpleFormat of objTrans to false
	
	
	if clipboardHasFM is false then
		display dialog "The clipboard did not contain any FileMaker objects."
		return false
	end if
	
	set objectsAsXML to clipboardGetObjectsAsXML({}) of objTrans
	
	
	-- SAMPLE TEST CODE:	set objectsAsXML to someButtonBarXML()
	set xmlBeforeSVG_1 to "<Type>SVG </Type>"
	set xmlBeforeSVG_2 to "<HexData>"
	set xmlAfterSVG to "</HexData>"
	
	
	try
		-- this will extract a list of SVG sections, which will include an unwanted prefix for each:
		set listOfSVG_HexWithPrefix to getTextBetweenMultiple(objectsAsXML, xmlBeforeSVG_1, xmlAfterSVG) of objTrans
		
		if (count of listOfSVG_HexWithPrefix) is 0 then error -1024
		
	on error errMsg number errNum
		if debugMode then
			display dialog errMsg
		else
			
			display dialog "No SVG found in the clipboard's FileMaker objects."
		end if
		return false
	end try
	
	-- remove the unwanted prefix from each:
	set listOfSVGs to {}
	repeat with oneHexWithPrefix in listOfSVG_HexWithPrefix
		set oneHexWithPrefix to contents of oneHexWithPrefix
		set oneHex to item 2 of parseChars({oneHexWithPrefix, xmlBeforeSVG_2}) of objTrans
		
		set oneSVG_XML to hexToUTF8(oneHex)
		-- Note: First tried to use the dataObjectToUTF8 handler in fmObjTrans, but something about building a data object and then writing to a file drops the initial opening bracket. 
		
		copy oneSVG_XML to end of listOfSVGs
	end repeat
	
	
	set blocksOfSVG to unParseChars(listOfSVGs, sepBlocks) of objTrans
	
	set the clipboard to blocksOfSVG
	
	
	return blocksOfSVG
	
	
end run


on hexToUTF8(hexStr)
	set jsCode to "
        function hexToUTF8(hex) {
            var bytes = [];
            for (var i = 0; i < hex.length; i += 2) {
                bytes.push(parseInt(hex.substr(i, 2), 16));
            }
            var str = '';
            var i = 0;
            while (i < bytes.length) {
                var b = bytes[i];
                var codePoint;
                if (b < 0x80) {
                    codePoint = b;
                    i += 1;
                } else if ((b & 0xE0) === 0xC0) {
                    codePoint = ((b & 0x1F) << 6) | (bytes[i+1] & 0x3F);
                    i += 2;
                } else if ((b & 0xF0) === 0xE0) {
                    codePoint = ((b & 0x0F) << 12) | ((bytes[i+1] & 0x3F) << 6) | (bytes[i+2] & 0x3F);
                    i += 3;
                } else {
                    codePoint = ((b & 0x07) << 18) | ((bytes[i+1] & 0x3F) << 12) | ((bytes[i+2] & 0x3F) << 6) | (bytes[i+3] & 0x3F);
                    i += 4;
                }
                str += String.fromCodePoint(codePoint);
            }
            return str;
        }
        hexToUTF8('" & hexStr & "');
    "
	return run script jsCode in "JavaScript"
end hexToUTF8



on someButtonBarXML()
	
	
	return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<fmxmlsnippet type=\"LayoutObjectList\">
<Layout enclosingRectTop =\"446.0000000\" enclosingRectLeft =\"660.0000000\" enclosingRectBottom =\"476.0000000\" enclosingRectRight =\"744.0000000\">
<Object type=\"ButtonBar\" key=\"109\" LabelKey=\"0\" flags=\"0\" rotation=\"0\">
<Bounds top=\"446.0000000\" left=\"660.0000000\" bottom=\"476.0000000\" right=\"744.0000000\"/>
<Styles>
<FullCSS>
self:normal .self&#10;{&#10;&#09;border-top-color: rgba(0%,0%,0%,0);&#10;&#09;border-right-color: rgba(0%,0%,0%,0);&#10;&#09;border-bottom-color: rgba(0%,0%,0%,0);&#10;&#09;border-left-color: rgba(0%,0%,0%,0);&#10;&#09;border-top-style: none;&#10;&#09;border-right-style: none;&#10;&#09;border-bottom-style: none;&#10;&#09;border-left-style: none;&#10;&#09;border-top-width: 0pt;&#10;&#09;border-right-width: 0pt;&#10;&#09;border-bottom-width: 0pt;&#10;&#09;border-left-width: 0pt;&#10;&#09;border-top-right-radius: 0pt 0pt;&#10;&#09;border-bottom-right-radius: 0pt 0pt;&#10;&#09;border-bottom-left-radius: 0pt 0pt;&#10;&#09;border-top-left-radius: 0pt 0pt;&#10;&#09;box-shadow: none;&#10;&#09;box-sizing: content-box;&#10;}&#10;self:normal .button_bar_divider&#10;{&#10;&#09;border-top-color: rgba(36.0784%,36.0784%,36.0784%,1);&#10;&#09;border-right-color: rgba(36.0784%,36.0784%,36.0784%,1);&#10;&#09;border-bottom-color: rgba(36.0784%,36.0784%,36.0784%,1);&#10;&#09;border-left-color: rgba(36.0784%,36.0784%,36.0784%,1);&#10;&#09;border-top-style: solid;&#10;&#09;border-right-style: solid;&#10;&#09;border-bottom-style: solid;&#10;&#09;border-left-style: solid;&#10;&#09;border-top-width: 1pt;&#10;&#09;border-right-width: 1pt;&#10;&#09;border-bottom-width: 1pt;&#10;&#09;border-left-width: 1pt;&#10;&#09;border-top-right-radius: 0pt 0pt;&#10;&#09;border-bottom-right-radius: 0pt 0pt;&#10;&#09;border-bottom-left-radius: 0pt 0pt;&#10;&#09;border-top-left-radius: 0pt 0pt;&#10;&#09;box-shadow: none;&#10;&#09;box-sizing: content-box;&#10;}&#10;</FullCSS>
<ThemeName>com.filemaker.theme.enlightened</ThemeName></Styles>
<ButtonBarObj flags=\"0\" segmentKey=\"0\">
<Object type=\"Button\" key=\"111\" LabelKey=\"0\" flags=\"8\" rotation=\"0\">
<Bounds top=\"0.0000000\" left=\"0.0000000\" bottom=\"30.0000000\" right=\"42.0000000\"/>
<TextObj flags=\"2\">
<ExtendedAttributes fontHeight=\"10\" graphicFormat=\"5\">
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
<CharacterStyle mask=\"32695\">
<Font-family codeSet=\"Roman\" fontId=\"0\" postScript=\"Helvetica\">Helvetica</Font-family>
<Font-size>12</Font-size>
<Face>0</Face>
<Color>#A3A3A3</Color>
</CharacterStyle>
</ExtendedAttributes>
<Styles>
<FullCSS>
self:normal .self&#10;{&#10;&#09;background-image: none;&#10;&#09;background-position: 0% 0%;&#10;&#09;background-size: auto;&#10;&#09;background-repeat: repeat repeat;&#10;&#09;background-origin: padding-box;&#10;&#09;background-clip: border-box;&#10;&#09;background-color: rgba(0%,0%,0%,1);&#10;&#09;border-top-color: rgba(0%,0%,0%,0);&#10;&#09;border-right-color: rgba(0%,0%,0%,0);&#10;&#09;border-bottom-color: rgba(0%,0%,0%,0);&#10;&#09;border-left-color: rgba(0%,0%,0%,0);&#10;&#09;border-top-style: none;&#10;&#09;border-right-style: none;&#10;&#09;border-bottom-style: none;&#10;&#09;border-left-style: none;&#10;&#09;border-top-width: 0pt;&#10;&#09;border-right-width: 0pt;&#10;&#09;border-bottom-width: 0pt;&#10;&#09;border-left-width: 0pt;&#10;&#09;border-top-right-radius: 0pt 0pt;&#10;&#09;border-bottom-right-radius: 0pt 0pt;&#10;&#09;border-bottom-left-radius: 0pt 0pt;&#10;&#09;border-top-left-radius: 0pt 0pt;&#10;&#09;border-image-source: none;&#10;&#09;border-image-slice: 100% 100% 100% 100% fill;&#10;&#09;border-image-width: 1 1 1 1;&#10;&#09;border-image-outset: 0 0 0 0;&#10;&#09;border-image-repeat: stretch stretch;&#10;&#09;outline-width: 0pt;&#10;&#09;outline-style: none;&#10;&#09;outline-color: invert;&#10;&#09;outline-offset: 0pt;&#10;&#09;font-family: -fm-font-family(Helvetica,Helvetica);&#10;&#09;font-weight: normal;&#10;&#09;font-stretch: normal;&#10;&#09;font-style: normal;&#10;&#09;font-variant: normal;&#10;&#09;font-size: 12pt;&#10;&#09;color: rgba(63.9216%,63.9216%,63.9216%,1);&#10;&#09;direction: ltr;&#10;&#09;line-height: 1line;&#10;&#09;block-progression: tb;&#10;&#09;text-align: center;&#10;&#09;text-transform: none;&#10;&#09;text-indent: 0pt;&#10;&#09;box-shadow: none;&#10;&#09;box-sizing: content-box;&#10;&#09;vertical-align: baseline;&#10;&#09;-fm-digit-set: roman;&#10;&#09;-fm-space-before: 0line;&#10;&#09;-fm-space-after: 0line;&#10;&#09;-fm-tab-stops: ;&#10;&#09;-fm-strikethrough: false;&#10;&#09;-fm-underline: none;&#10;&#09;-fm-glyph-variant: ;&#10;&#09;-fm-paragraph-margin-left: 0pt;&#10;&#09;-fm-paragraph-margin-right: 0pt;&#10;&#09;-fm-character-direction: ;&#10;&#09;-fm-use-default-appearance: false;&#10;&#09;-fm-override-with-classic: false;&#10;&#09;-fm-baseline-shift: 0pt;&#10;&#09;-fm-fill-effect: 0;&#10;&#09;-fm-highlight-color: rgba(0%,0%,0%,0);&#10;&#09;-fm-text-vertical-align: center;&#10;&#09;-fm-tategaki: false;&#10;&#09;-fm-rotation: 0;&#10;&#09;-fm-borders-between-reps: false;&#10;&#09;-fm-borders-baseline: false;&#10;&#09;-fm-texty-field: false;&#10;&#09;-fm-box-shadow-persist: none;&#10;}&#10;self:hover .self&#10;{&#10;&#09;background-color: rgba(0%,0%,0%,1);&#10;&#09;color: rgba(18.4314%,52.1569%,98.0392%,1);&#10;}&#10;self:pressed .self&#10;{&#10;&#09;background-color: rgba(0%,0%,0%,1);&#10;&#09;color: rgba(13.3333%,36.4706%,67.451%,1);&#10;}&#10;self:checked .self&#10;{&#10;&#09;background-color: rgba(0%,0%,0%,1);&#10;&#09;color: rgba(18.4314%,52.1569%,98.0392%,1);&#10;}&#10;self:normal .inner_border&#10;{&#10;&#09;border-top-color: rgba(0%,0%,0%,0);&#10;&#09;border-right-color: rgba(0%,0%,0%,0);&#10;&#09;border-bottom-color: rgba(0%,0%,0%,0);&#10;&#09;border-left-color: rgba(0%,0%,0%,0);&#10;&#09;border-top-style: none;&#10;&#09;border-right-style: none;&#10;&#09;border-bottom-style: none;&#10;&#09;border-left-style: none;&#10;&#09;border-top-width: 0pt;&#10;&#09;border-right-width: 0pt;&#10;&#09;border-bottom-width: 0pt;&#10;&#09;border-left-width: 0pt;&#10;&#09;border-top-right-radius: 0pt 0pt;&#10;&#09;border-bottom-right-radius: 0pt 0pt;&#10;&#09;border-bottom-left-radius: 0pt 0pt;&#10;&#09;border-top-left-radius: 0pt 0pt;&#10;&#09;padding-top: 0pt;&#10;&#09;padding-right: 0pt;&#10;&#09;padding-bottom: 0pt;&#10;&#09;padding-left: 0pt;&#10;&#09;margin-top: 0pt;&#10;&#09;margin-right: 0pt;&#10;&#09;margin-bottom: 0pt;&#10;&#09;margin-left: 0pt;&#10;&#09;width: auto;&#10;&#09;height: auto;&#10;&#09;top: auto;&#10;&#09;right: auto;&#10;&#09;bottom: auto;&#10;&#09;left: auto;&#10;&#09;position: static;&#10;&#09;box-shadow: none;&#10;&#09;box-sizing: content-box;&#10;}&#10;self:focus .inner_border&#10;{&#10;&#09;box-shadow: inset 0pt 0pt 2pt 1pt rgba(0%,43.9216%,81.1765%,1);&#10;}&#10;self:normal .text&#10;{&#10;&#09;width: 100%;&#10;&#09;height: 100%;&#10;&#09;box-sizing: border-box;&#10;}&#10;self:normal .icon&#10;{&#10;&#09;-fm-icon-color: rgba(63.9216%,63.9216%,63.9216%,1);&#10;&#09;-fm-icon-padding: 0.33em;&#10;}&#10;self:hover .icon&#10;{&#10;&#09;-fm-icon-color: rgba(18.4314%,52.1569%,98.0392%,1);&#10;}&#10;self:pressed .icon&#10;{&#10;&#09;-fm-icon-color: rgba(13.3333%,36.4706%,67.451%,1);&#10;}&#10;self:checked .icon&#10;{&#10;&#09;-fm-icon-color: rgba(18.4314%,52.1569%,98.0392%,1);&#10;}&#10;self:normal .baseline&#10;{&#10;&#09;border-top-color: rgba(0%,0%,0%,0);&#10;&#09;border-right-color: rgba(0%,0%,0%,0);&#10;&#09;border-bottom-color: rgba(0%,0%,0%,0);&#10;&#09;border-left-color: rgba(0%,0%,0%,0);&#10;&#09;border-top-style: none;&#10;&#09;border-right-style: none;&#10;&#09;border-bottom-style: none;&#10;&#09;border-left-style: none;&#10;&#09;border-top-width: 0pt;&#10;&#09;border-right-width: 0pt;&#10;&#09;border-bottom-width: 0pt;&#10;&#09;border-left-width: 0pt;&#10;}&#10;</FullCSS>
<ThemeName>com.filemaker.theme.enlightened</ThemeName></Styles>
<CharacterStyleVector>
<Style>
<Data></Data>
<CharacterStyle mask=\"32695\">
<Font-family codeSet=\"Roman\" fontId=\"0\" postScript=\"Helvetica\">Helvetica</Font-family>
<Font-size>12</Font-size>
<Face>0</Face>
<Color>#A3A3A3</Color>
</CharacterStyle>
</Style>
</CharacterStyleVector>
<ParagraphStyleVector>
<Style>
<Data></Data>
<ParagraphStyle mask=\"0\">
</ParagraphStyle>
</Style>
</ParagraphStyleVector>
</TextObj>
<ButtonObj buttonFlags=\"0\" iconSize=\"12\" displayType=\"1\">
<Stream size=\"24\">
<Type>FNAM</Type>
<HexData>000000010533373B3D3F000C3B6F690533343C3574292C3D</HexData>
</Stream>
<Stream size=\"1\">
<Type>GLPH</Type>
<HexData>01</HexData>
</Stream>
<Stream size=\"712\">
<Type>SVG </Type>
<HexData>3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D227574662D38223F3E0D0A3C7376672076657273696F6E3D22312E322220786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F7376672220786D6C6E733A786C696E6B3D22687474703A2F2F7777772E77332E6F72672F313939392F786C696E6B220D0A0920783D223070782220793D22307078222077696474683D223234707822206865696768743D2232347078222076696577426F783D22302030203234203234223E0D0A3C6720636C6173733D22666D5F66696C6C223E0D0A3C7061746820643D224D31322E3030312C3043352E3337332C302C302C352E3337332C302C313263302C362E3632372C352E3337332C31322C31322E3030312C31324331382E3632372C32342C32342C31382E3632372C32342C31320D0A094332342C352E3337332C31382E3632372C302C31322E3030312C307A204D31312E3831392C342E303563302E3930352C302C312E3630362C302E3637392C312E3630362C312E35383363302C302E38362D302E3730312C312E3538342D312E3632392C312E3538340D0A09632D302E3833372C302D312E3538342D302E3732342D312E3538342D312E3538344331302E3231332C342E3732392C31302E39362C342E30352C31312E3831392C342E30357A204D31342E3839362C31382E39313648392E313034762D302E3732350D0A0963312E3331322D302E3135382C312E3434382D302E32352C312E3434382D312E383535762D342E343863302D312E3439342D302E3135382D312E3536312D312E3234352D312E37343256392E34353863312E3335372D302E3135392C322E3835312D302E3435332C342E3131382D302E38313476372E3639330D0A0963302C312E3536322C302E3131322C312E3637342C312E3437312C312E3835355631382E3931367A222F3E0D0A3C2F673E0D0A3C2F7376673E0D0A</HexData>
</Stream>
</ButtonObj>
</Object>
<Object type=\"Button\" key=\"112\" LabelKey=\"0\" flags=\"8\" rotation=\"0\">
<Bounds top=\"0.0000000\" left=\"42.0000000\" bottom=\"30.0000000\" right=\"84.0000000\"/>
<TextObj flags=\"2\">
<ExtendedAttributes fontHeight=\"10\" graphicFormat=\"5\">
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
<CharacterStyle mask=\"32695\">
<Font-family codeSet=\"Roman\" fontId=\"0\" postScript=\"Helvetica\">Helvetica</Font-family>
<Font-size>12</Font-size>
<Face>0</Face>
<Color>#A3A3A3</Color>
</CharacterStyle>
</ExtendedAttributes>
<Styles>
<FullCSS>
self:normal .self&#10;{&#10;&#09;background-image: none;&#10;&#09;background-position: 0% 0%;&#10;&#09;background-size: auto;&#10;&#09;background-repeat: repeat repeat;&#10;&#09;background-origin: padding-box;&#10;&#09;background-clip: border-box;&#10;&#09;background-color: rgba(0%,0%,0%,1);&#10;&#09;border-top-color: rgba(0%,0%,0%,0);&#10;&#09;border-right-color: rgba(0%,0%,0%,0);&#10;&#09;border-bottom-color: rgba(0%,0%,0%,0);&#10;&#09;border-left-color: rgba(0%,0%,0%,0);&#10;&#09;border-top-style: none;&#10;&#09;border-right-style: none;&#10;&#09;border-bottom-style: none;&#10;&#09;border-left-style: none;&#10;&#09;border-top-width: 0pt;&#10;&#09;border-right-width: 0pt;&#10;&#09;border-bottom-width: 0pt;&#10;&#09;border-left-width: 0pt;&#10;&#09;border-top-right-radius: 0pt 0pt;&#10;&#09;border-bottom-right-radius: 0pt 0pt;&#10;&#09;border-bottom-left-radius: 0pt 0pt;&#10;&#09;border-top-left-radius: 0pt 0pt;&#10;&#09;border-image-source: none;&#10;&#09;border-image-slice: 100% 100% 100% 100% fill;&#10;&#09;border-image-width: 1 1 1 1;&#10;&#09;border-image-outset: 0 0 0 0;&#10;&#09;border-image-repeat: stretch stretch;&#10;&#09;outline-width: 0pt;&#10;&#09;outline-style: none;&#10;&#09;outline-color: invert;&#10;&#09;outline-offset: 0pt;&#10;&#09;font-family: -fm-font-family(Helvetica,Helvetica);&#10;&#09;font-weight: normal;&#10;&#09;font-stretch: normal;&#10;&#09;font-style: normal;&#10;&#09;font-variant: normal;&#10;&#09;font-size: 12pt;&#10;&#09;color: rgba(63.9216%,63.9216%,63.9216%,1);&#10;&#09;direction: ltr;&#10;&#09;line-height: 1line;&#10;&#09;block-progression: tb;&#10;&#09;text-align: center;&#10;&#09;text-transform: none;&#10;&#09;text-indent: 0pt;&#10;&#09;box-shadow: none;&#10;&#09;box-sizing: content-box;&#10;&#09;vertical-align: baseline;&#10;&#09;-fm-digit-set: roman;&#10;&#09;-fm-space-before: 0line;&#10;&#09;-fm-space-after: 0line;&#10;&#09;-fm-tab-stops: ;&#10;&#09;-fm-strikethrough: false;&#10;&#09;-fm-underline: none;&#10;&#09;-fm-glyph-variant: ;&#10;&#09;-fm-paragraph-margin-left: 0pt;&#10;&#09;-fm-paragraph-margin-right: 0pt;&#10;&#09;-fm-character-direction: ;&#10;&#09;-fm-use-default-appearance: false;&#10;&#09;-fm-override-with-classic: false;&#10;&#09;-fm-baseline-shift: 0pt;&#10;&#09;-fm-fill-effect: 0;&#10;&#09;-fm-highlight-color: rgba(0%,0%,0%,0);&#10;&#09;-fm-text-vertical-align: center;&#10;&#09;-fm-tategaki: false;&#10;&#09;-fm-rotation: 0;&#10;&#09;-fm-borders-between-reps: false;&#10;&#09;-fm-borders-baseline: false;&#10;&#09;-fm-texty-field: false;&#10;&#09;-fm-box-shadow-persist: none;&#10;}&#10;self:hover .self&#10;{&#10;&#09;background-color: rgba(0%,0%,0%,1);&#10;&#09;color: rgba(18.4314%,52.1569%,98.0392%,1);&#10;}&#10;self:pressed .self&#10;{&#10;&#09;background-color: rgba(0%,0%,0%,1);&#10;&#09;color: rgba(13.3333%,36.4706%,67.451%,1);&#10;}&#10;self:checked .self&#10;{&#10;&#09;background-color: rgba(0%,0%,0%,1);&#10;&#09;color: rgba(18.4314%,52.1569%,98.0392%,1);&#10;}&#10;self:normal .inner_border&#10;{&#10;&#09;border-top-color: rgba(0%,0%,0%,0);&#10;&#09;border-right-color: rgba(0%,0%,0%,0);&#10;&#09;border-bottom-color: rgba(0%,0%,0%,0);&#10;&#09;border-left-color: rgba(0%,0%,0%,0);&#10;&#09;border-top-style: none;&#10;&#09;border-right-style: none;&#10;&#09;border-bottom-style: none;&#10;&#09;border-left-style: none;&#10;&#09;border-top-width: 0pt;&#10;&#09;border-right-width: 0pt;&#10;&#09;border-bottom-width: 0pt;&#10;&#09;border-left-width: 0pt;&#10;&#09;border-top-right-radius: 0pt 0pt;&#10;&#09;border-bottom-right-radius: 0pt 0pt;&#10;&#09;border-bottom-left-radius: 0pt 0pt;&#10;&#09;border-top-left-radius: 0pt 0pt;&#10;&#09;padding-top: 0pt;&#10;&#09;padding-right: 0pt;&#10;&#09;padding-bottom: 0pt;&#10;&#09;padding-left: 0pt;&#10;&#09;margin-top: 0pt;&#10;&#09;margin-right: 0pt;&#10;&#09;margin-bottom: 0pt;&#10;&#09;margin-left: 0pt;&#10;&#09;width: auto;&#10;&#09;height: auto;&#10;&#09;top: auto;&#10;&#09;right: auto;&#10;&#09;bottom: auto;&#10;&#09;left: auto;&#10;&#09;position: static;&#10;&#09;box-shadow: none;&#10;&#09;box-sizing: content-box;&#10;}&#10;self:focus .inner_border&#10;{&#10;&#09;box-shadow: inset 0pt 0pt 2pt 1pt rgba(0%,43.9216%,81.1765%,1);&#10;}&#10;self:normal .text&#10;{&#10;&#09;width: 100%;&#10;&#09;height: 100%;&#10;&#09;box-sizing: border-box;&#10;}&#10;self:normal .icon&#10;{&#10;&#09;-fm-icon-color: rgba(63.9216%,63.9216%,63.9216%,1);&#10;&#09;-fm-icon-padding: 0.33em;&#10;}&#10;self:hover .icon&#10;{&#10;&#09;-fm-icon-color: rgba(18.4314%,52.1569%,98.0392%,1);&#10;}&#10;self:pressed .icon&#10;{&#10;&#09;-fm-icon-color: rgba(13.3333%,36.4706%,67.451%,1);&#10;}&#10;self:checked .icon&#10;{&#10;&#09;-fm-icon-color: rgba(18.4314%,52.1569%,98.0392%,1);&#10;}&#10;self:normal .baseline&#10;{&#10;&#09;border-top-color: rgba(0%,0%,0%,0);&#10;&#09;border-right-color: rgba(0%,0%,0%,0);&#10;&#09;border-bottom-color: rgba(0%,0%,0%,0);&#10;&#09;border-left-color: rgba(0%,0%,0%,0);&#10;&#09;border-top-style: none;&#10;&#09;border-right-style: none;&#10;&#09;border-bottom-style: none;&#10;&#09;border-left-style: none;&#10;&#09;border-top-width: 0pt;&#10;&#09;border-right-width: 0pt;&#10;&#09;border-bottom-width: 0pt;&#10;&#09;border-left-width: 0pt;&#10;}&#10;</FullCSS>
<ThemeName>com.filemaker.theme.enlightened</ThemeName></Styles>
<CharacterStyleVector>
<Style>
<Data></Data>
<CharacterStyle mask=\"32695\">
<Font-family codeSet=\"Roman\" fontId=\"0\" postScript=\"Helvetica\">Helvetica</Font-family>
<Font-size>12</Font-size>
<Face>0</Face>
<Color>#A3A3A3</Color>
</CharacterStyle>
</Style>
</CharacterStyleVector>
<ParagraphStyleVector>
<Style>
<Data></Data>
<ParagraphStyle mask=\"0\">
</ParagraphStyle>
</Style>
</ParagraphStyleVector>
</TextObj>
<ButtonObj buttonFlags=\"0\" iconSize=\"12\" displayType=\"1\">
<Stream size=\"27\">
<Type>FNAM</Type>
<HexData>000000010533373B3D3F000F3B6E69053935342E3B392E74292C3D</HexData>
</Stream>
<Stream size=\"1\">
<Type>GLPH</Type>
<HexData>01</HexData>
</Stream>
<Stream size=\"1811\">
<Type>SVG </Type>
<HexData>3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D227574662D38223F3E0D0A3C7376672076657273696F6E3D22312E322220786D6C6E733D22687474703A2F2F7777772E77332E6F72672F323030302F7376672220786D6C6E733A786C696E6B3D22687474703A2F2F7777772E77332E6F72672F313939392F786C696E6B220D0A0920783D223070782220793D22307078222077696474683D223234707822206865696768743D2232347078222076696577426F783D22302030203234203234223E0D0A3C6720636C6173733D22666D5F66696C6C223E0D0A3C7061746820643D224D32332E3539382C31382E383839632D302E3135342D302E3333322D302E3336352D302E3635322D302E3633332D302E393634632D302E32372D302E3331352D302E3631352D302E3534392D312E3035312D302E3730350D0A09632D302E3230352D302E3037312D302E3437312D302E3137312D302E3830332D302E333037632D302E3332382D302E3133342D302E3639372D302E3238372D312E3130392D302E343534632D302E3431322D302E3137342D302E3834382D302E3335342D312E3330372D302E35350D0A09632D302E3435352D302E3139372D302E3930382D302E3339312D312E3335352D302E353835632D302E3434392D302E3139372D302E3838352D302E3338372D312E3330352D302E353733632D302E3432322D302E3138352D302E3739392D302E33352D312E3132372D302E343934762D312E3830350D0A0963302D302E3038332C302E3032352D302E3231322C302E3037382D302E33393563302E3035312D302E3137392C302E3130372D302E3336362C302E3136382D302E35363463302E3037322D302E3232352C302E3134382D302E3436362C302E3233322D302E3732330D0A0963302E3138342D302E3334322C302E3333362D302E3732312C302E3437312D312E31313863302E3033372C302E3032342C302E3037382C302E3034352C302E3132332C302E30353263302E342C302E3036392C302E3730332D302E3639362C302E3738392D312E3632390D0A0963302E3038342D302E3931372C302E31382D312E3230352D302E3433342D312E32353263302D302E3034332C302E3030382D302E3038342C302E3030382D302E31323763302D312E30352D302E3131312D312E3933382D302E3333322D322E3636330D0A09632D302E3232312D302E3732342D302E32332D312E3234362D302E3631352D312E363933632D302E3338372D302E3434382D312E3132392D302E3833392D312E3633392D312E3034324331332E3234382C312E3039392C31322E3730372C312C31322E31332C310D0A09632D302E3538382C302D312E31342C302E3235392D312E36352C302E34363543392E3937312C312E3637322C392E3135312C312E3838362C382E3737312C322E3334632D302E33382C302E3435332D302E3330322C302E3939352D302E3532342C312E3731360D0A0943382E3033322C342E3736312C372E3938332C352E3739392C372E3938322C362E383139632D302E30312C302D302E3031382C302D302E3032372C3043372E33312C362E38362C372E3430392C372E3134332C372E3439362C382E3037360D0A0963302E3038372C302E3933332C302E33392C312E3639392C302E3739312C312E36323863302E30342D302E3030372C302E3037372D302E3032372C302E3131322D302E30343863302E31342C302E3431392C302E3239372C302E3831362C302E3439312C312E3137350D0A0963302E30382C302E3233362C302E3135332C302E3435392C302E3231362C302E36363263302E3035312C302E3137362C302E312C302E3334382C302E3134362C302E35313763302E3034342C302E3137322C302E30382C302E3239372C302E3039392C302E33373976312E3736310D0A09632D302E3331392C302E3134352D302E3638382C302E3330392D312E3131312C302E343933632D302E3432312C302E3138352D302E3836392C302E3337392D312E3334342C302E353838632D302E34372C302E3230342D302E3934372C302E3430392D312E3432362C302E3631360D0A09632D302E3437382C302E3230362D302E3933332C302E342D312E3336372C302E3538632D302E3433312C302E3137362D302E3832322C302E3333382D312E3137312C302E343737632D302E3335312C302E31342D302E3633332C302E3234342D302E38352C302E3331350D0A09632D302E3432322C302E3135362D302E3736352C302E33392D312E3033332C302E373035632D302E3236372C302E3331322D302E34382C302E3633322D302E3633332C302E39363443302E32332C31392E3236392C302E3039322C31392E3637312C302C32302E30393276312E3936683234762D312E39360D0A094332332E3931382C31392E3637312C32332E3738332C31392E3236392C32332E3539382C31382E3838397A222F3E0D0A3C2F673E0D0A3C2F7376673E0D0A</HexData>
</Stream>
</ButtonObj>
</Object>
</ButtonBarObj>
</Object>
</Layout></fmxmlsnippet>"
	
end someButtonBarXML






