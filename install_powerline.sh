#!/bin/bash

TMPDIR=/tmp
GET_PIP="${TMPDIR}/get-pip.py"
OPTIONS=("--user" "--upgrade")
PROVISIONAL="/tmp/provisional"

PYTHON_BINS="${HOME}/Library/Python/2.7/bin"
PATH="${PYTHON_BINS}:$PATH"

SITE_PACKAGES="${HOME}/Library/Python/2.7/lib/python/site-packages"
set -e

function rewrite {
	local FILE="$1"
	local TAG="${2}"
	shift 2

	rm -f "${PROVISIONAL}"
	while [ "$#" -gt 0 ]; do
		echo "$1 ${TAG}" >> "$PROVISIONAL"
		shift
	done
	(grep -v "$TAG" "$FILE" || true) >> "$PROVISIONAL"
	mv "${PROVISIONAL}" "${FILE}"
}

ADJUST_PATH_COMMAND='export PATH="'"${PYTHON_BINS}":'${PATH}"'
rewrite ~/.bash_profile "# POWERLINE_AUTO" "${ADJUST_PATH_COMMAND}" "powerline-daemon -q" "POWERLINE_BASH_CONTINUATION=1" "POWERLINE_BASH_SELECT=1" "${SITE_PACKAGES}/powerline/bindings/bash/powerline.sh"
rewrite ~/.vimrc 'POWERLINE_AUTO' \
	'python from powerline.vim import setup as powerline_setup #' \
	'python powerline_setup() #' \
	'python del powerline_setup #' \
	':set laststatus=2 "'

cd "${TMPDIR}"
curl https://bootstrap.pypa.io/get-pip.py -o "${GET_PIP}"
python "${GET_PIP}" "${OPTIONS[@]}"

pip install "${OPTIONS[@]}" powerline-status 

