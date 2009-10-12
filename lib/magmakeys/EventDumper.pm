{    
    use strict;

    package magmakeys::EventDumper;

    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;

        my $self = {};
        $self->{DUMP} = 0;

        bless( $self, $class );
    }
    
    # dump received events?
    sub dump {
        my $self = shift;
        $self->{DUMP} = shift if (@_);
        return $self->{DUMP};
    }

    1;
}
