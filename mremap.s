.intel_syntax noprefix

.section .data

    msg1:               .ascii "Part 1 of the message, "   # Message
    msg1_len = $ - msg1   # Calculate length of the message

    msg2:               .asciz "Part 1 of the message."   # Message
    msg2_len = $ - msg2   # Calculate length of the message


.section .text
    .globl _start

_start:
    # Perform mmap syscall
    # rdi = 0 (NULL), requesting kernel to choose the address
    # rsi = 4096 (size of the memory to allocate)
    # rdx = 3 (PROT_READ | PROT_WRITE)
    # r10 = 34 (MAP_ANONYMOUS | MAP_PRIVATE)
    # r8 = -1 (file descriptor, -1 for anonymous)
    # r9 = 0 (offset, 0 for anonymous)
    
    mov rdi, 0            # Address (NULL)
    mov rsi, 4096         # Length (4 KB)
    mov rdx, 3            # Protection (PROT_READ | PROT_WRITE)
    mov r10, 34           # Flags (MAP_ANONYMOUS | MAP_PRIVATE)
    mov r8, -1            # File descriptor (-1 for anonymous)
    mov r9, 0             # Offset (0 for anonymous)

    # Perform the syscall: mmap
    mov rax, 9            # Syscall number for mmap
    syscall               # Invoke syscall

    #int3
    # Check if mmap succeeded (returns address in rax)
    test rax, rax
    js mmap_failed        # Jump to mmap_failed if rax is negative (error)

    # Write msg1 at the address returned by mmap
    lea rdi, [rax]        # Load allocated memory address into rdi
    lea rsi, [msg1]       # Load msg1 address into rsi
    mov rcx, msg1_len     # Move the length of msg1 into rcx
    rep movsb             # Copy msg1 to the allocated memory

    # mmap succeeded, rax contains the allocated memory address

    # Prepare the arguments for mremap syscall
    # rdi = old_address (rax), rsi = old_size (4096), rdx = new_size (8192)
    # r10 = flags (1), r8 = new_address (0)
    
    mov rdi, rax          # old_address in rdi (address returned by mmap)
    mov rsi, 4096         # old_size (4 KB)
    mov rdx, 8192         # new_size (8 KB)
    mov r10, 1            # flags (1 MREMAP_MAYMOVE)
    xor r8, r8            # new_address (0, let kernel decide)

    # Perform the syscall: mremap
    mov rax, 25           # Syscall number for mremap
    syscall               # Invoke syscall

    #int3s
    # Check if mremap succeeded
    test rax, rax
    js mmap_failed        # Jump to mmap_failed if rax is negative (error)


    # Write msg2 at the new address after mremap
    lea rdi, [rax + msg1_len]        # Load new memory address (after msg1) into rdi
    lea rsi, [msg2]       # Load msg2 address into rsi
    mov rcx, msg2_len     # Move the length of msg2 into rcx
    rep movsb             # Copy msg2 to the new memory address

    #int3

    mov rsi, rax    # Load message
    mov rax, 1      # SYS Write
    mov rdi, 1                          # File descriptor for stdout
    mov rcx, msg2_len
    mov rdx, msg1_len  # Load error message length
    add rdx, rcx                        # Set exit code 1 for error
    syscall                             # Trigger syscall for writing error message

    mov rax, 60                         # Exit syscall number
    mov rdi, 0                          # Status code for correct!
    syscall                             # Exit the program

    # If we reach here, mremap succeeded
    # Exit the program (exit code 0)
    mov rdi, 0            # Exit code 0
    mov rax, 60           # Syscall number for exit
    syscall               # Invoke exit syscall

mmap_failed:
    # If mmap or mremap failed, exit with error code 1
    mov rdi, 1            # Exit code 1 (error)
    mov rax, 60           # Syscall number for exit
    syscall               # Invoke exit syscall
