from __future__ import annotations

from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.user import User
from app.services.settings_service import get_generation_price


class InsufficientBalanceError(Exception):
    def __init__(self, balance: Decimal, price: Decimal) -> None:
        self.balance = balance
        self.price = price
        super().__init__(f"Insufficient balance: {balance} < {price}")


async def charge_for_generation(db: AsyncSession, user: User) -> Decimal:
    price = await get_generation_price(db)
    balance = Decimal(str(user.balance))
    if balance < price:
        raise InsufficientBalanceError(balance, price)
    user.balance = balance - price
    await db.flush()
    return price
