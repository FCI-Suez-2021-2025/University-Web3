<h1 align="center">🎓 University-Web3</h1>

<div align="center">

![GitHub Repo stars](https://img.shields.io/github/stars/FCI-Suez-2021-2025/University-Web3)
![GitHub forks](https://img.shields.io/github/forks/FCI-Suez-2021-2025/University-Web3)
![GitHub watchers](https://img.shields.io/github/watchers/FCI-Suez-2021-2025/University-Web3)
![GitHub last commit](https://img.shields.io/github/last-commit/FCI-Suez-2021-2025/University-Web3)
![Github Created At](https://img.shields.io/github/created-at/FCI-Suez-2021-2025/University-Web3?color=1a73e8)
</div>

---

## 📋 Prerequisites

Before running the project, you need to:

1. Install the required packages using `pip install -r requirements.txt`.
2. Set up a local blockchain using **Foundry** and **Anvil**.
3. Choose a private key from Anvil’s output.
4. Create a `config.json` file in your project root with the following structure:

```json
{
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
```

⚠️ **Do not use real or sensitive private keys. Only use the ones generated by Anvil for local development.**

---

### 🛠 Install Foundry
### ⚠️ Important Note for Windows users

Use any bash terminal like Git Bash or WSL Terminal to install and run foundryup and anvil

---

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

---

### 🔥 Run Anvil

Start your local blockchain in the terminal with:

```bash
anvil
```

This runs a local node at `http://127.0.0.1:8545` and prints out a list of pre-funded private keys and addresses. Choose one private key and paste it into your `config.json`.

---