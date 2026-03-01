import unittest

from assembler import Assembler  # pyright: ignore[reportAttributeAccessIssue]


class TestAssembler(unittest.TestCase):
    """Unit tests for the complete RISC-V instruction set."""

    def setUp(self):
        """Initializes the assembler and mock labels before each test."""
        self.asm = Assembler()
        # inject mock labels to test jumps and branches without a full file pass
        self.asm.labels = {"START": 0, "LOOP": 12}

    def test_decimal_to_binary(self):
        """Tests two's complement binary conversion."""
        # test positive number
        self.assertEqual(self.asm.decimal_to_binary(5, 5), "00101")
        # test negative number
        self.assertEqual(self.asm.decimal_to_binary(-5, 5), "11011")

    def test_parse_memory_operand(self):
        """Tests the extraction of offset and base register from string."""
        offset, reg = self.asm.parse_memory_operand("-4(x2)")
        self.assertEqual(offset, -4)
        self.assertEqual(reg, "00010")

    def test_r_type_instructions(self):
        """Tests arithmetic and logical r-type formatting."""
        # add x3, x1, x2
        self.assertEqual(
            self.asm.translate_instruction("ADD x3, x1, x2", 0),
            "00000000001000001000000110110011",
        )
        # sub x4, x2, x1
        self.assertEqual(
            self.asm.translate_instruction("SUB x4, x2, x1", 0),
            "01000000000100010000001000110011",
        )
        # and x5, x1, x2
        self.assertEqual(
            self.asm.translate_instruction("AND x5, x1, x2", 0),
            "00000000001000001111001010110011",
        )

    def test_i_type_instructions(self):
        """Tests immediate and load i-type formatting."""
        # addi x2, x0, 10
        self.assertEqual(
            self.asm.translate_instruction("ADDI x2, x0, 10", 0),
            "00000000101000000000000100010011",
        )
        # lw x1, 4(x2)
        self.assertEqual(
            self.asm.translate_instruction("LW x1, 4(x2)", 0),
            "00000000010000010010000010000011",
        )

    def test_s_type_instructions(self):
        """Tests store formatting and immediate splitting."""
        # sw x1, 8(x2)
        self.assertEqual(
            self.asm.translate_instruction("SW x1, 8(x2)", 0),
            "00000000000100010010010000100011",
        )

    def test_b_type_instructions(self):
        """Tests branching offset calculations and formatting."""
        # beq x1, x3, LOOP (current address = 4, target = 12, offset = +8)
        self.assertEqual(
            self.asm.translate_instruction("BEQ x1, x3, LOOP", 4),
            "00000000001100001000010001100011",
        )
        # beq x1, x3, START (current address = 4, target = 0, offset = -4)
        self.assertEqual(
            self.asm.translate_instruction("BEQ x1, x3, START", 4),
            "11111110001100001000111011100011",
        )

    def test_j_type_instructions(self):
        """Tests jump offset calculations and formatting."""
        # jal x0, START (current address = 8, target = 0, offset = -8)
        self.assertEqual(
            self.asm.translate_instruction("JAL x0, START", 8),
            "11111111100111111111000001101111",
        )

    def test_custom_instructions(self):
        """Tests hardware-specific wait and end formatting."""
        # wait
        self.assertEqual(
            self.asm.translate_instruction("WAIT", 0),
            "00000000000000000000000001111111",
        )
        # end
        self.assertEqual(
            self.asm.translate_instruction("END", 0),
            "00000000000000000000100001111111",
        )


if __name__ == "__main__":
    unittest.main()
