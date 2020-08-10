#!/bin/bash
#
# Checks if SSL Certificate on https server is valid.
#
# Input file format:
#  domain1.com
#  domain2.com
#  domain3.com
# 
# Result output format:
#  domain1.com  error                error                -1
#  domain2.com  2013-10-31 00:00:00  2016-10-30 23:59:59  92
#  domain2.com  2015-12-03 00:00:00  2016-12-02 23:59:59  125
#

set -o pipefail

VERSION="DEV"

usage() {

	cat << EOF
SSL Certificate checker
Version: ${VERSION}

Usage: $0 [-h] [-v] [-l] [-n] [-A n] -i input_filename

	-i, --input-filename 	 Path to the list of domains to check
	-l, --only-alerting  	 Show only alerting domains (expiring soon and erroneous)
	-n, --only-names     	 Show only domain names instead of the full table
	-A, --alert-limit    	 Set threshold of upcoming expiration alert to n days
	-v, --verbose        	 Enable debug output
	-h, --help           	 Enable debug output

EOF

}

timestamp() {
	date "+%F %T"
}

info() {

	local msg="$1"
	local self_level=3
	local self_level_name="info"

	if [[ "${self_level}" -le "${GLOBAL_LOGLEVEL}" ]]; then	
		ts="$(timestamp)"
		echo "[${ts}] [${self_level_name}] [${FUNCNAME[1]}] $msg" >&2
		return 0
	fi
}

warning() {

	local msg="$1"
	local self_level=2
	local self_level_name="warning"

	if [[ "${self_level}" -le "${GLOBAL_LOGLEVEL}" ]]; then	
		ts="$(timestamp)"
		echo "[${ts}] [${self_level_name}] [${FUNCNAME[1]}] $msg" >&2
		return 0
	fi
}

date_to_epoch() {

	#
	# Converts a date string returned by OpenSSL to a Unix timestamp integer
	#

	local date_from

	[[ ! -z "$1" ]] && date_from="$1" || return 2

	case "$OSTYPE" in
		linux*)  date -d "${date_from}" "+%s" ;;
		darwin*) date -j -f "%b %d %T %Y %Z" "${date_from}" "+%s" ;;
	esac
}


epoch_to_date() {

	#
	# Converts a Unix timestamp integer to a date of a format passed as the second parameter
	#

	local date_epoch
	local date_format

	[[ ! -z "$1" ]] && date_epoch="$1" || return 2
	[[ ! -z "$2" ]] && date_format="$2" || date_format="+%F %T"

	case "$OSTYPE" in
		linux*)  date -d "@${date_epoch}" "${date_format}" ;;
		darwin*) date -j -f "%s" "${date_epoch}" "${date_format}" ;;
	esac
}

check_https_certificate_dates() {

	#
	# Probes remote host for HTTPS, retreives expiration dates and returns them in Unix timestamp format
	#

	[[ ! -z "$1" ]] && local remote_hostname="$1" || { warning "Remote hostname not set!"; return 100; }
	[[ ! -z "$2" ]] && local retries="$2" || retries=1
	[[ ! -z "$3" ]] && local current_retry="$3" || current_retry=1
	
	local result
	local final_result
	local dates=( )
	
	if [[ "${retries}" -gt 1 ]] && [[ "${current_retry}" -le "${retries}" ]]; then
		info "Retry #${current_retry} of ${retries} (Not implemented yet)"
		current_retry=$(( current_retry + 1 ))
		return 1
	fi

	info "Starting https ssl certificate validation for ${remote_hostname}"
	result="$( echo | openssl s_client -servername "${remote_hostname}" -connect "${remote_hostname}:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null | cut -d"=" -f2  )"
	RC=$?
	
	if [[ "${RC}" != "0" ]]; then

		warning "Can't process openssl output for ${remote_hostname}"
		final_result="${remote_hostname} error error"

	else

		while read line; do
			dates+=( "${line}" )
		done <<< "${result}"
	
		info "${remote_hostname} Not before ${dates[0]}"
		info "${remote_hostname} Not after ${dates[1]}"
		
		final_result="${remote_hostname} $(date_to_epoch "${dates[0]}") $(date_to_epoch "${dates[1]}")"
	fi
	
	echo "${final_result}"
	return "${RC}"
}

_required_cli_parameter() {

	local parameter_name
	local parameter_description

	[[ ! -z "${1}" ]] && parameter_name="${1}" || { echo "Error: Parameter name not set." >&2; exit 2; }
	[[ ! -z "${2}" ]] && parameter_description="${2}" || parameter_description=""

	if [[ -z "${!parameter_name}" ]]; then
		echo "Required parameter: ${parameter_description:-$parameter_name}"
		exit 1
	else
		return 0
	fi

}

main() {

	local CLI_INPUT_FILENAME
	local CLI_ONLY_ALERTING=0
	local CLI_ALERT_LIMIT=7
	local CLI_ONLY_NAMES=0
	local CLI_RETRIES=2
	local CLI_VERBOSE=0

	while [[ "$#" -gt 0 ]]; do 
		case "${1}" in
			-i|--input-filename)	CLI_INPUT_FILENAME="${2}"; shift; shift;;
			-l|--only-alerting)	CLI_ONLY_ALERTING=1; shift;;
			-n|--only-names)	CLI_ONLY_NAMES=1; shift;;
			-A|--alert-limit)	CLI_ALERT_LIMIT="${2}"; shift; shift;;
			-R|--retries)	CLI_RETRIES="${2}"; shift; shift;;
			-v|--verbose)	CLI_VERBOSE=1;shift;;
			-h|--help) usage; exit 0;;
			*) usage "Unknown parameter passed: '${1}'"; shift; shift;;
		esac; 
	done

	_required_cli_parameter CLI_INPUT_FILENAME "Input filename"
	[[ -f "${CLI_INPUT_FILENAME}" ]] || { echo "Can't open input file: '${CLI_INPUT_FILENAME}'"; exit 2; }

	[[ "${CLI_VERBOSE}" == "1" ]] && GLOBAL_LOGLEVEL=7 || GLOBAL_LOGLEVEL=0

	local full_result=( )
	local error_result=( )
	local formatted_result=( )
	local sorted_result=( )
	local today_timestamp

	today_timestamp="$(date "+%s")"

	while IFS= read -r remote_hostname; do 

		[[ -z "${remote_hostname}" ]] && continue

		info "Processing '${remote_hostname}'"
		current_result=$( check_https_certificate_dates "${remote_hostname}" )
		rc="$?"
		
		if [[ "${rc}" != "0" ]]; then
			warning "Skipping '${remote_hostname}'"
			error_result+=( "${remote_hostname}" )
		else
			full_result+=( "${current_result}" )
		fi
		info "Finished processing '${remote_hostname}'"
	done < "${CLI_INPUT_FILENAME}"

	if [[ "${#full_result[@]}" -le "0" ]]; then
		warning "Couldn't process anything from '${CLI_INPUT_FILENAME}'"
	fi

	if [[ "${#error_result[@]}" -gt "0" ]]; then
		for error_item in "${error_result[@]}"; do
			formatted_result+=( "${error_item}	error	error	-1" )
		done
	fi

	for result_item in "${full_result[@]}"; do
		
		result_item_parts=( ${result_item} )
		
		if [[ "${CLI_ONLY_ALERTING}" == "1" ]]; then
			if [[ "$(( (result_item_parts[2] - today_timestamp) / 86400 ))" -gt "${CLI_ALERT_LIMIT}" ]]; then
				continue
			fi
		fi

		formatted_result+=( "${result_item_parts[0]}	$(epoch_to_date "${result_item_parts[1]}" "+%F %T")	$(epoch_to_date "${result_item_parts[2]}" "+%F %T")	$(( (result_item_parts[2] - today_timestamp) / 86400 ))" )
	done

	while read formatted_item; do
		sorted_result+=( "${formatted_item}" )
	done <<< "$( IFS=$'\n' ; echo "${formatted_result[*]}" | sort -n -k6)"

	if [[ "${CLI_ONLY_NAMES}" == "1" ]]; then
		(IFS=$'\n'; echo "${sorted_result[*]}" | awk '{ print $1 }')
	else
		(IFS=$'\n'; echo "${sorted_result[*]}" | column -t -s$'\t')
	fi

}

main "$@"
