#!/bin/bash

ALERT_IF_IN_NEXT_MINUTES=10
ALERT_POPUP_BEFORE_SECONDS=30
BUFFER_SECONDS=60
NERD_FONT_MEETING="󰤙"

THM_RED=#e78284
THM_PEACH=#ef9f76
THM_SURFACE_0=#414559

LOCK_FILE="/tmp/tmux_meeting_popup.lock"

get_attendees() {
    attendees=$(
        icalBuddy \
            --includeEventProps "attendees" \
            --propertyOrder "datetime,title" \
            --noCalendarNames \
            --dateFormat "%A" \
            --includeOnlyEventsFromNowOn \
            --limitItems 1 \
            --excludeAllDayEvents \
            --separateByDate \
            --excludeEndDates \
            --bullet "" \
            eventsToday
    )
}

parse_attendees() {
    attendees_array=()
    for line in $attendees; do
        attendees_array+=("$line")
    done
    number_of_attendees=$((${#attendees_array[@]} - 3))
}

get_next_meeting() {
    next_meeting=$(
        icalBuddy \
            --includeEventProps "title,datetime" \
            --propertyOrder "datetime,title" \
            --noCalendarNames \
            --dateFormat "%A" \
            --includeOnlyEventsFromNowOn \
            --limitItems 1 \
            --excludeAllDayEvents \
            --separateByDate \
            --bullet "" \
            eventsToday
    )
}

get_next_next_meeting() {
    end_timestamp=$(date +"%Y-%m-%d ${end_time}:01 %z")
    tonight=$(date +"%Y-%m-%d 23:59:00 %z")
    next_next_meeting=$(
        icalBuddy \
            --includeEventProps "title,datetime" \
            --propertyOrder "datetime,title" \
            --noCalendarNames \
            --dateFormat "%A" \
            --limitItems 1 \
            --excludeAllDayEvents \
            --separateByDate \
            --bullet "" \
            eventsFrom:"${end_timestamp}" to:"${tonight}"
    )
}

parse_result() {
    array=()
    for line in $1; do
        array+=("$line")
    done
    time=$(echo "${array[2]}" | perl -CSD -pe 's/\s/ /g' | xargs)
    end_time="${array[4]}"
    title="${array[*]:5:30}"
}

calculate_times() {
    epoc_meeting=$(date -j -f "%H:%M %p" "$time" +%s)
    epoc_now=$(date +%s)
    epoc_diff=$((epoc_meeting - epoc_now))
    minutes_till_meeting=$((epoc_diff / 60))
}

display_popup() {
    tmux display-popup \
        -S "fg=$THM_RED" \
        -w50% \
        -h50% \
        -d '#{pane_current_path}' \
        -T " Meeting " \
        icalBuddy \
        --propertyOrder "datetime,title" \
        --noCalendarNames \
        --formatOutput \
        --includeEventProps "title,datetime,notes,url,attendees" \
        --includeOnlyEventsFromNowOn \
        --limitItems 1 \
        --excludeAllDayEvents \
        eventsToday
}

print_tmux_status() {
    if [[ $minutes_till_meeting -lt $ALERT_IF_IN_NEXT_MINUTES && $minutes_till_meeting -gt -60 ]]; then
        echo " #[bg=$THM_PEACH,fg=$THM_SURFACE_0]#[reverse]#[noreverse]$NERD_FONT_MEETING" \
            "#[fg=#{@thm_fg},bg=#{@thm_surface_0}] $time $title ($minutes_till_meeting minutes)"
    else
        echo
    fi

    if [[ $epoc_diff -gt $ALERT_POPUP_BEFORE_SECONDS && $epoc_diff -lt $((ALERT_POPUP_BEFORE_SECONDS + BUFFER_SECONDS)) ]]; then
        if [[ ! -f $LOCK_FILE ]]; then
            display_popup
            touch $LOCK_FILE
        fi
    elif [[ $epoc_diff -le 0 ]]; then
        rm -f $LOCK_FILE
    fi
}

main() {
    get_attendees
    parse_attendees
    get_next_meeting
    parse_result "$next_meeting"
    calculate_times
    if [[ "$next_meeting" != "" && $number_of_attendees -lt 2 ]]; then
        get_next_next_meeting
        parse_result "$next_next_meeting"
        calculate_times
    fi
    print_tmux_status
}

main
