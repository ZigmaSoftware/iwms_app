"""
Legacy shim: CustomerCreation now maps to UserCreation.
This keeps existing imports and migrations working after the model rename.
"""
from .userCreation import UserCreation as CustomerCreation

__all__ = ["CustomerCreation"]
