# 📌 Project Overview
Enterprise-grade testing framework for automotive Electronic Control Units (ECUs) with CI/CD integration.

## 🎯 Key Features
- **Multi-layer Testing**: Unit, Integration, HIL, Performance
- **Automated CI/CD**: Jenkins pipeline with parallel execution
- **Hardware Integration**: Support for HIL rigs and real ECUs
- **Comprehensive Reporting**: HTML, JUnit, Allure reports
- **ISO 26262 Compliance**: Safety-critical testing standards

## 🏗️ Architecture

─────────────────────────────────────────────┐
│ Jenkins CI/CD Pipeline │
├─────────────────────────────────────────────┤
│ Robot Framework │ Pytest │ HIL Tests │
├─────────────────────────────────────────────┤
│ ECU Simulator / HIL Rigs │
└─────────────────────────────────────────────┘## Auto-build test Fri Mar 20 15:58:26 WEST 2026
