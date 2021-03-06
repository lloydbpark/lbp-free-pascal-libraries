{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A lexical analyzer for a compiler CS class

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

{ Lexical Analyzer module.                              Lloyd B. Park  }
{                             January 31, 1992                         }
{  1.  April 01, 1993                                                  }
{         Initialized new Identifier's attributes in the sybol table   }
{                                                                      }
{                                                                      }
{ This Turbo Pascal unit performs a lexical analysis of the input file }

unit Lex_Anal;

{ ************************************************************************ }
interface         { This section defines identifiers that can be visable }
                  { to other Turbo Pascal modules.                       }
{ ************************************************************************ }

uses Buffered, TokenDef, SymTable;

{ ************************************************************************ }

procedure Open_Source( FileName: string);
   { Opens the Source file for input. }

procedure Close_Source;
   { Closes the Source file. }

procedure Get_Token( var Token: tToken; var Value: tTokenValue);
   { Reads the input file and returns the next token and its value }

{ ************************************************************************ }
implementation  { This section defines the hidden portions of this module }
{ ************************************************************************ }

var
   Lexeme_Beginning: tpChar;
   Forward:          tpChar;
   EndOfFileFlag:    boolean;
   Source:           tBuffered_File;

{ ************************************************************************ }

procedure Open_Source( FileName: string);
   { Opens the Source file for input. }
   begin
      Forward:= Open_File( Source, FileName);
      Get_Chr( Source, Forward);
      if (Forward^ <> Sentinel) then begin
         EndOfFileFlag:= false;
      end
      else begin
         EndOfFileFlag:= true;
      end;
   end; { Open_Source }

{ ************************************************************************ }

procedure Close_Source;
   { Closes the Source file. }
   begin
      Close_File( Source);
   end; { Close_Source }

{ ************************************************************************ }

procedure Get_Token( var Token: tToken; var Value: tTokenValue);
   { Reads the input file and returns the tokens and their values }
   var
      CommentFound: boolean;
      TempStr:      string[255];
      TempInt:      integer;
      Result:       integer;  { used for string to integer conversion }

   { --------------------------------------------------------------------- }

   procedure Get_Keyword_or_Identifier;
      var
         Symbol: tp_Symbol_Table_Entry;
         Image:  SymTable.tImage;
         i:      integer;
      begin
         { Move forward 1 char past the end of the Identifier text }
         repeat
            if (Forward^ in LowerCase) then
               { Convert to upper case letters }
               Forward^:= chr( ord( Forward^) + (ord('A') - ord('a')));
               Get_Chr( Source, Forward);
         until not (Forward^ in (Letters + Numbers));

         { Copy the identifier text to Image }
         i:= 0;
         while (Lexeme_Beginning <> Forward) do begin
            inc( i);
            Image[ i]:= Lexeme_Beginning^;
            Get_Chr( Source, Lexeme_Beginning);
         end;
         Image[ 0]:= chr( i); { Set the length of image }

         Symbol:= SymTable.Find( Image);
         if (Symbol = nil) then begin
            { It's not in the Symbol Table, so we need to add it }
            new( Symbol);
            Symbol^.Image:= Image;
            Symbol^.Token:= Identifier_tk;

            { Initialize the attributes }
            NewID( Symbol, NotDeclared, ScalarStruct, 0, 0);

            SymTable.Insert( Symbol);
         end;

         { Return the Token }
         Token:= Symbol^.Token;

         { If the token is an identifier, return a pointer to the symbol }
         if (Token = Identifier_tk) then begin
             Value.Symbol_Table_Entry:= Symbol;
         end;
      end; { Get_Keyword_or_Identifier }

   { --------------------------------------------------------------------- }

   procedure Get_Number;
      begin
         repeat
            Get_Chr( Source, Forward);
         until not (Forward^ in Numbers);

         { Copy the Lexeme to a pascal string }
         TempInt:= 0;
         while (Lexeme_Beginning <> Forward) do begin
            inc( TempInt);
            TempStr[ TempInt]:= Lexeme_Beginning^;
            Get_Chr( Source, Lexeme_Beginning);
         end;
         TempStr[ 0]:= chr( TempInt);  { Set the string length. }

         { Convert the Lexeme to a numeric value }
         val( TempStr, TempInt, Result);

         { Return the results }
         Token:= Number_tk;
         Value.IntValue:= TempInt;
      end;

   { --------------------------------------------------------------------- }

   procedure Get_Symbol;
      begin
         Get_Chr( Source, Forward);
         Case Lexeme_Beginning^ of
            ':': if (Forward^ = '=') then begin
                    Token:= Assign_tk;
                    Get_Chr( Source, Forward);
                 end
                 else begin
                    WriteLn( 'Invalid placement of ":".');
                    Halt;
                 end;
            '=': Token:= Equal_tk;
            '+': Token:= Add_tk;
            '-': if (Forward^ = '-') then begin
                    { Comment has been found }
                    CommentFound:= true;
                    { move forward to the end of the line }
                    repeat
                       Get_Chr( Source, Forward);
                    until (Forward^ = CR) or (Forward^ = Sentinel);
                 end { if comment }
                 else begin
                    Token:= Sub_tk;
                 end;
            '*': Token:= Mult_tk;
            '(': Token:= LeftParenthesis_tk;
            ')': Token:= RightParenthesis_tk;
            '[': Token:= LeftBracket_tk;
            ']': Token:= RightBracket_tk;
            ';': Token:= Semicolon_tk;
            ',': Token:= Comma_tk;
            '.': Token:= Period_tk;
            '<': if (Forward^ = '>') then begin
                    Token:= NotEqual_tk;
                    Get_Chr( Source, Forward);
                 end
                 else if (Forward^ = '=') then begin
                    Token:= LessThanOrEqual_tk;
                    Get_Chr( Source, Forward);
                 end
                 else begin
                    Token:= LessThan_tk;
                 end;
            '>': if (Forward^ = '=') then begin
                    Token:= GreaterThanOrEqual_tk;
                    Get_Chr( Source, Forward);
                 end
                 else begin
                    Token:= GreaterThan_tk;
                 end;
         end; { case }

      end; { Get_Symbol }
   { --------------------------------------------------------------------- }

   begin
      if EndOfFileFlag then begin
         Token:= EndOfFile_tk;
         exit; { Exit from the procedure returning the EndOfFile_Tk }
      end;

      repeat
         CommentFound:= false;
         { strip out the white space }
         while (Forward^ in WhiteSpace) do
            Get_Chr( Source, Forward);
         Lexeme_Beginning:= Forward;
         if (Forward^ in Letters) then Get_KeyWord_or_Identifier
         else if (Forward^ in Numbers) then Get_Number
         else if (Forward^ in Symbols) then Get_Symbol
         else if (Forward^ = Sentinel) then begin
            { End of file encountered }
            Token:= EndOfFile_tk;
            EndOfFileFlag:= true;
         end
         else begin
            WriteLn( 'Invalid character "', Forward^, '"');
            Halt;
         end;
      until (not CommentFound);
   end; { Get_Token }

{ ************************************************************************ }

end. { Lex_Anal }
