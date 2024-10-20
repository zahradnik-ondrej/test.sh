<div align="center">

# 🧪 test.sh

### An overengineered Bash script for the testing of C/C++ programs.

*(The instructions below have been made to work on **Linux** operating systems, specifically on **Ubuntu 22.04** along with the prerequisite of having **Git** installed on your system.)*

</div>

***

### Installation:

1. `git clone https://github.com/zahradnik-ondrej/test.sh.git`

2. `cd test.sh`

3. `chmod +x ./test.sh`

### Usage *(more examples [below](https://github.com/zahradnik-ondrej/test.sh?tab=readme-ov-file#examples))*:

`./test.sh <program/code path> <type of test> <other flags/options>`

***

### Features:

- **Automatic compilation of source code**
  - You do **not** need to compile the source code before running the testing script.
    If you provide the testing script with the name of a file which contains the source code of the program, the testing script will automatically compile the source code for you using the `g++` compiler before moving forward with the tests based on the `COMPILE_ARGUMENTS` variable specified in the testing script or via command line arguments by providing either the `--compile-args` or the `--add-args` option.

- **Manual testing after sample input tests**
  - You do **not** need to repeatedly run the program yourself in order to manually test other non-sample user inputs.
    The testing script will run your program after running the sample tests indefinitely on repeat allowing you to manually test other user inputs beyond the sample tests with ease.
    To exit the testing script after you're done testing other non-sample user inputs, simply press `Ctrl` + `C`.
    You can disable this functionality by setting the `MANUAL_TESTS` variable in the testing script to `0` instead of `1`.

- **Doesn't terminate the program on the first failing assertion** *(custom assertion macro)*
  - If you ever wanted to test all the assertions in your program to see which ones had **passed** / **failed** without the program terminating on the first failing assertion, provide the testing script with the name of a file which contains the source code of the program and the testing script will inject a custom assertion macro into a copy of the source code which causes the program to output the results of each and every assertion in your program allowing you to better understand what needs fixing.

- **Statistics**
  - The statistics table shown after testing the program with sample user inputs will provide a helpful and easy way to quickly check the success rate of the tests.
 
***

### Screenshots:

`> ./test.sh test1.c -i`

![](https://github.com/zahradnik-ondrej/test.sh/blob/main/screenshot_1.png?raw=true)

`> ./test.sh test2.c -a`

![](https://github.com/zahradnik-ondrej/test.sh/blob/main/screenshot_2.png?raw=true)

***

### Flags:

`-h`, `--help` - Show a help message and exit.

`-v`, `--version` - Show the current testing script's version number and exit.

`-i`, `--input` - Specify the type of test that should be performed upon the testing target as a **USER INPUT** based one.
*(Specifying a type of test is mandatory. The **assertion** type test is specified by the `-a` flag.)*

`-a`, `--assert` - Specify the type of test that should be performed upon the testing target as a **ASSERTION** based one.
*(Specifying a type of test is mandatory. The **user input** type test is specified by the `-i` flag.)*

`--sanitize` - Set the value of the **ADDRESS_SANITIZER** variable to **1**.
Override the default value.

`--diff` - Set the value of the **SHOW_DIFF** variable to **1**.
Override the default value.

`--debug` - Set the value of the **DEBUG** variable to **1**.
Override the default value.

`-m`, `--manual` - Set the value of the **MANUAL_TESTS** variable to **1**.
Override the default value.

`-c`, `--clear` - Set the value of the **CLEAR_HISTORY** variable to **1**.
Override the default value.

`--modify-assert` - Set the value of the **MODIFY_ASSERT** variable to **1**.
Override the default value.

`--dump` - Set the size of core files to be unlimited.
It is also advised to manually run the command `echo "./core" > /proc/sys/kernel/core_pattern` to set the core files to be created in the same directory as the tested program and to set a clear name for them.
*(This requires elevated privileges so you must run `sudo su` first, then the command and then exit with the `exit` command.)*

***

### Options:

`-t`, `--timeout` - Set the value of the **TIMEOUT** variable.
Override the default value.

`--sample` - Set the value of the **SAMPLE_DIR_PATH** variable.
Override the default value.

`--compile-args` - Set the value of the **COMPILE_ARGUMENTS** variable.
Override the default value.

`--add-args` - Set additional compile arguments to use with the compile arguments defined in the **COMPILE_ARGUMENTS** variable *(e.g. -Werror -Wno-unused-variable -O2)*.

***

### Variables:

`COMPILE_ARGUMENTS` - Default arguments passed to the compiler.
*(only works when the source code is provided instead of an already compiled program)*

`SAMPLE_DIR_PATH` - Path to a directory containing sample input and output files.

`ADDRESS_SANITIZER` - Add the `-fsanitize=address` and `-g` flags to the compilation arguments in order to take the full advantage of **ASan**.

`SHOW_DIFF` - Show the difference between the sample output files and the program's actual output using the `diff` command.

`DEBUG` - Run the program using `gdb` *(GNU Debugger)*.
If the source code has been provided instead of an already compiled program, also add the `-g` flag to the compilation arguments.
*(only works when either the source code is provided **or** the program has been compiled **with** the `-g` flag **and without** the `-s` flag)*

`MANUAL_TESTS` - Continue to run the program indefinitely on repeat after the sample tests to allow for manual testing of user inputs.

`CLEAR_TERMINAL` - Clear the terminal at the start of the testing process to make it more organized and readable.

`MODIFY_ASSERT` - Force the assert macro to **NOT** terminate the program after an assertion failure to see all **passed** / **failed** assertions.
*(only works when the source code is provided instead of an already compiled program)*

`TIMEOUT` - Length of the timeout being imposed on the tested program after which it will be forcefully terminated.

***

### Examples:

`./test.sh -h`

`./test.sh -v`

`./test.sh test1.c -i`

`./test.sh test1 -i`

`./test.sh test2.c -a`

`./test.sh test1.c -i --diff`

`./test.sh test1.c -i --debug`

`./test.sh test1.c -i -t 0`

`./test.sh test1.c -i -t 5`

`./test.sh test1.c -i --samples ./samples`

***

**Warning:** The names of the sample **input** and **output** files must be in a specific format for the testing script to be able to work with them.
The format of the sample **input** files is `*_in*` where in place of the asterisks can be anything but it must contain the string `_in` anywhere in the file's name.
The format of the sample **output** file is the same (`*_out*`) but any string(s) in place of the asterisks must be the same as the string(s) in place of the asterisks in the sample **input** file's name that correlates with it.
