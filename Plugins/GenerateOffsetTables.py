def generate_offset_table(pitch_ratio):
    offset_table = []
    current_offset = 0
    counter = 0

    while counter < 64:  # Adjust if larger tables are needed
        offset_table.append(int(current_offset/256))  # Store as word offset
        current_offset += int(pitch_ratio * 256)  # Scale for word offset
        counter=counter+1

    return offset_table

print("Offset table for 0.25x:")
output=generate_offset_table(0.25)
print(output)
print("Offset table for 0.33x:")
output=generate_offset_table(0.33333333)
print(output)
print("Offset table for 0.5x:")
output=generate_offset_table(0.5)
print(output)
print("Offset table for 0.75x:")
output=generate_offset_table(0.75)
print(output)
print("Offset table for 1.25x:")
output=generate_offset_table(1.25)
print(output)
print("Offset table for 1.33x:")
output=generate_offset_table(1.33333333)
print(output)
print("Offset table for 1.5x:")
output=generate_offset_table(1.5)
print(output)
print("Offset table for 1.75x:")
output=generate_offset_table(1.75)
print(output)