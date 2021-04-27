#!/bin/bash

# Check URL argument
if [[ $1 == '' ]]
then
	echo "Missing URL argument"
	echo "Example command: bash xss.sh http://google.com/?query=1"
	exit 1
fi

# Parse query strings from URL
queryStrings=$(echo $1 | awk -F'?' '{ print $2 }')
queryLength=$(echo $queryStrings | grep "&" -o | wc -l)
queryLength=$((queryLength+1))

# Tests for XSS exploit
function exploit {
	# Craft payload URL
	name=$(echo "$2" | awk -F'=' '{ print $1 }')
	value="PAYLOAD_START\"\'/>a<\\-PAYLOAD_END"
	url=$(echo "$1" | sed "s|$2|$name=$value|gi" | sed 's/"/\"/gi')

	# Get response from server
	curl "$url" --silent > output
	response=$(cat output)

	# Handle response
	chance=0
	if [[ "$response" =~ .*"PAYLOAD_START".* ]]
	then

		echo "	[-] String is reflected"
		
		text=$(echo $response | awk -F'PAYLOAD_START' '{ print $2 }')
		text=$(echo $text | awk -F'PAYLOAD_END' '{ print $1 }')

		# Look for characters in response
		if [[ "$text" =~ .*"\"".* ]]; then chance=$((chance+1)); fi
		if [[ "$text" =~ .*"'".* ]]; then chance=$((chance+1)); fi
		if [[ "$text" =~ .*"/".* ]]; then chance=$((chance+1)); fi
		if [[ "$text" =~ .*">".* ]]; then chance=$((chance+1)); fi
		if [[ "$text" =~ .*"a".* ]]; then chance=$((chance+1)); fi
		if [[ "$text" =~ .*"<".* ]]; then chance=$((chance+1)); fi
		if [[ "$text" =~ .*"-".* ]]; then chance=$((chance+1)); fi
	fi

	# Display results
	echo "	[!] Chance of XSS: $chance"
	echo ""

	# Cleanup files
	rm output
}

# Iterate query strings
counter=1
while : ; do
	query=$(echo $queryStrings | awk -F'&' "{ print \$$counter }")
	
	echo "Testing query: $query"
	exploit $1 $query

	counter=$((counter+1))
	[[ $counter -le $queryLength ]] || break
done
