#!/usr/bin/env python3
"""Render a preview of a .npy / .npz file for the npy.yazi plugin.

Metadata comes from the .npy header, which is a literal Python dict, so shape
and dtype are read with the stdlib alone - a multi-GB array previews without
touching its data. Values are shown when numpy is importable; when it isn't we
re-run once under `uv run --with numpy` before falling back to metadata only.

Usage: preview.py <file> [--width N]
"""

import ast
import os
import struct
import subprocess
import shutil
import sys
import zipfile

NO_REEXEC = "YAZI_NPY_NO_REEXEC"
MAX_NPZ_ENTRIES = 32

_color = os.getenv("NO_COLOR") is None


def sgr(code, s):
    return f"\x1b[{code}m{s}\x1b[0m" if _color else s


def bold(s):
    return sgr("1", s)


def dim(s):
    return sgr("2", s)


def label(k, v):
    return "  " + dim(f"{k:<8}") + str(v)


def human(n):
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if n < 1024:
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} PiB"


def read_header(fh):
    """Return (major, minor, header_dict) for the .npy stream at `fh`."""
    magic = fh.read(6)
    if magic != b"\x93NUMPY":
        raise ValueError("not a .npy file (bad magic)")
    major, minor = struct.unpack("<BB", fh.read(2))
    if major == 1:
        raw = fh.read(2)
        if len(raw) < 2:
            raise ValueError("truncated header")
        (hlen,) = struct.unpack("<H", raw)
    elif major in (2, 3):
        raw = fh.read(4)
        if len(raw) < 4:
            raise ValueError("truncated header")
        (hlen,) = struct.unpack("<I", raw)
    else:
        raise ValueError(f"unsupported .npy version {major}.{minor}")

    body = fh.read(hlen)
    if len(body) < hlen:
        raise ValueError("truncated header")
    encoding = "utf-8" if major >= 3 else "latin1"
    d = ast.literal_eval(body.decode(encoding))
    if not isinstance(d, dict) or "shape" not in d or "descr" not in d:
        raise ValueError("malformed header")
    return major, minor, d


def itemsize(descr):
    """Bytes per element for a simple dtype string, or None if not derivable."""
    if isinstance(descr, list):  # structured dtype: sum the fields
        total = 0
        for field in descr:
            sub = itemsize(field[1]) if len(field) > 1 else None
            if sub is None:
                return None
            total += sub * (1 if len(field) < 3 else _count(field[2]))
        return total
    if not isinstance(descr, str):
        return None
    base = descr.lstrip("<>=|")
    if not base:
        return None
    kind, rest = base[0], base[1:]
    if not rest.isdigit():
        return None
    n = int(rest)
    return n * 4 if kind == "U" else n  # unicode stores 4 bytes per code point


def _count(shape):
    n = 1
    for s in shape if isinstance(shape, (tuple, list)) else (shape,):
        n *= int(s)
    return n


def dtype_str(descr):
    if isinstance(descr, list):
        fields = ", ".join(str(f[0]) for f in descr[:6])
        more = f", +{len(descr) - 6} more" if len(descr) > 6 else ""
        return f"structured ({len(descr)} fields: {fields}{more})"
    return str(descr)


def header_lines(fh, title):
    major, minor, d = read_header(fh)
    shape = tuple(d["shape"])
    n = _count(shape)

    lines = [bold(title)]
    lines.append(label("shape", shape if shape else "() scalar"))
    lines.append(label("dtype", dtype_str(d["descr"])))
    lines.append(label("order", "Fortran" if d.get("fortran_order") else "C"))
    size = itemsize(d["descr"])
    lines.append(label("items", f"{n:,}" + (f"   {human(n * size)}" if size else "")))
    lines.append(label("format", f"npy v{major}.{minor}"))
    return lines


def npz_lines(path):
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        lines = [bold(f"npz archive - {len(names)} array(s)"), ""]
        for name in names[:MAX_NPZ_ENTRIES]:
            title = name[:-4] if name.endswith(".npy") else name
            try:
                with z.open(name) as fh:
                    lines += header_lines(fh, title)
            except Exception as e:  # one bad member shouldn't kill the preview
                lines += [bold(title), label("error", e)]
            lines.append("")
        if len(names) > MAX_NPZ_ENTRIES:
            lines.append(dim(f"  ... and {len(names) - MAX_NPZ_ENTRIES} more"))
    return lines


def value_lines(np, path, width):
    """Values and summary stats, read through a memory map."""
    try:
        a = np.load(path, mmap_mode="r")
    except ValueError:
        # allow_pickle would execute arbitrary code from the file; don't.
        return ["", dim("  object array - not unpickled")]

    opts = dict(threshold=500, edgeitems=3, linewidth=max(40, width - 2),
                precision=4, suppress=True)
    with np.printoptions(**opts):
        lines = ["", *str(a).splitlines()]

    if a.dtype.kind not in "iuf" or a.size == 0:
        return lines

    # Stats over a corner of the array, so a huge one stays cheap.
    cap = 1000
    sliced = a[tuple(slice(0, cap) for _ in a.shape)] if a.ndim else a
    b = np.asarray(sliced, dtype="float64")
    nans = int(np.isnan(b).sum())
    infs = int(np.isinf(b).sum())
    finite = b[np.isfinite(b)]

    if finite.size:
        stats = f"min {finite.min():.6g}   max {finite.max():.6g}   mean {finite.mean():.6g}"
    else:
        stats = "no finite values"
    if nans:
        stats += f"   NaN {nans:,}"
    if infs:
        stats += f"   Inf {infs:,}"
    if b.size < a.size:
        stats += f"   (first {cap} per axis)"
    return lines + ["", dim("  " + stats)]


def rerun_under_uv(argv):
    """Re-run this script with numpy provided by uv. Returns its stdout, or None."""
    if os.getenv(NO_REEXEC):
        return None
    uv = shutil.which("uv")
    if not uv:
        return None

    cmd = [uv, "run", "--quiet", "--no-project", "--with", "numpy",
           "python", os.path.abspath(__file__), *argv]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=30,
                           env={**os.environ, NO_REEXEC: "1"})
    except (OSError, subprocess.SubprocessError):
        return None
    return p.stdout if p.returncode == 0 and p.stdout else None


def main(argv):
    if not argv:
        sys.exit("usage: preview.py <file> [--width N]")

    path, width = argv[0], 80
    if "--width" in argv:
        try:
            width = max(20, int(argv[argv.index("--width") + 1]))
        except (IndexError, ValueError):
            pass

    try:
        if zipfile.is_zipfile(path):  # .npz is a zip of .npy members
            print("\n".join(npz_lines(path)))
            return
        with open(path, "rb") as fh:
            lines = header_lines(fh, os.path.basename(path))
    except (OSError, ValueError, SyntaxError) as e:
        sys.exit(f"npy preview: {e}")

    try:
        import numpy as np
    except ImportError:
        out = rerun_under_uv(argv)
        if out is not None:
            sys.stdout.write(out)
            return
        lines += ["", dim("  numpy unavailable - metadata only")]
    else:
        lines += value_lines(np, path, width)

    print("\n".join(lines))


if __name__ == "__main__":
    main(sys.argv[1:])
