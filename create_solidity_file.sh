#!/bin/bash

# filepath: /workspaces/blockchain-web3-terms/create_solidity_file.sh

# Check if a filename is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

# Add .sol extension if not provided
filename="$1"
if [[ "$filename" != *.sol ]]; then
  filename="$filename.sol"
fi

# Base Solidity template
template='// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NewContract {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}
'

# Create the file and add the template
echo "$template" > "$filename"
echo "Created $filename with a base Solidity template."