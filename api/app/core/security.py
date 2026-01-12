from datetime import datetime, timedelta
from jose import jwt
from app.core.config import settings

def verify_password(plain_password, hashed_password):
    return plain_password == hashed_password  # Plain text для теста

def get_password_hash(password):
    return password  # Plain text для теста

def create_access_token(subject: str, expires_delta: timedelta = None) -> str:
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=30)
    to_encode = {"exp": expire, "sub": subject}
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt
