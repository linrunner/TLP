# Fish shell completion for tlp, radio device command: bluetooth nfc wifi wwan, and run-on command: run-on-ac run-on-bat

set -l tlp_commands start bat ac usb bayoff setcharge fullcharge discharge recalibrate chargeonce diskid
set -l tlp_rf_devices bluetooth nfc wifi wwan
set -l tlp_rf_devices_commands on off toggle
set -l runon_commands run-on-ac run-on-bat

set -l current_command (status basename | path change-extension '')

if test $current_command = "tlp"
    set -l bats

    for b in /sys/class/power_supply/*
        if not string match -q -r hid $b; and test -f $b/present; and test (cat $b/present) = "1"; and test (cat $b/type) = "Battery"
            set -a bats (path basename $b)
        end
    end

    complete -c tlp -f
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a start -d "Start tlp and apply power saving profile for the actual power source"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a bat -d "Apply battery profile and enter manual mode"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a ac -d "Apply AC profile and enter manual mode"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a usb -d "Enable autosuspend for all USB devices except excluded"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a bayoff -d "Turn off optical drive in UltraBay/MediaBay"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a setcharge -d "Change charge thresholds temporarily"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a fullcharge -d "Charge battery to full capacity"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a chargeonce -d "Charge battery to the stop charge threshold once (ThinkPads only)"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a discharge -d "Force a complete discharge of the battery (ThinkPads only)"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a recalibrate -d "Perform a battery recalibration (ThinkPads only)"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -a diskid -d "Print disk ids for configured drives"
    complete -c tlp -n "not __fish_seen_subcommand_from $tlp_commands" -l version -d 'Print TLP version'
    complete -c tlp -n "__fish_seen_subcommand_from $tlp_commands[6..10] && not __fish_seen_subcommand_from $bats" -a "$bats"
end

if contains $current_command $tlp_rf_devices
    complete -c $current_command -f
    complete -c $current_command -n "not __fish_seen_subcommand_from $tlp_rf_devices_commands" -a on -d 'Switch device on'
    complete -c $current_command -n "not __fish_seen_subcommand_from $tlp_rf_devices_commands" -a off -d 'Switch device off'
    complete -c $current_command -n "not __fish_seen_subcommand_from $tlp_rf_devices_commands" -a toggle -d 'Toggle device state'
    complete -c $current_command -n "not __fish_seen_subcommand_from $tlp_rf_devices_commands" -l version -d 'Print TLP version'
end

if contains $current_command $runon_commands
    complete -c $current_command -xa "(__fish_complete_subcommand)"
end
