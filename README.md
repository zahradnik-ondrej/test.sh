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
  - You do not need to compile your code before running the tests. If you specifify the name of the file which contains your code *(e.g. `code.c` or `code.cpp`)*, the testing script will automatically compile the code for you using the `g++` compiler before running the tests based on the `DEFAULT_COMPILE_ARGUMENTS` specified in the testing script *(`-Wall -pedantic -g -fsanitize=address`)* + any additional compile arguments you pass into the testing script after the `<code_path>` *(e.g. `-Werror` or `-O`)*.
- **Manual input after sample tests**
  - You do not need to repeatedly run the program yourself in order to manually test other non-sample inputs. The testing script will run your program after running the sample tests indefinitely on repeat allowing you to manually test other user inputs beyond the sample tests with ease. To exit the testing script, simply press `Ctrl` + `C`. You can disable this functionality by setting the variable `CONTINUE_AFTER_TESTS` in the testing script to `0` instead of `1`.

<!--
- if no output file is provided for the corresponding input file, the script will print out `Caution`, the sample input data and the received output data
- if provided with a `program_name` *(e.g. `./test.sh program`)*, it will run tests for the input & output files
-->
