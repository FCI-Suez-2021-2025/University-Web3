from . import web3, config, ABI_DIR, BIN_DIR

def get_web3():
    return web3

def get_config():
    return config

def get_abi_dir():
    return str(ABI_DIR)

def get_bin_dir():
    return str(BIN_DIR)

def update_config():
    from . import update_config as _update_config
    _update_config()