{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Base classes on which interfaces to SQL databases are built

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

unit lbp_sql_db;
// Base classes on which interfaces to SQL databases are built

interface
{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_argv,        // So we can test to make sure argv was parsed before a 
                    // connection was setup
   lbp_types,       // Ordinal types, lbp_exceptions
   lbp_lists,       // Double linked lists
   lbp_vararray,
   lbp_sql_fields;
//   baseunix;


// *************************************************************************

type
   SQLdbException = class( lbp_exception);
   SQLdbCriticalException = class( lbp_exception);

// -------------------------------------------------------------------------

type
   dbConnection = class
      protected
         Opened:          boolean;
         Used:            boolean;
         UsedTime:        word32;
         HostStr:         string;
         PortW16:         word16;
         DatabaseStr:     string;
         UserStr:         string;
         PasswordStr:     string;
         dbTypeStr:       string;  // eg:  'MySQL', 'Postgresql', etc

      public
         constructor  Create( const idbType:   string;
                              const iHost:     string;
                              const iPort:     word16;
                              const iUser:     string;
                              const iPassword: string;
                              const iDatabase: string);
         destructor   Destroy();         override;
         procedure    Open();            virtual; abstract;
         procedure    Close();           virtual; abstract;
      protected
         procedure    SetDatabase( dbName: string);     virtual;
         procedure    SetUsed( IsInUse: boolean); virtual;
      public
         property     IsOpen:   boolean read Opened;
         property     InUse:    boolean read Used write SetUsed;
         property     Host:     string  read HostStr;
         property     Port:     word16  read PortW16;
         property     Database: string  read DatabaseStr write SetDatabase;
         property     User:     string  read UserStr;
         property     Password: string  read PasswordStr;
         property     dbType:   string  read dbTypeStr;
   end; // dbConnection


// -------------------------------------------------------------------------

type
   dbPrimaryKey = class;
   dbResults = class
      protected
         Connection:           dbConnection;
         DatabaseStr:          String;

         StandardQueryString:  string;
         FieldListString:      string;
         LongFieldListString:  string;
         UseLongFieldList:     boolean;
         SQLNameStr:           string;   // table
         MultiSQLwhere:        string;   // Only set by children with Multi
                                         // table queries.
         MyStoredAsHTML: boolean;  // Only used to set the corresponding AutoSQLFieldList values.
         MyAccessAsHTML: boolean;

         WorkSQLFieldList:     DoubleLinkedList;
         AutoSQLFieldList:     DoubleLinkedList; // For SQLQuery
         UniqueFields:         DoubleLinkedList;

      public
         Fields:               DoubleLinkedList; // For Query
         Indexes:              DoubleLinkedList;
         Relations:            DoubleLinkedList;

         // Default index values - they must be added into Fields and
         // Indexes by children
         ID:                   dbWord64Field;
         IDindex:              dbPrimaryKey;

         constructor  Create(       iConnection: dbConnection;
                              const iDatabase:   string);
         constructor  Create( const idbType:   string; const iHost:     string;
                              const iPort:     word16; const iUser:     string;
                              const iPassword: string; const iDatabase: string);
         destructor   Destroy();                             override;
         function     EscapeString( const S: string): string;virtual; abstract;
         procedure    SQLExecute( QueryStr: String);         virtual; abstract;
         procedure    SQLQuery( QueryStr: String);           virtual; abstract;
         function     Next(): boolean;                       virtual; abstract;
         function     GetLastInsertID: int64;                virtual; abstract;

         function     GetFieldValue( iName: string): string; virtual;
         function     GetFieldValue( i: integer): string;    virtual;
         function     GetFieldName( i: integer): string;     virtual;
         function     GetFieldCount(): integer;              virtual;

         property     FieldByName[ iName: string]: string read GetFieldValue; default;
         property     Field[ i: integer]: string read GetFieldValue;
         property     FieldName[ i: integer]: string read GetFieldName;
         property     FieldCount: integer read GetFieldCount;

         function     GetValueList(): string;                virtual;
         function     GetFieldList(): string;                virtual;
         function     GetLongFieldList(): string;            virtual;
         function     GetSQLQuery(): string;                 virtual;
         procedure    Query( WhereClause: string);           virtual; abstract;
         procedure    Query();                               virtual;
         function     GetSQLCreate(): string;                virtual;
         procedure    CreateTable();                         virtual;
         procedure    EmptyTable();                          virtual;
         procedure    DropTable();                           virtual;
         function     GetSQLUniqueWhere(): string;           virtual;
         function     GetSQLUpdate(): string;                virtual;
         function     GetSQLDelete(): string;                virtual;
         function     GetSQLInsert(): string;                virtual;
         procedure    Clear();                               virtual;
         function     HasChanged(): boolean;                 virtual;
         procedure    NoChange();                            virtual;
         procedure    Update();                              virtual;
         procedure    Delete();                              virtual;
         procedure    Insert();                              virtual;
         property     StoredAsHTML: boolean read MyStoredAsHTML write MyStoredAsHTML;
         property     AccessAsHTML: boolean read MyAccessAsHTML write MyAccessAsHTML;

      protected
         procedure    InitVars();                            virtual;
         procedure    EmptySQLFieldList(
                            SQLFieldList: DoubleLinkedList); virtual;
         procedure    SetDatabase( dbName: string);          virtual; abstract;
      public
         property     Database: string        read  DatabaseStr
                                              write SetDatabase;
         property     Table:    string        read  SQLNameStr;
   end; // dbResults


// -------------------------------------------------------------------------

type
   dbIndex = class
      public
         SQLName:    string;
         Fields:     DoubleLinkedList;
         SQLCreate:  string;
         Unique:     boolean;
         constructor Create( const iName:            string;
                             const FieldArray:       array of dbField;
                             const CreateParameters: string;
                             const UniqueFlag:       boolean);
         destructor  Destroy(); override;
         function    GetSQLCreate(): string; virtual;
      end; // dbIndex


// -------------------------------------------------------------------------

type
   dbRelation = class
      public
         LocalField:       dbField;
         RemoteFieldName:  string;
         RemoteTableName:  string;
         AutoDelete:       boolean;
         constructor       Create( LocalFieldIn: dbField;
                                   RemoteField:  string;
                                   RemoteTable:  string;
                                   AutoDel:      boolean);
      end; // dbRelation class



// -------------------------------------------------------------------------

type
   dbPrimaryKey = class( dbIndex)
      public
         constructor Create( const iName:      string;
                             const FieldArray: array of dbField);
         function    GetSQLCreate(): string; override;
      end; // dbPrimaryKey


// -------------------------------------------------------------------------

type
   NewDBConnectionProc = function( const iHost:     string;
                                   const iPort:     word16;
                                   const iUser:     string;
                                   const iPassword: string): dbConnection;

   dbConnectionRegistrationClass = class
      protected
         dbType:        string;
         NewConnection: NewDBConnectionProc;
      public
         constructor Create( const idbType:  string;
                             const NewProc:  NewDBConnectionProc);
      end; //ClassRegistrationClass


   // Used by child classes to minimize their connections.
   dbConnectionManager = class
      protected
         CritSect:               TRTLCriticalSection;
         RegisteredClasses:      PointerArray;
         RegisteredConnections:  PointerArray;
      public
         constructor  Create();
         destructor   Destroy(); override;
         procedure    Register( const idbType:        string;
                                const NewProc:        NewDBConnectionProc);
         function     GetConnection( const idbType:   string;
                                     const iHost:     string;
                                     const iPort:     word16;
                                     const iUser:     string;
                                     const iPassword: string): dbConnection;
                                                                virtual;
   end; // dbConnectionManager();


var
   ConnectionManager: dbConnectionManager;


// ************************************************************************

implementation

// ========================================================================
// = dbConnection   - Holds the UnixFileHandle and connection info
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbConnection.Create( const idbType:   string;
                                 const iHost:     string;
                                 const iPort:     word16;
                                 const iUser:     string;
                                 const iPassword: string;
                                 const iDatabase: string);
   begin
      if( not lbp_argv.Parsed) then begin
         raise argv_exception.Create( 'lbp_sql_db.dbConnection.Create() called before lbp_argv.ParseParams()!');
      end;

      Opened:=        false;
      Used:=          false;
      HostStr:=       iHost;
      PortW16:=       iPort;
      DatabaseStr:=   iDatabase;
      UserStr:=       iUser;
      PasswordStr:=   iPassword;
      dbTypeStr:=     idbType;
   end; // Create()


// ************************************************************************
// Done() - Destructor
// ************************************************************************

destructor dbConnection.Destroy();
   begin
      Close();
      inherited Destroy();
   end; // Done()


// ************************************************************************
// * SetDatabae() - Set the database used.  Children should override to
// *                perform the actual databse switch call to the server.
// ************************************************************************

procedure dbConnection.SetDatabase( dbName: string);
   begin
      DatabaseStr:= dbName;
   end; // SetDatabase()


// ************************************************************************
// * SetUsed() - Mark this connection as used.
// ************************************************************************

procedure dbConnection.SetUsed( IsInUse: boolean);
   begin
      Used:= IsInUse;
   end; // SetUsed()


// ========================================================================
// = dbResults
// ========================================================================
// ************************************************************************
// * Create() - This constructor assumes the dbConnection is not yet open.
// *            The user must call Open() before using the connection.
// ************************************************************************

constructor dbResults.Create( iConnection: dbConnection;
                              const iDatabase:   string);
   var
      Temp: dbField;
   begin
      inherited Create();

      Connection:= iConnection;
      Database:=   iDatabase;
      StoredAsHTML:= false; // might be changed in InitVars
      AccessAsHTML:= false; // might be changed in InitVars
      InitVars();
      // Assume the child has filled in Fields, let our EscapeString
      // function work for the child.
      Temp:= dbField( Fields.GetFirst());

      while( Temp <> nil) do begin
         Temp.SetEscapeStringFunction( @EscapeString);
         Temp.StoredAsHTML:= StoredAsHTML;
         Temp.AccessAsHTML:= AccessAsHTML;
         Temp:= dbField( Fields.GetNext());
      end;
   end; // Create()


// ------------------------------------------------------------------------
// - Create() - This constructor gets its dbConnection from the global
// -            ConnectionManager.
// ------------------------------------------------------------------------

constructor dbResults.Create( const idbType:   string;
                              const iHost:     string;
                              const iPort:     word16;
                              const iUser:     string;
                              const iPassword: string;
                              const iDatabase: string);

   var
      Temp: dbField;
   begin
      inherited Create();
      Connection:= ConnectionManager.GetConnection( idbType, iHost, iPort,
                                                    iUser, iPassword);
      Database:=   iDatabase;
      StoredAsHTML:= false; // might be changed in InitVars
      AccessAsHTML:= false; // might be changed in InitVars
      InitVars();
      // Assume the child has filled in Fields, let our EscapeString
      // function work for the child.
      Temp:= dbField( Fields.GetFirst());

      while( Temp <> nil) do begin
         Temp.SetEscapeStringFunction( @EscapeString);
         Temp.StoredAsHTML:= StoredAsHTML;
         Temp.AccessAsHTML:= AccessAsHTML;
         Temp:= dbField( Fields.GetNext());
      end;
   end; // Create()


// ************************************************************************
// Destroy() - Destructor
// ************************************************************************

destructor dbResults.Destroy();
   var
      IDindexDestroyed: boolean;
      IDDestroyed:      boolean;
      Fld:  dbField;
      Idx:  dbIndex;
      Rltn: dbRelation;
   begin
      IDindexDestroyed:= false;
      IDDestroyed:=      false;

      while( not Indexes.Empty()) do begin
         Idx:= dbIndex( Indexes.Dequeue());
         if( Idx = IDindex) then begin
            IDindexDestroyed:= true;
         end;
         Idx.Destroy();
      end;
      Indexes.Destroy();

      while( not Relations.Empty()) do begin
         Rltn:= dbRelation( Relations.Dequeue());
         Rltn.Destroy();
      end;
      Relations.Destroy();

      UniqueFields.RemoveAll;
      UniqueFields.Destroy();

      // Discard all the SQL Field Lists
      while( not Fields.Empty()) do begin
         Fld:= dbField( Fields.Dequeue());
         if( Fld = ID) then begin
            IDDestroyed:= true;
         end;
         Fld.Destroy();
      end;
      Fields.Destroy();
      EmptySQLFieldList( AutoSQLFieldList);
      AutoSQLFieldLIst.Destroy();

      if( not IDDestroyed) then begin
         ID.Destroy();
      end;
      if( not IDindexDestroyed) then begin
         IDindex.Destroy();
      end;
   end; // Destroy();


// ************************************************************************
// * GetFieldValue() - Returns the string value of the named field
// ************************************************************************

function dbResults.GetFieldValue( iName: string): string;
   var
      Temp: dbField;
   begin
      Temp:= dbField( WorkSQLFieldList.GetFirst());
      while( Temp <> nil) do begin
         if( Temp.GetSQLName() = iName) then begin
            result:= Temp.GetValue();
            exit;
         end;
         Temp:= dbField( WorkSQLFieldList.GetNext());
      end;

      raise dbFieldException.Create( 'MySQLResults.GetFieldValue():  ' +
               'Invalid index( ' + iName + ')');
   end; // GetFieldValue()


// -------------------------------------------------------------------------

function dbResults.GetFieldValue( i: integer): string;
   var
      Temp: dbField;
      j:    integer;
   begin
      j:= i;
      Temp:= dbField( WorkSQLFieldList.GetFirst());
      while( Temp <> nil) do begin
         if( j = 0) then begin
            exit( Temp.GetValue());
         end;
         dec( j);
         Temp:= dbField( WorkSQLFieldList.GetNext());
      end;

      raise dbFieldException.Create(
         'MySQLResults.GetFieldValue():  Invalid index( %d)', [i]);
   end; // GetFieldValue()


// ************************************************************************
// * GetFieldName() - Returns the name of the [ i]th record
// ************************************************************************

function dbResults.GetFieldName( i: integer): string;
   var
      Temp: dbField;
      j:    integer;
   begin
      j:= i;
      Temp:= dbField( WorkSQLFieldList.GetFirst());
      while( Temp <> nil) do begin
         if( j = 0) then begin
            exit( Temp.GetSQLName());
         end;
         dec( j);
         Temp:= dbField( WorkSQLFieldList.GetNext());
      end;

      raise dbFieldException.Create(
         'MySQLResults.GetFieldName():  Invalid index( %d)', [i]);
   end; // GetFieldName()


// ************************************************************************
// * GetFieldName() - Returns the name of the [ i]th record
// ************************************************************************

function dbResults.GetFieldCount(): integer;
   begin
      result:= WorkSQLFieldList.Length();
   end; // GetFieldCount()


// *************************************************************************
// * GetValueList() - Returns the current row as a comma delimited string
// *************************************************************************

function dbResults.GetValueList(): string;
   var
      Fld:  dbField;
      Temp: string;
   begin
      Temp:= '';
      if( not Fields.Empty()) then begin

         Fld:= dbField( Fields.GetFirst());
         Temp:= Fld.GetSQLValue();
         Fld:= dbField( Fields.GetNext());
         while( Fld <> nil) do begin
            Temp:= Temp + ',' + Fld.GetSQLValue();
            Fld:= dbField( Fields.GetNext());
         end; // while
      end;
      GetValueList:= Temp;
   end; // GetValueList();


// ************************************************************************
// * GetFieldList() - Returns a comma separated list of field Names.
// ************************************************************************

function dbResults.GetFieldList(): string;
   var
      Temp: dbField;
   begin
      if( (Length( FieldListString) = 0) and ( not Fields.Empty())) then begin

         Temp:= dbField( Fields.GetFirst());
         FieldListString:= Temp.GetSQLName;
         Temp:= dbField( Fields.GetNext());
         while( Temp <> nil) do begin
            FieldListString:= FieldListString + ', ' + Temp.GetSQLName;
            Temp:= dbField( Fields.GetNext());
         end; // while
      end;

      GetFieldList:= FieldListString;
   end; // GetFieldList()


// ************************************************************************
// * GetLongFieldList() - Returns a comma separated list of field Names.
// ************************************************************************

function dbResults.GetLongFieldList(): string;
   var
      Temp: dbField;
   begin
      if( (Length( LongFieldListString) = 0) and
          ( not Fields.Empty())) then begin

         Temp:= dbField( Fields.GetFirst());
         LongFieldListString:= SQLNameStr + '.' + Temp.GetSQLName;
         Temp:= dbField( Fields.GetNext());
         while( Temp <> nil) do begin
            LongFieldListString:= LongFieldListString + ', ' + SQLNameStr +
                                  '.' + Temp.GetSQLName;
            Temp:= dbField( Fields.GetNext());
         end; // while
      end;

      GetLongFieldList:= LongFieldListString;
   end; // GetLongFieldList()


// ************************************************************************
// * GetSQLQuery() - Returns the SQL string that will query for all
// *                 records and fields in this database.
// ************************************************************************

function dbResults.GetSQLQuery(): string;
   begin
      if( Length( StandardQueryString) = 0) then begin
         if( UseLongFieldList) then begin
            StandardQueryString:= 'select ' + GetLongFieldList() +
                                  ' from ' + SQLNameStr;
         end else begin
            StandardQueryString:= 'select ' + GetFieldList() +
                                  ' from ' + SQLNameStr;
         end;

         if( Length( MultiSQLwhere) <> 0) then begin
            StandardQueryString:= StandardQueryString + ' ' + MultiSQLWhere;
         end;
      end;

      GetSQLQuery:= StandardQueryString;
   end; // GetSQLQuery()


// *************************************************************************
// * Query() - Retrieve all the records from the table
// *************************************************************************

procedure dbResults.Query();
   begin
      Query( GetSQLQuery());
   end; // Query()


// *************************************************************************
// * GetSQLCreate() - Returns the SQL string that will create the table
// *************************************************************************

function dbResults.GetSQLCreate(): string;
   var
      Temp:  string;
      Fld:   dbField;
      Idx:   dbIndex;
   begin
      Temp:= 'create table ' + SQLNameStr + ' ( ' + chr( 10);
      Fld:= dbField( Fields.GetFirst());
      while( Fld <> nil) do begin
         Temp:= Temp + '   ' + Fld.GetSQLName() + ' ' +
                Fld.GetSQLCreate() + ',' + chr( 10);
         Fld:= dbField( Fields.GetNext());
      end;

      Idx:= dbIndex( Indexes.GetFirst());
      while( Idx <> nil) do begin
         Temp:= Temp + '   ' + Idx.GetSQLCreate();
         if( not Indexes.Last()) then begin
            Temp:= Temp + ',' + chr( 10);
         end else begin
            Temp:= Temp + chr( 10) + ')' + chr( 10);
         end;

         Idx:= dbIndex( Indexes.GetNext());
      end;

      GetSQLCreate:= Temp;
   end; // GetSQLCreate()


// *************************************************************************
// * CreateTable() - Creates the SQL table.
// *************************************************************************

procedure dbResults.CreateTable();
   begin
      SQLExecute( GetSQLCreate());
   end; // CreateTable();


// *************************************************************************
// * EmptyTable() - Drops the table (if it exists) and recreates it.
// *************************************************************************

procedure dbResults.EmptyTable();
   begin
      try // to drop the table
         DropTable();
      except
         on F: SQLdbException do begin
            // Do nothing if we just have an error because
            //     the table didn't exist.
         end;
      end; // try/except

      // Now recreate the table
      SQLExecute( GetSQLCreate());
   end; // EmptyTable();


// *************************************************************************
// * DropTable() - Drop the SQL table.
// *************************************************************************

procedure dbResults.DropTable();
   begin
      SQLExecute( 'drop table ' + SQLNameStr);
   end; // DropTable();


// *************************************************************************
// * GetSQLUniqueWhere() - Returns the SQL where clause that selects only
// *                       the current record.
// *************************************************************************

function dbResults.GetSQLUniqueWhere(): string;
   var
      Temp:     string = '';
      Fld:      dbField;
      FoundOne: boolean;
   begin
      FoundOne:= false;
      Fld:= dbField( UniqueFields.GetFirst());
      while( Fld <> nil) do begin
         if( FoundOne) then begin
            Temp:= Temp + ' and ';
         end else begin
            Temp:= ' where ';
            FoundOne:= true;
         end;

         Temp:= Temp + Fld.GetSQLName() + ' = ' + Fld.GetSQLOrigValue();
         Fld:= dbField( UniqueFields.GetNext());
      end; // while

      if( not FoundOne) then begin
         raise SQLdbException.Create( 'No UniqueFields were defined for this table!' +
                               '  You can not perform an update.');
      end;

      result:= Temp;
   end; // GetSQLUniqueWhere()


// *************************************************************************
// * GetSQLUpdate() - Returns the SQL string that will update the record in
// *                  the database to the current values of the fields.
// *************************************************************************

function dbResults.GetSQLUpdate(): string;
   var
      Temp:     string;
      Fld:      dbField;
      FoundOne: boolean;
   begin
      Temp:= 'update ' + SQLNameStr + ' set ';

      // Now add any changed fields (columns)
      FoundOne:= false;
      Fld:= dbField( Fields.GetFirst());
      while( Fld <> nil) do begin
         if( Fld.HasChanged()) then begin
            if( FoundOne) then begin
               Temp:= Temp + ', ';
            end else begin
               FoundOne:= true;
            end;

            Temp:= Temp + Fld.GetSQLName + ' = ' + Fld.GetSQLValue();
         end; // if the field has changed
         Fld:= dbField( Fields.GetNext());
      end; // while
      Temp:= Temp + GetSQLUniqueWhere();

      if( FoundOne) then begin
         result:= Temp;
      end else begin
         result:= '';
      end;
   end; // GetSQLUpdate()


// *************************************************************************
// * GetSQLDelete() - Returns the SQL string that will delete the current
// *                  record.
// *************************************************************************

function dbResults.GetSQLDelete(): string;
   begin
      GetSQLDelete:= 'delete from ' + SQLNameStr + GetSQLUniqueWhere();
   end; // GetSQLDelete()


// *************************************************************************
// * GetSQLInsert() - Returns the SQL string that will insert the current
// *                  record's fields into the database.
// *************************************************************************

function dbResults.GetSQLInsert(): string;
   var
      Temp:     string;
      Fld:      dbField;
      FoundOne: boolean;
   begin
      Temp:= 'insert into ' + SQLNameStr + ' values ( ';

      // Now add any changed fields (columns)
      FoundOne:= false;
      Fld:= dbField( Fields.GetFirst());
      while( Fld <> nil) do begin
         if( FoundOne) then begin
               Temp:= Temp + ', ';
         end else begin
               FoundOne:= true;
         end;

         Temp:= Temp + Fld.GetSQLValue();
         Fld:= dbField( Fields.GetNext());
      end; // while
      Temp:= Temp + ')';

      GetSQLInsert:= Temp;
   end; // GetSQLInsert()


// *************************************************************************
// * Clear() - Performs the Clear() function for every field in the record.
// *************************************************************************

Procedure dbResults.Clear();
   var
      Fld:  dbField;
   begin
      Fld:= dbField( Fields.GetFirst());
      while( Fld <> nil) do begin
         Fld.Clear();
         Fld.NoChange();
         Fld:= dbField( Fields.GetNext());
      end;
   end; // Clear()


// *************************************************************************
// * HasChanged() - Returns tru if the the record has changed.
// *************************************************************************

function dbResults.HasChanged(): boolean;
   var
      Fld:  dbField;
   begin
      Fld:= dbField( Fields.GetFirst());
      while( Fld <> nil) do begin
         if( Fld.HasChanged()) then begin
            exit( true);
         end;
         Fld:= dbField( Fields.GetNext());
      end;
      HasChanged:= false;
   end; // HasChanged()


// *************************************************************************
// * NoChange() - Performs the NoChange() function for every field in the
// *              record.
// *************************************************************************

Procedure dbResults.NoChange();
   var
      Fld:  dbField;
   begin
      Fld:= dbField( Fields.GetFirst());
      while( Fld <> nil) do begin
         Fld.NoChange();
         Fld:= dbField( Fields.GetNext());
      end;
   end; // NoChange()


// *************************************************************************
// * Update() - Update the current record to reflect the current Fields
// *            values.  Does no database call if no fields have changed!
// *************************************************************************

procedure dbResults.Update();
   var
      Temp: string;
   begin
      Temp:= GetSQLUpdate();
      if( Length( Temp) <> 0) then begin
         SQLExecute( Temp);
      end;
   end; // Update();


// *************************************************************************
// * Delete() - Delete the current record.
// *************************************************************************

procedure dbResults.Delete();
   begin
      SQLExecute( GetSQLDelete);
   end; // Delete();


// *************************************************************************
// * Insert() - Insert Fields values into the database.
// *************************************************************************

procedure dbResults.Insert();
   begin
      SQLExecute( GetSQLInsert);
      ID.SetValue( GetLastInsertID);
      ID.NoChange();
   end; // Insert();


// ************************************************************************
// * InitVars() - Called by create() to initialize all our internal vars.
// ************************************************************************

procedure dbResults.InitVars();
   begin
      Fields:=           DoubleLinkedList.Create();
      AutoSQLFieldList:= DoubleLinkedList.Create();

      WorkSQLFieldList:= Fields;
      Indexes:=          DoubleLinkedList.Create();

      ID:= dbWord64Field.Create( 'ID', 'not null auto_increment');
      IDindex:= dbPrimaryKey.Create( 'IDindex', [ ID]);

      UniqueFields:= DoubleLinkedList.Create();
      UniqueFields.Enqueue( ID);
      Relations:=    DoubleLinkedList.Create();
   end; // InitVars()


// ************************************************************************
// * EmptySQLFieldList() - Discard the fields in an SQLFieldList()
// ************************************************************************

procedure dbResults.EmptySQLFieldList( SQLFieldList: DoubleLinkedList);
   var
      Temp:  dbField;
   begin
      while( not SQLFieldList.Empty()) do begin
         Temp:= dbField( SQLFieldList.Dequeue());
         Temp.Destroy();
      end;
   end; //  EmptySQLFieldList()


// =========================================================================
// = dbIndex
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor dbIndex.Create( const iName:            string;
                            const FieldArray:       array of dbField;
                            const CreateParameters: string;
                            const UniqueFlag:       boolean);
   var
      i, H, L: integer;
   begin
      SQLName:=    iName;
      SQLCreate:=  CreateParameters;
      Unique:=     UniqueFlag;
      Fields:=     DoubleLinkedList.Create();
      // Transfer FieldArray to Fields
      H:= High( FieldArray);
      L:= Low( FieldArray);
      for i:= L to H do begin
         Fields.Enqueue( FieldArray[ i]);
      end;
   end; // Create()


// *************************************************************************
// * Done() - destructor
// *************************************************************************

destructor dbIndex.Destroy();
   begin
      Fields.RemoveAll();
      Fields.Destroy();
   end; // Done()


// *************************************************************************
// * GetSQLCreate() - Used to get the Index's parameters for the SQL
// *                  create command.  ID: index index1 (field1, field2)
// *************************************************************************

function dbIndex.GetSQLCreate(): string;
   var
      Temp: string;
      Fld:  dbField;
   begin
      if( Unique) then begin
         Temp:= 'unique ';
      end else begin
         Temp:= 'index ';
      end;

      Temp:= Temp + SQLName + '( ';

      // Add each field
      if( not Fields.Empty()) then begin
         Fld:= dbField( Fields.GetFirst());
         Temp:= Temp + Fld.GetSQLName();
         Fld:= dbField( Fields.GetNext());
         while( Fld <> nil) do begin
            Temp:= Temp + ', ' + Fld.GetSQLName();
            Fld:= dbField( Fields.GetNext());
         end;
      end; // if

      Temp:= Temp + ')';
      GetSQLCreate:= Temp;
   end; // GetSQLCreate()



// =========================================================================
// = dbPrimaryKey
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor dbPrimaryKey.Create( const iName:      string;
                                 const FieldArray: array of dbField);
   begin
      inherited Create( iName, FieldArray, '', true);
   end; // Create()


// *************************************************************************
// * GetSQLCreate() - Used to get the Index's parameters for the SQL
// *                  create command.  ID: index index1 (field1, field2)
// *************************************************************************

function dbPrimaryKey.GetSQLCreate(): string;
   var
      Temp: string;
      Fld:  dbField;
   begin
      Temp:= 'primary key ';

      Temp:= Temp + SQLName + '( ';

      // Add each field
      if( not Fields.Empty()) then begin
         Fld:= dbField( Fields.GetFirst());
         Temp:= Temp + Fld.GetSQLName();
         Fld:= dbField( Fields.GetNext());
         while( Fld <> nil) do begin
            Temp:= Temp + ', ' + Fld.GetSQLName();
            Fld:= dbField( Fields.GetNext());
         end;
      end; // if

      Temp:= Temp + ')';
      GetSQLCreate:= Temp;
   end; // GetSQLCreate()



// =========================================================================
// = dbRelation
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor dbRelation.Create( LocalFieldIn: dbField;
                               RemoteField:  string;
                               RemoteTable:  string;
                               AutoDel:      boolean);
   begin
      LocalField:=      LocalFieldIn;
      RemoteFieldName:= RemoteField;
      RemoteTableName:= RemoteTable;
      AutoDelete:=      AutoDel;
   end; // Create()



// ========================================================================
// = dbConnectionRegistrationClass
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbConnectionRegistrationClass.Create(
                             const idbType:  string;
                             const NewProc:  NewDBConnectionProc);
   begin
      dbType:=        idbType;
      NewConnection:= NewProc;
   end; // Create()


// ========================================================================
// = dbConnectionManager
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbConnectionManager.Create();
   begin
      inherited Create();
      InitCriticalSection( CritSect);
      RegisteredClasses:= PointerArray.Create();
      RegisteredConnections:= PointerArray.Create();
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

destructor dbConnectionManager.Destroy();
   var
      i:         int32;
      TempClass: dbConnectionRegistrationClass;
      TempConn:  dbConnection;
   begin
      for i:= 0 to RegisteredConnections.UpperBound do begin
         TempConn:= dbConnection( RegisteredConnections[ i]);
         TempConn.Destroy();
      end; // for
      RegisteredConnections.Destroy();

      for i:= 0 to RegisteredClasses.UpperBound do begin
         TempClass:= dbConnectionRegistrationClass( RegisteredClasses[ i]);
         TempClass.Destroy();
      end; // for
      RegisteredClasses.Destroy();
      DoneCriticalSection( CritSect);
      inherited Destroy();
   end; // Destroy()


// ************************************************************************
// * Register() - Register the function which returns a new dbConnection
// *              for a particular type.  IE: 'mysql', or 'postgres'
// ************************************************************************

procedure dbConnectionManager.Register( const idbType:  string;
                                        const NewProc:  NewDBConnectionProc);
   var
      i:        int32;
      RegClass: dbConnectionRegistrationClass;
   begin
      EnterCriticalSection( CritSect);
      // Check to see if this type is already registered.  Exit if it is.
      for i:= 0 to RegisteredClasses.UpperBound do begin
         RegClass:= dbConnectionRegistrationClass( RegisteredClasses[ i]);
         if( RegClass.dbType = idbType) then begin
            LeaveCriticalSection( CritSect);
            exit;
         end;
      end; // for

      // If we got here, then we need to register it.
      RegClass:= dbConnectionRegistrationClass.Create( idbType, NewProc);
      RegisteredClasses[ RegisteredClasses.UpperBound + 1]:= RegClass;

      LeaveCriticalSection( CritSect);
   end; // Register()


// ************************************************************************
// * GetConnection() - Get a shared connection to the named database
// ************************************************************************

function dbConnectionManager.GetConnection( const idbType:   string;
                                            const iHost:     string;
                                            const iPort:     word16;
                                            const iUser:     string;
                                            const iPassword: string):
                                                                  dbConnection;
   var
      ConnI:    int32;
      ClassI:   int32;
      RegClass: dbConnectionRegistrationClass;
      TestConn: dbConnection;
   begin
      EnterCriticalSection( CritSect);

      // First see if this connection is already registered
      for ConnI:= 0 to RegisteredConnections.UpperBound do begin
         TestConn:= dbConnection( RegisteredConnections[ ConnI]);
         if( (TestConn.dbType   = idbType)   and
             (TestConn.Host     = iHost)     and
             (TestConn.User     = iUser)     and
             (TestConn.Password = iPassword) and
             (TestConn.Port     = iPort))    then begin
            // It is already registered, so exit
            result:= TestConn;
            LeaveCriticalSection( CritSect);
            exit;
         end; // if
      end;  // for

      // We only reach here if the connection has not been registered before
      // Now test to see if we know how to create a connection of this type.
      for ClassI:= 0 to RegisteredClasses.UpperBound do begin
         RegClass:= dbConnectionRegistrationClass( RegisteredClasses[ ClassI]);
         if( RegClass.dbType = idbType) then begin
            // We know how to create the connection, so create it
            TestConn:= RegClass.NewConnection( iHost, iPort, iUser, iPassword);
            // And register it.
            RegisteredConnections[ RegisteredConnections.Upperbound + 1]:=
                                                                     TestConn;
            result:= TestConn;
            LeaveCriticalSection( CritSect);
            exit;
         end; // if
      end; // for

      LeaveCriticalSection( CritSect);

      // If we got here, we don't know how to create a connection of that type.
      raise SQLdbException.Create(
         'dbConnectionManager.GetConnection():  Attempt to get a ' +
         'dbConnection of an unregistered type!');
   end; // GetConnection()


// -------------------------------------------------------------------------
// - Unit initialization and finalization
// -------------------------------------------------------------------------
// *************************************************************************
// * Initialization
// *************************************************************************

Initialization
   begin
      ConnectionManager:= dbConnectionManager.Create();
   end;


// *************************************************************************
// * Finalization
// *************************************************************************

Finalization
   begin
      ConnectionManager.Destroy();
   end;


// *************************************************************************

end. // lbp_sql_db unit
