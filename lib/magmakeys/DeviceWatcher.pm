{
    use strict;

    package magmakeys::DeviceWatcher;
    use base "magmakeys::EventDumper";

    require magmakeys::InputEvent;

    # abstract class
    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = $class->SUPER::new();

        $self->{LISTENERS} = [];

        bless( $self, $class );
    }

    sub add_listener {
        my $self = shift;
        my $l = shift;
        push @{ $self->{LISTENERS} }, $l;
    }

    # add or remove handles
    sub add_filehandle { }
    sub remove_filehandle { }
    # start main loop
    sub watch { }

    # read an event from a given filehandle and process it
    sub process_filehandle {
        my $self = shift;
        my $fh = shift;
        my $ie = magmakeys::InputEvent->read_from_device($fh);
        
        unless (defined $ie) {
            print "Error reading from filehandle, removing ",$fh->filename," (",$fh->info,") from watchlist\n";
            $self->remove_filehandle($fh);
            return;
        } 

        if ($ie->type_description eq "EV_KEY" || $ie->type_description eq "EV_SW") {
            if ($self->dump) {
                print $ie->as_string, "\n";
            }
            # do something useful and inform our listeners
            for my $l ( @{ $self->{LISTENERS} } ) {
                $l->handle_event($ie);
            }
        }
    }
    1;
}
