from scripts.helpful_scripts import (
    get_account,
    get_contract   
)
from brownie import (
    Lottery,
    config,
    network
)

def deploy():
    account = get_account()
    print(account.balance)
    lottery = Lottery.deploy(
        get_contract("vrf_coordinator").address,
        get_contract("eth_usd_price_feed").address,
        config["networks"][network.show_active()]["key_hash"],
        config["networks"][network.show_active()]["subscription_id"],
        {"from": account}
        )


def main():
    deploy()
