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
# VersaRadioBase.pm is the base class for all radio modules, it handles async
# http requests and delegate content parsing to radio submodules

=head1 SEQUENCE DIAGRAM

To be used at:  http://www.websequencediagrams.com/

=head2 Init and refreshMetaData

	participant SqueezeServer as SS
	participant Plugin.pm as P
	participant "Radios::RadioModule.pm" as RM
	participant ":runUpdateTask" as RMRUT
	participant ":refreshMetaData" as RMRMD
	#participant "Radios::VersaRadioBase.pm" as VRB
	
	
	SS->P: initPlugin
	loop foreach Radio Module
	   P->RM: initVersaRadioModule
	   activate RM
	   RM->RM: mergeRadioParams
	   RM->RM: lastQueryTimeStamp = time()-120
	   RM->RM: Instancie 2 \nSlim...SimpleAsyncHTTP
	   RM->SS: Slim::Formats::RemoteMetadata->registerProvider(regexp, module::metaProvider)
	   RM-->P: return
	   deactivate RM
	   P-->SS: return
	end
	
	SS->RM: metaProvider()
	activate RM
	RM-->RM: lastMetaProviderTimeStamp = time()
	opt Update task not running  (!updateTaskRunning)
	
	   RM->RMRUT: runUpdateTask()
	   activate RMRUT
	   RMRUT->RMRUT: updateTaskRunning = 1
	   RMRUT->RMRMD: refreshMetaData()
	   activate RMRMD
	   opt lastQueryTimeStamp < 10 secondes
	      RMRMD-->RMRUT: return
	      RMRUT-->RM: return
	      RM-->SS: return
	   end
	   RMRMD->RMRMD: lastQueryTimeStamp = time()
	   RMRMD->RMRMD: firstUrlAsyncHttp->get()
	   RMRMD->RMRMD: secondUrlAsyncHttp->get()
	   RMRMD-->RMRUT: return
	   deactivate RMRMD
	   RMRUT-->RM: return
	   deactivate RMRUT
	end
	RM->RM: copy MetaData
	RM->RM: getVersaRadioIcon()
	RM-->SS: return $metaDataCopy;


=cut

package Plugins::VersaRadio::Radios::VersaRadioBase;

use strict;
use warnings;
use version; our $VERSION = qw('0.0.1);


use Data::Dumper;

# TODO: add comments!
# TODO: convert "firstUrl", "secondUrl" by a data structure of unlimited size

our $radioParams = {
	fullName => 'Base Module full name',
	name => 'BaseModule',
	defaultData => 'Present',
	userAgent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; .NET CLR 1.1.4322)',
	refererFirstURL => 'http://www.google.com/search?q=music+web+radio&ie=utf-8&oe=utf-8&aq=t',
	refererSecondURL => 'http://www.google.com/search?q=music+web+radio&ie=utf-8&oe=utf-8&aq=t',
	minWaitBetweenRequests => 11, # in seconds
};

my $log = $Plugins::VersaRadio::Plugin::log;

sub radioParams {
	my $obclass = shift;	
	my $class   = ref($obclass) || $obclass || __PACKAGE__;
	my $varname = $class . "::radioParams";
	no strict "refs"; 	# to access package data symbolically
	$$varname = shift if @_;
	return $$varname;
}

sub radioVars {
	my $obclass = shift;	
	my $class   = ref($obclass) || $obclass || __PACKAGE__;
	my $varname = $class . "::radioVars";
	no strict "refs"; 	# to access package data symbolically
	$$varname = shift if @_;
	return $$varname;
}

sub moduleData {
	my $obclass = shift;	
	my $class   = ref($obclass) || $obclass || __PACKAGE__;
	my $varname = $class . "::moduleData";
	no strict "refs"; 	# to access package data symbolically
	$$varname = shift if @_;
	return $$varname;
}

sub mergeRadioParams {
	my $class = shift;
	my $packageName = __PACKAGE__;
	$log->debug($packageName, " ", $class);
	if($class !~ /${packageName}/ ) {
		foreach my $param (keys(%{__PACKAGE__->radioParams()})) {
			if(not defined($class->radioParams()->{$param})) {
				$class->radioParams()->{$param} = __PACKAGE__->radioParams->{$param};
			}
		}
	}
}

sub initVersaRadioModule {
	my $class = shift;
	$log->debug("calling initVersaRadioModule: ",Dumper(@_), "\n");
	$class->mergeRadioParams();
	$class->radioVars()->{lastQueryTimeStamp} = time()-120;
	# Create a request
	$class->radioVars()->{firstUrlAsyncHttp} = Slim::Networking::SimpleAsyncHTTP->new(
		sub {return $class->asyncHTTPFirstUrlCallback(@_)},
		sub {return $class->asyncHTTPErrorCallback(@_)},
		{
			mydata   => 'foo',
			cache    => 0,		# optional, cache result of HTTP request
		}
	);
	
	if(defined $class->radioParams->{secondURL}) {
		$class->radioVars()->{secondUrlAsyncHttp}  = Slim::Networking::SimpleAsyncHTTP->new(
		sub {return $class->asyncHTTPSecondUrlCallback(@_)},
		sub {return $class->asyncHTTPErrorCallback(@_)},
			{
				mydata   => 'foo',
				cache    => 0,		# optional, cache result of HTTP request
			}
		);
				
	}
#	die ref($self)."::metaProvider";

# Removed as advised by Andy
#	Slim::Player::ProtocolHandlers->registerIconHandler(
#		$class->radioParams->{urlStreamRegexp},
#		sub {return $class->getVersaRadioIcon(@_); }
#	);

	Slim::Formats::RemoteMetadata->registerProvider(
		match => $class->radioParams->{urlStreamRegexp},
		func  => sub {return $class->metaProvider(@_)},
	);
	return;
}

sub asyncHTTPErrorCallback {
    my $http = shift;
    $log->error("Oh no! An Async HTTP error!\n");
}

sub mergeMetaData {
	my $class = shift;
	my $newMetaData = shift;
	
	foreach my $metaData (keys(%{$newMetaData })) {
		$class->radioVars()->{metadata}->{$metaData} = $newMetaData->{$metaData};
	}
	$log->debug("after merge: ",Dumper($class->radioVars()->{metadata}), "\n");
}

sub asyncHTTPFirstUrlCallback {
	# class name (from class call)
	my $class = shift;
	# asynchttp object
	my $http = shift;

	my $content = $http->content();

	#my $newContent = $class->parseFirstUrlContent($content);
	$class->mergeMetaData($class->parseFirstUrlContent($content));	

	$log->debug("Got Song Info.\n");

	my $refreshCode = sub {return $class->refreshMetaData};
	Slim::Utils::Timers::killTimers( $http, $refreshCode);

# TODO: don't stopUpdateTask, use a timer in metaProvider instead
	if(time()-$class->radioVars()->{lastMetaProviderTimeStamp}<60 and $class->radioVars()->{updateTaskRunning}) {
		$log->debug("Set refreshMetaData task in ".$class->radioParams()->{minWaitBetweenRequests}." seconds");
		Slim::Utils::Timers::setTimer( $http, Time::HiRes::time() + $class->radioParams()->{minWaitBetweenRequests}, $refreshCode);
	} else {
		$class->stopUpdateTask();
	}
}

sub asyncHTTPSecondUrlCallback {
	my $class = shift;
	my $http = shift;

	my $content = $http->content();

	#my $newContent = $class->parseSecondUrlContent($content);
	$class->mergeMetaData($class->parseSecondUrlContent($content));
	
	$log->debug("Got the second url content.\n");
}

sub refreshMetaData {
	my $class = shift;
	$log->debug("${class}::refreshMetaData Called, Calling refreshMetaData");
#	$log->debug("XXXXXX: $lastQueryTimeStamp");
	my $currentTimeStamp=time();
#	$log->debug("YYYYYY: $currentTimeStamp");

	# Limit the number of http request (one request every X seconds minimum)
	if($currentTimeStamp-$class->radioVars()->{lastQueryTimeStamp}< 10) {
		$log->debug( "Only ".($currentTimeStamp-$class->radioVars()->{lastQueryTimeStamp})."sec since last request, waiting" );
		return; # $class->radioVars()->{metadata};
	}
	
	$log->debug( ($currentTimeStamp-$class->radioVars()->{lastQueryTimeStamp})."sec. elapsed since last request, requesting song information");
	$class->radioVars()->{lastQueryTimeStamp}=time();

	$class->radioVars()->{firstUrlAsyncHttp}->get(
		$class->radioParams()->{firstURL},
		'Accept' => '*/*',
		'User-Agent' => $class->radioParams()->{userAgent},
		'Referer' => $class->radioParams()->{refererFirstURL},
	);
	if(defined $class->radioParams->{secondURL}) {
		$class->radioVars()->{secondUrlAsyncHttp}->get(
			$class->radioParams()->{secondURL},
			'Accept' => '*/*',
			'User-Agent' => $class->radioParams()->{userAgent},
			'Referer' => $class->radioParams()->{refererSecondURL},
		);
	}
}

sub getVersaRadioIcon {
	my $class = shift;
	if(defined($class->radioParams()->{icon})) 
	{	$log->debug("getVersaRadioIcon called! return: plugins/VersaRadio/html/images/".$class->radioParams()->{icon});
		return "plugins/VersaRadio/html/images/".$class->radioParams()->{icon};
	} 
	else 
	{	$log->debug("getVersaRadioIcon called! return: plugins/VersaRadio/html/images/".$class->radioParams()->{name}.".png");
		return "plugins/VersaRadio/html/images/".$class->radioParams()->{name}.".png";
	}
}

# TODO: replace the lastMetaProviderTimeStamp by a timer reinitialized 
# every time the metaProvider is called and stoping the task after 60 seconds
# TODO: rename the methods, all these names are difficult to understand
sub metaProvider {
	my $class = shift;
		$log->debug("calling metaProvider: ",Dumper(\@_), "\n");
	
	my ( $client, $url ) = @_;
	
#	my $icon = __PACKAGE__->_pluginDataFor('icon');
#	my $meta = __PACKAGE__->getLockerInfo( $client, $url );
	
#	return(__PACKAGE__." POOUAIT $class: ".$class->versaRadioHttpParser());
	$log->debug("${class}::metaProvider Called, Calling runUpdateTask");
	$class->radioVars()->{lastMetaProviderTimeStamp}=time();

	if(!$class->radioVars()->{updateTaskRunning}) {
		$log->debug("update task not running, calling runUpdateTask");
		$class->runUpdateTask();
	}

	$class->radioVars()->{metadata}->{icon} = $class->getVersaRadioIcon();
#	if(not defined ($class->radioVars()->{metadata}->{cover})) {
#		$class->radioVars()->{metadata}->{cover} = $class->getVersaRadioIcon();
#	}

	my $metaDataCopy = {};
	foreach my $key (keys(%{$class->radioVars()->{metadata}})) {
		$metaDataCopy->{$key} = $class->radioVars()->{metadata}->{$key};
	}
	if(not defined ($metaDataCopy->{cover})) {
		$metaDataCopy->{cover} = $class->getVersaRadioIcon();
	}
	return $metaDataCopy;

}


sub runUpdateTask {
	my $class = shift;
	$log->debug("${class}::runUpdateTask Called, Calling refreshMetaData");
	$class->radioVars()->{updateTaskRunning}=1;
	$class->refreshMetaData();
}

sub stopUpdateTask {
	my $class = shift;
	$log->debug("${class}::stopUpdateTask Called, setting updateTaskRunning to 0");
	$class->radioVars()->{updateTaskRunning}=0;
}

1;
