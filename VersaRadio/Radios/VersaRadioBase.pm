package Slim::Plugin::VersaRadio::Radios::VersaRadioBase;

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


use Data::Dumper;
use Carp qw(cluck);


our $radioParams = {
	fullName => "Base Module full name",
	name => 'BaseModule',
	defaultData => 'Present',
	userAgent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; .NET CLR 1.1.4322)',
	refererFirstURL => 'http://www.google.com/search?q=music+web+radio&ie=utf-8&oe=utf-8&aq=t',
	refererSecondURL => 'http://www.google.com/search?q=music+web+radio&ie=utf-8&oe=utf-8&aq=t',
	minWaitBetweenRequests => 11,
};

my $log = $Slim::Plugin::VersaRadio::Plugin::log;

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
	Slim::Player::ProtocolHandlers->registerIconHandler(
		$class->radioParams->{urlStreamRegexp},
		sub {return $class->getVersaRadioIcon(@_); }
	);

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
	my $class = shift;
	my $http = shift;

	my $content = $http->content();

	#my $newContent = $class->parseFirstUrlContent($content);
	$class->mergeMetaData($class->parseFirstUrlContent($content));	

	$log->debug("Got Song Info.\n");

	my $refreshCode = sub {return $class->refreshMetaData};
	Slim::Utils::Timers::killTimers( $http, $refreshCode);
	
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

sub metaProvider {
	my $class = shift;
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
