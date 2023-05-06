#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Import base.sh for the base packages list
. $script_dir/../dots source

failed=0
succeeded=0

discover_distro

echo -n "Is this distro supported? ..... "
if [[ ! "$distro" = "unknown" ]]; then
    echo "yes ($distro)"
    succeeded=$((succeeded + 1))
else
    echo "no ($distro)"
    failed=$((failed + 1))
fi

echo "##### Success/Failure: $succeeded / $failed"

exit $failed
