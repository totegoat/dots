#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Import base.sh for the base packages list
. $script_dir/../dots source

failed=0
succeeded=0

for dir in $app_dir $local_copy; do
    echo -n "$dir ..... "
    if [ -d $dir ]; then
        echo "exists"
        succeeded=$((succeeded + 1))
    else
        echo "not found"
        failed=$((failed + 1))
    fi
done

echo "##### Success/Failure: $succeeded / $failed"

exit $failed
