#!/bin/bash

NODE_ID=$1

if [ -z "$NODE_ID" ]; then
  echo "Error: Node ID not provided."
  echo "Usage: $0 <node-id>"
  exit 1
fi

echo "Updating Nomad node with ID: $NODE_ID"

nomad node drain -enable $NODE_ID

# wait for the node to be drained
echo "Waiting for node to be drained..."
sleep 10

# Check if the node is ineligible
if nomad node status | grep "$NODE_ID" | grep -q "ineligible"; then
  echo "Node $NODE_ID is ineligible."
else
  echo "Node $NODE_ID is not ineligible or not found."
fi

sudo apt update && sudo apt upgrade -y

# Check if the node is still ineligible
if nomad node status | grep "$NODE_ID" | grep -q "ineligible"; then
    echo "Node $NODE_ID is still ineligible after update."
else
    echo "Node $NODE_ID is no longer ineligible after update."
fi

nomad node drain -disable $NODE_ID

# Check if the node is still ineligible
if nomad node status | grep "$NODE_ID" | grep -q "ineligible"; then
    echo "Node $NODE_ID is still ineligible after re-enabling."
else
    echo "Node $NODE_ID is no longer ineligible after re-enabling."
fi

# end of file
