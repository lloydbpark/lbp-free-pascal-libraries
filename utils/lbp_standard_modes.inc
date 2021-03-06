{$ifdef RELEASE}

{$else}
   // -Crtoi
   {$rangechecks on}
   {$s+} // Stack checks on
   {$overflowchecks on}
   {$iochecks on}

   // -g
   {$debuginfo on}

   // -gh
//   uses heaptrc;

   // -gl
//   uses lineinfo;
{$endif}

// -S2ict
{$mode objfpc}
{$inline on}
// C style =+, etc goes here
{$LONGSTRINGS ON}

// This is available in trunk as of Feb 2013.  It is not in fpc 2.6.5.
//    It will allow functions like this: MyInt.ToString()
//          TIntegerHelper = type helper for Integer
//             function ToString: string;
//          end;
//          function TIntegerHelper.ToString: string;
//             begin
//                Result := IntToStr(Self);
//             end;
{$modeswitch typehelpers}

// -Op1
   // Not available as parameter?

// -Fu~/Pascal-v$fpcver/*
// -Fu~/Pascal-v$fpcver/netserv/*
// -Fu~/Pascal-v$fpcver/netserv/ipdb2/*
// -Fu~/Pascal-v$fpcver/netserv/ipdb2/reports/*
// -Fu~/Pascal-v$fpcver/sql/*
// -Fu~/Pascal-v$fpcver/utils/*
// {$unitpath ~/Pascal=v$fpcver/*}
// {$unitpath ~/Pascal=v$fpcver/netserv/*}
// {$unitpath ~/Pascal=v$fpcver/netserv/ipdb2/*}
// {$unitpath ~/Pascal=v$fpcver/netserv/ipdb2/reports/*}
// {$unitpath ~/Pascal=v$fpcver/sql/*}
// {$unitpath ~/Pascal=v$fpcver/utils/*}

// MySQL library path for linking
// {$ifndef win32}
//    {$LIBRARYPATH /usr/lib/mysql}
// {$endif}
