use 5.12.0;

package WebService::LOC::CongRec::Page 0.1_01
use Moose 1.13;
with 'MooseX::Log::Log4perl';

use HTML::Strip;
use Data::Dumper;

=head1 DESCRIPTION

A single page from the Congressional Record on THOMAS.

The URL is not persistent, but is along the lines of:
http://thomas.loc.gov/cgi-bin/query/D?r111:15:./temp/~r111h782Bg::

=cut

=head1 ATTRIBUTES

=over 1

=item mech

A WWW::Mechanize object that we can use to grab the page from Thomas.

=cut

has 'mech' => (
    is          => 'rw',
    isa         => 'Object',
    required    => 1,
);

=item url

The page URL.

=cut

has 'url' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=item pageID

This page's ID.

=cut

has 'pageID' => (
    is      => 'rw',
    isa     => 'Str',
);

=item summary

This page's summary.

=cut

has 'summary' => (
    is      => 'rw',
    isa     => 'Str',
);

=item content

This page's content.

=cut

has 'content' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

=back

=cut

sub BUILD {
    my ($self) = @_;

    my $tagStripper = HTML::Strip->new();
    $self->mech->get($self->url);

    my @lines = split /\n/, $self->mech->content;
    foreach my $line (@lines) {
        # Summary line doesn't have a <p> leader
        if ($line =~ m!^<b>(.+)</b><br/>!) {
            $self->summary($1);
            next;
        }

        next if ($line !~ /^<p>/ || $line =~ /^<p>---/);

        # Page ID
        if ($line =~ m!^<p><center><pre>\[Page: ([HSE]\d{1,6})\] <b>!) {
            $self->pageID($1);
            next;
        }

        # Line of actual content
        if ($line =~ m/^<p>(.*)$/) {
            my $text = $tagStripper->parse($1) . "\n";

            # Strip non-breaking spaces
            $text =~ s/\xA0//g;

            $self->content($self->content . $text);

            $tagStripper->eof();
        }
    }
}

1;
