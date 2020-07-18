#!/bin/bash
#
# Checks if SSL Certificate on https server is valid.
#
# Usage: 
#  ./check_certificate input_filename.txt
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

[[ "${DEBUG}" == "1" ]] && GLOBAL_LOGLEVEL="7" || GLOBAL_LOGLEVEL="0"

VERSION="DEV"

usage() {

	cat << EOF
SSL Certificate checker v.${VERSION}
Usage: $0 input_filename.txt
EOF

}

timestamp() {
	date "+%F %T"
}

info() {

	local msg="$1"
	local self_level=3
	local self_level_name="info"

	if [[ "${self_level}" -le "${GLOBAL_LOGLEVEL}" ]]
	then	
		ts="$(timestamp)"
		echo "[${ts}] [${self_level_name}] [${FUNCNAME[1]}] $msg" >&2
		return 0
	fi
}

warning() {

	local msg="$1"
	local self_level=2
	local self_level_name="warning"

	if [[ "${self_level}" -le "${GLOBAL_LOGLEVEL}" ]]
	then	
		ts="$(timestamp)"
		echo "[${ts}] [${self_level_name}] [${FUNCNAME[1]}] $msg" >&2
		return 0
	fi
}

date_to_epoch() {
	local date_from

	[[ ! -z "$1" ]] && date_from="$1" || return 2

	case "$OSTYPE" in

		linux*)
			date -d "${date_from}" "+%s"
		;;
		darwin* ) 
			date -j -f "%b %d %T %Y %Z" "${date_from}" "+%s"
		;;
	esac
}


date_from_epoch() {
	local date_epoch
	local date_format

	[[ ! -z "$1" ]] && date_epoch="$1" || return 2
	[[ ! -z "$2" ]] && date_format="$2" || return 2

	case "$OSTYPE" in

		linux*)
			date -d "@${date_epoch}" "${date_format}"
		;;
		darwin* ) 
			date -j -f "%s" "${date_epoch}" "${date_format}"
		;;
	esac
}

check_https_certificate_dates() {

	[[ ! -z "$1" ]] && local remote_hostname="$1" || { warning "Remote hostname not set!"; return 100; }
	
	local result
	local final_result
	local dates=( )
	
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

main() {

	[[ ! -z "${1}" ]] && input_filename="${1}" || { echo "Error: Input file not set."; usage; exit 2; }
	[[ -f "${input_filename}" ]] || { echo "Can't open input file: '${input_filename}'"; exit 2; }

	local full_result=( )
	local error_result=( )
	local formatted_result=( )
	local today_timestamp
	local sorted_result=( )

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
	done < "${input_filename}"

	if [[ "${#full_result[@]}" -le "0" ]]; then
		warning "Couldn't process anything from '${input_filename}'"
	fi

	if [[ "${#error_result[@]}" -gt "0" ]]; then
		for error_item in "${error_result[@]}"; do
			formatted_result+=( "${error_item}	error	error	-1" )
		done
	fi

	for result_item in "${full_result[@]}"; do
		result_item_parts=( ${result_item} )
		formatted_result+=( "${result_item_parts[0]}	$(date_from_epoch "${result_item_parts[1]}" "+%F %T")	$(date_from_epoch "${result_item_parts[2]}" "+%F %T")	$(( (result_item_parts[2] - today_timestamp) / 86400 ))" )
	done

	while read formatted_item; do
		sorted_result+=( "${formatted_item}" )
	done <<< "$( IFS=$'\n' ; echo "${formatted_result[*]}" | sort -n -k6)"

	(IFS=$'\n'; echo "${sorted_result[*]}" | column -t -s$'\t')

}

main "$@"
