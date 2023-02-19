#!/bin/bash

log()   { echo -e "\e[30;47m ${1} \e[0m ${@:2}"; }        # $1 background white
info()  { echo -e "\e[48;5;28m ${1} \e[0m ${@:2}"; }      # $1 background green
warn()  { echo -e "\e[48;5;202m ${1} \e[0m ${@:2}" >&2; } # $1 background orange
error() { echo -e "\e[48;5;196m ${1} \e[0m ${@:2}" >&2; } # $1 background red

log START $(date "+%Y-%d-%m %H:%M:%S")
START=$SECONDS

# https://www.cyberciti.biz/faq/linux-bash-exit-status-set-exit-statusin-bash/
# exit code `0` : Success
# exit code `1` : Operation not permitted
check_exit_code() {
    [[ $1 == 0 ]] && return
    error ABORT exit code $1 returned
    info DURATION $(($SECONDS - $START)) seconds
    exit 0
}

[[ -z $(printenv | grep ^CHDIR=) ]] &&
    { error ABORT CHDIR env variable is required; exit 1; } || 
    log CHDIR $CHDIR

# ⚠ very very useful for saving THOUSANDS of megabytes on your computer ⚠
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# https://www.terraform.io/cli/commands/init
# Error: Inconsistent dependency lock file
# use `init -upgrade` to update the locked dependency selections

info TERRAFORM init
terraform -chdir="$CHDIR" init -upgrade
# abort if exit code != 0
check_exit_code $?


info TERRAFORM validate
# https://www.terraform.io/cli/commands/validate
terraform -chdir="$CHDIR" validate
# abort if exit code != 0
check_exit_code $?


log END $(date "+%Y-%d-%m %H:%M:%S")
info DURATION $(($SECONDS - $START)) seconds