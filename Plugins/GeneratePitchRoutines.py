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
from math import floor


# Functions


def find_best_rational(num, max_denominator=64):
    # Find the best rational approximation with denominator <= max_denominator
    return Fraction(num).limit_denominator(max_denominator)


def generate_pitch_routine_68000(pitch_factor, level_num):
    # Generate assembly code for a specific pitch factor.
    # pitch_factor: float representing the speed multiplier (e.g., 2.0 for double speed)
    # level_num: integer for the routine number

    # Find rational approximation
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
    input_bytes = math.floor(output_bytes * pitch_factor)
    shift_amount = int(math.log2(output_bytes))

    code = []
    if warning:
        code = [warning]

    code.append(f".pitch_level_{level_num}:")
    code.append(f"\t\tasr.w\t#{shift_amount},d2")
    code.append(f"\t\tsubq.w\t#1,d2")
    code.append(f"\t\tbmi.s\t.lp_done_{level_num}")
    code.append("")

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
        code.append(f"\t\taddq.l\t#{input_bytes},d1")
    else:
        code.append(f"\t\tadd.w\t#{input_bytes},a2")
        code.append(f"\t\tadd.l\t#{input_bytes},d1")

    code.append(f"\t\tdbra\td2,.lp_{level_num}")
    code.append("\t\trts")
    code.append("")
    code.append(f".lp_done_{level_num}")
    code.append("\t\tmoveq\t#0,d0")
    code.append("\t\trts")
    code.append("")

    return "\n".join(code)


def generate_pitch_routine_68020(pitch_factor, level_num):
    # Generate assembly code for a specific pitch factor (68020 optimised).
    # pitch_factor: float representing the speed multiplier (e.g., 2.0 for double speed)
    # level_num: integer for the routine number

    # Find rational approximation
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
    input_bytes = math.floor(output_bytes * pitch_factor)
    shift_amount = int(math.log2(output_bytes))

    code = []
    if warning:
        code = [warning]

    code.append(f".pitch_level_{level_num}:")
    code.append(f"\t\tasr.w\t#{shift_amount},d2")
    code.append(f"\t\tsubq.w\t#1,d2")
    code.append(f"\t\tbmi.s\t.lp_done_{level_num}")
    code.append("")

    code.append(f".lp_{level_num}")

    # Generate move.b/.w/.l instructions
    i = 0
    while i < output_bytes:
        input_pos = math.floor(i * pitch_factor)

        # Determine how many bytes are sequential
        cur_bytes_offset = math.floor(i * pitch_factor)
        bytes_count = 1
        byte_counter = 1
        while byte_counter < 4:
            if i+byte_counter >= output_bytes:
                break  # Exceeded maximum length
            if math.floor((i+byte_counter) * pitch_factor) != cur_bytes_offset + 1:
                break  # Can't be combined
            # Add one to current number of consecutive bytes
            bytes_count = bytes_count + 1
            cur_bytes_offset = cur_bytes_offset + 1
            byte_counter = byte_counter + 1

        # Check if cur_bytes_count is 1, 2 or 4 and adjust accordingly
        increment = 1
        postfix = "b"
        if bytes_count == 2:
            increment = 2
            postfix = "w"
        if bytes_count == 4:
            increment = 4
            postfix = "l"

        if input_pos == 0:
            code.append(f"\t\tmove.{postfix}\t(a2),(a0)+")
        else:
            code.append(f"\t\tmove.{postfix}\t{input_pos}(a2),(a0)+")

        i = i + increment

    # Add the pointer increment
    if input_bytes <= 8:
        code.append(f"\t\taddq.w\t#{input_bytes},a2")
        code.append(f"\t\taddq.l\t#{input_bytes},d1")
    else:
        code.append(f"\t\tadd.w\t#{input_bytes},a2")
        code.append(f"\t\tadd.l\t#{input_bytes},d1")

    code.append(f"\t\tdbra\td2,.lp_{level_num}")
    code.append("\t\trts")
    code.append("")
    code.append(f".lp_done_{level_num}")
    code.append("\t\tmoveq\t#0,d0")
    code.append("\t\trts")
    code.append("")

    return "\n".join(code)


def generate_all_routines(min_pitch, max_pitch, num_steps):
    # Generate assembly routines for a range of pitch values
    # min_pitch: minimum pitch factor
    # max_pitch: maximum pitch factor
    # num_steps: number of pitch levels to generate

    pitch_step = (max_pitch - min_pitch) / (num_steps - 1)
    all_code = ["\t\tIF .m68020_indicator=2"]

    for i in range(num_steps):
        pitch = min_pitch + (i * pitch_step)
        all_code.append(generate_pitch_routine_68020(pitch, i))

    all_code.append("\t\tELSE\n")

    for i in range(num_steps):
        pitch = min_pitch + (i * pitch_step)
        all_code.append(generate_pitch_routine_68000(pitch, i))

    all_code.append("\t\tENDIF\n\tENDIF")

    return "\n".join(all_code)


def generate_jump_table(routine_name, num_steps):
    # Generates the jump table to be used by the pitch levels routine

    code = ["\t\t; Internal pitch shifting subroutines\n\t\t; 68020 version uses non-aligned reads"]
    code.append(routine_name)
    code.append("\tIF MXPLUGIN_PITCH=1")
    code.append(".m68020_indicator\tSET MIXER_68020+MXPLUGIN_68020_ONLY")
    code.append("\t\tIF .m68020_indicator=2")
    code.append("\t\t\tmc68020\n\t\t\tjmp .jt_table(pc,d4.w*4)\n\t\t\tmc68000")
    code.append("\t\tELSE")
    code.append("\t\t\tadd.w\td4,d4\n\t\t\tadd.w\td4,d4\n\t\t\tjmp .jt_table(pc,d4.w)")
    code.append("\t\tENDIF\n\n.jt_table")
    for i in range(num_steps):
        code.append(f"\t\tbra.w\t.pitch_level_{i}")

    code.append("")
    return "\n".join(code)


def generate_fp88_pitch_ratios(label_name, min_pitch, max_pitch, num_steps):
    # Generates a table with the pitch ratios used in fixed point 8.8 format

    pitch_step = (max_pitch - min_pitch) / (num_steps-1)
    code = [label_name]
    out = ""

    for i in range(num_steps):
        if i % 8 == 0:
            if out != "":
                out = out[:len(out) - 1]
                code.append(out)
            out = "\t\tdc.w\t"
        pitch = min_pitch + (i * pitch_step)
        ratio = find_best_rational(pitch)
        fp88 = int(round(float(ratio) * 256))  # fixed point 8.8 version of resulting ratio
        out = out + f"{fp88},"

    if out!="":
        out = out[:len(out) - 1]
        code.append(out)

    return "\n".join(code)


# Routine name
prefix = "MixPluginLevels"
routine = f"{prefix}_internal\\1"
label = f"{prefix}_pitch_table\\1"

# Pitch range to use
min_pitch = 0.1
max_pitch = 1.00
num_steps = 64

# Generate and display result
output = generate_jump_table(routine, num_steps)
print(output)
output = generate_all_routines(min_pitch, max_pitch, num_steps)
print(output)

print("\n\n; Pitch ratios in fp8.8 format")
output = generate_fp88_pitch_ratios(label, min_pitch, max_pitch, num_steps)
print(output)


#test_pitch = 0.5
#output = generate_pitch_routine_68020(test_pitch, 0)
#print(output)
#output = generate_pitch_routine_68000(test_pitch, 0)
#print(output)