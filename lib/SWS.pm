package SWS;

use REST::Client;


our $Rest;


sub import
{
    my $self = shift;
    my %args = (
        host => undef,
        @_,
        );

    return if $Rest;
    $Rest = REST::Client->new( %args );
}


sub Rest {
    my $self = shift;

    return $Rest;
}

1;
