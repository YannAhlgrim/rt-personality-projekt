#!/usr/bin/env python3
import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from server import lambda_handler

# This is the entry point that AWS Lambda will call
def handler(event, context):
    return lambda_handler(event, context)

# For compatibility, also export lambda_handler directly
__all__ = ['handler', 'lambda_handler']