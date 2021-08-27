#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "What file(s) do you want to encrypt?"
else
	for f in "$@"
	do
        openssl enc -aes-256-cbc -salt -in ${f} -out $f.enc
		if [[ $? -eq 0 ]]
		then
        	rm -f ${f}
		fi
	done
fi
