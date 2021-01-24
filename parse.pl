#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Digest::MD5 qw(md5_hex);
use Time::HiRes 'time';


# variables and input arguments section
my %flags = ('<=' => 1,
   	  	  '=>' => 2,
		  '->' => 3,
		  '**' => 4,
	  	  '==' => 5);

defined $ARGV[0] or die "You need to specify path to log file!\nUsage: $0 <path_to_log_file>\n";
my $path_to_log = $ARGV[0];
defined $ENV{'DBI_USER'} or die "Environmetn variable DBI_USER is not set, can't connect to base";
defined $ENV{'DBI_PASS'} or die "Environmetn variable DBI_PASS is not set, can't connect to base";


my %config;



# funtions section
sub parse_config {
	open(my $cfn_fh, "<", './auth.info');
	while (my $line = <$cfn_fh>) {
		next if $line =~ /^\s*$/;
		chomp $line;
		my ($conf_name, $conf_value)= split(/=/, $line);
		$config{$conf_name} = $conf_value;
	}

	defined $config{'user'} or die "User not specified in config file";
	defined $config{'pass'} or die "User password not specified in config file";
	defined $config{'db_name'} or die "db_name not specified in config file";
	defined $config{'db_address'} or die "db_address not specified in config file";

}


sub handle_string {

	my $line = shift;
	my %parsed_data;
	# ignore empty lines
	return 0 if $line eq "";

	my ($timestamp, $int_id, $flag, $rest_of, $id, $address);

	$line =~ s/^(\S+\s\S+)\s(\S+)\s(.+)//;
	$timestamp = $1;
	$int_id = $2;
	$rest_of = $3;

	# ignore strings without int_id
	return 0 if $int_id !~ /[0-9A-Za-z]+-[0-9A-Za-z]+-[0-9A-Za-z]+/g;

	$parsed_data{"datetime"} = "$timestamp";
	$parsed_data{"int_id"} = "$int_id";

	# get flag
	($flag) = $rest_of =~ /^(\S+)/;
	$parsed_data{"flag"} = $flag;

	# if there is no flag - return data with rest of string
	if (not defined $flags{$flag}) {
		$parsed_data{"str"} = $rest_of;
		return \%parsed_data;
	}


	if ($flag eq "<=") {
		# GRAB ID
		($id) = $rest_of =~ /id=(\S+)/;
		# generate id if it doesn't exist
		if (not defined $id) {
			$id = md5_hex(time());
		}
		$parsed_data{"id"} = "$id";

	} else {
		# GRAB ADDRESS
		($address) = $rest_of =~ /\S+\s(\S+)/;
		$parsed_data{"address"} = "$address";
	}

	$parsed_data{"str"} = $rest_of;
	return \%parsed_data;
}



# main entry
parse_config();
my $dsn = 'DBI:mysql:'.$config{"db_name"}.':'.$config{"db_address"};
my $dbh = DBI->connect($dsn, $config{"user"}, $config{"pass"}, {'RaiseError' => 1});

open(my $file_handle, '<', "$path_to_log") or die "Error opening log file '$path_to_log': $!";
while (my $line = <$file_handle>) {
	chomp $line;
	my $dbq;
	my $data = handle_string($line);
	next if $data == 0;

	if ($data->{"flag"} eq "<=") {
		$dbq = sprintf("INSERT INTO %s (created, id, int_id, str) VALUES (%s, %s, %s, %s)",
	            "message",
	            $dbh->quote($data->{"datetime"}),
	            $dbh->quote($data->{"id"}),
	            $dbh->quote($data->{"int_id"}),
	            $dbh->quote($data->{"str"}),
	            );
	} else {
		$dbq = sprintf("INSERT INTO %s VALUES (%s, %s, %s, %s)",
	            "log",
	            $dbh->quote($data->{"datetime"}),
	            $dbh->quote($data->{"int_id"}),
	            $dbh->quote($data->{"str"}),
	            $dbh->quote($data->{"address"}),
	            );
	}
	$dbh->do($dbq);
}	
close($file_handle);

$dbh->disconnect();