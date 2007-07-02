#!/usr/bin/perl
#
# Net::RTP example file
#
# Displays packet arrival timing
#

use Net::RTP;
use Data::Dumper;
use Time::HiRes;
use strict;


my $DEFAULT_PORT = 5004;	# Default RTP port


# Create RTP socket
my ($address, $port) = @ARGV;
usage() unless (defined $address);
$port = $DEFAULT_PORT unless (defined $port);

my $rtp = new Net::RTP(
		LocalPort=>$port,
		LocalAddr=>$address
) || die "Failed to create RTP socket: $!";


my $count = 0;
while (my $packet = $rtp->recv()) {

	# Parse the packet
	printf("COUNT=%d".$count);
	printf(", SRC=[%s]", $packet->source_ip());
	printf(", LEN=%d", $packet->payload_size());
	printf(", PT=%d", $packet->payload_type());
	printf(", SEQ=%d", $packet->seq_num());
	printf(", TIME=%d", $packet->timestamp());
	printf("\n");

	$count++;
}


sub usage {
	print "usage: rtptimer.pl <address> [<port>]\n";
	exit -1;
}


__END__

=pod

=head1 NAME

rtptimer.pl - Displays arrival times of incoming RTP packet headers

=head1 SYNOPSIS

rtptimer.pl <address> [<port>]


=head1 SEE ALSO

L<Net::RTP>

L<Net::RTP::Packet>

L<http://www.iana.org/assignments/rtp-parameters>


=head1 BUGS

Unicast addresses aren't currently detected and fail when trying to join 
multicast group.

=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 University of Southampton

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut
