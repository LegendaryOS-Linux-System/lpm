module Backend
    # Returns :bootc or :rpm_ostree (or raises if neither found)
    def self.detect
        return @_backend if defined?(@_backend)
        if system('which bootc > /dev/null 2>&1')
            @_backend = :bootc
        elsif system('which rpm-ostree > /dev/null 2>&1')
            @_backend = :rpm_ostree
        else
            UI.error 'Neither bootc nor rpm-ostree found on this system.'
            UI.note  'LegendaryOS lpm requires an immutable Fedora base.'
            exit 1
        end
    end

    def self.name
        case detect
        when :bootc      then 'bootc'
        when :rpm_ostree then 'rpm-ostree'
        end
    end

    def self.bootc?      = detect == :bootc
    def self.rpm_ostree? = detect == :rpm_ostree

    # Optional layer backends
    def self.flatpak?
        return @_flatpak if defined?(@_flatpak)
        @_flatpak = system('which flatpak > /dev/null 2>&1')
    end

    def self.distrobox?
        return @_distrobox if defined?(@_distrobox)
        @_distrobox = system('which distrobox > /dev/null 2>&1')
    end

    def self.toolbox?
        return @_toolbox if defined?(@_toolbox)
        @_toolbox = system('which toolbox > /dev/null 2>&1')
    end

    def self.container_backend
        return :distrobox if distrobox?
        return :toolbox   if toolbox?
        nil
    end
end
