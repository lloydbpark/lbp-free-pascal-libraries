{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

This is my workspace for building new CSV filters.  Its a little easier to
build them here in a small file rather than in the large lbp_csv_filter.pas
file.

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

unit csv_new_filter;

// This is a temporary location to hold new filters as they are being built
// and tested.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_argv,
   lbp_types,
   lbp_generic_containers,
   lbp_parse_helper, // CurrencyChrs
   lbp_csv_filter_aux,
   lbp_csv_filter,
   lbp_csv,
   lbp_ip_utils,
   sysutils;


// *************************************************************************
// * tCsvExtractIPv4()
// *************************************************************************

type
   tCsvExtractIPv4Filter = class( tCsvFilter)
      protected
         HeaderSent: boolean;
         iCellName:  string;
         oCellName:  string;
         iCellIndex: integer; // Index to the input cell
         oCellIndex: integer; // Index to the output cell
         IndexMap:   tIntegerArray;
         NewLength:  integer;
      public
         constructor Create( InputCellName: string; OutputCellName: string = '');
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvExtractIPv4Filter


// *************************************************************************

implementation

// ========================================================================
// = tCsvExtractIPv4Filter class - Finds the IPv4 address in the input cell,
// =                         extracts it, and saves it in the output cell.
// =                         if OutputCellName contains an empty string
// =                         then the the extracted value is saved in the
// =                         input cell instead.
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvExtractIPv4Filter.Create( InputCellName:  string; 
                                    OutputCellName: string = '');
   begin
      inherited Create();
      iCellName:=  InputCellName;
      oCellName:=  OutputCellName;
      iCellIndex:= -1;
      oCellIndex:= -1;
      HeaderSent:= false;
   end; // Create() 


// *************************************************************************
// * SetInputHeader()
// *************************************************************************

procedure tCsvExtractIPv4Filter.SetInputHeader( Header: tCsvCellArray);
      var
      i:          integer;
      iMax:       integer;
      j:          integer;
      L:          integer; // length of one of the headers
      NewHeader:  tCsvCellArray;
      AddCol:     boolean;
      FoundIn:    boolean = false; // True when we found the input header name
   begin
      L:= Length( Header);
      SetLength( IndexMap, L);
      AddCol:= (Length( oCellName) > 0);
      if( AddCol) then begin
         NewLength:= L + 1;
      end else begin
         oCellName:= iCellName;
         NewLength:= L;
      end;
      SetLength( NewHeader, NewLength);

      // Copy the column names to the new header
      i:= 0; 
      j:= 0;
      iMax:= L - 1;
      while( i <= iMax) do begin
         if( AddCol and (Header[ i] = oCellName)) then begin
            raise tCsvException.Create( 'The input header column name already exists!');
         end;
         NewHeader[ j]:= Header[ i];
         IndexMap[ i]:= j;
         if( (not FoundIn) and (Header[ i] = iCellName)) then begin
            FoundIn:= true;
            iCellIndex:= i;
            if( AddCol) then begin
               inc( j);
               NewHeader[ j]:= oCellName;
            end;
            oCellIndex:= j;
         end;
         inc( i);
         inc( j);
      end; // while

      if( not FoundIn) then begin
         raise tCsvException.Create( 'The passed header name was not found in the CSV''s headers!');
      end;

      // Pass the new header to the next filter
      if( not HeaderSent) then begin
         NextFilter.SetInputHeader( NewHeader);
         HeaderSent:= true;
      end;
   end; // SetInputHeader


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvExtractIPv4Filter.SetRow( Row: tCsvCellArray);
   var
      NewRow: tCsvCellArray;
      iMax:   integer;
      iOld:   integer;
      iNew:   integer;
   begin
      SetLength( NewRow, NewLength);
      // Trasfer fields from Row to NewRow;
      iMax:= Length( Row) - 1;
      for iOld:= 0 to iMax do begin
         iNew:= IndexMap[ iOld];
         NewRow[ iNew]:= Row[ iOld];
         NewRow[ oCellIndex]:= IPWord32ToString(IPStringToWord32( Row[ iCellIndex]));
      end;
      NextFilter.SetRow( NewRow);
   end; // SetRow();


// *************************************************************************

end.  // csv_new_filter unit
