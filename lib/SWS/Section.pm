package SWS::Section;

use strict;
use warnings;

# /student/{version}/public/course/{year},{quarter},{curriculum_abbreviation},{course_number}/{section_id}.{xml/json/xhtml}
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
    my $id = shift;

    my %quarters = ( 1 => 'winter', 2 => 'spring', 3 => 'summer', 4 => 'autumn' );

    use URI::Escape;

    if ( $id =~ /(\d{4})-(\d) (\d)-(.+) (\d{3}) ([A-Z]+)/i ) {
        # Use R25 AlienUid style
        my ($year, $quarter, $campus, $curric, $number, $section) = ($1, $2, $3, $4, $5, $6);
        $quarter = $quarters{$quarter};

        $id = "$year,$quarter," . uri_escape($curric) . ",$number/$section"
    }

    SWS->Rest->GET( "$path$id.xml" );

    if ( SWS->Rest->responseCode ne '200' ) {
        return ( undef, 'Error ' . SWS->Rest->responseCode . ': ' . SWS->Rest->responseContent );
    }

    eval { $self->{'xc'} = SWS->Rest->responseXpath(); };
    return ( undef, "$@" ) if "$@";

    $self->{'xc'}->registerNs( 'sws', 'http://webservices.washington.edu/student/' );

    return ( undef, "SWS Section not found" ) unless $self->{'xc'}->exists( "/sws:Section" );

    $self->{'xc'}->setContextNode( $self->{'xc'}->findnodes( '/sws:Section' )->shift );

    return $self->Id;
}


sub Id {
    my $self = shift;

    return sprintf( '%d,%s,%s,%d/%s',
                    $self->Year,
                    $self->Quarter,
                    $self->CurriculumAbbreviation,
                    $self->CourseNumber,
                    $self->SectionID );
}


sub AlienUid {
    my $self = shift;

    return sprintf( '%d-%d %d-%s %s %s',
                    $self->Year,
                    $self->QuarterNumber,
                    $self->CourseCampusNumber,
                    $self->CurriculumAbbreviation,
                    $self->CourseNumber,
                    $self->SectionID );
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

    return $campusnumbers{lc $self->CourseCampus} || 0;
}


sub IsPrimarySection {
    my $self = shift;

    return $self->{'xc'}->findvalue( 'sws:PrimarySection/sws:SectionID' ) eq $self->SectionID
        if $self->{'xc'}->exists( 'sws:PrimarySection' );

    my $xpc = XML::LibXML::XPathContext->new($self->{'xc'}->getContextNode->parentNode);
    $xpc->registerNs( 'sws', 'http://webservices.washington.edu/student/' );

    $self->Load($self->Id)
        unless $xpc->exists( 'sws:IsPrimarySection' );

    return $xpc->findvalue( 'sws:IsPrimarySection' ) ne 'false';
}


sub PrimarySection {
    my $self = shift;

    return $self if $self->IsPrimarySection;

    my $node = $self->{'xc'}->findnodes( 'sws:PrimarySection' )->shift;

    my $primary_section = SWS::Section->new( node => $node );

    return $primary_section;
}


sub LinkedSections {
    my $self = shift;

    $self->Load($self->Id)
        unless $self->{'xc'}->exists( 'sws:LinkedSectionTypes' );

    my @nodes = $self->{'xc'}->findnodes( 'sws:LinkedSectionTypes/sws:SectionType/sws:LinkedSections/sws:LinkedSection/sws:Section' );

    my @linked_section_list;

    for ( @nodes ) {
        my $linked_section = SWS::Section->new( node => $_ );
        push @linked_section_list, $linked_section;
    }

    use SWS::Sections;
    my $linked_sections = SWS::Sections->new( section_list => \@linked_section_list );

    return $linked_sections;
}


sub JointSections {
    my $self = shift;

    $self->Load($self->Id)
        unless $self->{'xc'}->exists( 'sws:JointSections' );

    my @nodes = $self->{'xc'}->findnodes( 'sws:JointSections/sws:Section' );

    my @joint_section_list;

    for ( @nodes ) {
        my $joint_section = SWS::Section->new( node => $_ );
        push @joint_section_list, $joint_section;
    }

    use SWS::Sections;
    my $joint_sections = SWS::Sections->new( section_list => \@joint_section_list );

    return $joint_sections;
}


sub Meetings {
    my $self = shift;

    $self->Load($self->Id)
        unless $self->{'xc'}->exists( 'sws:Meetings' );

    my @nodes = $self->{'xc'}->findnodes( 'sws:Meetings/sws:Meeting' );

    my @meeting_list;

    for ( @nodes ) {
        my $meeting = SWS::Meeting->new( node => $_ );
        push @meeting_list, $meeting;
    }

    use SWS::Meetings;
    my $meetings = SWS::Meetings->new( meeting_list => \@meeting_list );

    return $meetings;
}


sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    if ( my ($method) = $AUTOLOAD =~ /.*::(CourseNumber|CurriculumAbbreviation|Quarter|Year)/ ) {
        return $self->{'xc'}->findvalue( "sws:Course/sws:$method" )
            || $self->{'xc'}->findvalue( "sws:$method" )
            || ( undef, "Element $method not found" );
    }

    if ( my ($method) = $AUTOLOAD =~ /.*::(CourseTitle|CourseTitleLong|CourseCampus|CourseDescription)/ ) {
        return $self->{'xc'}->findvalue( "sws:$method" )
            || ( undef, "Element $method not found" );
    }

    if ( my ($method) = $AUTOLOAD =~ /.*::(SectionID)/ ) {
        return $self->{'xc'}->findvalue( "sws:$method" )
            || ( undef, "Element $method not found" );
    }

    return ( undef, "Method $AUTOLOAD not defined" );
}

1;
