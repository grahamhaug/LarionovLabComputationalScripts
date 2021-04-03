pNBO allows users to perform Natural Population Analysis on user-defined molecular fragments from the command line.  

### Use ###
pNBO requires a .nbo file containing the section "Summary of Natural Population Analysis"  
This can be generated from (in our case) the standalone NBOPro@Jmol or via an appropriate (ie: not NBO 3.0 era NBO software) QM-embedded software (NBO6.0).  

Call pNBO via:   
```
pNBO yourfile.nbo
```

### Output ###
Three calculations are reported for a given fragment:  
```
1. Natural Charge
2. number of electrons in the fragment
3. The defined fragment's percentage of the total molecular electron population  
```

For an example of output/use, see the images "using_pNBO1" and "using_pNBO2"  

### Installation ###
1. Place the pNBO script in your home/scripts folder

2. chmod 755 pNBO

3. Add an alias for pNBO into your .bashrc:
```
alias pNBO='/home1/your/directory/scripts/pNBO'
```
