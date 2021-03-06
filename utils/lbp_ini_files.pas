{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Reads and writes .ini file data.

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

// Much of the code in this unit duplicates built in Free Pascal libraries.
// Look into making this unit a wrapper around that.

unit lbp_ini_files;

// ************************************************************************
// * Routines to read and write to an .ini file
// ************************************************************************


interface

{$include lbp_standard_modes.inc}
{$I-}              // Turn off I/0 checking


// SysUtils for Exceptions
// Linux for BaseName()
uses
{$ifndef WINDOWS}
   BaseUnix,   // fpstat();
   UnixUtil,   // BaseName();
{$endif}
   lbp_argv,
   lbp_utils,    // StripSpaces()
   lbp_types,    // KSUException
   lbp_vararray,
   lbp_lists,
   Strings,
   SysUtils;   // FileExists(), FileAge(), Exception, ExtractFileName()

type

IniFileException = class( lbp_exception);
IniProcedure     = procedure();

IniFileObj = class // A class is always a pointer
   public
      FileName:           String; // The INI file name
   private
      Dirty:              boolean;
      CaseSensitive:      boolean;
      Sections:           DoubleLinkedList;  // A list of section lists
      CurrentSectionList: DoubleLinkedList;  // A list of items in the
                                             //    current section.
      CurrentLine:        StringPtr;
      SettingStr:         String;
      ValueStr:           String;
      LastMTime:          longint;    // Date when the file was last modified.
   public
      ProcStack:          DoubleLinkedList;  // A list of procedures to call
                                             // when ReadIfChanged is called
      constructor Open( iFileName: String; iCaseSensitive: boolean);
      constructor Open( iFileName: String);  // Opens FileName and reads it
                               // into buffer.  The file is then closed!
      destructor  Close();    // Opens File_Name and writes buffer into it.
      procedure   Read();     // Read the file and store the variables.
      function    ReadIfChanged(): boolean;
      procedure   Write();    // Write the internal representation to the file.
      procedure   RewindSections();
      function    NextSection(): String;
      function    CurrentSection(): String;
      procedure   GotoSection( Name: String);
      procedure   RewindVariables();
      function    NextVariable(): boolean;
      function    CurrentName(): String;
      function    CurrentValue(): String;
      function    ReadVariable( const VarName: String): String;
      function    ReadVariable( const SectionName: String;
                                const VarName: String): String;
      function    ReadVariable( const SectionName:  String;
                                const VarName:      String;
                                const DefaultValue: String): String;
      function    ReadVariable( const SectionName:  String;
                                const VarName:      String;
                                const DefaultValue: boolean): boolean;
      function    ReadVariable( const SectionName:  String;
                                const VarName:      String;
                                const DefaultValue: int32): int32;
      function    ReadVariable( const SectionName:  String;
                                const VarName:      String;
                                const DefaultValue: extended): extended;
      procedure   ReadArray(    const VarName:      String;
                                var   Values:       StringArray);
      procedure   ReadArray(    const SectionName:  String;
                                const VarName:      String;
                                var   Values:       StringArray);
      procedure   SetVariable(  const VarName:      String;
                                const VarValue:     String);
      procedure   SetVariable(  const SectionName:  String;
                                const VarName:      String;
                                const VarValue:     String);
      procedure   RemoveVariable();
      procedure   RemoveVariable( const VarName: String);
      procedure   RemoveVariable( const SectionName: String;
                                  const VarName: String);
      procedure   RunIniProcedures();
   private
      procedure   SplitLine();
      procedure   EmptyQueues();
   end; // INIFileObj

var
   Ini:                  IniFileObj = nil;

const
   DefaultSectionName:   String = 'DefaultSection';

// ************************************************************************

implementation

var
   InInitialization:     Boolean = false;


// ************************************************************************
// * Open() - CONSTRUCTOR - Open and read the file
// ************************************************************************

constructor IniFileObj.Open( iFileName: string);
   begin
      FileName:=       iFileName;
      CaseSensitive:=  false;
      Dirty:=          false;
      ProcStack:=      DoubleLinkedList.Create();

      read();
   end; // Open()


// ------------------------------------------------------------------------

constructor IniFileObj.Open( iFileName: string; iCaseSensitive: boolean);
   begin
      FileName:=       iFileName;
      CaseSensitive:=  iCaseSensitive;
      Dirty:=          false;
      ProcStack:=      DoubleLinkedList.Create();
      Read();
   end; // Open()


// ************************************************************************
// * Close() - DESTRUCTOR - Does not Write changes back to the File!
// *                        If you want to do that, call Write() first.
// ************************************************************************

destructor IniFileObj.Close();
   begin

      EmptyQueues();

      ProcStack.RemoveAll();
      ProcStack.Destroy();

      FileName:= '';
   end; // Close()


// ************************************************************************
// * ReadIfChanged()  - Call read if the INI file has chaned since we last
// *                    read or wrote it.  Returns true if the file had
// *                    changed.
// ************************************************************************

function IniFileObj.ReadIfChanged(): boolean;
   var
      NewMTime: int32;
   begin
{$ifndef win32}
      NewMTime:= FileAge( FileName);
      if( NewMTime <> LastMTime) then begin
         LastMTime:= NewMTime;
//         writeln( 'IniFileObj.ReadIfChanged():  ', FileName,
//                ' is being read because it changed');
         Read();
         RunINIProcedures();
         ReadIfChanged:= true;
      end else begin
{$endif}
         ReadIfChanged:= false;
{$ifndef win32}
      end;
{$endif}
   end; // ReadIfChanged();


// ************************************************************************
// * Read()  - Read the text file and store the variables in the
// *           internal structures.
// ************************************************************************

procedure IniFileObj.Read();
   var
      Temp:       String;
      InFile:     Text;
      TempLength: integer;
      QdString:   StringPtr;

   begin
      EmptyQueues();

      // Initialize the global variables
      Sections:=           DoubleLinkedList.Create( 'Sections');
      CurrentSectionList:= nil;
      CurrentLine:=        nil;
      Dirty:=              false;

      if( InInitialization and (not FileExists( FileName))) then begin
         InInitialization:= false;
         exit;
      end;

      LastMTime:= 0;

      assign( InFile, FileName);
      reset( InFile);


      // Add the default section
      CurrentSectionList:= DoubleLinkedList.Create( DefaultSectionName);
      Sections.Enqueue( CurrentSectionList);

     // For each line of the input file
      while( (IOResult = 0) and (not eof( InFile))) do begin
         readln( InFile, Temp);
         StripSpaces( Temp);
         // Is this a section heading?
         TempLength:= Length( Temp);
         if( (TempLength > 0) and (Temp[ 1] = '[') and
             (Temp[ TempLength] = ']')) then begin
            Temp:= copy( Temp, 2, TempLength - 2);
            CurrentSectionList:= DoubleLinkedList.Create( Temp);
            Sections.Enqueue( CurrentSectionList);

         end else begin
            // It is an item in a section
            new( QdString);
            QdString^:= Temp;
            CurrentSectionList.Enqueue( QdString);
         end;
      end; // for each line

      System.close( InFile);

      LastMTime:= FileAge( FileName);

      IOResult; // Read and discard the last IO Error if any.
   end; // Read()


// ************************************************************************
// * Write()  - Write the internal representation back to the file
// ************************************************************************

procedure IniFileObj.Write();
   var
      Temp:        StringPtr;
      OutFile:        Text;

   begin
      if( Dirty) then begin
         assign( OutFile, FileName);
         rewrite( OutFile);

         // Output the data - For each section
         CurrentSectionList:= DoubleLinkedList( Sections.GetFirst());
         while( CurrentSectionList <> nil) do begin
            if( CurrentSectionList.Name <> DefaultSectionName) then begin
                  writeln( OutFile, '[', CurrentSectionList.Name, ']');
            end;

            // Output the lines for this section
            Temp:= StringPtr( CurrentSectionList.GetFirst());
            while( Temp <> nil) do begin
               writeln( OutFile, Temp^);
               Temp:= StringPtr( CurrentSectionList.GetNext());
            end; //while

            CurrentSectionList:= DoubleLinkedList( Sections.GetNext());
         end; // for each section

         System.close( OutFile);
         LastMTime:= FileAge( FileName);
      end; // if Dirty

      Dirty:= false;
      IOResult; // Read and discard the last IO Error if any.
   end; // Write()


// ************************************************************************
// * RewindSections()  - Set up so the next NextSection() call
// *                     will get the first section.
// ************************************************************************

procedure IniFileObj.RewindSections();
   begin
      CurrentSectionList:= nil;
      CurrentLine:=        nil;
      SettingStr:=         '';
      ValueStr:=           '';
   end; // RewindSections()


// ************************************************************************
// * NextSection() -  Returns the name of the next section.
// ************************************************************************

function IniFileObj.NextSection(): String;
   begin
      CurrentLine:=        nil;
      SettingStr:=         '';
      ValueStr:=           '';

      if( Sections.Empty()) then begin
         NextSection:= '';
      end;

      if( CurrentSectionList = nil) then begin
         CurrentSectionList:= DoubleLinkedList( Sections.GetFirst());
      end else begin
         CurrentSectionList:= DoubleLinkedList( Sections.GetNext());
      end;

      if( CurrentSectionList = nil) then begin
         NextSection:= '';
      end else begin
         NextSection:= CurrentSectionList.Name;
      end;

   end; // NextSection()


// ************************************************************************
// * CurrentSection() -  Returns the name of the current section.
// ************************************************************************

function IniFileObj.CurrentSection(): String;
   begin

      if( CurrentSectionList = nil) then begin
         CurrentSection:= '';
      end else begin
         CurrentSection:= CurrentSectionList.Name;
      end;
   end; // CurrentSection()


// ************************************************************************
// * GotoSection() -  Goto the named section.
// ************************************************************************

procedure IniFileObj.GotoSection( Name: String);
   var
      LCSectionName: String;
      LCInputName:   String;
   begin
      // Rewind the variables;
      CurrentLine:= nil;
      SettingStr:=  '';
      ValueStr:=    '';

      LCInputName:= lowercase( Name);

      // Are we already in the proper section?
      if( CurrentSectionList <> nil) then begin
         if( CaseSensitive) then begin
            if( CurrentSectionList.Name = Name) then begin
               Exit;
            end;
         end else begin
            LCSectionName:= LowerCase( CurrentSectionList.Name);
            LCInputName:= LowerCase( Name);
            if( LCSectionName = LCInputName) then begin
               Exit;
            end;
         end // else
      end; // if CurrentSectionList is valid

      // Search until we find the name or run out of sections
      CurrentSectionList:= DoubleLinkedList( Sections.GetFirst());
      while( CurrentSectionList <> nil) do begin
         if( CaseSensitive) then begin
            if( CurrentSectionList.Name = Name) then begin
               break;
            end;
         end else begin
            LCSectionName:= LowerCase( CurrentSectionList.Name);
            if( LCSectionName = LCInputName) then begin
               break;
            end;
         end;

         CurrentSectionList:= DoubleLinkedList( Sections.GetNext());
      end; // while

      if( CurrentSectionList = nil) then begin
         raise IniFIleException.Create( 'INI Section heading [' + Name +
                                        '] not found!');
      end;
   end; // GotoSection()


// ************************************************************************
// * RewindVariables()  - Set up so the next NextVariable() call
// *                      will get the first variable in the current
// *                      section.
// ************************************************************************

procedure IniFileObj.RewindVariables();
   begin
      CurrentLine:= nil;
      SettingStr:=  '';
      ValueStr:=    '';
   end; // RewindVariables()


// ************************************************************************
// * NextVariable() -  Returns the next line which contains a
// *                   variable in the current section.  Returns null
// *                   if no valid variables remain.
// ************************************************************************

function IniFileObj.NextVariable(): boolean;
   begin
      SettingStr:=  '';
      ValueStr:=    '';

      if( CurrentSectionList = nil) then begin
         NextVariable:= false;
         Exit;
      end;

      while( true) do begin
         if( CurrentLine = nil) then begin
            CurrentLine:= StringPtr( CurrentSectionList.GetFirst());
         end else begin
            CurrentLine:= StringPtr( CurrentSectionList.GetNext());
         end;

         if( CurrentLine = nil) then begin
            NextVariable:= false;
            Exit;
         end else begin
            SplitLine();
            if( Length( SettingStr) > 0) then begin
               NextVariable:= true;
               Exit;
            end;
         end;
      end; // while Forever
   end; // NextVariable()


// ************************************************************************
// * CurrentName() -  Returns the name of the current setting.
// ************************************************************************

function IniFileObj.CurrentName(): String;
   begin
      if( CurrentLine = nil) then begin
         CurrentName:= '';
      end else begin
         CurrentName:= SettingStr;
      end;
   end; // CurrentName()


// ************************************************************************
// * CurrentValue() -  Returns the value of the current setting.
// ************************************************************************

function IniFileObj.CurrentValue(): String;
   begin
      if( CurrentLine = nil) then begin
         CurrentValue:= '';
      end else begin
         CurrentValue:= ValueStr;
      end;
   end; // CurrentName()


// ************************************************************************
// * ReadVariable() - Searches for the named variable in the current
// *                  section and returns its value.  Throws
// *                  INIException if not found.
// ************************************************************************

function IniFileObj.ReadVariable( const VarName: String): String;
   var
      LCVarName:     String;
      LCSettingStr:  String;
   begin
      if( CurrentSectionList = nil) then begin
         raise IniFileException.Create( 'Current INI file section is not set!');
      end;

      // Do our case conversion for non case sensitive compares
      if( not CaseSensitive) then begin
         LCVarName:= lowercase( VarName);
      end;

      CurrentLine:= nil; // rewind
      while( NextVariable()) do begin
         if( CaseSensitive) then begin
            if( SettingStr = VarName) then begin
               ReadVariable:= ValueStr;
               Exit;
            end;
         end else begin
            LCSettingStr:= lowercase( SettingStr);

            if( LCSettingStr = LCVarName) then begin
               ReadVariable:= ValueStr;
               Exit;
            end;
         end; // if
      end; // while

      raise IniFileException.Create( VarName + ' in [' +
                 CurrentSectionList.Name + '] was not found!');
   end; // ReadVariable()


// ------------------------------------------------------------------------
// - ReadVariable() - Search for the named variable in the named section
// ------------------------------------------------------------------------

function IniFileObj.ReadVariable( const SectionName:  String;
                                  const VarName:      String): String;
   begin
      GotoSection( SectionName);
      ReadVariable:= ReadVariable( VarName);
   end; // ReadVariable()


// ------------------------------------------------------------------------
// - ReadVariable() - Search for the named variable in the named section
//                    and return a default value if not found.
// ------------------------------------------------------------------------

function IniFileObj.ReadVariable( const SectionName:  String;
                                  const VarName:      String;
                                  const DefaultValue: String): String;
   begin
      try
         ReadVariable:= ReadVariable( SectionName, VarName);
      except
         on Exception do begin
            ReadVariable:= DefaultValue;
         end;
      end;
   end; // ReadVariable()


// ------------------------------------------------------------------------

function IniFileObj.ReadVariable( const SectionName:  String;
                                  const VarName:      String;
                                  const DefaultValue: boolean): boolean;
   var
      Temp: String;
   begin
      try
         Temp:= ReadVariable( SectionName, VarName);
         if( Length( Temp) > 0) then begin
            if( Temp[ 1] in ['T', 't', 'Y', 'y', '0', 'o', '1']) then begin
               ReadVariable:= true;
            end else begin
               ReadVariable:= false;
            end;
         end else begin
            ReadVariable:= DefaultValue;
         end;
      except
         on Exception do begin
            ReadVariable:= DefaultValue;
         end;
      end;
   end; // ReadVariable()


// ------------------------------------------------------------------------
// - ReadVariable() - Search for the named variable in the named section
//                    and return a default value if not found.
//                    This one is for 'long' integers.
// ------------------------------------------------------------------------

function IniFileObj.ReadVariable( const SectionName:  String;
                                  const VarName:      String;
                                  const DefaultValue: Int32): Int32;
   var
      S: String;
      X: Int32;
      ErrorCode: integer;
   begin
      try
         S:= ReadVariable( SectionName, VarName);
         val( S, X, ErrorCode);
         if( ErrorCode <> 0) then begin
            ReadVariable:= DefaultValue;
         end else begin
            ReadVariable:= X;
         end;
      except
         on Exception do begin
            ReadVariable:= DefaultValue;
         end;
      end;
   end; // ReadVariable()


// ------------------------------------------------------------------------
// - ReadVariable() - Search for the named variable in the named section
//                    and return a default value if not found.
//                    This one is for 'double' integers.
// ------------------------------------------------------------------------

function IniFileObj.ReadVariable( const SectionName:  String;
                                  const VarName:      String;
                                  const DefaultValue: extended): extended;
   var
      S: String;
      X: extended;
      ErrorCode: word;
   begin
      try
         S:= ReadVariable( SectionName, VarName);
         val( S, X, ErrorCode);
         if( ErrorCode <> 0) then begin
            ReadVariable:= DefaultValue;
         end else begin
            ReadVariable:= X;
         end;
      except
         on Exception do begin
            ReadVariable:= DefaultValue;
         end;
      end;
   end; // ReadVariable()


// ************************************************************************
// * ReadArray() - Searches for the named variable which can appear
// *               multiple times in the file.  The values found
// *               are returned as a DoubleLinkedList of strings.
// ************************************************************************

procedure IniFileObj.ReadArray( const VarName:      String;
                                var   Values: StringArray);
   var
      i:           integer;
      Found:       boolean;
   begin
      if( CurrentSectionList = nil) then begin
         raise IniFileException.Create( 'Current INI file section is not set!');
      end;

      SetLength( Values, 0);
      i:= 0;

      // Retreive the value, if any
      CurrentLine:= nil; // Rewind
      while( NextVariable()) do begin
         if( CaseSensitive) then begin
            Found:= (SettingStr = VarName);
         end else begin
            Found:= (lowercase(SettingStr) = lowercase( VarName));
         end; // if
         if( Found) then begin
            SetLength( Values, i + 1);
            Values[ i]:= ValueStr;
            inc( i);
         end;
      end; // while
   end; // ReadArray()


// ------------------------------------------------------------------------
// - ReadArray() - Search for the named variable in the named section
// ------------------------------------------------------------------------

procedure IniFileObj.ReadArray( const SectionName:  String;
                                const VarName:      String;
                                var   Values: StringArray);
   begin
      GotoSection( SectionName);
      ReadArray( VarName, Values);
   end; // ReadArray()


// ************************************************************************
// * SetVariable() - Searches for the named variable in the current
// *                 section and sets its value.  If not found, it
// *                 inserts a new VariableName = Variable pair.
// ************************************************************************

procedure IniFileObj.SetVariable( const VarName: String;
                                  const VarValue: String);
   var
      NewLine:   StringPtr;
      Found:     boolean;
   begin
      if( CurrentSectionList = nil) then begin
         raise IniFileException.Create( 'Current INI file section is not set!')
      end;

      new( NewLine);
      NewLine^:= VarName + '=' + VarValue;
      Found:= false;

      // Search for the named setting.
      CurrentLine:= nil;
      while( (not Found) and (NextVariable())) do begin
         if( CaseSensitive) then begin
            Found:= (SettingStr = VarName);
         end else begin
            Found:= (lowercase( SettingStr) = lowercase( VarName));
         end; // if
      end; // while

      Dirty:= true;
      if( Found) then begin

         dispose( CurrentLine);
         CurrentLine:= NewLine;
         SplitLine();
         CurrentSectionList.Replace( CurrentLine);
      end else begin
         CurrentSectionList.Enqueue( NewLine);
      end;

   end; // SetVariable()


// ------------------------------------------------------------------
// - SetVariable() - Search for the named variable in the named section
// ------------------------------------------------------------------

procedure IniFileObj.SetVariable( const SectionName:  String;
                                  const VarName:      String;
                                  const VarValue:     String);
   begin
      try
         GotoSection( SectionName);
      except
         on IniFileException do begin
            CurrentSectionList:= DoubleLinkedList.Create( SectionName);
            Sections.Enqueue( CurrentSectionList);
         end;
      end; // try/except

      SetVariable( VarName, VarValue);
   end; // ReadVariable()


// ************************************************************************
// * RemoveVariable()  - Removes the current variable.  If the
// *                     section is empty of valid variables, remove
// *                     it too.
// ************************************************************************

procedure IniFileObj.RemoveVariable();
   var
      Temp:  StringPtr;
   begin
      if( CurrentLine = nil) then begin
         raise INIFileException.Create( 'INIFile.RemoveVariable():  ' +
                           'You have not selected a variable for deletion!');
      end;

      CurrentSectionList.Remove();

      // Do we need to delete the section also?
      RewindVariables();
      if( not NextVariable()) then begin

         // First pop everything off the list (comments, if they exist)
         while( not CurrentSectionList.Empty()) do begin
            Temp:= StringPtr( CurrentSectionList.Pop());
            dispose( Temp);
         end;

         Sections.Remove();
         RewindSections();
      end; // if we need to delete the whole section

   end; // RemoveVariable();


// ------------------------------------------------------------------------
// - RemoveVariable() - Remove the named variable from the current
// -                    section.
// ------------------------------------------------------------------------

procedure IniFileObj.RemoveVariable( const VarName: String);
   begin
      ReadVariable( VarName);
      RemoveVariable();
   end; // RemoveVariable();


// ------------------------------------------------------------------------
// - RemoveVariable() - Remove the named variable from the current
// -                    section.
// ------------------------------------------------------------------------

procedure IniFileObj.RemoveVariable( const SectionName: String;
                                     const VarName: String);
   begin
      GotoSection( SectionName);
      ReadVariable( VarName);
      RemoveVariable();
   end; // RemoveVariable();


// ******************************************************************
// * RunINIProcedures() - Run all the procedures in ProcStack
// ******************************************************************

procedure IniFileObj.RunINIProcedures();
   var
      P: IniProcedure;
   begin
      P:= IniProcedure(ProcStack.GetFirst());
      while( P <> nil) do begin
         P();
         P:= IniProcedure( ProcStack.GetNext());
      end;
   end; // RunINIProcedures();


// ******************************************************************
// * SplitLine() - Splits CurrentLine into SettingStr, ValueStr pair
// *               NOTE!  CurrentLine can NOT be nil!
// ******************************************************************

procedure IniFileObj.SplitLine();
   var
      eq: integer;
   begin
      eq:= pos( '=', CurrentLine^);
      if( CurrentLine <> nil) then begin
         eq:= pos( '=', CurrentLine^);
         if( eq <> 0) then begin
            SettingStr:= copy( CurrentLine^, 1, eq - 1);
            ValueStr:= copy( CurrentLine^, eq + 1, Length( CurrentLine^) - eq);
            Exit
         end; // if
      end; // if

      ValueStr:= '';
      SettingStr:= '';
   end; // SplitLine()


// ************************************************************************
// * EmptyQueues() - Empty all the queues and deallocate memeory used
// *                 by this object.
// ************************************************************************

procedure IniFileObj.EmptyQueues();
   var
      Temp: StringPtr;
   begin
      // Only clear them if they have been initialized
      if( Sections <> nil) then begin
         while( not Sections.Empty()) do begin
            CurrentSectionList:= DoubleLinkedList( Sections.Dequeue());
            while( not CurrentSectionList.Empty()) do begin
               Temp:= StringPtr(CurrentSectionList.Dequeue());
               dispose( Temp);
            end;
            CurrentSectionList.Destroy(); // Dispose
            CurrentSectionList:= nil;
         end;
         Sections.Destroy(); // Dispose
         Sections:= nil;
      end; // if Sections <> nil

      CurrentSectionList:= nil;

      // This insures the AnsiString constructs are removed from the heap.
      CurrentLine:= nil;
      SettingStr:=  '';
      ValueStr:=    '';
   end; // EmptyQueues();


// *************************************************************************

end. // lbp_ini_files
