package Net::RTP;

################
#
# Net::RTP: Pure Perl Real-time Transport Protocol (RFC3550)
#
# Nicholas J Humfrey
# njh@cpan.org
#

use IO::Socket::Multicast;
use Net::RTP::Packet;
use Socket;
use strict;
use Carp;

use vars qw/$VERSION @ISA/;

@ISA = qw/IO::Socket::Multicast/;
$VERSION="0.03";

sub new {
    my $class = shift;
	return $class->SUPER::new(@_);
}

sub recv {
	my $self=shift;
	my ($size) = @_;
	
	# Default read size
	$size = 2048 unless (defined $size);
	
	# Receive a binary packet
	my $data = undef;
	my $sockaddr_in = $self->SUPER::recv($data, $size);
	if (defined $data and $data ne '') {
	
		# Parse the packet
		my $packet = new Net::RTP::Packet( $data );
		
		# Store the source address
		if ($self->sockdomain == &AF_INET 
		     and $sockaddr_in ne ''
		     and defined $packet)
		{
			my ($port,$addr) = unpack_sockaddr_in($sockaddr_in);
			$packet->{'source_ip'} = inet_ntoa($addr);
			$packet->{'source_port'} = $port;
		}
		
		return $packet;
	}
	
	return undef;
}

sub send {
	my $self=shift;
	my ($packet) = @_;
	
	if (!defined $packet or ref($packet) ne 'Net::RTP::Packet') {
		croak "Net::RTP->send() takes a Net::RTP::Packet as its only argument";
	}
	
	# Build packet and send it
	my $data = $packet->encode();
	return $self->SUPER::send($data);
}

sub DESTROY {
    my $self=shift;
	return $self->SUPER::DESTROY(@_);
}



1;

__END__

=pod

=head1 NAME

Net::RTP - Send and recieve RTP packets (RFC3550)

=head1 SYNOPSIS

  use Net::RTP;

  my $rtp = new Net::RTP( LocalPort=>5170, LocalAddr=>'233.122.227.171' );
  $rtp->mcast_add('233.122.227.171');
  
  my $packet = $rtp->recv();
  print "Payload type: ".$packet->payload_type()."\n";
  

=head1 DESCRIPTION

The C<Net::RTP> module subclasses L<IO::Socket::Multicast> to enable
you to manipulate multicast groups. The multicast additions are 
optional, so you may also send and recieve unicast packets.

=over

=item $rtp = new Net::RTP( [LocalPort=>$port,...] )

The new() method is the constructor for the Net::RTP class. 
It takes the same arguments as L<IO::Socket::Multicast> and L<IO::Socket::INET>.
As with L<IO::Socket::Multicast> the B<Proto> argument defaults
to "udp", which is more appropriate for RTP.

To create a UDP socket suitable for sending outgoing RTP packets, 
call new() without no arguments.  To create a UDP socket that can also receive
incoming RTP packets on a specific port, call new() with
the B<LocalPort> argument.

If you plan to run the client and server on the same machine, you may
wish to set the L<IO::Socket> B<ReuseAddr> argument to a true value.
This allows multiple multicast sockets to bind to the same address.


=item my $packet = $rtp->recv( [$size] )

Blocks and waits for an RTP packet to arrive on the UDP socket.
The read C<$size> defaults to 2048 which is usually big enough to read
an entire RTP packet (as it is advisable that packets are less than 
the Ethernet MTU).

Returns a C<Net::RTP::Packet> object or B<undef> if there is a problem.


=item $rtp->send( $packet )

Send a L<Net::RTP::Packet> from out of the RTP socket. 
The B<PeerPort> and B<PeerAddr> should be defined in order to send packets. 
Returns the number of bytes sent, or the undefined value if there is an error.

=back


=head1 SEE ALSO

L<Net::RTP::Packet>

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
