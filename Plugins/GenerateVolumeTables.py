#!/usr/bin/env python

# $VER: GenerateVolumeTables 1.0 (12.11.23)
#
# GenerateVolumeTables.py
# This file contains the Python 3 script to generate the volume tables used by the table based volume plugin for the
# audio mixer. Normally it is not needed to run this, but the code is provided to show how the tables were generated.
#
# Author: Jeroen Knoester
# Version: 1.0
# Revision: 20231112

volume_levels=16
level_counter=0
volume_table=[0]*256

# Generating n volume levels means using volume values of 0 to n-1 to select volume. Where 0 is silent and n-1 is max
# volume. Of these, both level 0 and level n-1 don't need to be generated as they are either just the value 0, or
# whatever value the sample originally had.
volume_levels=volume_levels-1
while level_counter<volume_levels-1:
    # Generate volume table
    sample_value=0
    while sample_value<256:
        volume_table[sample_value]=((sample_value-128)/volume_levels)*(level_counter+1)
        sample_value=sample_value+1

    # Print volume table
    output_string=""
    sample_value=0
    while sample_value<256:
        if sample_value==0:
            output_string = output_string + "\n"
            if level_counter+1<10:
                output_string = output_string+"vol_level_"+str(level_counter+1)+"\t\tdc.b "
            else:
                output_string = output_string+"vol_level_"+str(level_counter+1)+"\tdc.b "
        elif sample_value%8==0:
            output_string = output_string + "\n"
            if level_counter+1<10:
                output_string = output_string + "\t\t\t\tdc.b "
            else:
                output_string = output_string + "\t\t\t\tdc.b "

        output_string = output_string + str(round(volume_table[sample_value]))

        if sample_value%8!=7:
            output_string = output_string + ","

        sample_value=sample_value+1
    print(output_string)
    level_counter=level_counter+1

# End of File