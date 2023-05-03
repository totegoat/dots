#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Import base.sh for the base packages list
. $script_dir/../base.sh source

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

# Note: using ls instead of stat for macOS compat (macOS stat no -c option)
echo -n "$pass_file permission is 600 ..... "
if [ "$(ls -l $pass_file &> /dev/null | cut -d' ' -f1)" = "-rw-------" ]; then
    echo "true"
    succeeded=$((succeeded + 1))
else
    echo "false"
    failed=$((failed + 1))
fi

echo "##### Success/Failure: $succeeded / $failed"

exit $failed
