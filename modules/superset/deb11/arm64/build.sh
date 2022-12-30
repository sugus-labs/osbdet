#!/bin/bash

# Imports

# Variables
SCRIPT_PATH=""  # OS and Architecture dependant
SCRIPT_HOME=""  # OS and Architecture agnostic

# Aux functions

# debug
#   desc: Display a debug message if LOGLEVEL is DEBUG
#   params:
#     $1 - Debug message
#   return (status code/stdout):
debug() {
  if [[ "$LOGLEVEL" == "DEBUG" ]]; then
    echo $1
  fi
}

bienv_install(){
  debug "superset.bienv_install DEBUG [`date +"%Y-%m-%d %T"`] Installing all the software for the BI environment" >> $OSBDET_LOGFILE
  apt-get update >> $OSBDET_LOGFILE 2>&1
  apt-get install -y libffi-dev libsasl2-dev libldap2-dev python3-venv >> $OSBDET_LOGFILE 2>&1
  mkdir /opt/superset >> $OSBDET_LOGFILE 2>&1
  python3 -m venv /opt/superset/ >> $OSBDET_LOGFILE 2>&1
  . /opt/superset/bin/activate >> $OSBDET_LOGFILE 2>&1
  python -m pip install --upgrade pip >> $OSBDET_LOGFILE 2>&1
  python -m pip install apache-superset==2.0.1 >> $OSBDET_LOGFILE 2>&1
  python -m pip install WTForms==2.3.3 >> $OSBDET_LOGFILE 2>&1
  deactivate
  debug "superset.bienv_install DEBUG [`date +"%Y-%m-%d %T"`] Software for the BI environment installed" >> $OSBDET_LOGFILE
}
remove_bienv(){
  debug "superset.remove_bienv DEBUG [`date +"%Y-%m-%d %T"`] Removing BI environment software" >> $OSBDET_LOGFILE
  rm -rf /opt/superset
  apt-get remove -y libffi-dev libsasl2-dev libldap2-dev python3-venv --purge >> $OSBDET_LOGFILE 2>&1
  apt autoremove -y >>$OSBDET_LOGFILE 2>&1
  debug "superset.remove_bienv DEBUG [`date +"%Y-%m-%d %T"`] BI environment software removed" >> $OSBDET_LOGFILE
}

initialsetup(){
  debug "superset.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of Superset" >> $OSBDET_LOGFILE
  . /opt/superset/bin/activate >> $OSBDET_LOGFILE 2>&1
  export FLASK_APP=superset; 
  superset db upgrade >> $OSBDET_LOGFILE 2>&1
  superset fab create-admin --username osbdet --firstname osb --lastname bdet \
                            --email osbdet@osbdet.com --password osbdet123\$ >> $OSBDET_LOGFILE 2>&1
  superset init >> $OSBDET_LOGFILE 2>&1
  deactivate
  debug "superset.initialsetup DEBUG [`date +"%Y-%m-%d %T"`] Initial setup of Superset done" >> $OSBDET_LOGFILE
}

serviceinstall(){
  debug "superset.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation" >> $OSBDET_LOGFILE
  cp $SCRIPT_HOME/superset.service /lib/systemd/system/superset.service
  chmod 644 /lib/systemd/system/superset.service
  systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
  debug "superset.serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script installation done" >> $OSBDET_LOGFILE
}
remove_serviceinstall(){
  debug "superset.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation" >> $OSBDET_LOGFILE
  service superset stop >> $OSBDET_LOGFILE 2>&1
  systemctl disable superset.service >> $OSBDET_LOGFILE 2>&1
  rm /lib/systemd/system/superset.service 
  systemctl daemon-reload >> $OSBDET_LOGFILE 2>&1
  debug "jupyter.remove_serviceinstall DEBUG [`date +"%Y-%m-%d %T"`] Systemd script uninstallation done" >> $OSBDET_LOGFILE
}

# Primary functions
#
module_install(){
  debug "superset.module_install DEBUG [`date +"%Y-%m-%d %T"`] Starting module installation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. BI environment installation
  #   2. Initial setup of Superset
  #   3. Systemd script installation
  printf "  Installing module 'superset' ... "
  bienv_install
  initialsetup
  serviceinstall
  printf "[Done]\n"
  debug "superset.module_install DEBUG [`date +"%Y-%m-%d %T"`] Module installation done" >> $OSBDET_LOGFILE
}

module_status() {
  if [ -d "/opt/superset" ]
  then
    echo "Module is installed [OK]"
    exit 0
  else
    echo "Module is not installed [KO]"
    exit 1
  fi
}

module_uninstall(){
  debug "superset.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Starting module uninstallation" >> $OSBDET_LOGFILE
  # The installation of this module consists on:
  #   1. Systemd script removel
  #   2. Undoing setup of Superset
  #   3. BI environment removal
  printf "  Uninstalling module 'superset' ... "
  remove_serviceinstall
  remove_bienv
  printf "[Done]\n"
  debug "jupyter.module_uninstall DEBUG [`date +"%Y-%m-%d %T"`] Module uninstallation done" >> $OSBDET_LOGFILE
}

usage() {
  echo Starting \'superset\' unit
  echo Usage: script.sh [OPTION]
  echo 
  echo Available options for this module:
  echo "  install             module installation"
  echo "  status              module installation status check"
  echo "  uninstall           module uninstallation"
}

main(){
  # 1. Set logfile to /dev/null if it doesn't exist
  if [ -z "$OSBDET_LOGFILE" ] ; then
    export OSBDET_LOGFILE=/dev/null
  fi
  # 2. Main function
  debug "superset DEBUG [`date +"%Y-%m-%d %T"`] Starting activity with the superset module" >> $OSBDET_LOGFILE
  if [ $# -eq 1 ]
  then
    if [ "$1" == "install" ]
    then
      module_install
    elif [ "$1" == "status" ]
    then
      module_status
    elif [ "$1" == "uninstall" ]
    then
      module_uninstall
    else
      usage
      exit -1
    fi
  else
    usage
    exit -1
  fi
  debug "superset DEBUG [`date +"%Y-%m-%d %T"`] Activity with the superset module is done" >> $OSBDET_LOGFILE
}

if ! [ -z "$*" ]
then
  SCRIPT_PATH=$(dirname $(realpath $0))
  SCRIPT_HOME=$SCRIPT_PATH/../..
  OSBDET_HOME=$SCRIPT_HOME/../..
  main $*
fi
