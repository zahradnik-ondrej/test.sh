<div align="center">

# 🧪🛠 test.sh

### An overengineered testing script for C/C++ programs.

*(The instructions below have been made to work on **Linux** operating systems, specifically on **Ubuntu** (20.04 and 22.04))*

</div>

***

### Instalation:

`chmod +x ./test.sh`

### Usage:

`./test.sh <program_path/code_path> <additional_compile_arguments>`

***

### Features:

- **Automatic compilation of code**
  - You do not need to compile your code before running the tests. If you specifify the name of the file which contains your code *(e.g. `code.c` or `code.cpp`)*, the testing script will automatically run the compilation for you before running the tests based on the `DEFAULT_COMPILE_ARGUMENTS` specified in the testing script + any additional compile arguments you pass into the testing script after the `<code_path>`.

<!--
- if you do **not** want to show the difference *(`diff`)* of the input & output files in the `./sample/CZE/` directory, you can set the variable `SHOW_DIFF` in the script to `0`
- if no output file is provided for the corresponding input file, the script will print out `Caution`, the sample input data and the received output data
- if provided with a `program_name` *(e.g. `./test.sh program`)*, it will run tests for the input & output files
- if provided with a `code_name` *(e.g. `./test.sh code.c`)*, it will compile the code with the `g++` compiler before running the tests - the default arguments foer the compiler are `-Wall -g -fsanitize=address`
- if provided with a `code_name`, you can specify **additional** argument(s) for the compiler after the `code_name` *(e.g. `./test.sh code.c -Werror` or `./test.sh code.c -Werror -O`)*
-->
