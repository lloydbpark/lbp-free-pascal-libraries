{* ***************************************************************************

    Copyright (c) 2017 by Lloyd B. Park

    days - Simply prints the next two weeks dates in 'day-of-week, month day'
           format for my Growly Notes daily to-do lists

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or 
    (at your option) any later version.


    This program is distributed in the hope that it will be useful,but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with this program.  If not, see 
    <http://www.gnu.org/licenses/>.

*************************************************************************** *}

program days_between_dates;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_current_time,
   dateutils,
   sysutils;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'Usage:  days_between_dates  <start date in YYYY-MM-DD format>  <end date>');
      InsertUsage( '');
      InsertUsage( 'Simply prints the number of days between two dates');
      InsertUsage( '');
      ParseParams();
   end; // InitArgvParser()


// ************************************************************************
// * main()
// ************************************************************************

var
   Date1:    tlbpTimeClass;
   Date2:    tlbpTimeClass;
   TodayStr: string; 
   L:        integer;
begin
   InitArgvParser;
   
   L:= Length( UnnamedParams);
   if( L = 1) then begin
      TodayStr:= Copy( CurrentTime.Str, 1, 10) + ' 00:00:00';
      Date1:= tlbpTimeClass.Create( TodayStr);
      Date2:= tLbpTimeClass.Create( UnnamedParams[ 0] + ' 00:00:00');
   end else if( L = 2) then begin
      Date1:= tLbpTimeClass.Create( UnnamedParams[ 0] + ' 00:00:00');
      Date2:= tLbpTimeClass.Create( UnnamedParams[ 1] + ' 00:00:00');
   end else begin
      Usage( true);
   end;
   writeln;
   writeln( Abs(DaysBetween( Date1.TimeOfDay, Date2.TimeOfDay)));
   writeln;
   
   Date1.Destroy;
   Date2.Destroy;
end.  // days
