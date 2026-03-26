#!/usr/bin/python3

import os
import subprocess
import sys


def generate_image(fname):
    print(f">>> Generating image from: {fname}")
    subprocess.run(
        [
            "texfot",
            "xelatex",
            "-synctex=0",
            "-interaction=batchmode",
            "-halt-on-error",
            "--shell-escape",
            fname,
        ]
    )


def cleanup():
    keep_extensions = {".tex", ".png", ".py"}
    files = [f for f in os.listdir(".") if os.path.isfile(f)]
    for f in files:
        _, ext = os.path.splitext(f)
        if ext.lower() not in keep_extensions:
            try:
                os.remove(f)
                print(f"Deleted: {f}")
            except Exception as e:
                print(f"Exception while deleting {f}: {e}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python generator.py [all | <fname1> <fname2> ...]")
        sys.exit(1)
    if sys.argv[1].lower() == "all":
        files = [
            f
            for f in os.listdir(".")
            if os.path.isfile(f) and f.endswith(".tex") and f != "settings.tex"
        ]
    else:
        files = sys.argv[1:]
    for fname in files:
        generate_image(fname)
    cleanup()
