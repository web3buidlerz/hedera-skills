# LayerZero OFT Examples

Condensed patterns from Scaffold-HBAR `templates/bridge` (`packages/foundry/contracts/layerzero` + `script/layerzero`). Prefer the template for production copy-paste.

## Sepolia OFT

```solidity
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

contract MyOFT is OFT {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _owner,
        uint256 _preMint
    ) OFT(_name, _symbol, _lzEndpoint, _owner) Ownable(_owner) {
        if (_preMint > 0) {
            _mint(_owner, _preMint);
        }
    }
}
```

`OAppCore` does not initialize OZ Ownable — call `Ownable(_owner)` in the concrete constructor.

## Hedera HTS connector OFT

```solidity
abstract contract HTSConnector is OFTCore, KeyHelper, HederaTokenService {
    address public htsTokenAddress;
    uint8 internal constant HTS_DECIMALS = 18;

    constructor(string memory _name, string memory _symbol, address _lzEndpoint, address _delegate)
        payable
        OFTCore(HTS_DECIMALS, _lzEndpoint, _delegate)
    {
        // createFungibleToken via 0x167 with supply key = this contract
        // store htsTokenAddress; emit TokenCreated
    }

    function approvalRequired() external pure returns (bool) {
        return true;
    }

    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);
        // transferToken(_from → this) then burnToken
    }

    function _credit(address _to, uint256 _amountLD, uint32 /*_srcEid*/)
        internal
        override
        returns (uint256)
    {
        // mintToken then transferToken(this → _to)
        return _amountLD;
    }
}

contract MyHTSConnectorOFT is HTSConnector {
    constructor(string memory _name, string memory _symbol, address _lzEndpoint, address _delegate)
        payable
        HTSConnector(_name, _symbol, _lzEndpoint, _delegate)
        Ownable(_delegate)
    {}
}
```

## WireOApp (one side)

```solidity
bytes32 remotePeer = bytes32(uint256(uint160(remoteOApp)));
IOAppCore(localOApp).setPeer(cfg.remoteEid, remotePeer);

IMessageLibManager ep = IMessageLibManager(cfg.endpointV2);
ep.setSendLibrary(localOApp, cfg.remoteEid, cfg.sendUln302);
ep.setReceiveLibrary(localOApp, cfg.remoteEid, cfg.receiveUln302, 0);

// setConfig: ExecutorConfig (type 1) on send ULN
// setConfig: UlnConfig (type 2) on send + receive ULN (DVN set)

EnforcedOptionParam[] memory enforced = new EnforcedOptionParam[](1);
enforced[0] = EnforcedOptionParam({
    eid: cfg.remoteEid,
    msgType: 1,
    options: OptionsBuilder.newOptions().addExecutorLzReceiveOption(80_000, 0)
});
IOAppOptionsType3(localOApp).setEnforcedOptions(enforced);
```

Run wiring on **both** chains (local/remote swapped).

## Send (quote + send)

```solidity
using OptionsBuilder for bytes;

SendParam memory sendParam = SendParam({
    dstEid: cfg.remoteEid,
    to: bytes32(uint256(uint160(receiver))),
    amountLD: amountLD,
    minAmountLD: (amountLD * 9) / 10,
    extraOptions: OptionsBuilder.newOptions().addExecutorLzReceiveOption(80_000, 0),
    composeMsg: "",
    oftCmd: ""
});

MessagingFee memory fee = IOFT(localOFT).quoteSend(sendParam, false);
IOFT(localOFT).send{ value: fee.nativeFee }(sendParam, fee, payable(msg.sender));
```

Hedera → EVM: approve the **HTS token** for the connector, then `send` with quoted native fee.

## Deploy order (template)

```text
1. Deploy MyOFT on Sepolia
2. Deploy MyHTSConnectorOFT on Hedera (with HTS create value)
3. Deploy workers (optional educational mocks) on both chains
4. Wire Sepolia OApp with Hedera peer
5. Wire Hedera OApp with Sepolia peer
6. Verify peers(remoteEid) both ways
7. Associate Hedera account with htsTokenAddress
8. Send + relay (Labs network or educational lzReceive relay)
9. Sync frontend bridge config
```
