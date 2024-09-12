#!/usr/bin/env bash

check_command(){
  output="$(command -v "$1")"
  if [[ "${output}" == "" ]]; then
    errMsg="$1 not found"
    echo -e "\\x1b[31m$errMsg\\x1b[0m See: ($2)"
  else
    version="$("$1" version --client 2>/dev/null || "$1" --version 2>/dev/null)"

    if [[ "${version}" == ""  ]]; then
     echo -e  "\\x1b[33m$1\\x1b[0m Found, but could not locate version."
     else
      echo -e  "\\x1b[32m$1\\x1b[0m Found - Version: \n$version"
    fi
    echo -e "\\x1b[32m$1\\x1b[0m is installed at ${output}"
  fi
}

