#!/usr/bin/env perl
use warnings;
use lib 'lib';

use WebService::LOC::CongRec::Crawler;
use Log::Log4perl;

my $max = shift || 10;

Log::Log4perl->init_once('log4perl.conf');

my $crawler = WebService::LOC::CongRec::Crawler->new();

my $i = 1;

$crawler->goForth(\&process_page);

# Simplistic example of mid-crawl page processing
sub process_page {
    my ($day, $page) = @_;
    my $logger = Log::Log4perl->get_logger('thomas.pl.process_page');
    $logger->info("Page #$i");
    exit if ++$i > $max;
}
