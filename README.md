# TLP - Linux Advanced Power Management

TLP saves laptop battery power on Linux without the need to understand every
technical detail.

TLP comes with a default configuration already optimized for battery life, so
you may just install and forget it. Nevertheless TLP is highly customizable to
fulfil your specific requirements.

TLP is a pure command line tool with automated background tasks. It does not
contain a GUI.

## Features
### Power profiles
Depending on the power source (AC or battery) the following settings are applied:

- Kernel laptop mode and dirty buffer params
- Processor frequency scaling including "turbo boost" / "turbo core"
- Limit Intel CPU max/min P-state to control power dissipation (Intel P-state only)
- Intel CPU energy/performance policies HWP.EPP (Intel P-state only) and EPB
- Disk drive advanced power management level (APM) and spin down timeout
- AHCI link power management (ALPM) with device blacklist
- AHCI runtime power management for host controllers and disks (EXPERIMENTAL)
- PCIe active state power management (PCIe ASPM)
- Runtime power management for PCIe bus devices
- Intel GPU frequency limits
- Radeon graphics power management (KMS and DPM)
- Wifi power saving mode
- Enable/disable integrated radio devices (excluding connected devices)
- Power off optical drive in UltraBay/MediaBay
- Audio power saving mode

### Additional
- I/O scheduler (per disk)
- USB autosuspend with device blacklist/whitelist (input devices excluded automatically)
- Enable or disable integrated radio devices upon system startup and shutdown
- Restore radio device state on system startup (from previous shutdown)
- Radio device wizard: switch radios upon network connect/disconnect and dock/undock
- Disable Wake On LAN
- Integrated WWAN and bluetooth state is restored after suspend/hibernate
- Battery charge thresholds and recalibration - ThinkPads only

## Installation
TLP packages are available for all major Linux distributions; see
[Installation](https://linrunner.de/en/tlp/docs/tlp-linux-advanced-power-management.html#installation).

## Configuration
The default configuration provides optimized power saving out of the box.

Settings are stored in `/etc/default/tlp`;
see [Configuration](https://linrunner.de/en/tlp/docs/tlp-configuration.html) for
details.

## Documentation
Read the the full documentation at the website:

- <https://linrunner.de/tlp>

Or take a look at the manpages:

- tlp (apply settings)
- tlp-rdw (control the radio device wizard)
- tlp-stat (display tlp status and active settings)
- wifi, bluetooth, wwan (switch wireless devices on/off)
- run-on-ac, run-on-bat

## Support
Please use adequate Linux forums for help and support questions.

## Bug reports
Refer to the [Bug Reporting Howto](https://github.com/linrunner/TLP/blob/master/.github/Bug_Reporting_Howto.md).

## Contributing
Contributing is not only about coding and pull requests. Volunteers helping
with testing and support are always welcome!

See [Contributing](https://github.com/linrunner/TLP/blob/master/.github/CONTRIBUTING.md).
