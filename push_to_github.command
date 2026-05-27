#!/bin/bash
# ============================================================
# Apex Capital Bank — GitHub Push Script
# Double-click this file in Finder to run it
# ============================================================

PROJECT_DIR="$HOME/Desktop/Enterprise_Banking_KPI_Risk_Monitoring_Dashboard"
REPO_URL="https://github.com/KhadyothaReddy/Enterprise_Banking_KPI_Risk_Monitoring_Dashboard.git"

echo ""
echo "============================================================"
echo "  Apex Capital Bank — GitHub Setup"
echo "============================================================"
echo ""

cd "$PROJECT_DIR" || { echo "ERROR: Project folder not found on Desktop!"; exit 1; }

echo "[1/6] Initializing git repository..."
git init

echo ""
echo "[2/6] Configuring git..."
git config user.name "KhadyothaReddy"
git config user.email "khadyotha03@gmail.com"

echo ""
echo "[3/6] Staging all project files..."
git add .
git status

echo ""
echo "[4/6] Creating initial commit..."
git commit -m "Initial project setup: Enterprise Banking KPI & Risk Monitoring Dashboard"

echo ""
echo "[5/6] Adding GitHub remote..."
git remote add origin "$REPO_URL"
git branch -M main

echo ""
echo "[6/6] Pushing to GitHub..."
echo "      (You may be asked to log in to GitHub)"
git push -u origin main

echo ""
echo "============================================================"
echo "  Done! Check your GitHub repo:"
echo "  https://github.com/KhadyothaReddy/Enterprise_Banking_KPI_Risk_Monitoring_Dashboard"
echo "============================================================"
echo ""
read -p "Press Enter to close..."
