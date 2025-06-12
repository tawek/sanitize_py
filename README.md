# Python Env Sanitizer for macOS 🩸

> **TL;DR** – One shell script to end the nightmare of broken *pip*, cursed Homebrew Pythons, and the endless “Can not perform a `--user` install” tragedy. Run it, reload your shell, and get back to shipping code.

---

## Why Does This Even Exist?

Because the Python ecosystem decided that *simplicity* is a luxury we can’t afford:

1. **Homebrew** ships a Python that silently pushes `--user` installs and breaks virtualenvs.
2. *pip* still thinks sprinkling global‑user settings everywhere is a good idea.
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

Because the Homebrew maintainers thought defaulting to `--user` installs was *cute*. Guido blessed `pip`’s user‑site dance, and everyone else shrugged. 🤡

### “Can’t I just use the system Python?”

Apple’s `/usr/bin/python3` is SIP‑locked, outdated, and missing headers. Don’t.

### “Isn’t this pyenv setup overkill?”

Maybe – but it’s the one method that consistently sidesteps Homebrew’s madness **and** lets you juggle versions.

### “I still get the error!”

Run:

```bash
which python python3
python -m pip config list
printenv | grep -E 'PIP_|PYTHON'
```

If any path isn’t in `~/.pyenv/shims` or `global.user=true` re‑appears, congrats – another tool rewrote your config. Re‑run the script. 🔪

---

## Contributing

Feel free to PR improvements, but only if your change **reduces** misery. Extra rants welcome – humour heals.

---

## License

MIT. Because the only thing worse than Python packaging is legalese.

