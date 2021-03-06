{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Test the lexical analyzer for a compiler CS class

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

program Lex_Test;

uses TokenDef, SymTable, Lex_Anal;

var
   Token: tToken;
   Value: tTokenValue;
   Count: integer;
begin
   Open_Source( 'MyPrg.cmp');
   repeat
      Get_Token( Token, Value);
      Inc( Count);
   until (Token = EndOfFile_tk);
   Close_Source;
   DumpSymbolTable;
end.
