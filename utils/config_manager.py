import json
from pathlib import Path

DEFAULT_CONFIG = {
    "node_url": "http://127.0.0.1:8545",
    "deployer_private_key": "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    "deployer_address": "",
    "contracts": {
        "Professor": "",
        "Student": "",
        "Course": "",
        "Enrollment": "",
        "University": ""
    }
}


def get_config_path() -> Path:
    """Get the path to config.json, creating if doesn't exist"""
    config_path = Path(__file__).parent.parent / "config.json"
    if not config_path.exists():
        config_path.write_text(json.dumps(DEFAULT_CONFIG, indent=4))
    return config_path

def get_config() -> dict:
    """Load the config file"""
    with open(get_config_path(), 'r') as f:
        return json.load(f)

def update_config():
    """Save the current config (simplified version)"""
    from . import config  # Import the module-level config
    with open(get_config_path(), 'w') as f:
        json.dump(config, f, indent=4)