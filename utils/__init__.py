from web3 import Web3
from .config_manager import get_config_path, get_config, update_config

# Initialize config
config = get_config()

# Web3 setup
web3 = Web3(Web3.HTTPProvider(config["node_url"]))

# Set deployer address if private key exists
if config["deployer_private_key"] and not config["deployer_address"]:
    config["deployer_address"] = web3.eth.account.from_key(config["deployer_private_key"]).address
    update_config()

# Path constants
PROJECT_ROOT = get_config_path().parent
ABI_DIR = PROJECT_ROOT / "abi"
BIN_DIR = PROJECT_ROOT / "bin"

# Create directories if they don't exist
ABI_DIR.mkdir(exist_ok=True)
BIN_DIR.mkdir(exist_ok=True)