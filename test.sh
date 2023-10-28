#!/bin/bash

SHOW_DIFF=1
DEFAULT_COMPILE_ARGUMENTS="-Wall -g -fsanitize=address"
#DEFAULT_COMPILE_ARGUMENTS="-Wall -Werror -g -fsanitize=address"
CONTINUE_AFTER_TESTS=1

relative_path=$(dirname "$1")
code_path="$1"
program_name="$(basename "${code_path%.*}")"
program_path="${relative_path}/${program_name}"
sample_dir_path="${relative_path}/sample/CZE/"

if [[ "$1" == *.c ]]; then
  shift

  compile_output=$(g++ -fdiagnostics-color=always $DEFAULT_COMPILE_ARGUMENTS -o "${relative_path}/${program_name}" "$code_path" "$@" 2>&1)

  return_code=$?
  if [ $return_code -ne 0 ]; then
      echo "$compile_output"
      exit 1
  fi
fi

no_color="\e[0;0m"

green="\e[1;32m"
red="\e[1;31m"
blue="\e[0;34m"
dark_gray="\e[0;90m"
dark_gray_bold="\e[1;90m"
orange="\e[1;37m"

for in_sample_file in "${sample_dir_path}"*_in.txt; do
	out_sample_file=$(echo -n "$in_sample_file" | sed -e "s/_in\(.*\)$/_out\1/")

	$program_path < "$in_sample_file" > my_out.txt

	diff "$out_sample_file" my_out.txt > out_data_diff.txt 2>/dev/null
  diff_exit_status=$?

  if [ $diff_exit_status -eq 0 ]; then
    printf "${green}\U25B6 OK:${no_color} %s${dark_gray}\n" "$in_sample_file"
    cat "$in_sample_file"
    echo
  elif [ $diff_exit_status -eq 1 ]; then
    printf "${red}\U25BC Fail: %s \U25BC \n${no_color}" "$in_sample_file"
    printf "${blue}=== Sample Input Data ===\n${no_color}"
    cat "$in_sample_file"
    printf "${blue}=== Expected Sample Output Data ===\n${no_color}"
    cat "$out_sample_file"
    printf "${blue}=== Received Output Data ===\n${no_color}"
    cat my_out.txt
    if [ "$SHOW_DIFF" -eq 1 ]; then
      printf "${blue}=== Output Data Difference ===\n${no_color}"
      tail -n +2 out_data_diff.txt
    fi
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

if [[ -n "$compile_output" ]]; then
    echo "$compile_output"
fi

if [ $CONTINUE_AFTER_TESTS -eq 1 ]; then
  printf "${dark_gray_bold}\U25BC Manual input: \U25BC \n${no_color}"
fi
while [ $CONTINUE_AFTER_TESTS -eq 1 ]; do
  $program_path
  printf "${dark_gray}====== \n${no_color}"
done

