import serial
import time

# configuration
PORT = "/dev/ttyUSB1"  # This replaces COM6
BAUD = 9600
FILE_PATH = "program.bin"


def upload():
    try:
        ser = serial.Serial(PORT, BAUD, timeout=1)
        print(f"Connected to {PORT}")

        with open(FILE_PATH, "rb") as f:
            program_data = f.read()

        print(f"Sending {len(program_data)} bytes...")

        for byte in program_data:
            # send one byte at a time
            ser.write(bytes([byte]))
            # small delay to let the FPGA's 9600 baud state machine keep up
            time.sleep(0.01)

        print("Upload complete!")
        ser.close()

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    upload()
