#!/usr/bin/perl
#
# Net::RTP example file
#
# Display details of RTP packets recieved
#

use Net::RTP;
use Data::Dumper;
use strict;


my $DEFAULT_PORT = 5004;	# Default RTP port


# Create RTP socket
my ($address, $port) = @ARGV;
usage() unless (defined $address);
$port = $DEFAULT_PORT unless (defined $port);

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


sub usage {
	print "usage: rtpdump.pl <address> <port>\n";
	exit -1;
}


__END__

=pod

=head1 NAME

rtpdump.pl - Parse and display incoming RTP packet headers

=head1 SYNOPSIS

  rtpdump.pl <address> [<port>]

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
