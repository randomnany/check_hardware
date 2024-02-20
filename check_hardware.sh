#!/bin/bash

#system info   
system_info() {
    echo "+-------------------------------+----------------------+----------------------+"              >> $output_file
    echo "   系统信息 "                                                                                 >> $output_file
    echo "    ├── 操作系统:  " $(lsb_release -d|grep Description|awk  '{$1=""; print $0}')                >> $output_file
    echo "    ├── 内核版本:  " $(uname -a|awk '{print $1,$3}')                                            >> $output_file 
    echo "    ├── 主板名称:  " $(dmidecode -t 2|grep Product |cut -f2 -d: )                                            >> $output_file 
    echo "    └── 主板制造商:" $(dmidecode -t 2|grep Manufacturer|cut -f2 -d: )                                            >> $output_file 
}

#CPU info   
cpu_info() {
    echo "+-------------------------------+----------------------+----------------------+"              >> $output_file
    cpu_num=$(cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l)
    echo "   CPU X ${cpu_num}"                                                                                       >> $output_file

    cid=[]
    c=$(cat /proc/cpuinfo|grep "physical id"|wc -l)
    for i in $(seq 1 $c) 
    do
        cid[i]=$(cat /proc/cpuinfo|grep "physical id"| cut -f2 -d: |head -n $i |tail -n 1)
    done
    cname=[]
    c=$(cat /proc/cpuinfo|grep "name"|wc -l)
    for i in $(seq 1 $c)
    do
        cname[i]=$(cat /proc/cpuinfo|grep "name"| cut -f2 -d: |head -n $i |tail -n 1)
    done

    cpus=[]
    for((i=1;i<${#cid[@]};i++));
    do
        cpus[cid[i]]=${cname[$i]}
    done
    for((i=0;i<${#cpus[@]};i++)); 
    do
        echo "    CPU"$i                                                                                          >> $output_file
        echo "     └── 型号:"  ${cpus[$i]}   >> $output_file
    done
}

#memory info   
mem_info() {
    echo "+-------------------------------+----------------------+----------------------+"              >> $output_file
    mem_num=$(dmidecode -t memory |grep Size|grep -v No|wc -l)
    echo "   内存 X "${mem_num}                                                                                          >> $output_file
    echo "    └── 内存总大小: "$(dmidecode |grep "Range Size"|head -1|awk '{print $3$4}')                                >> $output_file
    msize=[]
    j=0
    for i in $(seq 1 $mem_num) 
    do
        msize[j]=$(dmidecode -t memory |grep Size|grep -v 'No'| cut -f2 -d: |head -n $i |tail -n 1)
        ((j++))
    done
    mname=[]
    j=0
    for i in $(seq 1 $mem_num) 
    do
        mname[j]=$(dmidecode -t memory |grep Manufacturer|grep -v 'Not'| cut -f2 -d: |head -n $i |tail -n 1)
        ((j++))
    done

    for((i=0;i<${mem_num};i++)); 
    do
        echo "    内存"$i                                                                                          >> $output_file
        echo "     ├── 型号:"  ${mname[$i]}   >> $output_file
        echo "     └── 大小:"  ${msize[$i]}   >> $output_file
    done
}

#disk and partitions   
partition_info() {
    echo "+-------------------------------+----------------------+----------------------+"              >> $output_file
    hd_num=$(lsblk -o NAME,MODEL,SIZE -nld|wc -l)
    echo "   硬盘 X "$hd_num  >> $output_file
    for i in $(seq 1 $hd_num)
    do
        echo "    硬盘"${i}                              >> $output_file
        echo "     ├── 型号:" $(lsblk -o MODEL -nld|head -n $i |tail -n 1)           >> $output_file
        echo "     └── 大小:" $(lsblk -o SIZE -nld|head -n $i |tail -n 1)              >> $output_file
    done

}

#nvidia info
nvidia_info() {
    echo "+-------------------------------+----------------------+----------------------+"              >> $output_file

    if [[ ! -z $(which nvidia-smi) ]];then
        nv_num=$(nvidia-smi --query-gpu=index,name,serial --format=csv|grep -i 'nvidia\|geforce'|wc -l)
        echo "   显卡 X "$nv_num  >> $output_file
        if [[  ! -z $(lspci |grep -i vga) ]];then
            OLD_IFS="$IFS" 
            i=1
            IFS=$'\n'
            for v in $(nvidia-smi --query-gpu=index,name,serial --format=csv|grep -i 'nvidia\|geforce')
            do
                nv_name=$(echo ${v}|awk -F',' '{print $2}')
                echo -e "    └──显卡${i}: ${nv_name}"    >> $output_file
                ((i++))
             done
             IFS="$OLD_IFS"
        else
            echo -e "   └──\033[1;31m显卡没有检测到\033[0m"    >> $output_file
        fi
    else
        nv_num=$(lspci | grep VGA|wc -l)
        echo "   显卡 X "$nv_num  >> $output_file
        if [[  ! -z $(lspci |grep -i vga) ]];then
            OLD_IFS="$IFS" 
            i=1
            IFS=$'\n'
            for v in $(lspci | grep VGA | awk -F ': ' '{print $2}')
            do
                nv_name=$v
                echo -e "    └──显卡${i}: ${nv_name}"    >> $output_file
                ((i++))
             done
             IFS="$OLD_IFS"
        else
            echo -e "   └──\033[1;31m显卡没有检测到\033[0m"    >> $output_file
        fi
    fi
}

#network adapter info   
adapter_info() {
    echo "+-------------------------------+----------------------+----------------------+"              >> $output_file
    net_num=$(ls /sys/class/net|grep -v docker|grep -v lo|grep -v veth|grep -v cni0|grep -v dummy0|grep -v flanne* |grep -v kube*|wc -l)
    echo "   网卡 X "$net_num  >> $output_file
    OLD_IFS="$IFS" 
    IFS=$'\n'
    i=1
    ls /sys/class/net|grep -v docker|grep -v lo|grep -v veth|grep -v cni0|grep -v dummy0|grep -v flanne* |grep -v kube* |while read line
    do
        speed=$(echo ${line}| xargs -I{} ethtool {} |grep "Speed:"|sed "s/Speed://g"|sed "s/\t//g"|sed "s/ //")
        echo "    └── "${line} "("$speed")"  >> $output_file
        ((i++))
    done
    IFS="$OLD_IFS"
}



output_dir="./"$(date +%Y-%m-%d)"/"
if [[ ! -d $output_dir ]];then
    mkdir -p $output_dir
fi

output_file_name=$(date "+%Y-%m-%d_%H-%M-%S").txt
output_file=$(echo ${output_dir}${output_file_name}|sed 's/ //g')

#输出所有信息
echo "+-----------------------------------------------------------------------------+"  >> $output_file
echo "+                服务器硬件检测  "  >> $output_file

system_info
cpu_info
mem_info
partition_info
nvidia_info
adapter_info

echo "+-----------------------------------------------------------------------------+"  >> $output_file
echo "+  生成文件地址：${output_file}"                                                  >> $output_file
echo "+-----------------------------------------------------------------------------+"  >> $output_file
cat $output_file
