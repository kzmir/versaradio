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
# FIP.pm is a module of Versa Radio that retrieves song information and album
# cover for french national radio FIP.
# Website: http://fipradio.com/
# Stream: http://mp3.live.tv-radio.com/fip/all/fiphautdebit.mp3 

package Plugins::VersaRadio::Radios::FIP;

use strict;
use warnings;
use version; our $VERSION = qw('0.0.1);
use Data::Dumper;

use base qw(Plugins::VersaRadio::Radios::VersaRadioBase);



our $radioParams = {

	fullName=>'FIP Radio',

	# the name of the .pm of the module
	name => 'FIP',

	# the regexp to detect the stream that this module applies to
#	urlStreamRegexp => qr/(?:squeezenetwork\.com.*\/mp3tunes|mp3tunes\.com\/)/,
	urlStreamRegexp => qr/(?:fiphautdebit\.mp3)/,

	firstURL => 'http://players.tv-radio.com/radiofrance/metadatas/fipRSS_a_lantenne.html',

	refererFirstURL => 'http://players.tv-radio.com/radiofrance/playerfip.php',

	secondURL => 'http://players.tv-radio.com/radiofrance/pochettes/fipRSS.html',

	refererSecondURL => 'http://players.tv-radio.com/radiofrance/playerfip.php',
	
# Specific params for the module
	specificData => 'Present'
};

our $radioVars = {};


# the method is called when we have an http answer
sub parseFirstUrlContent {
	my $class = shift;
	my $content = shift;

	if( $content =~ m!<b>([^<]*)</b></font><br><font face="arial" size="1" color="#ffffff"><b>([^<]*?)(?: - )?([^-<]*?)( [0-9]*)?</b>!mi ) {
	#die "track: $1 - artist: $2 - album: $3 - year: $4";
	return {
			artist   =>  $2,
			album    =>  $3,
			title    =>  $1, 
			year     =>  $4,
		};
	}
	return { title => 'No track data found.'}
}

sub parseSecondUrlContent {
	my $class = shift;
	my $content = shift;

	if( $content =~ m!<img border="0" src="([^"]*)" alt="pochette"!mi ) {
	#die "coverurl: $1 ";
		return { cover => $1 };
	} else {
		return { cover => undef };
	}
}

1;