Bash scripts for working on TACC's Frontera  

### Setup Instructions:

### alii.env  
- Defines env variables for each of the scripts so that they can be called by one another
- Edit it to reflect your local environment (point it at your 'home/whatever/scripts' directory)  
- Save the file in your /scripts directory  


### Place pLog, pSI, pDiag, pXYZ, pTime, pPool, and g16_SBATCH_template.txt into your /scripts directory  
- use 'chmod 755 pLog' and etc. to make each script executable (do this from /scripts directory)
- in your bash.rc, add aliases for each of the scripts (refer to picture below):  
![image](https://user-images.githubusercontent.com/49004818/189980680-a39a7978-58f5-4d42-9376-e82f8b518a68.png)  
- pLog needs to be edited to point to your own scripts directory:  
![image](https://user-images.githubusercontent.com/49004818/189981362-d4d2f905-81a8-4c95-991e-788d8345df49.png)  

### Editing pPool  
- pPool needs to be edited in several ways. First, you need a location on Frontera that will act as a temporary folder to hold jobs before submission. This is the "jobPool" directory - you need to 'mkdir' this directory somewhere. You can put it wherever you want in your /work directory:  
 ![image](https://user-images.githubusercontent.com/49004818/189989742-86eeaae5-48f1-4518-af89-0e3ce2116259.png)  
- Next, you need to specify the location of the /scripts directory:  
![image](https://user-images.githubusercontent.com/49004818/189989813-9686a455-d5c0-4a77-b37e-2e9d05433026.png)





