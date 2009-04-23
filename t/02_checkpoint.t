#!perl

## Test the "checkpoint" action

use strict;
use warnings;
use Data::Dumper;
use DBI;
use Test::More tests => 13;
use lib 't','.';
use CP_Testing;

use vars qw/$dbh $SQL $t/;

my $cp = CP_Testing->new( {default_action => 'checkpoint'} );

$dbh = $cp->test_database_handle();

my $S = q{Action 'checkpoint'};

$t=qq{$S fails when called with an invalid option};
like ($cp->run('foobar=12'), qr{^\s*Usage:}, $t);

$t=qq{$S fails when called without warning or critical};
like ($cp->run(''), qr{Must provide a warning and/or critical}, $t);

$t=qq{$S fails when called with invalid warning option};
like ($cp->run('-w foo'), qr{ERROR: .+'warning'.+valid time}, $t);

$t=qq{$S fails when called with invalid critical option};
like ($cp->run('-c foo'), qr{ERROR: .+'critical'.+valid time}, $t);

$t=qq{$S fails when called without a datadir option and PGDATA is not set};
delete $ENV{PGDATA};
like ($cp->run('-c 10'), qr{ERROR: Must supply a --datadir}, $t);

$t=qq{$S fails when called with an invalid datadir option and PGDATA is not set};
like ($cp->run('-c 10 --datadir=foobar'), qr{ERROR: Invalid data_directory}, $t);

my $host = $cp->get_host();
$t=qq{$S fails when called against a non datadir datadir};
like ($cp->run("-c 10 --datadir=$host"), qr{ERROR: Call to pg_controldata}, $t);

$t=qq{$S works when called for a recent checkpoint};
my $dbh = $cp->get_dbh();
$dbh->do('CHECKPOINT');
$dbh->commit();
$host =~ s/socket$//;
like ($cp->run("-w 20 --datadir=$host"), qr{POSTGRES_CHECKPOINT OK}, $t);

$t=qq{$S returns a warning when checkpoint older than warning option};
sleep 2;
like ($cp->run("-w 1 --datadir=$host"), qr{WARNING:}, $t);

$t=qq{$S returns a critical when checkpoint older than critical option};
like ($cp->run("-c 1 --datadir=$host"), qr{CRITICAL:}, $t);

$t=qq{$S returns the correct number of seconds};
like ($cp->run("-c 1 --datadir=$host"), qr{was \d seconds ago}, $t);

$t=qq{$S returns the expected output for MRTG};
like ($cp->run("-c 1 --output=MRTG --datadir=$host"), qr{^\d\n0\n\nLast checkpoint was \d seconds ago}, $t);

$t=qq{$S returns the expected output for MRTG};
like ($cp->run("-c 199 --output=MRTG --datadir=$host"), qr{^\d\n0\n\nLast checkpoint was \d seconds ago}, $t);

exit;