{
    use strict;

    package magmakeys::SelectDeviceWatcher;
    use base "magmakeys::DeviceWatcher";

    require IO::Select;

    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = {};
        
        $self->{SELECTOR} = new IO::Select;
        
        bless($self, $class);
    }

    sub add_filehandle {
        my $self = shift;
        my $dev = shift;
        $self->{SELECTOR}->add($dev);
    }

    sub remove_filehandle {
        my $self = shift;
        my $fh = shift;
        $self->SUPER::remove_filehandle($fh);
        $self->{SELECTOR}->remove($fh);
    }

    sub watch {
        my $self = shift;
        my $sel = $self->{SELECTOR};
        while(my @ready = $sel->can_read) {
            for my $fh (@ready) {
                $self->process_filehandle($fh);
            }
            return unless $sel->count > 0;
        }
    }

    1;
}
