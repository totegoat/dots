#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Import base.sh for the base packages list
. $script_dir/../dots source

failed=0
succeeded=0

echo -n "$pass_file ..... "
if [ -f $pass_file ]; then
    echo "exists"
    succeeded=$((succeeded + 1))
else
    echo "not found"
    failed=$((failed + 1))
fi

# using ls instead of stat for macOS compat (no -c option in macOS stat)
echo -n "$pass_file permission is 600 ..... "
if [ "$(ls -l $pass_file 2>/dev/null | cut -d' ' -f1)" = "-rw-------" ]; then
    echo "true"
    succeeded=$((succeeded + 1))
else
    echo "false"
    failed=$((failed + 1))
fi

echo "##### Success/Failure: $succeeded / $failed"

exit $failed
