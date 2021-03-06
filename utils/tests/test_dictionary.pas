{* ***************************************************************************

    Copyright (c) 2017 by Lloyd B. Park

    test_dictionary - Test my generic dictionary

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

program test_dictionary;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_generic_dictionaries,
   lbp_types;


// ************************************************************************

type
   tStringClass = class( tObject)
   public
      Value: String;
      Constructor Create( MyValue: string);
   end; // tStringClass


constructor tStringClass.Create( MyValue: string);
   begin
      Value:= MyValue;
   end;


// ************************************************************************

type
   tStringDictionary = specialize tgDictionary< string, test_dictionary.tStringClass>;

var
   A: tStringClass;
   B: tStringClass;
   C: tStringClass;
   D: tStringClass;
   E: tStringClass;
   F: tStringClass;
   G: tStringClass;
   Search: tStringClass;

// *************************************************************************
// * CompareStrings - global function used only by tStringTree
// *************************************************************************

function CompareStrings(  S1: string; S2: string): integer;
   begin
      if( S1 > S2) then begin
         result:= 1;
      end else if( S1 < S2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareStrings()


// *************************************************************************
// * NodeToString - global function used only by tStringTree
// *************************************************************************

function NodeToString( S: string): string;
   begin
      result:= S;
   end; // NodeToString;


// ************************************************************************
// * CreateStrings()
// ************************************************************************

procedure CreateStrings();
   begin
      A:= tStringClass.Create( 'aa');
      B:= tStringClass.Create( 'bb');
      C:= tStringClass.Create( 'cc');
      D:= tStringClass.Create( 'dd');
      E:= tStringClass.Create( 'ee');
      F:= tStringClass.Create( 'ff');
      G:= tStringClass.Create( 'gg');
      Search:= tStringClass.Create( 'ff');
   end; // CreateStrings()


// ************************************************************************
// * DestroyStrings()
// ************************************************************************

procedure DestroyStrings();
   begin
      A.Destroy;
      B.Destroy;
      C.Destroy;
      D.Destroy;
      E.Destroy;
      F.Destroy;
      G.Destroy;
      Search.Destroy;
   end; // DestroyStrings;


// ************************************************************************
// * FirstNextTest() - Test the First(), Next() functions
// ************************************************************************

procedure FirstNextTest();
   var
     Dict: tStringDictionary;
     V:    tStringClass;
     S:    string;
   begin
      CreateStrings;
      Dict:= tStringDictionary.Create( tStringDictionary.tCompareFunction( @CompareStrings));
      Dict.NodeToString:= tStringDictionary.tNodeToStringFunction( @NodeToString);

      Dict.Add( 'A', A);
      Dict.Add( 'B', B);
      Dict.Add( 'F', F);
      Dict.Add( 'G', G);
      Dict.Add( 'D', D);
      Dict.Add( 'E', E);
      Dict.Add( 'C', C);

      writeln( '------ Testing AVL Tree Find() function. ------');
      if( Dict.Find( 'F')) then writeln( '   Found: ', Dict.Value.Value);
      writeln( 'Find C using Dict[''C'']:  ',  Dict[ 'C'].Value);

      writeln( '------ Testing AVL Tree StartEnumeration() and Next() functions. ------');
      Dict.StartEnumeration();
      while( Dict.Next) do begin
         Writeln( '   ', Dict.Key, ' - ', Dict.Value.Value);
      end; 
      writeln;

      writeln( '------ Testing for Value in Dictionary functionality. ------');
      for V in Dict do Writeln( '   ', V.Value);
      writeln;

      writeln( '------ Testing for Key in Dictionary functionality. ------');
      for S in Dict.KeyEnum do Writeln( '   ', S);
      writeln;

      writeln( '------ Testing AVL Tree Dump procedure. ------');
      Dict.Dump;
      writeln;

      Dict.Destroy;
      DestroyStrings;
   end; // FirstNextTest()


// ************************************************************************
// * LastPreviouTest() - Test the StartEnumeration(), Previous() functions
// ************************************************************************

procedure LastPreviousTest();
   var
      Dict: tStringDictionary;
      V:    tStringClass;
      S:    string;
   begin
      CreateStrings;
      Dict:= tStringDictionary.Create( tStringDictionary.tCompareFunction( @CompareStrings));
      Dict.NodeToString:= tStringDictionary.tNodeToStringFunction( @NodeToString);

      Dict.Add( 'A', A);
      Dict.Add( 'B', B);
      Dict.Add( 'F', F);
      Dict.Add( 'G', G);
      Dict.Add( 'D', D);
      Dict.Add( 'E', E);
      Dict.Add( 'C', C);

      writeln( '------ Testing AVL Tree StartEnumeration() and Previous() functions. ------');
      Dict.StartEnumeration();
      while( Dict.Previous) do begin
         Writeln( '   ', Dict.Key, ' - ', Dict.Value.Value);
      end; 
      writeln;

      writeln( '------ Testing for Value in Dictionary functionality. ------');
      for V in Dict.Reverse do Writeln( '   ', V.Value);
      writeln;

      writeln( '------ Testing for Key in Dictionary functionality. ------');
      for S in Dict.ReverseKeyEnum do Writeln( '   ', S);
      writeln;

      // Remove all the StringObjects
      Search.Destroy();
      Dict.RemoveAll( true);
      // Remove the tree from memory also
      Dict.Destroy;
   end; // LastPreviousTest()


// ************************************************************************
// * main()
// ************************************************************************

begin
   FirstNextTest;
   LastPreviousTest;

   writeln( '------ Testing AVL Tree Dump() debugging function. ------')
end.  // test_dictionary
