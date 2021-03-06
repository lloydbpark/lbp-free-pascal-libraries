{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Postgres database support

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

unit lbp_pgsql_db;
// Implementation of the lbp_sql_db classes for PgSQL

interface
{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_Types,       // Ordinal types, lbp_exceptions
   lbp_SQL_db,      // Abstract classes for our classes
   lbp_sql_fields,
   postgres;


// ************************************************************************

const
   PgSQLdbType = 'PgSQL';
   PgSQLPortNumber = 5432;

const
   Oid_Int8      = 20;
   Oid_int2      = 21;
   Oid_Int4      = 23;
   Oid_Text      = 25;
   Oid_Float4    = 700;
   Oid_Float8    = 701;
   Oid_inet      = 869;
   Oid_bpchar    = 1042;
   Oid_varchar   = 1043;
   Oid_DateTime  = 1184;
   Oid_timestamp = 1114;
   Oid_Date      = 1082;
   Oid_Time      = 1083;
   Oid_bytea     = 17;

// -------------------------------------------------------------------------

type
   PgSQLdbConnection = class( dbConnection)
      protected
         DBHandle:    PPGConn;
      public
         constructor  Create( const iHost:     string;
                              const iPort:     word16;
                              const iUser:     string;
                              const iPassword: string;
                              const iDatabase: string);
         procedure    Open();            override;
         procedure    Close();           override;
   end; // PgSQLdbConnection


// -------------------------------------------------------------------------

type
   PgSQLdbResults = class( dbResults)
      protected
         DBResultSet:   PPGresult;
         DBExecResult:  PPGresult;
         CurrentRowNum: int32;
         RowsReturned:  int32;
      public
         constructor  Create( const iHost:       string;
                              const iPort:       word16;
                              const iUser:       string;
                              const iPassword:   string;
                              const iDatabase:   string);
         constructor  Create(       iConnection: dbConnection;
                              const iDatabase:   string);
         destructor   Destroy(); override;
         function     EscapeString( const S: string): string; override;
         procedure    SQLExecute( QueryStr: String);          override;
         procedure    SQLQuery( QueryStr: String);            override;
         procedure    Query();                                override;
         procedure    Query( WhereClause: string);            override;
         function     Next(): boolean;                        override;
         function     GetLastInsertID: int64;                 override;
         procedure    CreateTable();                          override;
         procedure    EmptyTable();                           override;
         procedure    DropTable();                            override;
         procedure    Update();                               override;
         procedure    Delete();                               override;
         procedure    Insert();                               override;
         protected
         procedure    PrivateQuery( QueryStr: string);  virtual;
         procedure    SetDatabase( dbName: string);     override;
      end; // PgSQLdbResults()


// -------------------------------------------------------------------------

type
   PgSQLdbHistoryInfoTable = class( PgSQLdbResults)
      public
         RelatedID:  dbWord64Field;
         MsgTime:    dbDateTimeField;
         LifeSpan:   dbWord8Field;
         Message:    dbTextField;
         ByRelationIndex: dbIndex;
         ByMsgTimeIndex:  dbIndex;
      public
         constructor  Create(       iConnection: dbConnection;
                              const iDatabase:   string;
                              const TableName:   string);
         constructor  Create( const iHost:       string;
                              const iPort:       word16;
                              const iUser:       string;
                              const iPassword:   string;
                              const iDatabase:   string;
                              const TableName:   string);
      protected
         procedure    InitVars();                            override;
   end; // PgSQLdbHistoryInfoTable


// ************************************************************************

implementation

// extern size_t PQescapeString(char *to, const char *from, size_t length);
// extern unsigned char *PQescapeBytea(unsigned char *bintext, size_t binlen,
   //                       size_t *bytealen);
function PQescapeString( ToStr: pchar; const FromStr:
                         pchar; FromLength: int32): int32; cdecl; external;
function PQresultErrorMessage( ResultSet: PPGresult): pchar; cdecl; external;


// ========================================================================
// = PgSQLdbConnection   - Holds the database handle
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor PgSQLdbConnection.Create( const iHost:     string;
                                      const iPort:     word16;
                                      const iUser:     string;
                                      const iPassword: string;
                                      const iDatabase: string);
   var
      TempPort:     word16;
   begin
      if( iPort = 0) then begin
         TempPort:= PgSQLPortNumber;
      end else begin
         TempPort:= iPort;
      end;

      if( iUser = '') then begin
         raise lbp_exception.Create(
            'PgSQLdbConnection.Open():  User name can not be empty!');
      end;

      inherited Create( PgSQLdbType, iHost, TempPort,
                        iUser, iPassword, IDatabase);
   end; // Create()


// ************************************************************************
// Open() - Open the connection
// ************************************************************************

procedure PgSQLdbConnection.Open();
   var
      ConnectionStr: string;
      PortStr:       string;
   begin
      if( Opened) then begin
         exit;
      end;

      ConnectionStr:= 'user = ''' + UserStr + '''';
      if( Length( PasswordStr) > 0) then begin
         ConnectionStr:= ConnectionStr + ' password = ''' + PasswordStr + '''';
      end;
      if ( Length( DatabaseStr) > 0) then begin
         ConnectionStr:= 'dbname = ''' + DatabaseStr + ''' ' + ConnectionStr;
      end;
      if( Length( HostStr) > 0) then begin
         Str( PortW16, PortStr);
         ConnectionStr:= 'host = ''' + HostStr + ''' port = ' + PortStr +' ' + ConnectionStr;
      end;

      DBHandle:= PQconnectdb( @ConnectionStr[ 1]);;

      if( DBHandle = nil) then begin
         raise SQLdbCriticalException.Create(
            'PgSQLdbConnection.Open():  Unable to allocate a new PgSQL handle!');
      end;

      if( PQStatus( DBHandle) <> CONNECTION_OK) then begin
         PQfinish( DBHandle);
         raise SQLdbCriticalException.Create(
            'PgSQLdbConnection.Open():  Unable to allocate a new PgSQL handle!');
      end;

      Opened:= true;
   end; // Open()


// ************************************************************************
// Close() - Close the connection
// ************************************************************************

procedure PgSQLdbConnection.Close();
   begin
      if( Opened) then begin
         PQfinish( DBHandle);
         Opened:= false;
      end;
   end; // Close()


// -------------------------------------------------------------------------
// - PgSQLdbResults
// -------------------------------------------------------------------------
// *************************************************************************
// Create() - Constructor
// *************************************************************************

constructor PgSQLdbResults.Create(       iConnection: dbConnection;
                                   const iDatabase: string);
   begin
      inherited Create( iConnection, iDatabase);
      DBResultSet:= nil;
   end; // Create()


// -------------------------------------------------------------------------

constructor PgSQLdbResults.Create( const iHost:     String;
                                   const iPort:     word16;
                                   const iUser:     String;
                                   const iPassword: String;
                                   const iDatabase: String);
   begin
      inherited Create( PgSQLdbType, iHost, iPort, iUser,
                        iPassword, iDatabase);
      DBResultSet:= nil;
   end; // Create();


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor PgSQLdbResults.Destroy();
   begin
      if( DBResultSet <> nil) then begin
         PQclear( DBResultSet);
         DBResultSet:= nil;
      end;
      inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * GetLastInsertID()
// *************************************************************************

function PgSQLdbResults.GetLastInsertID(): int64;
   begin

      {$WARNING This isn't going to work for postgres!  Fix it!'}
//      result:= PgSQL_insert_id( PgSQLdbConnection( Connection).DBHandle);
      result:= 0;
      raise lbp_exception.Create( 'GetLastInsertID not yet implemented!');
   end; // GetLastInsertID()


// *************************************************************************
// * EscapeString() - Escape strings for SQL queries using PgSQL's
// *                  conventions.
// *************************************************************************

function PgSQLdbResults.EscapeString( const S: string): string;
   var
      Temp: string;
      L:    Word32;
   begin
      L:= Length( S);
      if( L = 0) then begin
         result:= '';
      end else begin
         SetLength( Temp, ((L * 2) + 1));  // Make room in Temp for the maximum size
         L:= PQescapeString( @Temp[ 1], @S[ 1], L);
         SetLength( Temp, L);
         result:= Temp;
      end;
   end; // EscapeString()


// *************************************************************************
// * SQLExecute() - Perform a Non-query SQL command
// *************************************************************************

procedure PgSQLdbResults.SQLExecute( QueryStr: string);
   var
      DBHandle:     PPgConn;
      ExecStatus:   tExecStatusType;
      ErrorMessage: string;
   begin
      DBHandle:= PgSQLdbConnection( Connection).DBHandle;

      if( not Connection.IsOpen) then begin
         Connection.Open();
      end;

      DBExecResult:= PQexec( DBHandle, @QueryStr[ 1]);
      ExecStatus:= PQresultStatus( DBExecResult);
      if( ExecStatus <> PGRES_COMMAND_OK) then begin
         ErrorMessage:= PQresultErrorMessage( DBExecResult);
         raise SQLdbException.Create( 'PgSQLdbResults.SQLExecute():  ' +
                                      ErrorMessage);
      end;
   end; // SQLExecute()


// *************************************************************************
// * SQLQuery() - Perform an SQL query command
// *************************************************************************

procedure PgSQLdbResults.SQLQuery( QueryStr: string);
   begin
      EmptySQLFieldList( AutoSQLFieldList);
      WorkSQLFieldList:= AutoSQLFieldList;

      PrivateQuery( QueryStr);
   end; // SQLQuery()


// *************************************************************************
// * Query() - Perform a query on the default table
// *************************************************************************

procedure PgSQLdbResults.Query( WhereClause: string);
   begin
      if( Fields.Empty()) then begin
         raise SQLdbException.Create(
            'Don''t use Query() with no arguments when you haven''t set default fields!');
      end;
      WorkSQLFieldList:= Fields;

      PrivateQuery( GetSQLQuery() + ' ' + WhereClause);
   end; // SQLQuery()


// *************************************************************************
// * Query() - Retrieve the entire database.
// *************************************************************************

procedure PgSQLdbResults.Query();
   begin
      if( Fields.Empty()) then begin
         raise SQLdbException.Create(
            'Don''t use Query() when you haven''t set created default fields!');
      end;

      WorkSQLFieldList:= Fields;

      PrivateQuery( GetSQLQuery());
   end; // Query()

// *************************************************************************
// * PrivateQuery() - Does the actual query
// *************************************************************************

procedure PgSQLdbResults.PrivateQuery( QueryStr: string);

   var
//      DBFieldDef:   PPgSQL_FIELD;
      DBFieldCount: int32;
      DBHandle:     PPGConn;
      QueryStatus:  tExecStatusType;
      ErrorMessage: string;
      i:            int32;
      FieldNameStr: string;
      FieldSize:    int32;
      Temp:         dbField;
   begin
      if( length( QueryStr) = 0) then begin
         raise SQLdbException.Create(
            'Attempt to execute an empty SQL command!');
      end;

      // Get rid of the previous result set if needed.
      if( DBResultSet <> nil) then begin
         PQclear( DBResultSet);
         DBResultSet:= nil;
      end;
      // Clear values so Next() works.
      CurrentRowNum:= 0;
      RowsReturned:= 0;

      if( not Connection.IsOpen) then begin
         Connection.Open();
      end;

      DBHandle:= PgSQLdbConnection( Connection).DBHandle;

      // Fetch all the rows from the server.  (Query result rows)
      DBResultSet:= PQexec( DBHandle, @QueryStr[ 1]);
      QueryStatus:= PQresultStatus( DBResultSet);
      if( QueryStatus <> PGRES_TUPLES_OK) then begin
         ErrorMessage:= PQresultErrorMessage( DBResultSet);
         raise SQLdbException.Create( 'PGSQLdbResults.PrivateQuery():  ' +
                                      ErrorMessage);
      end;

      RowsReturned:= PQntuples( DBResultSet);

      // Create the field objects if needed
      if( WorkSQLFieldList.Empty()) then begin
         DBFieldCount:= PQnfields( DBResultSet);

         for i:= 0 to DBFieldCount - 1 do begin
            // Get the field name,                 Oid_type, and size
            FieldNameStr:= PQfname( DBResultSet, i);
            FieldSize:= PQfsize( DBResultSet, i);

{$WARNING - Find the OID_ values for each of these and fix the field case statement}
//  You can query the system table pg_type to obtain the names and properties of the various data types
// >psql IPdb2
// IPdb2=# \d pg_type
//       Table "pg_catalog.pg_type"
//     Column     |   Type   | Modifiers
// ---------------+----------+-----------
//  typname       | name     | not null
//  typnamespace  | oid      | not null
//  typowner      | integer  | not null
//  typlen        | smallint | not null
//  typbyval      | boolean  | not null
//  typtype       | "char"   | not null
//  typisdefined  | boolean  | not null
//  typdelim      | "char"   | not null
//  typrelid      | oid      | not null
//  typelem       | oid      | not null
//  typinput      | regproc  | not null
//  typoutput     | regproc  | not null
//  typreceive    | regproc  | not null
//  typsend       | regproc  | not null
//  typalign      | "char"   | not null
//  typstorage    | "char"   | not null
//  typnotnull    | boolean  | not null
//  typbasetype   | oid      | not null
//  typtypmod     | integer  | not null
//  typndims      | integer  | not null
//  typdefaultbin | text     |
//  typdefault    | text     |
//  IPdb2=# select oid, typname, typlen from pg_type;


            // Create the field class
              case PQftype( DBResultSet, i) of
                Oid_Int2:
                      Temp:= dbInt16Field.Create( FieldNameStr);
                Oid_Int4:
                      Temp:= dbInt32Field.Create( FieldNameStr);
                Oid_Int8:
                      Temp:= dbInt64Field.Create( FieldNameStr);
                Oid_Float8:
                      Temp:= dbDoubleField.Create( FieldNameStr);
                Oid_bpchar:
                      Temp:= dbCharField.Create( FieldNameStr, FieldSize);
                Oid_varchar: begin
                         Temp:= dbVarCharField.Create( FieldNameStr, FieldSize);
                         Temp.StoredAsHTML:= StoredAsHTML;
                         Temp.AccessAsHTML:= AccessAsHTML;
                      end;
                Oid_Text: begin
                         Temp:= dbTextField.Create( FieldNameStr);
                         Temp.StoredAsHTML:= StoredAsHTML;
                         Temp.AccessAsHTML:= AccessAsHTML;
                      end;
                Oid_inet:
                      Temp:= dbPgIPAddressField.Create( FieldNameStr);
                Oid_DateTime:
                      Temp:= dbDateTimeField.Create( FieldNameStr);
                Oid_Date:
                      Temp:= dbDateField.Create( FieldNameStr);
                Oid_Time:
                      Temp:= dbTimeField.Create( FieldNameStr);
                Oid_timestamp:
                      Temp:= dbTimeStampField.Create( FieldNameStr);
                Oid_bytea:
                      Temp:= dbTextField.Create( FieldNameStr);
                else begin
                   raise dbFieldException.Create(
                      'PgSQLdbResults.PrivateQuery():  Unknown field type %U!', [PQftype( DBResultSet, i)]);
                end;
             end; // case

            WorkSQLFieldList.Enqueue( Temp);
         end;  // for each field

      end; // if WorkSQLFieldList.Empty
   end; // PrivateQuery()


// *************************************************************************
// * Next() - Get the next record (row).
// *************************************************************************

function PgSQLdbResults.Next(): boolean;
   var
      Temp:          dbField;
      i:             word32;
   begin
      if( DBResultSet = nil) then begin
         result:= false;
         exit;
      end;

      if( (CurrentRowNum < 0) or (CurrentRowNum >= RowsReturned)) then begin
         result:= false;
         exit;
      end;

      Temp:= dbField( WorkSQLFieldList.GetFirst());
      i:= 0;
      while( Temp <> nil) do begin
         Temp.ForceSetValue( PQgetvalue( DBResultSet, CurrentRowNum, i));
         Temp.NoChange();
         inc( i);
         Temp:= dbField( WorkSQLFieldList.GetNext());
      end;

      inc( CurrentRowNum);
      result:= true;
   end; // Next();


// *************************************************************************
// * SetDatabae() - Set the database used.
// *************************************************************************

{$WARNING Continue working here.  Beyond this point needs even more work than that above}

procedure PgSQLdbResults.SetDatabase( dbName: string);
   begin
      if( dbName = '') then begin
         raise SQLdbException.Create(
            'PgSQLdbConnection.SetDatabase():  Database name can not be empty!');
      end;
      Connection.Database:= dbName;
      if( Connection.IsOpen) then begin
         SQLExecute( 'use ' + dbName);
      end;

      DatabaseStr:= dbName;
   end; // SetDatabase()


// *************************************************************************
// * CreateTable()
// *************************************************************************

procedure PgSQLdbResults.CreateTable();
   begin
      raise SQLdbException.Create( 'The Postgres CreateTable() function is not yet implemented.');
   end; // CreateTable()


// *************************************************************************
// * EmptyTable()
// *************************************************************************

procedure PgSQLdbResults.EmptyTable();
   begin
      raise SQLdbException.Create( 'The Postgres EmptyTable() function is not yet implemented.');
   end; // EmptyTable()


// *************************************************************************
// * DropTable()
// *************************************************************************

procedure PgSQLdbResults.DropTable();
   begin
      raise SQLdbException.Create( 'The Postgres DropTable() function is not yet implemented.');
   end; // DropTable()


// *************************************************************************
// * Update()
// *************************************************************************

procedure PgSQLdbResults.Update();
   begin
      raise SQLdbException.Create( 'The Postgres Update() function is not yet implemented.');
   end; // Update()


// *************************************************************************
// * Delete()
// *************************************************************************

procedure PgSQLdbResults.Delete();
   begin
      raise SQLdbException.Create( 'The Postgres Delete() function is not yet implemented.');
   end; // Delete()


// *************************************************************************
// * Insert()
// *************************************************************************

procedure PgSQLdbResults.Insert();
   begin
      raise SQLdbException.Create( 'The Postgres Insert() function is not yet implemented.');
   end; // Insert()


// =========================================================================
// = PgSQLdbHistoryInfoTable
// =========================================================================
// =========================================================================
// = dbHistoryInfoTable
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor PgSQLdbHistoryInfoTable.Create(       iConnection: dbConnection;
                                            const iDatabase:   string;
                                            const TableName:   string);
   begin
      inherited Create( iConnection, iDatabase);
      SQLNameStr:= TableName;
   end; // Create()


// -------------------------------------------------------------------------

constructor PgSQLdbHistoryInfoTable.Create( const iHost:     String;
                                            const iPort:     word16;
                                            const iUser:     String;
                                            const iPassword: String;
                                            const iDatabase: String;
                                            const TableName: string);
   begin
      inherited Create( iHost, iPort, iUser, iPassword, iDatabase);
      SQLNameStr:= TableName;
   end; // Create()


// *************************************************************************
// * InitVars() - Called by create() to initalize this object's variables
// *************************************************************************

procedure PgSQLdbHistoryInfoTable.InitVars();
   begin
      inherited InitVars();

      RelatedID:=  dbWord64Field.Create( 'RelatedID');
      MsgTime:=    dbDateTimeField.Create( 'MsgTime');
      LifeSpan:=   dbWord8Field.Create( 'LifeSpan');
      Message:=    dbTextField.Create( 'Message');

      Fields.Enqueue( ID);
      Fields.Enqueue( RelatedID);
      Fields.Enqueue( MsgTime);
      Fields.Enqueue( LifeSpan);
      Fields.Enqueue( Message);

      // Indexes
      ByRelationIndex:=  dbIndex.Create( 'ByRelationIndex',
                                         [ RelatedID, MsgTime, ID],
                                         '', false);
      ByMsgTimeIndex:=   dbIndex.Create( 'ByMsgTimeIndex', [ MsgTime],
                                       '', true);

      Indexes.Enqueue( IDindex);
      Indexes.Enqueue( ByRelationIndex);
      Indexes.Enqueue( ByMsgTimeIndex);
   end; // InitVars()



// =========================================================================
// = Global procedures
// =========================================================================
// *************************************************************************
// * NewConnection() - Returns a new PgSQLConnection
// *                   Used exclusively by the ConnectionManager
// *************************************************************************

function NewConnection( const iHost:     string;
                        const iPort:     word16;
                        const iUser:     string;
                        const iPassword: string): dbConnection;
   begin
      exit( PgSQLdbConnection.Create( iHost, iPort, iUser, iPassword, ''));
   end; // NewConnection()


// -------------------------------------------------------------------------
// - Unit initialization and finalization
// -------------------------------------------------------------------------
// *************************************************************************
// * Initialization
// *************************************************************************

Initialization
   begin
      lbp_sql_db.ConnectionManager.Register( PgSQLdbType, @NewConnection);
   end;


// *************************************************************************
// * Finalization
// *************************************************************************

Finalization
   begin
   end;


// *************************************************************************

end. // lbp_pgsql_db unit
