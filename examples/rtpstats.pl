#!/usr/bin/perl
#
# Display RTP statistics
#

use 5.008;             # 5.8 required for stable threading
use strict;
use warnings;
use threads;
use threads::shared;

use Net::RTP;
use Time::HiRes qw/ sleep /;
use Data::Dumper;


# Make STDOUT unbuffered
$|=1;

# Check the number of arguments
if ($#ARGV != 1) {
	print "usage: rtpstats.pl <address> <port>\n";
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


# Shared variables used for collecting statistics
our $packets : shared;
our $bytes : shared;
reset_stats();

threads->new( \&display_stats );

while (1) {

	my $packet = $rtp->recv();
	die "Failed to recieve packet: $!" unless (defined $packet);
	
	# Update statistics
	$bytes += $packet->payload_size();
	$packets++;
	
	# Parse the packet
	#print "$count ";
	#print "  Src=".$packet->source_ip().':'.$packet->source_port();
	#print ", Len=".$packet->payload_size();
	#print ", PT=".$packet->payload_type();
	#print ", SSRC=".$packet->ssrc();
	#print ", Seq=".$packet->seq_num();
	#print ", Time=".$packet->timestamp();
	#print ", Mark" if ($packet->marker());
	#print "\n";
}


sub display_stats {

	while (1) {
		sleep(1);

		printf("packets=%d, bytes=%d, bitrate=%d kbps\n", $packets, $bytes, ($bytes*8)/1000);
	
		reset_stats();
	}
	
}


sub reset_stats {
	
	$packets=0;
	$bytes=0;

}