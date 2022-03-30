#!/bin/bash

yousure=kdialog --title "RetroDECK" --warningyesno "Doing some changes in the RetroArch configuration may create serious issues, please continue only if you know what you're doing. Are you sure do you want to continue?"
if $yousure then
    retroarch