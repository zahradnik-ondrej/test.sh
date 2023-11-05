#!/bin/bash

DEFAULT_COMPILE_ARGUMENTS="-Wall -pedantic -g -fsanitize=address" # -Werror -Wno-unused-variable
CONTINUE_AFTER_TESTS=1

#SHOW_DIFF=1

relative_path=$(dirname "$1")
file_path="$1"
program_name="$(basename "${file_path%.*}")"
program_path="${relative_path}/${program_name}"
sample_dir_path="${relative_path}/sample/CZE/"

if [[ "$file_path" == *.c || "$file_path" == *.cpp ]]; then
  shift

  compile_output=$(g++ -fdiagnostics-color=always $DEFAULT_COMPILE_ARGUMENTS -o "${relative_path}/${program_name}" "$file_path" "$@" 2>&1)

  return_code=$?
  if [ $return_code -ne 0 ]; then
    echo "$compile_output"
    exit 1
  fi
fi

no_color="\e[0;0m"

#green="\e[0;32m"
green_bold="\e[1;32m"
#red="\e[0;35m"
red_bold="\e[1;35m"
blue="\e[0;34m"
dark_gray="\e[0;90m"
dark_gray_bold="\e[1;90m"
orange="\e[1;37m"

input_files=( "${sample_dir_path}"*_in.txt )
if [ -e "${input_files[0]}" ]; then
  for in_sample_file in "${sample_dir_path}"*_in.txt; do
    out_sample_file=$(echo -n "$in_sample_file" | sed -e "s/_in\(.*\)$/_out\1/")

    $program_path < "$in_sample_file" > my_out.txt

    diff "$out_sample_file" my_out.txt > out_data_diff.txt 2>/dev/null
    diff_exit_status=$?

    if [ $diff_exit_status -eq 0 ]; then
      printf "${green_bold}\U2714 OK:${no_color} %s${dark_gray}\n" "$in_sample_file"
      cat "$in_sample_file"

      echo
    elif [ $diff_exit_status -eq 1 ]; then
      printf "${red_bold}\U25BC Fail: %s \U25BC \n${no_color}" "$in_sample_file"

      printf "${blue}=== Sample Input Data ===\n${no_color}"
      cat "$in_sample_file"

      printf "${blue}=== Expected Sample Output Data ===\n${no_color}"
      cat "$out_sample_file"

      printf "${blue}=== Received Output Data ===\n${no_color}"
      cat my_out.txt

      # if [ "$SHOW_DIFF" -eq 1 ]; then
      #   printf "${blue}=== Output Data Difference ===\n${no_color}"
      #
      #   tail -n +2 out_data_diff.txt
      #
      #   awk '
      #   /^</ { print "\033[32m" $0 "\033[0m" }
      #   /^>/ { print "\033[31m" $0 "\033[0m" }
      #   /^---/ { print $0 }
      #   ' out_data_diff.txt
      #
      # fi

      echo
    else
      printf "${orange}\U25BC Caution: %s \U25BC \n${no_color}" "$in_sample_file"

      printf "${blue}=== Sample Input Data ===\n${no_color}"
      cat "$in_sample_file"

      printf "${blue}=== Received Output Data ===\n${no_color}"
      cat my_out.txt

      echo
    fi
  done

  rm my_out.txt out_data_diff.txt
fi

user_input=0
if [[ "$file_path" == *.c || "$file_path" == *.cpp ]]; then
  c_input_functions='scanf|fscanf|sscanf|vscanf|vfscanf|vsscanf|getchar|fgets|fgetc|getc|gets|read'
  cpp_input_functions='std::cin|std::getline|std::istream::get|std::istream::getline|std::istream::read|std::istream::readsome'
  if grep -q -E "$cpp_input_functions|$c_input_functions" "$file_path"; then
      user_input=1
  fi
else
  output=$(timeout --preserve-status 1s "$program_path" 2>/dev/null)
  exit_code=$?
  if [ $exit_code -eq 143 ]; then
    user_input=1
  fi
fi

if [ $user_input -eq 1 ]; then

  if [[ -n "$compile_output" ]]; then
    printf "${no_color}"
    echo "$compile_output"
  fi

  if [ ! -e "${input_files[0]}" ]; then
    printf "${red_bold}\U26A0 Warning:${no_color} No sample input data found in %s\n\n" "${sample_dir_path}"
  fi
  if [ $CONTINUE_AFTER_TESTS -eq 1 ]; then
    printf "${dark_gray_bold}\U25BC Manual input: \U25BC \n${no_color}"
    while [ $CONTINUE_AFTER_TESTS -eq 1 ]; do
        $program_path
        printf "${dark_gray}======\n${no_color}"
    done
  fi
else
  { $program_path; } 2>/dev/null

  if [[ -n "$compile_output" ]]; then
    echo "$compile_output"
  fi

  output=$($program_path 2>&1)
  assertion_error=$(echo "$output" | awk -F'`' '/Assertion/ {split($2,a,"'"'"'"); print a[1]}')
  if [[ -n "$assertion_error" ]]; then
    printf "${red_bold}\U25BC Failed assertion: \U25BC \n${no_color}"
    echo "$assertion_error"
  else
    printf "${green_bold}\U2714 OK${no_color}\n"
  fi
fi

rm "$program_path"

