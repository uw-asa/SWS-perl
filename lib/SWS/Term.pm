package SWS::Term;

use strict;
use warnings;

our $path = '/student/v4/public/term/';

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


sub Load {
    my $self = shift;
    my $id;
    if (@_ == 1) {
        $id = shift; # [{year},{quarter}|current|previous|next]
    } else {
        $id = join ',', @_;
    }
    SWS->Rest->GET( "$path$id.xml" );

    if ( SWS->Rest->responseCode ne '200' ) {
        return ( undef, 'Error ' . SWS->Rest->responseCode . ': ' . SWS->Rest->responseContent );
    }

    eval { $self->{'xc'} = SWS->Rest->responseXpath(); };
    return ( undef, "$@" ) if "$@";

    $self->{'xc'}->registerNs( 'sws', 'http://webservices.washington.edu/student/' );

    return ( undef, "SWS Term not found" ) unless $self->{'xc'}->exists( "/sws:Term" );

    $self->{'xc'}->setContextNode( $self->{'xc'}->findnodes( '/sws:Term' )->shift );

    return $self->Id;
}


sub Id {
    my $self = shift;

    return sprintf( '%d,%s',
                    $self->Year,
                    $self->Quarter);
}



sub QuarterNumber {
    my $self = shift;

    my %quarternumbers = ( 'winter' => 1, 'spring' => 2, 'summer' => 3, 'autumn' => 4 );

    return $quarternumbers{lc $self->Quarter};
}


sub QuarterAbbreviation {
    my $self = shift;

    my %quarterabbreviations = ( 'winter' => 'WIN', 'spring' => 'SPR', 'summer' => 'SUM', 'autumn' => 'AUT' );

    return $quarterabbreviations{lc $self->Quarter};
}


sub PreviousTerm {
    my $self = shift;

    $self->Load($self->Id)
        unless $self->{'xc'}->exists( 'sws:PreviousTerm' );

    my $node = $self->{'xc'}->findnodes( 'sws:PreviousTerm' )->shift;

    my $previous_term = SWS::Term->new( node => $node );

    return $previous_term;
}


sub NextTerm {
    my $self = shift;

    $self->Load($self->Id)
        unless $self->{'xc'}->exists( 'sws:NextTerm' );

    my $node = $self->{'xc'}->findnodes( 'sws:NextTerm' )->shift;

    my $next_term = SWS::Term->new( node => $node );

    return $next_term;
}


sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    if ( my ($method) = $AUTOLOAD =~ /.*::(Quarter|Year)/ ) {
        return $self->{'xc'}->findvalue( "sws:$method" )
            || ( undef, "Element $method not found" );
    }

    if ( my ($method) = $AUTOLOAD =~ /.*::(FirstDay|LastDayOfClasses|LastFinalExamDay)/ ) {
        $self->Load($self->Id)
            unless $self->{'xc'}->exists( "sws:$method" );

        return $self->{'xc'}->findvalue( "sws:$method" )
            || ( undef, "Element $method not found" );
    }

    return ( undef, "Method $AUTOLOAD not defined" );
}

1;
