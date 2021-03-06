pLog is a general purpose script for processing G16 jobs.  
The target file is "yourjob.log" which should be in the same directory that you call "pLog" 

### Using pLog ###
```
pLog yourjob.log
```

### Expected output ### 
So long as your G16 job had no errors and completed, you should get three output files.  
The contained information in each depends on the nature of your job.  
For a standard minimum optimization and frequency job, you will get 3 files:
```
yourjob-out.txt
yourjob-si.txt
yourjob.xyz
```
If your job did not contain a frequency calculation, the values for "enthalpy" "gibbs" and "gv50" should be empty, as these values require a frequency calculation. 

## Details on output files ##
### yourjob-out.txt ###
#this is output produced by pDiag - general day-to-day job maintenance/info/verification. Also used to extract thermodynamic values from freq jobs for analysis.  
GoodVibes is called by default on freq jobs; pLog expects a working install of goodvibes (see Robert Paton's group website)

### line-by-line pDiag/pTime output:  ###
```
name of file  
functional/dispersion (current function doesn't read split basis sets, yet; will read "gen" for these cases)  
dispersion model  
Solvation (solvent,model)  

SP Energy (hartree)  
Enthalpy (hartree)  
Gibbs (hartree)  
GoodVibes-corrected Gibbs (cutoff of 50 cm-1) (hartree)  

Charge/multiplicity  
*Either single point input geometry (denoted by line "Single point geometry") or the optimized geometry   

Time output (real time for each job and then cumulative time for all jobs in the log) (this output from pTime)  
```

### yourjob-si.txt ###
This output is from pSI - useful for pasting into SI documents before paper submission. Removes most of the details contained in pDiag (-out.txt) outputs

### yourjob.xyz ###
.xyz formatted output for either your optimized geometry or single point geometry (depending on if a single point or optimization job was run). 


### Installation/Configuration ###
1. Ensure all of the requisite files are added to your home/.../scripts directory
  pLog, pDiag, pSI, pXYZ, pTime are all necessary 
  
2. Chmod 755 each of the scripts and add an alias for each to both your a) .bashrc and b) a file in /scripts containing all of your environment variables. 
  alias pTime='/home1/your/folder/scripts/pTime'
  etc...
  
3. Within pLog, you will find the following line. Ensure that it points to the file in your /scripts directory which contains all of your aliases:
  #You will need to point this as where your scripts are
  source /home1/your/folder/scripts/YouEnvFile.env
