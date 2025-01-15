# Routine Manager in Assembly

This project demonstrates the management of multiple routines (or "threads") using assembly and C. It simulates a simple cooperative multitasking system where routines can be created, awaited, and executed in "parallel" up to a defined limit. The routines are stored in a custom stack, and their status is managed in memory.

## Overview

The core of this project is a routine manager written in assembly. The assembly code handles the routine lifecycle (creation, execution, awaiting, finishing), while the C code manages the higher-level setup and coordination.

The manager works with a fixed number of concurrent routines (10 in this case) and uses a simple cooperative multitasking model. Each routine has its own stack, and the execution context (registers, stack pointer, base pointer, instruction pointer) is saved and restored during context switches.

## Features

- **Routine Creation**: Routines can be initialized and scheduled for execution.
- **Context Switching**: Supports saving and restoring execution contexts, enabling multitasking.
- **Routine Status Management**: Routines are marked with different statuses (initialized, running, free).
- **Stack Management**: Each routine has its own stack and is given a defined capacity (4096 bytes).
- **Error Handling**: If too many routines are created (beyond the maximum limit), an error message is printed.


This project was inspired by **Tsoding Daily**.

## Build and Compile

To build the project, use the provided Makefile. You need `gcc` and `as` (the GNU assembler) installed on your system.

### To build the project:

```bash
make
