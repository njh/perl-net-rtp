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
$VERSION="0.02";

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
	if (defined $data) {
	
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

Net::RTP - Pure Perl Real-time Transport Protocol (RFC3550)

=head1 SYNOPSIS

  use Net::RTP;

  my $rtp = new Net::RTP();

=head1 DESCRIPTION




=head1 SEE ALSO

L<http://www.ietf.org/rfc/rfc3550.txt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-rtp@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you will automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Nicholas Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 University of Southampton

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.005 or, at
your option, any later version of Perl 5 you may have available.


=cut
