{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

define a class to hold a datetime and manipulate its components

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

unit lbp_current_time;

// Used by lbp_log and set by lbp_cron.  This unit is simply a
// place to store the current time so we don't have to reformat
// the time every time we call a log function.  lbp_cron, when
// running, updates the the time once per second.
//
interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_Types,    // Debug_Unit_Initialization variable
   classes,
   DateUtils,
   SysUtils;


// *************************************************************************

type
   tlbpTimeClass = class
      protected
         CritSect:    TRTLCriticalSection;
         TOD:         tDateTime;
         MyYear:      word;
         MyMonth:     word;
         MyDay:       word;
         MyHour:      word;
         MyMinute:    word;
         MySecond:    word;
         MyMillisec:  word;
         AsString:    string[21];
      public
         constructor Create();
         constructor Create( DateStr: string);
         destructor  Destroy(); override;
         procedure   Now();    // Set TimeOfDay equal to the system time
      protected
         procedure   SetTimeOfDay( iTOD: tDateTime); virtual;
         function    GetTimeOfDay():  tDateTime;
         function    GetYear():        word;
         function    GetMonth():       word;
         function    GetDay():         word;
         function    GetHour():        word;
         function    GetMinute():      word;
         function    GetSecond():      word;
         function    GetMillisecond(): word;
         function    GetDayOfWeek():   word;
         function    GetDayOfYear():   word;
         function    GetString():      string;
         procedure   SetString( DT: string);
         function    Val( S: string; sStart: integer; sEnd: integer): word;
      public
         property    Year:        word read GetYear;
         property    Month:       word read GetMonth;
         property    Day:         word read GetDay;
         property    Hour:        word read GetHour;
         property    Minute:      word read GetMinute;
         property    Second:      word read GetSecond;
         property    Millisecond: word read GetMillisecond;
         property    DayOfWeek:   word read GetDayOfWeek;
         property    DayOfYear:   word read GetDayOfYear;
         property    Str:         string read GetString write SetString;
         property    TimeOfDay:   tDateTime read GetTimeOfDay write SetTimeOfDay;
      end; // tlbpTimeClass


// *************************************************************************

var
   CurrentTime:   tlbpTimeClass;
   CronIsRunning: boolean = false;


// *************************************************************************

function  TimeStr(): string; // Return the CurrentTime as a string


// *************************************************************************

implementation

// *************************************************************************

// =========================================================================
// = Global functions
// =========================================================================
// *************************************************************************
// * TimeStr() - Returns current time as a string
// *************************************************************************

function TimeStr(): string;
   begin
      TimeStr:= CurrentTime.AsString;
   end; // TimeStr()


// =========================================================================
// = tlbpTimeClass
// =========================================================================
// *************************************************************************
// * Constructor Create()
// *************************************************************************

constructor tlbpTimeClass.Create();
   begin
      InitCriticalSection( CritSect);
      Now();
   end;


// *************************************************************************
// * Constructor Create()
// *************************************************************************

constructor tlbpTimeClass.Create( DateStr:  string);
   begin
      InitCriticalSection( CritSect);
      Str:= DateStr;
   end;


// *************************************************************************
// * Destructor Destroy();
// *************************************************************************

destructor tlbpTimeClass.Destroy();
   begin
      DoneCriticalSection( CritSect);
   end;


// *************************************************************************
// * GetYear()
// *************************************************************************

function tlbpTimeClass.GetYear(): word;
   begin
      EnterCriticalSection( CritSect);

      result:= MyYear;

      LeaveCriticalSection( CritSect);
   end; // GetYear


// *************************************************************************
// * GetMonth()
// *************************************************************************

function tlbpTimeClass.GetMonth(): word;
   begin
      EnterCriticalSection( CritSect);

      result:= MyMonth;

      LeaveCriticalSection( CritSect);
   end; // GetMonth


// *************************************************************************
// * GetDay()
// *************************************************************************

function tlbpTimeClass.GetDay(): word;
   begin
      EnterCriticalSection( CritSect);

      result:= MyDay;

      LeaveCriticalSection( CritSect);
   end; // GetDay


// *************************************************************************
// * GetHour()
// *************************************************************************

function tlbpTimeClass.GetHour(): word;
   begin
      EnterCriticalSection( CritSect);

      result:= MyHour;

      LeaveCriticalSection( CritSect);
   end; // GetHour


// *************************************************************************
// * GetMinute()
// *************************************************************************

function tlbpTimeClass.GetMinute(): word;
   begin
      EnterCriticalSection( CritSect);

      result:= MyMinute;

      LeaveCriticalSection( CritSect);
   end; // GetMinute


// *************************************************************************
// * GetSecond()
// *************************************************************************

function tlbpTimeClass.GetSecond(): word;
   begin
      EnterCriticalSection( CritSect);

      result:= MySecond;

      LeaveCriticalSection( CritSect);
   end; // GetSecond


// *************************************************************************
// * GetMillisecond()
// *************************************************************************

function tlbpTimeClass.GetMilliSecond(): word;
   begin
      EnterCriticalSection( CritSect);

      result:= MyMillisec;

      LeaveCriticalSection( CritSect);
   end; // GetSecond


// *************************************************************************
// * GetDayOfWeek()
// *************************************************************************

function tlbpTimeClass.GetDayOfWeek(): word;
   begin
      EnterCriticalSection( CritSect);

      result:= word( SysUtils.DayOfWeek( TOD));

      LeaveCriticalSection( CritSect);
   end; // GetDayOfWeek


// *************************************************************************
// * GetString()
// *************************************************************************

function tlbpTimeClass.GetString(): string;
   begin
      EnterCriticalSection( CritSect);

      result:= AsString;

      LeaveCriticalSection( CritSect);
   end; // GetString


// *************************************************************************
// * Val() - Convert a string to a value
// *************************************************************************

function tlbpTimeClass.Val( S: string; sStart: integer; sEnd: integer): word;
   var
      TempL: LongInt;
      Code:  integer;
      TempS: string;
   begin
      TempS:= copy( S, sStart, sEnd);
      Code:= 0;
      System.Val( TempS, TempL, Code);
      if( Code <> 0) then begin
         raise  EConvertError.Create( '"' + S + '" is not a valid word value!');
      end;
      result:= word( TempL);
   end; // Val()


// *************************************************************************
// * SetString() - Set the date and time from a string
// *************************************************************************

procedure tlbpTimeClass.SetString( DT: string);
   var
      ST:  tSystemTime;
   begin
      EnterCriticalSection( CritSect);

      // Year
      ST.Year:=    Val( DT, 1, 4);
      ST.Month:=   Val( DT, 6, 2);
      ST.Day:=     Val( DT, 9, 2);
      ST.Hour:=    Val( DT, 12, 2);
      ST.Minute:=  Val( DT, 15, 2);
      ST.Second:=  Val( DT, 18, 2);
      ST.Millisecond:= 0;
      TimeOfDay:= SystemTimeToDateTime( ST);

      LeaveCriticalSection( CritSect);
   end; // SetString


// *************************************************************************
// * GetDayOfYear()
// *************************************************************************

function tlbpTimeClass.GetDayOfYear(): word;
   begin
      EnterCriticalSection( CritSect);

      result:= DateUtils.DayOfTheYear( TOD);

      LeaveCriticalSection( CritSect);
   end; // GetDayOfYear


// *************************************************************************
// * SetTimeOfDay()
// *************************************************************************

procedure tlbpTimeClass.SetTimeOfDay( iTOD: tDateTime);
   begin
      EnterCriticalSection( CritSect);

      TOD:= iTOD;
      DecodeTime( iTOD, MyHour, MyMinute, MySecond, MyMillisec);
      DecodeDate( iTOD, MyYear, MyMonth, MyDay);
      AsString:= FormatDatetime( 'yyyy-mm-dd hh:nn:ss', iTOD);

      LeaveCriticalSection( CritSect);
   end;


// *************************************************************************
// * GetTimeOfDay()
// *************************************************************************

function tlbpTimeClass.GetTimeOfDay(): tDateTime;
   begin
      EnterCriticalSection( CritSect);

      result:= TOD;

      LeaveCriticalSection( CritSect);
   end;


// *************************************************************************
// * Now() - Set our internal variables to the current system time.
// *************************************************************************

procedure tlbpTimeClass.Now();
   begin
      TimeOfDay:= sysutils.Now();
   end; // Now()



// *************************************************************************
// * Initialization
// *************************************************************************

initialization
   begin
      CurrentTime:= tlbpTimeClass.Create();
   end; // initialization


// *************************************************************************
// * Finalization
// *************************************************************************

finalization
   begin
      CurrentTime.Destroy();
   end; // finalization


// *************************************************************************

end. // lbp_current_time unit

