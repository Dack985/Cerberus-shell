# watershell-cpp
Port of [watershell](https://github.com/wumb0/watershell) made by an alumni [wumb0](https://github.com/wumb0) that I decided to rewrite in C++ :)

## Setup
```
g++ main.cpp watershell.cpp -o ${INSERT_BINARY_NAME}
```

## Known Problems
- In older versions of linux `g++` might not come with a regex library. As part of figuring out Layer 2 we use regex so that way the code isnt even more painful to read/write. 
- You cannot connect to a watershell from the box it is running on. The watershell client MUST be run on another box in order for it to work.





python3 watershell-cli.py -l <ip_address.txt> -p 10000 -c <command in quotes>
python3 watershell-cli.py -p 10000 -c <command in quotes>
python3 watershell-cli.py -p 10000 -i

example command 
python3 watershell-cli.py -l team4_ips.txt -p 10000 -c "iptables -A INPUT -p icmp --icmp-type echo-request -j DROP"

