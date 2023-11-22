curl -s --data-urlencode "text=$1" "https://api.telegram.org/{{botTOKEN}}/sendMessage?chat_id={{CHAT_ID}}" >> /dev/null 

