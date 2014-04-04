package SWS::Sections;

use strict;
use warnings;

use SWS::Section;

use POSIX qw(strftime);


sub new  {
    my $class = shift;
    my $self  = { @_ };
    bless ($self, $class);

    return $self;
}


sub List {
    my $self = shift;

    return () unless $self->{'section_list'};

    return @{$self->{'section_list'}};
}


1;
