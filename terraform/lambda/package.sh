#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
rm -f lambda_function.zip
zip -r lambda_function.zip lambda_function.py
echo "Packaged lambda/lambda_function.zip"
