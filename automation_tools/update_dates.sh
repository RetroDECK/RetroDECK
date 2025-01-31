#!/bin/bash

# Path to the configuration file
CONFIG_FILE="config/retrodeck/reference_lists/features.json"

# Check if file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found"
    exit 1
fi

# Get today's date in the format YYYY-MM-DD
TODAYS_DATE=$(date +%Y-%m-%d)

# Update dates using jq
jq '
def is_leap_year($year): ($year % 4 == 0 and $year % 100 != 0) or ($year % 400 == 0);

def increment_date($date):
  if $date | length == 4 then
    ($date[0:2] | tonumber) as $month |
    ($date[2:4] | tonumber) as $day |
    if $month == 12 and $day == 31 then 
      "0101"
    elif $month == 2 and $day == 28 and is_leap_year(2024) then 
      "0229"
    elif $month == 2 and ($day == 28 or $day == 29) then 
      "0301"
    elif $day == 30 and ($month == 4 or $month == 6 or $month == 9 or $month == 11) then
      (if ($month + 1) < 10 then "0" else "" end + (($month + 1) | tostring)) + "01"
    elif $day == 31 then
      (if ($month + 1) < 10 then "0" else "" end + (($month + 1) | tostring)) + "01"
    else
      (if $month < 10 then "0" else "" end + ($month | tostring)) +
      (if ($day + 1) < 10 then "0" else "" end + (($day + 1) | tostring))
    end
  elif $date | length == 10 then
    ($date[0:4] | tonumber) as $year |
    ($date[5:7] | tonumber) as $month |
    ($date[8:10] | tonumber) as $day |
    if $month == 12 and $day == 31 then 
      (($year + 1) | tostring) + "-01-01"
    elif $month == 2 and $day == 28 and is_leap_year($year + 1) then 
      (($year + 1) | tostring) + "-02-29"
    elif $month == 2 and ($day == 28 or $day == 29) then 
      (($year + 1) | tostring) + "-03-01"
    elif $day == 30 and ($month == 4 or $month == 6 or $month == 9 or $month == 11) then
      (($year + 1) | tostring) + "-" + 
      (if ($month + 1) < 10 then "0" else "" end + (($month + 1) | tostring)) + "-01"
    elif $day == 31 then
      (($year + 1) | tostring) + "-" + 
      (if ($month + 1) < 10 then "0" else "" end + (($month + 1) | tostring)) + "-01"
    else
      (($year + 1) | tostring) + "-" +
      (if $month < 10 then "0" else "" end + ($month | tostring)) + "-" +
      (if ($day + 1) < 10 then "0" else "" end + (($day + 1) | tostring))
    end
  else . 
  end;

.splash_screens |= with_entries(
  .value |= (
    if has("start_date") then
      if .start_date < "'$TODAYS_DATE'" then 
        .start_date = increment_date(.start_date) 
      else . end
    else . end |
    if has("end_date") then
      if .end_date < "'$TODAYS_DATE'" then 
        .end_date = increment_date(.end_date) 
      else . end
    else . end |
    if has("full_start_date") then
      if .full_start_date < "'$TODAYS_DATE'" then 
        .full_start_date = increment_date(.full_start_date) 
      else . end 
    else . end |
    if has("full_end_date") then
      if .full_end_date < "'$TODAYS_DATE'" then 
        .full_end_date = increment_date(.full_end_date) 
      else . end
    else . end
  )
)' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

echo "All applicable dates rolled forward by one day."
