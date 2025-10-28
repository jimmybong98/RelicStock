from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from .models import MovementType, PurchaseStatus


class LockerBase(BaseModel):
    code: str = Field(..., min_length=1)
    description: Optional[str] = None


class LockerCreate(LockerBase):
    pass


class LockerUpdate(BaseModel):
    description: Optional[str] = None


class LockerOut(LockerBase):
    id: int

    class Config:
        orm_mode = True


class ItemBase(BaseModel):
    name: str
    sku: str
    description: Optional[str] = None
    quantity: int = 0
    minimum_quantity: int = 0
    locker_id: Optional[int] = None
    is_supply: bool = False
    max_return_time_hours: Optional[int] = Field(default=None, ge=1)


class ItemCreate(ItemBase):
    pass


class ItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    quantity: Optional[int] = None
    minimum_quantity: Optional[int] = None
    locker_id: Optional[int] = None
    is_supply: Optional[bool] = None
    max_return_time_hours: Optional[int] = Field(default=None, ge=1)


class ItemOut(ItemBase):
    id: int
    locker: Optional[LockerOut] = None

    class Config:
        orm_mode = True


class MovementCreate(BaseModel):
    item_id: int
    quantity: int
    movement_type: MovementType
    note: Optional[str] = None


class MovementOut(BaseModel):
    id: int
    item_id: int
    quantity: int
    movement_type: MovementType
    note: Optional[str]
    created_at: datetime

    class Config:
        orm_mode = True


class PurchaseRequestBase(BaseModel):
    item_id: Optional[int] = None
    item_name: str
    quantity: int
    requested_by: Optional[str] = None
    notes: Optional[str] = None


class PurchaseRequestCreate(PurchaseRequestBase):
    pass


class PurchaseRequestUpdate(BaseModel):
    status: Optional[PurchaseStatus] = None
    notes: Optional[str] = None


class PurchaseRequestOut(PurchaseRequestBase):
    id: int
    status: PurchaseStatus
    created_at: datetime

    class Config:
        orm_mode = True


class InventorySnapshot(BaseModel):
    total_items: int
    low_stock_items: int
    pending_requests: int
    overdue_returns: int


class SupplyWithdrawalOut(BaseModel):
    id: int
    item: ItemOut
    quantity_withdrawn: int
    quantity_returned: int
    withdrawn_at: datetime
    due_at: Optional[datetime] = None
    returned_at: Optional[datetime] = None
    note: Optional[str] = None

    class Config:
        orm_mode = True


class SupplyReturnRequest(BaseModel):
    quantity: int = Field(..., gt=0)
    note: Optional[str] = None
