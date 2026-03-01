class Assembler:
    """A two-pass RISC-V assembler for a custom 32-bit architecture."""

    OPCODES = {
        "R_TYPE": "0110011",
        "I_TYPE_ARITH": "0010011",
        "I_TYPE_LOAD": "0000011",
        "S_TYPE": "0100011",
        "B_TYPE": "1100011",
        "J_TYPE": "1101111",
        "WAIT": "1111111",
        "END": "1111111",
    }

    FUNCT3 = {
        "ADD": "000",
        "SUB": "000",
        "AND": "111",
        "OR": "110",
        "ADDI": "000",
        "LW": "010",
        "SW": "010",
        "BEQ": "000",
    }

    FUNCT7 = {"ADD": "0000000", "SUB": "0100000", "AND": "0000000", "OR": "0000000"}

    def __init__(self):
        # stores label names and their memory addresses
        self.labels = {}

    def decimal_to_binary(self, value, bits):
        """Converts an integer to a two's complement binary string of fixed length."""
        if value < 0:
            value = (1 << bits) + value
        return format(value, f"0{bits}b")

    def parse_register(self, reg_string):
        """Strips the prefix and returns a 5-bit binary string."""
        # clean string and parse integer
        reg_num = int(reg_string.replace("x", ""))
        return self.decimal_to_binary(reg_num, 5)

    def parse_memory_operand(self, operand):
        """Parses an operand like '4(x2)' into an immediate integer and a register."""
        # split offset and register
        imm_str, reg_str = operand.split("(")
        reg_str = reg_str.replace(")", "")
        return int(imm_str), self.parse_register(reg_str)

    def assemble_r_type(self, parts):
        """Assembles r-type instructions like add, sub, and, or."""
        # register to register operations
        opcode = self.OPCODES["R_TYPE"]  # the math category
        funct3 = self.FUNCT3[parts[0]]  # the specific math operation
        funct7 = self.FUNCT7[parts[0]]  # even more specific operation
        rd = self.parse_register(parts[1])  # destination
        rs1 = self.parse_register(parts[2])  # source 1
        rs2 = self.parse_register(parts[3])  # source 2

        # [specific function][source2][source1][general function][destination][instruction format]
        return funct7 + rs2 + rs1 + funct3 + rd + opcode

    def assemble_i_type(self, parts):
        """Assembles i-type instructions like addi and lw."""
        # operations that include an immediate constant or loading data
        if parts[0] == "LW":
            # ex. LW x1, 0(x2)
            opcode = self.OPCODES["I_TYPE_LOAD"]
            funct3 = self.FUNCT3[parts[0]]
            rd = self.parse_register(parts[1])
            # extract offset and base register
            imm_val, rs1 = self.parse_memory_operand(parts[2])
            imm = self.decimal_to_binary(imm_val, 12)
        else:
            # ex. ADDI x1, x1, 1,
            opcode = self.OPCODES["I_TYPE_ARITH"]
            funct3 = self.FUNCT3[parts[0]]
            rd = self.parse_register(parts[1])
            rs1 = self.parse_register(parts[2])
            imm = self.decimal_to_binary(int(parts[3]), 12)

        # [constant][source1][general function][instruction format]
        return imm + rs1 + funct3 + rd + opcode

    def assemble_s_type(self, parts):
        """Assembles s-type instructions like sw."""
        # SW x1, 0(x2)
        opcode = self.OPCODES["S_TYPE"]
        funct3 = self.FUNCT3[parts[0]]
        rs2 = self.parse_register(parts[1])
        # extract offset and base register
        imm_val, rs1 = self.parse_memory_operand(parts[2])
        imm = self.decimal_to_binary(imm_val, 12)

        # split immediate into upper 7 and lower 5 bits
        imm_upper = imm[0:7]
        imm_lower = imm[7:12]
        return imm_upper + rs2 + rs1 + funct3 + imm_lower + opcode

    def assemble_b_type(self, parts, current_address):
        """Assembles b-type instructions like beq."""
        # ex. BEQ x1, x3, END_LOOP
        opcode = self.OPCODES["B_TYPE"]
        funct3 = self.FUNCT3[parts[0]]
        rs1 = self.parse_register(parts[1])
        rs2 = self.parse_register(parts[2])

        # calculate relative offset from label
        target_address = self.labels[parts[3]]
        offset = target_address - current_address
        imm = self.decimal_to_binary(offset, 13)

        # construct immediate fields per risc-v spec
        imm_upper = imm[0] + imm[2:8]
        imm_lower = imm[8:12] + imm[1]
        return imm_upper + rs2 + rs1 + funct3 + imm_lower + opcode

    def assemble_j_type(self, parts, current_address):
        """Assembles j-type instructions like jal."""
        opcode = self.OPCODES["J_TYPE"]
        rd = self.parse_register(parts[1])

        # calculate relative offset from label
        target_address = self.labels[parts[2]]
        offset = target_address - current_address
        imm = self.decimal_to_binary(offset, 21)

        # construct immediate fields per risc-v spec
        imm_assembled = imm[0] + imm[10:20] + imm[9] + imm[1:9]
        return imm_assembled + rd + opcode

    def translate_instruction(self, line, current_address):
        """Routes a clean assembly line to the correct parser format."""
        # separate instruction args
        parts = line.replace(",", " ").split()
        inst = parts[0].upper()  # instruction is first on line

        # map instruction type to proper parser
        if inst in ["ADD", "SUB", "AND", "OR"]:
            return self.assemble_r_type(parts)
        elif inst in ["ADDI", "LW"]:
            return self.assemble_i_type(parts)
        elif inst in ["SW"]:
            return self.assemble_s_type(parts)
        elif inst in ["BEQ"]:
            return self.assemble_b_type(parts, current_address)
        elif inst in ["JAL"]:
            return self.assemble_j_type(parts, current_address)
        elif inst == "WAIT":
            return "0" * 25 + self.OPCODES["WAIT"]
        elif inst == "END":
            return "0" * 20 + "10000" + self.OPCODES["END"]

        raise ValueError(f"Unsupported instruction: {inst}")

    def assemble(self, input_path, output_path):
        """Executes the two-pass assembly process to resolve labels and compile."""
        with open(input_path, "r") as infile:
            lines = infile.readlines()

        clean_lines = []
        address = 0

        # pass 1: resolve labels and calculate addresses
        for line in lines:
            # detect if we are on a comment
            line = line.split("//")[0].strip()
            if not line:
                # ignore comments
                continue

            # check for labels like LOOP:
            if line.endswith(":"):
                label_name = line[:-1]
                # store label name/address in local dict
                # (address is running counter based on number of previous instructions)
                self.labels[label_name] = address
            else:
                # store all instructions in flat array
                clean_lines.append(line)
                address += 4  # all instructions are 4 bytes (32 bits)

        machine_code = []
        address = 0

        # pass 2: translate to machine code
        for line in clean_lines:
            binary_instruction = self.translate_instruction(line, address)
            machine_code.append(binary_instruction)
            address += 4

        # write compiled binary to output file
        with open(output_path, "w") as outfile:
            for instruction in machine_code:
                outfile.write(instruction + "\n")
            print(f"Successfully wrote compiled binary to: {output_path}")


if __name__ == "__main__":
    assembler = Assembler()
    assembler.assemble("examples/1_simple.s", "examples/1_simple.bin")
    assembler.assemble("examples/2_loop.s", "examples/2_loop.bin")
