#!/bin/tcsh
mkdir -p spark
mkdir -p spark/English.lproj

sdp -f ast -i CustomCoreSuite.sdef -o spark/ -V "10.3" SparkEditorSuite.sdef
#mv spark/SparkSuite.scriptTerminology spark/English.lproj/SparkSuite.scriptTerminology
mv spark/SparkEditorSuiteScripting.r spark/Spark\ Scripting.r
Rez spark/Spark\ Scripting.r -o spark/SparkScript.rsrc