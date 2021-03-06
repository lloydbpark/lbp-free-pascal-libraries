{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Handle timed events in a threaded environment

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

unit lbp_cron;

// SMALL unit to handle timed events.
// While lbp_cron works in a multi-threaded environment,
//    the list of cron jobs is global and you shouldn't
//    run multiple copies.
// Calling StartCron() starts the processing of CronJobs
//
interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_lists,
   lbp_types,    // Debug_Unit_Initialization variable
   lbp_current_time,
   classes,
   dateutils,
   sysutils;


// *************************************************************************

type
   tCronMaster = class
      protected
         CronStopEvent: pRTLEvent;
      public
         constructor Create();
         destructor  Destroy(); override;
         procedure   StartCron(); virtual;
         procedure   StopCron();  virtual;
         procedure   DoCronJobs(); virtual;
         procedure   CronWait();   virtual;
      end; // tCronMaster class


// -------------------------------------------------------------------------

type
   tCronJobSortElement = class(tThread)
      public
         SortValue:   tDateTime;
         constructor  Create( iSortValue: tDateTime);
         destructor   Destroy(); override;
      end; // tCronJobSortElement


// -------------------------------------------------------------------------

   tCronJobSortElementList = class( DoubleLinkedList)
      private
         DuplicatesAllowed: boolean;
      public
         constructor    Create( iDuplicatesAllowed: boolean);
         constructor    Create( iDuplicatesAllowed: boolean;
                                const iName: String);
         procedure Insert( SE: tCronJobSortElement);
      end; // tCronJobSortElementList


// -------------------------------------------------------------------------

type
   tCronJob = class( tCronJobSortElement)
      private
         MyInterval:   integer;  // 0 = one shot
         DestroyFlag:  boolean;
         IsInList:     boolean;
         // Synchronization Events
         StartEvent:   pRTLEvent;
      public
         constructor   Create( iEventTime: tDateTime; iInterval: integer);
         destructor    Destroy();     override;
         procedure     DoEvent();  virtual;
      private
         procedure     SetEventTime( iEventTime: tDateTime); virtual;
         function      GetEventTime(): tDatetime;            virtual;
         procedure     SetInterval( iInterval: integer);     virtual;
         function      GetInterval(): integer;               virtual;
         procedure     SetDestroyAfterEvent( D: boolean);    virtual;
         function      GetDestroyAfterEvent(): boolean;      virtual;
      protected
         procedure     Execute(); override;
      public
         property      EventTime: tDateTime read GetEventTime write SetEventTime;
         property      Interval:  integer read GetInterval  write SetInterval;
         property      DestroyAfterEvent: boolean read  GetDestroyAfterEvent
                                                 write SetDestroyAfterEvent;
      end; // tCronJob class


// *************************************************************************

var
   CronList:      tCronJobSortElementList;  // Used by the signal handler to
                                         // perform Cron functionality
   CronListCS:    TRTLCriticalSection;   // Use this to control access to
                                         // CronList for multiple threads
   CronMaster:    tCronMaster;


// *************************************************************************

procedure StartCron();
procedure StopCron();

// *************************************************************************

implementation

// *************************************************************************

// =========================================================================
// = Global functions
// =========================================================================
// *************************************************************************
// * StartCron() - Start the cron loop to process cron jobs.
// *************************************************************************

procedure StartCron();
   begin
      CronMaster.StartCron();
   end; // StartCron();


// *************************************************************************
// * StopCron() - Stop  the cron loop
// *************************************************************************

procedure StopCron();
   begin
      CronMaster.StopCron();
   end; // StopCron()



// =========================================================================
// = tCronMaster class
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCronMaster.Create();
   begin
      CronMaster:= self;
      CronIsRunning:= false;
      CronStopEvent:= RTLEventCreate();
   end; // Create();

// *************************************************************************
// * Destroy() - destrcuctor
// *************************************************************************

destructor tCronMaster.Destroy();
   begin
      if( CronIsRunning) then begin
         StopCron();
      end;
      RTLEventDestroy( CronStopEvent);
      inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * DoCronJobs() - Check our cron jobs and see if they need done.
// *************************************************************************

procedure tCronMaster.DoCronJobs();
   var
      Temp: tCronJob;
   begin
      // Check for timed events
      EnterCriticalSection( CronListCS);
      Temp:= tCronJob( CronList.GetFirst());
      LeaveCriticalSection( CronListCS);

      while( (Temp <> nil) and
            (CompareDateTime( Temp.EventTime, CurrentTime.TimeOfDay) <= 0)) do begin
         RTLEventSetEvent( Temp.StartEvent);
         if( Temp.Interval > 0) then begin
            // Set a new Event Time
            Temp.EventTime:=
               IncMillisecond( CurrentTime.TimeOfDay, Temp.Interval * 1000);
         end else begin

            // Remove the job from the queue
            EnterCriticalSection( CronListCS);
            CronList.Remove( Temp);
            LeaveCriticalSection( CronListCS);
         end;

         EnterCriticalSection( CronListCS);
         Temp:= tCronJob( CronList.GetFirst());
         LeaveCriticalSection( CronListCS);
      end;
   end; // DoCronJobs()


// *************************************************************************
// * CronWait() - Wait for about 1 second()
// *************************************************************************

procedure tCronMaster.CronWait();
   begin
      RTLEventWaitFor( CronStopEvent, 1000);
   end; // CronWait();

// *************************************************************************
// * StartCron() - Start the cron loop to process cron jobs.
// *************************************************************************

procedure tCronMaster.StartCron();
   begin
      if( not CronIsRunning) then begin
         CronIsRunning:= true;

         // Cron loop continues until it recieves a stop event;
         while( CronIsRunning) do begin

            CurrentTime.Now;
            DoCronJobs();

            // Now wait about one second,
            CronWait();
         end;
      end;
   end; // StartCron()


// *************************************************************************
// * StopCron() - Stop the cron loop.
// *************************************************************************

procedure tCronMaster.StopCron();
   begin
      CronIsRunning:= false;
      RTLEventSetEvent( CronStopEvent);
   end; // StopCron();


// =========================================================================
// = tCronJob - Time triggered events
// =========================================================================
// *************************************************************************
// * Constructor Create()
// *************************************************************************

constructor tCronJob.Create( iEventTime: tDateTime; iInterval: integer);
   var
      TempEventTime: tDateTime;
   begin
      StartEvent:= RTLEventCreate();

      // If we don't have a specific time in mind, set it for iInterval
      // seconds past now.
      TempEventTime:= iEventTime;
      if( TempEventTime = 0.0) then begin
         TempEventTime:=
            dateutils.IncMillisecond( CurrentTime.TimeOfDay, iInterval * 1000);
      end;

      inherited Create( TempEventTime);

      MyInterval:= iInterval;
      if( (iEventTime <> 0.0) or (iInterval <> 0)) then begin
         EnterCriticalSection( CronListCS);
         CronList.Insert( Self);
         IsInList:= true;
         LeaveCriticalSection( CronListCS);
      end else begin
         IsInList:= false;
      end;

      DestroyFlag:= false;  // Let the creating process do housekeeping.
   end; // Create()


// *************************************************************************
// * Destructor Destroy();
// *************************************************************************

destructor tCronJob.Destroy();
   begin
      if( IsInList) then begin
         EnterCriticalSection( CronListCS);
         CronList.Remove( Self);
         IsInList:= false;
         LeaveCriticalSection( CronListCS);
      end;

      // Tell the job to stop running and wait for it to finish.
      Terminate(); // Tell the thread to stop
      RTLEventSetEvent( StartEvent);
      WaitFor();

      RTLEventDestroy( StartEvent);

      inherited Destroy;
   end; // Destroy()


// *************************************************************************
// * DoEvent() - The event triggered by time
// *************************************************************************

procedure tCronJob.DoEvent();
   begin
      writeln( 'tCronJob.DoEvent():  Override this!');
   end; // DoEvent();


// *************************************************************************
// * SetEventTime() - Set the time when the next event should occur.
// *************************************************************************

procedure tCronJob.SetEventTime( iEventTime: tDateTime);
   begin
      EnterCriticalSection( CronListCS);
      if( IsInList) then begin
         CronList.Remove( self);  // remove from the current position in the list
      end;
      SortValue:= iEventTime;
      CronList.Insert( self);  // and add it back in at the proper new location.
      IsInList:= true;
      LeaveCriticalSection( CronListCS);
   end; // SetEventTime();


// *************************************************************************
// * GetEventTime() - Returns the time when the next event will occur.
// *************************************************************************

function tCronJob.GetEventTime(): tDateTime;
   begin
      EnterCriticalSection( CronListCS);
      result:= SortValue;
      LeaveCriticalSection( CronListCS);
   end; // SetEventTime();


// *************************************************************************
// * SetInterval() - Set the time when the next event should occur.
// *************************************************************************

procedure tCronJob.SetInterval( iInterval: integer);
   var
      TempEventTime: tDateTime;
   begin
      EnterCriticalSection( CronListCS);

      if( IsInList) then begin
         CronList.Remove( self);  // remove from the current position in the list
         IsInList:= false;
      end;
      myInterval:= iInterval;

      LeaveCriticalSection( CronListCS);

      if( MyInterval <> 0) then begin
         TempEventTime:= CurrentTime.TimeOfDay;
         IncMilliSecond( TempEventTime, int64( MyInterval) * int64( 1000));
         SetEventTime( TempEventTime);
      end;
   end; // SetInterval();


// *************************************************************************
// * GetInterval() - Get the time interval between each DoEvent call
// *************************************************************************

function tCronJob.GetInterval(): integer;
   begin
      GetInterval:= myInterval;
   end; // SetInterval();


// *************************************************************************
// * SetDestroyAfterEvent()
// *************************************************************************

procedure tCronJob.SetDestroyAfterEvent( D: boolean);
   begin
      DestroyFlag:= D;
   end; // SetDestroyAfterEvent()


// *************************************************************************
// * GetDestroyAfterEvent() - Children can override this to perform
// *                          processing before the job is removed from the
// *                          queue.
// *************************************************************************

function tCronJob.GetDestroyAfterEvent(): boolean;
   begin
      result:= DestroyFlag;
   end; // GetDestroyAfterEvent()


// *************************************************************************
// * Execute() - The main loop of the tThread
// *************************************************************************

procedure tCronJob.Execute();
   begin
      while( not Terminated) do begin
         RTLEventWaitFor( StartEvent);
         if( not Terminated) then begin
            DoEvent();
         end;
      end;
   end; // Execute()



// =========================================================================
// = tCronJobSortElement - Base element stored in a sorted array
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tCronJobSortElement.Create( iSortValue: tDateTime);
   begin
      SortValue:=  iSortValue;
      inherited Create( false);
   end; // Constructor


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tCronJobSortElement.Destroy();
   begin
      inherited Destroy;
   end; // Destructor


// =========================================================================
// = tCronJobSortElementList - A list of info elements.
// =========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tCronJobSortElementList.Create( iDuplicatesAllowed: boolean);
  begin
     inherited Create();
     DuplicatesAllowed:= iDuplicatesAllowed;
  end; // Create()

// ------------------------------------------------------------------------

constructor tCronJobSortElementList.Create( iDuplicatesAllowed: boolean;
                                         const iName: String);
  begin
     inherited Create( iName);
     DuplicatesAllowed:= iDuplicatesAllowed;
  end; // Create()


// *************************************************************************
// * Insert() - Insert the new element in sorted order.
// *************************************************************************

procedure tCronJobSortElementList.Insert( SE: tCronJobSortElement);
   var
      Temp:  tCronJobSortElement;
   begin
      Temp:= tCronJobSortElement( GetFirst());

//{$ERROR Insert tDateTime compare routine below}

      while( (Temp <> nil) and (Temp.SortValue < SE.SortValue)) do begin
         Temp:= tCronJobSortElement( GetNext());
      end;

      if( Temp = nil) then begin
         Enqueue( SE);
      end else begin

         // Check for duplicates
         if( (not DuplicatesAllowed) and
             (Temp.SortValue = SE.SortValue)) then begin
            exit;
         end;

         InsertBeforeCurrent( SE);
      end;
   end; // Insert()


// =========================================================================
// = Initialization/Finalization
// =========================================================================
var
   TempJob: tCronJob;
//   MyCronMaster: tCronMaster;

// *************************************************************************
// * Initialization
// *************************************************************************

initialization
   begin
      if( lbp_types.show_init) then begin
         writeln( 'Initialization of lbp_cron started.');
      end;
      CronMaster:= tCronMaster.Create();

      CronList:=    tCronJobSortElementList.Create( true);
      InitCriticalSection( CronListCS);
      if( lbp_types.show_init) then begin
         writeln( 'Initialization of lbp_cron ended.');
      end;
   end; // initialization


// *************************************************************************
// * Finalization
// *************************************************************************

finalization
   begin
      if( lbp_types.show_init) then begin
         writeln( 'Finalization of lbp_cron started.');
      end;
      if( CronIsRunning) then begin
         StopCron();
      end;
      CronMaster.Destroy();
      TempJob:= tCronJob( CronList.Dequeue);
      while( TempJob <> nil) do begin
         TempJob.IsInList:= false;
         if( TempJob.DestroyAfterEvent) then begin
            TempJob.Destroy();
         end;
         TempJob:= tCronJob( CronList.Dequeue);
      end;
      CronList.Destroy();
      DoneCriticalSection( CronListCS);
      Sleep( 100); // Sleep for 1/10th of a second to let threads complete.
      if( lbp_types.show_init) then begin
         writeln( 'Finalization of lbp_cron ended.');
      end;
   end; // finalization


// *************************************************************************

end. // lbp_cron unit

