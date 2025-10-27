# Fish completion for tlpctl

# Disable file completion as it is not needed
complete -c tlpctl -f

# Helper function to check if a command has been given
function __fish_tlpctl_needs_command
    set -l cmd (commandline -opc)
    set -e cmd[1]
    for i in $cmd
        switch $i
            case '-*'
                continue
            case '*'
                return 1
        end
    end
    return 0
end

# Helper function to check if using a specific subcommand
function __fish_tlpctl_using_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -gt 1
        if test $argv[1] = $cmd[2]
            return 0
        end
    end
    return 1
end

# Main commands - TLP-specific shortcuts first
complete -c tlpctl -n __fish_tlpctl_needs_command -a performance -d "Switch to performance profile"
complete -c tlpctl -n __fish_tlpctl_needs_command -a balanced -d "Switch to balanced profile"
complete -c tlpctl -n __fish_tlpctl_needs_command -a power-saver -d "Switch to power-saver profile"

# Standard commands
complete -c tlpctl -n __fish_tlpctl_needs_command -a list -d "List available power profiles"
complete -c tlpctl -n __fish_tlpctl_needs_command -a list-holds -d "List current power profile holds"
complete -c tlpctl -n __fish_tlpctl_needs_command -a get -d "Print the currently active power profile"
complete -c tlpctl -n __fish_tlpctl_needs_command -a set -d "Set the active power profile"
complete -c tlpctl -n __fish_tlpctl_needs_command -a launch -d "Run a command using a specific power profile (hold)"
complete -c tlpctl -n __fish_tlpctl_needs_command -a loglevel -d "Set the loglevel of the tlp-pd daemon"
complete -c tlpctl -n __fish_tlpctl_needs_command -a version -d "Print version information and exit"

# Global options
complete -c tlpctl -n __fish_tlpctl_needs_command -s h -l help -d "Show help message and exit"
complete -c tlpctl -n __fish_tlpctl_needs_command -l version -d "Print version information and exit"

# 'set' subcommand - complete with available profiles
complete -c tlpctl -n '__fish_tlpctl_using_command set' -a 'performance balanced power-saver' -d "Profile"

# 'loglevel' subcommand - complete with log levels
complete -c tlpctl -n '__fish_tlpctl_using_command loglevel' -a 'info debug' -d "Log level"

# 'launch' subcommand options
complete -c tlpctl -n '__fish_tlpctl_using_command launch' -s p -l profile -d "Profile to hold while running command" -a '(__fish_tlpctl_profiles)'
complete -c tlpctl -n '__fish_tlpctl_using_command launch' -s r -l reason -d "Reason to be noted on the hold"
complete -c tlpctl -n '__fish_tlpctl_using_command launch' -s i -l appid -d "AppID to be noted on the hold"
