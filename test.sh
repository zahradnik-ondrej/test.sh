#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                        _            _         _                             #
#                       | |_ ___  ___| |_   ___| |__                          #
#                       | __/ _ \/ __| __| / __| '_ \                         #
#                       | ||  __/\__ \ |_ _\__ \ | | |                        #
#                        \__\___||___/\__(_)___/_| |_|                        #
#                                                                             #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#             An overengineered testing script for C/C++ programs.            #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

DEFAULT_COMPILE_ARGUMENTS="-Wall -pedantic -g" # -Werror -Wno-unused-variable -O
ADDRESS_SANITIZER=1

TIMEOUT=1

RUN_SAMPLE_TESTS=1
SHOW_DIFF=0
CONTINUE_AFTER_TESTS=1
SAMPLE_DIR_PATH="/sample/CZE/"

CONTINUE_AFTER_ASSERT_FAIL=1

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

reset="\e[0;0m"

green="\e[0;32m"
green_bold="\e[1;32m"
red="\e[0;35m"
red_bold="\e[1;35m"
blue="\e[0;34m"
dark_gray="\e[0;90m"
dark_gray_bold="\e[1;90m"
orange="\e[1;37m"
purple="\e[0;34m"
pink="\e[0;31m"
pink_bold="\e[1;31m"
yellow="\e[1;33m"

printc() {
  indentation="$1"
  width="$2"
  spacing="$3"

  shift 3

  columns=()
  column_num=0
  row_max=0
  for string in "$@"; do
    words=($string)

    column=""
    row_len=0
    row_num=1
    for word in "${words[@]}"; do
      if [ ${#column} -eq 0 ]; then
        spaces=""
        if [ $column_num -eq 0 ]; then
          spaces=$(printf '%*s' "$indentation" "")
        fi
        column="$spaces$word"
        row_len=${#column}
      elif [ $((row_len + ${#word} + 1)) -le "$width" ]; then
        column="$column $word"
        row_len=$((row_len + ${#word} + 1))
      else
        spaces=""
        if [ $column_num -eq 0 ]; then
          spaces=$(printf '%*s' "$indentation" "")
        fi
        column="$column\n$spaces$word"
        ((row_num += 1))
        if [ "$row_num" -gt "$row_max" ]; then
          row_max="$row_num"
        fi
        row_len=${#word}
      fi
    done

    column="$column\n"
    columns+=("$column")
    ((column_num += 1))
  done

  for ((row = 0; row <= row_max; row++)); do
    prev_row_text=""
    row_text=""
    for ((column = 1; column <= "${#columns[@]}"; column++)); do
      position=$((indentation + (width + spacing) * (column - 1)))
      offset=$(( position - ${#prev_row_text} ))
      row_text=$(echo -e "${columns[$((column - 1))]}" | sed -n "$((row + 1))p")
      spaces=""
      if [ "$column" -ne 1 ]; then
        spaces=$(printf '%*s' "$offset" "")
      fi
      row_text="$spaces$row_text"
      printf "$row_text"
      prev_row_text=$(echo -n "$prev_row_text$row_text" | sed 's/\x1b\[[0-9;]*m//g')
    done
    echo
  done
}

show_help() {
  printf "${pink_bold}"
  printf "                        _            _         _      \n"
  printf "                       | |_ ___  ___| |_   ___| |__   \n"
  printf "                       | __/ _ \/ __| __| / __| '_ \  \n"
  printf "                       | ||  __/\__ \ |_ _\__ \ | | | \n"
  printf "                        \__\___||___/\__(_)___/_| |_| \n"
  printf "${reset}"
  echo
  printf "${pink}"
  printc 1 100 0 "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  printc 14 100 0 "An overengineered testing script for C/C++ programs."
  printf "${reset}"
  echo
  printc 0 100 0 "${green_bold}Usage: ${yellow} ${0} [options] <program_path/code_path> <additional_compile_arguments>"
  echo
  printc 0 50 0 "${green_bold}Options:${reset}"
  printc 2 50 0 "${purple}-h, --help${reset}" "Show this help message and exit."
  echo
  printc 0 50 0 "${green_bold}Arguments:${reset}"
  printc 2 50 0 "${purple}<program_path/code_path>${reset}" "The path to the C/C++ program or the source code file."
  echo
  printc 2 50 0 "${purple}<additional_compile_arguments>${reset}" "Additional arguments to pass to the compiler."
  printc 52 100 0 "${dark_gray}(only works when the source code is provided instead of an already compiled program)${reset}"
  echo
  printc 0 50 0 "${green_bold}Variables:${reset}"
  printc 2 50 0 "${purple}DEFAULT_COMPILE_ARGUMENTS${reset}" "The default arguments passed to the compiler."
  printc 52 100 0 "${dark_gray}(only works when the source code is provided instead of an already compiled program)${reset}"
  echo
  printc 2 50 0 "${purple}SHOW_DIFF${reset}" "Show the difference between the sample output files and the program's actual output."
  echo
  printc 2 50 0 "${purple}CONTINUE_AFTER_TESTS${reset}" "Continue to run the program indefinitely on repeat after the sample tests to allow for manual testing of user inputs."
  echo
  printc 2 50 0 "${purple}CONTINUE_AFTER_ASSERT_FAIL${reset}" "Force the assert macro NOT to terminate the program after an assertion failure to see all ${green}passed${reset}/${red}failed${reset} assertions."
  printc 52 100 0 "${dark_gray}(only works when the source code is provided instead of an already compiled program)${reset}"
  echo
  printc 2 50 0 "${purple}SAMPLE_DIR_PATH${reset}"
  #echo
  #printf "${green_bold}Examples:${reset}\n"
  #echo
}

# if no command line arguments have been passed
if [ "$#" -eq 0 ]; then
  show_help
  exit 1
fi

# if the argument `-h` or `--help` have been passed into the script
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
  exit 0
fi

relative_path=$(dirname "$1")
file_path="$1"
program_name="$(basename "${file_path%.*}")"
program_path="${relative_path}/${program_name}"
sample_dir_path="${relative_path}/${SAMPLE_DIR_PATH}"

source_code=0
# if the source code of the program is passed as the testing target
if [[ "$file_path" == *.c || "$file_path" == *.cpp ]]; then
  source_code=1
fi

# if the source code of the program is passed as the testing target
if [ $source_code -eq 1 ]; then
  shift

  if [ "$ADDRESS_SANITIZER" -eq 1 ]; then
      DEFAULT_COMPILE_ARGUMENTS+=" -fsanitize=address"
  fi

  compile_output=$(g++ -fdiagnostics-color=always $DEFAULT_COMPILE_ARGUMENTS -o "${relative_path}/${program_name}" "$file_path" "$@" 2>&1)

  exit_code=$?
  # if the compiler exited with an error code
  if [ $exit_code -ne 0 ]; then
    echo "$compile_output"
    exit 1
  fi
fi

if [[ $TIMEOUT == *[0-9] ]]; then
  TIMEOUT=${TIMEOUT}s
fi

if [ "$RUN_SAMPLE_TESTS" -eq 1 ]; then

  input_files=( "${sample_dir_path}"*_in.txt )
  # if at least one sample input file has been provided
  if [ -e "${input_files[0]}" ]; then
    input_files=1
  else
    input_files=0
  fi

  output_files=( "${sample_dir_path}"*_out.txt )
  # if at least one sample output file has been provided
  if [ -e "${output_files[0]}" ]; then
    output_files=1
  else
    output_files=0
  fi

  if [ $input_files -eq 1 ]; then
    # for every sample input file
    for in_sample_file in "${sample_dir_path}"*_in.txt; do
      out_sample_file=$(echo -n "$in_sample_file" | sed -e "s/_in\(.*\)$/_out\1/")

      timeout $TIMEOUT $program_path < "$in_sample_file" > my_out.txt

      exit_code=$?
      if [ $exit_code -eq 124 ]; then
        printf "${red_bold}\U25BC Fail: %s: The program was terminated due to ${TIMEOUT} timeout. \U25BC \n${reset}" "$in_sample_file"
        printf "${blue}=== Sample Input Data ===\n${reset}"
        cat "$in_sample_file"
        echo

        continue
      fi

      if [ ! -s my_out.txt ]; then
          output=0
      else
          output=1
      fi

      diff "$out_sample_file" my_out.txt > out_data_diff.txt 2>/dev/null
      diff_exit_status=$?

      # if the diff command returned NO difference in the compared files
      if [ $diff_exit_status -eq 0 ]; then
        printf "${green_bold}\U2714 OK:${reset} %s${dark_gray}\n" "$in_sample_file"
        cat "$in_sample_file"

        echo
      # if the diff command returned SOME difference in the compared files
      elif [ $diff_exit_status -eq 1 ]; then

        if [ $output -eq 1 ]; then
            printf "${red_bold}\U25BC Fail: %s \U25BC \n${reset}" "$in_sample_file"
        else
            printf "${red_bold}\U25BC Fail: %s: The program did not produce any output data. \U25BC \n${reset}" "$in_sample_file"
        fi

        printf "${blue}=== Sample Input Data ===\n${reset}"
        cat "$in_sample_file"

        printf "${blue}=== Expected Sample Output Data ===\n${reset}"
        cat "$out_sample_file"

        if [ $output -eq 1 ]; then
          printf "${blue}=== Received Output Data ===\n${reset}"
          cat my_out.txt

          if [ "$SHOW_DIFF" -eq 1 ]; then
            printf "${blue}=== Output Data Difference ===\n${reset}"

            cat out_data_diff.txt

            # tail -n +2 out_data_diff.txt

            # awk '
            # /^</ { print "\033[32m" $0 "\033[0m" }
            # /^>/ { print "\033[31m" $0 "\033[0m" }
            # /^---/ { print $0 }
            # ' out_data_diff.txt

          fi
        fi

        echo
      # if the diff command exited with an error code
      # (i.e. no sample output file has been provided)
      else
        if [ $output -eq 1 ]; then
            printf "${orange}\U25BC Caution: %s \U25BC \n${reset}" "$in_sample_file"
        else
            printf "${orange}\U25BC Caution: %s: The program did not produce any output data. \U25BC \n${reset}" "$in_sample_file"
        fi

        printf "${blue}=== Sample Input Data ===\n${reset}"
        cat "$in_sample_file"

        if [ $output -eq 1 ]; then
          printf "${blue}=== Received Output Data ===\n${reset}"
          cat my_out.txt
        fi

        echo
      fi

      rm -f my_out.txt out_data_diff.txt
    done
  fi
fi

user_input=0
# if the source code of the program is passed as the testing target
if [ $source_code -eq 1 ]; then
  c_input_functions='scanf|fscanf|sscanf|vscanf|vfscanf|vsscanf|getchar|fgets|fgetc|getc|gets|read'
  cpp_input_functions='std::cin|std::getline|std::istream::get|std::istream::getline|std::istream::read|std::istream::readsome'
  # if the source code includes any of the functions which wait for user input
  # (could produce false positives when the function name is commented out for example)
  if grep -q -E "$cpp_input_functions|$c_input_functions" "$file_path"; then
      user_input=1
  fi
else
  output=$(timeout --preserve-status 1s "$program_path" 2>/dev/null)
  exit_code=$?
  # if the program has timed out after 1 seconds
  # (i.e. the program IS waiting for user input)
  # (could produce false positives when the program takes longer than 1 second to finish executing)
  if [ $exit_code -eq 143 ]; then
    user_input=1
  fi
fi

# if the program includes any function which wait for user input
# (i.e. the testing is done using user input as opposed to testing the program with assertions)
if [ $user_input -eq 1 ]; then
  output=$(timeout --preserve-status 1s "$program_path" 2>/dev/null)
  exit_code=$?
  # if the program has finished executing in less than 1 second
  # (i.e. the program IS NOT waiting for user input)
  # (could produce false negatives when the program takes longer than 1 second to get to the user input function)
  if [ ! $exit_code -eq 143 ]; then
    exit 0
  fi

  if [[ "$RUN_SAMPLE_TESTS" == 1 && $input_files == 0 ]]; then
    printf "${red_bold}\U26A0 Warning:${reset} No sample input data found in %s\n\n" "${sample_dir_path}"
  fi
  if [ $CONTINUE_AFTER_TESTS -eq 1 ]; then
    printf "${dark_gray_bold}\U25BC Manual input: \U25BC \n${reset}"
    # run the program indefinitely on repeat
    # (to allow for manually testing user inputs)
    while [ $CONTINUE_AFTER_TESTS -eq 1 ]; do
        $program_path
        printf "${dark_gray}======\n${reset}"
    done
  fi
else
  if [ $output_files -eq 1 ]; then
    out_sample_file=$(ls ${sample_dir_path}*_out.txt 2> /dev/null | head -n 1)

    timeout $TIMEOUT $program_path > my_out.txt

    exit_code=$?
    if [ $exit_code -eq 124 ]; then
      printf "${red_bold}\U26A0 The program was terminated due to a ${TIMEOUT} timeout.\n${reset}"
    else
      diff "$out_sample_file" my_out.txt > out_data_diff.txt 2>/dev/null
      diff_exit_status=$?

      # if the diff command returned NO difference in the compared files
      if [ $diff_exit_status -eq 0 ]; then
        printf "${green_bold}\U2714 OK:${reset} %s${dark_gray}\n" "$out_sample_file"
        cat "$out_sample_file"
      # if the diff command returned SOME difference in the compared files
      elif [ $diff_exit_status -eq 1 ]; then
        printf "${red_bold}\U25BC Fail: \U25BC \n${reset}"

        printf "${blue}=== Expected Sample Output Data ===\n${reset}"
        cat "$out_sample_file"

        printf "${blue}=== Received Output Data ===\n${reset}"
        cat my_out.txt

        if [ "$SHOW_DIFF" -eq 1 ]; then
          printf "${blue}=== Output Data Difference ===\n${reset}"

          cat out_data_diff.txt

          # tail -n +2 out_data_diff.txt

          # awk '
          # /^</ { print "\033[32m" $0 "\033[0m" }
          # /^>/ { print "\033[31m" $0 "\033[0m" }
          # /^---/ { print $0 }
          # ' out_data_diff.txt

        fi
      fi
    fi

    rm -f my_out.txt out_data_diff.txt
  else
    # if the source code of the program is passed as the testing target
    if [[ "$source_code" == 1 && "$CONTINUE_AFTER_ASSERT_FAIL" == 1 ]]; then
      assert_replacement_code='#include <stdio.h>\n#define __RED "\\033[1;35m"\n#define __GREEN "\\033[1;32m"\n#define __GRAY "\\033[0;90m"\n#define __NONE "\\033[0m"\n#undef assert\nvoid custom_assert_fail(const char* assertion, const char* file, unsigned int line, const char* function) {\n    fprintf(stderr, __RED "\\u25bc Assertion failed: \\u25bc\\n" __NONE "%s\\n\\n", assertion);\n}\nvoid custom_assert_pass(const char* assertion, const char* file, unsigned int line, const char* function) {\n    fprintf(stderr, __GREEN "\\u2714 OK: " __GRAY "%s\\n\\n" __NONE, assertion);\n}\n#define assert(expr) \\\n    ((expr) \\\n     ? custom_assert_pass(#expr, __FILE__, __LINE__, __ASSERT_FUNCTION) \\\n     : custom_assert_fail(#expr, __FILE__, __LINE__, __ASSERT_FUNCTION))'

      new_file_path="${relative_path}/${program_name}_custom_assert.c"
      cp "$file_path" "$new_file_path"

      awk -v code="$assert_replacement_code" '/^int main/ {print code "\n" $0; next} {print}' "${new_file_path}" > tmp_file && mv tmp_file "${new_file_path}"

      compile_output=$(g++ -fdiagnostics-color=always $DEFAULT_COMPILE_ARGUMENTS -o "${relative_path}/${program_name}_custom_assert" "$new_file_path" "$@" 2>&1)

      new_program_path="${relative_path}/${program_name}_custom_assert"

      timeout $TIMEOUT "$new_program_path"
    else
      timeout $TIMEOUT "$program_path" 2>/dev/null

      output=$($program_path 2>&1)
      assertion_error=$(echo "$output" | awk -F'`' '/Assertion/ {split($2,a,"'"'"'"); print a[1]}')
      # if the program terminated due to an assertion error
      if [[ -n "$assertion_error" ]]; then
        printf "${red_bold}\U25BC Failed assertion: \U25BC \n${reset}"
        echo "$assertion_error"
      else
        printf "${green_bold}\U2714 OK${reset}\n"
      fi
    fi
  fi
fi

# if the source code of the program is passed as the testing target
if [ $source_code -eq 1 ]; then
  rm -f "$program_path" "$new_file_path" "$new_program_path"
fi

# if there has been any output from the compiler
# (i.e. warnings)
if [[ -n "$compile_output" ]]; then
  printf "\n${compile_output}\n"
fi

