{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Extract data from an XML string or file.  Quote and unquote XML strings.
I used the data structure used by lxml.py.

This file is part of Lloyd's Free Pascal Libraries (LFPL).

    LFPL is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation, either version 2.1 of the 
    License, or (at your option) any later version with the following 
    modification:

    As a special exception, the copyright holders of this library 
    give you permission to link this library with independent modules
    to produce an executable, regardless of the license terms of these
    independent modules, and to copy and distribute the resulting 
    executable under terms of your choice, provided that you also meet,
    for each linked independent module, the terms and conditions of 
    the license of that module. An independent module is a module which
    is not derived from or based on this library. If you modify this
    library, you may extend this exception to your version of the 
    library, but you are not obligated to do so. If you do not wish to
    do so, delete this exception statement from your version.

    LFPL is distributed in the hope that it will be useful,but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General 
    Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with LFPL.  If not, see <http://www.gnu.org/licenses/>.

*************************************************************************** *}
unit lbp_xml;

// Classes to handle Comma Separated Value strings and files.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_generic_containers,
   lbp_parse_helper;


// *************************************************************************

var
   // Element and Attribute names.  // Best practice is to avoid using '-' and '.'
   ElementNameChrs: tCharSet = ['a'..'z', 'A'..'Z', '0'..'9', '-', '_', '.'];
   EscapableChrs:   tCharSet = ['&','<','>','''','"']; 


// *************************************************************************

type
   tStringDict = specialize tgDictionary< string, string>;


// *************************************************************************

type
   tXmlElement = class( tObject)
      public type
         tXmlElementArray = array of tXmlElement;
      public
         Tag:     string;
         Text:    string;
         Tail:    string;
//         Attrib:  tStringDict;
         Child:  tXmlElementArray;
         function EscapeString( S: string; Quote: char = chr( 0)): string;
      end; // tXmlElement


// *************************************************************************

type
   tXml = class( tChrSource)
      private
         MyProlog = tXmlProlog;
         MyRoot = tXmlElement;

// *************************************************************************

implementation

// =========================================================================
// = tXmlElement
// =========================================================================
// *************************************************************************
// * EscapeString() - Return a copy of the passed string with special 
// *                  characters escaped per the XML standard.  If the string
// *                  should be quoted, pass the quote character.  
// *************************************************************************

function tXmlElement.EscapeString( S: string; Quote: char): string;
   var
      Si:         integer; // StartIndex;
      Ei:         integer; // EndIndex;
      L:          integer; 
      AmpStr:     string;
      EscapeChrs: tCharSet = [ '&', '<'];
   begin
      L:= Length( S);
      if( Quote in QuoteChrs) then begin
         result:= Quote;
         EscapeChrs:= EscapeChrs + [Quote];
      end else begin
         result:= '';
      end;
      Si:= 1;
      Ei:= 1;

      repeat
         if( S[ Ei] in EscapeChrs) then begin
            case S[ EI] of
               '''': AmpStr:= '&apos;';
               '"':  AmpStr:= '&quot;';
               '<':  AmpStr:= '&lt;';
               '&':  AmpStr:= '&amp;';
            end; // case
            result:= result + Copy( S, Si, Ei - Si) + AmpStr;
            inc( Ei);
            Si:= Ei;
         end else begin;
            inc( Ei);
         end;
      until( Ei > L);
      result:= result + Copy( S, Si, Ei - Si);
      if( Quote in QuoteChrs) then begin
         result:= result + Quote;
      end;
   end; // EscapeString();
{*
Three ways of escaping special characters
    &#X followed by Hex number followed by ';'
    &# follwed by decimal number followed by ';'
    & follwed by character abreviations of the name
       &amp  &
       &lt   <
       &gt   >
       &apos '
       &quot "

Lookup CDATA
Lookup when you can (must?) use />
Lookup the character set standard mentioned

*}

end. // lbp_xml unit
