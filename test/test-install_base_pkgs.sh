#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Import base.sh for the base packages list
. $script_dir/../base.sh source

failed=0
succeeded=0

for package in $base_packages; do
    echo -n "$package ..... "
    if command -v $package &> /dev/null; then 
        echo "installed"
        succeeded=$((succeeded + 1))
    else
        echo "not found"
        failed=$((failed + 1))
    fi
done

echo "##### Success/Failure: $succeeded / $failed"

exit $failed
