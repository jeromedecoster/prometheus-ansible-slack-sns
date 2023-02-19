#!/bin/bash

log() { echo -e "\e[30;47m ${1} \e[0m ${@:2}"; }          # $1 background white
info() { echo -e "\e[48;5;28m ${1} \e[0m ${@:2}"; }       # $1 background green
warn() { echo -e "\e[48;5;202m ${1} \e[0m ${@:2}" >&2; }  # $1 background orange
error() { echo -e "\e[48;5;196m ${1} \e[0m ${@:2}" >&2; } # $1 background red

# the directory containing the script file
export PROJECT_DIR="$(cd "$(dirname "$0")"; pwd)"

#
# variables : source + export all variables from .env 
#
if [[ -f $PROJECT_DIR/.env ]];
then
    # https://unix.stackexchange.com/a/79077 (`set -a` then `set +a` good but weird)
    # https://unix.stackexchange.com/a/79065 (simpler + one line)
    source $PROJECT_DIR/.env
    export $(cut -d= -f1 $PROJECT_DIR/.env | grep ^[A-Z])
else 
    warn WARN .env file is missing
fi

#
# overwrite default TF variables
#
export TF_VAR_project_dir=$PROJECT_DIR
export TF_VAR_project_name=$PROJECT_NAME
export TF_VAR_aws_region=$AWS_REGION
export TF_VAR_aws_profile=$AWS_PROFILE
export TF_VAR_sns_email=$SNS_EMAIL
# https://developer.hashicorp.com/terraform/cli/config/environment-variables#tf_var_name
export TF_VAR_ansible_all_ips='["'$NODE1_IP'","'$NODE2_IP'"]'
export TF_VAR_ansible_monitoring_ips='["'$MONITORING_IP'"]'

under() { echo -e "\033[0;4m${@}\033[0m"; } # write $@ underline
bold()  { echo -e "\033[1m${@}\033[0m"; }   # write $@ in bold

usage() {
    cat << EOF
$(under Usage)

    $(bold make dev)        Using Makefile
    $(bold ./make.sh dev)   Directly from the shell script
EOF
}

# create .env file
env-create() {
    local AWS_PROFILE=default

    # root account id
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
        --query 'Account' \
        --profile $AWS_PROFILE \
        --output text)
    log AWS_ACCOUNT_ID $AWS_ACCOUNT_ID

    # setup .env file with default values
    scripts/env-file.sh .env \
        AWS_PROFILE=$AWS_PROFILE \
        AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID \
        PROJECT_NAME=prometheus-ansible \
        MONITORING_IP=10.20.20.20 \
        NODE1_IP=10.30.30.30 \
        NODE2_IP=10.40.40.40 \
        GRAFANA_ADMIN_USER=admin \
        GRAFANA_ADMIN_PASSWORD=password

    # setup .env file again
    # /!\ use your own values
    scripts/env-file.sh .env \
        AWS_REGION=eu-west-3 \
        AWS_PROFILE=default \
        SNS_EMAIL=[change-here]@gmail.com \
        SLACK_API_URL=https://hooks.slack.com/services/[change-here] \
        SLACK_CHANNEL="#[change-here]"
}

# terraform init (upgrade) + validate
terraform-init() {
    CHDIR="$PROJECT_DIR/terraform" scripts/terraform-init.sh
}

# terraform create sns topic + ssh key + iam user ...
infra-create() {
    CHDIR="$PROJECT_DIR/terraform" scripts/terraform-apply.sh
}

# create monitoring + node1 + node2 
vagrant-up() {
    [[ ! -f ~/.ssh/${PROJECT_NAME}.pub ]] && { error ABORT "~/.ssh/${PROJECT_NAME}.pub is required"; exit 0; }
    export SSH_PUBLIC_KEY=$(cat ~/.ssh/${PROJECT_NAME}.pub)
    cd "$PROJECT_DIR/vagrant"
    vagrant up

    # for name in monitoring node1 node2
    # do
    #     CONFIG=$(vagrant ssh-config $name 2>/dev/null)
    #     # echo "$CONFIG"
    #     SSH_KEY=$(echo "$CONFIG" | grep IdentityFile | sed 's|^\s*IdentityFile\s*||')
    #     log SSH_KEY $SSH_KEY
    #     SSH_USER=$(echo "$CONFIG" | grep 'User ' | sed 's|^\s*User\s*||')
    #     log SSH_USER $SSH_USER
    #     SSH_HOST=$(echo "$CONFIG" | grep HostName | sed 's|^\s*HostName\s*||')
    #     log SSH_HOST $SSH_HOST
    #     SSH_PORT=$(echo "$CONFIG" | grep Port | sed 's|^\s*Port\s*||')
    #     log SSH_PORT $SSH_PORT

    #     # prevent SSH warning : 
    #     # @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!   @ 
    #     # @ IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY! @ 
    #     ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[$SSH_HOST]:$SSH_PORT" 1>/dev/null 2>/dev/null
    #     # ⚠ important : after `.ssh/known_hosts` update by ssh-keygen it is HIGHLY recommended 
    #     # to `sleep 1` second before `ssh-keyscan` to prevent exit code
    #     # also, do NOT OPEN `.ssh/known_hosts` in an text editor : this can block writing to the file using >>
    #     sleep 1

    #     # prevent SSH answer :
    #     # Are you sure you want to continue connecting (yes/no/[fingerprint])?
    #     # /!\ important option `-p` MUST be defined BEFORE ip $SSH_HOST
    #     ssh-keyscan -p $SSH_PORT $SSH_HOST 2>/dev/null >> ~/.ssh/known_hosts
    # done

    for ip in $MONITORING_IP $NODE1_IP $NODE2_IP
    do
        # prevent SSH warning : 
        # @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!   @ 
        # @ IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY! @ 
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$ip" 1>/dev/null 2>/dev/null
        # ⚠ important : after `.ssh/known_hosts` update by ssh-keygen it is HIGHLY recommended 
        # to `sleep 1` second before `ssh-keyscan` to prevent exit code
        # also, do NOT OPEN `.ssh/known_hosts` in an text editor : this can block writing to the file using >>
        sleep 1

        # prevent SSH answer :
        # Are you sure you want to continue connecting (yes/no/[fingerprint])?
        # /!\ important option `-p` MUST be defined BEFORE ip $SSH_HOST
        ssh-keyscan $ip 2>/dev/null >> ~/.ssh/known_hosts
    done
    
    # TODO : make it a robust shell scripts reusable in ./scripts/ or ./tools/
    if [[ -z $(grep "Host monitoring $MONITORING_IP # $PROJECT_NAME" ~/.ssh/config) ]];
    then
        echo "
Host monitoring $MONITORING_IP # $PROJECT_NAME
    HostName $MONITORING_IP
    User vagrant
    IdentityFile ~/.ssh/$PROJECT_NAME
    
Host node1 $NODE1_IP # $PROJECT_NAME
    HostName $NODE1_IP
    User vagrant
    IdentityFile ~/.ssh/$PROJECT_NAME
    
Host node2 $NODE2_IP # $PROJECT_NAME
    HostName $NODE2_IP
    User vagrant
    IdentityFile ~/.ssh/$PROJECT_NAME" >> ~/.ssh/config
    fi

    # check ssh connexion #1
    # ssh -i "$SSH_KEY" $SSH_USER@$SSH_HOST -p $SSH_PORT pwd

    [[ $(ssh monitoring pwd) == '/home/vagrant' ]] \
        && info SUCCESS 'ssh connexion using `ssh monitoring`' \
        || error ERROR 'ssh connexion using `ssh monitoring`'

    [[ $(ssh node1 pwd) == '/home/vagrant' ]] \
        && info SUCCESS 'ssh connexion using `ssh node1`' \
        || error ERROR 'ssh connexion using `ssh node1`'

    [[ $(ssh node2 pwd) == '/home/vagrant' ]] \
        && info SUCCESS 'ssh connexion using `ssh node2`' \
        || error ERROR 'ssh connexion using `ssh node2`'
}

# halt the 3 machines
vagrant-halt() {
    cd "$PROJECT_DIR/vagrant"
    vagrant halt
}

# destroy the 3 machines
vagrant-destroy() {
    cd "$PROJECT_DIR/vagrant"
    vagrant destroy --force
}

# install + configure prometheus + grafana + alert manager ...
ansible-play() {
    cd "$PROJECT_DIR/ansible"
    ansible-playbook --inventory inventory.yml playbook.yml
}

# terraform destroy sns topic + ssh key + iam user ...
infra-destroy() {
    terraform -chdir=$PROJECT_DIR/terraform destroy -auto-approve
}

# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] &&
    { info EXECUTE $1; eval $1; } || 
    usage
exit 0
