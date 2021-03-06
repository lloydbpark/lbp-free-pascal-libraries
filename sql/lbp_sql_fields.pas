{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Defines classes to hold some standard SQL fields

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
{$WARNING remove the dependence on Http encode/decode.  That was a leftover to support HTTP values in fields}
unit lbp_sql_fields;

interface
{$include lbp_standard_modes.inc}

uses
   sysutils,           // Format(), Now() for Windows
   httpdefs,           // Http Encode/Decode
   lbp_utils,         // IP String to cardinal, etc.
   lbp_ip_utils,      // IP and MAC conversions
   lbp_current_time,  // CurrentTime access.
   lbp_lists,
   lbp_types,         // int32, etc
   lbp_vararray;      // variable length arrays.


// *************************************************************************
// * Field types
// *************************************************************************

const
   BitSetNone:   word64 = 0;
   BitSetRead:   word64 = 1;
   BitSetWrite:  word64 = 2;
   BitSetCreate: word64 = 4;

   NICSize: byte = 12;
var
   BitSetAll:    word64;

type
   EscapeStringFunction = function( const S: string): string of object;

// *************************************************************************
// * MySQL Fields
// *************************************************************************
type

   dbFieldException = class( lbp_exception);

   dbField = class
      private
         MyStoredAsHTML: boolean;
         MyAccessAsHTML: boolean;
         AddOnEscapeString: EscapeStringFunction;
         function     DefaultEscapeString( const S: string): string;
      public
         constructor  Create( Name: string);
         destructor   Destroy();                  override;
         procedure    NoChange();                 virtual; abstract;
         function     HasChanged():      boolean; virtual;
         function     EscapeString( const S: string): string; virtual;
         function     CheckValidity( InputValue: string):  string;  virtual;
         procedure    SetValue( InputValue: string);       virtual; abstract;
         procedure    ForceSetValue( InputValue: string);  virtual; abstract;
         function     GetValue():        string;  virtual; abstract;
         function     GetOrigValue():    string;  virtual; abstract;
         procedure    Clear();                    virtual; abstract;
         procedure    RestoreValue();             virtual; abstract;
         function     GetSQLValue():     string;  virtual; abstract;
         function     GetSQLOrigValue(): string;  virtual; abstract;
         function     GetSQLCreate():    string;  virtual; abstract;
         function     GetSQLName():      string;  virtual;
         procedure    SetSQLName( Name: string);  virtual;
         procedure    SetEscapeStringFunction( F: EscapeStringFunction); virtual;
         property     StoredAsHTML: boolean read MyStoredAsHTML write MyStoredAsHTML;
         property     AccessAsHTML: boolean read MyAccessAsHTML write MyAccessAsHTML;
//         function     IsAuthorized( const Auth: Authenticator; const Check: integer); virtual;
      private
         HasChangedFlag: boolean;
         SQLName:        string;
         SQLCreate:      string;
      end; // dbField


// =========================================================================

   dbInt16Field = class( dbField)
      public
         OrigValue:   int16;
         NewValue:    int16;
         MaxValue:    int16;
         MinValue:    int16;
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         constructor  Create( Name: string; SQLCreateParams: string;
                              LowerBound: int16; UpperBound: int16);
         procedure    NoChange();                 override;
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetValue( InputValue: int16);       virtual;
         procedure    SetValue( InputValue: string);      override;
         procedure    ForceSetValue( InputValue: string); override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    Clear();                    override;
         procedure    RestoreValue();             override;
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbInt16Field


// =========================================================================

   dbWord16Field = class( dbField)
      public
         OrigValue:   word16;
         NewValue:    word16;
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         procedure    NoChange();                 override;
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetValue( InputValue: word16);      virtual;
         procedure    SetValue( InputValue: string);      override;
         procedure    ForceSetValue( InputValue: string); override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    Clear();                    override;
         procedure    RestoreValue();             override;
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbWord16Field


// =========================================================================

   dbInt32Field = class( dbField)
      public
         OrigValue:   int32;
         NewValue:    int32;
         MaxValue:    int32;
         MinValue:    int32;
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         constructor  Create( Name: string; SQLCreateParams: string;
                              LowerBound: int32; UpperBound: int32);
         procedure    NoChange();                 override;
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetValue( InputValue: int32);       virtual;
         procedure    SetValue( InputValue: string);      override;
         procedure    ForceSetValue( InputValue: string); override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    Clear();                    override;
         procedure    RestoreValue();             override;
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbInt32Field


// =========================================================================

   dbWord32Field = class( dbField)
      public
         OrigValue:   word32;
         NewValue:    word32;
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         procedure    NoChange();                 override;
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetValue( InputValue: word32);      virtual;
         procedure    SetValue( InputValue: string);      override;
         procedure    ForceSetValue( InputValue: string); override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    Clear();                    override;
         procedure    RestoreValue();             override;
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbWord32Field


// =========================================================================

   // Fixed length string
   dbCharField = class( dbField)
      public
         OrigValue:   string;
         NewValue:    string;
         Size:        int32;
         constructor  Create( Name: string; iSize: int32);
         constructor  Create( Name: string; SQLCreateParams: string;
                              iSize: int32);
         procedure    NoChange();                 override;
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetValue( InputValue: string);      override;
         procedure    ForceSetValue( InputValue: string); override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    Clear();                    override;
         procedure    RestoreValue();             override;
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbCharField


// =========================================================================

   // Variable length string with a maximum length.
   dbVarCharField = class( dbCharField)
      public
         constructor  Create( Name: string; iSize: int32);
         constructor  Create( Name: string; SQLCreateParams: string;
                              iSize: int32);
         function     CheckValidity( InputValue: string):   string;  override;
//         procedure    SetValue( InputValue: string);      override;
         procedure    Clear();                    override;
         function     GetSQLCreate():    string;  override;
      end; // dbVarCharField


// =========================================================================

   dbWord8Field = class( dbField)
      public
         OrigValue:   word8;
         NewValue:    word8;
         MaxValue:    word8;
         MinValue:    word8;
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         constructor  Create( Name: string; SQLCreateParams: string;
                              LowerBound: word8; UpperBound: word8);
         procedure    NoChange();                 override;
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetValue( InputValue: word8);       virtual;
         procedure    SetValue( InputValue: string);      override;
         procedure    ForceSetValue( InputValue: string); override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    Clear();                    override;
         procedure    RestoreValue();             override;
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbWord8Field


// =========================================================================

   dbInt64Field = class( dbField)
      public
         OrigValue:   int64;
         NewValue:    int64;
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         procedure    NoChange();                 override;
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetValue( InputValue: int64);       virtual;
         procedure    SetValue( InputValue: string);      override;
         procedure    ForceSetValue( InputValue: string); override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    Clear();                    override;
         procedure    RestoreValue();             override;
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbInt64Field


// =========================================================================

   dbWord64Field = class( dbField)
      public
         OrigValue:   word64;
         NewValue:    word64;
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         procedure    NoChange();                 override;
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetValue( InputValue: word64);      virtual;
         procedure    SetValue( InputValue: string);      override;
         procedure    ForceSetValue( InputValue: string); override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    Clear();                    override;
         procedure    RestoreValue();             override;
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbWord64Field


// =========================================================================

   dbDoubleField = class( dbField)
      public
         OrigValue:   Double;
         NewValue:    Double;
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         procedure    NoChange();                 override;
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetValue( InputValue: Double);       virtual;
         procedure    SetValue( InputValue: string);      override;
         procedure    ForceSetValue( InputValue: string); override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    Clear();                    override;
         procedure    RestoreValue();             override;
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbDoubleField


// =========================================================================

   dbBitSetField = class( dbWord64Field)
      public
         Descriptions: DoubleLinkedList; // list of dription strings
         BitValues:    Word64Array;      // The bit value which matches the
                                         // dription.
         constructor   Create( Name: string);
         constructor   Create( Name: string; SQLCreateParams: string);
         destructor    Destroy; override;
         procedure     VarInit(); virtual;
         procedure     SetBit( BitPattern: word64; Value: boolean); virtual;
         function      GetBit( BitPattern: word64): boolean; virtual;
      protected
         procedure     AddDescription( S: string);
      end; // dbBitSetField


// =========================================================================

   dbBooleanField = class( dbField)
      public
         OrigValue:   boolean;
         NewValue:    boolean;
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         procedure    NoChange();                 override;
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetValue( InputValue: boolean);     virtual;
         procedure    SetValue( InputValue: int32);       virtual;
         procedure    SetValue( InputValue: string);      override;
         procedure    ForceSetValue( InputValue: string); override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    Clear();                    override;
         procedure    RestoreValue();             override;
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbBooleanField


// =========================================================================

   dbDateTimeField = class( dbCharField)
      protected
         CheckString: string;
      public
         NowOnNull:   boolean; // when the input is empty, return now()
         constructor  Create( Name: string);
         function     CheckValidity( InputValue: string):   string;  override;
         procedure    SetToNow(); virtual;
         function     Now(): string; virtual;
         procedure    ForceSetValue( InputValue: string); override;
         procedure    Clear();                    override;
         function     GetSQLCreate():    string;  override;
      end; // dbDateTimeField


// =========================================================================

   dbDateField = class( dbDateTimeField)
      public
         constructor  Create( Name: string);
         function     Now(): string; override;
         function     GetSQLCreate():    string;  override;
      end; // dbDateField


// =========================================================================

   dbTimeField = class( dbDateTimeField)
      public
         constructor  Create( Name: string);
         function     Now(): string; override;
         function     GetSQLCreate():    string;  override;
      end; // dbTimeField


// =========================================================================

   dbTimestampField = class( dbDateTimeField)
      public
         constructor  Create( Name: string);
         function     Now(): string; override;
         function     GetSQLCreate():    string;  override;
      end; // dbTimestampField


// =========================================================================

   // Variable length string without a maximum length.
   dbTextField = class( dbVarCharField)
      public
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         function     GetSQLCreate():    string;  override;
      end; // dbTextField


// =========================================================================

   dbIPAddressField = class( dbWord32Field)
      private
         NumberOfOctets: integer;
      public
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         constructor  Create( Name: string; NumOctets: integer);
         constructor  Create( Name: string; NumOctets: integer;
                              SQLCreateParams: string);
         class function     StringToWord32( const S: String): word32; virtual;
         class function     Word32ToString( const X: word32): string; virtual;
         class function     Word32ToReverseString( const X: word32):    string; virtual;
         class function     IPAddressToNIC( const IPAddress: word32): string;    virtual;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    SetValue( InputValue: string);  override;
         procedure    SetValue( InputValue: word32);  override;
         procedure    ForceSetValue( InputValue: string); override;
      end; // dbIPAddressField


// =========================================================================

   dbPgIPAddressField = class( dbIPAddressField) // Postgres version
      public
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
      end; // dbPgIPAddressField


// =========================================================================

   dbNICAddressField = class( dbWord64Field)
      public
         constructor  Create( Name: string);
         constructor  Create( Name: string; SQLCreateParams: string);
         class function     RemoveNonHexCharacters( const S: String): String; virtual;
         class function     InsertSeparators( S:     String;
                                              C:     char;
                                              Count: int32): String; virtual;
         class function     InsertSeparators( S: String): String; virtual;
         class function     StringToWord64( const S: String): word64; virtual;
         class function     Word64ToString( const X: word64): string; virtual;
         class function     Word64ToString( const X: word64;
                                            C:     char;
                                            Count: int32): string; virtual;
         function     CheckValidity( InputValue: string):   string;  override;
         function     GetValue():        string;  override;
         function     GetOrigValue():    string;  override;
         procedure    SetValue( InputValue: string);  override;
         procedure    SetValue( InputValue: word64);  override;
      end; // dbNICAddresField


// =========================================================================

   dbPgMACAddressField = class( dbNICAddressField) // Postgres version
      public
         function     GetSQLValue():     string;  override;
         function     GetSQLOrigValue(): string;  override;
         function     GetSQLCreate():    string;  override;
         procedure    ForceSetValue( InputValue: string); override;
      end; // dbPgMACAddressField


// ************************************************************************

implementation

const
   EscapeCharacters =  '\''"' + chr( 0) + chr( 10) + chr( 13);
   ReplaceCharacters = '\''"' + '0'     + 'n'      + 'r';
   DefaultIPNumberOfOctets = 4;


// ========================================================================
// = dbField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbField.Create( Name: string);
   begin
      HasChangedFlag:= false;
      SQLName:= Name;
      SQLCreate:= ' not null';
      MyStoredAsHTML:= false;
      MyAccessAsHTML:= false;
      AddOnEscapeString:= nil;
   end; // Constructor


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor dbField.Destroy();
   begin
      SQLName:= '';
      SQLCreate:= '';
   end; // Destructor


// *************************************************************************
// * HasChanged() - True if the field has changed since the last call to
// *                NoChange().
// *************************************************************************

function dbField.HasChanged(): boolean;
  begin
     HasChanged:= HasChangedFlag;
  end; // HasChanged()


// ************************************************************************
// * DefaultEscapeString() - Replace some ascii characters with '/' sequences.
// ************************************************************************

function dbField.DefaultEscapeString( const S: string): string;
   var
      Temp:     string;
      i:        int32;
      iTemp:    int32;
      TempSize: int32;
      SSize:    int32;
      Position: int32;
   begin
      SSize:= Length( S);
      TempSize:= SSize;
      SetLength( Temp, TempSize);
      iTemp:= 1;
      for i:= 1 to Length( S) do begin
         Position:= Pos( S[ i], EscapeCharacters);
         if( Position > 0) then begin
            inc( TempSize);
            SetLength( Temp, TempSize);
            Temp[ iTemp]:= '\';
            inc( iTemp);
            Temp[ iTemp]:= ReplaceCharacters[ Position];
         end else begin
            Temp[ iTemp]:= S[ i];
         end;
         inc( iTemp);
      end; // for

      result:= Temp;
   end; // DefaultEscapeString()


// ************************************************************************
// * EscapeString() - Replace some ascii characters with '/' sequences.
// ************************************************************************

function dbField.EscapeString( const S: string): string;
   begin
      if( AddOnEscapeString <> nil) then begin
         result:= AddOnEscapeString( S);
      end else begin
         result:= DefaultEscapeString( S);
      end;
   end; // EscapeString()


// *************************************************************************
// *  CheckValidity() Check to make sure the input data is valid for
// *                 this field.  Also may perform manipulation of the
// *                 input data such as removing trailing spaces, etc.
// *                 The modified input data is returned and can be
// *                 used to set the underlying OrigValue of the field.
// *************************************************************************

function dbField.CheckValidity( InputValue: string): string;
   begin
      CheckValidity:= InputValue;
   end; // CheckValidity()


// *************************************************************************
// * GetSQLName() - Return the SQL Field name.
// *************************************************************************

function dbField.GetSQLName(): string;
   begin
      GetSQLName:= SQLName;
   end; // GetSQLName();


// *************************************************************************
// * SetSQLName() - Set the SQL Field name.
// *************************************************************************

procedure dbField.SetSQLName( Name: string);
   begin
      SQLName:= Name;
   end; // GetSQLName();


// *************************************************************************
// * SetEscapeStringFunction()
// *************************************************************************

procedure dbField.SetEscapeStringFunction( F: EscapeStringFunction);
   begin
      AddOnEscapeString:= F;
   end; // SetEscapeStringFunction();


// ========================================================================
// = dbInt16Field
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbInt16Field.Create( Name: string);
   begin
      inherited Create( Name);
      OrigValue:= 0;
      NewValue:= 0;
      MaxValue:= MaxInt16;
      MinValue:= MinInt16;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbInt16Field.Create( Name: string; SQLCreateParams: string);
   begin
      Create( Name);
      SQLCreate:= SQLCreateParams;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbInt16Field.Create( Name: string; SQLCreateParams: String;
                                 LowerBound: int16; UpperBound: int16);
   begin
      inherited Create( Name);
      SQLCreate:= SQLCreateParams;
      MaxValue:=  UpperBound;
      MinValue:=  LowerBound;
   end; // Constructor


// *************************************************************************
// * NoChange() - Sets the HasChanged() value to false.  This should be
// *              called after the value of the field has been read from
// *              from the SQL database.
// *************************************************************************

procedure dbInt16Field.NoChange();
   begin
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // NoChange


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbInt16Field.CheckValidity( InputValue: String): string;
   var
      TempI:      int32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not an integer value!');
      end;

      // Bounds test
      if( (TempI > MaxValue) or (TempI < MinValue)) then begin
         raise dbFieldException.Create(
           '%s: The input values is outside the range %d to %d',
           [SQLName, MinValue, MaxValue]);
      end;

      CheckValidity:= TempS;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

procedure dbInt16Field.SetValue( InputValue: int16);
   begin
      NewValue:= InputValue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbInt16Field.SetValue( InputValue: string);
   var
      TempI:      int32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= CheckValidity( InputValue);

      // Do the conversion.  No need to check ResultCode because it already
      // worked once in ValidityCheck()
      Val( TempS, TempI, ResultCode);
      // The if statement below just prevents a compiler Note from displaying.
      if( ResultCode <> 0) then begin
         ResultCode:= 0;
      end;

      NewValue:= int16( TempI);
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() Sets the value of the field from a string as in
// *                 SetValue() except no call to CheckValidity() is
// *                 is made.  This function will be used by dbTables
// *                 to set OrigValues from data in the SQL results.
// *                 In this case it does away with the bounds check.
// *************************************************************************

procedure dbInt16Field.ForceSetValue( InputValue: string);
   var
      TempI:      int32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not an integer value!');
      end;

      NewValue:= Int16( TempI);
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue();


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbInt16Field.GetValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetValue:= Temp;
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbInt16Field.GetOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetOrigValue:= Temp;
   end; // GetOrigValue();


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbInt16Field.Clear();
   begin
      NewValue:= 0;
   end; // Clear()


// *************************************************************************
// *  RestoreValue() - Restore original value an set HasChanged() to false.
// *************************************************************************

procedure dbInt16Field.RestoreValue();
   begin
      NewValue:= OrigValue;
      HasChangedFlag:= false;
   end; // RestoreValue()


// *************************************************************************
// * GetSQLValue() - Used to get the field's value as it would appear
// *                 in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbInt16Field.GetSQLValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetSQLValue:= Temp;
   end; // GetSQLValue()


// *************************************************************************
// * GetSQLOrigValue() - Used to get the field's original value as it would
// *                     appear in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbInt16Field.GetSQLOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetSQLOrigValue:= Temp;
   end; // GetSQLOrigValue()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbInt16Field.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'integer ' + SQLCreate;
   end; // GetSQLCreate()


// ========================================================================
// = dbWord16Field
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbWord16Field.Create( Name: string);
   begin
      inherited Create( Name);
      OrigValue:= 0;
      NewValue:= 0;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbWord16Field.Create( Name: string; SQLCreateParams: string);
   begin
      Create( Name);
      SQLCreate:= SQLCreateParams;
   end; // Constructor


// *************************************************************************
// * NoChange() - Sets the HasChanged() value to false.  This should be
// *              called after the value of the field has been read from
// *              from the SQL database.
// *************************************************************************

procedure dbWord16Field.NoChange();
   begin
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // NoChange


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbWord16Field.CheckValidity( InputValue: String): string;
   var
      TempI:      Int32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( (ResultCode <> 0) or (TempI > Int32( $FFFF)) or
          (TempI < 0)) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a 16 bit word value!');
      end;

      CheckValidity:= TempS;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

procedure dbWord16Field.SetValue( InputValue: Word16);
   begin
      NewValue:= InputValue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbWord16Field.SetValue( InputValue: string);
   var
      TempI:      Word32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= CheckValidity( InputValue);

      // Do the conversion.  No need to check ResultCode because it already
      // worked once in ValidityCheck()
      Val( TempS, TempI, ResultCode);
      // This if statement is just to quiet a compiler Note about ResultCode
      //    not being used.
      if( ResultCode <> 0) then begin
         ResultCode:= 0;
      end;

      NewValue:= Word16( TempI);
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() Sets the value of the field from a string as in
// *                 SetValue() except no call to CheckValidity() is
// *                 is made.  This function will be used by dbTables
// *                 to set OrigValues from data in the SQL results.
// *                 In this case it does away with the bounds check.
// *************************************************************************

procedure dbWord16Field.ForceSetValue( InputValue: string);
   var
      TempI:      Word32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a 16 bit word value!');
      end;

      NewValue:= Word16( TempI);
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue();


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbWord16Field.GetValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetValue:= Temp;
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbWord16Field.GetOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetOrigValue:= Temp;
   end; // GetOrigValue();


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbWord16Field.Clear();
   begin
      NewValue:= 0;
   end; // Clear()


// *************************************************************************
// *  RestoreValue() - Restore original value an set HasChanged() to false.
// *************************************************************************

procedure dbWord16Field.RestoreValue();
   begin
      NewValue:= OrigValue;
      HasChangedFlag:= false;
   end; // RestoreValue()


// *************************************************************************
// * GetSQLValue() - Used to get the field's value as it would appear
// *                 in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbWord16Field.GetSQLValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetSQLValue:= Temp;
   end; // GetSQLValue()


// *************************************************************************
// * GetSQLOrigValue() - Used to get the field's original value as it would
// *                     appear in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbWord16Field.GetSQLOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetSQLOrigValue:= Temp;
   end; // GetSQLOrigValue()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbWord16Field.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'bigint unsigned ' + SQLCreate;
   end; // GetSQLCreate()


// ========================================================================
// = dbInt32Field
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbInt32Field.Create( Name: string);
   begin
      inherited Create( Name);
      OrigValue:= 0;
      NewValue:= 0;
      MaxValue:= MaxInt32;
      MinValue:= MinInt32;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbInt32Field.Create( Name: string; SQLCreateParams: string);
   begin
      Create( Name);
      SQLCreate:= SQLCreateParams;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbInt32Field.Create( Name: string; SQLCreateParams: String;
                                 LowerBound: int32; UpperBound: int32);
   begin
      inherited Create( Name);
      SQLCreate:= SQLCreateParams;
      MaxValue:=  UpperBound;
      MinValue:=  LowerBound;
   end; // Constructor


// *************************************************************************
// * NoChange() - Sets the HasChanged() value to false.  This should be
// *              called after the value of the field has been read from
// *              from the SQL database.
// *************************************************************************

procedure dbInt32Field.NoChange();
   begin
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // NoChange


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbInt32Field.CheckValidity( InputValue: String): string;
   var
      TempI:      int32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not an integer value!');
      end;

      // Bounds test
      if( (TempI > MaxValue) or (TempI < MinValue)) then begin
         raise dbFieldException.Create(
           '%s: The input values is outside the range %d to %d',
           [SQLName, MinValue, MaxValue]);
      end;

      CheckValidity:= TempS;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

procedure dbInt32Field.SetValue( InputValue: int32);
   begin
      NewValue:= InputValue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbInt32Field.SetValue( InputValue: string);
   var
      TempI:      int32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= CheckValidity( InputValue);

      // Do the conversion.  No need to check ResultCode because it already
      // worked once in ValidityCheck()
      Val( TempS, TempI, ResultCode);
      // This if statement is just to quiet a compiler Note about ResultCode
      //    not being used.
      if( ResultCode <> 0) then begin
         ResultCode:= 0;
      end;

      NewValue:= TempI;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() Sets the value of the field from a string as in
// *                 SetValue() except no call to CheckValidity() is
// *                 is made.  This function will be used by dbTables
// *                 to set OrigValues from data in the SQL results.
// *                 In this case it does away with the bounds check.
// *************************************************************************

procedure dbInt32Field.ForceSetValue( InputValue: string);
   var
      TempI:      int32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not an integer value!');
      end;

      NewValue:= TempI;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue();


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbInt32Field.GetValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetValue:= Temp;
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbInt32Field.GetOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetOrigValue:= Temp;
   end; // GetOrigValue();


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbInt32Field.Clear();
   begin
      NewValue:= 0;
   end; // Clear()


// *************************************************************************
// *  RestoreValue() - Restore original value an set HasChanged() to false.
// *************************************************************************

procedure dbInt32Field.RestoreValue();
   begin
      NewValue:= OrigValue;
      HasChangedFlag:= false;
   end; // RestoreValue()


// *************************************************************************
// * GetSQLValue() - Used to get the field's value as it would appear
// *                 in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbInt32Field.GetSQLValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetSQLValue:= Temp;
   end; // GetSQLValue()


// *************************************************************************
// * GetSQLOrigValue() - Used to get the field's original value as it would
// *                     appear in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbInt32Field.GetSQLOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetSQLOrigValue:= Temp;
   end; // GetSQLOrigValue()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbInt32Field.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'integer ' + SQLCreate;
   end; // GetSQLCreate()


// ========================================================================
// = dbWord32Field
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbWord32Field.Create( Name: string);
   begin
      inherited Create( Name);
      OrigValue:= 0;
      NewValue:= 0;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbWord32Field.Create( Name: string; SQLCreateParams: string);
   begin
      Create( Name);
      SQLCreate:= SQLCreateParams;
   end; // Constructor


// *************************************************************************
// * NoChange() - Sets the HasChanged() value to false.  This should be
// *              called after the value of the field has been read from
// *              from the SQL database.
// *************************************************************************

procedure dbWord32Field.NoChange();
   begin
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // NoChange


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbWord32Field.CheckValidity( InputValue: String): string;
   var
      TempI:      Word32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      // Just to prevent a compiler note about TempI not being used.
      TempI:= TempI;
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a 32 bit word value!');
      end;

      CheckValidity:= TempS;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

procedure dbWord32Field.SetValue( InputValue: Word32);
   begin
      NewValue:= InputValue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbWord32Field.SetValue( InputValue: string);
   var
      TempI:      Word32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= CheckValidity( InputValue);

      // Do the conversion.  No need to check ResultCode because it already
      // worked once in ValidityCheck()
      Val( TempS, TempI, ResultCode);
      // This if statement is just to quiet a compiler Note about ResultCode
      //    not being used.
      if( ResultCode <> 0) then begin
         ResultCode:= 0;
      end;

      NewValue:= TempI;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() Sets the value of the field from a string as in
// *                 SetValue() except no call to CheckValidity() is
// *                 is made.  This function will be used by dbTables
// *                 to set OrigValues from data in the SQL results.
// *                 In this case it does away with the bounds check.
// *************************************************************************

procedure dbWord32Field.ForceSetValue( InputValue: string);
   var
      TempI:      Word32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a 32 bit word value!');
      end;

      NewValue:= TempI;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue();


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbWord32Field.GetValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetValue:= Temp;
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbWord32Field.GetOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetOrigValue:= Temp;
   end; // GetOrigValue();


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbWord32Field.Clear();
   begin
      NewValue:= 0;
   end; // Clear()


// *************************************************************************
// *  RestoreValue() - Restore original value an set HasChanged() to false.
// *************************************************************************

procedure dbWord32Field.RestoreValue();
   begin
      NewValue:= OrigValue;
      HasChangedFlag:= false;
   end; // RestoreValue()


// *************************************************************************
// * GetSQLValue() - Used to get the field's value as it would appear
// *                 in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbWord32Field.GetSQLValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetSQLValue:= Temp;
   end; // GetSQLValue()


// *************************************************************************
// * GetSQLOrigValue() - Used to get the field's original value as it would
// *                     appear in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbWord32Field.GetSQLOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetSQLOrigValue:= Temp;
   end; // GetSQLOrigValue()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbWord32Field.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'bigint unsigned ' + SQLCreate;
   end; // GetSQLCreate()


// ========================================================================
// = dbCharField - Fixed length string
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbCharField.Create( Name: string; iSize: int32);
   begin
      inherited Create( Name);
      Size:= iSize;
      Clear();
      OrigValue:= NewValue;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbCharField.Create( Name: string; SQLCreateParams: string;
                                iSize: int32);
   begin
      Create( Name, iSize);
      SQLCreate:= SQLCreateParams;
   end; // Constructor


// *************************************************************************
// * NoChange() - Sets the HasChanged() value to false.  This should be
// *              called after the value of the field has been read from
// *              from the SQL database.
// *************************************************************************

procedure dbCharField.NoChange();
   begin
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // NoChange


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbCharField.CheckValidity( InputValue: String): string;
   begin
      // Bounds test
      if( Length( InputValue) <> Size) then begin
         raise dbFieldException.Create(
           '%s: The input string (%s) must be %d characters long!',
           [SQLName, InputValue, Size]);
      end;

      CheckValidity:= InputValue;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

procedure dbCharField.SetValue( InputValue: string);
   begin
      if( StoredAsHTML xor AccessAsHTML) then begin
         if( StoredAsHTML) then begin
            NewValue:= CheckValidity( HTTPEncode( InputValue));
         end else begin
            NewValue:= CheckValidity( HTTPDecode( InputValue));
         end;
      end else begin
         NewValue:= CheckValidity( InputValue);
      end;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() Sets the value of the field from a string as in
// *                 SetValue() except no call to CheckValidity() is
// *                 is made.  This function will be used by dbTables
// *                 to set OrigValues from data in the SQL results.
// *                 In this case it does away with the bounds check.
// *                 No HTML conversion is performed.
// *************************************************************************

procedure dbCharField.ForceSetValue( InputValue: string);
   begin
      NewValue:= InputValue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue();


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbCharField.GetValue(): string;
   begin
      if( StoredAsHTML xor AccessAsHTML) then begin
         if( StoredAsHTML) then begin
            result:= HTTPDecode( NewValue);
         end else begin
            result:= HTTPEncode( NewValue);
         end;
      end else begin
         result:= NewValue;
      end;
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbCharField.GetOrigValue(): string;
   begin
      if( StoredAsHTML xor AccessAsHTML) then begin
         if( StoredAsHTML) then begin
            result:= HTTPDecode( OrigValue);
         end else begin
            result:= HTTPEncode( OrigValue);
         end;
      end else begin
         result:= OrigValue;
      end;
   end; // GetOrigValue();


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbCharField.Clear();
   begin
      NewValue:= StringOfChar( ' ', Size);
   end; // Clear()


// *************************************************************************
// *  RestoreValue() - Restore original value an set HasChanged() to false.
// *************************************************************************

procedure dbCharField.RestoreValue();
   begin
      NewValue:= OrigValue;
      HasChangedFlag:= false;
   end; // RestoreValue()


// *************************************************************************
// * GetSQLValue() - Used to get the field's value as it would appear
// *                 in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbCharField.GetSQLValue(): string;
   begin
      GetSQLValue:= '''' + EscapeString( NewValue) + '''';
   end; // GetSQLValue()


// *************************************************************************
// * GetSQLOrigValue() - Used to get the field's original value as it would
// *                     appear in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbCharField.GetSQLOrigValue(): string;
   begin
      GetSQLOrigValue:= '''' + EscapeString( OrigValue) + '''';
   end; // GetSQLOrigValue()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbCharField.GetSQLCreate(): string;
   begin
      GetSQLCreate:= Format( 'char( %d) %s', [Size, SQLCreate]);
   end; // GetSQLCreate()


// ========================================================================
// = dbVarCharField - Fixed length string
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbVarCharField.Create( Name: string; iSize: int32);
   begin
      inherited Create( Name, iSize);
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbVarCharField.Create( Name: string; SQLCreateParams: string;
                                iSize: int32);
   begin
      inherited Create( Name, SQLCreateParams, iSize);
   end; // Constructor


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbVarCharField.CheckValidity( InputValue: String): string;
   begin
      // Bounds test
      if( Length( InputValue) > Size) then begin
         raise dbFieldException.Create(
           '%s: The input string (%s) must be less than %d characters long!',
           [SQLName, InputValue, Size + 1]);
      end;

      CheckValidity:= InputValue;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

// procedure dbVarCharField.SetValue( InputValue: string);
//    begin
//       NewValue:= CheckValidity( InputValue);
//       HasChangedFlag:= (NewValue <> OrigValue);
//    end; // SetValue()


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbVarCharField.Clear();
   begin
      if( StoredAsHTML) then begin
         NewValue:= '+';
      end else begin
         NewValue:= '';
      end;
   end; // Clear()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbVarCharField.GetSQLCreate(): string;
   begin
      GetSQLCreate:= Format( 'varchar( %d) %s', [Size, SQLCreate]);
   end; // GetSQLCreate()


// ========================================================================
// = dbWord8Field
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbWord8Field.Create( Name: string);
   begin
      inherited Create( Name);
      OrigValue:= 0;
      NewValue:= 0;
      MaxValue:= MaxWord8;
      MinValue:= 0;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbWord8Field.Create( Name: string; SQLCreateParams: string);
   begin
      Create( Name);
      SQLCreate:= SQLCreateParams;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbWord8Field.Create( Name: string; SQLCreateParams: String;
                                 LowerBound: word8; UpperBound: word8);
   begin
      inherited Create( Name);
      SQLCreate:= SQLCreateParams;
      MaxValue:=  UpperBound;
      MinValue:=  LowerBound;
   end; // Constructor


// *************************************************************************
// * NoChange() - Sets the HasChanged() value to false.  This should be
// *              called after the value of the field has been read from
// *              from the SQL database.
// *************************************************************************

procedure dbWord8Field.NoChange();
   begin
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // NoChange


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbWord8Field.CheckValidity( InputValue: String): string;
   var
      TempI:      Word32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a byte value!');
      end;

      // Bounds test
      if( (TempI > MaxValue) or (TempI < MinValue)) then begin
         raise dbFieldException.Create(
           '%s: The input values is outside the range %d to %d',
           [SQLName, MinValue, MaxValue]);
      end;

      CheckValidity:= TempS;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

procedure dbWord8Field.SetValue( InputValue: Word8);
   begin
      NewValue:= InputValue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbWord8Field.SetValue( InputValue: string);
   var
      TempI:      Word32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= CheckValidity( InputValue);

      // Do the conversion.  No need to check ResultCode because it already
      // worked once in ValidityCheck()
      Val( TempS, TempI, ResultCode);
      // This if statement is just to stop compiler warnings
      if( ResultCode <> 0) then begin
         ResultCode:= 0;
      end;

      NewValue:= word8( TempI);
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() Sets the value of the field from a string as in
// *                 SetValue() except no call to CheckValidity() is
// *                 is made.  This function will be used by dbTables
// *                 to set OrigValues from data in the SQL results.
// *                 In this case it does away with the bounds check.
// *************************************************************************

procedure dbWord8Field.ForceSetValue( InputValue: string);
   var
      TempI:      Word32;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a byte value!');
      end;

      NewValue:= word8( TempI);
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue();


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbWord8Field.GetValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetValue:= Temp;
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbWord8Field.GetOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetOrigValue:= Temp;
   end; // GetOrigValue();


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbWord8Field.Clear();
   begin
      NewValue:= 0;
   end; // Clear()


// *************************************************************************
// *  RestoreValue() - Restore original value an set HasChanged() to false.
// *************************************************************************

procedure dbWord8Field.RestoreValue();
   begin
      NewValue:= OrigValue;
      HasChangedFlag:= false;
   end; // RestoreValue()


// *************************************************************************
// * GetSQLValue() - Used to get the field's value as it would appear
// *                 in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbWord8Field.GetSQLValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetSQLValue:= Temp;
   end; // GetSQLValue()


// *************************************************************************
// * GetSQLOrigValue() - Used to get the field's original value as it would
// *                     appear in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbWord8Field.GetSQLOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetSQLOrigValue:= Temp;
   end; // GetSQLOrigValue()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbWord8Field.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'tinyint unsigned ' + SQLCreate;
   end; // GetSQLCreate()


// ========================================================================
// = dbInt64Field
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbInt64Field.Create( Name: string);
   begin
      inherited Create( Name);
      OrigValue:= 0;
      NewValue:= 0;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbInt64Field.Create( Name: string; SQLCreateParams: string);
   begin
      Create( Name);
      SQLCreate:= SQLCreateParams;
   end; // Constructor


// *************************************************************************
// * NoChange() - Sets the HasChanged() value to false.  This should be
// *              called after the value of the field has been read from
// *              from the SQL database.
// *************************************************************************

procedure dbInt64Field.NoChange();
   begin
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // NoChange


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbInt64Field.CheckValidity( InputValue: String): string;
   var
      TempI:      int64;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a 64 bit integer value!');
         // Stop compiler warning by 'using' TempI
         TempI:= TempI;
      end;

      CheckValidity:= TempS;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

procedure dbInt64Field.SetValue( InputValue: int64);
   begin
      NewValue:= InputValue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbInt64Field.SetValue( InputValue: string);
   var
      TempI:      int64;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= CheckValidity( InputValue);

      // Do the conversion.  No need to check ResultCode because it already
      // worked once in ValidityCheck()
      Val( TempS, TempI, ResultCode);
      // This if statement is just to stop compiler warnings about ResultCode
      if( ResultCode <> 0) then begin
         ResultCode:= 0;
      end;

      NewValue:= TempI;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() Sets the value of the field from a string as in
// *                 SetValue() except no call to CheckValidity() is
// *                 is made.  This function will be used by dbTables
// *                 to set OrigValues from data in the SQL results.
// *                 In this case it does away with the bounds check.
// *************************************************************************

procedure dbInt64Field.ForceSetValue( InputValue: string);
   var
      TempI:      int64;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a 64 bit integer value!');
      end;

      NewValue:= TempI;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue();


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbInt64Field.GetValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetValue:= Temp;
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbInt64Field.GetOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetOrigValue:= Temp;
   end; // GetOrigValue();


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbInt64Field.Clear();
   begin
      NewValue:= 0;
   end; // Clear()


// *************************************************************************
// *  RestoreValue() - Restore original value an set HasChanged() to false.
// *************************************************************************

procedure dbInt64Field.RestoreValue();
   begin
      NewValue:= OrigValue;
      HasChangedFlag:= false;
   end; // RestoreValue()


// *************************************************************************
// * GetSQLValue() - Used to get the field's value as it would appear
// *                 in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbInt64Field.GetSQLValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetSQLValue:= Temp;
   end; // GetSQLValue()


// *************************************************************************
// * GetSQLOrigValue() - Used to get the field's original value as it would
// *                     appear in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbInt64Field.GetSQLOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetSQLOrigValue:= Temp;
   end; // GetSQLOrigValue()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbInt64Field.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'bigint ' + SQLCreate;
   end; // GetSQLCreate()


// ========================================================================
// = dbWord64Field
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbWord64Field.Create( Name: string);
   begin
      inherited Create( Name);
      OrigValue:= 0;
      NewValue:= 0;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbWord64Field.Create( Name: string; SQLCreateParams: string);
   begin
      Create( Name);
      SQLCreate:= SQLCreateParams;
   end; // Constructor


// *************************************************************************
// * NoChange() - Sets the HasChanged() value to false.  This should be
// *              called after the value of the field has been read from
// *              from the SQL database.
// *************************************************************************

procedure dbWord64Field.NoChange();
   begin
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // NoChange


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbWord64Field.CheckValidity( InputValue: String): string;
   var
      TempI:      word64;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a 64 bit integer value!');
         // Stop compiler warning about Temp1 not being used.
         TempI:= TempI;
      end;

      CheckValidity:= TempS;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

procedure dbWord64Field.SetValue( InputValue: word64);
   begin
      NewValue:= InputValue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbWord64Field.SetValue( InputValue: string);
   var
      TempI:      word64;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= CheckValidity( InputValue);

      // Do the conversion.  No need to check ResultCode because it already
      // worked once in ValidityCheck()
      Val( TempS, TempI, ResultCode);
      // This if statement is just to stop compiler warnings
      if( ResultCode <> 0) then begin
         ResultCode:= 0;
      end;

      NewValue:= TempI;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() Sets the value of the field from a string as in
// *                 SetValue() except no call to CheckValidity() is
// *                 is made.  This function will be used by dbTables
// *                 to set OrigValues from data in the SQL results.
// *                 In this case it does away with the bounds check.
// *************************************************************************

procedure dbWord64Field.ForceSetValue( InputValue: string);
   var
      TempI:      word64;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a 64 bit integer value!');
      end;

      NewValue:= TempI;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue();


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbWord64Field.GetValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetValue:= Temp;
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbWord64Field.GetOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetOrigValue:= Temp;
   end; // GetOrigValue();


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbWord64Field.Clear();
   begin
      NewValue:= 0;
   end; // Clear()


// *************************************************************************
// *  RestoreValue() - Restore original value an set HasChanged() to false.
// *************************************************************************

procedure dbWord64Field.RestoreValue();
   begin
      NewValue:= OrigValue;
      HasChangedFlag:= false;
   end; // RestoreValue()


// *************************************************************************
// * GetSQLValue() - Used to get the field's value as it would appear
// *                 in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbWord64Field.GetSQLValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetSQLValue:= Temp;
   end; // GetSQLValue()


// *************************************************************************
// * GetSQLOrigValue() - Used to get the field's original value as it would
// *                     appear in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbWord64Field.GetSQLOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetSQLOrigValue:= Temp;
   end; // GetSQLOrigValue()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbWord64Field.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'bigint unsigned ' + SQLCreate;
   end; // GetSQLCreate()


// ========================================================================
// = dbDoubleField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbDoubleField.Create( Name: string);
   begin
      inherited Create( Name);
      OrigValue:= 0;
      NewValue:= 0;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbDoubleField.Create( Name: string; SQLCreateParams: string);
   begin
      Create( Name);
      SQLCreate:= SQLCreateParams;
   end; // Constructor


// *************************************************************************
// * NoChange() - Sets the HasChanged() value to false.  This should be
// *              called after the value of the field has been read from
// *              from the SQL database.
// *************************************************************************

procedure dbDoubleField.NoChange();
   begin
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // NoChange


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbDoubleField.CheckValidity( InputValue: String): string;
   var
      TempI:      extended;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a floating point value!');
            // Stop compiler errors about TempI not being used.
            TempI:= TempI;
      end;

      CheckValidity:= TempS;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

procedure dbDoubleField.SetValue( InputValue: Double);
   begin
      NewValue:= InputValue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbDoubleField.SetValue( InputValue: string);
   var
      TempI:      Extended;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= CheckValidity( InputValue);

      // Do the conversion.  No need to check ResultCode because it already
      // worked once in ValidityCheck()
      Val( TempS, TempI, ResultCode);
      // This if statement is just to stop compiler warnings
      if( ResultCode <> 0) then begin
         ResultCode:= 0;
      end;

      NewValue:= Double( TempI);
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() Sets the value of the field from a string as in
// *                 SetValue() except no call to CheckValidity() is
// *                 is made.  This function will be used by dbTables
// *                 to set OrigValues from data in the SQL results.
// *                 In this case it does away with the bounds check.
// *************************************************************************

procedure dbDoubleField.ForceSetValue( InputValue: string);
   var
      TempI:      Extended;
      TempS:      string;
      ResultCode: word;
   begin
      TempS:= InputValue;

      if( Length( InputValue) = 0) then begin
         TempS:= '0';
      end;

      Val( TempS, TempI, ResultCode);
      if( ResultCode <> 0) then begin
         Raise dbFieldException.Create( SQLName +
            ':  The input string (' + TempS +
            ') is not a floating point value!');
      end;

      NewValue:= Double( TempI);
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue();


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbDoubleField.GetValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetValue:= Temp;
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbDoubleField.GetOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetOrigValue:= Temp;
   end; // GetOrigValue();


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbDoubleField.Clear();
   begin
      NewValue:= 0;
   end; // Clear()


// *************************************************************************
// *  RestoreValue() - Restore original value an set HasChanged() to false.
// *************************************************************************

procedure dbDoubleField.RestoreValue();
   begin
      NewValue:= OrigValue;
      HasChangedFlag:= false;
   end; // RestoreValue()


// *************************************************************************
// * GetSQLValue() - Used to get the field's value as it would appear
// *                 in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbDoubleField.GetSQLValue(): string;
   var
      Temp: string;
   begin
      Str( NewValue, Temp);
      GetSQLValue:= Temp;
   end; // GetSQLValue()


// *************************************************************************
// * GetSQLOrigValue() - Used to get the field's original value as it would
// *                     appear in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbDoubleField.GetSQLOrigValue(): string;
   var
      Temp: string;
   begin
      Str( OrigValue, Temp);
      GetSQLOrigValue:= Temp;
   end; // GetSQLOrigValue()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbDoubleField.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'double ' + SQLCreate;
   end; // GetSQLCreate()


// =========================================================================
// = dbBitSetField
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor dbBitSetField.Create( Name: string);
  begin
     inherited Create( Name);
     VarInit();
  end; // Constructor

// -------------------------------------------------------------------------

constructor dbBitSetField.Create( Name: string; SQLCreateParams: string);
   begin
      inherited Create( Name, SQLCreateParams);
      VarInit();
   end; // Constructor


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor  dbBitSetField.Destroy;
   var
      Temp: StringPtr;
   begin
      while( not Descriptions.Empty()) do begin
         Temp:= StringPtr( Descriptions.Pop());
         Temp^:= '';
         Dispose( Temp);
      end;
      Descriptions.Destroy();
      BitValues.Destroy();
   end; // Destructor


// *************************************************************************
// * VarInit() - Children should override this to set their own values.
// *************************************************************************

procedure dbBitSetField.VarInit();
   begin
      Descriptions:= DoubleLinkedList.Create();
      BitValues:= Word64Array.Create();
   end; // VarInit()


// *************************************************************************
// * SetBit() - Set BitPattern bits to Value
// *************************************************************************

procedure dbBitSetField.SetBit( BitPattern: word64; Value: boolean);
   begin
      if Value then begin
         NewValue:= NewValue or BitPattern;
      end else begin
         NewValue:= NewValue and (not BitPattern);
      end;

      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetBitt()


// *************************************************************************
// * GetBit() - Checks to see if every bit in BitPattern is on in NewValue
// *************************************************************************

function dbBitSetField.GetBit( BitPattern: word64): boolean;
   begin
      GetBit:= (BitPattern = (NewValue and BitPattern));
   end; // GetBit


// *************************************************************************
// * AddDescription() - A protected helper app to make the VarInit
// *                    functions of children look cleaner.
// *************************************************************************

procedure dbBitSetField.AddDescription( S: string);
   var
      Temp: StringPtr;
   begin
      new( Temp);
      Temp^:= S;
      Descriptions.Enqueue( Temp);
   end; // AddDescription()


// ========================================================================
// = dbBooleanField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbBooleanField.Create( Name: string);
   begin
      inherited Create( Name);
      OrigValue:= false;
      NewValue:= false;
   end; // Constructor


// ------------------------------------------------------------------------

constructor dbBooleanField.Create( Name: string; SQLCreateParams: string);
   begin
      Create( Name);
      SQLCreate:= SQLCreateParams;
   end; // Constructor


// *************************************************************************
// * NoChange() - Sets the HasChanged() value to false.  This should be
// *              called after the value of the field has been read from
// *              from the SQL database.
// *************************************************************************

procedure dbBooleanField.NoChange();
   begin
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // NoChange


// *************************************************************************
// * CheckValidity() - Check to make sure the input data is valid for
// *                   this field.  Also may perform manipulation of the
// *                   input data such as removing trailing spaces, etc.
// *                   The modified input data is returned and can be
// *                   used to set the underlying OrigValue of the field.
// *************************************************************************

function dbBooleanField.CheckValidity( InputValue: String): string;
   var
      TempC:      char;
      TempI:      int32;
      TempS:      string;
      ResultCode: word;
   begin
      // Check for empty string
      if( Length( InputValue) = 0) then begin
         TempS:= 'F';
      end else begin
         // Not an empty string
         // Check for yes/no type strings
         TempC:= InputValue[ 1];
         if( TempC in [ 'Y', 'y', 'T', 't']) then begin
            TempS:= 'T';
         end else if( TempC in [ 'N', 'n', 'F', 'f']) then begin
            TempS:= 'F';
         end else begin
            // We hope it is a numeric value
            Val( InputValue, TempI, ResultCode);
            if( ResultCode <> 0) then begin
               Raise dbFieldException.Create( SQLName +
                  ':  The input string (' + TempS +
                  ') is not a boolean value!');
            end;
            if( TempI = 0) then begin
               TempS:= 'F';
            end else begin
               TempS:= 'T';
            end;
         end; // else not a yes/no type string
      end; // InputValue is not an empty string
      CheckValidity:= TempS;
   end; // CheckValidity()


// *************************************************************************
// * SetValue() - Sets the (new) value of the field.
// *************************************************************************

procedure dbBooleanField.SetValue( InputValue: boolean);
   begin
      NewValue:= InputValue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbBooleanField.SetValue( InputValue: int32);
   begin
      NewValue:= (InputValue <> 0);
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbBooleanField.SetValue( InputValue: string);
   var
      TempS:      string;
   begin
      TempS:= CheckValidity( InputValue);
      if( TempS = 'T') then begin
         NewValue:= true;
      end else begin
         NewValue:= false;
      end;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() Sets the value of the field from a string as in
// *                 SetValue() except no call to CheckValidity() is
// *                 is made.  This function will be used by dbTables
// *                 to set OrigValues from data in the SQL results.
// *                 In this case it does away with the bounds check.
// *************************************************************************

procedure dbBooleanField.ForceSetValue( InputValue: string);
   var
      TempS:      string;
   begin
      TempS:= CheckValidity( InputValue);
      if( TempS = 'T') then begin
         NewValue:= true;
      end else begin
         NewValue:= false;
      end;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue();


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbBooleanField.GetValue(): string;
   begin
      if( NewValue) then begin
         GetValue:= 'true';
      end else begin
         GetValue:= 'false';
      end;
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbBooleanField.GetOrigValue(): string;
   begin
      if( OrigValue) then begin
         GetOrigValue:= 'true';
      end else begin
         GetOrigValue:= 'false';
      end;
   end; // GetOrigValue();


// *************************************************************************
// * Clear() - Sets the field to its default value.
// *************************************************************************

procedure dbBooleanField.Clear();
   begin
      NewValue:= false;
   end; // Clear()


// *************************************************************************
// *  RestoreValue() - Restore original value an set HasChanged() to false.
// *************************************************************************

procedure dbBooleanField.RestoreValue();
   begin
      NewValue:= OrigValue;
      HasChangedFlag:= false;
   end; // RestoreValue()


// *************************************************************************
// * GetSQLValue() - Used to get the field's value as it would appear
// *                 in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbBooleanField.GetSQLValue(): string;
   begin
      if( NewValue) then begin
         GetSQLValue:= '1';
      end else begin
         GetSQLValue:= '0';
      end;
   end; // GetSQLValue()


// *************************************************************************
// * GetSQLOrigValue() - Used to get the field's original value as it would
// *                     appear in a SQL query string.  IE: quoted strings.
// *************************************************************************

function dbBooleanField.GetSQLOrigValue(): string;
   begin
      if( OrigValue) then begin
         GetSQLOrigValue:= '1';
      end else begin
         GetSQLOrigValue:= '0';
      end;
   end; // GetSQLOrigValue()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbBooleanField.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'tinyint unsigned ' + SQLCreate;
   end; // GetSQLCreate()


// ========================================================================
// = dbDateTimeField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbDateTimeField.Create( Name: string);
   begin
      inherited Create( Name, 19);
      CheckString:= '0000-00-00 00:00:00';
      Clear();
   end; // Constructor


// *************************************************************************
// * CheckValidity() - Make sure the input data is in the correct format
// *                   Fixes problems if possible.
// *************************************************************************

function dbDateTimeField.CheckValidity( InputValue: string): string;
   var
      i:      integer;
      Temp:   string;
      Found:  boolean; // true if an error was found
      CSchar: char;
      IVchar: char;
   begin
      if( Length( InputValue) = 0) then begin
         if( NowOnNull) then begin
            Temp:= Now();
         end else begin
            Temp:= CheckString;
         end;
      end else begin
         Temp:= InputValue;
      end;

      if( Length( Temp) <> Size) then begin
         raise dbFieldException.Create( SQLName + ':  The input value (' +
                                        Temp + ') is not a valid date/time!');
      end;

      // for each character in InputValue
      Found:= false;
      for i:= 1 to Size do begin
         CSchar:= CheckString[ i];
         IVchar:= Temp[ i];

         // Is it supposed to be numeric?
         if( CSchar = '0') then begin
            if( (IVchar < '0') or (IVchar > '9')) then begin
               Found:= true;
            end;

         // Non-numeric, so they must match excatly.
         end else begin
            if( CSchar <> IVchar) then begin
               Found:= true;
            end;
         end;
      end; // for each character in InputValue

      // did we find a error?
      if( Found) then begin
         raise dbFieldException.Create( SQLName + ':  The input value (' +
                                        Temp + ') is not a valid date/time!');
      end;

      CheckValidity:= Temp;
   end; // CheckValidity()


// *************************************************************************
// * SetToNow() - Set NewValue to Now()
// *************************************************************************

procedure dbDateTimeField.SetToNow();
   begin
      NewValue:= Now();
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetToNow()


// *************************************************************************
// * Now() - Return the current date and time in dbDateTime format
// *************************************************************************

function dbDateTimeField.Now(): string;
   begin
{$ifdef win32}
      result:= FormatDateTime( 'yyyy"-"mm"-"dd" "hh":"nn":"ss', SysUtils.Now());
{$else}
      if( not CronIsRunning) then begin
         CurrentTime.Now();
      end;
      Now:= CurrentTime.Str
{$endif}
   end; // Now()


// *************************************************************************
// * ForceSetValue() - Set the value of the field from a string
// *************************************************************************

procedure dbDateTimeField.ForceSetValue( InputValue: string);
   begin
      if( Length( InputValue) = 0) then begin
         if( NowOnNull) then begin
            NewValue:= Now();
         end else begin
            NewValue:= CheckString;
         end;
      end else begin
         NewValue:= InputValue;
      end;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // ForceSetValue()


// *************************************************************************
// * Clear() - Set the field to its default value
// *************************************************************************

procedure dbDateTimeField.Clear();
   begin
      if( NowOnNull) then begin
         NewValue:= Now();
      end else begin
         NewValue:= CheckString;
      end;
      OrigValue:= NewValue;
      HasChangedFlag:= false;
   end; // Clear()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbDateTimeField.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'datetime not null';
   end; // GetSQLCreate()


// ========================================================================
// = dbDateField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbDateField.Create( Name: string);
   begin
      inherited Create( Name);
      Size:= 10;
      CheckString:= '0000-00-00';
      Clear();
   end; // Constructor


// *************************************************************************
// * Now() - Return the current date and time in dbDate format
// *************************************************************************

function dbDateField.Now(): string;
   var
      Temp: String;
   begin
{$ifdef win32}
      result:= FormatDateTime( 'yyyy"-"mm"-"dd', SysUtils.Now());
{$else}
      if( not CronIsRunning) then begin
         CurrentTime.Now();
      end;
      Temp:= CurrentTime.Str;

      result:= Copy( Temp, 1, 10);
{$endif}
   end; // Now()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbDateField.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'date not null';
   end; // GetSQLCreate()


// ========================================================================
// = dbTimeField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbTimeField.Create( Name: string);
   begin
      inherited Create( Name);
      Size:= 8;
      CheckString:= '00:00:00';
      Clear();
   end; // Constructor


// *************************************************************************
// * Now() - Return the current date and time in dbDate format
// *************************************************************************

function dbTimeField.Now(): string;
   var
      Temp: String;
   begin
{$ifdef win32}
      result:= FormatDateTime( 'hh":"nn":"ss', SysUtils.Now());
{$else}
      if( not CronIsRunning) then begin
         CurrentTime.Now();
      end;
      Temp:= CurrentTime.Str;

      result:= Copy( Temp, 12, 8);
{$endif}
   end; // Now()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbTimeField.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'time not null';
   end; // GetSQLCreate()


// ========================================================================
// = dbTimestampField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbTimestampField.Create( Name: string);
   begin
      inherited Create( Name);
      CheckString:= '00000000000000';
      Size:= 14;
      Clear();
   end; // Constructor


// *************************************************************************
// * Now() - Return the current date and time in dbDate format
// *************************************************************************

function dbTimestampField.Now(): string;
   begin
{$ifdef win32}
      result:= FormatDateTime( 'y"-"mm"-"dd" "hh":"nn":"ss', SysUtils.Now());
{$else}
      if( not CronIsRunning) then begin
         CurrentTime.Now();
      end;
      result:= CurrentTime.Str;
{$endif}
   end; // Now()


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbTimestampField.GetSQLCreate(): string;
   begin
      GetSQLCreate:= Format( 'timestamp( %d) not null',[Size]);
   end; // GetSQLCreate()


// ========================================================================
// = dbTextField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbTextField.Create( Name: string);
   begin
      inherited Create( Name, MaxInt32);
   end; // Constructor


// -------------------------------------------------------------------------

constructor dbTextField.Create( Name: string; SQLCreateParams: string);
   begin
      inherited Create( Name, SQLCreateParams, MaxInt32);
   end; // Constctructor


// *************************************************************************
// * GetSQLCreate() - Used to get the field's parameters for the SQL
// *                  create command.  IE:  int not null, etc.
// *************************************************************************

function dbTextField.GetSQLCreate(): string;
   begin
      GetSQLCreate:= 'text ' + SQLCreate;
   end; // GetSQLCreate()


// ========================================================================
// = dbIPAddressField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbIPAddressField.Create( Name: string);
   begin
      inherited Create( Name);
      NumberOfOctets:= DefaultIPNumberOfOctets;
   end; // Constructor


// -------------------------------------------------------------------------

constructor dbIPAddressField.Create( Name: string; SQLCreateParams: string);
   begin
      inherited Create( Name, SQLCreateParams);
      NumberOfOctets:= DefaultIPNumberOfOctets;
   end; // Constructor


// -------------------------------------------------------------------------

constructor dbIPAddressField.Create( Name: string; NumOctets: integer);
   begin
      inherited Create( Name);
      NumberOfOctets:= NumOctets;
   end; // Constructor


// -------------------------------------------------------------------------

constructor dbIPAddressField.Create( Name: string; NumOctets: integer;
                                     SQLCreateParams: string);
   begin
      inherited Create( Name, SQLCreateParams);
      NumberOfOctets:= NumOctets;
   end; // Constructor


// *************************************************************************
// * StringToWord32() - Convert the String representation of an IP address
// *                    to a Long.
// *************************************************************************

class function dbIPAddressField.StringToWord32( const S: String): word32;
   begin
      try
         StringToWord32:= IPStringToWord32( S);
      except
         on e: IPConversionException do begin
            raise dbFieldException.Create( e.Message);
         end;
      end; // try/except
   end; // StringToWord32()


// *************************************************************************
// * Word32ToString() - Convert the long representation of an IP address
// *                    to a String.
// *************************************************************************

class function dbIPAddressField.Word32ToString( const X: word32): string;
   begin
      try
         Word32ToString:= IPWord32ToString( X);
      except
         on e: IPConversionException do begin
            raise dbFieldException.Create( e.Message);
         end;
      end; // try/except
   end; // Word32ToString()


// *************************************************************************
// * Word32ToReversString() - Convert the long representation of an IP
// *                          address to a String in reverse order.  This
// *                          function is intended to be used to create DNS
// *                          entries.
// *************************************************************************

class function dbIPAddressField.Word32ToReverseString( const X: word32): string;
   var
      Temp:    Word32ByteArray;
      Octet:   string[ 4];
      IPStr:   string[ 15];
      i:       word;
   begin
      IPStr:= '';
      Temp.Word32Value:= X;
      for i:= 0 to 3 do begin
         Str( Temp.ByteValue[ i], Octet);
         if( i > 0) then begin
            IPStr:= IPStr + '.' + Octet;
         end else begin
            IPStr:= IPStr + Octet;
         end;
      end; // for

      Word32ToReverseString:= IPStr;
   end; // Word32ToReverseString()


// *************************************************************************
// * IPAddressToNIC() - Converts the input IP Address string to
// *                    our standard unknown NIC address.
// *                    ( 6 f's followed by last two zero padded
// *                    octets of the IP Address.
// *************************************************************************

class function dbIPAddressField.IPAddressToNIC( const IPAddress: word32): string;
   var
      Temp:    Word32ByteArray;
      Octet:   string[ 4];
      IPStr:   string[ 15];
      i:       word;
   begin
      IPStr:= 'ffffff';
      Temp.Word32Value:= IPAddress;
      for i:= 1 downto 0 do begin
         Str( Temp.ByteValue[ i], Octet);
         while( Length( Octet) < 3) do begin
            Octet:= '0' + Octet;
         end;
         IPStr:= IPStr + Octet;
      end; // for

      IPAddressToNIC:= IPStr;
   end; // IPAddressToNIC()


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbIPAddressField.GetValue(): string;
   begin
      GetValue:= Word32ToString( NewValue);
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbIPAddressField.GetOrigValue(): string;
   begin
      GetOrigValue:= Word32ToString( OrigValue);
   end; // GetOrigValue();


// *************************************************************************
// * SetValue() - Set the value of the field from the passed string
// *************************************************************************

procedure dbIPAddressField.SetValue( InputValue: String);
   begin
      // Is it a standard integer value
      if( Pos( '.', InputValue) = 0) then begin
         inherited SetValue( InputValue);
      end else begin

          // It contains dots, so it must be an IP address.
          NewValue:= StringToWord32( InputValue);
          HasChangedFlag:= ( NewValue <> OrigValue);
      end;
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbIPAddressField.SetValue( InputValue: Word32);
   begin
      NewValue:= Inputvalue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// *************************************************************************
// * ForceSetValue() - Set the value of the field from the passed string
// *************************************************************************

procedure dbIPAddressField.ForceSetValue( InputValue: String);
   begin
      // Is it a standard integer value
      if( Pos( '.', InputValue) = 0) then begin
         inherited ForceSetValue( InputValue);
      end else begin

          // It contains dots, so it must be an IP address.
          NewValue:= StringToWord32( InputValue);
          HasChangedFlag:= ( NewValue <> OrigValue);
      end;
   end; // ForceSetValue()



// ========================================================================
// = dbPgIPAddressField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

function dbPgIPAddressField.GetSQLValue(): string;
   begin
      result:= '''' + Word32ToString( NewValue) + '''';
   end; // GetSQLValue()


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

function dbPgIPAddressField.GetSQLOrigValue(): string;
   begin
      result:= '''' + Word32ToString( OrigValue) + '''';
   end; // GetSQLValue()


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

function dbPgIPAddressField.GetSQLCreate(): string;
      begin
         raise dbFieldException.Create( 'dbPgIPAddressField.GetSQLCreate is not currently  suported');
         result:= '';
      end; // GetSQLCreate()


// ========================================================================
// = dbNICAddressField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor dbNICAddressField.Create( Name: string);
   begin
      inherited Create( Name);
   end; // Constructor


// -------------------------------------------------------------------------

constructor dbNICAddressField.Create( Name: string; SQLCreateParams: string);
   begin
      inherited Create( Name, SQLCreateParams);
   end; // Constructor


// ******************************************************************
// * RemoveNonHexCharacters()
// ******************************************************************

class function dbNICAddressField.RemoveNonHexCharacters( const S: String): String;
   var
      B:     String;
      i:     integer;
      Len:   integer;
      TempS: String;
      TempC: char;
   begin
      B:= '';
      TempS:= Lowercase( S);
      Len:= Length( TempS);

      // For each character in the input string
      for i:= 1 to Len do begin
         TempC:= TempS[ i];

         // Is it a valid character?
         if( ((TempC >= '0') and (tempC <= '9')) or
             ((TempC >= 'a') and (tempC <= 'f'))) then begin

            // Yes, so copy it to B
            B:= B + TempC;

         end; // if valid characters
      end; // For each character in the input string

      RemoveNonHexCharacters:= B;

   end; // RemoveNonHexCharacters()


// ******************************************************************
// * CheckValidity() Check to make sure the input data is valid for
// *                 this field.  Also may perform manipulation of the
// *                 input data such as removing trailing spaces, etc.
// *                 The modified input data is returned and can be
// *                 used to set the underlying OrigValue of the field.
// ******************************************************************

function dbNICAddressField.CheckValidity( InputValue: string): string;
   var
      Temp: string;
   begin
      Temp:= RemoveNonHexCharacters( InputValue);
      if ( Length( Temp) <> NICSize) then begin
         raise dbFieldException.Create(
             'NIC addresses must contain %d hex characters!', [NICSize]);
      end; // if
      CheckValidity:= Temp;

   end; // CheckValidity()


// *************************************************************************
// * InsertSeparators() - Inserts a separator character (C) between each
// *                      Count characters of the NIC (S).
// *************************************************************************


class function dbNICAddressField.InsertSeparators( S: String): string;
   begin
      InsertSeparators:= InsertSeparators( S, ':', 4);
   end;


   // -----------------------------------------------------------------

class function dbNICAddressField.InsertSeparators( S:     string;
                                             C:     char;
                                             Count: int32): string;
   var
      Temp:  string;
      i:     integer;
      Len:   integer;
   begin
      Len:= length( S);
      if ( Len < Count) then begin
         exit( S);
      end;

      // Copy the first portion in.
      Temp:= copy( S, 1, Count);

      // Now copy each remaining group preceeded by the separator character
      i:= Count + 1;
      while( i <= Len) do begin
         Temp:= Temp + C + copy( S, i, Count);
         i:= i + Count;
      end; // while

      InsertSeparators:= Temp;
   end; // InsertSeparators()


// *************************************************************************
// * StringToWord64() - Convert the String representation of a NIC address
// *                    to a Long.
// *************************************************************************

class function dbNICAddressField.StringToWord64( const S: String): word64;
   var
      Code: word;
      Temp: string;
   begin
      Temp:= '$' + RemoveNonHexCharacters( S);
      val( Temp, StringToWord64, code);
      if( Code > 0) then begin
         raise dbFieldException.Create(
            'dbNICAddressField.StringToWord64():  ' + S +
            ' is an invalid NIC address.');
      end;
   end; // StringToWord32()


// *************************************************************************
// * Word32ToString() - Convert the long representation of an IP address
// *                    to a String.
// *************************************************************************

class function dbNICAddressField.Word64ToString( const X: word64): string;
   begin
      Word64ToString:= InsertSeparators( HexStr( int64(X), NICSize));
   end; // Word32ToString()


// -------------------------------------------------------------------------

class function dbNICAddressField.Word64ToString( const X: word64;
                                                 C:       char;
                                                 Count:   int32): string;
   begin
      Word64ToString:= InsertSeparators( HexStr( int64(X), NICSize), C, Count);
   end; // Word32ToString()


// *************************************************************************
// * GetValue() - Returns the value of the field as a string.
// *************************************************************************

function dbNICAddressField.GetValue(): string;
   begin
      GetValue:= Word64ToString( NewValue);
   end; // GetValue();


// *************************************************************************
// * GetOrigValue() - Returns the original value of the field as a string
// *************************************************************************

function dbNICAddressField.GetOrigValue(): string;
   begin
      GetOrigValue:= Word64ToString( OrigValue);
   end; // GetOrigValue();


// *************************************************************************
// * SetValue() - Set the value of the field from the passed string
// *************************************************************************

procedure dbNICAddressField.SetValue( InputValue: String);
   begin
      NewValue:= StringToWord64( InputValue);
      HasChangedFlag:= ( NewValue <> OrigValue);
   end; // SetValue()


// -------------------------------------------------------------------------

procedure dbNICAddressField.SetValue( InputValue: Word64);
   begin
      NewValue:= Inputvalue;
      HasChangedFlag:= (NewValue <> OrigValue);
   end; // SetValue()


// ========================================================================
// = dbPgMACAddressField
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

function dbPgMACAddressField.GetSQLValue(): string;
   begin
      result:= '''' + HexStr( int64( NewValue), NICSize) + '''';
   end; // GetSQLValue()


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

function dbPgMACAddressField.GetSQLOrigValue(): string;
   begin
      result:= '''' + HexStr( int64( OrigValue), NICSize) + '''';
   end; // GetSQLValue()


// ************************************************************************
// * Create() - Constructor
// ************************************************************************

function dbPgMACAddressField.GetSQLCreate(): string;
      begin
         raise dbFieldException.Create( 'dbPgMACAddressField.GetSQLCreate is not currently  suported');
         result:= '';
      end; // GetSQLCreate()


// *************************************************************************
// * ForceSetValue() - Set the value of the field from the passed string
// *************************************************************************

procedure dbPgMACAddressField.ForceSetValue( InputValue: String);
   begin
      NewValue:= StringToWord64( InputValue);
      HasChangedFlag:= ( NewValue <> OrigValue);
   end; // ForceSetValue()


   // *************************************************************************
// * Unit Initialization and Finalization
// *************************************************************************

initialization
begin
   BitSetAll:= MaxWord64;
end;


// *************************************************************************

end.  // lbp_sql_fields unit
