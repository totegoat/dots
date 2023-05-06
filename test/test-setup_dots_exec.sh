#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Import base.sh for the base packages list
. $script_dir/../dots source

failed=0
succeeded=0

# Symlink to dots script is in bin_dir
echo -n "$bin_dir/dots ..... "
if [ -L $bin_dir/dots ]; then
    echo "exists"
    succeeded=$((succeeded + 1))
else
    echo "not found"
    failed=$((failed + 1))
fi

# Make sure bin_dir is in PATH
echo -n "$bin_dir is in PATH ..... "
if which dots &>/dev/null; then
    echo "true"
    succeeded=$((succeeded + 1))
else
    echo "false"
    failed=$((failed + 1))
fi

echo "##### Success/Failure: $succeeded / $failed"

exit $failed
