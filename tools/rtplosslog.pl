#!/usr/bin/perl
#
# Log RTP packet loss
#

use 5.008;             # 5.8 required for stable threading
use strict;
use warnings;
use threads;
use threads::shared;

use Net::RTP;
use Time::Local;
use Time::HiRes qw/ sleep /;
use Data::Dumper;


my $IP_HEADER_SIZE = 28; 	# 20 bytes of IPv4 header and 8 bytes of UDP header


# Make STDOUT unbuffered
$|=1;

# Check the number of arguments
if ($#ARGV != 1) {
	print "usage: rtplosslog.pl <address> <port> [<src_ip>]\n";
	exit;
}

# Create RTP socket
my ($address, $port, $src_ip) = @ARGV;
my $rtp = new Net::RTP(
		LocalPort=>$port,
		LocalAddr=>$address,
		ReuseAddr=>1
);

# Join the multicast group
$rtp->mcast_add($address) || die "Couldn't join multicast group: $!\n";


# Shared variable used for collecting statistics
our $stats = &share( {} );
reset_stats($stats);
threads->new( \&display_stats );


while (1) {

	my $packet = $rtp->recv();
	die "Failed to recieve packet: $!" unless (defined $packet);
	
	# No chosen source IP yet?
	my $src = $packet->source_ip();
	unless (defined $src_ip) {
		print STDERR "# Using $src as source IP address.\n"; 
		$src_ip = $src;
	}
	next if ($src ne $src_ip);
	
	# First packet ?
	unless (defined $stats->{'first_packet'}) {
		$stats->{'first_packet'}=time();
		$stats->{'ssrc'}=$packet->ssrc();
		$stats->{'seq_num'}=$packet->seq_num();
	}
	
	# Verfify Source Identifier
	if ($stats->{'ssrc'} ne $packet->ssrc()) {
		warn "# SSRC of packets from '$src' has changed.\n";
		$stats->{'ssrc'} = $packet->ssrc();
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

	# Wait until the first second of a minute
	my $start = start_of_next_minute();
	print STDERR "# Waiting until start of next minute.\n";
	sleep( $start-time() );
	print STDERR "# Timestamp\tPackets\tBytes\tLost\tLate\n";

	my $next = $start+60;
	
	while (1) {
		# Set everything back to Zero
		reset_stats( $stats );
		
		# Wait until time for next check
		sleep($next-time()) if ($next-time()>0);

		printf("%d\t%d\t%d\t%d\t%d\n", time(), $stats->{'packets'}, $stats->{'bytes'}, $stats->{'lost'}, $stats->{'late'} );
		
		# Report again in 1 minute
		$next += 60.0;
	}
	
}

sub start_of_next_minute {
	my ($sec,$min,$hour,$mday,$mon,$year) = gmtime();
	$sec=0;
	$min++;
	return timegm($sec,$min,$hour,$mday,$mon,$year);
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

rtplosslog.pl - Display packet loss for a RTP session each minute

=head1 SYNOPSIS

  rtplosslog.pl <address> <port> [<src_ip>]

=head1 DESCRIPTION

  Foo bar

=head1 AUTHOR

Nicholas Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 University of Southampton

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.008 or,
at your option, any later version of Perl 5 you may have available.

=cut

