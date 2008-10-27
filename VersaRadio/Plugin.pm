package Slim::Plugin::VersaRadio::Plugin;

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

use base qw(Slim::Plugin::OPMLBased);

use Data::Dumper;
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
my @versaRadioModulesNames = ('FIP', 'TSF', 'FrequenceJazz');

sub initPlugin {
	my $class = shift;
	
	foreach my $moduleName (@versaRadioModulesNames) {
		my $moduleFullName = 'Slim::Plugin::VersaRadio::Radios::'.$moduleName;
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
