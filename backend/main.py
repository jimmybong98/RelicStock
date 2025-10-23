from __future__ import annotations

import base64
import io

import qrcode
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from . import models, schemas
from .database import Base, engine, get_session

app = FastAPI(title="RelicStock API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)


def get_db() -> Session:
    with get_session() as session:
        yield session


# Locker endpoints
@app.post("/lockers", response_model=schemas.LockerOut, status_code=status.HTTP_201_CREATED)
def create_locker(locker: schemas.LockerCreate, db: Session = Depends(get_db)):
    if (
        db.query(models.Locker).filter(models.Locker.code == locker.code).first()
        is not None
    ):
        raise HTTPException(status_code=400, detail="Locker code already exists")
    db_locker = models.Locker(**locker.dict())
    db.add(db_locker)
    db.flush()
    db.refresh(db_locker)
    return db_locker


@app.get("/lockers", response_model=list[schemas.LockerOut])
def list_lockers(db: Session = Depends(get_db)):
    return db.query(models.Locker).order_by(models.Locker.code).all()


@app.patch("/lockers/{locker_id}", response_model=schemas.LockerOut)
def update_locker(locker_id: int, locker: schemas.LockerUpdate, db: Session = Depends(get_db)):
    db_locker = db.get(models.Locker, locker_id)
    if db_locker is None:
        raise HTTPException(status_code=404, detail="Locker not found")
    for key, value in locker.dict(exclude_unset=True).items():
        setattr(db_locker, key, value)
    db.add(db_locker)
    db.flush()
    db.refresh(db_locker)
    return db_locker


# Item endpoints
@app.post("/items", response_model=schemas.ItemOut, status_code=status.HTTP_201_CREATED)
def create_item(item: schemas.ItemCreate, db: Session = Depends(get_db)):
    if db.query(models.Item).filter(models.Item.sku == item.sku).first() is not None:
        raise HTTPException(status_code=400, detail="SKU already exists")
    db_item = models.Item(**item.dict())
    db.add(db_item)
    db.flush()
    db.refresh(db_item)
    return db_item


@app.get("/items", response_model=list[schemas.ItemOut])
def list_items(db: Session = Depends(get_db)):
    return db.query(models.Item).order_by(models.Item.name).all()


@app.get("/items/{item_id}", response_model=schemas.ItemOut)
def get_item(item_id: int, db: Session = Depends(get_db)):
    db_item = db.get(models.Item, item_id)
    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return db_item


@app.patch("/items/{item_id}", response_model=schemas.ItemOut)
def update_item(item_id: int, item: schemas.ItemUpdate, db: Session = Depends(get_db)):
    db_item = db.get(models.Item, item_id)
    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    for key, value in item.dict(exclude_unset=True).items():
        setattr(db_item, key, value)
    db.add(db_item)
    db.flush()
    db.refresh(db_item)
    return db_item


@app.post(
    "/items/{item_id}/movements",
    response_model=schemas.MovementOut,
    status_code=status.HTTP_201_CREATED,
)
def register_movement(
    item_id: int, movement: schemas.MovementCreate, db: Session = Depends(get_db)
):
    db_item = db.get(models.Item, item_id)
    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    if movement.movement_type == models.MovementType.OUT and db_item.quantity < movement.quantity:
        raise HTTPException(status_code=400, detail="Insufficient stock for the movement")

    if movement.movement_type == models.MovementType.OUT:
        db_item.quantity -= movement.quantity
    else:
        db_item.quantity += movement.quantity

    movement_data = movement.dict()
    movement_data["item_id"] = item_id
    db_movement = models.InventoryMovement(**movement_data)
    db.add(db_item)
    db.add(db_movement)
    db.flush()
    db.refresh(db_movement)
    return db_movement


@app.get("/items/{item_id}/movements", response_model=list[schemas.MovementOut])
def list_movements(item_id: int, db: Session = Depends(get_db)):
    db_item = db.get(models.Item, item_id)
    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return (
        db.query(models.InventoryMovement)
        .filter(models.InventoryMovement.item_id == item_id)
        .order_by(models.InventoryMovement.created_at.desc())
        .all()
    )


@app.get("/items/{item_id}/qrcode")
def get_item_qrcode(item_id: int, db: Session = Depends(get_db)):
    db_item = db.get(models.Item, item_id)
    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    qr = qrcode.QRCode(version=1, box_size=10, border=2)
    qr.add_data(
        {
            "id": db_item.id,
            "name": db_item.name,
            "sku": db_item.sku,
            "locker": db_item.locker.code if db_item.locker else None,
        }
    )
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    encoded = base64.b64encode(buffer.getvalue()).decode("utf-8")
    return {"mime_type": "image/png", "base64_data": encoded}


# Purchase request endpoints
@app.post(
    "/purchase-requests",
    response_model=schemas.PurchaseRequestOut,
    status_code=status.HTTP_201_CREATED,
)
def create_purchase_request(
    request: schemas.PurchaseRequestCreate, db: Session = Depends(get_db)
):
    db_request = models.PurchaseRequest(**request.dict())
    db.add(db_request)
    db.flush()
    db.refresh(db_request)
    return db_request


@app.get("/purchase-requests", response_model=list[schemas.PurchaseRequestOut])
def list_purchase_requests(db: Session = Depends(get_db)):
    return (
        db.query(models.PurchaseRequest)
        .order_by(models.PurchaseRequest.created_at.desc())
        .all()
    )


@app.patch(
    "/purchase-requests/{request_id}", response_model=schemas.PurchaseRequestOut
)
def update_purchase_request(
    request_id: int, request: schemas.PurchaseRequestUpdate, db: Session = Depends(get_db)
):
    db_request = db.get(models.PurchaseRequest, request_id)
    if db_request is None:
        raise HTTPException(status_code=404, detail="Purchase request not found")
    for key, value in request.dict(exclude_unset=True).items():
        setattr(db_request, key, value)
    db.add(db_request)
    db.flush()
    db.refresh(db_request)
    return db_request


# Dashboard snapshot
@app.get("/snapshot", response_model=schemas.InventorySnapshot)
def get_snapshot(db: Session = Depends(get_db)):
    total_items = db.query(models.Item).count()
    low_stock_items = (
        db.query(models.Item)
        .filter(models.Item.quantity <= models.Item.minimum_quantity)
        .count()
    )
    pending_requests = (
        db.query(models.PurchaseRequest)
        .filter(models.PurchaseRequest.status == models.PurchaseStatus.PENDING)
        .count()
    )
    return schemas.InventorySnapshot(
        total_items=total_items,
        low_stock_items=low_stock_items,
        pending_requests=pending_requests,
    )
