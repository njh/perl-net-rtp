#!/usr/bin/perl
#

use Module::Build;
use strict;


# Create the Build script
my $build = Module::Build->new
(
	module_name => 'Net::RTP',
	license => 'gpl',
	build_requires => {
		'Module::Build' => '0.20'
	},
	requires => {
		'Test' => '1.00',
	},
	create_makefile_pl => 'passthrough',
);

$build->create_build_script;
