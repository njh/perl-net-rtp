#!/usr/bin/perl

use IO::Socket::Multicast;
use Net::RTP::Packet;
use Data::Dumper;
use strict;

my $PORT = '5170';
my $GROUP = '233.122.227.171';


my $sock = new IO::Socket::Multicast(
		Proto=>'udp',
		LocalPort=>'5170',
		LocalAddr=>'233.122.227.171',
		ReuseAddr=>1
);

# Add the Radio 1 multicast group
$sock->mcast_add('233.122.227.171') || die "Couldn't set group: $!\n";


my $count = 0;
while (1) {
	# now receive some multicast data
	my $data = '';
	my $addr = $sock->recv($data,2048);

	# Parse the packet
	my $packet = new Net::RTP::Packet( $data );
	print "$count ";
	print "  Len=".length($packet->payload());
	print ", PT=".$packet->payload_type();
	print ", SSRC=".$packet->ssrc();
	print ", Seq=".$packet->seq_num();
	print ", Time=".$packet->time_stamp();
	print ", Mark" if ($packet->marker());
	print "\n";

	$count++;
}

