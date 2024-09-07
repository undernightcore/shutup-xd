#!/bin/bash

#Failsafe mode
#(Possible values being a number between 80 and 100, or "auto")
E_value="auto"

#IPMI IDs
CPUID0=0Eh
CPUID1=0Fh

AMBIENT_ID=04h
EXHAUST_ID=01h

#Logtype:
#0 = Only Alerts
#1 = Fan speed output + alerts
#2 = Simple text + fanspeed output + alerts
#3 = Table + fanspeed output + alerts
Logtype=2

#There you basically define your fan curve. For each fan step temperature (in °C) you define which fan speed it uses when it's equal or under this temp.
#For example: until it reaches step0 at 30°C, it runs at 2% fan speed, if it's above 30°C and under 35°C, it will run at 6% fan speed, ect
#Fan speed values are to be set as for each step in the FST# value, in % between 0 and 100.
TEMP_STEP0=55
FST0=10
TEMP_STEP1=56
FST1=11
TEMP_STEP2=57
FST2=12
TEMP_STEP3=57
FST3=13
TEMP_STEP4=58
FST4=14
TEMP_STEP5=59
FST5=15
TEMP_STEP6=59
FST6=16
TEMP_STEP7=60
FST7=17
TEMP_STEP8=60
FST8=18
TEMP_STEP9=61
FST9=19
TEMP_STEP10=61
FST10=20
TEMP_STEP11=61
FST11=21
TEMP_STEP12=62
FST12=22
TEMP_STEP13=62
FST13=23
TEMP_STEP14=63
FST14=24
TEMP_STEP15=63
FST15=25
TEMP_STEP16=63
FST16=26
TEMP_STEP17=64
FST17=27
TEMP_STEP18=64
FST18=28
TEMP_STEP19=64
FST19=29
TEMP_STEP20=65
FST20=30
TEMP_STEP21=65
FST21=31
TEMP_STEP22=65
FST22=32
TEMP_STEP23=65
FST23=33
TEMP_STEP24=66
FST24=34
TEMP_STEP25=66
FST25=35
TEMP_STEP26=66
FST26=36
TEMP_STEP27=66
FST27=37
TEMP_STEP28=67
FST28=38
TEMP_STEP29=67
FST29=39
TEMP_STEP30=67
FST30=40
TEMP_STEP31=67
FST31=41
TEMP_STEP32=67
FST32=42
TEMP_STEP33=68
FST33=43
TEMP_STEP34=68
FST34=44
TEMP_STEP35=68
FST35=45
TEMP_STEP36=68
FST36=46
TEMP_STEP37=68
FST37=47
TEMP_STEP38=69
FST38=48
TEMP_STEP39=69
FST39=49
TEMP_STEP40=69
FST40=50
TEMP_STEP41=69
FST41=51
TEMP_STEP42=69
FST42=52
TEMP_STEP43=69
FST43=53
TEMP_STEP44=70
FST44=54
TEMP_STEP45=70
FST45=55
TEMP_STEP46=70
FST46=56
TEMP_STEP47=70
FST47=57
TEMP_STEP48=70
FST48=58
TEMP_STEP49=70
FST49=59
TEMP_STEP50=71
FST50=60
TEMP_STEP51=71
FST51=61
TEMP_STEP52=71
FST52=62
TEMP_STEP53=71
FST53=63
TEMP_STEP54=71
FST54=64
TEMP_STEP55=71
FST55=65
TEMP_STEP56=71
FST56=66
TEMP_STEP57=72
FST57=67
TEMP_STEP58=72
FST58=68
TEMP_STEP59=72
FST59=69
TEMP_STEP60=72
FST60=70
TEMP_STEP61=72
FST61=71
TEMP_STEP62=72
FST62=72
TEMP_STEP63=72
FST63=73
TEMP_STEP64=72
FST64=74
TEMP_STEP65=73
FST65=75
TEMP_STEP66=73
FST66=76
TEMP_STEP67=73
FST67=77
TEMP_STEP68=73
FST68=78
TEMP_STEP69=73
FST69=79
TEMP_STEP70=73
FST70=80
TEMP_STEP71=73
FST71=81
TEMP_STEP72=73
FST72=82
TEMP_STEP73=73
FST73=83
TEMP_STEP74=73
FST74=84
TEMP_STEP75=74
FST75=85
TEMP_STEP76=74
FST76=86
TEMP_STEP77=74
FST77=87
TEMP_STEP78=74
FST78=88
TEMP_STEP79=74
FST79=89
TEMP_STEP80=74
FST80=90
TEMP_STEP81=74
FST81=91
TEMP_STEP82=74
FST82=92
TEMP_STEP83=74
FST83=93
TEMP_STEP84=74
FST84=94
TEMP_STEP85=75
FST85=95
TEMP_STEP86=75
FST86=96
TEMP_STEP87=75
FST87=97
TEMP_STEP88=75
FST88=98
TEMP_STEP89=75
FST89=99
TEMP_STEP90=75
FST90=100

#CPU fan governor type - keep in mind, with IPMI it's CPUs, not cores.
#0 = uses average CPU temperature accross CPUs
#1 = uses highest CPU temperature
TEMPgov=0

#Maximum allowed delta in TEMPgov0. If exceeded, switches profile to highest value.
CPUdelta=15

#Max offset applied to CPU temps
MAX_MOD=69

#If your exhaust temp is reaching 65°C, you've been cooking your server. It needs the woosh.
EXHTEMP_MAX=65

#Hexadecimal conversion and IPMI command into a function 
ipmifanctl=(ipmitool -I open raw 0x30 0x30)

#Failsafe = Parameter check
re='^[0-9]+$'
ren='^[+-]?[0-9]+?$'

function setfanspeed () { 
    TEMP_Check=$1
    TEMP_STEP=$2
    FS=$3
    if [[ $FS == "auto" ]]; then
        if [ "$Logtype" != 0 ] && [ "$4" -eq 0 ]; then
                echo "> $TEMP_Check °C is higher or equal to $TEMP_STEP °C. Switching to automatic fan control"
        fi
        [ "$4" -eq 1 ] && echo "> ERROR : Keeping fans on auto as safety measure"
        [ "$4" -eq 2 ] && echo "> WARNING : Container stopped, Dell default dynamic fan control profile applied for safety"
        "${ipmifanctl[@]}" 0x01 0x01
    else
        if [[ $FS -gt "100" ]]; then
            FS=100
        fi
        HEX_value=$(printf '%#04x' "$FS")
        if [ "$4" -eq 1 ]; then
            echo "> ERROR : Keeping fans on high profile ($3 %) as safety measure"
        elif [ "$Logtype" != 0 ]; then
            echo "> $TEMP_Check °C is lower or equal to $TEMP_STEP °C. Switching to manual $FS % control"
        fi
        "${ipmifanctl[@]}" 0x01 0x00
        "${ipmifanctl[@]}" 0x02 0xff "$HEX_value"
     fi
}

function gracefull_exit () {
  setfanspeed XX XX "$E_value" 2
  exit 0
}

trap 'gracefull_exit' SIGQUIT SIGKILL SIGTERM

while true
do
        sleep 60 &
        SLEEP_PROCESS_PID=$!
        
        #Counting CPU Fan speed steps and setting max value
        for ((i=0; i>=0 ; i++))
        do
                inloopstep="TEMP_STEP$i"
                inloopspeed="FST$i"
                if [[ -z "${!inloopspeed}" ]] || [[ -z "${!inloopstep}" ]]; then
                        inloopmaxstep="TEMP_STEP$((i-1))"
                        MAXTEMP="${!inloopmaxstep}"
                        TEMP_STEP_COUNT=$i
                        break                
                fi
        done

        #Pulling temperature data from IPMI
        if $IPMIDATA_toggle ; then
        IPMIPULLDATA=$(ipmitool -I open sdr type temperature)
        DATADUMP=$(echo "$IPMIPULLDATA")
        if [ -z "$DATADUMP" ]; then
                echo "No data was pulled from IPMI"
                setfanspeed XX XX "$E_value" 1
        else
                AUTOEM=false
        fi
        else
                echo "Both IPMI data and Non-IPMI-CPU data are toggled off"
                setfanspeed XX XX "$E_value" 1
        fi

        #Parsing CPU Temp data into values to be later checked in count, continuity and value validity.
        CPUTEMP0=$(echo "$DATADUMP" |grep "$CPUID0" |grep degrees |grep -Po '\d{2}' | tail -1)
        CPUTEMP1=$(echo "$DATADUMP" |grep "$CPUID1" |grep degrees |grep -Po '\d{2}' | tail -1)

        #CPU counting
        if [ -z "$CPUTEMP0" ]; then
                CPUcount=0
        else
                if [[ ! -z "$CPUTEMP0" ]]; then #Infinite CPU number adding, if you pull individual CPU cores from lm-sensors or something
                        TEMPadd=0
                        for ((i=0; i>=0 ; i++))
                        do
                                CPUcountloop="CPUTEMP$i"
                                if [[ ! -z "${!CPUcountloop}" ]]; then
                                        if ! [[ "${!CPUcountloop}" =~ $re ]] ; then
                                        echo "!!error: Reading is not a number or negative!!"
                                        echo "Falling back to ambient mode..."
                                        CPUcount=0
                                        break
                                        fi
                                        currcputemp="${!CPUcountloop}"
                                        CPUcount=$((i+1))
                                        TEMPadd=$((TEMPadd+currcputemp))
                                else
                                        if [[ $((CPUcount % 2)) -eq 0 ]] || [[ $CPUcount -eq 1 ]]; then
                                                CPUn=$((TEMPadd/CPUcount))
                                                break
                                        else
                                                CPUcount=0
                                                echo "CPU count is odd, please check your configuration";
                                                echo "Falling back to ambient mode..."
                                                break
                                        fi
                                fi
                        done

                fi
        fi

        #CPU Find lowest and highest CPU temps
        if [ "$CPUcount" -gt 1 ]; then
                for ((i=0; i<CPUcount; i++)) #General solution to finding the highest number with a shitty shell loop
                do if [[ $i -le $CPUcount ]]; then
                        CPUtemploop="CPUTEMP$i"
                        if [ "$i" -eq 0 ]; then
                        CPUh=${!CPUtemploop}
                        CPUl=${!CPUtemploop}
                        else
                        if [ ${!CPUtemploop} -gt $CPUh ]; then
                                CPUh=${!CPUtemploop}
                        fi
                        if [ ${!CPUtemploop} -lt $CPUl ]; then
                                CPUl=${!CPUtemploop}
                        fi
                        fi
                fi
                done
        fi

        if [ $TEMPgov -eq 1 ] || [ $((CPUh-CPUl)) -gt $CPUdelta ]; then
                echo "!! CPU DELTA Exceeded !!"
                echo "Lowest : $CPUl°C"
                echo "Highest: $CPUh°C"
                echo "Delta Max: $CPUdelta °C"
                echo "Switching CPU profile..."
                CPUdeltatest=1
                CPUn=$CPUh
        fi

        #Intake temperature
        AMBTEMP=$(echo "$DATADUMP" |grep "$AMBIENT_ID" |grep degrees |grep -Po '\d{2}' | tail -1)
        
        #Exhaust temperature modifier when CPU temps are available and Checks for Delta Mode and Ambient mode
        EXHTEMP=$(echo "$DATADUMP" |grep "$EXHAUST_ID" |grep degrees |grep -Po '\d{2}' | tail -1)
        if [ $CPUcount != 0 ]; then
                if [[ ! -z "$EXHTEMP" ]]; then
                        if [ "$EXHTEMP" -ge $EXHTEMP_MAX ]; then
                                echo "Exhaust temp is critical!! : $EXHTEMP °C!"
                                TEMPMOD=$MAX_MOD
                        fi
                fi
        fi

        #vTemp
        if [ -z "$TEMPMOD" ]; then
        TEMPMOD=0
        fi
        if [ $CPUcount != 0 ]; then
                vTEMP=$((CPUn+TEMPMOD))
        fi

        #Emergency mode trigger
        if $AUTOEM ; then
                setfanspeed XX XX "$E_value" 1
        fi

        #Logtype logic
        if [ $Logtype -eq 2 ]; then
                for ((i=0; i<CPUcount; i++))
                do if [[ $i -le $CPUcount ]]; then
                        CPUtemploopecho="CPUTEMP$i"
                        echo "CPU$i = ${!CPUtemploopecho} °C"
                fi
                done
                [ "$CPUcount" -eq 0 ] && echo "No CPU sensors = Ambient Mode"
                [ "$TEMPgov" -eq 0 ] && [ "$CPUcount" -gt 1 ] && echo "$CPUcount CPU average = $CPUn °C"
                [ "$TEMPgov" -eq 1 ] && [ "$CPUcount" -gt 1 ] && echo "$CPUcount CPU highest = $CPUn °C"
                [[ ! -z "$AMBTEMP" ]] && echo "Ambient = $AMBTEMP °C" 
                [[ ! -z "$EXHTEMP" ]] && echo "Exhaust = $EXHTEMP °C"
                [[ "$CPUcount" != 0 ]] && [[ "$TEMPMOD" != 0 ]] && echo "TEMPMOD = +$TEMPMOD °C"
                if [ "$CPUcount" -ge 1 ]; then 
                        [ -z "$CPUdeltatest" ] && echo "CPUdelta = $CPUdelta °C" || echo "CPUdelta EX! = $CPUdelta °C"
                fi
                if [ "$CPUcount" != 0 ]; then
                        echo  "vTEMP = $vTEMP °C"
                fi
        fi

        if [ $Logtype -eq 3 ]; then
                (
                printf 'SOURCE\tFETCH\tTEMPERATURE\n' 
                for ((i=0; i<CPUcount; i++))
                do if [[ $i -le $CPUcount ]]; then
                        CPUtemploopecho="CPUTEMP$i"
                        printf '%s\t%4s\t%12s\n' "CPU$i" "OK" "${!CPUtemploopecho} °C"
                fi
                done
                [ "$CPUcount" -eq 0 ] && printf '%s\t%4s\t%12s\n' "CPU" "NO" "Ambient Mode"
                [ "$TEMPgov" -eq 0 ] && [ "$CPUcount" -gt 1 ] && printf '%s\t%4s\t%12s\n' "$CPUcount CPU average" "OK" "$CPUn °C"
                [ "$TEMPgov" -eq 1 ] && [ "$CPUcount" -gt 1 ] && printf '%s\t%4s\t%12s\n' "$CPUcount CPU highest" "OK" "$CPUn °C"
                [[ ! -z "$AMBTEMP" ]] && printf '%s\t%4s\t%12s\n' "Ambient" "OK" "$AMBTEMP °C" || printf '%s\t%4s\t%12s\n' "Ambient" "NO" "NaN " 
                [[ ! -z "$EXHTEMP" ]] && printf '%s\t%4s\t%12s\n' "Exhaust" "OK" "$EXHTEMP °C" || printf '%s\t%4s\t%12s\n' "Exhaust" "NO" "NaN " 
                if [ "$CPUcount" -ge 1 ]; then 
                        [ -z "$CPUdeltatest" ] && printf '%s\t%4s\t%12s\n' "CPUdelta" "OK" "$CPUdelta °C" || printf '%s\t%4s\t%12s\n' "CPUdelta" "EX" "$CPUdelta °C"
                fi
                if [ "$CPUcount" != 0 ]; then
                        [[ "$TEMPMOD" != 0 ]] && printf '%s\t%4s\t%12s\n' "TEMPMOD" "OK" "+$TEMPMOD °C" || printf '%s\t%4s\t%12s\n' "TEMPMOD" "NO" "NaN "
                fi
                if [ "$CPUcount" != 0 ]; then
                        [[ "$vTEMP" != "$CPUn" ]] && printf '%s\t%4s\t%12s\n' "vTEMP" "OK" "$vTEMP °C" || printf '%s\t%4s\t%12s\n' "vTEMP" "EQ" "$vTEMP °C" 
                fi
                ) | column -t -s $'\t'
        fi
        #Logtype logic end.

        #Temp comparisons
        if [ $CPUcount -gt 0 ]; then
                if [ $vTEMP -ge $MAXTEMP ]; then
                        setfanspeed "$vTEMP" $MAXTEMP "$E_value" 0
                        echo "!! CPU MODE : Temperature Critical trigger!!"
                else
                        for ((i=0; i<TEMP_STEP_COUNT; i++))
                        do
                                TEMP_STEPloop="TEMP_STEP$i"
                                FSTloop="FST$i"
                                if [ $vTEMP -le "${!TEMP_STEPloop}" ]; then
                                        setfanspeed $vTEMP "${!TEMP_STEPloop}" "${!FSTloop}" 0
                                        break
                                fi
                        done
                fi 
        fi

        wait $SLEEP_PROCESS_PID
done
