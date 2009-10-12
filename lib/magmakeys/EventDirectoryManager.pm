{
    use strict;

    package magmakeys::EventDirectoryManager;
    use base "magmakeys::EventHandlerManager";
    
    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $basedir = shift;
        
        my $self = $class->SUPER::new();

        $self->{event_directory} = $basedir;

        bless($self, $class);
    }

    sub get_directories {
        my ($self, $event) = @_;
        my $b  = $self->{event_directory};
        my $en = $event->name;
        my $et = $event->type_description;
        my $v  = $event->value;
        return map { $b."/".$_ } (
            "$en",              # KEY_RADIO
            "$en/$v",           # KEY_RADIO/1
            "$et",              # EV_KEY
            "$et/$en",          # EV_KEY/KEY_RADIO
            "$et/$en/$v"        # EV_KEY/KEY_RADIO/1
        );
    }

    sub handle_event {
        my $self = shift;
        my $event = shift;

        $self->SUPER::handle_event($event);
        
        for my $dir ( $self->get_directories($event) ) {
            print "Checking event directory: $dir\n" if $self->dump;
            next unless ( -d $dir );

            foreach my $f ( <$dir/*> ) {
                my $scriptname = substr($f,length($dir)+1);
                next unless ( $scriptname =~ /^[a-z0-9]+$/ || 
                              $scriptname =~ /^_?([a-z0-9_.]+-)+[a-z0-9]+$/ || 
                              $scriptname =~ /^[a-z0-9][a-z0-9-]*$/ );
                next if ($scriptname =~ /\.dpkg-(?:dist|new|old|tmp)$/ ||
                         $scriptname =~ /\.disabled$/);

                next unless ( -x $f);

                $self->launch_command( $f, $event );
            }
        }
    }

    1;
}
