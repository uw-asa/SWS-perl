package SWS::Meetings;

use strict;
use warnings;

use SWS::Meeting;

use POSIX qw(strftime);


sub new  {
    my $class = shift;
    my $self  = { @_ };
    bless ($self, $class);

    return $self;
}


sub List {
    my $self = shift;

    return () unless $self->{'meeting_list'};

    return @{$self->{'meeting_list'}};
}


1;
