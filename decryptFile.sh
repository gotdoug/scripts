#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "What file(s) do you want to decrypt?"
else
	for f in "$@"
	do
        openssl enc -d -aes-256-cbc -salt -in ${f} > $(basename ${f} .enc)
		if [[ $? -eq 0 ]]
		then
        	rm -f ${f}
		fi
	done
fi
