{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A newer version of the parser for a compiler CS class

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

{ Parser program.                                       Lloyd B. Park  }
{                             March 03, 1992                           }
{                                                                      }
{           1  modified to include code generation  April 01, 1993     }
{                                                                      }
{                                                                      }

program Parser;

uses TokenDef, SymTable, Lex_Anal, Machine, Mach_if;

{ ************************************************************************ }
{ * Global variables * }
{ ******************** }

var
   Next_Token: tToken;
   Next_Value: tTokenValue;

{ ************************************************************************ }

procedure AExpr; forward;
procedure StatementLst; forward;

{ ************************************************************************ }

procedure Factor;
   var
      name:            tp_Symbol_Table_Entry;
      t:               tTypeAttr;
      struct:          tStructAttr;
      size:            tMachineWord;
      addr:            tMachineAddress;
      ExpectedStruct:  tStructAttr;
   begin
      { Next_Token must be one of the following or its an error }
      Case Next_Token of
         Identifier_tk: begin { Identifier or Array }
               begin { sem }
                  SetVariableName( name^.Image); { in Dump File output }
                  name:= Next_Value.Symbol_Table_Entry;
                  if not IsDeclared( name) then begin
                     WriteLn( 'ERROR: undeclared identifier');
                     halt;
                  end;
                  SetVariableName( name^.Image); { in Dump File output }
                  Lookup( name, t, struct, size, addr);
                  Emit2( LoadI_mi, addr);
                  ExpectedStruct:= ScalarStruct;
               end; { sem }

               Get_Token( Next_Token, Next_Value);

               { Optional array index "[" AExpr "]" | }
               if (Next_Token = LeftBracket_tk) then begin

                  Get_Token( Next_Token, Next_Value);
                  AExpr;

                  if (Next_Token <> RightBracket_tk) then begin
                     WriteLn( 'ERROR: "]" missing in array index!');
                     Halt;
                  end; { Error }

                  begin { sem }
                     ExpectedStruct:= ArrayStruct;
                     Emit( Add_mi);
                  end; { sem }

                  Get_Token( Next_Token, Next_Value);
               end; { If array }

               begin { sem }
                  { Structure mismatch ? }
                  if (Struct <> ExpectedStruct) then begin
                     if (Struct = ScalarStruct) then begin
                        WriteLn( 'ERROR: Can not index into a scalar structure.');
                     end
                     else begin
                        WriteLn( 'ERROR: Array index value expected.');
                     end;
                     Halt;
                  end; { Structure mismatch }

                  Emit( Load_mi);
               end; { sem }
            end; { ID }

         Number_tk: begin
               Get_Token( Next_Token, Next_Value);
               begin { sem }
                  Emit2( LoadI_mi, Next_Value.IntValue);
               end; { sem }
            end; { Number }

         Sub_tk: begin { "-" AExpr }
               begin { sem }
                  Emit2( LoadI_mi, 0);
               end; { sem }
               Get_Token( Next_Token, Next_Value);
               AExpr;
               begin { sem }
                  Emit( Sub_mi);
               end; { sem }
            end; { "-" AExpr }

         LeftParenthesis_tk: begin { "(" AExpr ")" }
               Get_Token( Next_Token, Next_Value);
               AExpr;

               if (Next_Token <> RightParenthesis_tk) then begin
                  WriteLn( 'ERROR: ")" missing');
                  Halt;
               end; { Error }

               Get_Token( Next_Token, Next_Value );
            end;  { "(" AExpr ")" }

         { Otherwise it is an unexpected token }
         else begin
            WriteLn( 'ERROR: Factor expected!');
            Halt;
         end;
      end; { Case }
   end; { Factor }

{ ************************************************************************ }

procedure Term;
   var
      Function_Token: tToken;
   begin
      Factor;

      { Optional ( * | div | mod )}
      while Next_Token in [mult_tk, div_tk, mod_tk] do begin

         { Save the function }
         Function_Token:= Next_Token;

         { Get the other operator }
         Get_Token( Next_Token, Next_Value);
         Factor;

         { Perform the function }
         case Function_Token of
            Mult_tk: begin { Sem }
                  Emit( Mul_mi);
               end; { Sem }
            Div_tk:  begin { Sem }
                  Emit( Div_mi);
               end; { Sem }
            Mod_tk: begin { Sem }
                  Emit( Mod_mi);
               end; { Sem }
         end; { case }
      end; { while }
   end; { Term }

{ ************************************************************************ }

procedure AExpr;
   var
      Function_Token: tToken;
   begin
      Term;

      { Optional ( + | - )}
      while Next_Token in [Add_tk, Sub_tk] do begin

         { Save the function }
         Function_Token:= Next_Token;

         { Get the next operator }
         Get_Token( Next_Token, Next_Value);
         Term;

         { Perform the function }
         case Function_Token of
            Add_tk: begin { Sem }
                  Emit( Add_mi);
               end; { Sem }
            Sub_tk: begin { Sem }
                  Emit( Sub_mi);
               end; { Sem }
         end; { case }
      end; { while }
   end; { AExpr }

{ ************************************************************************ }

procedure Expr( var cond: tMachineConditional);

   begin
      AExpr;

      { Optional conditional statements }
      if Next_Token in [LessThan_tk, LessThanOrEqual_tk, Equal_tk,
                           GreaterThan_tk, GreaterThanOrEqual_tk,
                           NotEqual_tk] then begin
         case Next_Token of
            GreaterThan_tk: begin
                  begin { sem }
                     cond:= GreaterThan_mc;
                  end; { sem }
                  Get_Token( Next_Token, Next_Value);
               end;
            GreaterThanOrEqual_tk: begin
                  begin { sem }
                     cond:= GreaterThanOrEqual_mc;
                  end; { sem }
                  Get_Token( Next_Token, Next_Value);
               end;
            Equal_tk: begin
                  begin { sem }
                     cond:= Equal_mc;
                  end; { sem }
                  Get_Token( Next_Token, Next_Value);
               end;
            LessThanOrEqual_tk: begin
                  begin { sem }
                     cond:= LessThanOrEqual_mc;
                  end; { sem }
                  Get_Token( Next_Token, Next_Value);
               end;
            LessThan_tk: begin
                  begin { sem }
                     cond:= LessThan_mc;
                  end; { sem }
                  Get_Token( Next_Token, Next_Value);
               end;
            NotEqual_tk: begin
                  begin { sem }
                     cond:= NotEqual_mc;
                  end; { sem }
                  Get_Token( Next_Token, Next_Value);
               end;
         end; { case }

         AExpr;
      end; { if }
   end; { Expr }

{ ************************************************************************ }

procedure AssignmentStatement;
   { Next_Token must be equal to Identifier_tk }
   var
      name:            tp_Symbol_Table_Entry;
      t:               tTypeAttr;
      struct:          tStructAttr;
      size:            tMachineWord;
      addr:            tMachineAddress;
      ExpectedStruct:  tStructAttr;
   begin
      begin { sem }
         name:= Next_Value.Symbol_Table_Entry;
         if not IsDeclared( name) then begin
            WriteLn( 'ERROR: undeclared identifier');
            halt;
         end;
         SetVariableName( Name^.Image); { in Dump File output }
         Lookup( name, t, struct, size, addr);
         Emit2( LoadI_mi, addr);
         ExpectedStruct:= ScalarStruct;
      end; { sem }

      Get_Token( Next_Token, Next_Value);

      { Optional array subscript }
      if (Next_Token = LeftBracket_tk) then begin
         Get_Token( Next_Token, Next_Value);

         AExpr;

         { Must end with a right bracket }
         if (Next_Token <> RightBracket_tk) then begin
            WriteLn( 'ERROR: "]" must follow an array subscript!');
            halt;
         end; { Error }
         Get_Token( Next_Token, Next_Value);

         begin { sem }
            ExpectedStruct:= ArrayStruct;
            Emit( Add_mi);
         end; { sem }

      end; { Optional array subscript }

      begin { sem }
         { Structure mismatch ? }
         if (Struct <> ExpectedStruct) then begin
            if (Struct = ScalarStruct) then begin
               WriteLn( 'ERROR: Can not index into a scalar structure.');
            end
            else begin
               WriteLn( 'ERROR: Array index value expected.');
            end;
            Halt;
         end; { Structure mismatch }
      end; { sem }

      { Mandatory assignment }
      if (Next_Token <> Assign_tk) then begin
         WriteLn( 'ERROR: Assignment operator expected!');
         halt;
      end; { Error }

      Get_Token( Next_Token, Next_Value);

      AExpr;

      begin { sem }
         Emit( Store_mi);
      end; { sem }
   end; { AssignmentStatement }

{ ************************************************************************ }

procedure IfStatement;
   { Next_Token must be equal to If_tk }
   var
      cond:           tMachineConditional;
      End_If_Label:   tLabel;
      Next_Alt_Label: tLabel;
   begin
      Get_Token( Next_Token, Next_Value);

      Expr( cond);

      begin { sem }
         End_If_Label:= GenLabel;
         Next_Alt_Label:= GenLabel;
         EmitCJmp( Next_Alt_Label, InvertMachineConditional( cond));
      end; { sem }

      { Mandatory Then }
      if (Next_Token <> Then_tk) then begin
         WriteLn( 'ERROR: "THEN" missing from "IF" statement');
         halt;
      end; { Error }

      Get_Token( Next_Token, Next_Value);

      StatementLst;

      begin { sem }
         EmitJmp( End_If_Label);
      end; { sem }

      { Zero or more Elsif statements }
      while (Next_Token = Elsif_tk) do begin
         Get_Token( Next_Token, Next_Value);

         begin { sem }
            SetLabel( Next_Alt_Label);
            Next_Alt_Label:= GenLabel;
         end; { sem }

         Expr( cond);

         begin { sem }
            EmitCJmp( Next_Alt_Label, InvertMachineConditional( cond));
         end; { sem }

         { Mandatory Then }
         if (Next_Token <> Then_tk) then begin
            WriteLn( 'ERROR: "THEN" missing from "ELSIF" statement');
            halt;
         end; { Error }

         Get_Token( Next_Token, Next_Value);

         StatementLst;

         begin { sem }
            EmitJmp( End_If_Label);
         end; { sem }
      end; { Zero or more Elsif }

      { Optional Else }
      if (Next_Token = Else_tk) then begin
         Get_Token( Next_Token, Next_Value);

         begin { sem }
            SetLabel( Next_Alt_Label);
            Next_Alt_Label:= GenLabel;
         end; { sem }

         StatementLst;
      end;

      { Mandatory End }
      if (Next_Token <> End_tk) then begin
         WriteLn( 'ERROR: "END" missing from "IF" statement');
         halt;
      end; { Error }

      Get_Token( Next_Token, Next_Value);

      begin { sem }
         SetLabel( Next_Alt_Label);
         SetLabel( End_If_Label);
      end; { sem }


   end; { IfStatement }

{ ************************************************************************ }

procedure WhileStatement;
   { Next_Token must be equal to While_tk }
   var
      cond:       tMachineConditional;
      Loop_Label: tLabel;
      End_Label:  tLabel;
   begin
      Get_Token( Next_Token, Next_Value);

      begin { sem }
         Loop_Label:= GenLabel;
         End_Label:=  GenLabel;
         SetLabel( Loop_Label);
      end; { sem }

      Expr( cond);

      begin { sem }
         EmitCJmp( End_Label, InvertMachineConditional( cond));
      end; { sem }

      { Mandatory Do }
      if (Next_Token <> Do_tk) then begin
         WriteLn( 'ERROR: "DO" expected after "WHILE"!');
         halt;
      end; { Error }

      Get_Token( Next_Token, Next_Value);

      StatementLst;

      { Mandatory End }
      if (Next_Token <> End_tk) then begin
         WriteLn( 'ERROR: "END" missing for "WHILE" loop!');
         halt;
      end; { Error }

      begin { sem }
         EmitJmp( Loop_Label);
         SetLabel( End_Label);
      end; { sem }

      Get_Token( Next_Token, Next_Value);
   end; { WhileStatement }

{ ************************************************************************ }

procedure Statement;
   begin
      case Next_Token of
         Identifier_tk:  AssignmentStatement;
         If_tk:          IfStatement;
         While_tk:       WhileStatement;

         { It must be one of the above or it is an error }
         else begin
            WriteLn( 'ERROR: A statement must follow a semicolon!');
            halt;
         end;
      end; { case }
   end; { Statement }

{ ************************************************************************ }

procedure StatementLst;
   begin
      { Do we have the start of the first statement ? }
      if Next_Token in [If_tk, While_tk, Identifier_tk] then begin
         Statement;

         while (Next_Token = Semicolon_tk) do begin
            Get_Token( Next_Token, Next_Value);

            Statement;
         end; { while }
      end; { if first statement }

   end; { StatementLst }

{ ************************************************************************ }

procedure IdOrArray( t: tTypeAttr);
   var
      name:   tp_Symbol_Table_Entry;
      struct: tStructAttr;
      size:   tMachineWord;
      addr:   tMachineAddress;
   begin
      { Error if token is not Identifier_tk }
      if (Next_Token <> Identifier_tk) then begin
         WriteLn( 'ERROR: Identifier expected');
         halt;
      end;

      begin { sem }
         name:= Next_Value.Symbol_Table_Entry;
         if IsDeclared( name) then begin
            WriteLn( 'ERROR: duplicate identifier');
            halt;
         end;
         size:= 1;
         struct:= ScalarStruct;
      end; { sem }

      Get_Token( Next_Token, Next_Value);

      { Array ? }
      if (Next_Token = LeftBracket_tk) then begin
         Get_Token( Next_Token, Next_Value);

         { Error if token is not Number_tk }
         if (Next_Token <> Number_tk) then begin
            WriteLn( 'ERROR: Array size expected!');
            halt;
         end;

         begin { sem }
            struct:= ArrayStruct;
            size:= Next_Value.IntValue;
         end; { sem }

         Get_Token( Next_Token, Next_Value);

         { Error if token is not RightParenthesis_tk }
         if (Next_Token <> RightBracket_tk) then begin
            WriteLn( 'ERROR: After an array size, "]" is expected!');
            halt;
         end;

         Get_Token( Next_Token, Next_Value);
      end; { if Array }

      begin { sem }
         addr:= ReserveDataSpace( size);
         NewID( name, t, struct, size, addr);
      end; { sem }

   end; { IDOrArray }

{ ************************************************************************ }

procedure VariableDcl( t: tTypeAttr);
   { Reads a single integer declaration statement }
   { Should only be called when Next_Token = Integer_Tk }
   begin
      { read the list of declarations until a comma does not follow one }
      repeat
         { Next_Token can only equal an Integer_tk or a Comma_tk }
         { Either way, move past it. }
         Get_Token( Next_Token, Next_Value);

         IdOrArray( t);
      until (Next_Token <> Comma_tk);

      if (Next_Token <> Semicolon_tk) then begin
         WriteLn(
            'ERROR: Variable declarations should terminate with a semicolon!');
         halt;
      end;

      Get_Token( Next_Token, Next_Value);

   end; { VariableDcl }

{ ************************************************************************ }

procedure VariableDclLst;
   { Reads any number of variable declarations }
   var
      t:  tTypeAttr;
   begin
      while (Next_Token = Integer_tk) do begin

         begin { sem }
            t:= IntegerType;
         end; { sem }

         VariableDcl( t);
      end;
   end; { VariableDclLst }

{ ************************************************************************ }

procedure ProgramDcl;
   begin
      { Error if token is not Program_tk }
      if (Next_Token <> Program_tk) then begin
         WriteLn( 'ERROR: Program must start with "PROGRAM" keyword!');
         halt;
      end;

      Get_Token( Next_Token, Next_Value);

      { Error if token is not Identifier_tk }
      if (Next_Token <> Identifier_tk) then begin
         WriteLn( 'ERROR: Name is missing in the "PROGRAM" declaration!');
         halt;
      end;

      begin { sem }
         { Set the ID as the ProgramName }
         NewID( Next_Value.Symbol_Table_Entry,
                ProgramNameType, ScalarStruct, 0, 0);
      end; { sem }

      Get_Token( Next_Token, Next_Value);

      { Error if token is not Semicolon_tk }
      if (Next_Token <> Semicolon_tk) then begin
         WriteLn( 'ERROR: Program declaration must end in a semicolon!');
         halt;
      end;

      Get_Token( Next_Token, Next_Value);


      { Process all variable declarations }
      VariableDclLst;

      { Error if token is not Begin_tk }
      if (Next_Token <> Begin_tk) then begin
         WriteLn( 'ERROR: "BEGIN" expected, but not found!');
         halt;
      end;

      Get_Token( Next_Token, Next_Value);

      StatementLst;

      { Error if token is not End_tk }
      if (Next_Token <> End_tk) then begin
         WriteLn( 'ERROR: "END" expected!');
         halt;
      end;

      Get_Token( Next_Token, Next_Value);

      { Error if token is not Period_tk }
      if (Next_Token <> Period_tk) then begin
         WriteLn( 'ERROR: "." missing from "END."!');
         halt;
      end;

      begin { sem }
         Emit( Svc_mi);
      end; { sem }
   end; { ProgramDcl }

{ ************************************************************************ }

var
   Count: integer;
begin
   Open_Source( 'MyPrg.cmp');
   Get_Token( Next_Token, Next_Value);
   ProgramDcl;
   Close_Source;

   RunProgram;
   DumpMachineInstructionMemory;
   DumpMachineDataMemory;
   DumpSymbolTable;
end.
