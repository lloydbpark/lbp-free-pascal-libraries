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

program days;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_current_time,
   dateutils,
   sysutils;


// ************************************************************************

var
   NumberOfDays: integer = 8;
   DoCovidEmail: boolean = false;
   ToMonday:     array[ 1..7] of integer = ( +1, 0, -1, -2, 4, 3, 2);
   DowStr:       array[ 1..7] of string = ( 'Sunday', 'Monday', 'Tuesday',
                    'Wednesday', 'Thursday', 'Friday', 'Saturday');
   MonthStr:     array[ 1..12] of string = ( 'January', 'February', 'March',
                    'April', 'May', 'June', 'July', 'August', 'September',
                    'October', 'November', 'December');
   DayStr:       array[ 1..31] of string = ('1st', '2nd', '3rd', '4th', '5th',
                    '6th', '7th', '8th', '9th', '10th', '11th', '12th', '13th',
                    '14th', '15th', '16th', '17th', '18th', '19th', '20th',
                    '21st', '22nd', '23rd', '24th', '25th', '26th', '27th',
                    '28th', '29th', '30th', '31st');
   
   

// ***********************************************************************
// * ParseArgv() - check the validity of the command line
// ***********************************************************************

procedure ParseArgv();
   var
      L:    integer;
      N:    string;
      Code: integer;
   begin
      L:= Length( UnnamedParams);
      if( L > 1) then begin
         writeln; writeln;
         writeln( 'You entered too many parameters!');
         writeln; writeln;
         Usage( true);
      end else if( L = 1) then begin
         CurrentTime.Str:= UnnamedParams[ 0] + ' 00:00:00';
      end;

      if ParamSet( 'number-of-days') then begin
         N:= GetParam( 'number-of-days');
         Val( N, NumberOfDays, Code);
         if( Code <> 0) then begin
            raise Exception.Create( 'An invalid number of days was entered!');
         end;
         if( NumberOfDays < 1) then begin
            raise Exception.Create( 'The number of days must be equal to or greater than 1!');
         end;   
      end; 
      DoCovidEmail:= ParamSet( 'covid');
   end; // ParseArgv();

   
// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'Usage:  days [-n days] [start date in YYYY-MM-DD format]');
      InsertUsage( '');
      InsertUsage( 'Simply prints the next two weeks of dates in ''day-of-week, month, day''');
      InsertUsage( '   format for my Growly Notes daily to-do lists');
      InsertUsage( '');
      InsertUsage( 'Options:');
      InsertUsage( '   Start date is optional.  Today''s date is used if none is specified.');
      InsertUsage( '');
      InsertParam( ['n', 'd', 'number-of-days'], true, '', 'The number of days to print.  Defaults to 8');
      InsertParam( ['c', 'covid'], false, '', 'Print out the subject line and body for a work');
      InsertUsage( '                                 from home message to Bob.');
      AddPostParseProcedure( @ParseArgv);
      ParseParams();
   end; // InitArgvParser()


// ************************************************************************
// * PrintDays() - Print the dates to stdout 
// ************************************************************************

procedure PrintDays();
   var
      i:     integer;
      DT:    tDateTime;
      DOW:   string;
      Month: string;
   begin
      DT:= CurrentTime.TimeOfDay;
      for i:= 1 to NumberOfDays do begin
         DOW:=   DowStr[ DayOfWeek( DT)];
         Month:= MonthStr[ MonthOf( DT)];
         Writeln( DOW, ', ', Month, ' ', DayOf( DT));
         DT:= IncDay( DT);
      end; // for
   end; // PrintDays()


// ************************************************************************
// * DateTimeToString() - Return the date time in this format:
// *                      Monday, June 23rd
// ************************************************************************

// ************************************************************************
// * PrintEmail()
// ************************************************************************

procedure PrintEmail();
   var
      DT:           tDateTime;
      MondayDT:     tDateTime;
      FridayDT:     tDateTime;
      ThisOrNext:   string = 'next';
      MondayOffset: integer;
      FridayOffset: integer;
      MondayStr:    string;
      FridayStr:    string;
   begin
      DT:= CurrentTime.TimeOfDay;
      MondayOffset:= ToMonday[ DayOfWeek( DT)];
      FridayOffset:= MondayOffset + 4;

      MondayDT:= IncDay( DT, MondayOffset);
      FridayDT:= IncDay( DT, FridayOffset);

      MondayStr:= DowStr[ DayOfWeek( MondayDT)] + ', ' +
                  MonthStr[ MonthOf( MondayDT)] + ' ' + 
                  DayStr[ DayOfTheMonth( MondayDT)];
      FridayStr:= DowStr[ DayOfWeek( FridayDT)] + ', ' +
                  MonthStr[ MonthOf( FridayDT)] + ' ' + 
                  DayStr[ DayOfTheMonth( FridayDT)];

      writeln( 'Working from home the week of ' + MondayStr + ' through ' +
               FridayStr);
      writeln;
      writeln;
      writeln( 'Hi Bob,');
      writeln;
      if( MondayOffset <= 0) then begin
         write( 'I''m sorry I''m late sending this to you.  I''m working ' +
                'from home this week, ' + MondayStr + ' through ' +
                FridayStr);
      end else begin
         write( 'I''m planning on working from home next week, ' +
                 MondayStr + ' through ' + FridayStr);
      end;
      writeln;
      writeln;
   end; // PrintEmail()


// ************************************************************************
// * main()
// ************************************************************************

begin
   InitArgvParser;
   writeln;
   if( DoCovidEmail) then PrintEmail() else PrintDays();
   writeln;
end.  // days
