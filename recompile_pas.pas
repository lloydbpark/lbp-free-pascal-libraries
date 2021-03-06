{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

recompile_pas program.  This porgram gathers a list of pascal source code files
(.pas and .pp) in the current folder and all subfolders of the current folder.
It then attempts to compile is source file.  Any that fail are tried again in a 
second, third, and fourth pass.  This is inefficient, but much easier than 
parsing each file looking for 'uses' clauses and building a dependency tree.

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

program recompile_pas;

{$include lbp_standard_modes.inc}

uses
   sysutils,  // functions to traverse a file directory
   process,   // Execute a child program
   classes;   // tFPList


// =======================================================================
// = Global functions and variables
// =======================================================================

var
   MaxAttempts:  integer  = 4; // The maximum attempts to compile.
   ShowProgress: boolean  = true;
   ShowFailed:   boolean  = true;


// ***********************************************************************
// * CreateListOfFiles() - Returns an tStringList of tCode
// ***********************************************************************

function GetPathStrings(): tStringList;
   var
      {$ifdef UNIX}
         PathSeparator: char = ':';
      {$endif}
      {$ifdef WINDOWS}
         PathSeparator: char = ';';
      {$endif}
      PathStrings: tStringList;
      SearchPath:  string;
      i:           integer; 
      L:           integer; // length of S
      iStart:      integer;
      S:           string;
      C:           char;
   begin
      PathStrings:= tStringList.Create;
      SearchPath:= GetEnvironmentVariable( 'PATH');
       L:= Length( SearchPath);
      iStart:= 1;
      S:= '';
      i:= 1;
      while( i <= L) do begin
         C:= SearchPath[ i];
         if( C = PathSeparator ) then begin
            // Add S to PathStrings;
            if( i > iStart) then begin
               if( S[ Length(s)] <> DirectorySeparator) then begin
                  S:= S + DirectorySeparator;
               end;
               PathStrings.Add( S);
            end;
            iStart:= i + 1;
            S:= '';
         end else begin
            S:= S + C;
         end;
         Inc( i);
      end;

      if( i > iStart) then begin
         if( S[ Length(s)] <> DirectorySeparator) then begin
            S:= S + DirectorySeparator;
         end;
         PathStrings.Add( S);
      end;
      result:= PathStrings;
   end; // GetPathStrings();
      

// ***********************************************************************
// * GetFPC() - Returns the full path to the FPC compiler
// ***********************************************************************

function GetFPC(): string;
   var
      SearchPath: tStringList;
      S:          string;
      i:          integer;
      L:          integer;
      {$ifdef UNIX}
         FPC:        string = 'fpc';
      {$endif}
      {$ifdef WINDOWS}
         FPC:        string = 'fpc.exe';
      {$endif}
   begin
      SearchPath:= GetPathStrings;
      L:= SearchPath.Count - 1;
      for i:= 0 to L do begin
         S:= SearchPath.Strings[ i] + FPC;
         if( FileExists( S)) then begin
            result:= S;
            SearchPath.Destroy;
            exit;
         end;
      end;

      raise Exception.Create( FPC + ' was not found in the search path!');
   end; // GetFPC()


// ***********************************************************************
// * CreateListOfFiles() - Returns an tStringList of Pascal source code files
// ***********************************************************************

function CreateListOfFiles( Path: string = '.'): tStringList;
   var
      CurrentDir: String;
      FileList:   tStringList;

   // --------------------------------------------------------------------
   // - RecursiveLOF()
   // --------------------------------------------------------------------

   procedure RecursiveLOF( Path: String);
      var
         FileInfo:   TSearchRec;
         L:          integer; // The length of the file name
         FolderList: tStringList;
         FolderName: String;
      begin
         FolderList:= tStringList.Create();
         chdir( Path);
         if( FindFirst ('*', faAnyFile and faDirectory, FileInfo) = 0) then Repeat
            if( (FileInfo.Attr and faDirectory) = faDirectory) then begin
               if( (FileInfo.Name = '.') or (FileInfo.Name = '..')) then continue;
               FolderName:= Path + DirectorySeparator + FileInfo.Name;
               FolderList.Add( FolderName);
            end else begin
               // Handle a standard file - Does it end with a *.pas or *.pp?
               L:= length( FileInfo.Name);
               if( (pos( '.pas', FileInfo.Name) = (L - 3)) or
                   (pos( '.pp',  FileInfo.Name) = (L - 2))) then begin
                  FileList.Add( Path + DirectorySeparator + FileInfo.Name);
               end; // if it ends in .pas or .pp
            end;
         Until FindNext( FileInfo) <> 0;
         FindClose( FileInfo);

         // Now process the list of subfolders.  We have to do it this way because
         //    Find() and FindNext() can not be called recursively.
         for FolderName in FolderList do RecursiveLOF( FolderName);
         FolderList.Clear;
         FolderList.Destroy;
      end; // RecursiveLOF()

   // --------------------------------------------------------------------

   begin
      FileList:= tStringList.Create;
      result:= FileList;
      GetDir( 0, CurrentDir);

      RecursiveLOF( CurrentDir);
      ChDir( CurrentDir);
   end; // CreateListOfFiles()


// ************************************************************************
// * RecompileSub() - Recompile every file in PasFiles.  On return PasFiles
// *                  contains only the files wich failed to compile.
// ************************************************************************

procedure RecompileSub(  var PasFiles: tStringList; FPC: string);
   var
      FailedFiles:  tStringList;
      i:            integer;
      L:            integer;
      Folder:       string;
      Options:      array[ 1..1] of string;
      OutputStr:    string;
      ExitStatus:   integer;
      RunResult:    integer;      
   begin
      FailedFiles:= tStringList.Create();
      
   // writeLn;
   // writeln;   
      L:= PasFiles.Count - 1;
      for i:= 0 to L do begin
         Folder:= ExtractFilePath( PasFiles.Strings[ i]);
         Options[ 1]:= ExtractFileName( PasFiles.Strings[ i]);
         
         RunResult:= RunCommandInDir( Folder, FPC, Options, OutputStr, ExitStatus);
         if( (RunResult = 0) and (ExitStatus = 0)) then begin
            if( ShowProgress) then writeln( 'OK:      ', PasFiles.Strings[ i]);
         end else begin
            if( ShowProgress) then writeln( 'Failed:  ', PasFiles.Strings[ i]);
            FailedFiles.Add( PasFiles.Strings[ i]);
         end;
         
      end;
      
      PasFiles.Destroy;
      PasFiles:= FailedFiles;
   end; // RecompileSub()

   
// ************************************************************************
// * Recompile() - Recompile all pascal files found in the current folder's
//                 subtree.
// ************************************************************************

procedure Recompile();
   var
      PasFiles:  tStringList;  // List of source code files
      FPC:       string;       // Full path of the compiler executeable
      PassCount: integer = 0;
      i:         integer;
   begin
      PasFiles:= CreateListOfFiles();
      FPC:= GetFPC;
   
      while( (PassCount < MaxAttempts) and (PasFiles.Count > 0)) do begin
         RecompileSub( PasFiles, FPC);
         inc( PassCount);
      end;
   
      if( ShowFailed) then begin
         if( PasFiles.Count > 0) then begin
           writeln();
           writeln();
           writeln( 'The following files failed to compile!');
           writeln();
         end;
         for i:= 0 to PasFiles.Count - 1 do begin
            writeln( PasFiles.Strings[ i]);
         end;
      end; // If ShowFailed
      PasFiles.Destroy;
   end; // Recompile()


// ************************************************************************
// * main()
// ************************************************************************

begin
   Recompile();
end.  // recompile_pas
