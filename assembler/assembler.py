import sys


def decimal_to_binary(value, bits):
    """Converts an integer to a two's complement binary string of fixed length."""
    if value < 0:
        value = (1 << bits) + value
    return format(value, f"0{bits}b")


def parse_register(reg_string):
    """Strips the prefix and returns a 5-bit binary string."""
    # clean string and parse integer
    reg_num = int(reg_string.replace("x", ""))
    return decimal_to_binary(reg_num, 5)


def assemble_r_type(parts):
    """Assembles r-type instructions like add, sub, and, or."""
    opcode = "0110011"
    rd = parse_register(parts[1])
    rs1 = parse_register(parts[2])
    rs2 = parse_register(parts[3])

    # map funct3 and funct7
    if parts[0] == "ADD":
        funct3, funct7 = "000", "0000000"
    elif parts[0] == "SUB":
        funct3, funct7 = "000", "0100000"
    elif parts[0] == "AND":
        funct3, funct7 = "111", "0000000"
    elif parts[0] == "OR":
        funct3, funct7 = "110", "0000000"
    else:
        # raise an error if an invalid r-type instruction is passed
        raise ValueError(f"Unsupported R-Type instruction: {parts[0]}")

    # concatenate the 32-bit string
    return funct7 + rs2 + rs1 + funct3 + rd + opcode


def assemble_i_type(parts):
    """Assembles i-type instructions like addi."""
    opcode = "0010011"
    rd = parse_register(parts[1])
    rs1 = parse_register(parts[2])
    imm = decimal_to_binary(int(parts[3]), 12)
    funct3 = "000"

    # concatenate the 32-bit string
    return imm + rs1 + funct3 + rd + opcode


def assemble_instruction(line):
    """Routes an assembly line to the correct parser format."""
    # remove commas and split into array
    parts = line.replace(",", " ").split()
    instruction = parts[0].upper()

    if instruction in ["ADD", "SUB", "AND", "OR"]:
        return assemble_r_type(parts)
    elif instruction == "ADDI":
        return assemble_i_type(parts)
    elif instruction == "WAIT":
        return "00000000000000000000000001111111"
    elif instruction == "END":
        return "00000000000000000001000001111111"

    # fallback for unsupported instructions
    return "00000000000000000000000000000000"


def assemble_file(input_path, output_path):
    """Parses a RISC-V assembly file and generates a binary output file."""
    # open and read raw assembly text
    with open(input_path, "r") as infile:
        lines = infile.readlines()

    machine_code = []

    # loop through each instruction line
    for line in lines:
        # strip whitespace and comments
        clean_line = line.split("//")[0].strip()
        if not clean_line:
            continue

        binary_instruction = assemble_instruction(clean_line)
        machine_code.append(binary_instruction)

    print(machine_code)
    # write compiled binary to output file
    with open(output_path, "w") as outfile:
        for instruction in machine_code:
            outfile.write(instruction + "\n")


if __name__ == "__main__":
    assemble_file("program.s", "output.bin")
