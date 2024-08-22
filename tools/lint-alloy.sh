#!/usr/bin/env bash

# Yep, its just the Grafana River lint script

#cd "alloy-modules/" || exit

# check if the alloy CLI tool is installed
if [[ "$(command -v alloy)" == "" ]]; then
  errMsg="Alloy CLI Tool Not Found."
  echo -e "\\x1b[31m$errMsg\\x1b[0m See: (https://grafana.com/docs/alloy/latest/set-up/install/)"
  exit 0
fi

(return 0 2>/dev/null) && sourced=1 || sourced=0

format="console"

for arg in "$@"
do
  if [[ "$arg" == "format=checkstyle" ]]; then
    format="checkstyle"
    break
  fi
done

if [[ "$format" == "console" ]]; then
  echo "Galah Monitoring - Performing Alloy Lint"
fi

statusCode=0
checkstyle='<?xml version="1.0" encoding="utf-8"?><checkstyle version="4.3">'


while read -r file; do
  message=$(alloy fmt -w "${file}" 2>&1)
  currentCode="$?"
  message=$(echo   "${message}" | grep -v "Error: encountered errors during formatting")

  if [[ "${currentCode}" == 0 ]]; then
    echo -e "\\x1b[32m$file\\x1b[0m: no issues found"

  else
    echo -e "\\x1b[31m$file\\x1b[0m: issues found"

    while IFS= read -r row; do
      line=$(echo "${row}" | awk -F ':' '{print $2}')
      column=$(echo "${row}" | awk -F ':' '{print $3}')
      error=$(echo "${row}" | cut -d':' -f4- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed -e 's/"/\&quot;/g' | xargs)
      checkstyle="${checkstyle}<error line=\"${line}\" column=\"${column}\" severity=\"error\" message=\"${error}\" source=\"grafana-alloy\"/>"
      if [[ "${format}" == "console" ]]; then
        echo "  - ${row}"
      fi
      done <<< "${message}"
      checkstyle="${checkstyle}</file>"
  fi

  if [[ "${statusCode}" == 0 ]]; then
    statusCode="$currentCode"
  fi

done < <(find . -type f -name "*.alloy"  || true)

if [[ "${format}" == "checkstyle" ]]; then
  echo -n "${checkstyle}"
else
  echo ""
  echo ""
fi

if [[ "$sourced" == "1" ]]; then
    return "$statusCode"
  else
    exit "$statusCode"
fi