.PHONY: deploy

# Charger les variables d'environnement à partir du fichier .env
include .env
export $(shell sed 's/=.*//' .env)

test : ;forge test -v

coverage : ;forge coverage -v

createFactoryAbi: ;forge build --silent && jq '.abi' ./out/RetrovrsNftFactory.sol/RetrovrsNftFactory.json > ./abi/RetrovrsNftFactory.json

deploySepolia: ;forge script script/DeployRetrovrsNftFactory.s.sol --rpc-url ${SEPOLIA_RPC_URL} --private-key ${ADMIN_RETROVRS_COLLECTION_PRIVATE_KEY} --legacy --broadcast

.PHONY: test

createCollection:
	@if [ -z "$(FACTORY_ADDRESS)" ] || [ -z "$(COLLECTION_NAME)" ] || [ -z "$(COLLECTION_SYMBOL)" ] || [ -z "$(ADMIN_ADDRESS)" ]; then \
		echo "Usage: make createCollection FACTORY_ADDRESS=<factory_address> COLLECTION_NAME=<collection_name> COLLECTION_SYMBOL=<collection_symbol> ADMIN_ADDRESS=<admin_address>"; \
		exit 1; \
	fi
	cast send $(FACTORY_ADDRESS) "createCollection(string,string,address)" "$(COLLECTION_NAME)" "$(COLLECTION_SYMBOL)" $(ADMIN_ADDRESS) --rpc-url $(SEPOLIA_RPC_URL) --private-key $(ADMIN_RETROVRS_COLLECTION_PRIVATE_KEY) --legacy

addDeployerCollectionRole:
	@if [ -z "$(ADDRESS)" ]; then \
        echo "Usage: make addDeployerCollectionRole ARG=<value>"; \
        exit 1; \
    fi
	cast send $(ADDRESS_LAST_DEPLOYED_FACTORY) "addDeployerCollectionRole(address)" $(ADDRESS) --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --legacy


getDeployerCollectionsByIndex:
	@if [ -z "$(INDEX)" ]; then \
		echo "Usage: make getDeployerCollectionsByIndex ARG=<value>"; \
		exit 1; \
	fi
	cast call $(ADDRESS_LAST_DEPLOYED_FACTORY) "getDeployerCollectionsByIndex(uint256)" "$(INDEX)" --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --legacy

decode:
	@if [ -z "$(HEX_VALUE)" ]; then \
		echo "Usage: make decode HEX_VALUE=<hex_value>"; \
	exit 1; \
	fi
	python3 decode_hex.py $(HEX_VALUE)


addMinterRole:
	@if [ -z "$(ADDRESS_COLLECTION)" ] || [ -z "$(MINTER)" ]; then \
		echo "Usage: make addMinterRole ADDRESS_COLLECTION=<collection_address> MINTER=<minter_address>"; \
		exit 1; \
	fi	
	cast send $(ADDRESS_COLLECTION) "addMinterRole(address)" $(MINTER) --rpc-url $(SEPOLIA_RPC_URL) --private-key $(ADMIN_RETROVRS_COLLECTION_PRIVATE_KEY) --legacy


flattenContract:
	@if [ -z "$(INPUT)" ]; then \
		echo "Usage: make flattenContract INPUT=<input>"; \
		exit 1; \
	fi
	forge flatten --output src/$(INPUT).flattened.sol src/$(INPUT).sol

# forge verify-contract 0xC8bC7a736d330c4ce7bcB067AD075434eb1Df8CA src/RetrovrsNft.flattened.sol:RetrovrsNft --chain 11155111 --compiler-version v0.8.26 --num-of-optimizations 200 --constructor-args $(cast abi-encode "constructor(string,string,address)" "Luxury handbags" "LUXBAGS" 0x95F20f515FF135f861b23BBbe0EB9d27941247E3) --etherscan-api-key <etherscan_api_key> --watch --force 
verifyDeployedRetrovrsNftOnSepolia:
	@if [ -z "$(ADDRESS)" ]; then \
		echo "Usage: make verifyDeployedContractOnSepolia ARG=<value>"; \
		exit 1; \
	fi
	forge verify-contract --chain-id 11155111 $(ADDRESS) --etherscan-api-key $(ETHERSCAN_API_KEY) src/RetrovrsNft.flattened.sol:RetrovrsNft


 
checkVerify:
	@if [ -z "$(GUID)" ]; then \
		echo "Usage: make checkVerify ARG=<value>"; \
		exit 1; \
	fi
	forge verify-check --chain-id 11155111 '$(GUID)' --etherscan-api-key $(ETHERSCAN_API_KEY)


getMinter:
	@if [ -z "$(ADDRESS_COLLECTION)" ] [ -z "$(INDEX)" ]; then \
		echo "Usage: make getMinter ADDRESS_COLLECTION=<collection_address> INDEX=<index>"; \
		exit 1; \
	fi	
	cast call $(ADDRESS_COLLECTION) "getMinter(uint256)" $(INDEX) --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --legacy
	
