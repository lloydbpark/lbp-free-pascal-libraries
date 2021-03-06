{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

<brief description of the file.  for exampl: Definition of common types>

Token definitions from an old compiler CS course

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

{ Token definitions                                     Lloyd B. Park  }
{                             February 09, 1992                        }
{                                                                      }
unit TokenDef;

{ ************************************************************************ }
interface         { This section defines identifiers that can be visable }
                  { to other Turbo Pascal modules.                       }
{ ************************************************************************ }

type
   tToken = ( Start_of_Keywords_tk,
                 Program_tk,
                 Integer_tk,
                 Begin_tk,
                 End_tk,
                 If_tk,
                 Then_tk,
                 Elsif_tk,
                 Else_tk,
                 Div_tk,
                 Mod_tk,
                 While_tk,
                 Do_tk,
              End_of_Keywords_tk,
              Start_of_Operators_tk,
                 Assign_tk,
                 Add_tk,
                 Sub_tk,
                 Mult_tk,
                 RightParenthesis_tk,
                 LeftParenthesis_tk,
                 RightBracket_tk,
                 LeftBracket_tk,
                 Semicolon_tk,
                 Comma_tk,
                 Period_tk,
                 LessThan_tk,
                 LessThanOrEqual_tk,
                 Equal_tk,
                 GreaterThanOrEqual_tk,
                 GreaterThan_tk,
                 NotEqual_tk,
              End_of_Operators_tk,
              Identifier_tk,
              Number_tk,
              EndOfFile_tk );

const
    Tab      = chr( 8);
    Space    = chr( 32);
    LF       = chr( 10);
    CR       = chr( 13);
    Sentinel = chr( 4);  { Sentinel char to mark the ends of the buffers and }
                         { end of the file. }

    LowerCase      = ['a'..'z'];
    Letters        = ['a'..'z','A'..'Z', '_'];
    Numbers        = ['0'..'9'];
    Symbols        = [':', '=', '+', '-', '*', '(', ')', '[', ']', ';',
                      ',', '.', '<', '>'];
    WhiteSpace     = [ Tab, LF, CR, Space];
    KeywordTokens  = [ Start_of_Keywords_tk..End_of_Keywords_tk];
    OperatorTokens = [ Start_of_Operators_tk..End_of_Operators_tk];

{ ************************************************************************ }
implementation  { This section defines the hidden portions of this module }
{ ************************************************************************ }

begin  { TokenDef }
end. { TokenDef }
