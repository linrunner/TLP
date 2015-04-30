This build of TLP comes with tlp-gtk aka ThinkVantage Dashboard, a graphical
interface for tlp-stat.

tlp-gtk can be extended via plugins which are pythonic classes.

```python
class MyPlugin():
    def __init__(self):
        # Perform basic initialization
        self.autoupdate = False # Reloads data via getListboxRows every 3 seconds

    def getHeader(self):
        # Return a title as shown in the sidebar
        return 'My Plugin'

    def shouldDisplay(self):
        # Perform checks whether this plugin is available on this ThinkPad
        return True

    def getListboxRows(self):
        # Return a list of GtkWidgets for the main area
        rows = []
        # Displays the title ('Nothing') on the left, and the content of the
        # file ('/dev/null') on the right
        rows.append(addToListbox('Nothing', '/dev/null'))

        # Adds a the title on the left, and a progressbar with subtitle
        # on the right
        rows.append(addPercentageToListbox('How full is the glass?',
                50.0,
                "volume of liquid"
        ))

        # Custom row with a GtkBox
        box = Gtk.Box()
        box.add(Gtk.Label("Hello"))
        box.add(Gtk.Label("World"))
        rows.append(box)

        return rows

# Add an instance of the plugin for auto-discovery with priority 99
PLUGINS.append((99, MyPlugin()))
```

Linking to the ThinkVantage button:
```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'ThinkVantage'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding 'Launch1'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "python3 /path/to/tlp-gtk.py"
```
