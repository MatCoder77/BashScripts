#!/bin/bash

mode="default"
short_info="USER PPID PID COMMAND"
normal_info="USER PPID PID SID TTY STATE COMMAND"
full_info="USER PPID PID PGID SID TTY TPGID PRIORITY NICE STATE FILES COMMAND"
allowed_info="USER PPID PID PGID SID TTY TPGID PRIORITY NICE STATE FILES COMMAND"
mode_set="false"

display_info=${normal_info}

help() {
	echo -e "Pomoc: \nmyps [-m short | normal | full] [-o user,ppid,pid,pgid,id,tty,tpgid,priority,nice,state,files,command]"
}

isInInfo() {
	for option in $allowed_info; do
		if [ $option == $1 ]; then
			return 0
		fi
	done
	return 1
}

getStatData() {
	stat_data=$(cat /proc/$1/stat)
	data=${stat_data/(*)/}
	IFS=' ' read -ra process_info <<< "$data"
}

readProcesses() {
	procs=$(ls /proc | grep -E '^[0-9]+$' | sort -n)
	info=""
	for process in $procs; do
		if [ -d /proc/$process ]; then
		getStatData $process
		for option in $display_info; do		
			case $option in
			"USER")
				info+='|'$(cat /proc/$process/status | grep -Poi '^uid:\s+\K[0-9]+')
				;;
			"PPID")
				info+='|'$(cat /proc/$process/status | grep -Poix 'PPID:\s+\K[0-9]+')
				;;
			"PID")
				info+='|'$(cat /proc/$process/status | grep -Poix 'PID:\s+\K[0-9]+')
				;;
			"PGID")
				info+='|'${process_info[3]}
				;;
			"SID")
				info+='|'${process_info[4]}
				;;
			"TTY")
				info+='|'${process_info[5]}
				;;
			"TPGID")
				info+='|'${process_info[6]}
				;;
			"PRIORITY")
				info+='|'${process_info[16]}
				;;
			"NICE")
				info+='|'${process_info[17]}
				;;
			"STATE")
				info+='|'$(cat /proc/$process/status | grep -Poix 'STATE:\s+\K.+')
				;;
			#"FILES")
			#	info+='|'$(ls /proc/$process/fd | wc -l)
			#	;;
			"FILES")
				count=$(lsof -p $process | wc -l)
				if [ $count -le 0 ]; then
					count=0
				else
					((count--))
				fi
				info+='|'$count
				;;
			"COMMAND")
				info+='|'$(cat /proc/$process/status | grep -Poix 'NAME:\s+\K.+')
				;;
			esac
		done
		info+=$"\n"
		fi
	done
	prepared_titles=${display_info// /|}
	#echo $prepared_titles
	(echo -e $prepared_titles$"\n"$info) | column -t -s"|"

}

while getopts ":m:o:h" opt; do
	case "$opt" in
	m)
		mode_set="true"
		case $OPTARG in
		"full")
			display_info=$full_info
			;;
		"normal")
			display_info=$normal_info
			;;
		"short")
			display_info=$short_info
			;;
		*)
			echo "Zły argument $OPTARG dla flagi -m"
			help
			exit 1
			;;
		esac
		;;
	o)
		if [ $mode_set == "false" ]; then
			display_info=" "
		fi
		args=${OPTARG^^}
		IFS=',' read -ra user_options <<< "$args"
		for i in "${user_options[@]}"; do
			if isInInfo $i; then
				display_info+=" $i "
			else
				echo "Zły argument $i dla flagi -o" 
				help
				exit 1
			fi
		done
		;;
	\?)
		echo "Błędna flaga"
		help
		;;
	h)
		help
		exit 1
		;;
	:)
		echo "Brak argumentów dla -o "
		help
		;;
	esac
done
readProcesses
#echo $display_info
#getStatData "1652"
