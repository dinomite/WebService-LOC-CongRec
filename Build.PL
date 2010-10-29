=head1 NAME

WebService::LOC::CongRec

=head1 AUTHOR

Drew Stephens <drew@dinomite.net>

=head1 CONTRIBUTORS

None

=head1 COPYRIGHT

Copyright 2010, Drew Stephens

=head1 DESCRIPTION

Grab the Congressional Record from thomas.loc.gov via the daily issues list.

=cut

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new (
    module_name     => 'WebService::LOC::CongRec',
    license         => 'perl',
    dist_author     => 'Drew Stephens <drew@dinomite.net>',
    dist_version    => '0.1_04',
    test_author     => 'Drew Stephens <drew@dinomite.net>',
    dist_abstract   => 'Get the congressional record from thomas.loc.gov',
    build_requires  => {
        'HTML::Strip'       => '1.06',
        'Moose'             => '1.13',
        'MooseX::Log::Log4perl'     => '0.42',
        'MooseX::Types::DateTime'   => '0.05',
        'Test::Class'       => '0.36',
        'WWW::Mechanize'    => '1.64',
    }
);

$build->create_build_script;
