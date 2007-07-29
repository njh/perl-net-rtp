#!/usr/bin/perl
#
# Net::RTCP example file
#
# Display details of RTCP packets recieved
#

use Net::RTCP;
use Data::Dumper;
use strict;


my $DEFAULT_PORT = 5005;	# Default RTCP port


# Create RTCP socket
my ($address, $port) = @ARGV;
usage() unless (defined $address);
$port = $DEFAULT_PORT unless (defined $port);

my $rtcp = new Net::RTCP(
		LocalPort=>$port,
		LocalAddr=>$address
) || die "Failed to create RTCP socket: $!";


my $count = 0;
while (my $packet = $rtcp->recv()) {

	print Dumper( $packet );
	
	$count++;
}


sub usage {
	print "usage: rtcpdump.pl <address> [<port>]\n";
	exit -1;
}


__END__

=pod

=head1 NAME

rtcpdump.pl - Parse and display incoming RTCP packet headers

=head1 SYNOPSIS

rtcpdump.pl <address> [<port>]

=head1 DESCRIPTION

rtcpdump.pl displays the RTCP header of packets sent to a multicast group.
If no port is specified, then port 5004 is assumed.

For each packet recieved, the following fields are displayed:

=over

=item

B<COUNT> - the number of packets recieved.

=item

B<SRC> - the source IP address and port.

=item

B<LEN> - the length of the payload (in bytes).

=item

B<PT> - the payload type number.

=item

B<SSRC> - the source indentifier unique to this session.

=item

B<SEQ> - the packet's contiguous sequence number.

=item

B<TIME> - the packet's timestamp (based on payload clock rate).

=item

B<MARK> - displayed if the packet's marker bit is set.

=back

=head1 SEE ALSO

L<Net::RTCP>

L<Net::RTCP::Packet>

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
