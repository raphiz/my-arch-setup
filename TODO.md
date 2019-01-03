# Things to do...

- Finalise snapshot timeline of user home
- Fix liniting errors (systemd mask and vscode comand) (`ansible-lint sites.yml`)
- Enhance privacy / security
  - [encrypted DNS](https://wiki.archlinux.org/index.php/Dnscrypt-proxy)
  - use [Firejail](https://wiki.archlinux.org/index.php/firejail) for Chrome, Firefox, Redshift etc.
  - SE-Linux and AppArmor
    - Use firewalld lockdown
  - [Use a YubiKey to unlock a LUKS](https://github.com/agherzan/yubikey-full-disk-encryption)
- Try out and use (or adapt) [rmshit](https://github.com/lahwaacz/Scripts/blob/master/rmshit.py)
- Use .gitlocal instead of global git for user config