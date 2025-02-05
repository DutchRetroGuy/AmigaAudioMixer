# $VER: GeneratePitchRoutines 1.0 (05.02.25)
#
# GeneratePitchRoutines.py
# This file contains the Python 3 script to generate the pitch routines used by the pitch plugin in MXPLG_PITCH_LEVELS
# for the audio mixer. Normally it is not needed to run this, but the code is provided to show how the routines were
# generated.
#
# Author: Jeroen Knoester
# Version: 1.0
# Revision: 20250205

# Imports
import math
from fractions import Fraction

# Functions


def find_best_rational(num, max_denominator=16):
    # Find the best rational approximation with denominator <= max_denominator
    return Fraction(num).limit_denominator(max_denominator)


def generate_pitch_routine(pitch_factor, level_num):
    # Generate assembly code for a specific pitch factor.
    # pitch_factor: float representing the speed multiplier (e.g., 2.0 for double speed)
    # level_num: integer for the routine number

    # Find rational approximation
    #original_value = pitch_factor
    rational = find_best_rational(pitch_factor)
    warning = ''

    if abs(float(rational) - pitch_factor) > 0.001:
        warning = f"; Rounded {pitch_factor} to nearest rational of {rational.numerator}/{rational.denominator} ({float(rational)})"
        pitch_factor = float(rational)

    # Calculate minimum pattern length needed
    pattern_length = 4
    if rational.denominator > 2:
        # Increase pattern length based on denominator
        if rational.denominator > 2:
            pattern_length = 8
        if rational.denominator > 8:
            pattern_length = 16


    output_bytes = pattern_length
    input_bytes = round(output_bytes * pitch_factor)
    shift_amount = int(math.log2(output_bytes))

    code = []
    if warning:
        code = [warning]

    code.append(f".pitch_level_{level_num}:")
    code.append(f"\t\tasr.w\t#{shift_amount},d2")
    code.append(f".lp_{level_num}")

    # Generate move.b instructions
    for i in range(output_bytes):
        input_pos = math.floor(i * pitch_factor)
        if input_pos == 0:
            code.append("\t\tmove.b\t(a2),(a0)+")
        else:
            code.append(f"\t\tmove.b\t{input_pos}(a2),(a0)+")

    # Add the pointer increment
    if input_bytes <= 8:
        code.append(f"\t\taddq.w\t#{input_bytes},a2")
    else:
        code.append(f"\t\tadd.w\t#{input_bytes},a2")

    code.append(f"\t\tdbra\td2,.lp_{level_num}")
    code.append("\t\trts")
    code.append("")

    return "\n".join(code)


def generate_all_routines(min_pitch, max_pitch, num_steps):
    # Generate assembly routines for a range of pitch values
    # min_pitch: minimum pitch factor
    # max_pitch: maximum pitch factor
    # num_steps: number of pitch levels to generate

    pitch_step = (max_pitch - min_pitch) / (num_steps - 1)
    all_code = []

    for i in range(num_steps):
        pitch = min_pitch + (i * pitch_step)
        all_code.append(generate_pitch_routine(pitch, i))
        
    all_code.append("\tENDIF")

    return "\n".join(all_code)


def generate_jumptable(routine_name,num_steps):
    # Generates the jumptable to be used by the pitch levels routine

    code = [routine_name]
    code.append("\tIF MXPLUGIN_PITCH=1")
    code.append("\t\tadd.w\td0,d0\n\t\tadd.w\td0,d0\n\t\tjmp .jt_table(pc,d0.w)\n\n.jt_table")
    for i in range(num_steps):
        code.append(f"\t\tbra.w\t.pitch_level_{i}")

    code.append("")
    return "\n".join(code)


# Routine name
routine_name = "MixPluginLevels_internal\\1"

# Pitch range to use
min_pitch = 0.25
max_pitch = 4.00
num_steps = 64

# Generate and display result
output = generate_jumptable(routine_name,num_steps)
print(output)
output = generate_all_routines(min_pitch,max_pitch,num_steps)
print(output)