{
    use strict;

    package magmakeys::EventFileManager;
    use base "magmakeys::EventHandlerManager";

    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        
        my $self = $class->SUPER::new();

        $self->{"HANDLERS"} = {};

        bless($self, $class);
    }
    
    sub flush_handlers {
        my $self = shift;
        $self->{HANDLERS} = {};
    }

    sub read_handlers_from_file {
        my $self = shift;
        my $filename = shift;
        
        my $fh = new IO::File($filename, 'r');
        my $i = 0;
        while (<$fh>) {
            $i++;
            s/#.*//;
            next unless /[^[:space:]]/;

            if (/^((?:KEY|SW)_[[:alnum:]_]+(?:\+(?:KEY|SW)_[[:alnum:]_]+)*)[[:space:]]+([[:digit:],]+)[[:space:]]+(.*)$/) {
                my ($ev, $values, $cmd) = ($1, $2, $3);
                for my $val ( split(/,/, $values) ) {
                    unless ($self->add_handler($ev, $val, $cmd)) {
                        print STDERR "Unable to register event handler for event '$ev' and value '$val' (line $i)\n";
                    }
                }
            } else {
                print STDERR "Unable to parse line $i: $_\n";
            }
        }
        $fh->close();
    }
 
    sub add_handler {
        my $self = shift;
        my $event_name = shift;
        my $value = shift;
        my $cmd = shift;

        # re-phrase event name to suit our sorting
        my $sorted_event_name = join('+', sort split(/\+/, $event_name) );
        
        push @{ $self->{HANDLERS}{$sorted_event_name}{$value} }, $cmd;
    }

    sub handle_event {
        my $self = shift;
        my $event = shift;
        
        my $cmds = undef;
        
        # are we ignoring this event?
        return if $self->ignore_event($event->name);

        if ($event->type_description eq "EV_KEY") {
            # handle multiple pressed keys by joing their names
            my $state_string;
            if ($event->value == 1) {
                $self->press_key($event->name);
                $state_string = join("+", $self->pressed_keys);
            } elsif ($event->value == 0) {
                $state_string = join("+", $self->pressed_keys);
                $self->release_key($event->name);
            } elsif ($event->value == 2) {
                $state_string = join("+", $self->pressed_keys);
            }
            if ($self->dump) {
                print "Key state: $state_string (", $event->value, ")\n";
            }
            $cmds = $self->{HANDLERS}{$state_string}{$event->value};
        } else {
            $cmds = $self->{HANDLERS}{$event->name}{$event->value};
        }
        if (defined $cmds && ref $cmds) {
            for my $cmd (@$cmds) {
                $self->launch_command($cmd, $event);
            }
        }
    }

    1;
}
