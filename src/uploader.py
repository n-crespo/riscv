import serial
import time
import os
import platform

# --- Configuration ---
# Set these based on your current OS
LINUX_PORT = "/dev/ttyUSB1"
WINDOWS_PORT = "COM6"  # check Device Manager to confirm your COM number
BAUD = 9600
FILE_PATH = "tb.hex"


def upload():
    # automatic port selection based on OS
    port = WINDOWS_PORT if platform.system() == "Windows" else LINUX_PORT

    if not os.path.exists(FILE_PATH):
        print(f"Error: {FILE_PATH} not found. Run 'make sim/fib.hex' first.")
        return

    try:
        serial_connection = serial.Serial(port, BAUD, timeout=1)
        print(f"Connected to {port} on {platform.system()} at {BAUD} baud.")

        with open(FILE_PATH, "r") as f:
            lines = f.readlines()

        print(f"Parsing {FILE_PATH}...")

        bytes_to_send = []
        for line in lines:
            line = line.strip()
            if line.startswith("@") or not line:
                continue

            instructions = line.split()
            for instr in instructions:
                # Little Endian conversion
                raw_val = int(instr, 16)
                bytes_to_send.append(raw_val & 0xFF)  # byte 0 (LSB)
                bytes_to_send.append((raw_val >> 8) & 0xFF)  # byte 1
                bytes_to_send.append((raw_val >> 16) & 0xFF)  # byte 2
                bytes_to_send.append((raw_val >> 24) & 0xFF)  # byte 3

        print(
            f"Sending {len(bytes_to_send)} bytes ({len(bytes_to_send)//4} instructions)..."
        )

        for i, b in enumerate(bytes_to_send):
            serial_connection.write(bytes([b]))
            # small delay for Basys3 buffer stability
            time.sleep(0.005)
            if (i + 1) % 4 == 0:
                print(f"Sent instruction {(i+1)//4}")

        print("\nUpload Successful! The CPU should now be ticking.")
        serial_connection.close()

    except Exception as e:
        print(f"Error: {e}")
        print(
            "\nTip: Make sure the FPGA is plugged in and no other program (like Vivado's Serial Console) is using the port."
        )


if __name__ == "__main__":
    upload()
