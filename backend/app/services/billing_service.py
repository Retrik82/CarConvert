from __future__ import annotations

from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.user import User
from app.repositories.user_repository import UserRepository
from app.services.settings_service import SettingsService


class InsufficientBalanceError(Exception):
    def __init__(self, balance: Decimal, price: Decimal) -> None:
        self.balance = balance
        self.price = price
        super().__init__(f"Insufficient balance: {balance} < {price}")


class BillingService:
    def __init__(self, db: AsyncSession) -> None:
        self._users = UserRepository(db)
        self._settings = SettingsService(db)

    async def charge_for_generation(self, user: User) -> Decimal:
        price = await self._settings.get_generation_price()
        balance = Decimal(str(user.balance))
        if balance < price:
            raise InsufficientBalanceError(balance, price)
        await self._users.update_balance(user, balance - price)
        return price


async def charge_for_generation(db: AsyncSession, user: User) -> Decimal:
    return await BillingService(db).charge_for_generation(user)
