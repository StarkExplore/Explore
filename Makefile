.PHONY: default

ROOT_PROJECT = .
PROJECT_NAME = explore
BUILD_DIR = target

# Default target
default: test

# All relevant targets
all: build test

# Compile the project
build:
	$(MAKE) clean format
	@echo "Building..."
	sozo build

# Test the project
test:
	@echo "Testing everything..."
	sozo test

# Format the project
format:
	@echo "Formatting everything..."
	cairo-format --recursive --print-parsing-errors $(ROOT_PROJECT)

# Check the formatting of the project
check-format:
	@echo "Checking formatting..."
	cairo-format --recursive --check $(ROOT_PROJECT)

# Clean the project
clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)/*
	mkdir -p $(BUILD_DIR)

# Start devnet
devnet:
	katana --seed 0

# Deploy project into katana
migrate:
	sozo migrate