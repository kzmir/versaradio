package Slim::Plugin::VersaRadio::Radios::TSF;

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


use base qw(Slim::Plugin::VersaRadio::Radios::VersaRadioBase);



our $radioParams = {

	fullName=>'TSF Jazz',

	# the name of the .pm of the module
	name => 'TSF',

	# the regexp to detect the stream that this module applies to
	urlStreamRegexp => qr/(?:tsfjazz-high\.mp3)/,

	firstURL => 'http://www.tsfjazz.com/getSongInformations.php',

	refererFirstURL => 'http://www.tsfjazz.com/accueil.php',
	
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
		title    =>  $title, 
	};
}


1;