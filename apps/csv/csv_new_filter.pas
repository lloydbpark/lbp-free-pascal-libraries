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
         iIndex:     integer;
         oIndex:     integer;
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
      iCellName:= InputCellName;
      oCellName:= OutputCellName;
      HeaderSent:= false;
   end; // Create() 


// *************************************************************************
// * SetInputHeader()
// *************************************************************************

procedure tCsvExtractIPv4Filter.SetInputHeader( Header: tCsvCellArray);
      var
      HeaderDict: tHeaderDict;
      Name:       string;
      i:          integer;
      iMax:       integer;
      ErrorMsg:   string;
      NewHeader:  tCsvCellArray;
   begin
      // Create and populate the temorary lookup tree
      if( oCellName = '') then begin
         oCellName:= iCellName;
      end;
      HeaderDict:= tHeaderDict.Create( tHeaderDict.tCompareFunction( @CompareStrings));
      HeaderDict.AllowDuplicates:= false;
      iMax:= Length( Header) - 1;
      for i:= 0 to iMax do HeaderDict.Add( Header[ i], i);

      // Create and populate the IndexMap;
      iMax:= NewLength - 1;
      SetLength( IndexMap, NewLength);
      for i:= 0 to iMax do begin
         Name:= NewHeader[ i];
         // Is the new header field in the old headers?
         if( HeaderDict.Find( Name)) then begin
            IndexMap[ i]:= HeaderDict.Value();
         end else begin
            if( AllowNew) then begin
               IndexMap[ i]:= -1; 
            end else begin
               ErrorMsg:= sysutils.Format( HeaderUnknownField, [Name]);
               lbp_argv.Usage( true, ErrorMsg);
            end;
         end; // if/else New Header field was found in the on header 
      end; // for

      // Clean up the HeaderDict
      HeaderDict.RemoveAll();
      HeaderDict.Destroy();
 
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
      iMax:= NewLength - 1;
      for iNew:= 0 to iMax do begin
         iOld:= IndexMap[ iNew];
         if( iOld < 0) then NewRow[ iNew]:= '' else NewRow[ iNew]:= Row[ iOld];
      end;
      NextFilter.SetRow( NewRow);
   end; // SetRow();


// *************************************************************************

end.  // csv_new_filter unit
