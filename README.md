# GPurgeX

```
 _____ ______                    __   __
|  __ \| ___ \                   \ \ / /
| |  \/| |_/ /   _ _ __ __ _  ___ \ V /
| | __ |  __/ | | | '__/ _` |/ _ \/   \
| |_\ \| |  | |_| | | | (_| |  __/ /^\ \
 \____/\_|   \__,_|_|  \__, |\___\/   \/
                        __/ |
                       |___/
```

Clean GNOME debloating script by Zer0C0d3r.

## Quick Start

```bash
chmod +x gnome-debloat.sh
./gnome-debloat.sh --help
```

## Usage

```bash
./gnome-debloat.sh              # Run debloat
./gnome-debloat.sh --dry-run    # Preview changes (safe)
./gnome-debloat.sh --restore    # Restore packages
./gnome-debloat.sh --interactive # Choose packages
```

## Features

- **24 GNOME packages** targeted for removal
- **Multi-platform** support (Linux/BSD)
- **Silent operation** with progress indicators
- **Backup & restore** functionality
- **Safety warnings** for critical packages
- **Clean CLI interface** without clutter

## Supported Systems

- **Linux:** Ubuntu/Debian (apt), Fedora/RHEL (dnf), Arch (pacman)
- **BSD:** FreeBSD (pkg), OpenBSD (pkg_add)

## Target Packages

The script removes these 24 GNOME packages:

1. **decibels** - Simple audio player
2. **gnome-connections** - Remote desktop client
3. **gnome-font-viewer** - Font viewer utility
4. **gnome-calculator** - Calculator application
5. **gnome-calendar** - Calendar application
6. **snapshot** - Camera application
7. **gnome-characters** - Character map
8. **gnome-clocks** - World clock application
9. **gnome-console** - Terminal emulator ⚠️ **CRITICAL WARNING**
10. **gnome-contacts** - Contacts manager
11. **gnome-tour** - Welcome tour
12. **gnome-text-editor** - Text editor
13. **gnome-system-monitor** - System monitor
14. **epiphany** - Web browser
15. **gnome-weather** - Weather application
16. **totem** - Video player
17. **simple-scan** - Document scanner
18. **yelp** - Help browser
19. **gnome-maps** - Maps application
20. **gnome-music** - Music player
21. **gnome-software** - Software center
22. **gnome-system-monitor** - System monitor (duplicate)
23. **malcontent** - Parental controls
24. **gnome-logs** - System logs viewer

## Important Warning

**⚠️ gnome-console is GNOME's default terminal emulator!**

Removing it will delete your terminal application. Before running this script:

1. **Install an alternative terminal** such as:
   - `kitty` - Fast GPU-accelerated terminal
   - `alacritty` - Cross-platform terminal
   - `konsole` - KDE terminal
   - `gnome-terminal` - Alternative GNOME terminal

2. **Set your new terminal as default** in your system settings

3. **Test your new terminal** works properly before running the debloat script

## Safety Features

- **Automatic backups** created before removal
- **Confirmation prompts** for destructive operations
- **Special warning** and confirmation for gnome-console removal
- **Graceful error handling** and cleanup
- **Idempotent operations** (safe to run multiple times)
- **Smart dependency handling** - automatically tries cascade and force removal when needed

## Backup & Restore

The script automatically creates backups in `~/.config/gnome-debloat/` with timestamps:
```
~/.config/gnome-debloat/backup.txt.2025-01-21_14-30-15
```

To restore packages manually:
```bash
# Using the script's restore function
./gnome-debloat.sh --restore

# Or manually restore specific packages
sudo apt install gnome-calculator gnome-clocks  # Ubuntu/Debian
sudo dnf install gnome-calculator gnome-clocks  # Fedora/RHEL
sudo pacman -S gnome-calculator gnome-clocks    # Arch
```

## Logging

All operations are logged to `~/.gnome-debloat.log`:
```
[2025-01-21 14:30:15] REMOVED: gnome-calculator (via apt)
[2025-01-21 14:30:16] REMOVED: gnome-clocks (via apt)
[2025-01-21 14:30:17] SKIPPED: epiphany — already uninstalled!
```

## Troubleshooting

### Common Issues & Solutions

#### 1. Script Only Processes First Package
**Problem**: Script shows "SKIPPED: package — already uninstalled!" and stops
**Solution**: This was a bug in early versions. Update to latest version (1.0.4+)

**Debugging**:
```bash
# Run with verbose mode to see all package processing
./gnome-debloat.sh --verbose

# Check if script is processing all packages
./gnome-debloat.sh --verbose 2>&1 | grep -E "(Checking:|FOUND:|SKIPPED:)"
```

#### 2. Package Detection Issues
**Problem**: Script doesn't detect installed packages
**Solution**: Verify package manager detection and package names

**Debugging**:
```bash
# Test package detection manually
pacman -Qi yelp malcontent gnome-logs  # Arch/Fedora
apt list --installed yelp malcontent gnome-logs  # Ubuntu/Debian
dnf list installed yelp malcontent gnome-logs  # RHEL/CentOS

# Run script with verbose to see detection results
./gnome-debloat.sh --verbose --dry-run
```

#### 3. Permission Denied Errors
**Problem**: `sudo: command not found` or permission errors
**Solution**: Ensure sudo is installed and user has sudo access

```bash
# Check if sudo is available
which sudo

# Test sudo access
sudo -v

# If sudo not available, run as root
su -c './gnome-debloat.sh'
```

#### 4. Package Removal Failures
**Problem**: `Failed to remove package` errors
**Solution**: The script handles this gracefully and continues processing

**Common causes**:
- **Dependency conflicts**: Some packages require others
- **Running processes**: Close applications using the packages
- **Lock files**: Wait and retry

```bash
# Check for running processes
ps aux | grep -i package_name

# Kill processes if necessary
sudo pkill -f package_name

# Retry the script
./gnome-debloat.sh --dry-run  # Preview first
./gnome-debloat.sh            # Then run
```

#### 5. Interactive Mode Issues
**Problem**: `PACKAGES: readonly variable` error
**Solution**: Update to latest version (1.0.3+) which fixes this

**Workaround**:
```bash
# Use non-interactive mode instead
./gnome-debloat.sh --dry-run  # Preview changes
./gnome-debloat.sh            # Run normally
```

#### 6. Backup/Restore Issues
**Problem**: Cannot restore packages or backup not found
**Solution**: Check backup location and permissions

```bash
# Check backup directory
ls -la ~/.config/gnome-debloat/

# Check log file for errors
cat ~/.gnome-debloat.log

# Manual restore if needed
sudo pacman -S gnome-calculator gnome-clocks  # Arch
sudo apt install gnome-calculator gnome-clocks  # Ubuntu
```

#### 7. System-Specific Issues

**Arch Linux**:
```bash
# Update package database first
sudo pacman -Sy

# Check for package name differences
pacman -Ss gnome | grep -i package_name
```

**Ubuntu/Debian**:
```bash
# Update package lists
sudo apt update

# Check package status
apt list --installed | grep package_name
```

**Fedora/RHEL**:
```bash
# Clean package cache
sudo dnf clean all

# Check package info
dnf info package_name
```

#### 8. Getting Help

**Debug Information**:
```bash
# Show system info
uname -a
cat /etc/os-release

# Show package manager
which pacman apt dnf pkg pkg_add

# Show script version
./gnome-debloat.sh --help | head -5
```

**Log Analysis**:
```bash
# Check the log file
cat ~/.gnome-debloat.log

# Run with verbose for detailed output
./gnome-debloat.sh --verbose 2>&1 | tee debug.log
```

**Report Issues**:
1. Run script with `--verbose` flag
2. Save the output to a file
3. Check the log file: `~/.gnome-debloat.log`
4. Include system information and error messages

### Prevention Tips

1. **Always run `--dry-run` first** to preview changes
2. **Backup important data** before running
3. **Close applications** that might use GNOME packages
4. **Update your system** before running the script
5. **Have an alternative terminal** ready (in case gnome-console is removed)

### Emergency Recovery

If something goes wrong:

1. **Check logs**: `cat ~/.gnome-debloat.log`
2. **Restore from backup**: `./gnome-debloat.sh --restore`
3. **Manual reinstall**: Install packages manually using your package manager
4. **System recovery**: Use your distribution's recovery tools if needed

---

## License

MIT License - Copyright (c) 2025 Zer0C0d3r

---

*Simple one-time usage script. Download from: https://github.com/Zer0C0d3r*
