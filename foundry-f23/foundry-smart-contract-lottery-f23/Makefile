-include .env

build:
	forge build

# if --network sepolia is used, then use sepolia stuff, otherwise use anvil stuff

NETWORK_ARGS := --rpc-url $(ANVIL_RPC_URL) --account defaultKey --password-file .password --sender $(DEFAULT_KEY_ADDRESS) --broadcast -vvvv

ifeq ($(findstring --network sepolia,$(ARGS)), --network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account sepoliaChrome --password-file .password --sender $(SEPOLIA_CHROME_ADDRESS) --broadcast --verify --etherscan-api-key $(API_KEY) -vvvv
endif

deploy:
	forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)

sepolia:
	forge script script/DeployRaffle.s.sol:DeployRaffle --fork-url $(SEPOLIA_RPC_URL)

anvil:
	forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(ANVIL_RPC_URL) --account defaultKey --sender $(DEFAULT_KEY_ADDRESS) --password-file .password --broadcast