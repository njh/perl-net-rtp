#!/usr/bin/perl
#

use Module::Build;
use strict;


# Create the Build script
my $build = Module::Build->new
(
	module_name => 'Net::RTP',
	license => 'perl',
	build_requires => {
		'Module::Build' => '0.20'
	},
	script_files => [
		'tools/rtpdump.pl',
		'tools/rtpstats.pl',
		'tools/rtpsend-pcmu.pl',
		'tools/rtplosslog.pl',
	],
	requires => {
		'Test::More' => 0,
	},
	
	create_makefile_pl => 'passthrough',
	
	recommends => {
		'IO::Socket::Multicast6' => '0.02',
		'IO::Socket::Multicast' => '1.05',
		'IO::Socket::INET6' => '2.51',
		'IO::Socket::INET' => '1.20',
	},
);

$build->create_build_script;
