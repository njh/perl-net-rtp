
use strict;
use Test;


# use a BEGIN block so we print our plan before Net::oRTP is loaded
BEGIN { plan tests => 3 }

# load Net::oRTP
use Net::RTP;

# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing Net::RTP version $Net::RTP::VERSION\n";

# Module has loaded sucessfully 
ok(1);


# Create a send/receive object
my $rtp = new Net::RTP();
ok( defined $rtp );

exit;

