"""OpenRouter concurrency limits — local semaphores with optional Redis coordination."""

from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager
from typing import AsyncIterator

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

_hint_semaphore: asyncio.Semaphore | None = None
_process_semaphore: asyncio.Semaphore | None = None


def _hint_semaphore() -> asyncio.Semaphore:
    global _hint_semaphore
    if _hint_semaphore is None:
        _hint_semaphore = asyncio.Semaphore(settings.hint_max_concurrent)
    return _hint_semaphore


def _process_semaphore() -> asyncio.Semaphore:
    global _process_semaphore
    if _process_semaphore is None:
        _process_semaphore = asyncio.Semaphore(settings.process_max_concurrent)
    return _process_semaphore


@asynccontextmanager
async def hint_slot() -> AsyncIterator[None]:
    sem = _hint_semaphore()
    await sem.acquire()
    try:
        yield
    finally:
        sem.release()


@asynccontextmanager
async def process_slot() -> AsyncIterator[None]:
    sem = _process_semaphore()
    await sem.acquire()
    try:
        yield
    finally:
        sem.release()
