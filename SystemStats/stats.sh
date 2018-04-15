#!/bin/bash

graph_hight=15
graph_width=10
#graph_scale="        ⏌ "
graph_scale_number_width=10
graph_scale_unit=3
graph_scale_division=$((graph_hight / graph_scale_unit))
#converted_scale=(0 0 0 0 0 0)
read_graph_scale=(0 0 0 0 0 0)
write_graph_scale=(0 0 0 0 0 0)
cpu_utilization_graph_scale=(0 0 0 0 0 0)
#graph_array=(11 15 0 5 5 8 9 4 10 15)
read_graph_array=(0 0 0 0 0 0 0 0 0 0)
write_graph_array=(0 0 0 0 0 0 0 0 0 0)
cpu_utilization_graph_array=(0 0 0 0 0 0 0 0 0 0)
read_array=(0 0 0 0 0 0 0 0 0 0)
write_array=(0 0 0 0 0 0 0 0 0 0)
cpu_utilization_array=(0 0 0 0 0 0 0 0 0 0)
read_max=0
recent_read_max=0
write_max=0
recent_write_max=0
cpu_utilization_max=0
recent_cpu_utilization_max=0

getScaleNumber() {
	local number=$1
	local number_width=${#number}
	local k=$((graph_scale_number_width - number_width))
	getChar " " $k
	formated_scale_number=$nchar$number
}

update() {
	old_data=$(cat /proc/diskstats | grep '\ssda\s')
	sleep 1
	new_data=$(cat /proc/diskstats | grep '\ssda\s')
	loadavg_data=$(cat /proc/loadavg)
	
	IFS=' ' read -ra old_data_array <<< "$old_data"
	IFS=' ' read -ra new_data_array <<< "$new_data"
	IFS=' ' read -ra loadavg_array <<< "$loadavg_data"
	
	read_speed=$(($((new_data_array[5]-old_data_array[5]))*512))
	write_speed=$(($((new_data_array[9]-old_data_array[9]))*512))
	cpu_utilization=${loadavg_array[0]}
	
	updateRecentDataArray
	
	convert $read_speed
	read_display=$converted$unit	
	convert $write_speed
	write_display=$converted$unit
	cpu_utilization_display=$cpu_utilization
	
	calcGraphScale $read_max $recent_read_max read_graph_scale
	calcGraphScale $write_max $recent_write_max write_graph_scale
	calcGraphScaleForCPU $cpu_utilization_max $recent_cpu_utilization_max
	
	#FOR READ
	
	updateGraphArray
	
	#printf "\033c"
	#printf "Predkosc odczytu: $read_speed \n"
	#printf "Predkosc zapisu: $write_speed \n"
	#printf "Predkosc odczytu: $read_display \n"
	#printf "Predkosc zapisu: $write_display \n"
	#printf "Ostatnie 5 odczytow: %s \n" "${read_array[@]}"
	#printf "Max odczyt: $read_max\n"
	#printf "Slupki: %s \n" "${read_graph_array[@]}"
	#printf "Ostatnie 5 zapisow: %s \n" "${write_array[@]}"
	#printf "Max zapis: $write_max\n"
	#printf "Slopki zap: %s \n" "${write_graph_array[@]}"
	#printf "__________________________________\n"
}


getChar() {
	nchar=""
	char=$1
	quantity=$2
	local i=0
	while [ $i -lt $quantity ]; do
		nchar+="$char"
		((i++))
	done
}

getMax() {
	declare -a ar=("${!1}")
	max=${ar[0]}
	for n in "${ar[@]}" ; do
		#((n > max)) && max=$n
		if (( $( bc <<< "$n > $max") )); then
			max=$n
		fi
	done
echo $max
}
updateRecentDataArray() {
	local i=$((graph_width - 1))
	while [ $i -gt 0 ]; do
		read_array[$i]=${read_array[$((i - 1))]}
		write_array[$i]=${write_array[$((i - 1))]}
		cpu_utilization_array[$i]=${cpu_utilization_array[$((i - 1))]}
		((i--))
	done
	read_array[0]=$read_speed
	write_array[0]=$write_speed
	cpu_utilization_array[0]=$cpu_utilization
	
	read_max=$(getMax read_array[@])
	write_max=$(getMax write_array[@])
	cpu_utilization_max=$(getMax cpu_utilization_array[@])
}
calcHight() {
	local nr=$1
	local max=$2
	#if [ $max -gt 0 ]; then
	if (( $(bc <<< "$max > 0") )); then
		hight=$(bc -l <<< "a=((($nr * $graph_hight)/$max) + 0.5); scale=0; a/1")
	else
		hight=0
	fi
	echo $hight
}	

updateGraphArray() {
	if [ $read_max -eq $recent_read_max ]; then
		if [ $read_max -gt 0 ]; then
			local i=$((graph_width - 1))
			while [ $i -gt 0 ]; do
				read_graph_array[$i]=${read_graph_array[$((i - 1))]}
				((i--))
			done
			read_graph_array[0]=$(calcHight $read_speed $read_max)
		fi
	else
		local j=0
		while [ $j -lt $graph_width ]; do
			read_graph_array[$j]=$(calcHight ${read_array[$j]} $read_max)
			((j++))
		done
	fi
	recent_read_max=$read_max
	
	
	
	if [ $write_max -eq $recent_write_max ]; then
		if [ $write_max -gt 0 ]; then
			local k=$((graph_width - 1))
			while [ $k -gt 0 ]; do
				write_graph_array[$k]=${write_graph_array[$((k - 1))]}
				((k--))
			done
			write_graph_array[0]=$(calcHight $write_speed $write_max)
		fi
	else
		local n=0
		while [ $n -lt $graph_width ]; do
			write_graph_array[$n]=$(calcHight ${write_array[$n]} $write_max)
			((n++))
		done
	fi
	recent_write_max=$write_max
	
	
	#if [ $cpu_utilization_max -eq $recent_cpu_utilization_max ]; then
	if (( $(bc <<< "$cpu_utilization_max == $recent_cpu_utilization_max") )); then
		#if [ $cpu_utilization_max -gt 0 ]; then
		if (( $(bc <<< "$cpu_utilization_max > 0") )); then
			local p=$((graph_width - 1))
			while [ $p -gt 0 ]; do
				cpu_utilization_graph_array[$p]=${cpu_utilization_graph_array[$((p - 1))]}
				((p--))
			done
			cpu_utilization_graph_array[0]=$(calcHight $cpu_utilization $cpu_utilization_max)
		fi
	else
		local q=0
		while [ $q -lt $graph_width ]; do
			cpu_utilization_graph_array[$q]=$(calcHight ${cpu_utilization_array[$q]} $cpu_utilization_max)
			((q++))
		done
	fi
	recent_cpu_utilization_max=$cpu_utilization_max
}

calcGraphScale() {
	local scale_max=$1
	local scale_max_recent=$2
	local -n converted_scale=$3
	if [ $scale_max -ne $scale_max_recent ]; then
	#if (( $(bc <<< "$scale_max != $scale_max_recent") )); then
	#echo "JESTEM TU"
		local byte_scale=(0 0 0 0 0 0)
		local i=1
		local distance=$(bc -l <<< "scale=0; $scale_max / $graph_scale_division")
		byte_scale[0]=$scale_max
 		while [ $i -lt $graph_scale_division ]; do
 		#while (( $(bc <<< "$i < $graph_scale_division") )); do
			byte_scale[$i]=$(bc -l <<< "scale=2; $scale_max - ($i * $distance)")
			((i++))
 		done
 		byte_scale[$graph_scale_division]=0
		local k=0
		while [ $k -lt ${#byte_scale[@]} ]; do
			convert ${byte_scale[$k]}
			converted_scale[$k]=$converted" "$unit
			((k++))
		done
	fi
}

calcGraphScaleForCPU() {
	local scale_max=$1
	local scale_max_recent=$2
	if (( $(bc <<< "$scale_max != $scale_max_recent") )); then
		local i=1
		local distance=$(bc -l <<< "scale=2; $scale_max / $graph_scale_division")
		cpu_utilization_graph_scale[0]=$scale_max
 		while (( $(bc <<< "$i < $graph_scale_division") )); do
			cpu_utilization_graph_scale[$i]=$(bc -l <<< "scale=2; print 0; $scale_max - ($i * $distance)")
			((i++))
 		done
 		cpu_utilization_graph_scale[$graph_scale_division]=0
	fi
}

printGraph() {
	declare -a graph_array=("${!1}")
	declare -a graph_scale=("${!2}")
	local gr_scale="⏌ "
	local i=$((graph_hight - 1))
	getScaleNumber "${graph_scale[0]}"
	graph="$formated_scale_number"$gr_scale"\n"
	local x=1
	local graph_scale_index=1
	while [ $i -ge 0 ]; do
		if ! ((x % graph_scale_unit)); then
			getScaleNumber "${graph_scale[$graph_scale_index]}"
			graph+=$formated_scale_number$gr_scale
			((graph_scale_index++))
		else
			getChar " " "$graph_scale_number_width"
			graph+=$nchar$gr_scale
		fi
		#graph+=$graph_scale
		local j=0
		while [ $j -lt $graph_width ]; do
			if [ ${graph_array[$j]} -gt $i ]; then
				graph+="███ "
			else
				graph+="    "
			fi
			((j++))
		done
		graph+="\n"
		((i--))
		((x++))
	done
	getChar "⎺" "$(($((graph_scale_number_width + ${#gr_scale})) + 4 * graph_width))"
	graph+=$nchar
	printf "$graph\n\n"
	#calcGraphScale $write_max $recent_write_max
	#printf "%s," "${graph_scale[@]}"
}


convert() {
	local in_bytes=$1
	unit=""
	local giga="1000000000"
	local mega="1000000"
	local kilo="1000"
	if [ "$in_bytes" -ge "$giga" ]; then
		converted=$(bc <<< "scale=2; $in_bytes/$giga")
		unit="G"
	elif [ "$in_bytes" -ge "$mega" ]; then
		converted=$(bc <<< "scale=2; $in_bytes/$mega")
		unit="M"
		#echo W MG
	elif [ "$in_bytes" -ge "$kilo" ]; then
		converted=$(bc <<< "scale=2; $in_bytes/$kilo")
		unit="k"
		#echo W kB
	else
		converted=$in_bytes
	fi
	unit+="B"
}
while true; do

	update
	printf "\033c"
	
	printf "			Prędkość odczytu: $read_display \n"
	printGraph read_graph_array[@] read_graph_scale[@]
	
	
	printf "			Prędkość zapisu: $write_display \n"
	printGraph write_graph_array[@] write_graph_scale[@]
	
	
	printf "			Zużycie CPU: $cpu_utilization_display\n"
	printGraph cpu_utilization_graph_array[@] cpu_utilization_graph_scale[@]
	
	
done
