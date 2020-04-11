#!/bin/bash
#    Copyright 2020 Leonardo Andres Morales

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.


# @description Create a dialog to ask for a value
# @arg $type one of: string | number | password
# @arg $var_name name of an existing variable, it's value is used as default value
# @arg $title on the dialog
# @exitcode 1 - unknown value type
# @exitcode 0 - variable successfuly inquired and set
# @example
#    askValue type var_name title
#
#    local myvariable="Hello"
#    askValue string myvariable "Configuring myvariable"
function askValue() {
  getArgs "type var_name title"

  checkBins dialog
  exitOnError "Bash 'dialog' util not found"

  local subtitle="Please type the ${var_name} value:"

  local value=
  case ${type} in
    string)
      value=$(dialog --stdout --title "${title}" --inputbox "${subtitle}" 0 0 "${!var_name}")
      ;;
    number)
      while : ; do
        value=$(dialog --stdout --title "${title}" --inputbox "${subtitle}" 0 0 "${!var_name}")
        if [[ "$value" =~ ^[0-9]+$ ]]; then
          break
        fi
      done
      ;;
    password)
      value=$(dialog --stdout --title "${title}" --passwordbox "${subtitle}" 0 0)
      ;;
    *)
      echoError "Invalid dialogs.askValue type ${type} for ${title}: ${var_name}"
      exit 1
    ;;
  esac
  eval "${var_name}=\"${value}\""
}

# @description Create a configuration dialog containing a selection of variables to update
# @arg $title on the dialog
# @arg $layout string containing pairs of:
#     var_type var_name
# @see askValue for layout types
# @example
#  local my_id=baroni
#  local my_age=27
#  showConfigurationDialog "Please set my_id and my_age" "
#    string my_id
#    number my_age
#  "
function showConfigurationDialog() {
  getArgs "title layout"

  checkBins dialog
  exitOnError "Bash 'dialog' util not found"

  local OLDIFS=${IFS}
  # Keep looping with the dialogs until finish
  while : ; do
    # Initialize dialog
    local dialog_cmd="dialog --stdout --menu \"${title}\" 0 0 0"
    local field
    IFS=$'\n'
    # For every layout field
    for field in ${layout//\\n/ }
    do
      IFS=' '
      local parts=(${field})
      local value=${!parts[1]}
      # Hide password fields
      [ "${parts[0]}" = "password" ] && value='######'
      # Build dialog_cmd
      [ -n "${parts[1]}" ] && dialog_cmd="${dialog_cmd} ${parts[1]} \"${value}\""
    done
    dialog_cmd="${dialog_cmd} finish ''"
    # Run dialog and get return
    local selection=$(eval ${dialog_cmd})
    IFS=$'\n'
    local found=0
    # Find the selected property
    for field in ${layout//\\n/ }
    do
      IFS=' '
      local parts=(${field})
      [ -z "${parts[1]}" ] && continue
      [ "${selection}" != "${parts[1]}" ] && continue
      # Property layout item found, update it
      self askValue ${parts[0]} ${parts[1]} "${title}"
      [ $? = "0" ] && found=1
    done
    [ "${found}" = "0" ] && break
  done
  IFS=${OLDIFS}
}

