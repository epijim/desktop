# #!/bin/bash
#
# Copyright (c) 2015 Baptiste DE RENZO
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
#                                                      CONFIGURATION VARIABLES
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

# colors initialization
cyan='\033[0;36m'   ; pink='\033[0;35m'  ; blue='\033[0;34m'
yellow='\033[0;33m' ; green='\033[0;32m' ; red='\033[0;31m'
white='\033[0;37m'  ; grey='\033[1;30m'  ; black='\033[0;30m'

# Column size
c1=15 # title
c2=20 # bar size [preferably even number]
c3=6  # bar info
c4=15 # complement

# information to display
# available widget : information, weather, itunes, network, cpu_memory, battery, disks, stocks
widgets=('information' 'weather' 'itunes' 'network' 'cpu_memory' 'battery' 'disks' 'stocks' )
refresh=('1'           '1'       '1'      '1'        '1'         '1'       '1'     '1'      )
#refresh=('1'          '900'     '3'      '15'       '5'         '60'      '60'    '60'     ) # TODO : fix refresh rate 

# Color options
default_color=$white
bar_begin=''
bar_empty_char='•'
bar_full_char='•'
bar_end=''
bar_empty_color=$black
bar_full_color=$white

# Stock options
#stocks=('AAPL' 'GOOG' 'MSFT' 'CSCO' 'ORCL' 'AMD' 'YAHOY' 'FB' 'TWTR')
stocks=('AAPL' 'AMD' 'GOOG')
stock_begin=''
stock_negative_empty_char='•'
stock_negative_full_char='•'
stock_positive_full_char='•'
stock_positive_empty_char='•'
stock_end=''
stock_negative_color=$red
stock_positive_color=$green

# Weather options
unit='metric'  # metric|imperial

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

BEGIN_TIMESTAMP=$(ruby -e 'puts "%.3f" % Time.now')

function _repeat () { for ((i=0; i<$2; ++i)); do echo -n "$1"; done;}
function _p (){ (( ${#2} > $1 )) && echo -n "${2:0:$1}. " || { echo -n "${2:0:$1}  "; _repeat " " $(($1-${#2})); } }

# Print progression bar
function _bar(){
        BAR_WIDTH=$1
        FULL=$(echo $2 | cut -d'.' -f1)
        BAR_COMP=("$bar_begin" "$bar_empty_char" "$bar_full_char" "$bar_end")
        BAR_COLOR=("$bar_full_color" "$bar_empty_color")
        BRACKET_CHARS_WIDTH=$(( ${#BAR_COMP[0]} + ${#BAR_COMP[3]} ))

        FULL_WIDTH=$(((($BAR_WIDTH - $BRACKET_CHARS_WIDTH) * $FULL) / 100))
        EMPTY_WIDTH=$((($BAR_WIDTH - $BRACKET_CHARS_WIDTH) - $FULL_WIDTH))

        BAR_FULL="${BAR_COLOR[0]}$(_repeat  "${BAR_COMP[1]}" $FULL_WIDTH)"
        BAR_EMPTY="${BAR_COLOR[1]}$(_repeat "${BAR_COMP[2]}" $EMPTY_WIDTH)$default_color"
        BAR="${BAR_COMP[0]}${BAR_FULL}${BAR_EMPTY}${BAR_COMP[3]}"

        echo -ne "${BAR}   "
}

# Print stock bar
function _stock_bar(){
        BAR_WIDTH=$1
        MAX=$2
        WAY=${3:0:1}
        FULL=$(echo "${3:1}*(100/$MAX)" | bc -l | cut -d'.' -f1)
        BAR_COMP=("$stock_begin" "$stock_negative_empty_char" "$stock_negative_full_char" "$stock_positive_full_char" "$stock_positive_empty_char" "$stock_end")
        BAR_COLOR=("$bar_empty_color" "$stock_negative_color" "$stock_positive_color")
        BRACKET_CHARS_WIDTH=$(( ${#BAR_COMP[0]} + ${#BAR_COMP[5]} ))
        (( $FULL > 100 )) && FULL=100

        # TODO : Fix even width
        if [[ $WAY = "+" ]]; then
                LEFT_EMPTY=$(( $BAR_WIDTH / 2  ))
                LEFT_FULL=0
                RIGHT_FULL=$(((($BAR_WIDTH - $BRACKET_CHARS_WIDTH) * $FULL) / 200))
                RIGHT_EMPTY=$(( $LEFT_EMPTY - $RIGHT_FULL ))
        else
                RIGHT_EMPTY=$(( $BAR_WIDTH / 2  ))
                RIGHT_FULL=0
                LEFT_FULL=$(((($BAR_WIDTH - $BRACKET_CHARS_WIDTH) * $FULL) / 200))
                LEFT_EMPTY=$(( $RIGHT_EMPTY - $LEFT_FULL ))
        fi
        BAR_LEFT_EMPTY="${BAR_COLOR[0]}$(_repeat "${BAR_COMP[1]}" $LEFT_EMPTY)"
        BAR_LEFT_FULL="${BAR_COLOR[1]}$(_repeat  "${BAR_COMP[2]}" $LEFT_FULL)"
        BAR_RIGHT_FULL="${BAR_COLOR[2]}$(_repeat  "${BAR_COMP[3]}" $RIGHT_FULL)"
        BAR_RIGHT_EMPTY="${BAR_COLOR[0]}$(_repeat "${BAR_COMP[4]}" $RIGHT_EMPTY)$default_color"

        BAR="${BAR_COMP[0]}${BAR_LEFT_EMPTY}${BAR_LEFT_FULL}${BAR_RIGHT_FULL}${BAR_RIGHT_EMPTY}${BAR_COMP[5]}"
        echo -ne "${BAR}   "
}

#
# SOFTWARE & HARDWARE
#
function _set_information(){
	system_profiler SPSoftwareDataType > /tmp/geektool/software
	system_profiler SPHardwareDataType > /tmp/geektool/hardware
	OWNER=$(grep 'User Name:' /tmp/geektool/software | sed -e 's,.*: ,,' -e 's,(.*)$,,')
	OS=$(grep 'System Version:' /tmp/geektool/software | sed 's,.*: ,,')
	SERIAL=$(grep 'Serial Number (system):' /tmp/geektool/hardware | sed 's,.*: ,,')

	echo
	_p $c1 "Owner"     && _p $(($c1+$c2)) "$OWNER"  && echo
	_p $c1 "OS"        && _p $(($c1+$c2)) "$OS"     && echo
	_p $c1 "Serial n°" && _p $(($c1+$c2)) "$SERIAL" && echo
}

#
#   CPU & MEMORY
#
function _set_cpu_memory(){
	# CPU
	top -l1 | head -n15 > /tmp/geektool/top
	CPU=$((100 - $(grep -oE '[0-9]+.[0-9]+% idle' /tmp/geektool/top | cut -d'.' -f1)))
	PROCESSES=$(grep -oE 'Processes: [0-9]+' /tmp/geektool/top | grep -oE '[0-9]+')
	# TODO : verify CPU LOAD (always > 1)
	CPU_LOAD5=$(echo $(grep 'Load Avg:' /tmp/geektool/top | cut -d',' -f2 | sed 's, ,,g')-1 | bc -l | sed 's,^\.,0.,')
	CPU_LOAD5_1=$(echo $CPU_LOAD5*100 | bc -l | cut -d'.' -f1)
	if (( $CPU_LOAD5_1 < 0 )); then
		CPU_LOAD5=$(grep 'Load Avg:' /tmp/geektool/top | cut -d',' -f2 | sed 's, ,,g')
		CPU_LOAD5_1=0
	elif (( $CPU_LOAD5_1 > 100 )); then
		CPU_LOAD5_1=100
	fi

	# Memory
	MEMORY_ALL=$(grep 'PhysMem:' /tmp/geektool/top | sed -e 's,G,000000000,g' -e 's,M,000000,g' -e 's,K,000,g')
	MEMORY_USED=$(echo $MEMORY_ALL | grep -oE '[0-9]+ used'   | grep -oE '[0-9]+')
	MEMORY_FREE=$(echo $MEMORY_ALL | grep -oE '[0-9]+ unused' | grep -oE '[0-9]+')
	MEMORY_TOTAL=$(( $MEMORY_USED + $MEMORY_FREE ))
	MEMORY=$(( $MEMORY_USED * 100 / $MEMORY_TOTAL ))
	MEMORY_MAXSIZE=$(grep 'Memory:' /tmp/geektool/hardware | sed -e 's,.*: ,,' -e 's,B$,o,g')

	echo
	_p $c1 "CPU Usage"      && _bar $c2 "$CPU"            && _p $c3 "$CPU%"            && _p $c4 "$PROCESSES ps."         &&  echo
	#_p $c1 "CPU Load"      && _bar $c2 "$CPU_LOAD5_1"    && _p $c3 "$CPU_LOAD5"       && echo 
	_p $c1 "Memory Usage"   && _bar $c2 "$MEMORY"         && _p $c3 "$MEMORY%"         && echo
}

#
#   BATTERY
#
function _set_battery(){
        function convert_secs() {
                local h=$(expr $1 / 3600)
                local m=$(expr $1 % 3600 / 60)
                local s=$(expr $1 % 60)
                local duration=""
                [[ $h != 0 ]] && duration="${duration}${h} h "
                [[ $m != 0 ]] && duration="${duration}${m} min"
                [[ $s != 0 ]] && duration="${duration}${s} s "
                [[ -n $2 ]] && echo $duration | cut -d' ' -f$(seq 1 $((2*$2)) | tr '\n' ',' | sed 's/,$//') || echo $duration
        }
        ioreg -w0 -l > /tmp/geektool/ioreg
        AC=$(grep ExternalConnected /tmp/geektool/ioreg | awk '{print $5}')
        if [[ $AC == "Yes" ]]; then
                POWER="Charging"
        else
                POWER="Discharging"
                BATTERY_TIME_LEFT_MIN=$(grep 'TimeRemaining' /tmp/geektool/ioreg | awk '{print $5}')
                BATTERY_TIME_LEFT_SEC=$(( $BATTERY_TIME_LEFT_MIN * 60 ))
                POWER=$(convert_secs $BATTERY_TIME_LEFT_SEC 2)
        fi
        CUR_CAPACITY=$(grep CurrentCapacity   /tmp/geektool/ioreg | awk '{print $5}')
        MAXIMUM_CAPACITY=$(grep MaxCapacity   /tmp/geektool/ioreg | awk '{print $5}')
        DESIGN_CAPACITY=$(grep DesignCapacity /tmp/geektool/ioreg | awk '{print $5}')
        BATTERY=$(( CUR_CAPACITY * 100 / $MAXIMUM_CAPACITY ))
        BATTERY_HEALTH=$(( $MAXIMUM_CAPACITY * 100 / $DESIGN_CAPACITY ))
        (( $BATTERY_HEALTH > 100 )) && BATTERY_HEALTH=100
        BATTERY_CYCLES=$(grep -oE '"Cycle Count"=[0-9]+' /tmp/geektool/ioreg | grep -oE '[0-9]+')

        echo
		_p $c1 "Battery"        && _bar $c2 "$BATTERY"        && _p $c3 "$BATTERY%"        && _p $c4 "$POWER"                 && echo
		_p $c1 "Battery Health" && _bar $c2 "$BATTERY_HEALTH" && _p $c3 "$BATTERY_HEALTH%" && _p $c4 "$BATTERY_CYCLES Cycles" && echo

}

#
#   DISKS
#
function _set_disks(){
	echo 
	df -h | sed 1d | grep -vE '^map|^devfs' > /tmp/geektool/disk
	[[ ! -f /tmp/geektool/software ]] && system_profiler SPSoftwareDataType > /tmp/geektool/software
	BOOT_VOLUME=$(grep 'Boot Volume:' /tmp/geektool/software | sed 's,.*: ,,')
	while read LINE; do

        	NAME=$(echo "$LINE" | awk '{print $9}' | sed -e "s,^\/$,$BOOT_VOLUME,g" -e 's,/Volumes/,,' )
        	SIZE=$(echo "$LINE" | awk '{print $2}' | sed -e 's,\([0-9]\)\([A-Za-z]\),\1 \2,' -e 's,i$,o,')
    	    USED=$(echo "$LINE" | awk '{print $5}' | sed 's,%,,')
		    _p $c1 "$NAME"        && _bar $c2 "$USED"        && _p $c3 "$USED%"        && _p $c4 "$SIZE"                 && echo

	done < /tmp/geektool/disk
}

#
#   ITUNES
#
function _set_itunes(){
	function ask_itunes(){
   	     echo $(osascript << EOT
   	     tell application "iTunes"
   	             return $1
   	     end tell
		EOT)
	}
	if [[ -n $ITUNES_SONG ]]; then
		ITUNES_SONG=$(ask_itunes "name of current track" | sed 's,(.*,,')
		ITUNES_ARTIST=$(ask_itunes "artist of current track")
		ITUNES_ALBUM=$(ask_itunes "album of current track")
		ITUNES_TRACK_DURATION=$(ask_itunes "duration of current track")
		ITUNES_TRACK_POSITION=$(ask_itunes "player position")
		ITUNES_RATING=$(($(ask_itunes "rating of current track")/20))
		ITUNES_STARS=$(_repeat "✭" $ITUNES_RATING )
		TRACK_PROGRESS=$(echo "$ITUNES_TRACK_POSITION*100/$ITUNES_TRACK_DURATION" | bc -l | cut -d'.' -f1)
		echo	 # ► ■
		_p $(($c1+$c2+$c3)) "$ITUNES_ARTIST"  && echo
		_p $c1 "$ITUNES_SONG"    && _bar $c2 "$TRACK_PROGRESS"  && _p $c3 "$TRACK_PROGRESS%"   && _p $c4 "$ITUNES_STARS" && echo
	fi
}

#
#   NETWORK
#
function _set_network(){
	airport_bin="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
	$airport_bin -I > /tmp/geektool/airport
	WIFI_SSID=$(grep ' SSID' /tmp/geektool/airport | sed -E 's,.*: ?,,')
	WIFI_SECURITY=$(grep -E '(Security|link auth)' /tmp/geektool/airport |  sed -E 's,.*: ?,,' | tr 'a-z' 'A-Z')
	WIFI_SIGNAL=$(grep -E '(avgSignalLevel|agrCtlRSSI)' /tmp/geektool/airport | grep -oE '\-[0-9]+')
	WIFI_NOISE=$(grep -E '(avgNoiseLevel|agrCtlNoise)' /tmp/geektool/airport | grep -oE '\-[0-9]+')
	WIFI_STRENGTH="$(($WIFI_SIGNAL - $WIFI_NOISE))"
	WIFI_PERCENT=$(( $WIFI_STRENGTH * 2 ))
	(( $WIFI_PERCENT > 100 )) && WIFI_PERCENT=100

	PRIVATE_IP_ADDRESS=$(ifconfig | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -vE '(1|0|255)$')
	PUBLIC_IP_ADDRESS=$(curl -s ip.appspot.com)

	echo
	_p $c1 "Internal IP"       && _p   $c2 "$PRIVATE_IP_ADDRESS"  && echo
	_p $c1 "External IP"       && _p   $c2 "$PUBLIC_IP_ADDRESS"   && echo
	_p $c1 "$WIFI_SSID"        && _bar $c2 "$WIFI_PERCENT"        && _p $c3 "${WIFI_STRENGTH}dB"        && _p $c4 "$WIFI_SECURITY"                 && echo
}

#
#   WEATHER
# 
#function _set_weather(){
	# Set temperature symbol
	[[ $unit = 'metric' ]] && WEATHER_SYMBOLE='C' || WEATHER_SYMBOLE='F'

	# Get location
	curl -s http://ipinfo.io/json > /tmp/geektool/location
	CITY=$(grep 'city' /tmp/geektool/location | cut -d'"' -f4)
	COUNTRY=$(grep 'country' /tmp/geektool/location | cut -d'"' -f4)
	
	# Get weather
	curl -s "http://api.openweathermap.org/data/2.5/weather?q=${CITY},${COUNTRY}&units=${unit}" > /tmp/geektool/weather
	TEMPERATURE=$(grep -oE '"temp":-?[0-9]+.[0-9]+' /tmp/geektool/weather | cut -d':' -f2 | cut -d'.' -f1)
	[[ $TEMPERATURE = "-0" ]] && TEMPERATURE="0"
	PRESSURE=$(grep -oE '"pressure":-?[0-9]+.[0-9]+' /tmp/geektool/weather | cut -d':' -f2 )

	echo
	_p $c1 "Location"  && _p $(($c1+$c2)) "$CITY (${TEMPERATURE}°${WEATHER_SYMBOLE})" && echo
}

#
#   STOCKS
#
function _set_stocks(){
	echo
	for STOCK in ${stocks[@]}; do
		while IFS=',' read -r PRICE CHANGE PERCENT; do
			PERCENT=$(echo $PERCENT | cut -d '"' -f 2 | tr -d '%')
			# TODO : Fix typo
			_p $(($c1/2-3)) "$STOCK" && _p $(($c1-$c1/2+1)) "» $PRICE$"  && _stock_bar $c2 6 "$PERCENT" && _p $c3 "$PERCENT%" && echo
		done <<< $(curl -Ls "http://finance.yahoo.com/d/quotes.csv?s=$STOCK&f=l1c1p2")
	done
}

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

# get timestamp
date=$(date +%s)

#Clean up 
trap 'rm -f /tmp/geektool/{disk,top,vm_stat,software,hardware,ioreg}' EXIT

# create initial file
if [[ ! -f /tmp/geektool/last_refresh ]]; then
	mkdir /tmp/geektool &> /dev/null
        for i in ${!widgets[*]}; do
                echo "last_refresh[$i]=$date" >> /tmp/geektool/last_refresh
        done
fi
# Load last refresh time
. /tmp/geektool/last_refresh

echo -ne "$default_color"
date +"%Y/%m/%d %H:%M:%S"

for i in ${!widgets[*]}; do
        widget="${widgets[$i]}"
        widget_refresh_rate="${refresh[$i]}"
        widget_last_refresh="${last_refresh[$i]}"
        widget_next_refresh=$(( $widget_last_refresh + $widget_refresh_rate ))
        if (( $date >= $widget_next_refresh )); then
                # refresh last_refresh param
                sed -i '' "s,.*\[$i\].*,last_refresh[$i]=$date," /tmp/geektool/last_refresh
                case $widget in
                        information) _set_information  ;;
                        itunes)      _set_itunes       ;;
                        cpu_memory)  _set_cpu_memory   ;;
                        battery)     _set_battery      ;;
                        disks)       _set_disks        ;;
                        stocks)      _set_stocks       ;;
                        weather)     _set_weather      ;;
                        network)     _set_network      ;;
                esac
        fi
done

END_TIMESTAMP=$(ruby -e 'puts "%.3f" % Time.now')
ELASPED_TIME=$(echo "$END_TIMESTAMP - $BEGIN_TIMESTAMP" | bc -l | sed 's,^\.,0.,')
echo && echo "generated in ${ELASPED_TIME}s"
