{
    use strict;

    package magmakeys::DBusDeviceWatcher;
    use magmakeys::DeviceWatcher;
    our @ISA=("magmakeys::DeviceWatcher");

    sub new {
        require Net::DBus;
        require Net::DBus::Reactor;
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self = $class->SUPER::new();
        
        my $bus = Net::DBus->system;
        $self->{HAL} = $bus->get_service("org.freedesktop.Hal");

        $self->{REACTOR} = Net::DBus::Reactor->main;

        $self->__init_reactor;

        bless($self, $class);
    }

    sub __init_reactor {
        my $self = shift;
        # get reference to HAL manager
        my $manager = $self->{HAL}->get_object("/org/freedesktop/Hal/Manager", "org.freedesktop.Hal.Manager");
        # add all existing devices
        foreach my $id (@{$manager->GetAllDevices}) {
            $self->cb_device_added($id);
        }

        # register hotplug callback
        # sometimes devices disappear before we can investigate - therefore we place
        # the method in an eval block
        $manager->connect_to_signal("DeviceAdded", sub {eval{ $self->cb_device_added(shift) }} );
    }


    sub add_filehandle {
        my $self = shift;
        my $dev = shift;

        my $read_cb = sub {
            my $dev = shift;
            $self->process_filehandle($dev);
        };

        $self->{REACTOR}->add_read( 
            $dev->fileno,
            Net::DBus::Callback->new(
                method => $read_cb,
                args   => [$dev]
            ),
            1
        );
    }

    sub remove_filehandle {
        my $self = shift;
        my $dev = shift;
        $self->{REACTOR}->remove_read($dev->fileno);
    }

    sub cb_device_added {
        my $self = shift;
        my $device_id = shift;
        # a new device has been added to the system, let's take a look at it
        my $dev = $self->{HAL}->get_object($device_id, 'org.freedesktop.Hal.Device');
        my $props = $dev->GetAllProperties;
        # is it an input device?
        if ($props->{"linux.subsystem"} eq "input") {
            # check input capabilities
            # only watch devices with keys, switches or buttons
            for my $cap (@{$props->{"info.capabilities"}}) {
                if ($cap eq "input.keyboard" ||
                    $cap eq "input.keypad" ||
                    $cap eq "input.keys" ||
                    $cap eq "input.switch" ||
                    $cap eq "button") {

                    # add it to our watch list
                    my $dev_filename = $props->{"input.device"};
                    my $info = $props->{"info.product"};

                    my $device_file = new magmakeys::DeviceFile($dev_filename, $info);
                    if ($device_file) {
                        $self->add_filehandle($device_file);
                    } else {
                        print STDERR "Unable to open input device file ", $props->{"input.device"}, "\n";
                    }

                    last;
                }
            }
        }
    }

    sub watch {
        my $self = shift;
        # start main loop
        $self->{REACTOR}->run();
    }

    1;
}
