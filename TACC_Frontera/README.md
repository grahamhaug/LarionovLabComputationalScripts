Scripts for working on TACC's Frontera  

alii.env  
- Defines env variables for each of the scripts so that they can be called by one another
- Edit it to reflect your local environment (point it at your 'home/whatever/scripts' directory)  
- Save the file in your /scripts directory  

Place pLog, pSI, pDiag, pXYZ, pTime, and pPool into your /scripts directory  
- use 'chmod 755 pLog' and etc. to make each script executable (do this from /scripts directory)
- in your bash.rc, add aliases for each of the scripts (refer to picture below):  
![image](https://user-images.githubusercontent.com/49004818/189980680-a39a7978-58f5-4d42-9376-e82f8b518a68.png)

