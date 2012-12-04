package MTPath;

use strict;
use warnings;

use base 'Exporter';
use FindBin qw($Bin);
use File::Spec;

our @EXPORT = 'test_config';
our $TEST_CONFIG = 'mt-test-config.cgi';

BEGIN {
    my @paths = ( 'lib', 'extlib', @_ );

    $ENV{MT_HOME} = File::Spec->catdir($Bin, '../../..')
        unless $ENV{MT_HOME};

    push @INC, File::Spec->catdir($ENV{MT_HOME}, $_)
        foreach @paths;
}

sub test_config {
    for my $cfg ( ( $TEST_CONFIG, 'mt-config.cgi' ) ) {
        my $path = File::Spec->catdir($ENV{MT_HOME}, $cfg);
        return $path if -f $path;
    }
}

use MT;
MT->new( Config => test_config );

1;
