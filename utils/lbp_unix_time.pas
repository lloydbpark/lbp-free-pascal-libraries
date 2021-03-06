{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

convert a date-time value to and from UNIX time format.  

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

unit lbp_unix_time;

// Used by lbp_log and set by lbp_cron.  This unit is simply a
// place to store the current time so we don't have to reformat
// the time every time we call a log function.  lbp_cron, when
// running, updates the the time once per second.
//
interface

{$include lbp_standard_modes.inc}

uses
   lbp_Types,    // Debug_Unit_Initialization variable
   lbp_current_time,
   classes,
   DateUtils,
   SysUtils,
   UnixUtil;


// *************************************************************************

type
   tlbpUnixTimeClass = class( tlbpTimeClass)
      protected
         MyEpoch:      longint;
         GMTTOD:       tDateTime;
         GMTAsString:  string[ 21];
         MyGMTOffset:    int64;
      protected
         function    GetEpoch():     longint;
         procedure   SetEpoch( E:    longint);
         function    GetGMTTOD():    tDateTime;
         procedure   SetGMTTOD(      iTOD: tDateTime);
         function    GetGMTStr():    String;
         procedure   SetGMTStr( DT:  string);
         procedure   SetTimeOfDay(   iTOD: tDateTime); override;
      public
         property    Epoch:          longint read GetEpoch write SetEpoch;
         property    GMTTimeOfDay:   tDateTime read GetGMTTOD write SetGMTTOD;
         property    GMTStr:         string  read GetGMTStr write SetGMTStr;
         property    GMTOffset:      int64   read MyGMTOffset;
      end; // tlbpUnixTimeClass


// *************************************************************************

var
   CurrentTime: tlbpUnixTimeClass;
   EpochStart:  tlbpTimeClass;


// *************************************************************************

implementation

// =========================================================================
// = tlbpUnixTimeClass
// =========================================================================
// *************************************************************************
// * SetEpoch()
// *************************************************************************

procedure tlbpUnixTimeClass.SetEpoch( E: LongInt);
   var
      ST:  tSystemTime;
   begin
      EnterCriticalSection( CritSect);

      with ST do begin
         EpochToLocal( E, Year, Month, Day, Hour, Minute, Second);
         Millisecond:= 0;
      end;
      TimeOfDay:= SystemTimeToDateTime( ST);
      
      LeaveCriticalSection( CritSect);
   end;


// *************************************************************************
// * GetEpoch()
// *************************************************************************

function tlbpUnixTimeClass.GetEpoch(): LongInt;
   begin
      EnterCriticalSection( CritSect);

      result:= MyEpoch;

      LeaveCriticalSection( CritSect);
   end;


// *************************************************************************
// * GetGMTTOD() - Returns a DateTime representing GMT
// *************************************************************************

function tlbpUnixTimeClass.GetGMTTOD(): tDateTime;
   begin
      EnterCriticalSection( CritSect);

      result:= GMTTOD;

      LeaveCriticalSection( CritSect);
   end;


// *************************************************************************
// * GMTStr() - Returns a string representation of GMT
// *************************************************************************

function tlbpUnixTimeClass.GetGMTStr(): string;
   begin
      EnterCriticalSection( CritSect);

      result:= GMTAsString;

      LeaveCriticalSection( CritSect);
   end;


// *************************************************************************
// * SetGMTTOD()
// *************************************************************************

procedure tlbpUnixTimeClass.SetGMTTOD( iTOD: tDateTime);
   var
      ST:         tSystemTime;
      TempEpoch:  longint;
      Temp:       int64;
      NewTOD:     tDateTime;
   begin
      EnterCriticalSection( CritSect);

      with ST do begin
         TOD:= iTOD;
         DecodeTime( iTOD, Hour, Minute, Second, Millisecond);
         DecodeDate( iTOD, Year, Month, Day);
         TempEpoch:= LocalToEpoch( Year, Month, Day, Hour, Minute, Second);
      
         Temp:= SecondsBetween( iTOD, EpochStart.TimeOfDay);
         MyGMTOffset:= int64( TempEpoch) - Temp;
         NewTOD:= incsecond( TOD, -MyGMTOffset);
      end;
      TimeOfDay:= NewTOD;

      LeaveCriticalSection( CritSect);
   end; // SetGMTTOD()


// *************************************************************************
// * SetTimeOfDay()
// *************************************************************************

procedure tlbpUnixTimeClass.SetTimeOfDay( iTOD: tDateTime);
   var
      Temp:     int64;
   begin
      EnterCriticalSection( CritSect);
      
      TOD:= iTOD;
      DecodeTime( iTOD, MyHour, MyMinute, MySecond, MyMillisec);
      DecodeDate( iTOD, MyYear, MyMonth, MyDay);
      AsString:= FormatDatetime( 'yyyy-mm-dd hh:nn:ss', iTOD);
      MyEpoch:= LocalToEpoch( Year, Month, Day, Hour, Minute, Second);
      
      Temp:= SecondsBetween( TimeOfDay, EpochStart.TimeOfDay);
      MyGMTOffset:= int64( Epoch) - Temp;
      GMTTOD:= incsecond( TOD, MyGMTOffset);
      GMTAsString:=  FormatDatetime( 'yyyy-mm-dd hh:nn:ss', GMTTOD);

      LeaveCriticalSection( CritSect);
   end; // SetTimeOfDay()


// *************************************************************************
// * SetGMTStr() - Set the GMT date and time from a string
// *************************************************************************

procedure tlbpUnixTimeClass.SetGMTStr( DT: string);
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
      GMTTimeOfDay:= SystemTimeToDateTime( ST);

      LeaveCriticalSection( CritSect);
   end; // SetGMTStr


// *************************************************************************
// * Initialization
// *************************************************************************

initialization
   begin
      EpochStart:=  tlbpTimeClass.Create( '1970-01-01 00:00:00');
      CurrentTime:= tlbpUnixTimeClass.Create();
   end; // initialization


// *************************************************************************
// * Finalization
// *************************************************************************

finalization
   begin
      CurrentTime.Destroy();
      EpochStart.Destroy();
   end; // finalization


// *************************************************************************
   
end. // lbp_unitx_time unit

