#!/bin/bash
# shellcheck disable=SC2015,SC2236
#
# Manages looped runs
# ===================
#
# Use this script to automate HTTPS SSL Certificate monitoring. 
# It curl's remote server on 443 port and then checks remote 
# SSL Certificate expiration date. You can use it with Zabbix, 
# Nagios/Icinga or other.
#
# GitHub repository: 
# https://github.com/pavelkim/check_certificates
#
# Community support:
# https://github.com/pavelkim/check_certificates/issues
#
# Copyright © 2022, Pavel Kim
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set -o pipefail

VERSION="DEV"

[[ ! -z "${CHECK_INTERVAL}" ]] && OVERRIDE_CHECK_INTERVAL="${CHECK_INTERVAL}"
[[ ! -z "${CHECK_CERTIFICATES_PATH}" ]] && OVERRIDE_CHECK_CERTIFICATES_PATH="${CHECK_CERTIFICATES_PATH}"
[[ ! -z "${GLOBAL_LOGLEVEL}" ]] && OVERRIDE_GLOBAL_LOGLEVEL="${GLOBAL_LOGLEVEL}"

[[ -z "${OVERRIDE_CHECK_INTERVAL}" ]] && CHECK_INTERVAL=$(( 60 * 60 * 2 ))
[[ -z "${OVERRIDE_CHECK_CERTIFICATES_PATH}" ]] && CHECK_CERTIFICATES_PATH="/check_certificates.sh"
[[ -z "${OVERRIDE_GLOBAL_LOGLEVEL}" ]] && GLOBAL_LOGLEVEL=2

usage() {

	cat << EOF
SSL Certificate checker
Version: ${VERSION}

Usage: $0 [args|params]
   args                     Arguments to pass to check_certificates.sh
   params                   Parameters to pass to check_certificates.sh

   -h, --help               Show help

Environment variables:

   CHECK_INTERVAL=N         Interval between starts in sec.
                            Single start will be done if unset or 0.

   CHECK_CERTIFICATES_PATH=/check_certificates.sh
                            Path to check_certificates.sh (executable)
   
   GLOBAL_LOGLEVEL=N        Loglevel: 3=info, 2=warning

EOF

}

timestamp() {
	date "+%F %T"
}

error() {

        [[ ! -z "${1}" ]] && msg="ERROR: ${1}" || msg="ERROR!"
        [[ ! -z "${2}" ]] && rc="${2}" || rc=1

        echo "[$(timestamp)] ${BASH_SOURCE[1]}: line ${BASH_LINENO[0]}: ${FUNCNAME[1]}: ${msg}" >&2
        exit "${rc}"
}

info() {

	local msg="$1"
	local self_level=3
	local self_level_name="info"

	if [[ "${self_level}" -le "${GLOBAL_LOGLEVEL}" ]]; then	
		echo "[$(timestamp)] [${self_level_name}] [${FUNCNAME[1]}] $msg" >&2
		return 0
	fi
}

warning() {

	local msg="$1"
	local self_level=2
	local self_level_name="warning"

	if [[ "${self_level}" -le "${GLOBAL_LOGLEVEL}" ]]; then	
		echo "[$(timestamp)] [${self_level_name}] [${FUNCNAME[1]}] $msg" >&2
		return 0
	fi
}

main() {

	local STOP
	local RC

	STOP=0

	while [[ ${STOP} != "1" ]]; do

		if [[ "${CHECK_INTERVAL}" == "0" || -z "${CHECK_INTERVAL}" ]]; then
			warning "Check interval makes it a non-loop, single start: CHECK_INTERVAL='${CHECK_INTERVAL}'"
			STOP=1
		fi

		info "Calling '${CHECK_CERTIFICATES_PATH} ${*}'"
		"${CHECK_CERTIFICATES_PATH}" "$@"
		RC=$?

		[[ "${RC}" != "0" ]] && error "Script '${CHECK_CERTIFICATES_PATH}' exited with code '${RC}', can't continue" "${RC}"

		info "Sleeping before the next run for '${CHECK_INTERVAL}' sec."
		sleep "${CHECK_INTERVAL}"

	done

}

main "${@}"
