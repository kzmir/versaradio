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
# TSF.pm is a module of Versa Radio that retrieves song information 
# for french Jazz radio "TSF Jazz".
# Website: http://www.tsfjazz.com/
# Stream: http://broadcast.infomaniak.net/tsfjazz-high.mp3  

package Plugins::VersaRadio::Radios::TSF;

use strict;
use warnings;
use version; our $VERSION = qw('0.0.1);


use base qw(Plugins::VersaRadio::Radios::VersaRadioBase);

our $radioVars = {};

our $radioParams = {

	fullName=>'TSF Jazz',

	# the name of the .pm of the module
	name => 'TSF',

	# the regexp to detect the stream that this module applies to
	urlStreamRegexp => qr/(?:tsfjazz-high\.mp3)/,

	firstURL => 'http://www.tsfjazz.com/getSongInformations.php',

	refererFirstURL => 'http://www.tsfjazz.com/accueil.php',
	
};



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