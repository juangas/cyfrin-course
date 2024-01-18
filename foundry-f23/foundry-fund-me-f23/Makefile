-include .env

build:; forge build

deploy-sepolia:; 
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --account sepoliaWallet --password-file .password --sender $(SEPOLIA_WALLET) --broadcast --verify --etherscan-api-key $(API_KEY) -vvvv

deploy-anvil:; 
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(ANVIL_RPC_URL) --account defaultKey --password-file .password  --broadcast 

withdraw:
	cast send $(CONTRACT_ADDRESS) "withdraw()" --rpc-url $(SEPOLIA_RPC_URL) --account sepoliaWallet --password-file .password