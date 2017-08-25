#!/usr/bin/env bash

path=${1}
cd $(basedir ${path})
while [ -h ${path} ]; do
	
done
