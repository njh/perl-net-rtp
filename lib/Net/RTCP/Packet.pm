package Net::RTCP::Packet;

################
#
# Net::RTCP::Packet: Pure Perl RTCP network packet object (RFC3550)
#
# Nicholas J Humfrey, njh@cpan.org
#

use strict;
use Carp;

use vars qw/$VERSION/;
$VERSION="0.01";


sub new {
    my $class = shift;
	my ($bindata) = @_;

	# Store parameters
    my $self = {
		'sdes' => {},
		'reports' => {},
		'senders' => {},
# 		'APP' => {},
#		'BYE' => {},
    };
    bless $self, $class;

	# Decode binary packet?
	if (defined $bindata) {
		$self->decode( $bindata );
	}
	
	return $self;
}


sub _parse_header {
	my $self = shift;
	my ($bindata) = @_;

	# Decode the binary header (network endian)
	my ($vpc, $type, $length) = unpack( 'CCn', $bindata );
	$length = $length*4;

	# We only know how to parse version 2 of RTCP
	my $version = ($vpc & 0xC0) >> 6;
	if ($version != 2) {
		carp "Warning: unsupported RTCP packet version ($version)";
		return (0);
	}
	
	# Check that the padding bit is set to zero
	my $padding = ($vpc & 0x20) >> 5;
	if ($padding != 0) {
		carp "Warning: padding bit is not set to zero";
		return (0);
	}

	my $count = ($vpc & 0x1F);
	my $payload = substr( $bindata, 4, $length );

	return ($type, $count, $length, $payload);
}


sub decode {
	my $self = shift;
	my ($bindata) = @_;
	

	while( length($bindata) ) {
	
		# Parse the subpacket header
		my ($type, $count, $length, $payload) = $self->_parse_header( $bindata );
		#printf("type=%d count=%d length=%d\n", $type, $count, $length);

		# Check the subpacket type
		if ($type==200) { $self->_decode_SR( $payload, $count ); }
		elsif ($type==201) { $self->_decode_RR( $payload, $count ); }
		elsif ($type==202) { $self->_decode_SDES( $payload, $count ); }
		elsif ($type==203) { $self->_decode_BYE( $payload, $count ); }
		elsif ($type==204) { $self->_decode_APP( $payload, $count ); }
		else {
			warn("Unsupported RTCP packet type: ".$type);
		}
		
		# Move on to the next sub-packet
		$bindata = substr( $bindata, $length+4 );
	}


	# Undefine the source IP and port
	# (it is unknown and set elsewhere)
	$self->{'source_ip'} = undef;
	$self->{'source_port'} = undef;
	
	# Success
	return 1;
}

sub _get_sdes_type_name {
	my ($sdes) = @_;
	
	return 'END' if ($sdes==0);
	return 'CNAME' if ($sdes==1);
	return 'NAME' if ($sdes==2);
	return 'EMAIL' if ($sdes==3);
	return 'PHONE' if ($sdes==4);
	return 'LOC' if ($sdes==5);
	return 'TOOL' if ($sdes==6);
	return 'NOTE' if ($sdes==7);
	return 'PRIV' if ($sdes==8);
	return $sdes;
	
}


sub _decode_reports {
	my $self = shift;
	my ($bindata, $count, $reporter_ssrc) = @_;
	
	# Parse each report
	for(my $n=0; $n<$count; $n++) {
		# The SSRC being reported on
		my $ssrc = sprintf('%x',unpack("N", $bindata));
		$bindata = substr($bindata, 4);
		
		# Packet loss
		my ($fact_lost, $cumul_lost_high, $cumul_lost_low) = unpack("CCn", $bindata);
		$bindata = substr($bindata, 4);
		$self->{'reports'}->{$reporter_ssrc}->{$ssrc}->{'frac_lost'} = $fact_lost;
		$self->{'reports'}->{$reporter_ssrc}->{$ssrc}->{'cumul_lost'} = 
			(($cumul_lost_high&0xFF)<<16)+$cumul_lost_low;

		# Sequence number, jitter and delay
		my ($seq_num, $jitter, $last_sr, $sr_delay) = unpack("NNNN", $bindata);
		$bindata = substr($bindata, 16);
		$self->{'reports'}->{$reporter_ssrc}->{$ssrc}->{'seq_num'} = $seq_num;
		$self->{'reports'}->{$reporter_ssrc}->{$ssrc}->{'jitter'} = $jitter;
		$self->{'reports'}->{$reporter_ssrc}->{$ssrc}->{'last_sr'} = $last_sr;
		$self->{'reports'}->{$reporter_ssrc}->{$ssrc}->{'sr_delay'} = $sr_delay;
	}

	
	## Check for left-over bytes
	if (length($bindata)) {
		warn length($bindata)." bytes left over, after decoding reports";
	}
}


sub _decode_SR {
	my $self = shift;
	my ($bindata, $count) = @_;
	
	# Get the SSRC of the sender
	my $ssrc = sprintf('%x',unpack("N", $bindata));
	$bindata = substr($bindata, 4);

	# 20-byte Sender Report 
	my ($ntp_high, $ntp_low, $rtp_ts, $packets, $octets) = unpack("NNNNN", $bindata);
	$bindata = substr($bindata, 20);

	# Store in hash
	$self->{'senders'}->{$ssrc}->{'ntp_high'}=$ntp_high;	# perl doesn't support 64bit numbers?
	$self->{'senders'}->{$ssrc}->{'ntp_low'}=$ntp_low;
	$self->{'senders'}->{$ssrc}->{'rtp_ts'}=$rtp_ts;
	$self->{'senders'}->{$ssrc}->{'pkts_sent'}=$packets;
	$self->{'senders'}->{$ssrc}->{'octets_sent'}=$octets;
	

	# Now parse the report blocks
	$self->_decode_reports( $bindata, $count, $ssrc );
}

sub _decode_RR {
	my $self = shift;
	my ($bindata, $count) = @_;
	
	# Get the SSRC of the reporter
	my $ssrc = sprintf('%x',unpack("N", $bindata));
	$bindata = substr($bindata, 4);

	# Parse the report blocks
	$self->_decode_reports( $bindata, $count, $ssrc );
}

sub _decode_SDES {
	my $self = shift;
	my ($bindata, $count) = @_;
	
	# Parse each SSRC
	for(my $s=0; $s<$count; $s++) {
		# Get the SSRC
		my $ssrc = sprintf('%x',unpack("N", $bindata));
		$bindata = substr($bindata, 4);

		while( length($bindata) ) {
			# Get the type
			my ($typenum) = unpack("C", $bindata);
			my $type = _get_sdes_type_name( $typenum );
			$bindata = substr( $bindata, 1 );
			last if ($type eq 'END');

			# Then get the length
			my ($len) = unpack("C", $bindata);
			$bindata = substr( $bindata, 1 );
			
			# FInally the value
			my $value = substr( $bindata, 0, $len );
			$bindata = substr( $bindata, $len );
			
			# Store the type/value
			$self->{'sdes'}->{$ssrc}->{$type}=$value;
		}
	}
	
}

sub _decode_APP {
	my $self = shift;
	my ($bindata, $count) = @_;
	
	#printf("APP ssrc count: %d\n", $count);
	warn "RTCP packet type 'APP' isn't supported yet";



}

sub _decode_BYE {
	my $self = shift;
	my ($bindata, $count) = @_;
	
	#printf("BYE ssrc count: %d\n", $count);
	warn "RTCP packet type 'BYE' isn't supported yet";


}

sub encode {
	my $self = shift;
	my $bindata = '';
	

	# Store the size of the encoded packet
	#$self->{'size'} = length( $bindata );
	
	return $bindata;
}


1;

__END__

=pod

=head1 NAME

Net::RTCP::Packet - RTCP network packet object (RFC3550)

=head1 SYNOPSIS

  use Net::RTCP::Packet;
  
  my $packet = new Net::RTCP::Packet();
  $packet->foo(  );
  $packet->bar(  );

=head1 DESCRIPTION

Net::RTCP::Packet is a collection of a number of sub RTCP packets.

=over

=item $packet = new Net::RTCP::Packet( [$binary] )

The new() method is the constructor for the C<Net::RTCP::Packet> class.



=item $packet->foo( [$value] )

Does foo

=item $packet->bar( [$value] )

Does bar


=back

=head1 SEE ALSO

L<Net::RTCP>

L<http://www.ietf.org/rfc/rfc3550.txt>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-rtp@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you will automatically
be notified of progress on your bug as I make changes.


=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 University of Southampton

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.005 or, at
your option, any later version of Perl 5 you may have available.


=cut
