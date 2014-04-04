package SWS::Course;

use strict;
use warnings;

# /student/{version}/public/course/{year},{quarter},{curriculum_abbreviation},{course_number}.{xml/json/xhtml}
our $path = '/student/v4/public/course/';

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
    my $id = uc shift;

    my %quarters = ( 1 => 'winter', 2 => 'spring', 3 => 'summer', 4 => 'autumn' );

    use URI::Escape;

    # Use R25 AlienUid style
    $id =~ /(\d{4})-(\d) (\d)-(.+) (\d{3})/;
    my ($year, $quarter, $curric, $number) = ($1, $2, $4, $5);
    $quarter = $quarters{$quarter};

    SWS->Rest->GET( $path . "$year,$quarter," . uri_escape($curric) . ",$number.xml" );

    if ( SWS->Rest->responseCode ne '200' ) {
        return ( undef, 'Error ' . SWS->Rest->responseCode . ': ' . SWS->Rest->responseContent );
    }

    eval { $self->{'xc'} = SWS->Rest->responseXpath(); };
    return ( undef, "$@" ) if "$@";

    $self->{'xc'}->registerNs( 'sws', 'http://webservices.washington.edu/student/' );

    return ( undef, "SWS Course not found" ) unless $self->{'xc'}->exists( "/sws:Course" );

    $self->{'xc'}->setContextNode( $self->{'xc'}->findnodes( '/sws:Course' )->shift );

    return 1;
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


sub CourseCampusNumber {
    my $self = shift;

    my %campusnumbers = ( 'seattle' => 0, 'bothell' => 1, 'tacoma' => 2 );

    return $campusnumbers{lc $self->CourseCampus};
}


sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    if ( my ($method) = $AUTOLOAD =~ /.*::(CurriculumAbbreviation|Quarter|Year)/ ) {
        return $self->{'xc'}->findvalue( "sws:Curriculum/sws:$method" )
            || ( undef, "Element $method not found" );
    }

    if ( my ($method) = $AUTOLOAD =~ /.*::(CourseTitle|CourseTitleLong|CourseCampus|CourseDescription)/ ) {
        return $self->{'xc'}->findvalue( "sws:$method" )
            || ( undef, "Element $method not found" );
    }

    return ( undef, "Method $AUTOLOAD not defined" );
}

1;
