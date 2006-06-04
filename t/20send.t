#!/usr/bin/perl

use strict;
use Test;
use Data::Dumper;

# use a BEGIN block so we print our plan before Net::RTP is loaded
BEGIN { plan tests => 6 }

# load Net::RTP
use Net::RTP;
ok(1);


# Create a packet to send
my $packet = new Net::RTP::Packet();
ok( $packet->payload_type(96) );
ok( $packet->payload('Hello World!') );

# Create a RTP socket with multicast desination
my $rtp = new Net::RTP( PeerAddr=>'239.255.234.1:4100' );
ok( defined $rtp );

# Set multicast TTL to 1
ok( $rtp->mcast_ttl( 1 ) );

# Send the packet (returns length of packet sent)
my $result = $rtp->send($packet);
ok( $result == 24 );
