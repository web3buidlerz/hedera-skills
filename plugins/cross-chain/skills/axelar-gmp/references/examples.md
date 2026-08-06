# Axelar GMP Examples

Condensed patterns from Scaffold-HBAR `templates/cross-chain-dca` (`packages/hardhat/contracts`). Prefer the template for production copy-paste.

## IBridgeSender (source abstraction)

```solidity
interface IBridgeSender {
    function send(
        uint256 planId,
        uint256 amountPerExecution,
        address targetToken,
        uint256 minAmountOut
    ) external payable;
}
```

## AxelarMessageSender (Hedera)

```solidity
import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";

contract AxelarMessageSender is IBridgeSender {
    IAxelarGateway public immutable gateway;
    IAxelarGasService public immutable gasService;
    string public destinationChain;
    string public destinationAddress;
    address public authorizedCaller;

    constructor(
        address _gateway,
        address _gasService,
        string memory _destinationChain,
        string memory _destinationAddress
    ) {
        gateway = IAxelarGateway(_gateway);
        gasService = IAxelarGasService(_gasService);
        destinationChain = _destinationChain;
        destinationAddress = _destinationAddress;
    }

    function setAuthorizedCaller(address caller) external onlyOwner {
        authorizedCaller = caller;
    }

    function setDestinationAddress(string memory dest) external onlyOwner {
        destinationAddress = dest;
    }

    function send(
        uint256 planId,
        uint256 amountPerExecution,
        address targetToken,
        uint256 minAmountOut
    ) external payable override {
        require(msg.sender == authorizedCaller, "not authorized");
        require(msg.value > 0, "zero value");

        bytes memory payload = abi.encode(planId, amountPerExecution, targetToken, minAmountOut);

        gasService.payNativeGasForContractCall{ value: msg.value }(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            address(authorizedCaller)
        );
        gateway.callContract(destinationChain, destinationAddress, payload);
    }
}
```

## AxelarMessageReceiver (destination)

```solidity
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";

contract AxelarMessageReceiver is AxelarExecutable {
    string public expectedSourceChain;
    string public expectedSourceAddress;
    IDcaHandler public immutable handler;

    constructor(
        address _gateway,
        string memory _expectedSourceChain,
        string memory _expectedSourceAddress,
        address _handler
    ) AxelarExecutable(_gateway) {
        expectedSourceChain = _expectedSourceChain;
        expectedSourceAddress = _expectedSourceAddress;
        handler = IDcaHandler(_handler);
    }

    function _execute(
        bytes32 /* commandId */,
        string calldata srcChain,
        string calldata srcAddress,
        bytes calldata payload
    ) internal override {
        require(
            keccak256(bytes(_toLower(srcChain))) ==
                keccak256(bytes(_toLower(expectedSourceChain))),
            "invalid source chain"
        );
        require(
            keccak256(bytes(_toLower(srcAddress))) ==
                keccak256(bytes(_toLower(expectedSourceAddress))),
            "invalid source address"
        );

        (uint256 planId, uint256 amountIn, address tokenOut, uint256 minAmountOut) =
            abi.decode(payload, (uint256, uint256, address, uint256));

        handler.handleDcaExecution(planId, amountIn, tokenOut, minAmountOut);
    }
}
```

## DcaOrchestrator (Hedera + HSS + bridge)

```solidity
contract DcaOrchestrator {
    address private constant HSS = address(0x16b);
    int64 private constant RESPONSE_SUCCESS = 22;

    IBridgeSender public immutable bridgeSender;
    mapping(uint256 => DcaPlan) public plans;
    mapping(uint256 => bool) public needsReschedule;

    function executeDca(uint256 planId) external {
        DcaPlan storage plan = plans[planId];
        require(plan.active, "plan not active");
        require(block.timestamp >= plan.lastExecutionTime + plan.intervalSeconds, "too soon");

        plan.lastExecutionTime = block.timestamp;
        plan.executionCount += 1;

        bridgeSender.send{ value: plan.feeForSender }(
            planId,
            plan.amountPerExecution,
            plan.targetToken,
            plan.minAmountOut
        );

        if (plan.maxExecutions > 0 && plan.executionCount >= plan.maxExecutions) {
            plan.active = false;
        } else if (!_scheduleNextExecution(planId)) {
            needsReschedule[planId] = true;
        }
    }

    function _scheduleNextExecution(uint256 planId) internal returns (bool) {
        DcaPlan storage plan = plans[planId];
        bytes memory callData = abi.encodeWithSelector(this.executeDca.selector, planId);
        uint256 expiry = block.timestamp + plan.intervalSeconds;

        if (!IHederaScheduleService(HSS).hasScheduleCapacity(expiry, 4_000_000)) {
            return false;
        }
        (int64 code, ) = IHederaScheduleService(HSS).scheduleCall(
            address(this),
            expiry,
            4_000_000,
            0,
            callData
        );
        return code == RESPONSE_SUCCESS;
    }
}
```

## DcaExecutor (destination business logic)

Bridge-unaware handler — only the authorized receiver may call it.

```solidity
interface IDcaHandler {
    function handleDcaExecution(
        uint256 planId,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut
    ) external;
}

contract DcaExecutor is IDcaHandler {
    ISwapRouter public immutable swapRouter;
    IERC20 public immutable sourceToken;
    address public authorizedCaller;

    function handleDcaExecution(
        uint256 planId,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut
    ) external override {
        require(msg.sender == authorizedCaller, "not authorized");
        sourceToken.approve(address(swapRouter), amountIn);
        swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(sourceToken),
                tokenOut: tokenOut,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            })
        );
    }
}
```

## Deploy And Wire Order

```text
1. Deploy DcaExecutor(swapRouter, sourceToken)           # Sepolia
2. Deploy AxelarMessageReceiver(gateway, "hedera", senderPlaceholder, executor)
3. executor.setAuthorizedCaller(receiver)

4. Deploy AxelarMessageSender(gateway, gasService, "ethereum-sepolia", receiverPlaceholder)  # Hedera
5. Deploy DcaOrchestrator(sender)
6. sender.setAuthorizedCaller(orchestrator)

7. sender.setDestinationAddress(receiver)                # wire Hedera → Sepolia
8. receiver.setExpectedSourceAddress(sender)             # wire Sepolia ← Hedera

9. Fund orchestrator with HBAR (relay gas)
10. Fund executor with source tokens (swap capital)
```
