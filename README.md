# bombo82-overlay


This is my own gentoo overlay, so none of these ebuilds will have official support.

## Installation

You can use this overlay by adding a file to `/etc/portage/repos.conf/` containing the following:
```bash
[bombo82]
priority = 50
location = /opt/portage/bombo82
sync-type = git
sync-uri = https://github.com/bombo82/bombo82-overlay.git
auto-sync = Yes
```

Or add it from layman;
```bash
# layman -f -a bombo82
```

## Development tools

This overlay includes helper scripts for maintainers in the `tools/` directory.
They are not installed by Portage and are only useful when working on ebuilds.

- `tools/jetbrains.sh` — Helper for maintaining JetBrains IDE ebuilds.
  Commands:
  - `licenses`: output a Gentoo `LICENSE` string from third-party libraries.
    Requires `bash`, `curl` and `jq`.
  - `find-exec`: output `fperms` lines for executable files (foreign
    architectures excluded by default).
  - `find-arch`: output `rm ... || die` lines for foreign architecture
    directories.

  The tarball is resolved from the package ebuild and looked up in `\$DISTDIR`
  (default: `/var/cache/distfiles`).
  ```bash
  ./tools/jetbrains.sh licenses clion
  ./tools/jetbrains.sh find-exec clion
  ./tools/jetbrains.sh find-exec --all clion
  ./tools/jetbrains.sh find-arch clion
  ./tools/jetbrains.sh --distdir /custom/path find-exec clion
  ```

## Contributing
If you find an issue then please submit it on [the issue tracker](https://github.com/bombo82/bombo82-overlay/issues).

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
Except where otherwise noted, the content on this overlay is licensed under the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or (at your option) any later version.
[GNU General Public License](https://www.gnu.org/licenses).

This README is licensed under a [Creative Commons Attribution 4.0 International license](https://creativecommons.org/licenses/by/4.0/).
