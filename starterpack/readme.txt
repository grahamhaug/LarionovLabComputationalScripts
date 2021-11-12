1. Add this directory to your $HOME directory

2. Install Python 3.9.5 
  a. untar python-3.9.5.tgz: "tar -xvf python-3.9.5.tgz"
  b. make a local directory in your $HOME to store the new version of python in (TACC uses an older version; this install will supercede): 
      ex: 'mkdir /home1/yourpath/Python_3.9.5'
      move into the untarred directory (not the one you just made)
      
  c. use './configure --prefix=PathToYourCreatedDirectory' ex: './configure --prefix=home1/05793/rdg758/Python_3.9.5'
  d. 'make' 
  e. 'make install' 
  f. make a PATH variable for the new directory (the one you made- ex, in .bashrc: export PATH=/home1/05793/rdg758/Python_3.9.5/bin:$PATH)
  g. Make a symlink for python3.9.5 and pip to get python 3.9.5 instead of the frontera default
    i. change into /bin (within python dir you made).
    ii. use 'ln -s python3.9 python' for python and 'ln -s pip pip3' for pip
  h. refresh with 'bash'
  i. verify install with 'python -V' - should see python 3.9.5
  j. check pip also with 'pip -v'
  
3. Add GoodVibes 
  a. add an alias for the goodvibes directory added with this dir. ex: PYTHONPATH="${PYTHONPATH}:/home1/05793/rdg758/GoodVibes"
  b. export python path: 'export PYTHONPATH'
  c. check that GoodVibes is working with 'python -m goodvibes' 

4. Configure the scripts in /scripts
  a. Open the alii.env file and change the paths to the scripts directory on the current account; save and exit. 
  b. open 'pLog' and change the alii.env line to point at the current location of alii.env on your account
  c. open 'pPool' and change the alii.env line to point at the current location of alii.env on your account
  d. in 'pPool' edit the line "Specify location of sbatch template" - this needs to be in your /scripts
  e. make a directory in your /work directory called jobPool - output and whatnot will be put here until they start. - kind of a placeholder
  f. point the line 'set jobPool directory location' to your new jobPool dir. 
  g. down in the script look for the three other lines that need to have their job dirs changed 
  h. in g16_SBATCH_template:
    i. point alii at the correct place
    ii. point jobPool at the correct place
    iii. there are some hardcoded /scratch directories - need to test if other users can write to here or need their own scratch
    iv. check through this to see if anything else
   
  
  

