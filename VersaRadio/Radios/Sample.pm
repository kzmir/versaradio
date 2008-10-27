package Plugins::VersaRadio::Radios::Sample;

#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$
#
# Get custom meta data from web radio websites

use strict;
use warnings;
use version; our $VERSION = qw('0.0.1);

use base qw(Plugins::VersaRadio::Radios::VersaRadioBase);



our $radioParams = {

	fullName=>'Test Module',

	# the name of the .pm of the module
	name => 'Sample',

	# only needed if icon name is different from ""plugins/RadioPlus/html/images/{name}.png"
	icon => 'TSF.png', 

	# the regexp to detect the stream that this module applies to
#	urlStreamRegexp => qr/(?:squeezenetwork\.com.*\/mp3tunes|mp3tunes\.com\/)/,
	urlStreamRegexp => qr/(?:tsfjazz-high\.mp3)/,

	firstURL => 'http://www.tsfjazz.com/getSongInformations.php',

	refererFirstURL => 'http://www.tsfjazz.com/accueil.php',

	secondURL => 'http://www.tsfjazz.com/getSongInformations.php',

	refererSecondURL => 'http://www.tsfjazz.com/accueil.php',
	
# Specific params for the module
	specificData => 'Present'
};

our $radioVars = {};


# the method is called when we have an http answer
sub parseFirstUrlContent {
	my $class = shift;
	my $content = shift;
	my ($artist, $title) = split(/\|/,$content);
	#die "track: $1 - artist: $2 - album: $3 - year: $4";
	return {
		artist   =>  $artist,
#		album    =>  $3,
#		title    =>  $title, 
#		year     =>  $4,
#		cover    =>  'plugins/VersaRadio/html/images/TSF.png',
#		icon     =>  'plugins/VersaRadio/html/images/TSF.png'
	};
}

sub parseSecondUrlContent {
	my $class = shift;
	my $content = shift;

	my ($artist, $title) = split(/\|/,$content);
	#die "track: $1 - artist: $2 - album: $3 - year: $4";
	return {
#		artist   =>  $artist,
		title    =>  $title, 
#		album    =>  $3,
#		year     =>  $4,
#		cover    =>  'plugins/VersaRadio/html/images/TSF.png',
#		icon     =>  'plugins/VersaRadio/html/images/TSF.png'
	};
}

1;