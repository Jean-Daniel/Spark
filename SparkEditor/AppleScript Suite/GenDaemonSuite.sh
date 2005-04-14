#!/bin/tcsh
mkdir -p daemon
#mkdir -p daemon/English.lproj

sdp -f ast -i CustomCoreSuite.sdef -o daemon/ -V "10.3" SparkSuite.sdef
#mv daemon/SparkSuite.scriptTerminology daemon/English.lproj/SparkSuite.scriptTerminology
mv daemon/SparkSuiteScripting.r daemon/Spark\ Scripting.r
#Rez daemon/SparkSuiteScripting.r -o daemon/SparkScript.rsrc
