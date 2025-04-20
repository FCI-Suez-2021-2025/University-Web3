import json
import os

from web3 import Web3


# Get the project root directory (one level up from current_folder/)
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Define the ABI directory
ABI_DIR = os.path.join(PROJECT_ROOT, "abi")

# Define the ABI directory
BIN_DIR = os.path.join(PROJECT_ROOT, "bin")

# Load config.json
CONFIG_PATH = os.path.join(PROJECT_ROOT, "config.json")
if not os.path.exists(CONFIG_PATH):
    raise FileNotFoundError(f"Configuration file not found: {CONFIG_PATH}")

with open(CONFIG_PATH, "r") as config_file:
    config = json.load(config_file)

# Web3 setup
web3 = Web3(Web3.HTTPProvider(config["node_url"]))

# Get deployer address
deployer_private_key = config["deployer_private_key"]
deployer_account = web3.eth.account.from_key(deployer_private_key).address

# Update config with deployer address
config["deployer_address"] = deployer_account

with open(CONFIG_PATH, "w") as config_file:
    json.dump(config, config_file, indent=4)