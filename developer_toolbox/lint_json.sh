#!/bin/bash

json=$1

jq . $json > $json.tmp && mv -f $json.tmp $json