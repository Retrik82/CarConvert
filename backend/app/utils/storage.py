from pathlib import Path


def check_upload_dir_writable(upload_dir: str) -> tuple[bool, str | None]:
    path = Path(upload_dir)
    try:
        path.mkdir(parents=True, exist_ok=True)
        probe = path / ".write_test"
        probe.write_text("ok")
        probe.unlink()
        return True, None
    except OSError as exc:
        return False, str(exc)
