package Slim::Plugin::VersaRadio::Radios::FrequenceJazz;

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

	fullName=>'Fréquence Jazz',

	# the name of the .pm of the module
	name => 'FrequenceJazz',

	# the regexp to detect the stream that this module applies to
	urlStreamRegexp => qr/(?:frequencejazz-high\.mp3)/,

	firstURL => 'http://www.frequencejazz.com/winradio/chansonEnCours.php',

	refererFirstURL => 'http://www.frequencejazz.com/index.php',
	
};

our $radioVars = {};


# the method is called when we have an http answer
sub parseFirstUrlContent {
	my $class = shift;
	my $content = shift;

	my ($artwork, $artist, $title) = split(/#/,$content);
	$artwork =~ s/.*(http:\/\/.*)/$1/g;
	if( $artwork =~ /http:\/\/www\.jazzradio\.fr\/images\/pochette\.jpg/g ) {
		undef($artwork);
	}
	return {
		artist   =>  $artist,
#		album    =>  $3,
		title    =>  $title, 
#		year     =>  $4,
		cover    =>  $artwork
	};
}


1;