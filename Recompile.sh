#!/bin/bash

# *************************************************************************
# * This script will recompile all Lloyd's Free Pascal programs.  In order
# * To work properly, each directory which needs to be compiled should be 
# * listed in the variable below.  Order is important!  For example, since 
# * much of the other code depends on packages in utils, utils should be
# * the first directory listed.
# *************************************************************************

SourceDirs='
   utils
   utils/net
   utils/tests
   ldap
   sql
   homeschool
   lloyd/compiler
   apps/cvs-move-root
   apps/ssh-url-handler
   apps/string-to-unix-time
   apps/xcolor-to-apple
   dhcp
'


# *************************************************************************
# Possible base Free Pascal code directories.  If there are multiple matches, 
# only the last one will be used.
# *************************************************************************

AllowedBaseDirs='
   H:\programming\pascal\lbp
   programming/pascal/lbp/
   /opt/programming/pascal/lbp/
'


# *************************************************************************
# * MoveToBaseDir() - cd to the base free pascal code directory
# *************************************************************************

MoveToBaseDir() {
   local TESTDIR
   local HomeDir
   cd ~
   HomeDir=`pwd`
   for TESTDIR in ${AllowedBaseDirs}; do
      if [[ -d ${TESTDIR} ]]; then
         cd ${TESTDIR}
      fi
   done
   
   if [[ ${HomeDir} == `pwd` ]]; then
      echo >&2
      echo >&2
      echo >&2
      echo 'Unable to find the base Free Pascal directory!  Exiting.' >&2
      echo >&2
      echo >&2
      exit -1
   fi 
}


# *************************************************************************
# * CompileDir() - Compile all the pascal code in the passed directory
# *************************************************************************

CompileDir() {
   if [[ ! -d $1 ]]; then
      echo >&2
      echo >&2
      echo '********************************************************' >&2
      echo "* The directory ${SOURCEDIR} does not exist!  Exiting..." >&2
      echo '********************************************************' >&2
      echo >&2
      exit -1
   fi
   
   echo
   echo
   echo '********************************************************'
   echo "* Compiling code in ${SOURCEDIR}"
   echo '********************************************************'
   echo
 
   cd $1
   rm -f *.ppu *.o
   for FILE in *.pas; do
      fpc ${FILE}
   done;
   cd - >/dev/null
}


# *************************************************************************
# * main()
# *************************************************************************

MoveToBaseDir
for SOURCEDIR in ${SourceDirs}; do
   CompileDir ${SOURCEDIR}   
done

echo
echo
echo '********************************************************'
echo "* Done"
echo '********************************************************'
echo
