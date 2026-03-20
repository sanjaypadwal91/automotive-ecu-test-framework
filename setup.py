"""
Setup script for Automotive ECU Test Framework
"""
from setuptools import setup, find_packages

setup(
    name="automotive-ecu-test-framework",
    version="1.0.0",
    author="Your Name",
    author_email="your.name@company.com",
    description="Enterprise-grade automotive ECU testing framework",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: Other/Proprietary License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.8",
    install_requires=[
        line.strip() for line in open("requirements.txt").readlines()
        if line.strip() and not line.startswith("#")
    ],
)