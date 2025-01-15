# Variables
ASM = as                      # Assembler command
CC = gcc                      # C compiler command
CFLAGS = -c -g -fno-pie        # C compiler flags (compile only, debugging symbols, no position-independent code)
LDFLAGS = -no-pie -g           # Linker flags (no position-independent code, debugging symbols)

# Source files
ASM_SRC = routine.s          # Assembly source file
C_SRC = main.c                 # C source file

# Object files
ASM_OBJ = routine.o            # Assembly object file
C_OBJ = main.o                 # C object file

# Executable file
EXEC = routine.out             # Executable file name

# Default rule
all: $(EXEC)                   # The default target is to build the executable

# Rule for assembling the .asm file
$(ASM_OBJ): $(ASM_SRC)          # If the assembly source file changes
	$(ASM) -o $(ASM_OBJ) $(ASM_SRC) -g  # Assemble the .asm file into .o file with debugging symbols

# Rule for compiling the .c file
$(C_OBJ): $(C_SRC)              # If the C source file changes
	$(CC) $(CFLAGS) -o $(C_OBJ) $(C_SRC)  # Compile the .c file into .o file with the specified flags

# Rule for linking the object files to create the executable
$(EXEC): $(ASM_OBJ) $(C_OBJ)    # If any object file changes
	$(CC) -o $(EXEC) $(C_OBJ) $(ASM_OBJ) $(LDFLAGS)  # Link object files to produce the final executable

# Clean rule
clean:                          # The clean target is used to remove generated files
	rm -f $(ASM_OBJ) $(C_OBJ) $(EXEC)  # Remove the object files and executable
