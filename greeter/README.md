## Dependencies

To run the greeter, you must have the following core components installed on your system:

### Required

- **[Quickshell](https://quickshell.org):** The engine used to render the QML interface and provide the necessary Wayland desktop shell integrations.

- **[greetd](https://git.sr.ht/~kennylevinsen/greetd):** The login daemon responsible for session management and user authentication.

### Optional

- **[uwsm](https://wiki.archlinux.org/title/Universal_Wayland_Session_Manager):** Provides a more consistent interface for launch/exit commands, using this is _not_ necessary but makes installation easier.

- **[cage](https://github.com/cage-kiosk/cage):** A lightweight compositor that can host the greeter window. `wlr-randr` can be used to customise monitor config.

- **JetbrainsMono Nerd Font**: The font I used while designing. Use [Configuration](#configuration) if you want to override it.

<br>

## Getting Started

### 1. Run [Install Script](/install.sh)

The install script handles installing everything for selected compositors. If you aren't using one of them you'll need to check [configuration](#configuration) options after installing. After the script runs you may want to edit the compositor configuration to add more accurate monitor settings.

> _Note_: Any wayland based compositor should work as long as it can run quickshell. I just don't have experience with them to provide configurations myself.

##### Easy Install Compositors

- Hyprland
- Niri

##### Other Environments

The easiest way to get this running would be by installing `cage` from the [optional deps](#optional)

### 2. Greetd

**Modify `/etc/greetd/config.toml`:**

```toml
[terminal]
vt = 1

[default_session]
# only ONE command should be active

# hyprland
command = "env HYPRLAND_CONFIG=/etc/ctos/greeter.hyprland.conf uwsm start hyprland.desktop"

# niri
command = "env NIRI_CONFIG=/etc/ctos/greeter.niri.kdl uwsm start niri.desktop"

# others and desktop environment users
command = "env CTOS_MODE=kiosk cage -ds -m last -- quickshell --path /opt/ctos/greeter.qml"

# e.g. you have a secondary monitor that the original command is showing on
# replace 'HDMI-A-1' with the name of the unwanted monitor
# NOTE: requires wlr-randr to be installed
command = "cage -ds -- sh -c 'wlr-randr --output HDMI-A-1 --off && env CTOS_MODE=kiosk quickshell --path /opt/ctos/greeter.qml'"

user = "greeter"  # okay to be different, don't modify from your default

# Keep this as a backup to boot into your default session if needed
# command = "agreety --cmd 'uwsm start hyprland.desktop'"
```

> _Note_: On my setup im using CachyOS and the greetd setup may look different or use a different user, should have no problems as long as that created user is the same in the `config.toml`

### 3. Verifying Installation

> **Note:** Be aware of the [Recovery](#recovery) section in case of issues.

By default, the shell starts in a test state. This allows you to verify the UI and animations are working correctly without needing a functional `greetd` backend or a live session.

- **Default Password:** In test mode, use the password **`password`** to simulate a successful login.
- **Exit Shortcut:** `Esc` will terminate the process.

```bash
CTOS_DEBUG=1 CTOS_MODE=test quickshell --path /opt/ctos/greeter.qml
```

### 4. Session Lock (Lockd)

All that's required for the session locker is that you run this command, the `CTOS_MODE=lockd` is what tells the shell to run as a session locker.

```bash
CTOS_MODE=lockd quickshell --path /opt/ctos/greeter.qml
```

<br>

## Configuration

Configuration will be installed in `/etc/ctos`. The example file below will be installed by the script and should suit most use cases. Please see the file comments for descriptions.

> _Other Compositors:_ See the options `modes.greetd.launch` and `modes.greetd.exit`

`/etc/ctos/greeter.config.json`:

```jsonc
{
  /* Link to the JSON Schema for IDE autocompletion and validation */
  "$schema": "https://raw.githubusercontent.com/TSM-061/ctOS/main/schema/greeter.schema.json",

  /* The Unix username used for the login session */
  "user": "tomtom",

  /* Primary monitor, greeter only renders on monitor selected */
  "monitor": "DP-3",

  /* The typeface used for the terminal-style interface elements */
  "fontFamily": "JetBrainsMono Nerd Font",

  /* Cosmetic 'Identity Card' data displayed in the post-login sequence */
  "fakeIdentity": {
    "id": "XYZ-843",
    "class": "L5_PROV",
    "fullName": "Blume Admin",
  },

  "fakeStatus": {
    "env": "Workstation",
    "node": "109.389.013.301",
  },

  /* Configuration profiles for different greeter modes */
  "modes": {
    "greetd": {
      "animations": "all",
      /* Command sequence to terminate the greeter compositor */
      "exit": ["uwsm", "stop"],
      /* Command sequence to launch the main desktop session */
      "launch": ["uwsm", "start", "hyprland.desktop"],
    },
    "lockd": {
      "animations": "reduced", // May not want animations after locking screen
    },
    "test": {
      "animations": "all",
    },
  },
}
```

<br>

## Recovery

### Session Lock (Lockd)

If the lock-screen becomes unresponsive, you are in a "Deadlock" state. Because Wayland's security model ensures the process obtaining the lock performs the unlock as well, a frozen locker means the session is inaccessible from the GUI. This is dependent on the compositor used as well.

**To recover without a hard reboot:**

1. **Switch TTY:** Press **`Ctrl+Alt+F2`** to access a terminal console.
2. **Dispatch Exit:** Log in and send the exit command directly to the compositor instance. During development, it was found that standard process signals may fail to release the lock; forcing the compositor to exit is the only reliable method:

```bash
hyprctl --instance 0 "dispatch exit"
```

3. **Return to Session:** Switch back to your original TTY (usually **`Ctrl+Alt+F1`**). The compositor will have terminated, returning you to the `greetd` login screen or the TTY prompt, effectively clearing the hung session.

### Display Manager Fallback (Greetd)

If the greeter fails to load at boot, use the "Rollback" method to access your system.

1. **Switch TTY:** Press **`Ctrl+Alt+F2`**.
2. **Revert Config:** Edit the `greetd` configuration to use the fallback text greeter:

```bash
sudo nano /etc/greetd/config.toml
```

3. **Swap to Agreety:**

```toml
[default_session]
# Use the fallback text-greeter
command = "agreety --cmd 'uwsm start hyprland.desktop'"
```

4. **Restart:** Apply changes with `sudo systemctl restart greetd`.

## Security

The ctOS shell is only a frontend. It does not handle password hashing or sensitive authentication logic itself. It essentially passes your inputs to Greetd or Wayland Session Lock.

> **Note:** Your system will remain locked even if the shell crashes. [See Recovery](#recovery)

- **Backend Security:** Authentication is handled entirely by **greetd** and standard Linux PAM (Pluggable Authentication Modules). It is as secure as running the default `greetd` configurations on a new system.
- **Privilege Level:** The only privileged (root) action required is moving assets to `/opt/ctos` and `/etc/ctos`.
- **Runtime:** The display manager shell itself runs under the `greeter` user a low-privilege system account.
