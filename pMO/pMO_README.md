pMO is used to batch generate high resolution .cube files. These files can be used to render publication quality molecular orbital or spin density images for publication using VMD. 

A video that describes the use of pMO and how to use VMD to render images:  
https://www.youtube.com/watch?v=7yINELAtJr0

### To install: ###
1. Place pMO script in your home/scripts/ directory

2. Place pMO_SBATCH_template.txt in your home/scripts/ directory

3. create an alias for pMO in your bash.rc file:
alias pMO='/home1/YourHome/YourHome/scripts/pMO'

4. use "chmod 755 pMO" to make pMO executable

### To use: ###
call pMO on a log file in the current directory using:  
```
"pMO example.log" 
```
The script is then interactive so long as it finds (a complete) example.log and example.chk in the current directory.  
