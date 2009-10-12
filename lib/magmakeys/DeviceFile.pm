{
    use strict;

    package magmakeys::DeviceFile;
    use base "IO::File";

    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;

        my $filename = shift;
        my $info = shift;
        my $self = $class->SUPER::new($filename, 'r');
        return undef unless $self;

        ${*$self}->{FILENAME} = $filename;
        ${*$self}->{INFO} = $info;

        bless( $self, $class );
    }

    sub filename {
        my $self = shift;
        return ${*$self}->{FILENAME};
    }
    
    sub info {
        my $self = shift;
        return ${*$self}->{INFO};
    }

    1;
}
