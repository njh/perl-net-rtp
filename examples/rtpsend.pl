#!/usr/bin/perl
#
# Net::RTP example file
#
# Send a file containing PCMU audio 
# to specified address and port
#
# File can be generated using:
# sox input.aiff -t raw -b -U -c 1 -r 8000 output.raw
#

use Net::RTP;
use Time::HiRes qw/ usleep /; 
use strict;


my $PAYLOAD_TYPE = 0;		# u-law
my $PAYLOAD_SIZE = 160;		# 160 samples per packet


# Make STDOUT unbuffered
$|=1;

# Check the number of arguments
if ($#ARGV != 2) {
	print "usage: rtpsend.pl filename dest_addr dest_port\n";
	exit;
}

# Get the command line parameters
my ($filename, $address, $port ) = @ARGV;
print "Input Filename: $filename\n";
print "Remote Address: $address\n";
print "Remote Port: $port\n";



# Create RTP socket
my $rtp = new Net::RTP(
		PeerPort=>$port,
		PeerAddr=>$address,
);


# Create RTP packet
my $packet = new Net::RTP::Packet();
$packet->payload_type( $PAYLOAD_TYPE );


# Open the input file
open(PCMU, $filename) or die "Failed to open input file: $!";

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


