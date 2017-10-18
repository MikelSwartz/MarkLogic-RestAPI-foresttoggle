#!/bin/bash
display_usage() {
  echo "          ${0#*/}"
  echo
  echo "Toggles forests between two databases."
  echo -e "Usage:\n          ${0} -s <Server Name> -a <DBa> -b <DBb> -u <User Name> -p <Password>\n"
  echo -e "Example:\n          ${0} -s devhost313 -a MyDOC -b MyDOC_Swap -u admin -p \$(cat pass)\n"
  echo -e "Optional:\n          Keep the password in a temp file named 'pass'."
  echo "          Using \$(cat pass) keeps the password out of the Command Line History."
  echo
  exit 1
}

while getopts "hs:a:b:u:p:" arg;
  do
    case $arg in
    s )
      HOST=$OPTARG
      ;;
    a )
      DB1=$OPTARG
      ;;
    b )
      DB2=$OPTARG
      ;;
    u )
      USER=$OPTARG
      ;;
    p )
      PASS=$OPTARG
      ;;
    h )
      display_usage
      ;;
    \?)
      echo "Unknown option: -$OPTARG" >&2
      display_usage
      ;;
    : )
      echo "Missing option argument for -$OPTARG" >&2
      display_usage
      ;;
    * )
      echo "Unimplemented option: -$OPTARG" >&2;
      display_usage
      ;;
  esac
done
if [[ ! $HOST || ! $DB1 || ! $DB2 || ! $USER || ! $PASS ]]
  then
    echo "Argument missing"
    display_usage
fi
DB1_Forests=$(curl -s -X GET  --anyauth -u $USER:$PASS http://${HOST}:8002/manage/v2/databases/${DB1}/properties |\
    grep "<forest>.*</forest>" |\
    awk -F'[<>]' '{print $3}')
DB2_Forests=$(curl -s -X GET  --anyauth -u $USER:$PASS http://${HOST}:8002/manage/v2/databases/${DB2}/properties |\
    grep "<forest>.*</forest>" |\
    awk -F'[<>]' '{print $3}')

for i in $DB1_Forests
 do
   curl -s --anyauth -u $USER:$PASS -X POST -i \
    -d "state=detach" -d "database=${DB1}" \
    -H "Content-type: application/x-www-form-urlencoded" \
    http://${HOST}:8002/manage/v2/forests/${i}
done
for i in $DB2_Forests
 do
   curl -s --anyauth -u $USER:$PASS -X POST -i \
    -d "state=detach" -d "database=${DB2}" \
    -H "Content-type: application/x-www-form-urlencoded" \
    http://${HOST}:8002/manage/v2/forests/${i}
done
for i in $DB1_Forests
 do
   curl -s --anyauth -u $USER:$PASS -X POST -i \
    -d "state=attach" -d "database=${DB2}" \
    -H "Content-type: application/x-www-form-urlencoded" \
    http://${HOST}:8002/manage/v2/forests/${i}
done
for i in $DB2_Forests
 do
   curl -s --anyauth -u $USER:$PASS -X POST -i \
    -d "state=attach" -d "database=${DB1}" \
    -H "Content-type: application/x-www-form-urlencoded" \
    http://${HOST}:8002/manage/v2/forests/${i}
done

