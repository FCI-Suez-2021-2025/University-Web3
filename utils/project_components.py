import json

from utils import web3, ABI_DIR, BIN_DIR, config, CONFIG_PATH


def get_web3():
    return web3


def get_config():
    return config


def get_abi_dir():
    return ABI_DIR


def get_bin_dir():
    return BIN_DIR


def update_config():
    new_config = config

    # Write the updated config back to the file
    with open(CONFIG_PATH, "w") as config_file:
        json.dump(new_config, config_file, indent=4)
