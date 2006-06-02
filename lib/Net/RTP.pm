package Net::RTP;

################
#
# Net::RTP: Pure Perl Real-time Transport Protocol (RFC3550)
#
# Nicholas Humfrey
# njh@ecs.soton.ac.uk
#

use strict;
use Carp;

use vars qw/$VERSION/;

$VERSION="0.02";

sub new {
    my $class = shift;

	# Store parameters
    my $self = {

    };


    bless $self, $class;
	return $self;
}


sub DESTROY {
    my $self=shift;
    

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

Nicholas Humfrey, njh@ecs.soton.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 University of Southampton

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.005 or, at
your option, any later version of Perl 5 you may have available.


=cut
