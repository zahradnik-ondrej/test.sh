#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
                               VERSION="1.0.0"                                #
#                        _            _         _                             #
#                       | |_ ___  ___| |_   ___| |__                          #
#                       | __/ _ \/ __| __| / __| '_ \                         #
#                       | ||  __/\__ \ |_ _\__ \ | | |                        #
#                        \__\___||___/\__(_)___/_| |_|                        #
#                                                                             #
#                              Ondrej Zahradnik                               #
#                                ondraz@pm.me                                 #
#                 https://github.com/zahradnik-ondrej/test.sh                 #
#                                                                             #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#      An overengineered Bash script for the testing of C/C++ programs.       #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

COMPILE_ARGUMENTS="-std=c++20 -Wall -pedantic -Wno-long-long"
SAMPLE_DIR_PATH="./sample/CZE"

ADDRESS_SANITIZER=1
SHOW_DIFF=0
DEBUG=0
MANUAL_TESTS=1
CLEAR_TERMINAL=1
TIMEOUT=2
MODIFY_ASSERT=1

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

reset="\e[0;0m"

green="\e[0;32m"
green_bold="\e[1;32m"
red="\e[0;35m"
red_bold="\e[1;35m"
blue="\e[0;34m"
dark_gray="\e[0;90m"
dark_gray_bold="\e[1;90m"
orange="\e[0;37m"
orange_bold="\e[1;37m"
pink="\e[0;31m"
pink_bold="\e[1;31m"
yellow_bold="\e[1;33m"

upper_left_corner="\u2554"
upper_right_corner="\u2557"
lower_left_corner="\u255A"
lower_right_corner="\u255D"
horizontal_line="\u2550"
vertical_line="\u2551"

# TODO: add custom width and spacing for each column
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
  clear
  printf "${pink}"
  printc 31 100 0 "version: ${VERSION}"
  printf "${pink_bold}"
  printf "                        _            _         _      \n"
  printf "                       | |_ ___  ___| |_   ___| |__   \n"
  printf "                       | __/ _ \/ __| __| / __| '_ \  \n"
  printf "                       | ||  __/\__ \ |_ _\__ \ | | | \n"
  printf "                        \__\___||___/\__(_)___/_| |_| \n"
  printf "${reset}"
  echo
  printf "${pink}"
  printc 30 100 0 "Ondrej Zahradnik"
  printc 28 100 0 "ondraz@protonmail.com"
  printc 17 100 0 "https://github.com/zahradnik-ondrej/test.sh"
  echo
  printc 1 100 0 "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  printc 6 100 0 "An overengineered Bash script for the testing of C/C++ programs."
  printf "${reset}"
  echo
  printc 0 100 0 "${green_bold}Example usage: ${yellow_bold}${0} src/main.c -i ${dark_gray}(more examples below)${reset}"
  echo
  printc 0 50 0 "${green_bold}Flags:${reset}"
  printc 2 50 0 "${blue}-h, --help${reset}" "Show this help message and exit."
  echo
  printc 2 50 0 "${blue}-v, --version${reset}" "Show the current testing script's version number and exit."
  echo
  printc 2 50 0 "${blue}-i, --input${reset}" "Specify the type of test that should be performed upon the testing target as a ${pink}USER INPUT${reset} based one. ${dark_gray}(Specifying a type of test is mandatory. The ${dark_gray_bold}assertion${dark_gray} type test is specified by the \`${dark_gray_bold}-a${dark_gray}\` flag.)${reset}"
  echo
  printc 2 50 0 "${blue}-a, --assert${reset}" "Specify the type of test that should be performed upon the testing target as an ${pink}ASSERTION${reset} based one. ${dark_gray}(Specifying a type of test is mandatory. The ${dark_gray_bold}user input${dark_gray} type test is specified by the \`${dark_gray_bold}-i${dark_gray}\` flag.)${reset}"
  echo
  printc 2 50 0 "${blue}--sanitize${reset}" "Set the value of the ${blue}ADDRESS_SANITIZER${reset} variable to ${green}1${reset}.\nOverride the default value: ${dark_gray}${ADDRESS_SANITIZER}${reset}."
  echo
  printc 2 50 0 "${blue}--diff${reset}" "Set the value of the ${blue}SHOW_DIFF${reset} variable to ${green}1${reset}.\nOverride the default value: ${dark_gray}${SHOW_DIFF}${reset}."
  echo
  printc 2 50 0 "${blue}--debug${reset}" "Set the value of the ${blue}DEBUG${reset} variable to ${green}1${reset}.\nOverride the default value: ${dark_gray}${DEBUG}${reset}."
  echo
  printc 2 50 0 "${blue}-m, --manual${reset}" "Set the value of the ${blue}MANUAL_TESTS${reset} variable to ${green}1${reset}.\nOverride the default value: ${dark_gray}${MANUAL_TESTS}${reset}."
  echo
  printc 2 50 0 "${blue}-c, --clear${reset}" "Set the value of the ${blue}CLEAR_HISTORY${reset} variable to ${green}1${reset}.\nOverride the default value: ${dark_gray}${CLEAR_HISTORY}${reset}."
  echo
  printc 2 50 0 "${blue}--modify-assert${reset}" "Set the value of the ${blue}MODIFY_ASSERT${reset} variable to ${green}1${reset}.\nOverride the default value: ${dark_gray}${MODIFY_ASSERT}${reset}."
  echo
  printc 2 50 0 "${blue}--dump${reset}" "Set the size of core files to be unlimited."
  printc 52 100 0 "It is also advised to manually run the command \`${dark_gray}echo \"./core\" > /proc/sys/kernel/core_pattern${reset}\` to set the core files to be created in the same directory as the tested program and to set a clear name for them. ${dark_gray}(This requires elevated privileges so you must run \`${dark_gray_bold}sudo su${dark_gray}\` first, then the command and then exit with the \`${dark_gray_bold}exit${dark_gray}\` command.)${reset}"
  echo
  printc 0 50 0 "${green_bold}Options:${reset}"
  printc 2 50 0 "${blue}-t, --timeout${reset}" "Set the value of the ${blue}TIMEOUT${reset} variable.\nOverride the default value: ${dark_gray}${TIMEOUT}${reset}."
  echo
  printc 2 50 0 "${blue}--samples${reset}" "Set the value of the ${blue}SAMPLE_DIR_PATH${reset} variable.\nOverride the default value: ${dark_gray}${SAMPLE_DIR_PATH}${reset}."
  echo
  printc 2 50 0 "${blue}--compile-args${reset}" "Set the value of the ${blue}COMPILE_ARGUMENTS${reset} variable.\nOverride the default value: ${dark_gray}${COMPILE_ARGUMENTS}${reset}."
  echo
  printc 2 50 0 "${blue}--add-args${reset}" "Set additional compile arguments to use with the compile arguments defined in the ${blue}COMPILE_ARGUMENTS${reset} variable ${dark_gray}(e.x. \"-Werror -Wno-unused-variable -O2\")${reset}."
  echo
  printc 0 50 0 "${green_bold}Variables:${reset}"
  printc 2 50 0 "${blue}COMPILE_ARGUMENTS${reset}" "Default arguments passed to the compiler.\nDefault value: ${dark_gray}${COMPILE_ARGUMENTS}${reset}."
  printc 52 100 0 "${dark_gray}(only works when the source code is provided instead of an already compiled program)${reset}"
  echo
  printc 2 50 0 "${blue}SAMPLE_DIR_PATH${reset}" "Path to a directory containing sample input and output files.\nDefault value: ${dark_gray}${SAMPLE_DIR_PATH}${reset}."
  echo
  printc 2 50 0 "${blue}ADDRESS_SANITIZER${reset}" "Add the \`${dark_gray}-fsanitize=address${reset}\` and \`${dark_gray}-g${reset}\` flags to the compilation arguments in order to take the full advantage of ${dark_gray}ASan${reset}.\nDefault value: ${dark_gray}${ADDRESS_SANITIZER}${reset}."
  echo
  printc 2 50 0 "${blue}SHOW_DIFF${reset}" "Show the difference between the sample output files and the program's actual output using the \`${dark_gray}diff${reset}\` command.\nDefault value: ${dark_gray}${SHOW_DIFF}${reset}."
  echo
  printc 2 50 0 "${blue}DEBUG${reset}" "Run the program using \`${dark_gray}gdb${reset}\` ${dark_gray}(GNU Debugger)${reset}.\nIf the source code has been provided instead of an already compiled program, also add the \`${dark_gray}-g${reset}\` flag to the compilation arguments.\nDefault value: ${dark_gray}${DEBUG}${reset}.\nIf the value of the ${blue}DEBUG${reset} variable is ${green}1${reset}, the values of the ${blue}INPUT_TESTS${reset} and ${blue}MANUAL_TESTS${reset} variables are ignored. "
  printc 52 100 0 "${dark_gray}(only works when either the source code is provided ${dark_gray_bold}or${dark_gray} the program has been compiled ${dark_gray_bold}with${dark_gray} the \`${dark_gray_bold}-g${dark_gray}\` flag ${dark_gray_bold}and without${dark_gray} the \`${dark_gray_bold}-s${dark_gray}\` flag)${reset}"
  echo
  printc 2 50 0 "${blue}MANUAL_TESTS${reset}" "Continue to run the program indefinitely on repeat after the sample tests to allow for manual testing of user inputs.\nDefault value: ${dark_gray}${MANUAL_TESTS}${reset}.\nIf the value of the ${blue}DEBUG${reset} variable is ${green}1${reset}, the value of the ${blue}MANUAL_TESTS${reset} variable is ignored."
  echo
  printc 2 50 0 "${blue}CLEAR_TERMINAL${reset}" "Clear the terminal at the start of the testing process to make it more organized and readable.\nDefault value: ${dark_gray}${CLEAR_TERMINAL}${reset}."
  echo
  printc 2 50 0 "${blue}MODIFY_ASSERT${reset}" "Force the assert macro to ${red}NOT${reset} terminate the program after an assertion failure to see all ${green}passed${reset}/${red}failed${reset} assertions.\nDefault value: ${dark_gray}${MODIFY_ASSERT}${reset}."
  printc 52 100 0 "${dark_gray}(only works when the source code is provided instead of an already compiled program)${reset}"
  echo
  printc 2 50 0 "${blue}TIMEOUT${reset}" "Length of the timeout being imposed on the tested program after which it will be forcefully terminated.\nDefault value: ${dark_gray}${TIMEOUT}${reset}."
  echo
  printc 0 50 0 "${green_bold}Examples:${reset}"
  printf "${yellow_bold}"
  printc 2 100 0 "${0} -h"
  printc 2 100 0 "${0} -v"
  printc 2 100 0 "${0} test1.c -i"
  printc 2 100 0 "${0} test1 -i"
  printc 2 100 0 "${0} test2.c -a"
  printc 2 100 0 "${0} test1.c -i --diff"
  printc 2 100 0 "${0} test1.c -i --debug"
  printc 2 100 0 "${0} test1.c -i -t 0"
  printc 2 100 0 "${0} test1.c -i -t 5"
  printc 2 100 0 "${0} test1.c -i --samples ./samples"
  printf "${reset}"
  echo
  printf "${orange_bold}"
  printc 0 100 0 "${orange_bold}\U26A0 Warning: ${orange}The names of the sample ${orange_bold}input${orange} and ${orange_bold}output${orange} files must be in a specific format for the testing script to be able to work with them."
  printc 0 100 0 "The format of the sample ${orange_bold}input${orange} files is \`${orange_bold}*_in*${orange}\` where in place of the asterisks can be anything but it must contain the string \`${orange_bold}_in${orange}\` anywhere in the file's name."
  printc 0 100 0 "The format of the sample ${orange_bold}output${orange} file is the same (\`${orange_bold}*_out*${orange}\`) but any string(s) in place of the asterisks must be the same as the string(s) in place of the asterisks in the sample ${orange_bold}input${orange} file's name that correlates with it."
  printf "${reset}"
  echo
}

format_time() {
    local input_time=$1

    # if the input time is not in the correct format
    if ! [[ $input_time =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      echo "?"
      return
    fi

    # if the input time equals 0
    if (( $(echo "$input_time == 0" | bc -l) )); then
      echo "0ms"
      return
    fi

    local seconds_in_minute=60
    local minutes_in_hour=60
    local hours_in_day=24
    local days_in_week=7

    local seconds
    local milliseconds
    seconds=$(echo "$input_time" | cut -d. -f1)
    milliseconds=$(echo "$input_time" | cut -d. -f2)

    # if the number of characters after the decimal point equals 1
    if [ ${#milliseconds} -eq 1 ]; then
        milliseconds=$(( milliseconds * 100 ))
    # if the number of characters after the decimal point equals 2
    elif [ ${#milliseconds} -eq 2 ]; then
        milliseconds=$(( milliseconds * 10 ))
    fi

    local minutes=$(( seconds / seconds_in_minute ))
    seconds=$(( seconds % seconds_in_minute ))

    local hours=$(( minutes / minutes_in_hour ))
    minutes=$(( minutes % minutes_in_hour ))

    local days=$(( hours / hours_in_day ))
    hours=$(( hours % hours_in_day ))

    local weeks=$(( days / days_in_week ))
    days=$(( days % days_in_week ))

    local formatted_time=""
    [[ $weeks -gt 0 ]] && formatted_time="${formatted_time}${weeks}w "
    [[ $days -gt 0 ]] && formatted_time="${formatted_time}${days}d "
    [[ $hours -gt 0 ]] && formatted_time="${formatted_time}${hours}h "
    [[ $minutes -gt 0 ]] && formatted_time="${formatted_time}${minutes}m "
    [[ $seconds -gt 0 ]] && formatted_time="${formatted_time}${seconds}s "
    [[ $milliseconds -gt 0 ]] && formatted_time="${formatted_time}${milliseconds}ms"

    echo "$formatted_time"
}

print_stats() {
  stats_mock="     Stats: ${successful_tests}/${failed_tests}/${indeterminable_tests} "
  stats_len=${#stats_mock}

  printf "${dark_gray}${upper_left_corner}"
  # for each character of the stats
  for ((i = 1; i <= stats_len; i++)); do printf "${horizontal_line}"; done
  printf "${upper_right_corner}\n"

  printf "${vertical_line} ${dark_gray_bold}\U24D8  Stats: ${green_bold}${successful_tests}${dark_gray}/${red_bold}${failed_tests}${dark_gray}/${orange_bold}${indeterminable_tests}  ${dark_gray}${vertical_line}\n"

  printf "${lower_left_corner}"
  # for each character of the stats
  for ((i = 1; i <= stats_len; i++)); do printf "${horizontal_line}"; done
  printf "${lower_right_corner}${reset}\n\n"
}

# if no command line arguments have been passed
if [ "$#" -eq 0 ]; then
  show_help
  exit 0
fi

input=0
assert=0

# while there are still some unprocessed command line arguments left
while [[ $# -gt 0 ]]; do
  # check the first unprocessed command line argument
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--version)
      printf "version: ${VERSION}\n"
      exit 0
      ;;
    --compile-args)
      COMPILE_ARGUMENTS="$2"; shift; shift
      ;;
    --compile-args=*)
      COMPILE_ARGUMENTS="${1#*=}"; shift
      ;;
    --add-args)
      additional_compile_arguments="$2"; shift; shift
      ;;
    --add-args=*)
      additional_compile_arguments="${1#*=}"; shift
      ;;
    --samples)
      SAMPLE_DIR_PATH="$2"; shift; shift
      ;;
    --samples=*)
      SAMPLE_DIR_PATH="${1#*=}"; shift
      ;;
    -i|--input)
      # if the `assert` variable stayed its default value (0)
      # (i.e. # the type of test - ASSERTION, hasn't been chosen already)
      if [ "$assert" -eq 0 ]; then
        input=1; shift
      else
        printf "${red_bold}\U26A0 Program can't be tested for both user inputs AND assertions. Please remove either the \`-i\` or the \`-a\` flag from the arguments.${reset}\n"
        exit 1
      fi
      ;;
    -a|--assert)
      # if the `input` variable stayed its default value (0)
      # (i.e. # the type of test - USER INPUT, hasn't been chosen already)
      if [ "$input" -eq 0 ]; then
        assert=1; shift
      else
        printf "${red_bold}\U26A0 Program can't be tested for both user inputs AND assertions. Please remove either the \`-i\` or the \`-a\` flag from the arguments.${reset}\n"
        exit 1
      fi
      ;;
    --sanitize)
      ADDRESS_SANITIZER=1; shift
      ;;
    --diff)
      SHOW_DIFF=1; shift
      ;;
    --debug)
      DEBUG=1; shift
      ;;
    -m|--manual)
      MANUAL_TESTS=1; shift
      ;;
    -c|--clear)
      CLEAR_TERMINAL=1; shift
      ;;
    -t|--timeout)
      TIMEOUT="$2"; shift; shift
      ;;
    -t=*|--timeout=*)
      TIMEOUT="${1#*=}"; shift
      ;;
    --modify-assert)
      MODIFY_ASSERT=1; shift
      ;;
    --dump)
      ulimit -c unlimited
      printf "${orange_bold}\U26A0 The size of core files has been set to unlimited.${reset}\n"
      exit 0
      ;;
    *)
      # if the `file_path` variable hasn't been specified yet and
      # the current command line argument is an existent path to a file
      if [[ -z "$file_path" && -f "$1" ]]; then
        file_path="$1"; shift
      # if the current command line argument is NOT an existent path to a file
      elif [ ! -f "$1" ]; then
        printf "${red_bold}\U26A0 Cannot find file:${reset} $1\n"
        exit 1
      else
        printf "${red_bold}\U26A0 Unexpected argument:${reset} $1\n"
        exit 1
      fi
  esac
done

# if both the `input` and the `assert` variable stayed their default value (0)
# (i.e. no type of test has been specified)
if [[ "$input" -eq 0 && "$assert" -eq 0 ]]; then
  printf "${red_bold}\U26A0 No type of test has been specified. Please add either the \`-i\` or the \`-a\` flag to the arguments.${reset}\n"
  exit 1
fi

# if the `file_path` variable hasn't been specified
if [ -z "$file_path" ]; then
  printf "${red_bold}\U26A0 No testing target specified.${reset}\n"
  exit 1
fi

if [ "$CLEAR_TERMINAL" -eq 1 ]; then
  clear
fi

relative_path=$(dirname "$file_path")
program_name="$(basename "${file_path%.*}")"
program_path="${relative_path}/${program_name}"
sample_dir_path="${relative_path}/${SAMPLE_DIR_PATH}/"

source_code=0
# if the source code of the program is passed as the testing target
if [[ "$file_path" == *.c || "$file_path" == *.cpp ]]; then
  source_code=1
fi

# if the source code of the program is passed as the testing target
if [ $source_code -eq 1 ]; then
  if [ "$ADDRESS_SANITIZER" -eq 1 ]; then
        COMPILE_ARGUMENTS+=" -fsanitize=address -g"
  fi

  if [ "$DEBUG" -eq 1 ]; then
      COMPILE_ARGUMENTS+=" -g"
  fi

  compile_output=$(g++ -fdiagnostics-color=always $COMPILE_ARGUMENTS $additional_compile_arguments -o "${relative_path}/${program_name}" "$file_path" 2>&1)

  exit_code=$?
  # if the compiler exited with an error code
  if [ "$exit_code" -ne 0 ]; then
    echo "$compile_output"
    exit 1
  fi
fi

if [ "$DEBUG" -eq 1 ]; then
  gdb "$program_path"
  exit 0
fi

# if the TIMEOUT` variable only includes numbers
if [[ "$TIMEOUT" == *[0-9] ]]; then
  TIMEOUT="${TIMEOUT}s"
fi

# if there has been any output from the compiler
# (i.e. warnings)
if [[ -n "$compile_output" ]]; then
  printf "${orange_bold}\U25BC Compilation output: \U25BC \n${reset}${compile_output}\n\n"
fi

if [ -f /usr/bin/time ]; then
  USR_BIN_TIME=1
else
  USR_BIN_TIME=0
  printf "${orange_bold}\U26A0 /usr/bin/time not found. Execution time will not be available.\n\n"
fi

# if the program is supposed to be tested for different user inputs
# (i.e. as opposed to being tested for assertions)
if [ $input -eq 1 ]; then
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

  # if at least one sample input file has been provided
  if [ $input_files -eq 1 ]; then
    successful_tests=0
    failed_tests=0
    indeterminable_tests=0
    # for every sample input file
    for in_sample_file in "${sample_dir_path}"*_in.txt; do
      out_sample_file=$(echo -n "$in_sample_file" | sed -e "s/_in\(.*\)$/_out\1/")

      export ASAN_OPTIONS=color=always

      if [ $USR_BIN_TIME -eq 1 ]; then
        output=$( /usr/bin/time --quiet --format="%e" -o execution_time.txt timeout "$TIMEOUT" "$program_path" < "$in_sample_file" 2>&1 )
      else
        output=$( timeout "$TIMEOUT" "$program_path" < "$in_sample_file" 2>&1 )
      fi
      timeout_exit_code=$?
      if [ $USR_BIN_TIME -eq 1 ]; then
        execution_time=$( cat execution_time.txt )
        rm -f execution_time.txt
        execution_time=$(format_time "$execution_time")
      fi

      diff_output=$(diff "$out_sample_file" <(echo "$output") 2>/dev/null)
      diff_exit_status=$?

      # if the `timeout` command exited with the code 124
      # (i.e. the program has exceeded the specified timeout)
      if [ $timeout_exit_code -eq 124 ]; then
        printf "${red_bold}\U25BC Fail: %s: The program was terminated due to ${TIMEOUT} timeout. \U25BC \n${reset}" "$in_sample_file"
        printf "${blue}=== Sample Input Data ===\n${reset}"
        cat "$in_sample_file"
        echo
        # if the file specified in the `out_sample_file` variable exists
        if [ -s "$out_sample_file" ]; then
          printf "${blue}=== Expected Sample Output Data ===\n${reset}"
          cat "$out_sample_file"
          echo
        fi

        continue
      fi

      # if the diff command returned NO difference in the compared files
      if [ $diff_exit_status -eq 0 ]; then
        ((successful_tests++))
        if [ $USR_BIN_TIME -eq 1 ]; then
          printf "${green_bold}\U2714 OK:${reset} %s${dark_gray} (Execution time: ${execution_time})\n" "$in_sample_file"
        else
          printf "${green_bold}\U2714 OK:${reset} %s$\n" "$in_sample_file"
        fi
        cat "$in_sample_file"
        printf "${reset}\n"
      # if the diff command returned SOME difference in the compared files
      elif [ $diff_exit_status -eq 1 ]; then
        ((failed_tests++))

        # if the variable `output` contains any data (is NOT empty)
        # (i.e. the program has produced some output data)
        if [ -n "$output" ]; then
            printf "${red_bold}\U25BC Fail: %s \U25BC ${dark_gray}(Execution time: ${execution_time})\n${reset}" "$in_sample_file"
        else
            if [ $USR_BIN_TIME -eq 1 ]; then
              printf "${red_bold}\U25BC Fail: %s: The program did not produce any output data. \U25BC ${dark_gray}(Execution time: ${execution_time})\n${reset}" "$in_sample_file"
            else
              printf "${red_bold}\U25BC Fail: %s: The program did not produce any output data. \U25BC\n${reset}" "$in_sample_file"
            fi
        fi

        printf "${blue}=== Sample Input Data ===\n${reset}"
        cat "$in_sample_file"

        printf "${blue}=== Expected Sample Output Data ===\n${reset}"
        cat "$out_sample_file"

        # if the variable `output` contains any data (is NOT empty)
        # (i.e. the program has produced some output data)
        if [ -n "$output" ]; then
          printf "${blue}=== Received Output Data ===\n${reset}"
          echo "$output"

          if [ "$SHOW_DIFF" -eq 1 ]; then
            printf "${blue}=== Output Data Difference ===\n${reset}"

            echo "$diff_output" | awk '
                /^</ { print "\033[32m" $0 "\033[0m" }
                /^>/ { print "\033[31m" $0 "\033[0m" }
                /^---/ { print $0 }
            '
          fi
        fi

      echo

      # if the diff command exited with an error code
      # (i.e. no sample output file has been provided)
      else
        ((indeterminable_tests++))
        # if the variable `output` contains any data (is NOT empty)
        # (i.e. the program has produced some output data)
        if [ -n "$output" ]; then
            if [ $USR_BIN_TIME -eq 1 ]; then
              printf "${orange_bold}\U25BC Caution: %s \U25BC ${dark_gray}(Execution time: ${execution_time})\n${reset}" "$in_sample_file"
            else
              printf "${orange_bold}\U25BC Caution: %s \U25BC\n${reset}" "$in_sample_file"
            fi
        else
            if [ $USR_BIN_TIME -eq 1 ]; then
              printf "${orange_bold}\U25BC Caution: %s: The program did not produce any output data. \U25BC ${dark_gray}(Execution time: ${execution_time})\n${reset}" "$in_sample_file"
            else
              printf "${orange_bold}\U25BC Caution: %s: The program did not produce any output data. \U25BC\n${reset}" "$in_sample_file"
            fi
        fi

        printf "${blue}=== Sample Input Data ===\n${reset}"
        cat "$in_sample_file"

        # if the variable `output` contains any data (is NOT empty)
        # (i.e. the program has produced some output data)
        if [ -n "$output" ]; then
          printf "${blue}=== Received Output Data ===\n${reset}"
          echo "$output"
        fi

        echo
      fi
    done

    print_stats
  else
    printf "${red_bold}\U26A0 Warning:${reset} No sample input data found in %s\n\n" "${sample_dir_path}"
  fi

  # if no sample input files have been provided but at least one sample output file has
  if [[ "$input_files" -eq 0 && "$output_files" -eq 1 ]]; then
    out_sample_file=$(ls ${sample_dir_path}*_out.txt 2> /dev/null | head -n 1)

    if [ $USR_BIN_TIME -eq 1 ]; then
      output=$( /usr/bin/time --quiet --format="%e" -o execution_time.txt timeout "$TIMEOUT" "$program_path" 2>&1 )
    else
      output=$( timeout "$TIMEOUT" "$program_path" 2>&1 )
    fi
    timeout_exit_code=$?
    if [ $USR_BIN_TIME -eq 1 ]; then
      execution_time=$( cat execution_time.txt )
      rm -f execution_time.txt
      execution_time=$(format_time "$execution_time")
    fi

    # if the `timeout` command exited with the code 124
    # (i.e. the program has exceeded the specified timeout)
    if [ $timeout_exit_code -eq 124 ]; then
      printf "${red_bold}\U26A0 The program was terminated due to a ${TIMEOUT} timeout.\n${reset}"
    else
      diff_output=$(diff "$out_sample_file" <(echo "$output") 2>/dev/null)
      diff_exit_status=$?

      # if the diff command returned NO difference in the compared files
      if [ $diff_exit_status -eq 0 ]; then
        if [ $USR_BIN_TIME -eq 1 ]; then
          printf "${green_bold}\U2714 OK:${reset} %s${dark_gray} (Execution time: ${execution_time})\n" "$out_sample_file"
        else
          printf "${green_bold}\U2714 OK:${reset} %s\n" "$out_sample_file"
        fi
        cat "$out_sample_file"
      # if the diff command returned SOME difference in the compared files
      elif [ $diff_exit_status -eq 1 ]; then
        if [ $USR_BIN_TIME -eq 1 ]; then
          printf "${red_bold}\U25BC Fail: \U25BC ${dark_gray}(Execution time: ${execution_time})\n${reset}"
        else
          printf "${red_bold}\U25BC Fail: \U25BC\n${reset}"
        fi

        printf "${blue}=== Expected Sample Output Data ===\n${reset}"
        cat "$out_sample_file"

        printf "${blue}=== Received Output Data ===\n${reset}"
        echo "$output"

        if [ "$SHOW_DIFF" -eq 1 ]; then
          printf "${blue}=== Output Data Difference ===\n${reset}"
          echo "$diff_output" | awk '
              /^</ { print "\033[32m" $0 "\033[0m" }
              /^>/ { print "\033[31m" $0 "\033[0m" }
              /^---/ { print $0 }
          '
        fi
      fi
    fi
  fi

  if [ $MANUAL_TESTS -eq 1 ]; then
    printf "${dark_gray_bold}\U25BC Manual input: \U25BC \n${reset}"
    # run the program indefinitely on repeat
    # (to allow for manual testing of user inputs)
    while [ $MANUAL_TESTS -eq 1 ]; do
      $program_path
      printf "${dark_gray}======\n${reset}"
    done
  fi
elif [ "$assert" -eq 1 ]; then
  # if the source code of the program is passed as the testing target
  if [[ "$source_code" == 1 && "$MODIFY_ASSERT" == 1 ]]; then
    assert_replacement_code='#include <stdio.h>\n#define __RED "\\033[1;35m"\n#define __GREEN "\\033[1;32m"\n#define __GRAY "\\033[0;90m"\n#define __NONE "\\033[0m"\n#undef assert\nvoid custom_assert_fail(const char* assertion, const char* file, unsigned int line, const char* function) {\n    fprintf(stderr, __RED "\\u25bc Assertion failed: \\u25bc\\n" __NONE "%s\\n\\n", assertion);\n}\nvoid custom_assert_pass(const char* assertion, const char* file, unsigned int line, const char* function) {\n    fprintf(stderr, __GREEN "\\u2714 OK: " __GRAY "%s\\n\\n" __NONE, assertion);\n}\n#define assert(expr) \\\n    ((expr) \\\n     ? custom_assert_pass(#expr, __FILE__, __LINE__, __func__) \\\n     : custom_assert_fail(#expr, __FILE__, __LINE__, __func__))'

    new_file_path="${relative_path}/${program_name}_custom_assert."
    # if the file extension of the source code is ".c"
    if [[ "$file_path" == *.c ]]; then
      new_file_path+="c"
    # if the file extension of the source code is ".cpp"
    elif [[ "$file_path" == *.cpp ]]; then
      new_file_path+="cpp"
    fi
    cp "$file_path" "$new_file_path"

    sed -i '/#include <assert.h>/d' "$new_file_path"
    sed -i '/#include <cassert>/d' "$new_file_path"

    awk -v code="$assert_replacement_code" 'BEGIN {print code} {print}' "$new_file_path" > tmp_file && mv tmp_file "$new_file_path"

    new_program_path="${relative_path}/${program_name}_custom_assert"

    compile_output=$(g++ -fdiagnostics-color=always $COMPILE_ARGUMENTS $additional_compile_arguments -o "$new_program_path" "$new_file_path" "$@" 2>&1)

    if [ $USR_BIN_TIME -eq 1 ]; then
      output=$( /usr/bin/time --quiet --format="%e" -o execution_time.txt timeout "$TIMEOUT" "$new_program_path" 2>&1 )
    else
      output=$( timeout "$TIMEOUT" "$new_program_path" 2>&1 )
    fi
    timeout_exit_code=$?
    if [ $USR_BIN_TIME -eq 1 ]; then
      execution_time=$( cat execution_time.txt )
      rm -f execution_time.txt
      execution_time=$(format_time "$execution_time")
    fi

    printf "${output}\n\n"

    # if the `timeout` command exited with the code 124
    # (i.e. the program has exceeded the specified timeout)
    if [ $timeout_exit_code -eq 124 ]; then
      printf "${red_bold}\U26A0 Fail: The program was terminated due to ${TIMEOUT} timeout.\n${reset}"
    else
      printf "${dark_gray}(Execution time: ${execution_time})${reset}\n"
    fi
  else
    if [ $USR_BIN_TIME -eq 1 ]; then
      output=$( /usr/bin/time --quiet --format="%e" -o execution_time.txt timeout "$TIMEOUT" "$program_path" 2>&1 )
    else
      output=$( timeout "$TIMEOUT" "$program_path" 2>&1 )
    fi
    timeout_exit_code=$?
    if [ $USR_BIN_TIME -eq 1 ]; then
      execution_time=$( cat execution_time.txt )
      rm -f execution_time.txt
      execution_time=$(format_time "$execution_time")
    fi

    # if the `timeout` command exited with the code 124
    # (i.e. the program has exceeded the specified timeout)
    if [ $timeout_exit_code -eq 124 ]; then
      printf "${red_bold}\U26A0 Fail: The program was terminated due to ${TIMEOUT} timeout.\n${reset}"
      exit 1
    fi

    output=$($program_path 2>&1)
    assertion_error=$(echo "$output" | awk -F'`' '/Assertion/ {split($2,a,"'"'"'"); print a[1]}')
    # if the program terminated due to an assertion error
    if [[ -n "$assertion_error" ]]; then
      if [ $USR_BIN_TIME -eq 1 ]; then
        printf "${red_bold}\U25BC Failed assertion: \U25BC ${dark_gray}(Execution time: ${execution_time})\n${reset}"
      else
        printf "${red_bold}\U25BC Failed assertion: \U25BC\n${reset}"
      fi
      echo "$assertion_error"
    else
      if [ $USR_BIN_TIME -eq 1 ]; then
        printf "${green_bold}\U2714 OK ${dark_gray}(Execution time: ${execution_time})${reset}\n"
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

