import numpy as np
import matplotlib.pyplot as plt
import os

#v1.0
#written by GCH
#3/2/2022

### Reads all .out files in the current directory and makes a .png w/ 3 plots:
# Specified bond distance vs. time (big)
# SCF energy vs. time (small)
# Specified bond distance vs. SCF Energy (small)

#I think these two latter plots could be refined in a future version to extract
#some meaningful information

#ask user for an output name - will create example.png in local dir. 
outputName = input("\nEnter desired filename for output image: ")

#get user input - need two atom indices for bond of interest
#Requires that user enters integer input for atom indices
def takeInt(message):
	while True:
		try:
			userInput = int(input(message))
		except ValueError:
			print("You must enter an integer. Try again.")
			continue
		else:
			return userInput
			break
#can probably extend this to take angles/DHAs as well - have to test
atom1 = takeInt("What is the first atom index? ")
atom2 = takeInt("What is the second atom index? ")

#Gather all Milo output files in the current dir.
input_files = [file for file in os.listdir('.') if os.path.isfile(file) and file.endswith('.out')]
#print(input_files)

#Parameters for figure output graphs' size/shape
gs_kw = dict(height_ratios=[3, 1])
axes = plt.figure(figsize=(24, 12), constrained_layout=True).subplot_mosaic(
                [['topTraces', 'topTraces'], # Note repitition of 'bar'
                 ['leftEnergy', 'rightDistance']], gridspec_kw=gs_kw)

#TO DO
#DONE - prompt user for an output filename for the image produced/saved in LD
#DONE - check that these values are ints / prompt for error if not
#for each index provided by user, get the corresponding atom type from
#the coordinates - store that atomType + atomNum as var for printing to axes below

#grab data for each Milo input file in the current directory
for input_file in input_files:
	#don't need this at the moment, it's for writing to specific output text files
	#input_file_basename = input_file.split("_")[0]

	#grab the molecular coordinates for each calculated step
	with open(input_file, 'rt') as input_text: #, open(input_file_basename + '-test.txt', 'w') as output:
		#this list stores the SCF energies in descending order
		scf_list = []
		#this list stores fs data
		steps_fs = []

		#this list stores the individual lines of a geometry
		stepX_xyz = []
		
		#this list stores each completed geometry 
		stepwise_list = []
		copy = False
		
		#read the Milo log file for the SCF energies and matching geometries, store them into lists
		for line in input_text:
			#captures the SCF energies of each geometry into a list: scf_list
			if "SCF Energy:" in line:
				scf_list.append(float(next(input_text, '').strip()))

			#regex that captures the fs intervals - for x axis
			if "### Step" in line:
				steps_fs.append(float(line.split()[3]))

			#read the output file for blocks starting with "coordinates" and ending in "scf energy"
			#each block matching the above is the geometry of a single step
			#store each such geometry into a list: stepwise_list
			
			#this flag marks the start of each coordinates section	
			if "  Coordinates:" in line:
				#start copying here
				copy = True
				continue

			#this block activates once a "coordinates" block is finished
			#these flags mark the end of each coordinates block	
			#(or the end of the output file)
			elif "SCF Energy:" in line or "Normal termination" in line or "Oh no!" in line:
				#add the captured geometry block to the stepwise_list list 	
				stepwise_list.append(stepX_xyz) 
				#reset the capturing list to empty if end condition is met
				stepX_xyz = []
				#stop copying here	
				copy = False
				continue

			elif copy and line.strip() != "":
				#if "copy" is turned on and the line isn't an empty one, 
				#capture line to the capturing list
				stepX_xyz.append(line.strip().split())


		
	#trim one value off of fs list - I don't remember if this is used, anymore
	#chopped_fs = steps_fs.pop()

	#grab the atom names for graph
	atom1Name = stepwise_list[0][atom1 - 1][0]
	#print(atom1Name)
	atom2Name = stepwise_list[0][atom2 - 1][0]
	
	#can hardcode atoms here
	#atom1 = 1
	#atom2 = 44
	distances = []
	for geometry in stepwise_list[0:-1]:
		# numpy array
		point1 = np.array(geometry[atom1 - 1][1:4], dtype=float) # np array
		point2 = np.array(geometry[atom2 - 1][1:4], dtype=float)
		#print(point1)
		#print(point2)
		dist = np.linalg.norm(point1 - point2) # euclidean distance
		#print(f"Distance: {dist}")
		distances.append(dist)
		#x2, y2, z2 = geometry[atom2 - 1][1:4]
		#print(f"x1: {x1}, y1: {y1}, z1: {z1}")

	#debug
	#print("---------")
	#print(stepwise_list[0][0])
	#make sure everything is the same length
	#for debug:
	#print(f"distances has {len(distances)} elements.")
	#print(f"scf_list has {len(scf_list)} elements.")
	#print(f"steps_fs has {len(steps_fs)} elements.")

	if len(distances) == len(scf_list) == len(steps_fs):
		#print("good to go")
		continue
	else:
		#print("chopping to length")	
		#make a list of data categories and determine the maximum shared value
		list_lengths = [len(distances), len(scf_list), len(steps_fs)] 
		min_value = min(list_lengths)
		#trim values as needed
		distances = distances[:min_value]
		scf_list = scf_list[:min_value]
		steps_fs = steps_fs[:min_value]

	#Plot data to a formatted figure
	#title/axes for each of the subplots
	axes['topTraces'].set_title('Time vs. Bond Distance', fontsize=18)
	axes['topTraces'].set_xlabel('Time (fs)', fontsize=12)
	axes['topTraces'].set_ylabel('{}({}) - {}({}) Distance (A)'.format(atom1Name, atom1, atom2Name, atom2), fontsize=12)

	axes['leftEnergy'].set_title('Time vs. SCF Energy', fontsize=18)
	axes['leftEnergy'].set_xlabel('Time (fs)', fontsize=12)
	axes['leftEnergy'].set_ylabel('SCF Energy (Hartree)', fontsize=12)

	axes['rightDistance'].set_title('Bond Distance vs. SCF Energy', fontsize=18)
	axes['rightDistance'].set_xlabel('{}({}) - {}({}) Distance (A)'.format(atom1Name, atom1, atom2Name, atom2), fontsize=12)
	axes['rightDistance'].set_ylabel('SCF Energy (Hartree)', fontsize=12)

	#plot the data to each subplot
	axes['topTraces'].plot(steps_fs, distances, color='blue', linewidth=2)
	axes['leftEnergy'].plot(steps_fs, scf_list, color='red', linewidth=2)
	axes['rightDistance'].plot(distances, scf_list, color='green', linewidth=2)

#show the plot last
#plt.show()

#save the figure
plt.savefig(f'{outputName}.png')

#closing message
print(f"\n{outputName}.png output to current directory.")
