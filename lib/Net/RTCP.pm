package Net::RTCP;

################
#
# Net::RTCP: Pure Perl Real-time Transport Control Protocol (RFC3550)
#
# Nicholas J Humfrey
# njh@cpan.org
#

use Net::RTP;
use strict;
use Carp;



use vars qw/$VERSION @ISA/;
@ISA = ('Net::RTP');
$VERSION="0.01";



#
## This class' implementation is in RTP.pm ##
#



1;

__END__

=pod

=head1 NAME

Net::RTCP - Send and receive RTCP packets (RFC3550)

=head1 SYNOPSIS

  use Net::RTCP;

  my $rtcp = new Net::RTCP( LocalPort=>5171, LocalAddr=>'233.122.227.171' );
  
  my $packet = $rtcp->recv();
  print "Payload type: ".$packet->payload_type()."\n";
  

=head1 DESCRIPTION

The C<Net::RTCP> module subclasses L<IO::Socket::Multicast6> to enable
you to manipulate multicast groups. The multicast additions are 
optional, so you may also send and recieve unicast packets.

=over

=item $rtcp = new Net::RTCP( [LocalAdrr=>$addr, LocalPort=>$port,...] )

The new() method is the constructor for the Net::RTCP class. 
It takes the same arguments as L<IO::Socket::INET>, however 
the B<Proto> argument defaults to "udp", which is more appropriate for RTCP.

The Net::RTCP super-class used will depend on what is available on your system
it will try and use one of the following (in order of preference) :

	IO::Socket::Multicast6 (IPv4 and IPv6 unicast and multicast)
	IO::Socket::Multicast (IPv4 unicast and multicast)
	IO::Socket::INET6 (IPv4 and IPv6 unicast)
	IO::Socket::INET (IPv4 unicast)

If LocalAddr looks like a multicast address, then Net::RTCP will automatically 
try and join that multicast group for you.


=item my $packet = $rtcp->recv( [$size] )

Blocks and waits for an RTCP packet to arrive on the UDP socket.
The read C<$size> defaults to 2048 which is usually big enough to read
an entire RTCP packet (as it is advisable that packets are less than 
the Ethernet MTU).

Returns a C<Net::RTCP::Packet> object or B<undef> if there is a problem.


=item $rtcp->send( $packet )

Send a L<Net::RTCP::Packet> from out of the RTCP socket. 
The B<PeerPort> and B<PeerAddr> should be defined in order to send packets. 
Returns the number of bytes sent, or the undefined value if there is an error.

=item $rtcp->superclass()

Returns the name of the super-class that Net::RTCP chose to use.

=back


=head1 SEE ALSO

L<Net::RTCP::Packet>

L<IO::Socket::Multicast6>

L<IO::Socket::INET6>

L<IO::Socket::Multicast>

L<IO::Socket::INET>

L<http://www.ietf.org/rfc/rfc3550.txt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-rtp@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you will automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 University of Southampton

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.005 or, at
your option, any later version of Perl 5 you may have available.


=cut
