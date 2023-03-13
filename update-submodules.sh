#!/bin/bash

git submodule foreach --recursive git checkout master
git submodule foreach --recursive git pull origin master

git submodule foreach --recursive git checkout main
git submodule foreach --recursive git pull origin main