# Oracle Adapter Examples

Generic libs and read patterns for Hedera `IPriceOracle` adapters. Prefer a concrete project template for full contract copy-paste.

## Shared libs

```solidity
library PairLib {
    function pairKey(string memory baseSymbol, string memory quoteSymbol)
        internal
        pure
        returns (bytes32)
    {
        require(bytes(baseSymbol).length != 0 && bytes(quoteSymbol).length != 0);
        return keccak256(abi.encode(baseSymbol, quoteSymbol));
    }
}

library ProviderLib {
    bytes32 internal constant CHAINLINK = keccak256("CHAINLINK");
    bytes32 internal constant SUPRA = keccak256("SUPRA");
    bytes32 internal constant PYTH = keccak256("PYTH");
}

library AssetConversionLib {
    uint256 internal constant PRICE_SCALE = 1e18;

    function baseToQuote(
        uint256 baseAmount,
        uint8 baseDecimals,
        uint8 quoteDecimals,
        uint256 priceE18
    ) internal pure returns (uint256) {
        require(priceE18 != 0);
        uint256 quoteUnits = Math.mulDiv(baseAmount, 10 ** quoteDecimals, 10 ** baseDecimals);
        return Math.mulDiv(quoteUnits, priceE18, PRICE_SCALE);
    }

    function quoteToBase(
        uint256 quoteAmount,
        uint8 baseDecimals,
        uint8 quoteDecimals,
        uint256 priceE18
    ) internal pure returns (uint256) {
        require(priceE18 != 0);
        uint256 baseUnits = Math.mulDiv(quoteAmount, 10 ** baseDecimals, 10 ** quoteDecimals);
        return Math.mulDiv(baseUnits, PRICE_SCALE, priceE18);
    }
}
```

## Decimal normalization

```solidity
uint8 constant NORMALIZED_DECIMALS = 18;

function normalizeToE18(uint256 amount, uint8 decimals) pure returns (uint256) {
    if (decimals == NORMALIZED_DECIMALS) return amount;
    if (decimals < NORMALIZED_DECIMALS) {
        return amount * (10 ** (NORMALIZED_DECIMALS - decimals));
    }
    return amount / (10 ** (decimals - NORMALIZED_DECIMALS));
}
```

## Chainlink read sketch

```solidity
(uint80 roundId, int256 answer,, uint256 updatedAt, uint80 answeredInRound) =
    feed.latestRoundData();

if (answeredInRound < roundId || updatedAt == 0) revert OracleIncompleteRound();
if (answer <= 0) revert OracleInvalidPrice();
if (block.timestamp - updatedAt > MAX_STALENESS) {
    revert OracleStalePrice(updatedAt, MAX_STALENESS);
}

uint256 priceE18 = normalizeToE18(uint256(answer), feed.decimals());
```

Constructor config shape: `pairKey → feed address` (immutable after deploy).

## Supra read sketch

```solidity
ISupraSValueFeed.PriceFeed memory pf = SUPRA_ORACLE.getSvalue(supraPairIds[pairKey]);
if (pf.time == 0) revert OracleIncompleteRound();
if (pf.price == 0) revert OracleInvalidPrice();

uint256 updatedAt = pf.time > 10_000_000_000 ? pf.time / 1_000 : pf.time;
if (block.timestamp - updatedAt > MAX_STALENESS) {
    revert OracleStalePrice(updatedAt, MAX_STALENESS);
}

uint256 priceE18 = normalizeToE18(pf.price, uint8(pf.decimals));
```

Constructor config shape: push-oracle address + `pairKey → supraPairId`.

## Pyth read / update sketch

```solidity
function updatePrice(bytes[] calldata updateData) external payable {
    uint256 fee = PYTH.getUpdateFee(updateData);
    if (msg.value < fee) revert PythUpdateFeeTooLow(msg.value, fee);
    PYTH.updatePriceFeeds{ value: msg.value }(updateData);
}

PythStructs.Price memory price = PYTH.getPriceNoOlderThan(priceId, MAX_STALENESS);
if (price.publishTime == 0) revert OracleIncompleteRound();
if (price.price <= 0) revert OracleInvalidPrice();
if (price.conf > uint64(price.price)) revert PythInvalidConfidence();
```

Pyth exponent normalization (signed `expo`):

```solidity
function normalizePythToE18(int64 price, int32 expo) pure returns (uint256) {
    uint256 positive = uint64(price);
    if (expo >= 0) {
        return positive * (10 ** (18 + uint32(expo)));
    }
    uint256 mag = uint256(-int256(expo));
    if (mag <= 18) return positive * (10 ** (18 - mag));
    return positive / (10 ** (mag - 18));
}
```

Constructor config shape: Pyth contract + `pairKey → bytes32 priceId`.

## Consumer conversion

```solidity
IPriceOracle.PriceData memory data = oracle.latestPrice(pairKey);
uint256 quoteAmount = AssetConversionLib.baseToQuote(
    baseAmount, baseDecimals, quoteDecimals, data.priceE18
);
```

Ownable `setOracle(address)` switches providers without redeploying business logic.
