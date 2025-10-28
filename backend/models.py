from __future__ import annotations

from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum as SAEnum,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


class Locker(Base):
    __tablename__ = "lockers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    description: Mapped[str | None] = mapped_column(String(255))

    items: Mapped[list["Item"]] = relationship("Item", back_populates="locker")


class Item(Base):
    __tablename__ = "items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    sku: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    quantity: Mapped[int] = mapped_column(Integer, default=0)
    minimum_quantity: Mapped[int] = mapped_column(Integer, default=0)
    locker_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("lockers.id"))
    is_supply: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    max_return_time_hours: Mapped[int | None] = mapped_column(Integer)

    locker: Mapped[Locker | None] = relationship("Locker", back_populates="items")
    movements: Mapped[list["InventoryMovement"]] = relationship(
        "InventoryMovement", back_populates="item", cascade="all, delete-orphan"
    )
    purchase_requests: Mapped[list["PurchaseRequest"]] = relationship(
        "PurchaseRequest", back_populates="item", cascade="all, delete-orphan"
    )
    supply_withdrawals: Mapped[list["SupplyWithdrawal"]] = relationship(
        "SupplyWithdrawal", back_populates="item", cascade="all, delete-orphan"
    )


class MovementType(str, PyEnum):
    IN = "in"
    OUT = "out"


class InventoryMovement(Base):
    __tablename__ = "inventory_movements"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    item_id: Mapped[int] = mapped_column(Integer, ForeignKey("items.id"))
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    movement_type: Mapped[MovementType] = mapped_column(
        SAEnum(MovementType), nullable=False
    )
    note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    item: Mapped[Item] = relationship("Item", back_populates="movements")
    supply_withdrawal: Mapped["SupplyWithdrawal" | None] = relationship(
        "SupplyWithdrawal", back_populates="movement", uselist=False
    )


class PurchaseStatus(str, PyEnum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    RECEIVED = "received"


class PurchaseRequest(Base):
    __tablename__ = "purchase_requests"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    item_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("items.id"))
    item_name: Mapped[str] = mapped_column(String(150), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    requested_by: Mapped[str | None] = mapped_column(String(150))
    status: Mapped[PurchaseStatus] = mapped_column(
        SAEnum(PurchaseStatus), default=PurchaseStatus.PENDING, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    notes: Mapped[str | None] = mapped_column(Text)

    item: Mapped[Item | None] = relationship("Item", back_populates="purchase_requests")


class SupplyWithdrawal(Base):
    __tablename__ = "supply_withdrawals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    movement_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("inventory_movements.id"), unique=True
    )
    item_id: Mapped[int] = mapped_column(Integer, ForeignKey("items.id"), nullable=False)
    quantity_withdrawn: Mapped[int] = mapped_column(Integer, nullable=False)
    quantity_returned: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    withdrawn_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    due_at: Mapped[datetime | None] = mapped_column(DateTime)
    returned_at: Mapped[datetime | None] = mapped_column(DateTime)
    note: Mapped[str | None] = mapped_column(Text)

    item: Mapped[Item] = relationship("Item", back_populates="supply_withdrawals")
    movement: Mapped[InventoryMovement] = relationship(
        "InventoryMovement", back_populates="supply_withdrawal"
    )

    @property
    def pending_quantity(self) -> int:
        return self.quantity_withdrawn - self.quantity_returned

    def is_overdue(self, reference: datetime | None = None) -> bool:
        if self.returned_at is not None:
            return False
        if self.due_at is None:
            return False
        reference = reference or datetime.utcnow()
        return reference > self.due_at
