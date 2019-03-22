#ifndef WATERSHELL_H_
#define WATERSHELL_H_

// Networking
#include <linux/if_ether.h>
#include <linux/if_packet.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <linux/filter.h>

// General
#include <string>
#include <vector>


class Watershell {
public:
    Watershell();
    Start();

    /* its a datagram inside a packet inside a frame!
    * gotta be packed though!
    */
    struct __attribute__((__packed__)) udpframe {
        struct ethhdr ehdr;
        struct iphdr ip;
        struct udphdr udp;
        unsigned char data[ETH_DATA_LEN - sizeof(struct udphdr) - sizeof(struct iphdr)];
    };

     

private:
    std::string iface;

    int sockfd;
    struct ifreq *sifreq;
    bool promisc;

    void send_status(std::vector<unsigned char>buf, std::vector<unsigned char>payload);   
    void sigint(int signum);
    void ip_checksum(struct iphdr *ip);
    void udp_checksum(struct iphdr *ip, std::vector<unsigned char>payload);    
};

/* BPF code generated with tcpdump -dd udp and port 12345
 * used to filter incoming packets at the socket level
 */
const struct sock_filter bpf_code[] = {
    { 0x28, 0, 0, 0x0000000c },
    { 0x15, 0, 6, 0x000086dd },
    { 0x30, 0, 0, 0x00000014 },
    { 0x15, 0, 15, 0x00000011 },
    { 0x28, 0, 0, 0x00000036 },
    { 0x15, 12, 0, 0x00003039 }, //5
    { 0x28, 0, 0, 0x00000038 },
    { 0x15, 10, 11, 0x00003039 }, //7
    { 0x15, 0, 10, 0x00000800 },
    { 0x30, 0, 0, 0x00000017 },
    { 0x15, 0, 8, 0x00000011 },
    { 0x28, 0, 0, 0x00000014 },
    { 0x45, 6, 0, 0x00001fff },
    { 0xb1, 0, 0, 0x0000000e },
    { 0x48, 0, 0, 0x0000000e },
    { 0x15, 2, 0, 0x00003039 }, //15
    { 0x48, 0, 0, 0x00000010 },
    { 0x15, 0, 1, 0x00003039 }, //17
    { 0x6, 0, 0, 0x0000ffff },
    { 0x6, 0, 0, 0x00000000 },
};

#endif // WATERSHELL_H_
