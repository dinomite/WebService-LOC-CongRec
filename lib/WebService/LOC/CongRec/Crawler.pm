package WebService::LOC::CongRec::Crawler;
our $VERSION = '0.1_04';
use Moose;
with 'MooseX::Log::Log4perl';

use WebService::LOC::CongRec::Util;
use WebService::LOC::CongRec::Day;
use WebService::LOC::CongRec::Page;
use DateTime;
use WWW::Mechanize;

=head1 SYNOPSIS

    use WebService::LOC::CongRec::Crawler;
    use Log::Log4perl;
    Log::Log4perl->init_once('log4perl.conf');
    $crawler = WebService::LOC::CongRec::Crawler->new();
    $crawler->goForth();

=head1 ATTRIBUTES

=over 1

=item issuesRoot

The root page for Daily Digest issues.

Breadcrumb path:
Library of Congress > THOMAS Home > Congressional Record > Browse Daily Issues

=cut

has 'issuesRoot' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://thomas.loc.gov/home/Browse.php?&n=Issues',
);

=item issues

A hash of issues: %issues{year}{month}{day}{section}

=cut

has 'issues' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    auto_deref  => 1,
    default     => sub { [] },
);

=item mech

A WWW::Mechanize object with state that we can use to grab the page from Thomas.

=cut

has 'mech' => (
    is          => 'rw',
    isa         => 'Object',
    builder     => '_build_mech',
);

=back

=cut

sub _build_mech {
    return WWW::Mechanize->new(
        agent => 'CongRec https://github.com/dinomite/WebService-LOC-CongRec; ' .
                    WWW::Mechanize->VERSION,
    );
}

=head1 METHODS

=head2 goForth()

 $crawler->goForth();
 $crawler->goForth(process => \&process_page);
 $crawler->goForth(start => $x);
 $crawler->goForth(end => $y);

Start crawling from the Daily Digest issues page, i.e.
http://thomas.loc.gov/home/Browse.php?&n=Issues

Also, for a specific congress, where NUM is congress number:
http://thomas.loc.gov/home/Browse.php?&n=Issues&c=NUM

Returns the total number of pages grabbed.

Accepts an optional processing function to perform for each page.

Accpets optional page counter start and end ranges.  If neither are
given, or given as zero, crawing starts from the beginning and
goes until all pages are visited.

=cut

sub goForth {
    my $self = shift;
    my $args = {
        process => undef,
        start   => 0,
        end     => 0,
        @_
    };
    my $n = \$args->{start};  # Page iterator
    my $grabbed = 0;  # Pages seen.
    my $seen = 0;  # Issues seen.

    $self->mech->get($self->issuesRoot);
    $self->parseRoot($self->mech->content);

    # Go through each of the days
    foreach my $day (@{$self->issues}) {
        last if $args->{end} && $seen >= $args->{end};

        $self->log->info("Date: " . $day->date->strftime('%Y-%m-%d') . "; " . $day->house);

        # Each of the pages for day
        foreach my $pageURL (@{$day->pages}) {
            last if $args->{end} && $seen >= $args->{end};
            $seen++;  # Increment issue.
            next if $args->{start} && $seen < $args->{start};

            $self->log->debug("Getting page: $pageURL");

            my $webPage = WebService::LOC::CongRec::Page->new(
                    mech => $self->mech, 
                    url => $pageURL,
            );

            # Invoke the callback if one was provided
            $args->{process}->($day, $webPage) if $args->{process} && ref $args->{process} eq 'CODE';

            $$n++;  # Increment page number visited.
            $grabbed++;  # Increment total pages visited.
        }
    }

    return $grabbed;
}

=head2 parseRoot(Str $content)

Parse the the root of an issue an fill our hash of available issues

=cut

sub parseRoot {
    my ($self, $content) = @_;

    # Fast forward to the table
    my @lines = split /\n/, $content;
    foreach my $line (@lines) {
        last if $line =~ /<table/;
    }

    my $year = '';
    foreach my $line (@lines) {
        last if $line =~ m!</table>!;

        # Initialize the top-level of the hash when we see a new year
        if ($line =~ /<font size=4>\w+ ([12]\d{3})/) {
            $year = $1;
            next;
        }

        # Each row begins with a date
        my ($month, $day);
        if ($line =~ /<td width=25%>(\w+) +([123]\d|\d)/) {
            $month = WebService::LOC::CongRec::Util->getMonthNumberFromString($1);
            $day = $2;
        } else {
            next;
        }

        # Create a CR::W:Day for each issue that exists for this line
        my $date = DateTime->new(year => $year, month => $month, day => $day, time_zone => 'America/Los_Angeles');
        push @{$self->issues}, $self->makeDay($date, 'h') if ($line =~ />House</);
        push @{$self->issues}, $self->makeDay($date, 's') if ($line =~ />Senate</);
        push @{$self->issues}, $self->makeDay($date, 'e') if ($line =~ />Extension of Remarks</);
        push @{$self->issues}, $self->makeDay($date, 'd') if ($line =~ />Daily Diges</);
    }
}

sub makeDay {
    my ($self, $date, $house) = @_;

    my $day = WebService::LOC::CongRec::Day->new(
            mech    => $self->mech,
            date    => $date,
            house   => $house,
    );

    return $day;
}

1;
