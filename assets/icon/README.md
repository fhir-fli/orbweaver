# App icon

`orbweaver_master.png` is the source. `tool/make_icon.py` renders it into all
five Android densities and all sixteen iOS entries:

    python3 tool/make_icon.py

`orbweaver.png` is the 1024 master it also writes, for the store listings.

## What the master is

Grey's artwork, with two corrections that the platforms require: the background
is flattened to solid navy (0xFF1E4E8C) because a gradient flattens badly at
small sizes and Apple rejects an alpha channel, and everything sits inside 80%
of the square because Android masks the icon to a circle, a squircle or a
rounded square depending on the launcher.

## Two things that were tried and are worse

**Drawing at the target pixel size without supersampling.** It removes the
antialiasing, and the result is jagged rather than sharp. Small icons are
supposed to be antialiased; the softness that prompted the attempt was an
artefact of viewing them magnified with nearest-neighbour. At 1:1 the full
composition holds down to 40 px.

**A separate simplified mark for the small sizes.** Dropping either half loses
something the other cannot carry: without the web it does not say Orbweaver,
without the book it does not say what the app is.

Nothing in this directory ships. `assets/icon` is not in the pubspec asset list;
the generated files are written straight into the android and ios trees.
