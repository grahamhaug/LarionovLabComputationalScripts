# LarionovLabComputationalScripts
Useful scripts for data processing/job management of Gaussian 16 input/output in a Linux environment. All of these are bash scripts, but I plan on re-writing/conceiving some of these in python, soon. The eventual goal is autonomous job submission/management and minimal back-end user involvement in processing data.   

### pASDI ###
Automates the setup process for Activation Strain/Distortion Interaction analysis. Extracts geometries from an IRC.log file. Creates .xyz files for:
FullInput.xyz (each iteration)
User-defined fragment1.xyz (each iteration)
User-defined fragment2.xyz (each iteration)
User can then auto-create G16 input.coms from generated .xyzs using common DFT methods (can batch submit with pPool)

### pLog ###
Creates general diagnostic file (DFA/Basis/Dispersion/Solvation/Charge/Multiplicity, thermodynamics, GoodVibes corrections, and time cost), SI file, and .xyz files from .logs

### pMO ###
Quickly batch render .cube files for FMOs, a user-defined range of MOs, and spin density

### pPool ###
Generate SBATCH submission files with user-input parameters (hours, queue, allocation, etc.) for one or multiple files simultaneously 

### pRestart ###
Allows for restart of large calculations, including frequency calculations, for calculations using readwritefiles.rwf

### pClog ###
"combine logs" - will combine iterative logs from pRestart, ie. yourjob.log, yourjob2.log, ... , yourjobx.log into a single yourjob-full.log for use with pLog

### pNBO ###
Conduct fragment-based natural population analysis (ex: metal/ligand electron population/ % of total electron population) on molecules from .nbo files 
Useful for generation of NBO parametric data for multivariate analysis (ex: ligand populations across multiple structures)
