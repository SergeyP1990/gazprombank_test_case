#!/usr/bin/perl


use strict;
use warnings; 
use DBI;
use CGI;

my %config;

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

sub error {
    my $cgi  = shift;   # CGI.pm object
    my $err_msg = shift;
    print $cgi->header,
          $cgi->start_html("");
    print("ERROR: $err_msg<br>");
    print $cgi->end_html;
    exit;
}

sub handle_query {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;

    my $mail = $cgi->param('mail');

    print $cgi->header,
          $cgi->start_html(""),
          $cgi->h1("Results:");

    if (not defined $mail or $mail eq "") {
        print("Query is empty");
        print $cgi->end_html;
        return;
    }

    parse_config();
    my $dsn = 'DBI:mysql:'.$config{"db_name"}.':'.$config{"db_address"};
    my $dbh = DBI->connect($dsn, $config{"user"}, $config{"pass"}, {'RaiseError' => 1});

    my $sql = (" (select created, str, int_id from message where str like ?)
                 union
                 (select created, str, int_id from log where address = ?)
                 order by created, int_id limit 101");
    my $sth = $dbh->prepare($sql) || error($cgi, $dbh->errstr);
    $sth->execute("%$mail%", $mail) || error($cgi, $sth->errstr);

    my $rows = $sth->rows;

    if ($rows > 100) {
        print $cgi->h3("There is more than 100 records");
    }

    while (my $ref = $sth->fetchrow_hashref()) {
      print "$ref->{'created'}; $ref->{'str'}<br>";
    }
    $sth->finish();

    print $cgi->end_html;
 
}