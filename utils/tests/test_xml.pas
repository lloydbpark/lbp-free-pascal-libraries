{* ***************************************************************************

    Copyright (c) 2017 by Lloyd B. Park

    test_trees - Test my generic trees

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or 
    (at your option) any later version.


    This program is distributed in the hope that it will be useful,but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with this program.  If not, see 
    <http://www.gnu.org/licenses/>.

*************************************************************************** *}

program test_trees;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
//   lbp_generic_containers,
   lbp_types,
   lbp_xml,
   lbp_generic_containers;


// ************************************************************************
// * TestEscapeString()
// ************************************************************************

procedure TestEscapeString();
   var
      Xml:  tXmlElement;
      S:    string;
   begin
      Writeln( '-----------------------------------------------------------');
      Writeln( '- Testing escaping special characters in an XML string');
      Writeln( '-----------------------------------------------------------');
      Xml:= tXmlElement.Create();

      S:= '&<&';
      writeln( S, ':  ', Xml.EscapeString( S,'"'));
      writeln( S, ':  ', Xml.EscapeString( S,''''));

      S:= 'Lloyd & Amey.  2 < 3';
      writeln( S, ':  ', Xml.EscapeString( S));
      S:= '''Lloyd'' & "Amey".  2 < 3';
      writeln( S, ':  ', Xml.EscapeString( S, '"'));
      S:= '''Lloyd'' & "Amey".  2 < 3';
      writeln( S, ':  ', Xml.EscapeString( S, ''''));

      writeln;
      Xml.Destroy;
   end; // TestEscapeString();


// ************************************************************************
// * TestAttribute()
// ************************************************************************

// procedure TestAttribute();
//    var
//       A: tXmlAttribute;
//    begin
//       A:= tXmlAttribute.Create;
//       A.Add( 'href', 'http://www.w3.org/XML');
//       A.Add( 'Lloyd', 'Family');

//       writeln( '------- Testing XML Attribute functionality --------');
//       if( A.Find( 'href')) then writeln( '   Found: ', A.Value);

//       A.Destroy;
//    end; // TestAttribute()


// ************************************************************************
// * Main()
// ************************************************************************

begin
//    TestAttribute();
   TestEscapeString();
end.  // test_xml program
