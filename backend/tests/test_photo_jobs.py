from datetime import datetime, timedelta, timezone
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.services.job_service import JobService, _fail_job


@pytest.mark.asyncio
async def test_fail_stale_active_jobs_marks_failed_and_refunds() -> None:
    db = AsyncMock()
    service = JobService(db)
    stale_job = MagicMock()
    stale_job.user_id = "user-1"
    stale_job.charged_amount = Decimal("0.10")

    user = MagicMock()
    user.balance = Decimal("1.00")

    with (
        patch.object(service._jobs, "list_stale_active", AsyncMock(return_value=[stale_job])),
        patch.object(service._jobs, "update_status", AsyncMock()) as update_status,
        patch("app.services.job_service.UserRepository") as user_repo_cls,
        patch("app.services.job_service.BillingService") as billing_cls,
    ):
        user_repo_cls.return_value.get_by_id = AsyncMock(return_value=user)
        billing = billing_cls.return_value
        billing.refund_for_generation = AsyncMock()

        failed = await service.fail_stale_active_jobs(user_id="user-1")

    assert failed == 1
    update_status.assert_awaited_once()
    billing.refund_for_generation.assert_awaited_once_with(user, Decimal("0.10"))


@pytest.mark.asyncio
async def test_fail_job_refunds_charge() -> None:
    db = AsyncMock()
    job = MagicMock()
    job.user_id = "user-1"
    job.charged_amount = Decimal("0.10")

    with (
        patch("app.services.job_service.JobService") as service_cls,
        patch("app.services.job_service._refund_job_charge", AsyncMock()) as refund,
    ):
        service_cls.return_value._jobs.update_status = AsyncMock()
        await _fail_job(db, job, error="boom")

    refund.assert_awaited_once_with(db, job)
