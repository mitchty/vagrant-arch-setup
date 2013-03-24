#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
#
# Simple script, first arg is the path to the vmware fusion vmwarevm folder, second is the box name.
source="$1"
box="$2"

[[ ${TMPDIR} != '' ]] && temp_dir="${TMPDIR}/$$" || temp_dir="/tmp/$$"
[[ ! -d ${temp_dir} ]] && mkdir -p ${temp_dir}

if [[ -d /Applications/VMware\ Fusion.app/Contents/Library ]]; then
  PATH=${PATH}:/Applications/VMware\ Fusion.app/Contents/Library
else
  echo "Not sure where vmware fusion is installed, exiting."
  exit 1
fi

echo "temp dir is: ${temp_dir}"

function validate_source_dir {
  [[ ! -d ${source} ]] && echo "Input ${source} isn't a directory." && exit 2
  echo ${source} | grep vmwarevm > /dev/null 2>&1
  [[ $? != 0 ]] && echo "Input ${source} doesn't appear to be a vmwarevm directory." && exit 3
}

function validate_input {
  validate_source_dir
  [[ ${box} != '' ]] && echo "Specify a filename for the boxfile to output to."
}

function copy_vmware_files {
  echo "Copying vmware files to ${temp_dir} from ${source}."
  rsync -az "${source}"/*.nvram "${source}"/*.vmsd\
 "${source}"/*.vmx "${source}"/*.vmxf\
 "${source}"/*.vmdk  ${temp_dir}
}

function shrink_copy {
  echo "Defragmenting vmdk's"
  find ${temp_dir} -type f -name "*.vmdk" -print0 | xargs -0 vmware-vdiskmanager -d
  echo "Shrinking vmdk's"
  find ${temp_dir} -type f -name "*.vmdk" -print0 | xargs -0 vmware-vdiskmanager -k
}

function build_box {
  echo "Building boxfile ${box}"
  cd ${temp_dir}
  echo '{"provider":"vmware_fusion"}' > metadata.json
  tar cf - . | gzip -9 -c - > ${box}
}

validate_input
copy_vmware_files
shrink_copy
build_box

echo "Cleaning up after myself."
cd / && rm -fr ${temp_dir}

echo "done"

exit 0
