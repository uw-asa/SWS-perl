package SWS::Meeting;

use strict;
use warnings;

sub new  { 
    my $class = shift;
    my %args = (
        node => undef,
        @_,
        );

    my $self  = {};
    if ( $args{'node'} ) {
        $self->{'xc'} = XML::LibXML::XPathContext->new($args{'node'});
        $self->{'xc'}->registerNs( 'sws', 'http://webservices.washington.edu/student/' );
    }

    bless ($self, $class);

    return $self;
}


sub DaysOfWeek {
    my $self = shift;

    my @nodes = $self->{'xc'}->findnodes( 'sws:DaysOfWeek/sws:Days/sws:Day/sws:Name' );
    return map { $_->toString } @nodes;
}


sub DaysOfWeekText {
    my $self = shift;

    return $self->{'xc'}->findvalue( 'sws:DaysOfWeek/sws:Text' )
        || ( undef, "Element DaysOfWeek/Text not found" );
}


sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    if ( my ($method) = $AUTOLOAD =~ /.*::(Building|RoomNumber|StartTime|EndTime|MeetingIndex|MeetingType)/ ) {
        return $self->{'xc'}->findvalue( "sws:$method" );
    }

    if ( my ($method) = $AUTOLOAD =~ /.*::(BuildingToBeArranged|RoomToBeArranged|DaysOfWeekToBeArranged)/ ) {
        return ( $self->{'xc'}->findvalue( "sws:$method" ) eq 'true' );
    }

    return ( undef, "Method $AUTOLOAD not defined" );
}

1;
