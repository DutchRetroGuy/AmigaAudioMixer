# $VER: GeneratePitchRoutines 1.0 (05.02.25)
#
# GeneratePitchRoutines.py
# This file contains the Python 3 script to generate the pitch routines used by the pitch plugin in MXPLG_PITCH_LEVELS
# for the audio mixer. Normally it is not needed to run this, but the code is provided to show how the routines were
# generated.
#
# Author: Jeroen Knoester
# Version: 1.0
# Revision: 20250211

# Imports
import math
from fractions import Fraction
from math import floor
from dataclasses import dataclass


# Type definitions
@dataclass
class PitchParams:
    loop_label: str
    level_num: int
    input_bytes: int
    output_bytes: int
    pitch_factor: float
    reverse: bool


# Functions
def find_best_rational(num, max_denominator=64):
    # Find the best rational approximation with denominator <= max_denominator
    return Fraction(num).limit_denominator(max_denominator)


def generate_pitch_loop(params: PitchParams):
    output_code = [f".{params.loop_label}_{params.level_num}"]

    # Calculate exact positions for the bytes based on the ratio
    positions = []
    for i in range(params.output_bytes):
        input_pos = math.floor(i * params.pitch_factor)
        positions.append(input_pos)

    instructions = []

    # Generate move.b instructions using these exact positions
    for input_pos in positions:
        if input_pos == 0 and not params.reverse:
            instructions.append("\t\tmove.b\t(a2),(a0)+")
        else:
            instructions.append(f"\t\tmove.b\t{input_pos}(a2),(a0)+")

    # Reverse instruction order if needed
    if params.reverse:
        instructions.reverse()
        output_code.append("\t\ttst.w\td6")
        output_code.append(f"\t\tbeq\t\t.lp_done_{params.level_num}")
        output_code.append("")
        output_code.append("\t\tmove.w\t#128,d7")
        output_code.append("\t\tsub.w\td6,d7")
        output_code.append("\t\tlsr.w\t#2,d6")
        output_code.append(f"\t\tjmp\t\t.jt_table_{params.level_num}(pc,d7.w)")
        output_code.append("")
        output_code.append(f".jt_table_{params.level_num}")

    # Add instructions to output code
    output_code.extend(instructions)

    # Calculate exact input bytes needed for this pattern
    max_pos = max(positions) + 1

    # Add the pointer increment
    if params.reverse:
        output_code.append("\t\tadd.w\td6,a2")
        output_code.append("\t\tadd.l\td6,d1")
    else:
        if max_pos > 0:
            if max_pos <= 8:
                output_code.append(f"\t\taddq.w\t#{max_pos},a2")
                output_code.append(f"\t\taddq.l\t#{max_pos},d1")
            else:
                output_code.append(f"\t\tadd.w\t#{max_pos},a2")
                output_code.append(f"\t\tadd.l\t#{max_pos},d1")

    output_code.append(f"\t\tdbra\td2,.{params.loop_label}_{params.level_num}")

    return output_code


def generate_pitch_routine_68000(pitch_factor, level_num):
    # Generate assembly code for a specific pitch factor.
    # pitch_factor: float representing the speed multiplier (e.g., 2.0 for double speed)
    # level_num: integer for the routine number

    # Find rational approximation
    rational = find_best_rational(pitch_factor)
    warning = ''

    if abs(float(rational) - pitch_factor) > 0.001:
        # warning = f"; Rounded {pitch_factor} to nearest rational of {rational.numerator}/{rational.denominator} "
        # warning = warning + f"({float(rational)})"
        pitch_factor = float(rational)

    # Note: maximum pattern length directly determines maximum number of pitch steps available
    #       length =  8 -> 8 steps
    #       length = 16 -> 16 steps
    # Extra steps over these numbers will cause steps that don't make any audible difference with the step immediately
    # preceding them to be created, even if the actual code looks slightly different.

    pattern_length = 32  # Static pattern length to keep pitch shift tonal quality consistent

    output_bytes = pattern_length
    input_bytes = math.floor(output_bytes * pitch_factor)
    shift_amount = int(math.log2(output_bytes))

    code = []
    if warning:
        code = [warning]

    code.append(f".pitch_level_{level_num}:")
    code.append("\t\tmove.w\td2,d6")
    code.append("\t\tand.w\t#$1f,d6")
    code.append("\t\tadd.w\td6,d6")
    code.append("\t\tadd.w\td6,d6")
    code.append(f"\t\tlsr.w\t#{shift_amount},d2")
    code.append(f"\t\tsubq.w\t#1,d2")
    code.append(f"\t\tbmi\t\t.remainder_{level_num}")
    code.append("")

    # Call generate_pitch_loop
    params = PitchParams(
        loop_label="lp",
        level_num=level_num,
        input_bytes=input_bytes,
        output_bytes=output_bytes,
        pitch_factor=pitch_factor,
        reverse=False
    )
    code.extend(generate_pitch_loop(params))

    # Continue here to reach 4 bytes-output offset
    #if output_bytes > 4:
    #    bytes_remaining = output_bytes-4
    #    bytes_input = math.floor(bytes_remaining * pitch_factor)

    # Add empty line between loop and remainder
    code.append("")

    # Call generate_pitch_loop
    params = PitchParams(
        loop_label="remainder",
        level_num=level_num,
        input_bytes=input_bytes,
        output_bytes=output_bytes,
        pitch_factor=pitch_factor,
        reverse=True
    )
    code.extend(generate_pitch_loop(params))
    code.pop()

    code.append("")
    code.append(f".lp_done_{level_num}")
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
        all_code.append(generate_pitch_routine_68000(pitch, i))

    all_code.append("\t\tENDIF")

    return "\n".join(all_code)


def generate_jump_table(routine_name, num_steps):
    # Generates the jump table to be used by the pitch levels routine

    code = [
        "\t\t; Internal pitch shifting subroutines",
        "\t\t; Note: all pitch ratios are rounded to nearest rational",
        routine_name,
        "\tIF MXPLUGIN_PITCH=1",
        ".m68020_indicator\tSET MIXER_68020+MXPLUGIN_68020_ONLY",
        "\t\tmoveq\t#0,d6",
        "\t\tIF .m68020_indicator=2",
        "\t\t\tmc68020\n\t\t\tjmp .jt_table(pc,d4.w*4)\n\t\t\tmc68000",
        "\t\tELSE",
        "\t\t\tmove.w\td4,d7\n\t\t\tadd.w\td7,d7\n\t\t\tadd.w\td7,d7\n\t\t\tjmp .jt_table(pc,d7.w)",
        "\t\tENDIF\n\n.jt_table"
            ]

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
min_pitch = 1/32
max_pitch = 1.00
num_steps = 32

# Generate and display result
output = generate_jump_table(routine, num_steps)
print(output)
output = generate_all_routines(min_pitch, max_pitch, num_steps)
print(output)

print("\n\n; Pitch ratios in fp8.8 format")
output = generate_fp88_pitch_ratios(label, min_pitch, max_pitch, num_steps)
print(output)