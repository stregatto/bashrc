#!/bin/bash

export MARKPATH=$HOME/.marks

export GIT_DEFAULT_BRANCHES='trunk sre prd nonprd dev stg'

function parse_git_branch {
   git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function manman {
    echo -e "___________________________________________\n"
    echo "Stregatto's help"
    echo -e "These are the custom function you can use:\n"
    egrep -E ^function ~/.bashrc |awk '{print $2}'| egrep -Ev ^_
    echo -e "___________________________________________\n"
}

function check_compression {
  curl -s -I -H 'Accept-Encoding: gzip,deflate' $1 |grep "Content-Encoding"
}

function setgopath {
  LOCALDIR=$(pwd)
  if [[ ! -e $DEFAULT_GOPATH ]]; then
    export DEFAULT_GOPATH=${GOPATH}
  fi
  export GOPATH=${LOCALDIR}
  echo The GOPATH is ${GOPATH}
}

function resetgopath {
  if [[ ! -e $DEFAULT_GOPATH ]]; then
      echo "Nothing to do"
  else
      export GOPATH=${DEFAULT_GOPATH}
  fi
  echo The GOPATH is ${GOPATH}
}

# emergency nodns ssh
function sshnodns {
    if [[ $1 == *"@"* ]]
    then
        IN=$1
        shift
        commandline=$@
        set -- "$IN"; IFS="@"; declare -a Array=($*)
        remoteserver=$(/usr/bin/dig @${DEFDNS} ${Array[1]}.${DOMAIN} | awk  '/ANSWER SECTION/{  getline; print $5 }')
        shift
        /usr/bin/ssh ${Array[0]}@$remoteserver "$commandline"
    else
        remoteserver=$(/usr/bin/dig @${DEFAULT_DNS} $1.${DOMAIN} | awk  '/ANSWER SECTION/{  getline; print $5 }')
        shift
        /usr/bin/ssh $remoteserver "$@"
    fi
}

function certcheck {
  if ! [[ -z "$1" ]]
  then
      WEBSITE=$1
      echo -n | openssl s_client -connect ${WEBSITE}:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'|openssl x509 -text -noout
  else
      echo "Please, give me at least one web site"
  fi
}

# ddump returns dump of dns grepping for a string, is useful to find server (cname/a/srv records) on multiple domains
function ddump {
  domains='prod nonprd dev fancy foo bar'
  domain=''
  dns=${DEFAULT_DNS}
  stringToGrep=$2
  tempfile=$(mktemp)
  case $1 in
    "prod" )
      domain='prod.org' ;;
    "nonprd" )
      domain='nonprd.org';;
    "foo" )
        domain='foo.org';;
    "bar" )
        domain='bar.org';;
    "dev" )
      domain='dev.org'
      dns=${DEV_ORG_DNS};;
    "fancy" )
      dns=${FANCY_ORG_DNS}
      domain='fancy.org';;
    "all" )
      domain='all';;
    *)
      echo "
Usage:
  ddump DOMAIN [name|ip]

Please, give me one domain:

prod.org              => prod
nonprd.org            => nonprd
foo.org               => foo
bar.org               => bar
dev.org               => dev
fancy.org             => fancy
test all                    => all

      "
    esac
    if ! [[ -z "${domain}" ]] && ! [[ ${domain} == "all" ]]
      then
        dig AXFR ${domain} @${dns} > ${tempfile}
        if ! [[ -z "${stringToGrep}" ]]
          then
            cat ${tempfile} |grep ${stringToGrep}
          else
            cat ${tempfile}
        fi
        rm ${tempfile}
    elif [[ ${domain} == "all" ]]
      then
        for d in ${domains}
          do
            ddump ${d} ${stringToGrep}
          done
    fi
}

function puppet_modules {
  DEFAULT_GIT="ssh://${DEFAULT_GIT_USER}@${DEFAULT_GIT_SERVER}"
  SWITCH=$1
  PARAM=$2
  case ${SWITCH} in
    "add" )
       _add_puppet_modules "${PARAM}";;
    "delete" )
      echo "delete";;
    "search" )
      echo "search";;
    * )
      echo "
Usage:
  puppet_modules [add|delete|search] MODULE_NAME

The command expects to be in the Puppet's modules direcotry

MODULE_NAME is the name of the module you would like to add, format:
  modue_somename

The module will be added to the default branches:
  $GIT_DEFAULT_BRANCHES

The module should be present in the following git repository:
  $DEFAULT_GIT
      ";;
    esac
}

function _add_puppet_modules () {
  MODULENAME=${1#module_}
  MODULESFILE="Puppetfile"
  for BRANCH in $GIT_DEFAULT_BRANCHES
  do
    git checkout ${BRANCH}
    NEWMODULE="
mod '$MODULENAME',
 :git => \"${DEFAULT_GIT}/module_${MODULENAME}.git\",
 :branch => '$BRANCH'"
    cp ${MODULESFILE} ${MODULESFILE}.tmp
    echo "${NEWMODULE}" >> ${MODULESFILE}.tmp
    cat ${MODULESFILE}.tmp |grep -v '^$' > ${MODULESFILE} && rm ${MODULESFILE}.tmp
    git diff
    read -p "Please check the differences, can I continue and commit on remote? y/N" yn
    case $yn in
      [Yy]* ) git add ${MODULESFILE} &&
              git commit -m "add ${MODULENAME}" &&
              git push;;
      * ) git reset --hard HEAD; break;;
    esac
  done
}

function validateyaml {
    if ! [[ -z "$1" ]]
    then
        FILE=$1
        python -c 'import yaml,sys;yaml.safe_load(sys.stdin)' < ${FILE}
    else
        echo "Please, give me some file"
    fi
}

function validatejson {
    if ! [[ -z "$1" ]]
    then
        FILE=$1
        python -m json.tool < ${FILE}
    else
        echo "Please, give me some file"
    fi
}

settitle() {
    printf "\033k$1\033\\"
    }


ssh() {
    settitle "$*";
    command ssh "$@";
    settitle "bash";
}


function jump {
    cd -P "$MARKPATH/$1" 2>/dev/null || echo "No such mark: $1"
}
function mark {
    mkdir -p "$MARKPATH"; ln -s "$(pwd)" "$MARKPATH/$1"
}
function unmark {
    rm -i "$MARKPATH/$1"
}
function marks {
    \ls -l "$MARKPATH" | tail -n +2 | sed 's/  / /g' | cut -d' ' -f9- | awk -F ' -> ' '{printf "%-10s -> %s\n", $1, $2}'
}


function _git-branches {
    export GITBRANCHES=`git branch | grep -v forge|awk 'BEGIN { ORS = " " } { print }'|tr \* ' '`
}

function git-rebase-all {
    _git-branches
    echo "Rebase all branches to trunk ${GITBRANCHES}"
    for b in ${GITBRANCHES}
        do
            git checkout ${b} && \
            git rebase trunk && \
            git push
        done
    git checkout trunk
}


function git-reset-all {
    _git-branches
    echo "Hard Reset of all branches"
    for b in ${GITBRANCHES}
    do
        git checkout ${b} && \
        git clean -f && \
        git reset --hard HEAD && \
        git fetch origin && \
        git reset --hard origin/${b}
    done
    git checkout trunk
}


function git-checkout-default-branches {
    echo "Checkout all branches from ${GIT_DEFAULT_BRANCHES}"
    for branch in ${GIT_DEFAULT_BRANCHES}
        do
            git checkout ${branch}
            git pull origin ${branch}
        done
    git checkout trunk
}

function git-pull-all {
    _git-branches
    echo "Pulling all branches: ${GITBRANCHES}"
    for b in ${GITBRANCHES}
        do
            git checkout ${b} && \
            git pull
        done
    git checkout trunk
}

_completemarks() {
  local curw=${COMP_WORDS[COMP_CWORD]}
  local wordlist=$(find $MARKPATH -type l |grep -Eo '[^/]+/?$')
  COMPREPLY=($(compgen -W '${wordlist[@]}' -- "$curw"))
  return 0
}

#skip bash dependencies
if [ $0 == '-bash' ];
then
    complete -F _completemarks jump unmark

    # Bash completition
    if [ -f $(brew --prefix)/etc/bash_completion ]; then
        . $(brew --prefix)/etc/bash_completion
    fi
fi

function python-update-venv-v3() {
  PYTHON_VERSION='3.7'
  echo "Removing old venv3: ${PYTHON_VENV_HOME}/venv3"
  cd "${PYTHON_VENV_HOME}"
  rm -rf "./venv3"
  virtualenv --python=python${PYTHON_VERSION} venv3
  echo "update packages"
  source ./venv3/bin/activate
  ${PYTHON_PERSONAL_HOME}/packages.sh pycurl
  cd -
}
