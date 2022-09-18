Bash scripts for working on TACC's Frontera HPC  

### Setup Instructions:

### File placement  
Put all of the following files into a /scripts directory in your /home directory:  
- alii.env - *Contains env variables for the scripts to cooperate with one another*
- pPool - *Interactively makes SBATCH input files for one/multiple jobs and submits the jobs*
- pLog - *Processes output if your job completes*
- pDiag - *Makes a your_job-out.txt file containing job info/thermodynamics/geometry/time to complete info*
- pTime - *Calculates how much time your job(s) required*
- pXYZ - *Outputs a correctly formatted .xyz of your job's optimized geometry*
- pSI - *Outputs a formatted file for placement into a SI file*  


### Edit alii.env  
- Defines env variables for each of the scripts so that they can be called by one another
- Edit it to reflect your local environment (point it at your 'home/whatever/scripts' directory)  


### Make scripts executable using 'chmod' command
- From within /scripts, use 'chmod 755 pLog' to make each script executable (do this for pPool, pLog, pDiag, pTime, pXYZ, and pSI)
- If you type 'ls' in the terminal you should see each script in green

### Add aliases for scripts to your .bashrc
- use 'cdh' to move to your /home directory
- type 'vi .bashrc' to open your .bashrc file (be careful with this file)
- scroll down to Section 3:  
![image](https://user-images.githubusercontent.com/49004818/189991651-ba8cf079-06d1-4094-a0aa-13efff5bc5f2.png)
- below "Place any else below" section, add aliases for each of the scripts (refer to picture below but use your paths):  
![image](https://user-images.githubusercontent.com/49004818/189980680-a39a7978-58f5-4d42-9376-e82f8b518a68.png)  

### Edit pLog script to point at your own /scripts directory
- pLog needs to be edited to point to your own scripts directory:  
![image](https://user-images.githubusercontent.com/49004818/189981362-d4d2f905-81a8-4c95-991e-788d8345df49.png)  

### Editing pPool  
- pPool needs to be edited in several ways. First, you need a location on Frontera that will act as a temporary folder to hold jobs before submission. This is the "jobPool" directory - you need to 'mkdir' this directory somewhere. You can put it wherever you want in your /work directory:  
 ![image](https://user-images.githubusercontent.com/49004818/189989742-86eeaae5-48f1-4518-af89-0e3ce2116259.png)  
- Next, you need to specify the location of the /scripts directory:  
![image](https://user-images.githubusercontent.com/49004818/189989813-9686a455-d5c0-4a77-b37e-2e9d05433026.png)  

### Editing the SLURM template
The file g16_SBATCH_template.txt is used as a template for SLURM job submission scripts. You need to edit this file to reflect your own account.  
- First, specify the locations of your alii.env file and your /jobPool directory (same one used by pPool):  
![image](https://user-images.githubusercontent.com/49004818/190917553-1a03a322-aafe-4bd3-ae24-fdff7881d5a1.png)  
- Next, you need to specify the location of your /scratch directory in the following (highlighted) lines:  
![image](https://user-images.githubusercontent.com/49004818/190917619-56b4cbdb-1d78-4300-a14d-ce3734625c37.png)







