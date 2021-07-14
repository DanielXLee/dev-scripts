#!/bin/bash

region=$1
[[ "X$region" == "X" ]] && echo "Miss region, example run: ./play.sh gz" && exit 1
ansible-playbook -i inventory-${region} playbook.yml -v
