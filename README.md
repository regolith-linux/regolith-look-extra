# regolith-look-extra

Regolith Looks are discrete configurations of desktop components that together that
define the capabilities and flavor of a desktop interface.  There is a package
`regolith-look-default` which is the default look and requires minimal dependencies.
This package houses extra looks created and maintained by the Regolith project.


## Theme directory conventions

### The `root` file

This is the main theme configuration file. It defines the theme's color palette, fonts,
wallpaper, compositor settings, and uses
[C preprocessor `#include` directives](https://gcc.gnu.org/onlinedocs/cpp/Include-Syntax.html)
to load other config files (window manager config, status bar config, and terminal
config).

These includes should use relative paths in the following style so themes can be
portable to other filesystem locations:

```
#include "i3xrocks"
#include "wm"
#include "gnome-terminal"
```


## Testing changes to this repo

WARNING: `regolith-look-selector` will not pick up look directories that are symbolic
links.

TODO: Populate this section.
