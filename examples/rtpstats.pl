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
use Time::HiRes qw/ sleep time /;
use Data::Dumper;


my $IP_HEADER_SIZE = 40; 	# 20 bytes of IP+8 bytes of UDP


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
our $all_stats = &share({});
threads->new( \&display_stats );

my $seq=0;
while (1) {

	my $packet = $rtp->recv();
	die "Failed to recieve packet: $!" unless (defined $packet);
	
	# No stats for that SSRC yet?
	my $ssrc = $packet->ssrc();
	unless (exists $all_stats->{$ssrc}) {
		$all_stats->{$ssrc} = init_stats( $packet )
	}
	my $stats = $all_stats->{$ssrc};
	
	# Check Source IP
	if ($stats->{'src_ip'} ne $packet->source_ip()) {
		warn "Ignoring packet with different Source IP address";
		next;
	}
	
	# Update statistics
	$stats->{'bytes'} += $packet->size()+$IP_HEADER_SIZE;
	$stats->{'packets'} += 1;
	
	# Lost or OutOfOrder packet?
	if ($stats->{'seq_num'} != $packet->seq_num()) {
		if ($stats->{'seq_num'}-1 == $packet->seq_num()) {
			# Duplicated
			$stats->{'dup'}++;
		} elsif ($stats->{'seq_num'} > $packet->seq_num()) {
			# Out Of Order
			$stats->{'late'}++;
			$stats->{'lost'}--;
		} else {
			# Lost
			$stats->{'lost'}++;
		}
	}
	
	# Calculate next number in sequence
	$stats->{'seq_num'} = $packet->seq_num()+1;
	if ($stats->{'seq_num'} > 65535) {
		$stats->{'seq_num'}=0;
	}
}


sub display_stats {

	my $start = time();
	my $next = $start+1;
	
	print_key();
	
	while (1) {
		# Wait until time for next check
		sleep($next-time()) if ($next-time()>0);

		my $sec = (localtime())[0];
		print_key() if ($sec==0);
		
		foreach my $stats ( values %$all_stats ) {
			$stats->{'total_packets'}+=$stats->{'packets'};
			$stats->{'total_bytes'}+=$stats->{'bytes'};
			$stats->{'total_lost'}+=$stats->{'lost'};
			$stats->{'total_late'}+=$stats->{'late'};
			
			printf("%2d  %3d  %3d  %3d  %6d | %5d  %4d  %4d %6d  %4d  %s\n",
			$sec, $stats->{'packets'}, $stats->{'lost'}, $stats->{'late'}, $stats->{'bytes'},
			$stats->{'total_packets'}, $stats->{'total_lost'}, $stats->{'total_late'},
			$stats->{'total_bytes'}/1024, 
			(($stats->{'total_bytes'}*8)/1000)/(time()-$start), 
			$stats->{'src_ip'}, );
			
			reset_stats( $stats );
		}

		# Report again in 1 second
		$next += 1.0;
	}
	
}

sub print_key {
	print " T Pkts Lost Late   Bytes |  Pkts  Lost  Late     kB  kbps  Sender\n";
}

sub init_stats {
	my ($packet) = @_;
	my $stats = &share( {} );

	my $ssrc = $packet->ssrc();
	$stats->{'ssrc'}=$ssrc;
	$stats->{'seq_num'}=$packet->seq_num();
	$stats->{'src_ip'}=$packet->source_ip();
	
	$stats->{'total_packets'}=0;
	$stats->{'total_bytes'}=0;
	$stats->{'total_lost'}=0;
	$stats->{'total_late'}=0;
	$stats->{'total_dup'}=0;
	
	reset_stats($stats);

	return $stats;
}

sub reset_stats {
	my ($stats) = @_;

	$stats->{'packets'}=0;	# Packets in past second
	$stats->{'bytes'}=0;	# Bytes in past second
	$stats->{'lost'}=0;		# Packets lost in past second
	$stats->{'late'}=0;		# Out of order
	$stats->{'dup'}=0;		# Duplicated packets in past second

}
