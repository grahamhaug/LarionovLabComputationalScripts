#!/bin/bash

#pSI
#v1.0
#GCH - 3/2/21
#last edited - 11/11/2021

#Extracts E(SCF) and -where applicable- the final optimized geometry from G16 .log files

#Determine the name of the input.log - print it at the top of the output
outputName=$(basename "$1" .log)
echo "$outputName"

#print the SCF energy in Hartree
awk '/Charge =/,/GINC/ {print}' $1 > selection
awk '/A.U. after/ {print $3,$4,$5}' selection > energy
tail -1 energy
echo ""

#print the charge and multiplicity
multiplicity=$(grep 'Charge =' $1 | head -1 | sed -n 's/ \+/ /gp')
echo "$multiplicity" | sed -e 's/Charge/       Charge/' | sed -e 's/Multiplicity/      Multiplicity/'

#Get line numbers for Start/Stop of the geometry section(s)
#pull out the line numbers for "Redundant internal coordinates" - start lines for geometries in .log files
startGeom=$(awk '/Redundant internal/ {print FNR}' selection | tr '\n\r' ' ')
#save these into an array
IFS=' ' read -r -a startArray <<< "$startGeom"
#pull out the line numbers for "Redundant internal coordinates" - start lines for geometries in .log files
endGeom=$(awk '/Recover conn/ {print FNR}' selection| tr '\n\r' ' ')
#save these into an array
IFS=' ' read -r -a endArray <<< "$endGeom"

#make variables to count the number of elements in each array
startCount="${#startArray[@]}"
endCount="${#endArray[@]]}"

#pass the last start/stop lines - the last geometry match - to these variables for reading into awk
if [[ "$startCount" -eq 0 || -z "$startCount" ]]; then
        inputGeom=$(awk '/Charge =/,/ITRead=/' $1 | head -n -2 | tail -n+2)
        echo "Single point geometry:"
        echo "$inputGeom"
elif [ "$startCount" -eq 1 ] && [ "$endCount" = 1 ]; then
        #set the line numbers of finalStart/End to the only values
        finalStart=${startGeom}
        finalEnd=${endGeom}
else
        #if there are more than 1 start/stop counted, choose the last line numbers for each
        finalStart=${startArray[-1]}
        finalEnd=${endArray[-1]}
fi

#pull out the geometry and format it in .xyz format - tab separated
if [ "$startCount" -ne 0 ]; then
        awk "NR==$finalStart,NR==$finalEnd" selection | head -n -1 | tail -n +2 > tempGeom
#	awk "NR==$finalStart,NR==$finalEnd" selection > tempGeom
#        finalGeom=$(awk -F ',' '{printf "%-5s %-15s %-15s %-15s \n", $1, $3, $4, $5}' tempGeom |  sed -e '/^[^0-9]*$/d')
	finalGeom=$(awk -F ',' '{printf "%-4s %15.10f %15.10f %15.10f\n", $1, $3, $4, $5}' tempGeom | sed -e '/^[^0-9]*$/d')
        echo "$finalGeom"
fi



#file cleanup
rm -rf selection energyblock energy energyblock tempGeom

