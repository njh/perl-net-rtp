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


my $IP_HEADER_SIZE = 28; 	# 20 bytes of IPv4 header and 8 bytes of UDP header


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
	
	# Verfify Source Address
	if ($stats->{'source_ip'} ne $packet->source_ip()) {
		warn "Source IP of SSRC of  '$ssrc' has changed.\n";
		$stats->{'source_ip'} = $packet->source_ip();
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
			$stats->{'lost'}+=($packet->seq_num()-$stats->{'seq_num'});
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

		my ($sec, $min, $hour) = localtime();
		print_key() if ($sec==0);
		
		foreach my $stats ( values %$all_stats ) {
			$stats->{'total_packets'}+=$stats->{'packets'};
			$stats->{'total_bytes'}+=$stats->{'bytes'};
			$stats->{'total_lost'}+=$stats->{'lost'};
			$stats->{'total_late'}+=$stats->{'late'};
			
			printf("%2.2d:%2.2d:%2.2d  %3d  %3d  %3d  %6d | %5d  %4d  %4d %6d  %4d  %s\n",
			$hour, $min, $sec, 
			$stats->{'packets'}, $stats->{'lost'}, $stats->{'late'}, $stats->{'bytes'},
			$stats->{'total_packets'}, $stats->{'total_lost'}, $stats->{'total_late'},
			$stats->{'total_bytes'}/1024, 
			(($stats->{'total_bytes'}*8)/1000)/(time()-$stats->{'first_packet'}), 
			$stats->{'source_ip'}, );
			
			reset_stats( $stats );
		}

		# Report again in 1 second
		$next += 1.0;
	}
	
}

sub print_key {
	print "Time     Pkts Lost Late   Bytes |  Pkts  Lost  Late     kB  kbps  Sender\n";
}

sub init_stats {
	my ($packet) = @_;
	my $stats = &share( {} );

	$stats->{'ssrc'}=$packet->ssrc();
	$stats->{'seq_num'}=$packet->seq_num();
	$stats->{'source_ip'}=$packet->source_ip();
	$stats->{'first_packet'}=time();
	
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




__END__

=pod

=head1 NAME

rtpstats.pl - Displays packet loss statistics for an RTP session

=head1 SYNOPSIS

  rtpstats.pl <address> [<port>]

=head1 DESCRIPTION

  Foo bar

=head1 AUTHOR

Nicholas Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 University of Southampton

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut

