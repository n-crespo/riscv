// initialize registers with immediate values
ADDI x1, x0, 5
ADDI x2, x0, 10

// perform math operations
ADD x3, x1, x2
SUB x4, x2, x1

AND x5, x1, x2
OR x6, x1, x2

// x1 = 5
// x2 = 10
// x3 = x1 + x2 = 15
// x4 = x2 - x1 = 5
// x5 = x1 AND x2
// x6 = x1 OR X2

// system control
WAIT
END
