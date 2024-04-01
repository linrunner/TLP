# Fish shell completion for tlp and radio device command: bluetooth nfc wifi wwan

set -l tlp_commands start bat ac usb bayoff setcharge fullcharge discharge recalibrate chargeonce
set -l tlp_rf_devices bluetooth nfc wifi wwan
set -l tlp_rf_devices_commands on off toggle

set -l current_command (status basename | path change-extension '')

if test $current_command = "tlp"
    set -l bats

    for b in /sys/class/power_supply/*
        if not string match -r hid $b; and test -f $b/present; and test (cat $b/present) = "1"; and test (cat $b/type) = "Battery"
            set -a bats (path basename $b)
        end
    end

    complete -c tlp -f
    complete -c tlp -f -n "not __fish_seen_subcommand_from $tlp_commands" -a start -d "Start tlp and apply power saving profile for the actual power source"
    complete -c tlp -f -n "not __fish_seen_subcommand_from $tlp_commands" -a bat -d "Apply battery profile and enter manual mode"
    complete -c tlp -f -n "not __fish_seen_subcommand_from $tlp_commands" -a ac -d "Apply AC profile and enter manual mode"
    complete -c tlp -f -n "not __fish_seen_subcommand_from $tlp_commands" -a usb -d "Enable autosuspend for all USB devices except excluded"
    complete -c tlp -f -n "not __fish_seen_subcommand_from $tlp_commands" -a bayoff -d "Turn off optical drive in UltraBay/MediaBay"
    complete -c tlp -f -n "not __fish_seen_subcommand_from $tlp_commands" -a setcharge -d "Change charge thresholds temporarily"
    complete -c tlp -f -n "not __fish_seen_subcommand_from $tlp_commands" -a fullcharge -d "Charge battery to full capacity"
    complete -c tlp -f -n "not __fish_seen_subcommand_from $tlp_commands" -a chargeonce -d "Charge battery to the stop charge threshold once (ThinkPads only)"
    complete -c tlp -f -n "not __fish_seen_subcommand_from $tlp_commands" -a discharge -d "Force a complete discharge of the battery (ThinkPads only)"
    complete -c tlp -f -n "not __fish_seen_subcommand_from $tlp_commands" -a recalibrate -d "Perform a battery recalibration (ThinkPads only)"
    complete -c tlp -f -n "__fish_seen_subcommand_from $tlp_commands[8..12] && not __fish_seen_subcommand_from $bats" -a "$bats"
end

if contains $current_command $tlp_rf_devices
    complete -c $current_command -f
    complete -c $current_command -n "not __fish_seen_subcommand_from $tlp_rf_devices_commands" -a on -d 'Switch device on'
    complete -c $current_command -n "not __fish_seen_subcommand_from $tlp_rf_devices_commands" -a off -d 'Switch device off'
    complete -c $current_command -n "not __fish_seen_subcommand_from $tlp_rf_devices_commands" -a toggle -d 'Toggle device state'
end
