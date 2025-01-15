.intel_syntax noprefix

.equ MAX_CONCURRENT_ROUTINES, 10      
.equ STACK_CAPACITY, 4096

.section .text

.global routine
.global routine_init
.global routine_await


routine:
    xor rbx, rbx                      # Clear rbx
    xor rcx, rcx                      # Clear rcx

    check_loop_go:
    mov al, [contexts_status + rcx]    # Load status of the context
    cmp al, 0                          # Compare status with 0 (not initialized)
    jne not_zero_go                    # If status is not 0, jump to not_zero_go

    mov rbx, rcx                       # Store the index in rbx

    jmp done_go                        # Jump to done_go

    not_zero_go:
    inc rcx                             # Increment rcx to check the next context

    cmp rcx, MAX_CONCURRENT_ROUTINES    # Check if we have exceeded max routines
    jge overflow_fail                   # If so, jump to overflow_fail
    jmp check_loop_go                   # Otherwise, continue checking

    done_go:

    mov BYTE PTR [contexts_status + rbx], 1   # Mark the context as in use

    mov rax, STACK_CAPACITY             # Load stack capacity
    mul rbx                             # Multiply by the index to get offset
    mov rcx, rax                        # Store the result in rcx
    mov rax, [stacks_end]               # Load the end of stacks pointer
    sub rax, rcx                        # Subtract offset from stack end

    sub rax, 8                          # Adjust for function return address size
    lea rcx, [routine_finish]           # Load address of routine_finish
    mov [rax], rcx                      # Set return address to routine_finish

    mov [contexts_rsp+rbx*8], rax       # Save the stack pointer for this context
    mov QWORD  PTR [contexts_rbp+rbx*8], 0  # Clear the base pointer
    mov [contexts_rip+rbx*8], rdi       # Set instruction pointer to the routine

    ret                                 # Return from routine

routine_init:
    xor rbx, rbx                      # Clear rbx
    xor rcx, rcx                      # Clear rcx

    check_loop_init:

    mov al, [contexts_status + rcx]    # Check status of context
    cmp al, 0                          # Compare with 0
    jne not_zero_init                  # If not 0, jump to not_zero_init

    mov rbx, rcx                       # Store the index in rbx

    jmp done_init                      # Jump to done_init

    not_zero_init:
    inc rcx                             # Increment to check the next context

    cmp rcx, MAX_CONCURRENT_ROUTINES    # Check if we exceeded max routines
    jge overflow_fail                   # Jump to overflow_fail if exceeded
    jmp check_loop_init                 # Otherwise, continue checking

    done_init:

    mov BYTE PTR [contexts_status + rbx], 2   # Mark context as initialized

    pop rax                            # Pop return address from stack
    mov [contexts_rsp+rbx*8], rsp      # Save stack pointer
    mov [contexts_rbp+rbx*8], rbp      # Save base pointer
    mov [contexts_rip+rbx*8], rax      # Set the instruction pointer to return address

    jmp rax                             # Jump to the address to start execution

# TODO: routine_await_init
routine_await:

    mov rbx, [contexts_current]         # Load current context index

    mov al, [contexts_status + rbx]    # Load status of the current context
    cmp al, 2                          # Compare with 2 (initialized)
    jne init_await                     # If not initialized, jump to init_await

    pop rax                            # Pop return address
    mov [contexts_rsp+rbx*8], rsp      # Save the current stack pointer
    mov [contexts_rbp+rbx*8], rbp      # Save the current base pointer
    mov [contexts_rip+rbx*8], rax      # Save return address
    mov [contexts_exit_addr], rax      # Store exit address
    mov BYTE PTR [contexts_status + rbx], 1   # Mark context as running
    jmp init_await_done                # Jump to done handling

    init_await:

    pop rax                            # Pop return address
    mov [contexts_rsp+rbx*8], rsp      # Save stack pointer
    mov [contexts_rbp+rbx*8], rbp      # Save base pointer
    mov [contexts_rip+rbx*8], rax      # Save instruction pointer

    init_await_done:
    inc rbx                            # Increment the context index

    xor rcx, rcx                       # Clear rcx
    check_loop_await:

    mov al, [contexts_status + rbx]    # Check the status of the next context
    cmp al, 1                          # Compare with 1 (running)
    jne not_one_await                  # If not running, jump to not_one_await

    jmp done_await                     # Jump to done_await if context is running

    not_one_await:

    inc rcx                             # Increment rcx
    inc rbx                             # Increment context index

    cmp rcx, MAX_CONCURRENT_ROUTINES - 1 # Check if all routines are checked
    jge routine_exit                   # If so, exit the loop

    cmp rbx, MAX_CONCURRENT_ROUTINES    # If index exceeded, reset
    jge reset_rbx                       # Reset rbx if exceeded

    jmp check_loop_await               # Continue checking

    reset_rbx:
    xor rbx, rbx                       # Reset rbx to 0
    jmp check_loop_await               # Continue checking the contexts

    done_await:

    mov [contexts_current], rbx        # Update current context

    mov rsp, [contexts_rsp+rbx*8]      # Restore stack pointer
    mov rbp, [contexts_rbp+rbx*8]      # Restore base pointer
    jmp QWORD PTR [contexts_rip+rbx*8] # Jump to the instruction pointer

routine_finish:

    mov rbx, [contexts_current]         # Load current context
    mov BYTE PTR [contexts_status + rbx], 0  # Mark the context as free

    jmp routine_await                  # Go back to routine_await

routine_exit:

    mov rax, 0                          # Exit status 0
    mov rbx, 0                          # Reset rbx

    mov rsp, [contexts_rsp+rbx*8]       # Restore stack pointer
    mov rbp, [contexts_rbp+rbx*8]       # Restore base pointer
    jmp QWORD PTR [contexts_rip+rbx*8]  # Jump to the instruction pointer

overflow_fail:
    mov rax, 1                          # Set exit code 1 for error
    mov rdi, 1                          # File descriptor for stderr
    lea rsi, [too_many_routines_msg]    # Load error message
    lea rdx, [too_many_routines_msg_len] # Load error message length
    syscall                             # Trigger syscall for writing error message

    mov rax, 60                         # Exit syscall number
    mov rdi, 1                          # Status code for failure
    syscall                             # Exit the program

.section .data
    
    stacks_end:        .quad stacks + MAX_CONCURRENT_ROUTINES * STACK_CAPACITY   # End of stack area

    too_many_routines_msg:               .asciz "ERROR: Too many routines\n"   # Error message
    too_many_routines_msg_len = $ - too_many_routines_msg   # Calculate length of the message

.section .bss
    contexts_current: .quad 0             # Current context index
    stacks:           .skip MAX_CONCURRENT_ROUTINES * STACK_CAPACITY  # Space for all stacks

# TODO: save more register

    contexts_rsp:     .skip MAX_CONCURRENT_ROUTINES * 8   # Space for saving stack pointers
    contexts_rbp:     .skip MAX_CONCURRENT_ROUTINES * 8   # Space for saving base pointers
    contexts_rip:     .skip MAX_CONCURRENT_ROUTINES * 8   # Space for saving instruction pointers

    contexts_status:  .skip MAX_CONCURRENT_ROUTINES      # Space for storing context status

    contexts_exit_addr:   .skip 8                      # Space for storing exit address
