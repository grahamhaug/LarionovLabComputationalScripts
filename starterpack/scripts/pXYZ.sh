#!/bin/bash

#pXYZ
#v1.1
#GCH - 4/24/20
#last edited: 4/2/2021

#This will find the FINAL optimized geometry from an opt/freq job
#it avoids geometries read from .chk reads early in a --link1-- optimization

#Determine the name of the input.log
outputName=$(basename "$1" .log)

#chunk the log into something manageable - save it to "selection"
awk '/Charge =/,/GINC/ {print}' $1 > selection 

#Get line numbers for Start/Stop of the geometry section(s) 
#pull out the line numbers for "Redundant internal coordinates" - start lines for geometries in .log files
startGeom=$(awk '/Redundant internal/ {print FNR}' selection | tr '\n\r' ' ')
#save these into an array
IFS=' ' read -r -a startArray <<< "$startGeom"
#pull out the line numbers for "Redundant internal coordinates" - start lines for geometries in .log files
endGeom=$(awk '/Recover conn/ {print FNR}' selection | tr '\n\r' ' ')
#save these into an array
IFS=' ' read -r -a endArray <<< "$endGeom"

#variables to hold the array count
startCount="${#startArray[@]}"
endCount="${#endArray[@]]}"

#pull out the geometry and format it in .xyz format - tab separated
if [ "$startCount" -ne 0 ]; then
	#pass the last start/stop lines - the last geometry match - to these variables for reading into awk
	finalStart=${startArray[-1]}
	finalEnd=${endArray[-1]}
	
	awk "NR==$finalStart,NR==$finalEnd" selection > tempGeom
	finalGeom=$(awk -F ',' '{printf "%-5s %-15s %-15s %-15s \n", $1, $3, $4, $5}' tempGeom |  sed -e '/^[^0-9]*$/d')
	
	#pull everything together for the final format of .xyz files
	echo -n "$finalGeom" | grep -c '^'
	echo "$outputName"
	echo "$finalGeom"
fi

if [ -z "$finalGeom" ]; then
	inputGeom=$(awk '/Charge =/,/ITRead=/' $1 | head -n -2 | tail -n+2)
	echo -n "$inputGeom" | grep -c '^'
	echo "$outputName"
	echo "$inputGeom"
fi

rm -rf selection tempGeom
