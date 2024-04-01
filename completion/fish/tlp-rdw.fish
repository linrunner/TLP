# Fish shell completion for tlp-rdw

set -l tlp_rdw_commands enable disable

complete -c tlp-rdw -f
complete -c tlp-rdw -n "not __fish_seen_subcommand_from $tlp_rdw_commands" -a enable -d 'Enable RDW actions'
complete -c tlp-rdw -n "not __fish_seen_subcommand_from $tlp_rdw_commands" -a disable -d 'Disable RDW actions'
complete -c tlp-rdw -n "not __fish_seen_subcommand_from $tlp_rdw_commands" -l version -d 'Print TLP version'
