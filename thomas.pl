#!/usr/bin/env perl
use warnings;
use lib 'lib';

use WebService::LOC::CongRec::Crawler;
use Log::Log4perl;

my $max = shift || 10;

Log::Log4perl->init_once('log4perl.conf');

my $crawler = CongRec::Crawler->new();

my $i = 1;

$crawler->goForth(\&process_page);

# Simplistic example of mid-crawl page processing
sub process_page {
    my $p = shift;
    $p->log->info("Page #$i");
    exit if ++$i > $max;
}
