#!/usr/bin/perl
#
# Net::RTP example file
#
# Display details of RTP packets recieved
#

use Net::RTP;
use Data::Dumper;
use strict;

# Make STDOUT unbuffered
$|=1;

# Check the number of arguments
if ($#ARGV != 1) {
	print "usage: rtpdump.pl <address> <port>\n";
	exit;
}

# Create RTP socket
my ($address, $port) = @ARGV;
my $rtp = new Net::RTP(
		LocalPort=>$port,
		LocalAddr=>$address,
		ReuseAddr=>1
);

# Join the multicast group
$rtp->mcast_add($address) || die "Couldn't join multicast group: $!\n";


my $count = 0;
while (my $packet = $rtp->recv()) {

	# Parse the packet
	print "$count ";
	print "  Src=".$packet->source_ip().':'.$packet->source_port();
	print ", Len=".$packet->payload_size();
	print ", PT=".$packet->payload_type();
	print ", SSRC=".$packet->ssrc();
	print ", Seq=".$packet->seq_num();
	print ", Time=".$packet->timestamp();
	print ", Mark" if ($packet->marker());
	print "\n";

	$count++;
}

