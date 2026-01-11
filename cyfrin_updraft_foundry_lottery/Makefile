.PHONY: deploy-sepolia simulate-sepolia

deploy-sepolia:
	forge script script/RaffleDeploySepolia.s.sol \
	--rpc-url $$SEPOLIA_RPC_URL \
	--private-key $$MY_PRIVATE_KEY \
	--chain sepolia \
	--broadcast --verify \
	-vvvv

simulate-sepolia:
	forge script script/RaffleDeploySepolia.s.sol \
		--fork-url "$${SEPOLIA_RPC_URL}" \
		-vvvv

participate:
	forge script script/RaffleParticipate.s.sol \
	--rpc-url $$SEPOLIA_RPC_URL \
	--private-key $$MY_PRIVATE_KEY \
	--chain sepolia \
	--broadcast \
	-vvvv

reveal:
	forge script script/RaffleRevealResult.s.sol \
	--rpc-url $$SEPOLIA_RPC_URL \
	--private-key $$MY_PRIVATE_KEY \
	--chain sepolia \
	--broadcast \
	-vvvv