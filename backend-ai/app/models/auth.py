from pydantic import BaseModel, Field
from typing import Optional


class TokenResponse(BaseModel):
    id: Optional[str] = None
    name: str
    email: Optional[str] = None
    token: str


class AuthResponse(BaseModel):
    ok: bool
    message: Optional[str] = None
    token: Optional[str] = None
