#!/usr/bin/env bash

#
#   Copyright 2021 Marco Vermeulen
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

function __sdk_list() {
	local candidate="$1"

	if [[ -z "$candidate" ]]; then
		__sdkman_list_candidates
	else
		__sdkman_list_versions "$candidate"
	fi
}

function __sdkman_list_candidates() {
	if __sdkman_offline_mode_enabled; then
		__sdkman_offline_list_candidates
	elif [[ "$SDKMAN_AVAILABLE" == "false" ]]; then
		__sdkman_echo_red "This command is not available. Internet unreachable."
	else
		__sdkman_echo_paged "$(__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/candidates/list")"
	fi
}

function __sdkman_list_versions() {
	local candidate versions_csv

	candidate="$1"
	versions_csv="$(__sdkman_build_version_csv "$candidate")"
	__sdkman_determine_current_version "$candidate"

	if [[ "$SDKMAN_AVAILABLE" == "false" ]]; then
		__sdkman_installed_versions "$candidate" "$versions_csv"
	else
		local current_encoded versions_csv_encoded
		current_encoded="$(__sdkman_url_encode_plus "$CURRENT")"
		versions_csv_encoded="$(__sdkman_url_encode_plus "$versions_csv")"
		__sdkman_echo_paged "$(__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/candidates/${candidate}/${SDKMAN_PLATFORM}/versions/list?current=${current_encoded}&installed=${versions_csv_encoded}")"
	fi
}

function __sdkman_installed_versions() {
	local candidate versions_csv

	candidate="$1"
	versions_csv="$2"

	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
	__sdkman_echo_yellow "Offline: only showing installed ${candidate} versions"
	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"

	# Iterate with read rather than an indexed loop: bash arrays are 0-indexed
	# and zsh arrays are 1-indexed, and '${#versions}' means element count in
	# zsh but string length of the first element in bash. The csv is built in
	# ascending order, so 'sort -r' restores the descending display order.
	local version has_versions='false'
	while IFS= read -r version; do
		if [[ -n "$version" ]]; then
			has_versions='true'
			if [[ "$version" == "$CURRENT" ]]; then
				__sdkman_echo_no_colour " > ${version}"
			else
				__sdkman_echo_no_colour " * ${version}"
			fi
		fi
	done <<< "$(echo "$versions_csv" | tr ',' '\n' | sort -r)"

	if [[ "$has_versions" == 'false' ]]; then
		__sdkman_echo_yellow "   None installed!"
	fi

	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
	__sdkman_echo_no_colour "* - installed                                                                   "
	__sdkman_echo_no_colour "> - currently in use                                                            "
	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
}

function __sdkman_build_version_csv() {
	local candidate versions_csv

	candidate="$1"
	versions_csv=""

	if [[ -d "${SDKMAN_CANDIDATES_DIR}/${candidate}" ]]; then
		for version in $(find "${SDKMAN_CANDIDATES_DIR}/${candidate}" -maxdepth 1 -mindepth 1 \( -type l -o -type d \) -exec basename '{}' \; | sort -r); do
			if [[ "$version" != 'current' ]]; then
				versions_csv="${version},${versions_csv}"
			fi
		done
		versions_csv=${versions_csv%?}
	fi
	echo "$versions_csv"
}


