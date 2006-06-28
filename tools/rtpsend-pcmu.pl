#!/usr/bin/perl
#
# Send an audio file to specified address and port
# using PCM u-law payload type (0)
#
# Requires 'sox' command to help transcode the audio file
#

use Net::RTP;
use Time::HiRes qw/ usleep /; 
use strict;

my $DEFAULT_PORT = 5004;	# Default RTP port
my $DEFAULT_TTL = 2;		# Default Time-to-live
my $PAYLOAD_TYPE = 0;		# u-law
my $PAYLOAD_SIZE = 160;		# 160 samples per packet


# Get the command line parameters
my ($filename, $address, $port, $ttl ) = @ARGV;
usage() unless (defined $filename);
usage() unless (defined $address);
$port=$DEFAULT_PORT unless (defined $port);
$ttl=$DEFAULT_TTL unless (defined $ttl);

print "Input Filename: $filename\n";
print "Remote Address: $address\n";
print "Remote Port: $port\n";
print "Multicast TTL: $ttl\n";
print "Payload type: $PAYLOAD_TYPE\n";
print "Payload size: $PAYLOAD_SIZE bytes\n";



# Create RTP socket
my $rtp = new Net::RTP(
		PeerPort=>$port,
		PeerAddr=>$address,
);

# Set the TTL
$rtp->mcast_ttl( $ttl );

# Create RTP packet
my $packet = new Net::RTP::Packet();
$packet->payload_type( $PAYLOAD_TYPE );


# Open the input file (via sox)
open(PCMU, "sox '$filename' -t raw -b -U -c 1 -r 8000 - |") 
or die "Failed to open input file: $!";

my $data;
while( my $read = read( PCMU, $data, $PAYLOAD_SIZE ) ) {

	# Set payload, and increment sequence number and timestamp
	$packet->payload($data);
	$packet->seq_num_increment();
	$packet->timestamp_increment( $PAYLOAD_SIZE );
	
	my $sent = $rtp->send( $packet );
	#print "Sent $sent bytes.\n";
	
	# This isn't a very good way of timing it
	# but it kinda works
	usleep( 1000000 * $PAYLOAD_SIZE / 8000 );
}

close( PCMU );


sub usage {
	print "usage: rtpsend-pcmu.pl <filename> <dest_addr> [<dest_port>] [<ttl>]\n";
	exit -1;
}
