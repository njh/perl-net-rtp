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


# Shared variable used for collecting statistics
our $stats = &share({});

threads->new( \&display_stats );

my $seq=0;
while (1) {

	my $packet = $rtp->recv();
	die "Failed to recieve packet: $!" unless (defined $packet);
	
	my $ssrc = $packet->ssrc();
	unless (exists $stats->{$ssrc}) {
		$stats->{$ssrc} = &share({});
		$stats->{$ssrc}->{'seq_num'}=$packet->seq_num();
		reset_stats( $ssrc );
	}
	
	# Update statistics
	$stats->{$ssrc}->{'bytes'} += $packet->payload_size();
	$stats->{$ssrc}->{'packets'} += 1;
	
	# Lost or late packet?
	if ($stats->{$ssrc}->{'seq_num'} != $packet->seq_num()) {
		if ($stats->{$ssrc}->{'seq_num'}-1 == $packet->seq_num()) { 
			$stats->{$ssrc}->{'dup'}++;
		} elsif ($stats->{$ssrc}->{'seq_num'} > $packet->seq_num()) { 
			$stats->{$ssrc}->{'late'}++;
			$stats->{$ssrc}->{'lost'}--;
		} else {
			$stats->{$ssrc}->{'lost'}++;
		}
	}
	
	# Calculate next number in sequence
	$stats->{$ssrc}->{'seq_num'} = $packet->seq_num()+1;
	if ($stats->{$ssrc}->{'seq_num'} > 65535) {
		$stats->{$ssrc}->{'seq_num'}=0;
	}
	
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

		#my $sec = (localtime())[0];
		#printf("%3d  packets=%3d, bytes=%d, lost=%d, bitrate=%d kbps\n", $sec, $packets, $bytes, $lost, ($bytes*8)/1000);
	
		print Dumper( $stats );
		#reset_stats();
	}
	
}


sub reset_stats {
	my ($ssrc) = @_;
	
	$stats->{$ssrc}->{'packets'}=0;
	$stats->{$ssrc}->{'bytes'}=0;
	$stats->{$ssrc}->{'lost'}=0;
	$stats->{$ssrc}->{'late'}=0;
	$stats->{$ssrc}->{'dup'}=0;
	#$lost=0;
}
