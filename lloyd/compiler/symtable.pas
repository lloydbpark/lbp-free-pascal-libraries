{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A symbol table for a compiler CS class

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

{ Symbol Table Module                                   Lloyd B. Park  }
{                             February 09, 1992                        }
{                                                                      }
{  1. April 01, 1993                                                   }
{       Added attributes TypeAttr, StructAttr, SizeAttr                }
{             AddrAttr to t_Symbol_Table_Entry                         }
{       Added New_ID, LookUp, IsDeclared procedures                    }
{                                                                      }
{ This Turbo Pascal unit performs symbol table maintenance.            }

unit SymTable;

{ ************************************************************************ }
interface         { This section defines identifiers that can be visable }
                  { to other Turbo Pascal modules.                       }
{ ************************************************************************ }

// uses TokenDef, Machine, Mach_If;
uses  TokenDef;

type
   tp_Symbol_Table_Entry = ^t_Symbol_Table_Entry;
   tTokenValue = record
         case tToken of
            Number_tk:     (IntValue:   integer);
            Identifier_tk: (Symbol_Table_Entry: tp_Symbol_Table_Entry);
      end; { tTokenValue }

   tTypeAttr = (IntegerType, ProgramNameType, KeyWordType, NotDeclared);
   tStructAttr = (ScalarStruct, ArrayStruct);
   tImage = string[ 64];
   t_Symbol_Table_Entry = record
         Token:      tToken;
         Image:      tImage;
         TypeAttr:   tTypeAttr;
         StructAttr: tStructAttr;
         SizeAttr:   tMachineWord;
         AddrAttr:   tMachineAddress;
      end;
   Item_Type = t_Symbol_Table_Entry;
   Item_Ptr  = tp_Symbol_Table_Entry;

{ ************************************************************************ }

function Find( var S: tImage): tp_Symbol_Table_Entry;
   { Searches the Symbol Table for an entry whose Image is S }
   { Returns nil if no match is found }

procedure Insert( Entry: tp_Symbol_Table_Entry);
   { Inserts Entry into the Hash Table and intializes TypeAttr.    }
   { NOTE!   No checks are made for duplicate entries.  It is the  }
   {         responsibility of the user to check for duplicates    }
   {         before Inserting an Entry                             }

procedure DumpSymbolTable;
   { This is a debugging procedure }
   { It dumps the images stored in the symbol table to the file SymTable.txt }

procedure NewID( Symbol:          tp_Symbol_Table_Entry;
                 TypeAttribute:   tTypeAttr;
                 StructAttribute: tStructAttr;
                 SizeAttribute:   tMachineWord;
                 AddrAttribute:   tMachineAddress);
   { Sets Symbol's attributes }

procedure Lookup( Symbol:          tp_Symbol_Table_Entry;
                 var TypeAttribute:   tTypeAttr;
                 var StructAttribute: tStructAttr;
                 var SizeAttribute:   tMachineWord;
                 var AddrAttribute:   tMachineAddress);
   { Retrieves the attribute information from Symbol }

function IsDeclared( Symbol: tp_Symbol_Table_Entry): boolean;
   { Returns true if Symbol's TypeAttribute <> NotDeclared }

{ ************************************************************************ }
implementation  { This section defines the hidden portions of this module }
{ ************************************************************************ }

const
   HashSize = 101; { should be a prime number }
   NumOfKeyWords = 12;

{$I Lists.pas}

{ ************************************************************************ }

type
   tKeywordEntries = array[ 1..NumOfKeyWords] of t_Symbol_Table_Entry;

const
   KeywordEntries: tKeywordEntries = (
       ( Token: Program_tk;  Image: 'PROGRAM'; TypeAttr: KeywordType),
       ( Token: Integer_tk;  Image: 'INTEGER'; TypeAttr: KeywordType),
       ( Token: Begin_tk;    Image: 'BEGIN';   TypeAttr: KeywordType),
       ( Token: End_tk;      Image: 'END';     TypeAttr: KeywordType),
       ( Token: If_tk;       Image: 'IF';      TypeAttr: KeywordType),
       ( Token: Then_tk;     Image: 'THEN';    TypeAttr: KeywordType),
       ( Token: Elsif_tk;    Image: 'ELSIF';   TypeAttr: KeywordType),
       ( Token: Else_tk;     Image: 'ELSE';    TypeAttr: KeywordType),
       ( Token: Div_tk;      Image: 'DIV';     TypeAttr: KeywordType),
       ( Token: Mod_tk;      Image: 'MOD';     TypeAttr: KeywordType),
       ( Token: While_tk;    Image: 'WHILE';   TypeAttr: KeywordType),
       ( Token: Do_tk;       Image: 'DO';      TypeAttr: KeywordType));

var
   HashTable: array[ 0..(HashSize - 1)] of List_Type;

{ ************************************************************************ }

function GetHashValue( var I: tImage): integer;
   { Returns a hash value for image I }
   { I must have a length of at least 1. }
   var
      Temp: integer;
   begin
      case Length( I) of
         1: Temp:= 5 * ord( I[ 1]);
         2: Temp:= 3 * ord( I[ 1]) + 2 * ord( I[ 2]);
         3: Temp:= ord( I[ 1]) + 2 * (ord( I[ 2]) + ord( I[ 3]));
         4: Temp:= ord( I[ 1]) + ord( I[ 2]) + 2 * ord( I[ 3]) + ord( I[ 4]);
         else Temp:= ord( i[ 1]) + ord( i[2]) + ord( i[ 3]) +
                     ord( i[ length( i) - 1]) + ord( i[ length( i)]);
      end; { case }
      GetHashValue:= Temp mod HashSize;
   end; { GetHashValue }

{ ************************************************************************ }

function Find( var S: tImage): tp_Symbol_Table_Entry;
   { Searches the Symbol Table for an entry whose Image is S }
   { Returns nil if no match is found }
   var
      Found: boolean;
      index: integer;
      Temp:  tp_Symbol_Table_Entry;
   begin
      index:= GetHashValue( S);
      Found:= false;
      Temp:= GetFirst( HashTable[ index]);
      if Temp = nil then begin
         Find:= nil;
      end
      else begin { the list is not empty }
         if (Temp^.Image = S) then Found:= true;
         while (Temp <> nil) and (not Found) do begin
            Temp:= GetNext( HashTable[ index]);
            if (Temp^.Image = S) then Found:= true;
         end;
         if Found and (not First( HashTable[ index])) then begin
            { For quicker access, move the most recently found entry }
            {   to the front of the list }
            Temp:= Remove( HashTable[ index]);
            AddFront( Temp, HashTable[ index]);
         end;
         Find:= Temp;
      end; { else - list is not empty }

   end; { Find }

{ ************************************************************************ }

procedure InsertSub( Entry: tp_Symbol_Table_Entry);
   { Inserts Entry into the Hash Table.                            }
   { NOTE!   No checks are made for duplicate entries.  It is the  }
   {         responsibility of the user to check for duplicates    }
   {         before Inserting an Entry                             }

   var
      index: integer;
   begin
      index:= GetHashValue( Entry^.Image);
      AddFront( Entry, HashTable[ index]);
   end; { Insert }

{ ************************************************************************ }

procedure Insert( Entry: tp_Symbol_Table_Entry);
   { Inserts Entry into the Hash Table and initializes TypeAttr.   }
   { NOTE!   No checks are made for duplicate entries.  It is the  }
   {         responsibility of the user to check for duplicates    }
   {         before Inserting an Entry                             }

   begin
      InsertSub( Entry);
      Entry^.TypeAttr:= NotDeclared;
   end;

{ ************************************************************************ }

procedure DumpSymbolTable;
   { This is a debugging procedure }
   { It dumps the images stored in the symbol table }
   var
      i: integer;
      Entry: tp_Symbol_Table_Entry;
      f:     Text; { a text file }
      Temp:  HexString;
   begin
      assign( f, 'SymTable.txt');
      rewrite( f);
      WriteLn( f, 'Symbol Table Dump');
      for i:= 0 to HashSize-1 do begin
         if not Empty( HashTable[ i]) then begin
            WriteLn( f, '   Table Index = ', i);
            Entry:= GetFirst( HashTable[ i]);
            while (Entry <> nil) do begin
               Write( f, '        ');
               case Entry^.TypeAttr of
                  KeyWordType: begin
                        writeln( f, '(keyword) = ', Entry^.Image);
                     end;
                  ProgramNameType: begin
                        writeln( f, '(program) = ', Entry^.Image);
                     end;
                  NotDeclared: begin
                        writeln( f, '(not declared) = ', Entry^.Image);
                     end;
                  IntegerType:  begin
                        Write( f, Entry^.Image);
                        if (Entry^.StructAttr = ArrayStruct) then begin
                           Write( f, '[', Entry^.SizeAttr, ']');
                        end;
                        Dec_to_Hex( Entry^.AddrAttr, Temp);
                        WriteLn( f, ' @', Temp);
                     end;
               end; { case }
               Entry:= GetNext( HashTable[ i]);
            end; { while }
         end; { if }
      end; { for }
      close( f);
   end; { DumpSymbolTable }

{ ************************************************************************ }

procedure NewID( Symbol:          tp_Symbol_Table_Entry;
                 TypeAttribute:   tTypeAttr;
                 StructAttribute: tStructAttr;
                 SizeAttribute:   tMachineWord;
                 AddrAttribute:   tMachineAddress);
   { Sets Symbol's attributes }
   begin
      with Symbol^ do begin
         TypeAttr:=   TypeAttribute;
         StructAttr:= StructAttribute;
         SizeAttr:=   SizeAttribute;
         AddrAttr:=   AddrAttribute;
      end;
   end; { NewID }

{ ************************************************************************ }

procedure Lookup( Symbol:          tp_Symbol_Table_Entry;
                 var TypeAttribute:   tTypeAttr;
                 var StructAttribute: tStructAttr;
                 var SizeAttribute:   tMachineWord;
                 var AddrAttribute:   tMachineAddress);
   { Retrieves the attribute information from Symbol }
   begin
      with Symbol^ do begin
         TypeAttribute:=   TypeAttr;
         StructAttribute:= StructAttr;
         SizeAttribute:=   SizeAttr;
         AddrAttribute:=   AddrAttr;
      end;
   end; { Lookup }

{ ************************************************************************ }

function IsDeclared( Symbol: tp_Symbol_Table_Entry): boolean;
   { Returns true if Symbol's TypeAttr <> NotDeclared }
   begin
      if Symbol^.TypeAttr = NotDeclared then begin
         IsDeclared:= false;
      end
      else begin
         IsDeclared:= true;
      end;
   end; { IsDeclared }

{ ************************************************************************ }

var
  i:     integer;
  temp:  tp_Symbol_Table_Entry;

begin { SymTable }
   { Make all the HashTable lists empty }
   for i:= 0 to HashSize-1 do begin
      Initialize( HashTable[ i]);
   end;
   { Add the keywords to the hash table }
   for i:= 1 to NumOfKeywords do begin
      Temp:= Addr( KeywordEntries[ i]);
      { Temp = the address of KeywordEntries[ i] }
      InsertSub( Temp);
   end;
end. { SymTable }
