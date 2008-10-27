###############################################################################
#   $URL$
#   $Rev$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$
###############################################################################
# VersaRadio, (c) Robin V.    
#                  robinsp+versaradio (à) gmail  .com
# Source is under Mozilla Public License 1.1 ( http://www.mozilla.org/MPL/ )
#
# Versa Radio is a plugin for slimdevices Squeezcenter that permits retrieval 
# of custom meta data from web radio websites
#
###############################################################################
# FrequenceJazz.pm is a module of Versa Radio that retrieves song information 
# for french Jazz radio "Frequence Jazz".
# Website: http://www.jazzradio.fr/
# Stream: http://broadcast.infomaniak.ch/frequencejazz-high.mp3  

package Plugins::VersaRadio::Radios::FrequenceJazz;

use strict;
use warnings;
use version; our $VERSION = qw('0.0.1);


use base qw(Plugins::VersaRadio::Radios::VersaRadioBase);



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