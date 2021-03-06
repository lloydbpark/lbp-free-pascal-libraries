{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

supports access to MySQL tables

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

unit lbp_mysql_db;
// Implementation of the lbp_sql_db classes for MySQL

interface
{$include lbp_standard_modes.inc}
{$ifndef windows}
   {$LINKLIB ssl}
   {$LINKLIB mysqlclient_r}
{$endif}

uses
   lbp_types,       // Ordinal types, lbpExceptions
   lbp_sql_db,      // Abstract classes for our classes
   lbp_sql_fields,
   fpopenssl,
   openssl,
//   sslsockets,
//   opensslsockets,
   mysql55;


// ************************************************************************

const
   MySQLdbType = 'MySQL';
   MySQLPortNumber = 3306;

// -------------------------------------------------------------------------

type
   MySQLdbConnection = class( dbConnection)
      protected
         DBHandle:    PMYSQL;
      public
         constructor  Create( const iHost:     string;
                              const iPort:     word16;
                              const iUser:     string;
                              const iPassword: string;
                              const iDatabase: string);
         procedure    Open();            override;
         procedure    Close();           override;
   end; // dbConnection


// -------------------------------------------------------------------------

type
   MySQLdbResults = class( dbResults)
      protected
         DBResultSet:  PMYSQL_RES;
         DBRow:        MYSQL_ROW;
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
         procedure    Query( WhereClause: string);            override;
         procedure    Query();                                override;
         function     Next(): boolean;                        override;
         function     GetLastInsertID: int64;                 override;
      protected
         procedure    PrivateQuery( QueryStr: string);  virtual;
         procedure    SetDatabase( dbName: string);     override;
      end; // MySQLdbResults()


// -------------------------------------------------------------------------

type
   MySQLdbHistoryInfoTable = class( MySQLdbResults)
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
   end; // MySQLdbHistoryInfoTable


// ************************************************************************

implementation

// ========================================================================
// = MySQLdbConnection   - Holds the database handle
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor MySQLdbConnection.Create( const iHost:     string;
                                      const iPort:     word16;
                                      const iUser:     string;
                                      const iPassword: string;
                                      const iDatabase: string);
   var
      TempPort:     word16;
   begin
      if( iHost = '') then begin
         raise lbp_exception.Create(
            'MySQLdbConnection.Open():  Host name can not be empty!');
      end;

      if( iPort = 0) then begin
         TempPort:= 3306;
      end else begin
         TempPort:= iPort;
      end;

      if( iUser = '') then begin
         raise lbp_exception.Create(
            'MySQLdbConnection.Open():  User name can not be empty!');
      end;

      inherited Create( MySQLdbType, iHost, TempPort,
                        iUser, iPassword, IDatabase);
   end; // Create()


// ************************************************************************
// Open() - Open the connection
// ************************************************************************

procedure MySQLdbConnection.Open();
   var
      TempPassword: pointer;
      TempDatabase: pointer;
      ConnResult:   pointer;
   begin
      if( Opened) then begin
         exit;
      end;

      DBHandle:= mysql_init( nil);
      if( DBHandle = nil) then begin
         raise SQLdbCriticalException.Create(
            'MySQLdbConnection.Open():  Unable to allocate a new MySQL handle!');
      end;


      if( PasswordStr = '') then begin
         TempPassword:= nil;
      end else begin
         TempPassword:= @PasswordStr[ 1];
      end;

      if( DatabaseStr = '') then begin
         TempDatabase:= nil;
      end else begin
         TempDatabase:= @DatabaseStr[ 1]
      end;

      // Connect to the server
      InUse:= true;
      ConnResult:= mysql_real_connect( DBHandle, @HostStr[1], @UserStr[ 1],
                                       TempPassword, TempDatabase, PortW16,
                                       nil, 0);
      InUse:= false;
      if( ConnResult = nil) then begin
         raise SQLdbException.Create( mysql_error( dbHandle));
      end;

      Opened:= true;
   end; // Open()


// ************************************************************************
// Close() - Close the connection
// ************************************************************************

procedure MySQLdbConnection.Close();
   begin
      if( Opened) then begin
         mysql_close( DBHandle);
         Opened:= false;
      end;
      InUse:= false; // just to make sure
   end; // Close()


// -------------------------------------------------------------------------
// - MySQLdbResults
// -------------------------------------------------------------------------
// *************************************************************************
// Create() - Constructor
// *************************************************************************

constructor MySQLdbResults.Create(       iConnection: dbConnection;
                                   const iDatabase: string);
   begin
      inherited Create( iConnection, iDatabase);
      DBRow:= nil;
      DBResultSet:= nil;
   end; // Create()


// -------------------------------------------------------------------------

constructor MySQLdbResults.Create( const iHost:     String;
                                   const iPort:     word16;
                                   const iUser:     String;
                                   const iPassword: String;
                                   const iDatabase: String);
   begin
      inherited Create( MySQLdbType, iHost, iPort, iUser,
                        iPassword, iDatabase);
      DBRow:= nil;
   end; // Create();


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor MySQLdbResults.Destroy();
   begin
      if( DBResultSet <> nil) then begin
         mysql_free_result( DBResultSet);
         DBResultSet:= nil;
      end;
      inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * GetLastInsertID()
// *************************************************************************

function MySQLdbResults.GetLastInsertID(): int64;
   begin
      Connection.InUse:= true;
      result:= mysql_insert_id( MySQLdbConnection( Connection).DBHandle);
      Connection.InUse:= false;
   end; // GetLastInsertID()


// *************************************************************************
// * EscapeString() - Escape strings for SQL queries using MySQL's
// *                  conventions.
// *************************************************************************

function MySQLdbResults.EscapeString( const S: string): string;
   var
      Temp: string;
      L:    Word32;
   begin
      // This is bizare, but the MySQL Escape function relies on the connection being open
      if( not Connection.IsOpen) then begin
         Connection.Open();
      end;

      L:= Length( S);
      if( L = 0) then begin
         result:= '';
      end else begin
         SetLength( Temp, L * 2);  // Make room in Temp for the maximum size
         L:= mysql_real_escape_string( MySQLdbConnection( Connection).DBHandle,
                                       @Temp[ 1], @S[ 1], L);
         SetLength( Temp, L);
         result:= Temp;
      end;
   end; // EscapeString()



// *************************************************************************
// * SQLExecute() - Perform a Non-query SQL command
// *************************************************************************

procedure MySQLdbResults.SQLExecute( QueryStr: string);
   var
      DBHandle:    PMYSQL;
   begin

      if( not Connection.IsOpen) then begin
         Connection.Open();
      end;

      DBHandle:= MySQLdbConnection( Connection).DBHandle;

      if( mysql_real_query( DBHandle, @QueryStr[ 1],
                            Length( QueryStr)) <> 0) then begin
         raise SQLdbException.Create( mysql_error( DBHandle));
      end;

   end; // SQLExecute()


// *************************************************************************
// * SQLQuery() - Perform an SQL query command
// *************************************************************************

procedure MySQLdbResults.SQLQuery( QueryStr: string);
   begin
      EmptySQLFieldList( AutoSQLFieldList);
      WorkSQLFieldList:= AutoSQLFieldList;

      PrivateQuery( QueryStr);
   end; // SQLQuery()


// *************************************************************************
// * Query() - Perform a query on the default table
// *************************************************************************

procedure MySQLdbResults.Query( WhereClause: string);
   begin
      if( Fields.Empty()) then begin
         raise SQLdbException.Create(
            'Don''t use Query() when you haven''t set created default fields!');
      end;

      WorkSQLFieldList:= Fields;

      PrivateQuery( GetSQLQuery() + ' ' + WhereClause);
   end; // SQLQuery()


// ------------------------------------------------------------------------

procedure MySQLdbResults.Query();
   begin
      if( Fields.Empty()) then begin
         raise SQLdbException.Create(
            'Don''t use Query() when you haven''t set created default fields!');
      end;

      WorkSQLFieldList:= Fields;

      PrivateQuery( GetSQLQuery());
   end; // SQLQuery()


// *************************************************************************
// * PrivateQuery() - Does the actual query
// *************************************************************************

procedure MySQLdbResults.PrivateQuery( QueryStr: string);
   var
      DBFieldDef:   PMYSQL_FIELD;
      DBFieldCount: Word32;
      DBHandle:     PMYSQL;
      i:            Word32;
      FieldNameStr: string;
      Temp:         dbField;
   begin
      if( length( QueryStr) = 0) then begin
         raise SQLdbException.Create(
            'Attempt to execute an empty SQL command!');
      end;

      // Get rid of the previous result set if needed.
      if( DBResultSet <> nil) then begin
         mysql_free_result( DBResultSet);
         DBResultSet:= nil;
      end;

      // Clear any pointers to the previous row so Next() works.
      DBRow:= nil;

      if( not Connection.IsOpen) then begin
         Connection.Open();
      end;

      DBHandle:= MySQLdbConnection( Connection).DBHandle;
      Connection.InUse:= true;
      try
         if( mysql_real_query( DBHandle, @QueryStr[ 1],
                               Length( QueryStr)) <> 0) then begin
            raise SQLdbException.Create( mysql_error( DBHandle));
         end;

         // Fetch all the rows from the server
         DBResultSet:= mysql_store_result( DBHandle);
         if( (DBResultSet = nil) and (mysql_errno( DBHandle) <> 0)) then begin
            raise SQLdbException.Create( mysql_error( DBHandle));
         end;
      finally
         Connection.InUse:= false;
      end; // try/finally

      // Create the field objects if needed
      if( WorkSQLFieldList.Empty()) then begin
         DBFieldCount:= mysql_num_fields( DBResultSet);

//         writeln( 'Debug MySQLdbResults.PrivateQuery():  FIELD_TYPE = ', ord( FIELD_TYPE_NEWDATE));
         for i:= 0 to DBFieldCount - 1 do begin
            DBFieldDef:= mysql_fetch_field_Direct( DBResultSet, i);
//            writeln( 'Debug MySQLdbResults.PrivateQuery():  ', DBFieldDef^.name, ' - ', ord( DBFieldDef^._type));
         end;

         for i:= 0 to DBFieldCount - 1 do begin
            // Get the field name, type, and size
            DBFieldDef:= mysql_fetch_field_Direct( DBResultSet, i);
            if( DBFieldDef^.table = '') then begin
               FieldnameStr:= DBFieldDef^.name;
            end else begin
               FieldNameStr:= DBFieldDef^.table + '.' + DBFieldDef^.name
            end;

            // Create the field class
             case DBFieldDef^.ftype of
               FIELD_TYPE_TINY:
                     Temp:= dbWord8Field.Create( FieldNameStr);
               FIELD_TYPE_LONG:
                     if( (DBFieldDef^.flags and UNSIGNED_FLAG) <> 0) then begin
                        Temp:= dbWord32Field.Create( FieldNameStr);
                     end else begin
                        Temp:= dbInt32Field.Create( FieldNameStr);
                     end;
               FIELD_TYPE_LONGLONG:
                     if( (DBFieldDef^.flags and UNSIGNED_FLAG) <> 0) then begin
                        Temp:= dbWord64Field.Create( FieldNameStr);
                     end else begin
                        Temp:= dbInt64Field.Create( FieldNameStr);
                     end;
               FIELD_TYPE_DECIMAL:
                     Temp:= dbDoubleField.Create( FieldNameStr);
               FIELD_TYPE_STRING:
                     Temp:= dbCharField.Create( FieldNameStr, DBFieldDef^.length);
               FIELD_TYPE_VAR_STRING:
                     Temp:= dbVarCharField.Create( FieldNameStr, DBFieldDef^.length);
               FIELD_TYPE_DATETIME:
                     Temp:= dbDateTimeField.Create( FieldNameStr);
               FIELD_TYPE_DATE:
                     Temp:= dbDateField.Create( FieldNameStr);
               FIELD_TYPE_TIME:
                     Temp:= dbTimeField.Create( FieldNameStr);
               FIELD_TYPE_TIMESTAMP:
                     Temp:= dbTimeStampField.Create( FieldNameStr);
               FIELD_TYPE_BLOB:
                     Temp:= dbTextField.Create( FieldNameStr);
               else begin
                  raise dbFieldException.Create(
                     'MySQLdbResults.PrivateQuery():  Unknown field type!');
               end;
            end; // case

            WorkSQLFieldList.Enqueue( Temp);
         end;  // for each field

      end; // if WorkSQLFieldList.Empty
   end; // PrivateQuery()


// *************************************************************************
// * Next() - Get the next record (row).
// *************************************************************************

function MySQLdbResults.Next(): boolean;
   var
      Temp:          dbField;
      i:             word32;
   begin
      if( DBResultSet = nil) then begin
         result:= false;
         exit;
      end;

      DBRow:= mysql_fetch_row( DBResultSet);
      if( DBRow = nil) then begin
         result:= false;
         exit;
      end;

      Temp:= dbField( WorkSQLFieldList.GetFirst());
      i:= 0;
      while( Temp <> nil) do begin
         Temp.ForceSetValue( DBRow[ i]);
         Temp.NoChange();
         inc( i);
         Temp:= dbField( WorkSQLFieldList.GetNext());
      end;

      result:= true;
   end; // Next();

// *************************************************************************
// * SetDatabae() - Set the database used.
// *************************************************************************

procedure MySQLdbResults.SetDatabase( dbName: string);
   begin
      if( dbName = '') then begin
         raise SQLdbException.Create(
            'MySQLdbConnection.SetDatabase():  Database name can not be empty!');
      end;
      Connection.Database:= dbName;
      if( Connection.IsOpen) then begin
         SQLExecute( 'use ' + dbName);
      end;

      DatabaseStr:= dbName;
   end; // SetDatabase()


// =========================================================================
// = MySQLdbHistoryInfoTable
// =========================================================================
// =========================================================================
// = dbHistoryInfoTable
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor MySQLdbHistoryInfoTable.Create(       iConnection: dbConnection;
                                            const iDatabase:   string;
                                            const TableName:   string);
   begin
      inherited Create( iConnection, iDatabase);
      SQLNameStr:= TableName;
   end; // Create()


// -------------------------------------------------------------------------

constructor MySQLdbHistoryInfoTable.Create( const iHost:     String;
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

procedure MySQLdbHistoryInfoTable.InitVars();
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
// * NewConnection() - Returns a new MySQLConnection
// *                   Used exclusively by the ConnectionManager
// *************************************************************************

function NewConnection( const iHost:     string;
                        const iPort:     word16;
                        const iUser:     string;
                        const iPassword: string): dbConnection;
   begin
      result:= MySQLdbConnection.Create( iHost, iPort, iUser, iPassword, '');
   end; // NewConnection()


// -------------------------------------------------------------------------
// - Unit initialization and finalization
// -------------------------------------------------------------------------
// *************************************************************************
// * Initialization
// *************************************************************************

Initialization
   begin
      lbp_sql_db.ConnectionManager.Register( MySQLdbType, @NewConnection);
   end;


// *************************************************************************
// * Finalization
// *************************************************************************

Finalization
   begin
   end;


// *************************************************************************

end. // lbp_mysql_db unit
