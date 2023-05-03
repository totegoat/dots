#!/usr/bin/env bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

failed=0

for testfile in "$script_dir"/test-*.sh; do
    tf=$(basename $testfile)
    echo
    echo "##### $tf #####"
    if ! $script_dir/$tf; then 
        failed=$((failed + 1))
        echo "##### $tf ######################################## FAIL"
    else
        echo "##### $tf ######################################## PASS"
    fi
done

exit $failed
