#!/usr/bin/env python3
"""Development-only downloader for the exact official E5 artifacts we ship."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import urllib.request

REVISION = "614241f622f53c4eeff9890bdc4f31cfecc418b3"
ARTIFACTS = {
    "model.int8.onnx": (
        "onnx/model_qint8_avx512_vnni.onnx", 118346824,
        "dd476dd0c2514e9b9be83aeb3853fac0763e0bdf4a71645407587d77c48a2d88",
    ),
    "tokenizer.json": (
        "onnx/tokenizer.json", 17082730,
        "0b44a9d7b51c3c62626640cda0e2c2f70fdacdc25bbbd68038369d14ebdf4c39",
    ),
}


def digest(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def prepare(output: Path, overwrite: bool = False) -> None:
    output.mkdir(parents=True, exist_ok=True)
    for name, (source, size, expected) in ARTIFACTS.items():
        destination = output / name
        if destination.exists():
            if destination.stat().st_size == size and digest(destination) == expected:
                print(f"Verified existing {name}")
                continue
            if not overwrite:
                raise ValueError(f"{name} differs from pinned artifact; use --overwrite to replace it")
        url = f"https://huggingface.co/intfloat/multilingual-e5-small/resolve/{REVISION}/{source}"
        temporary = destination.with_name(destination.name + ".download")
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "quran-offline-e5-setup/1"})
            with urllib.request.urlopen(request, timeout=120) as stream, temporary.open("wb") as target:
                written = 0
                while chunk := stream.read(1024 * 1024):
                    written += len(chunk)
                    if written > size:
                        raise ValueError(f"Unexpected size for {name}")
                    target.write(chunk)
            if temporary.stat().st_size != size or digest(temporary) != expected:
                raise ValueError(f"Pinned size/hash verification failed for {name}")
            temporary.replace(destination)
            print(f"Downloaded and verified {name}")
        finally:
            temporary.unlink(missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Download approximately 135 MB of official INT8 E5 and tokenizer artifacts")
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[2] / "assets/offline_search")
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()
    prepare(args.output, args.overwrite)


if __name__ == "__main__":
    main()
