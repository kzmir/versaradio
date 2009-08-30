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
# Plugin.pm is the module called by SqueezeCenter at startup, its goal is to
# register the differente Radios::xxx modules and to initialize the logger

package Plugins::VersaRadio::Plugin;

use strict;

use warnings;
use version; our $VERSION = qw('0.0.1);

use base qw(Slim::Plugin::OPMLBased);

use Slim::Formats::RemoteMetadata;
use Slim::Utils::Prefs;

our $log = Slim::Utils::Log->addLogCategory({
        'category'     => 'plugin.versaradio',
		'defaultLevel' => $ENV{RADIOPLUS_DEV} ? 'DEBUG' : 'ERROR',        
		'description'  => 'PLUGIN_RADIO_PLUS_MODULE_NAME',
});

my $prefs = preferences('plugin.versaradio');

$prefs->set('wasHere','true');
#$prefs->client($client)->set('clientWasHere','true');

#my @moduleList = ('Fip', 'FrequenceJazz', 'TSF');
#my @versaRadioModulesNames = ('Sample');

# TODO: replace by some code to autodetect modules and maybe some user interface
my @versaRadioModulesNames = ('FIP', 'TSF', 'FrequenceJazz');

sub initPlugin {
	my $class = shift;
	
	foreach my $moduleName (@versaRadioModulesNames) {
		my $moduleFullName = 'Plugins::VersaRadio::Radios::'.$moduleName;
		eval "use ${moduleFullName}";
		if(length($@)!=0) {
			$log->error("module ${moduleFullName} not found: ", $@);
		}
#		print("Initializing radio module:  $moduleFullName");
		${moduleFullName}->initVersaRadioModule();

		#Modules::$module::test();
		#use Slim::Plugin::VersaRadio::Mdules::ModTest;	
	}

#	my $moduleFullName = 'Slim::Plugin::VersaRadio::Radios::VersaRadioBase';
#	print("\nradio Params: ".Dumper($moduleFullName->radioParams())."\n");
#	print("\nradio Vars: ".Dumper($moduleFullName->radioVars())."\n");
#
#	foreach my $radioName (@versaRadioModulesNames) {
#		my $moduleFullName = 'Slim::Plugin::VersaRadio::Radios::'.$radioName;
#		print("\nradio Params: ".Dumper($moduleFullName->radioParams())."\n");
#		print("\nradio Vars: ".Dumper($moduleFullName->radioVars())."\n");
#	}
	
}

sub getDisplayName () {
	return 'PLUGIN_VERSARADIO_MODULE_NAME';
}
