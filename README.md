# Python Env Sanitizer for macOS 🩸

> **TL;DR** – One shell script to end the nightmare of broken *pip*, cursed Homebrew Pythons, and the endless “Can not perform a `--user` install” tragedy. Run it, reload your shell, and get back to shipping code.

---

## Why Does This Even Exist?

Because the Python ecosystem decided that *simplicity* is a luxury we can’t afford:

1. **Homebrew** used to ship a Python where `pip` defaulted to `--user` installs, confusing virtualenvs. Old guides still assume this behavior.
2. *pip* honors config files that can force user installs. Stray `pip.conf` entries linger for years.
3. Scripts call `python3` while toolchains assume `python`. Meanwhile, neither may be the one you actually installed.
4. You waste hours rage‑googling instead of writing code.

This repo exists so you can point to it and say, “See? It’s *not me* – it’s a clown‑car of conflicting defaults.”

---

## Quick Start

```bash
curl -O https://raw.githubusercontent.com/<your‑org>/<repo>/main/sanitize_py.sh
chmod +x sanitize_py.sh
./sanitize_py.sh
exec $SHELL   # reload zsh so changes take effect
```

That’s it. The next time you create a venv, `pip install` **just works** – no `--user` drama.

---

## How We Got Here

Python packaging on macOS has a long history of conflicting defaults:

* **PEP 405** (2012) formalized virtual environments, but many tools kept installing packages globally.
* Homebrew patched `pip` for years to default to the user site, leading to the infamous “Can not perform a `--user` install” error inside venvs.
* **PEP 668** (2023) introduced the `EXTERNALLY-MANAGED` marker so package managers can protect system Pythons.
* By 2025, Homebrew no longer forces `--user`, but old configs and tutorials still do.

This script grew out of that mess. It enforces a clean interpreter via **pyenv** so you can rely on `python -m venv` behaving sanely.

---

## What the Script Does

1. **Checks** for poisonous env‑vars (`PIP_USER`, `PIP_REQUIRE_VIRTUALENV`, etc.).
2. **Installs & configures** **pyenv** via Homebrew – the irony is delicious.
3. **Installs** a clean CPython (default 3.12.3).
4. **Patches `~/.zshrc`** to:

   * load pyenv
   * prepend `~/.pyenv/shims` to `PATH`
   * alias `python3 → python` (plus a real shim symlink)
5. **Scrubs** your global *pip* config of the dreaded `global.user = true`.
6. **Verifies** that both `python` **and** `python3` resolve to the pyenv shim.

Result: a *sane*, venv‑friendly Python toolchain.

---

## FAQ (a.k.a. Blood‑Soaked Rant)

### “Why can’t `python -m venv` just work on macOS?”

Homebrew’s old `--user` patch collided with pip’s user‑site support from **PEP 370**. Even though the patch is gone, leftover configs still trigger the error.

### “Can’t I just use the system Python?”

Apple’s `/usr/bin/python3` is protected by SIP. It’s reasonably up to date (Python 3.11 ships with Sonoma) but lacks development headers unless Xcode tools are installed. Many users still prefer an external interpreter.

### “Isn’t this pyenv setup overkill?”

Maybe. pyenv is a convenient way to install multiple Python versions without touching `/usr/bin`. A clean Homebrew or python.org install works too as long as you avoid `--user` settings.

### “I still get the error!”

Run:

```bash
which python python3
python -m pip config list
printenv | grep -E 'PIP_|PYTHON'
```

If any path isn’t in `~/.pyenv/shims` or `global.user=true` re‑appears, congrats – another tool rewrote your config. Re‑run the script. 🔪

As of **PEP 668**, package managers may mark their Python as externally managed. If you see that warning, create a virtual environment or use pyenv’s interpreter.

---

## Does This Still Matter in 2025?

Mostly yes. Homebrew no longer forces `--user` installs and system Pythons are newer, but stray configuration files still break venvs. This script remains a quick way to reset your setup with pyenv so you can focus on coding instead of troubleshooting.

---

## Contributing

Feel free to PR improvements, but only if your change **reduces** misery. Extra rants welcome – humour heals.

---

## License

MIT. Because the only thing worse than Python packaging is legalese.

