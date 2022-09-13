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
- pPool needs to be edited in three ways. First, you need a location on Frontera that will act as a temporary folder to hold jobs before submission. This is the "jobPool" directory - you need to 'mkdir' this directory somewhere. You can put it wherever you want in your /work directory:  
![image](https://user-images.githubusercontent.com/49004818/189981754-5a090e20-417d-4e14-8f94-8f28e5692547.png)  
- Next, you need to specify the location of the g16_SBATCH_template.txt file that pPool will use to make job inputs (this should be your own /scripts dir):  
![image](https://user-images.githubusercontent.com/49004818/189981938-e93e63d8-ec1a-4e5e-bbda-87e0a91cfec8.png)  
- Finally, edit the other line to specify where your alii.env file is (should also be in your /scripts dir):  
![image](https://user-images.githubusercontent.com/49004818/189982069-f1ca6c28-6f52-44a7-beae-a0bf8f71e44b.png)




