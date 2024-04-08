import sys

def binary_to_strings(input_file, output_file):
    with open(input_file, 'rb') as f_in:
        with open(output_file, 'w') as f_out:
            byte = f_in.read(1)
            while byte:
                byte_str = format(ord(byte), '08b') + '\n'  # Convert byte to binary string
                f_out.write(byte_str)
                byte = f_in.read(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py input_file output_file")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]

    binary_to_strings(input_file, output_file)
    print("Bytes written to", output_file)
