import os
import platform
import setuptools
import subprocess
import re
import shutil

# Print out our uname for debugging purposes
uname = platform.uname()
print(uname)

env = os.environ

# Clean out any existing files
# subprocess.call(["make", "clean"], env=env)

# Build the Go shared module for whatever OS we're on
# subprocess.call(["make", "so"], env=env)

print("Build the CFFI headers")
# subprocess.call(["pip", "install", "cffi~=1.1"], env=env)
subprocess.call(["make", "ffi"], env=env)

with open("pybluemonday/__init__.py", "r", encoding="utf8") as f:
    version = re.search(r'__version__ = "(.*?)"', f.read()).group(1)

with open("README.md", "r", encoding="utf8") as fh:
    long_description = fh.read()

setuptools.setup(
    name="pybluemonday",
    version=version,
    author="Kevin Chung",
    author_email="kchung@nyu.edu",
    description="Python bindings for the bluemonday HTML sanitizer",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/ColdHeat/pybluemonday",
    packages=setuptools.find_packages(),
    # packages=['pybluemonday', 'pybluemonday/bluemonday'],
    include_package_data=True,
    package_dir={'pybluemonday':'.'},
    package_data={
        'pybluemonday': ['bluemonday.cpython-311-x86_64-linux-gnu.so'],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.7",
    # I'm not sure what this value is supposed to be
    # build_golang={"root": "github.com/ColdHeat/pybluemonday"},
    # ext_modules=[setuptools.Extension("pybluemonday/bluemonday", ["bluemonday.go"])],
    setup_requires=["cffi~=1.1"],
    install_requires=["cffi~=1.1"],
)
