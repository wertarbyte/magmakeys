{
    use strict;

    # Event class
    package magmakeys::InputEvent;
    require IO::File;
    use Config;

    my $struct_len = ($Config{longsize} * 2) +
                     ($Config{i16size} * 2) +
                     ($Config{i32size});
    
    # type name -> type number
    our %type = ();
    # event name -> event number
    our %code = ();
    # (type number, event number) -> event name
    our %ev_dict = ();

    sub load_constants {
        my $proto = shift;
        my $class = ref($proto) || $proto;

        my $filename = shift;

        my $fh = new IO::File($filename, "r");
        return 0 unless defined $fh;

        while (my $line = <$fh>) {
            # ignore comments
            next if $line =~ /^#/;
            #
            # lines look like this:
            # KEY_F1 0x28
            #
            # the prefix indicates the event type (KEY)
            # the (hex)number is the code we'll read from the device file
            my ($string, $number) = split(/[[:space:]]+/, $line);
            $number = hex($number) if $number =~ /^0x/;

            my ($prefix, $desc) = split(/_/, $string, 2);
            # lines starting with EV_ contain the code numbers indicating the event type
            if ($prefix eq "EV") {
                $type{$string} = $number;
            } else {
                $code{$string} = { type => "EV_".$prefix, code => $number };
                
                my $type_code = $type{"EV_".$prefix};
                $ev_dict{$type_code}{$number} = { event => $string, type => "EV_".$prefix };
            }
        }
        $fh->close();
        return 1;
    }

    sub lookup_constants {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $name = shift;

        my $code_id = $code{$name}{code};
        my $type_id = $type{ $code{$name}{type} };
        return [$type_id, $code_id];
    }

    # construct a new event object by specifying code numbers for type, code and value
    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = {};

        if (@_ == 3) {
            $self->{TYPE} = shift;
            $self->{CODE} = shift;
            $self->{VALUE} = shift;
        } else {
            return undef;
        }
        $self->{DEVICE} = undef;

        bless($self, $class);
    }

    sub read_from_device {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        
        my $dev = shift;
        
        my $buffer;
        my $len = sysread($dev, $buffer, $struct_len);
        return undef unless $len > 0;
        
        my ($sec, $usec, $type, $code, $value) = unpack('L!L!S!S!i!', $buffer);

        my $me = $class->new($type, $code, $value);
        $me->{DEVICE} = $dev;
        return $me;
    }

    sub type { return shift()->{TYPE}; }
    sub code { return shift()->{CODE}; }
    sub value { return shift()->{VALUE}; }
    sub device { return shift()->{DEVICE}; }

    sub name {
        my $self = shift;
        return $ev_dict{$self->type}{$self->code}{event};
    }

    sub type_description {
        my $self = shift;
        return $ev_dict{$self->type}{$self->code}{type};
    }


    sub matches {
        my $self = shift;
        my $other = shift;

        return ($self->type == $other->type &&
                $self->code == $other->code &&
                $self->value== $other->value);
    }

    sub as_string {
        my $self = shift;
        return ($self->device ? ($self->device->filename." (".$self->device->info.")")  : "Unknown device"),": InputEvent ",$self->type,"/",$self->code," (", $self->name, ") with value ", $self->value;
    }

    1;
} 
