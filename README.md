# LarionovLabComputationalScripts
Useful scripts for data processing/job management of Gaussian 16 input/output in a Linux environment.

1. Copy these scripts to your home directory/scripts 

2. Use "chmod 755 scriptname" to make each script executable

3. Add an appropriate alias for each of the scripts to your .bashrc file
  example:
  alias pRestart='/home1/.../scripts/pRestart'
  alias pClog='/home1/.../scripts/pClog'
  alias pPL='/home1/.../scripts/pLog'
  
4. Copy these aliases also into an environment variable, also located in your /scripts directory:
  "vi alii.env"
      alias pRestart='/home1/.../scripts/pRestart'
      alias pClog='/home1/.../scripts/pClog'
      alias pPL='/home1/.../scripts/pLog'
      :wq
  
5. In the pLog script, make sure to change the line below so that it points to your environment variable created in #4:
  #You will need to point this as where your scripts are
  source /home1/.../scripts/alii.env
  


  
