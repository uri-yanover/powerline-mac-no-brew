#!/bin/bash

# Fix up ctypes so that macvim can import powerline (or anything else reliant on ctypes)

TMPDIR=/tmp
GET_PIP="${TMPDIR}/get-pip.py"
OPTIONS=("--user" "--upgrade")
PROVISIONAL="/tmp/provisional"

PYTHON_BINS="${HOME}/Library/Python/2.7/bin"
PATH="${PYTHON_BINS}:$PATH"

SITE_PACKAGES="${HOME}/Library/Python/2.7/lib/python/site-packages"
POWERLINE_CONFIG="${SITE_PACKAGES}/powerline/config_files/config.json"

MAC_VIM_CTYPES_FIX="mac_vim_ctypes_fix"
MAC_VIM_CTYPES_INIT="${HOME}/Library/Python/2.7/lib/python/site-packages/${MAC_VIM_CTYPES_FIX}/__init__.py"

function alter {
        python -c 'from json import load, dump
from sys import argv

with open(argv[1], "rb") as file_obj:
    data = load(file_obj)

pointer = data

split = argv[2].split(".")
for path_element in split[:-1]:
    pointer = pointer.get(path_element)
pointer[split[-1]] = argv[3]

with open(argv[1], "wb") as file_obj:
    dump(data, file_obj, indent=4)

' $@
}

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

if [ "$#" -gt 1 ]; then
    COMMAND="will never be valid"
else
    COMMAND="$1"
fi

case "${COMMAND}" in
     install)
         # fallthrough
         ;;

     uninstall)
        rewrite ~/.bash_profile '# POWERLINE_AUTO'
        rewrite ~/.vimrc 'POWERLINE_AUTO'
        exit 0
        ;;

    *)
        echo "Usage: $0 [install|uninstall]"
        exit 1
        ;;
esac

rewrite ~/.bash_profile "# POWERLINE_AUTO" \
        'if ! type powerline > /dev/null 2>&1; then export PATH="'${PYTHON_BINS}':${PATH}"; fi' \
        'if [ -z "${LC_ALL+set}" ]; then _LC_ALL_POWERLINE=clean; export LC_ALL="en_US.utf8"; fi' \
        'powerline-daemon -q' \
        "POWERLINE_BASH_CONTINUATION=1" \
        "POWERLINE_BASH_SELECT=1" \
        "${ADJUST_PATH} . ${SITE_PACKAGES}/powerline/bindings/bash/powerline.sh" \
        'if [ -n "${_LC_ALL_POWERLINE}" ]; then unset _LC_ALL_POWERLINE; unset LC_ALL; fi'

rewrite ~/.vimrc 'POWERLINE_AUTO' \
        "python import ${MAC_VIM_CTYPES_FIX} #" \
        'python from powerline.vim import setup as powerline_setup #' \
        'python powerline_setup() #' \
        'python del powerline_setup #' \
        ':set laststatus=2 "' \
        ':syntax on "'
 
cd "${TMPDIR}"
curl https://bootstrap.pypa.io/get-pip.py -o "${GET_PIP}"
python2 "${GET_PIP}" "${OPTIONS[@]}"

python2 -m pip install "${OPTIONS[@]}" powerline-status 
alter "${POWERLINE_CONFIG}" "ext.shell.theme" "default_leftonly"


rm -rf "$(dirname "${MAC_VIM_CTYPES_INIT}")"
mkdir -p "$(dirname "${MAC_VIM_CTYPES_INIT}")"
cat > "${MAC_VIM_CTYPES_INIT}" <<'----end----'
import sys
from os.path import dirname, join, exists, isfile, relpath
from os import listdir, makedirs, walk
from shutil import rmtree, copy

if sys.version_info[0] == 2 and sys.platform == 'darwin':
    SOURCE = "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/ctypes"
    OVERRIDES=join(dirname(__file__), 'overrides')
    DEST=join(OVERRIDES, 'ctypes')
    INIT_FILE = join(DEST, '__init__.py')
    
    if exists(OVERRIDES):
        rmtree(OVERRIDES)
    
    for (dirpath, dirnames, file_names) in walk(SOURCE):
        destpath = join(DEST, relpath(dirpath, SOURCE))
    
        if not exists(destpath):
            makedirs(destpath)
        for file_name in file_names:
            copy(join(dirpath, file_name), join(destpath, file_name))
    
    with open(INIT_FILE, 'rt') as file_object:
        lines = list(file_object)
    
    with open(INIT_FILE, 'wb') as file_object:
        file_object.write('\n'.join(line.rstrip() for line in lines 
                          if 'CFUNCTYPE(c_int)(lambda' not in line))
    
    from sys import path
    path.insert(0, OVERRIDES)
----end----


