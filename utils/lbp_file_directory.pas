{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

a class to handle some UNIX file information.

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

//{$define FPLSTAT_FIX}

unit lbp_file_directory;
// Creates a balanced binary tree of pointers.  Makes use of a comparison

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

interface

uses
   {$ifdef FPLSTAT_FIX}
      {$WARNING FPLSTAT_FIX is active}
      syscall,
   {$endif}
   BaseUnix,
   lbp_types;      // tStringObj


// *************************************************************************

type
   FileInfoException = class( lbp_exception);


// *************************************************************************

type

   tFileInfoClass = class
      private
         DirName:       string;
         UnixDirectory: pDir;
         UnixDirEnt:    PDirent;
         UnixStat:      Stat;
         StatOK:        boolean;
      public
         constructor   Create( DirectoryName: string);
         destructor    Destroy(); override;
         function      Next(): boolean;
         function      Name:  string;
         function      FullName: string;
         function      INode: ino_t;
         function      Mode:  mode_t;
         function      UID:   uid_t;
         function      GID:   gid_t;
         function      IsSocket():          boolean;
         function      IsSymbolicLink():    boolean;
         function      IsRegularFile():     boolean;
         function      IsBlockDevice():     boolean;
         function      IsDirectory():       boolean;
         function      IsCharacterDevice(): boolean;
         function      IsFIFO():            boolean;
      private
         procedure myDirOpen();
      public
         property  Directory: string read DirName;
      end; // tFileInfoClass


// *************************************************************************

{$ifdef FPLSTAT_FIX}
   function fpLstat( path: pchar; Info: pstat): cint;
   function fplstat( filename: ansistring; Info: pstat): cint;
{$endif}

implementation

{$ifdef FPLSTAT_FIX}
   function fpLstat( path: pchar; Info: pstat): cint;
      begin
         fpLStat:=do_syscall( syscall_nr_lstat64,
                              TSysParam( path), TSysParam( info));
      end;

   function fplstat( filename: ansistring; Info: pstat): cint;
      begin
         fpLStat:=do_syscall( syscall_nr_lstat64,
                              TSysParam( pchar( filename)), TSysParam( info));
      end;
{$endif}



// =========================================================================
// = tFileInfoClass
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tFileInfoClass.Create( DirectoryName: string);
   begin
      inherited Create();
      DirName:= DirectoryName;
      UnixDirectory:= nil;
      UnixDirEnt:= nil;
      StatOK:= false;
   end; //constructor


// *************************************************************************
// * Destory() - Destructor
// *************************************************************************

destructor  tFileInfoClass.Destroy();
   begin
      if( UnixDirectory <> nil) then begin
         fpCloseDir( UnixDirectory^);
      end;
      inherited Destroy;
   end; // Destructor


// *************************************************************************
// * Next() - Attempt to read information about the next file name in the
// *          directory.
// *************************************************************************

function tFileInfoClass.Next(): boolean;
   begin
      // Try to start at the beginning
      if( UnixDirEnt = nil) then begin
         StatOK:= false;
         if( UnixDirectory <> nil) then begin
            fpCloseDir( UnixDirectory^);
         end;
         MyDirOpen();
      end;

      UnixDirEnt:= fpReadDir( UnixDirectory^);
      result:= ( UnixDirEnt <> nil);
   end; // Mext()


// *************************************************************************
// * Name() - Return the name of the current directory entry
// *************************************************************************

function tFileInfoClass.Name(): string;
   begin
      result:= pchar( @UnixDirEnt^.d_name[ 0]);
   end; // Name()


// *************************************************************************
// * FullName() - Return the full name of the current directory entry
// *************************************************************************

function tFileInfoClass.FullName(): string;
   var
      Temp: string;
   begin
      Temp:= DirName;
      if( DirName[ Length( DirName)] <> '/') then begin
         Temp:= DirName + '/';
      end;
      result:= Temp + pchar( @UnixDirEnt^.d_name[ 0]);
   end; // FullName()


// *************************************************************************
// * INode() - Return the inode of the current directory entry
// *************************************************************************

function tFileInfoClass.Inode(): ino_t;
   begin
      result:= UnixDirEnt^.d_fileno;
   end; // INode()


// *************************************************************************
// * Mode() - Return the mode (permissions) of the current directory entry
// *************************************************************************

function tFileInfoClass.Mode(): mode_t;
   var
      Temp: string;
   begin
      if( not StatOK) then begin
         Temp:= FullName;
         fplstat( @Temp[1] , @UnixStat);
      end;
      result:= UnixStat.st_mode;
   end; // Mode()


// *************************************************************************
// * UID() - Return the user number of the current directory entry
// *************************************************************************

function tFileInfoClass.UID(): uid_t;
   var
      Temp: string;
   begin
      if( not StatOK) then begin
         Temp:= FullName;
         fplstat( @Temp[1] , @UnixStat);
      end;
      result:= UnixStat.st_uid;
   end; // UID()


// *************************************************************************
// * GID() - Return the group number of the current directory entry
// *************************************************************************

function tFileInfoClass.GID(): gid_t;
   var
      Temp: string;
   begin
      if( not StatOK) then begin
         Temp:= FullName;
         fplstat( @Temp[1] , @UnixStat);
      end;
      result:= UnixStat.st_gid;
   end; // GID()


// *************************************************************************
// * IsSocket() - Return true if the current directory entry is a socket
// *************************************************************************

function tFileInfoClass.IsSocket(): boolean;
   var
      Temp: string;
   begin
      if( not StatOK) then begin
         Temp:= FullName;
         fplstat( @Temp[1] , @UnixStat);
      end;
      result:= (UnixStat.st_mode and S_IFMT) = S_IFSOCK;
   end; // IsSocket)


// *************************************************************************
// * IsSymbolicLink() - Return true if the current directory entry is a
// *                    symbolic link
// *************************************************************************

function tFileInfoClass.IsSymbolicLink(): boolean;
   var
      Temp: string;
   begin
      if( not StatOK) then begin
         Temp:= FullName;
         fplstat( @Temp[1] , @UnixStat);
      end;
      result:= (UnixStat.st_mode and S_IFMT) = S_IFLNK;
   end; // IsSymbolicLink)


// *************************************************************************
// * IsRegularFile() - Return true if the current directory entry is a
// *                   regular file
// *************************************************************************

function tFileInfoClass.IsRegularFile(): boolean;
   var
      Temp: string;
   begin
      if( not StatOK) then begin
         Temp:= FullName;
         fplstat( @Temp[1] , @UnixStat);
      end;
      result:= (UnixStat.st_mode and S_IFMT) = S_IFREG;
   end; // IsRegularFile)


// *************************************************************************
// * IsBlockDevice() - Return true if the current directory entry is a
// *                   block device
// *************************************************************************

function tFileInfoClass.IsBlockDevice(): boolean;
   var
      Temp: string;
   begin
      if( not StatOK) then begin
         Temp:= FullName;
         fplstat( @Temp[1] , @UnixStat);
      end;
      result:= (UnixStat.st_mode and S_IFMT) = S_IFBLK;
   end; // IsBlockDevice)


// *************************************************************************
// * IsDirectory() - Return true if the current directory entry is a directory
// *************************************************************************

function tFileInfoClass.IsDirectory(): boolean;
   begin
      if( not StatOK) then begin
         fplstat( FullName , @UnixStat);
      end;
      result:= (UnixStat.st_mode and S_IFMT) = S_IFDIR;
   end; // IsDirectory)


// *************************************************************************
// * IsCharacterDevice() - Return true if the current directory entry is a
// *                       character device
// *************************************************************************

function tFileInfoClass.IsCharacterDevice(): boolean;
   var
      Temp: string;
   begin
      if( not StatOK) then begin
         Temp:= FullName;
         fplstat( @Temp[1] , @UnixStat);
      end;
      result:= (UnixStat.st_mode and S_IFMT) = S_IFCHR;
   end; // IsCharacterDevice)


// *************************************************************************
// * IsFIFO() - Return true if the current directory entry is a FIFO
// *************************************************************************

function tFileInfoClass.IsFIFO(): boolean;
   var
      Temp: string;
   begin
      if( not StatOK) then begin
         Temp:= FullName;
         fplstat( @Temp[1] , @UnixStat);
      end;
      result:= (UnixStat.st_mode and S_IFMT) = S_IFIFO;
   end; // IsFIFO)


// *************************************************************************
// * MyDirOpen() - Attempt to open our directory
// *************************************************************************

procedure tFileInfoClass.myDirOpen();
   begin
      if( UnixDirectory = nil) then begin
         UnixDirectory:= fpOpenDir( DirName);
         if( UnixDirectory = nil) then begin
            raise FileInfoException.Create(
                  'Unable to open directory "' + DirName + '" for reading!');
         end;
      end;
   end; // MyDirOpen()


// *************************************************************************

end. // lbp_file_directory unit
