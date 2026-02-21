#!/usr/bin/env bash
set -e

echo "===== Brew Health Check ====="
echo

echo ">> brew doctor"
brew doctor || true
echo

echo ">> brew missing"
brew missing || true
echo

echo ">> brew outdated"
brew outdated || true
echo

echo "===== Done ====="
