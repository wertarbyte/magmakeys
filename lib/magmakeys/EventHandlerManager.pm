{
    use strict;

    package magmakeys::EventHandlerManager;
    use base "magmakeys::EventDumper";
    require IO::File;

    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = $class->SUPER::new();
        $self->{"keys"} = {};
        $self->{"ignore"} = {};
        
        bless($self, $class);
    }
    
    sub press_key {
        my $self = shift;
        my $key = shift;

        $self->{"keys"}{$key}++;
    }

    sub release_key {
        my $self = shift;
        my $key = shift;
        $self->{"keys"}{$key}--;
        unless ($self->{"keys"}{$key} > 0) {
            delete $self->{"keys"}{$key};
        }
    }

    sub pressed_keys {
        my $self = shift;
        return sort keys %{$self->{keys}};
    }

    sub handle_event {
        my ($self, $event) = @_;
        # are we ignoring this event?
        return if $self->ignore_event($event->name);

        if ($event->type_description eq "EV_KEY") {
            # handle multiple pressed keys by joing their names
            if ($event->value == 1) {
                $self->press_key($event->name);
            } elsif ($event->value == 0) {
                $self->release_key($event->name);
            }
        }
    }

   sub launch_command {
        my $self = shift;
        my $cmd = shift;
        my $event = shift;
        print "Launching command '", $cmd, "'\n";
        if (fork() == 0) {
            # reset signal handler
            $SIG{CHLD} = undef;
            $SIG{HUP} = undef;
            # set up environment
            if ($event) {
                $ENV{EVENT_TYPE} = $event->type_description;
                $ENV{EVENT_NAME} = $event->name;
                $ENV{EVENT_VALUE} = $event->value;
                # FIXME transport both the old and the new state
                $ENV{PRESSED_KEYS} = join("+", $self->pressed_keys);
            }
            exec($cmd);
        }
    }

    sub ignore_event {
        my ($self, $event, $value) = @_;
        if (defined $value) {
            $self->{"ignore"}{lc $event} = $value;
        }
        return $self->{"ignore"}{lc $event};
    }

    1;
}
