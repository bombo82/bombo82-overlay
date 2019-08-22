#bombo82-overlay

This is my own gentoo overlay, so none of these ebuilds will have official support.

#Installation

You can use this overlay by adding a file to `/etc/portage/repos.conf/` containing the following;
```bash
[bombo82]
priority = 50
location = /opt/portage/bombo82
sync-type = git
sync-uri = https://github.com/bombo82/bombo82-overlay.git
auto-sync = Yes
```

## Contributing
If you find an issue then please submit it on [the issue tracker](https://github.com/bombo82/bombo82-overlay/issues).

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
Except where otherwise noted, the content on this overlay is licensed under the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or (at your option) any later version.
[GNU General Public License](https://www.gnu.org/licenses).

This README is licensed under a [Creative Commons Attribution 4.0 International license](https://creativecommons.org/licenses/by/4.0/).
