#!/usr/bin/awk -f
##############################################################
#                                                            #
# "extract_irc.awk" by Fernando R. Clemente (Gaussian, Inc.) #
#                   July 2021                                #
#                                                            #
#    UTILITY TO EXTRACT IRC ENERGIES, REACTION COORDINATES,  #
#    AND GEOMETRIES FROM A GAUSSIAN FORMATTED CHECKPOINT     #
#    FILE.                                                   #
#                                                            #
#    Usage:  extract_irc.awk  example.fchk  >  example.txt   #
#                                                            #
##############################################################
# Read number of atoms.
/^Number of atoms/ { NAtoms = $NF }
# Read array with integer atomic numbers (Z) for atoms in the molecule.
/^Atomic numbers/ {
    NVal = $NF
    I = 0
    while (I < NVal) {
        getline
        for (J=1;J<=NF;J++) {
            I++
            Z[I] = $J
            }
        }
    }
# Read IRC reference energy (ERef).
/^IRC Reference Energy/ { ERef = $NF }
# Read array with IRC results. Currently, there are two results per
# geometry (IRC point), the first one is the energy of the IRC point
# (EIRC in Hartrees) relative to the reference energy, and the second one
# is the value of the reaction coordinate (IRC in amu^(1/2) * Bohr).
# From here we will also find out the number of IRC points that are
# stored (NPoints).
/^IRC point       1 Results for each geome/ {
    NVal = $NF
    Pt = 0
    I = 0
    while (I < NVal) {
        getline
        for (J=1;J<=NF;J++) {
            I++
            if (I % 2 == 0) {
                IRC[Pt] = $J
                }
            else {
                Pt++
                # Store energy of the point (add reference energy to read value).
                EIRC[Pt] = ERef + $J
                }
            }
        }
    NPoints = Pt
    }
# Read IRC geometries (GIRC). One geometry per IRC point, 3 Cartesian coordinates
# per atom. Cartesian coordinates (X,Y,Z) are stored in Bohr in the FCHK file, and
# this script converts them to Angstrom.
/^IRC point       1 Geometries/ {
    # Angstrom/Bohr conversion factor.
    ToA = 0.52917721092
    NVal = $NF
    Pt = 1
    At = 1
    IC = 1
    I = 0
    while (I < NVal) {
        getline
        for (J=1;J<=NF;J++) {
            I++
            GIRC[Pt,At,IC] = $J * ToA
            if (IC == 3) {
                IC = 0
                if (At == NAtoms) {
                    At = 0
                    Pt++
                    }
                At++
                }
            IC++
            }
        }
    }
# Done reading the information we wanted from the FCHK file.
# Loop over each IRC point and print the results (energy,
# reaction coordinate, and geometry).
END {
    printf("IRC Results read from FCHK file\n")
    printf(" Energies in Hartree\n")
    printf(" Reaction coordinates in amu^(1/2) * Bohr\n")
    printf(" Cartesian coordinates in Angstrom\n")
    printf("----------\n")
    for (Pt=1;Pt<=NPoints;Pt++) {
        printf("Point %6d | Energy = %20.10f | Reac. Coordinate = %12.5f\n", Pt, EIRC[Pt], IRC[Pt])
        for (At=1;At<=NAtoms;At++) {
            printf("%6d",Z[At])
            for (IC=1;IC<=3;IC++) {
                printf("%20.10f",GIRC[Pt,At,IC])
                }
            printf("\n")
            }
        printf("----------\n")
        }
    }

