from utils import get_config, update_config
from utils.contract_deployer import deploy_with_dependencies
from utils.contract_type import ContractType
from utils.contract_verifier import verify_contract

_config = get_config()
_initialized = False


def _initialize_contract_system():
    """Initialize the contract system on first import"""
    global _initialized
    if _initialized:
        return

    print("Initializing contract system...")

    # 1. Deploy core contracts
    required_contracts = [
        ContractType.PROFESSOR,
        ContractType.STUDENT,
        ContractType.COURSE,
        ContractType.ENROLLMENT,
        ContractType.UNIVERSITY
    ]

    for contract_type in required_contracts:
        contract_name = contract_type.value
        if not _config['contracts'].get(contract_name) or not verify_contract(_config['contracts'][contract_name]):
            print(f"Initializing {contract_name} contract...")
            deploy_with_dependencies(contract_type)

    update_config()
    _initialized = True
    print("Contract system initialized")


# Run initialization when module is imported
_initialize_contract_system()