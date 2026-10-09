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

#
# Offline mode: drive everything off the candidates folder, never the API.
#
# Enabled by setting 'offline_mode=true' in ${SDKMAN_DIR}/etc/config. Candidate
# versions are expected to be unpacked by hand into
# ${SDKMAN_CANDIDATES_DIR}/<candidate>/<version>, after which 'sdk install'
# behaves as "make this version current" and 'sdk list' reports what is on disk.
#

function __sdkman_offline_mode_enabled() {
	[[ "$offline_mode" == "true" ]]
}

# A candidate is anything with a folder under candidates/, so that versions
# dropped on disk are usable without a candidates cache refresh.
function __sdkman_offline_candidate_known() {
	local candidate="$1"
	__sdkman_offline_mode_enabled && [[ -d "${SDKMAN_CANDIDATES_DIR}/${candidate}" ]]
}

function __sdkman_offline_current_version() {
	local candidate current_link
	candidate="$1"
	current_link="${SDKMAN_CANDIDATES_DIR}/${candidate}/current"

	if [[ -L "$current_link" ]]; then
		readlink "$current_link" | sed "s!${SDKMAN_CANDIDATES_DIR}/${candidate}/!!g"
	fi
}

function __sdkman_offline_install() {
	local candidate version folder version_dir
	candidate="$1"
	version="$2"
	folder="$3"
	version_dir="${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}"

	__sdkman_check_version_present "$version" || return 1

	# Nothing on disk under candidates/<candidate>/<version>: fall back to
	# linking an external folder, when one was supplied.
	if [[ ! -d "$version_dir" && ! -L "$version_dir" ]]; then
		if [[ -n "$folder" ]]; then
			__sdkman_install_local_version "$candidate" "$version" "$folder" || return 1
		else
			__sdkman_offline_version_not_found "$candidate" "$version"
			return 1
		fi
	fi

	__sdkman_offline_set_current "$candidate" "$version"
}

function __sdkman_offline_set_current() {
	local candidate version current_version
	candidate="$1"
	version="$2"
	current_version="$(__sdkman_offline_current_version "$candidate")"

	echo ""
	if [[ "$current_version" == "$version" ]]; then
		__sdkman_echo_yellow "${candidate} ${version} is already the current version."
	else
		__sdkman_echo_green "Setting ${candidate} ${version} as default."
		__sdkman_link_candidate_version "$candidate" "$version"
	fi

	__sdkman_set_candidate_home "$candidate" "$version"
	__sdkman_add_to_path "$candidate"
	export PATH
	echo ""
}

function __sdkman_offline_version_not_found() {
	local candidate version
	candidate="$1"
	version="$2"

	echo ""
	__sdkman_echo_red "Stop! ${candidate} ${version} is not present in ${SDKMAN_CANDIDATES_DIR}/${candidate}."
	echo ""
	__sdkman_echo_yellow "Tip: unpack it there first, then run this command again:"
	echo ""
	__sdkman_echo_yellow "  \$ sdk install ${candidate} ${version}"
	echo ""
	__sdkman_echo_yellow "Tip: see what is already on disk:"
	echo ""
	__sdkman_echo_yellow "  \$ sdk list ${candidate}"
}

function __sdkman_offline_list_candidates() {
	local candidates_dir candidate current_version installed_count found line

	candidates_dir="$SDKMAN_CANDIDATES_DIR"
	found='false'

	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
	__sdkman_echo_yellow "Offline: only showing candidates found in ${candidates_dir}"
	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
	__sdkman_echo_no_colour "$(printf ' %-24s %-24s %s' 'Candidate' 'Current' 'Installed')"
	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"

	if [[ -d "$candidates_dir" ]]; then
		for candidate in $(find "$candidates_dir" -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; | sort); do
			found='true'
			current_version="$(__sdkman_offline_current_version "$candidate")"
			installed_count="$(__sdkman_offline_installed_count "$candidate")"
			line="$(printf ' %-24s %-24s %s' "$candidate" "${current_version:-none}" "$installed_count")"
			__sdkman_echo_no_colour "$line"
		done
	fi

	if [[ "$found" == 'false' ]]; then
		__sdkman_echo_yellow "   None installed!"
	fi

	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
	__sdkman_echo_no_colour "Use: sdk list <candidate> to see installed versions                             "
	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
}

function __sdkman_offline_installed_count() {
	local candidate versions_csv
	candidate="$1"
	versions_csv="$(__sdkman_build_version_csv "$candidate")"

	if [[ -z "$versions_csv" ]]; then
		echo "0"
	else
		echo "${versions_csv}" | tr ',' '\n' | grep -c .
	fi
}
