// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0 ^0.8.18;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// lib/v1-core/contracts/commons/GlacisCommons.sol

/// @title Glacis Commons
/// @dev Contract for utility functions and structures common to Glacis Client and Infrastructure
contract GlacisCommons {
    struct GlacisData {
        bytes32 messageId;
        uint256 nonce;
        bytes32 originalFrom;
        bytes32 originalTo;
    }

    struct GlacisTokenData {
        address glacisToken;
        uint256 glacisTokenAmount;
    }

    struct GlacisRoute {
        uint256 fromChainId; // WILDCARD means any chain
        bytes32 fromAddress; // WILDCARD means any address
        address fromAdapter; // WILDCARD means any GMP, can also hold address
    }

    struct CrossChainGas {
        uint128 gasLimit;
        uint128 nativeCurrencyValue;
    }

    uint160 constant public WILDCARD = type(uint160).max;
    uint256 constant public GLACIS_RESERVED_IDS = 248;
}

// lib/v1-core/contracts/interfaces/IGlacisRemoteCounterpartManager.sol

/// @title IGlacisRemoteCounterpartManager
/// @notice An interface that defines the existence and addition of a contract's remote counterparts
interface IGlacisRemoteCounterpartManager {
    /// @notice Adds an authorized glacis counterpart component in a remote chain that interacts with this component
    /// @param chainIDs An array with chains of the glacis remote components
    /// @param glacisComponents An array of addresses of the glacis components on remote chains
    function addRemoteCounterparts(
        uint256[] calldata chainIDs,
        bytes32[] calldata glacisComponents
    ) external;

    /// @notice Removes an authorized glacis counterpart component on remote chain that this components interacts with
    /// @param chainId The chainId to remove the remote component
    function removeRemoteCounterpart(uint256 chainId) external;

    /// @notice Gets an authorized glacis counterpart component on remote chain that this components interacts with
    /// @param chainId The chainId to of the remote component
    function getRemoteCounterpart(uint256 chainId) external returns (bytes32);
}

// lib/v1-core/contracts/interfaces/IXERC20.sol

interface IXERC20 {
    /**
     * @notice Emits when a lockbox is set
     *
     * @param _lockbox The address of the lockbox
     */

    event LockboxSet(address _lockbox);

    /**
     * @notice Emits when a limit is set
     *
     * @param _mintingLimit The updated minting limit we are setting to the bridge
     * @param _burningLimit The updated burning limit we are setting to the bridge
     * @param _bridge The address of the bridge we are setting the limit too
     */
    event BridgeLimitsSet(
        uint256 _mintingLimit,
        uint256 _burningLimit,
        address indexed _bridge
    );

    /**
     * @notice Reverts when a user with too low of a limit tries to call mint/burn
     */

    error IXERC20_NotHighEnoughLimits();

    /**
     * @notice Reverts when caller is not the factory
     */
    error IXERC20_NotFactory();

    struct Bridge {
        BridgeParameters minterParams;
        BridgeParameters burnerParams;
    }

    struct BridgeParameters {
        uint256 timestamp;
        uint256 ratePerSecond;
        uint256 maxLimit;
        uint256 currentLimit;
    }

    /**
     * @notice Sets the lockbox address
     *
     * @param _lockbox The address of the lockbox
     */

    function setLockbox(address _lockbox) external;

    /**
     * @notice Updates the limits of any bridge
     * @dev Can only be called by the owner
     * @param _mintingLimit The updated minting limit we are setting to the bridge
     * @param _burningLimit The updated burning limit we are setting to the bridge
     * @param _bridge The address of the bridge we are setting the limits too
     */
    function setLimits(
        address _bridge,
        uint256 _mintingLimit,
        uint256 _burningLimit
    ) external;

    /**
     * @notice Returns the max limit of a minter
     *
     * @param _minter The minter we are viewing the limits of
     *  @return _limit The limit the minter has
     */
    function mintingMaxLimitOf(
        address _minter
    ) external view returns (uint256 _limit);

    /**
     * @notice Returns the max limit of a bridge
     *
     * @param _bridge the bridge we are viewing the limits of
     * @return _limit The limit the bridge has
     */

    function burningMaxLimitOf(
        address _bridge
    ) external view returns (uint256 _limit);

    /**
     * @notice Returns the current limit of a minter
     *
     * @param _minter The minter we are viewing the limits of
     * @return _limit The limit the minter has
     */

    function mintingCurrentLimitOf(
        address _minter
    ) external view returns (uint256 _limit);

    /**
     * @notice Returns the current limit of a bridge
     *
     * @param _bridge the bridge we are viewing the limits of
     * @return _limit The limit the bridge has
     */

    function burningCurrentLimitOf(
        address _bridge
    ) external view returns (uint256 _limit);

    /**
     * @notice Mints tokens for a user
     * @dev Can only be called by a minter
     * @param _user The address of the user who needs tokens minted
     * @param _amount The amount of tokens being minted
     */

    function mint(address _user, uint256 _amount) external;

    /**
     * @notice Burns tokens for a user
     * @dev Can only be called by a minter
     * @param _user The address of the user who needs tokens burned
     * @param _amount The amount of tokens being burned
     */

    function burn(address _user, uint256 _amount) external;
}

/**
 * An optional extension to IXERC20 that the GlacisTokenMediator will query for. 
 * It allows developers to have XERC20 tokens that have different addresses on
 * different chains.
 */
interface IXERC20GlacisExtension {
    /**
     * @notice Returns a token variant for a specific chainId if it exists.
     *
     * @param chainId The chainId of the token variant.
     */
    function getTokenVariant(uint256 chainId) external view returns (bytes32);

    /**
     * @notice Sets a token variant for a specific chainId.
     *
     * @param chainId The chainId of the token variant.
     * @param variant The address of the token variant.
     */
    function setTokenVariant(uint256 chainId, bytes32 variant) external;
}

// lib/v1-core/contracts/libraries/AddressBytes32.sol

/// @title Address to Bytes32 Library
/// @notice A library that converts address to bytes32 and bytes32 to address
library AddressBytes32 {
    /// @notice Converts an address to bytes32
    /// @param addr The address to be converted
    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function toAddress(bytes32 b) internal pure returns (address) {
        return address(uint160(uint256(b)));
    }
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/v1-core/contracts/interfaces/IGlacisAccessControlClient.sol

/// @title IGlacisAccessControlClient
/// @notice An interface that determines Glacis' required access control
interface IGlacisAccessControlClient {
    /// @notice Adds an allowed route for this client
    /// @notice Queries if a route from path GMP+Chain+Address is allowed for this client
    /// @param route The origin route for the message
    /// @param payload The payload of a message
    /// @return True if route is allowed, false otherwise
    function isAllowedRoute(
        GlacisCommons.GlacisRoute memory route,
        bytes memory payload
    ) external view returns (bool);
}

// lib/v1-core/contracts/interfaces/IGlacisRouter.sol

/// @title IGlacisRouterEvents
/// @notice An interface that defines a GlacisRouter's events
abstract contract IGlacisRouterEvents is GlacisCommons
{
    event GlacisAbstractRouter__MessageIdCreated(
        bytes32 indexed messageId,
        bytes32 indexed sender,
        uint256 nonce
    );
    event GlacisAbstractRouter__AdapterRegistered(
        uint8 indexed gmpId,
        address indexed adapterAddress,
        address indexed previousAddress
    );
    event GlacisAbstractRouter__AdapterUnregistered(
        uint8 indexed gmpId,
        address indexed adapterAddress
    );
    event GlacisRouter__ReceivedMessage(
        bytes32 indexed messageId,
        bytes32 indexed from,
        uint256 indexed fromChainId,
        address adapter,
        bytes32 to
    );
    event GlacisRouter__ExecutedMessage(
        bytes32 indexed messageId,
        bytes32 indexed from,
        uint256 indexed fromChainId,
        address adapter,
        bytes32 to
    );
    event GlacisRouter__MessageDispatched(
        bytes32 indexed messageId,
        bytes32 indexed from,
        uint256 indexed toChainId,
        bytes32 to,
        bytes data,
        address[] adapters,
        CrossChainGas[] fees,
        address refundAddress,
        bool retryable
    );
    event GlacisRouter__MessageRetried(
        bytes32 indexed messageId,
        bytes32 indexed from,
        uint256 indexed toChainId,
        bytes32 to,
        bytes data,
        address[] adapters,
        CrossChainGas[] fees,
        address refundAddress
    );
}

/// @title IGlacisRouter
/// @notice An interface that defines an interface that sends and receives messages across chains
interface IGlacisRouter {
    /// @notice Routes the payload to the specific address on the destination chain
    /// using specified adapters
    /// @param chainId Destination chain (EIP-155)
    /// @param to Destination address on remote chain
    /// @param payload Payload to be routed
    /// @param adapters An array of adapters to be used for the routing (addresses 0x01-0xF8 for Glacis adapters 
    /// or specific addresses for custom adapters)
    /// @param fees Array of fees to be sent to each GMP & custom adapter for routing (must be same length as gmps)
    /// @param refundAddress An address for native currency to be sent to that are greater than fees charged. If it is a 
    /// contract it needs to support receive function, reverted otherwise
    /// @param retryable True if this message could pottentially be retried
    /// @return A tuple with a bytes32 messageId and a uint256 nonce
    function route(
        uint256 chainId,
        bytes32 to,
        bytes memory payload,
        address[] memory adapters,
        GlacisCommons.CrossChainGas[] memory fees,
        address refundAddress,
        bool retryable
    ) external payable returns (bytes32, uint256);

    /// @notice Retries routing the payload to the specific address on destination chain
    /// using specified GMPs and quorum
    /// @param chainId Destination chain (EIP-155)
    /// @param to Destination address on remote chain
    /// @param payload Payload to be routed
    /// @param adapters An array of adapters to be used for the routing (addresses 0x01-0xF8 for Glacis adapters 
    /// or specific addresses for custom adapters)
    /// @param fees Array of fees to be sent to each GMP & custom adapter for routing (must be same length as gmps)
    /// @param refundAddress An address for native currency to be sent to that are greater than fees charged. If it is a 
    /// contract it needs to support receive function, tx will revert otherwise
    /// @param messageId The messageId to retry
    /// @param nonce Unique value for this message routing
    /// @return A tuple with a bytes32 messageId and a uint256 nonce
    function routeRetry(
        uint256 chainId,
        bytes32 to,
        bytes memory payload,
        address[] memory adapters,
        GlacisCommons.CrossChainGas[] memory fees,
        address refundAddress,
        bytes32 messageId,
        uint256 nonce
    ) external payable returns (bytes32, uint256);

    /// @notice Receives a cross chain message from an IGlacisAdapter.
    /// @param fromChainId Source chain (EIP-155)
    /// @param glacisPayload Received payload with embedded GlacisData
    function receiveMessage(
        uint256 fromChainId,
        bytes memory glacisPayload
    ) external;
}

// lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// lib/v1-core/contracts/client/GlacisAccessControlClient.sol

/// @title Glacis Access Control Client
/// @dev This contract encapsulates Glacis Access Control client logic. Contracts inheriting this will have access to
/// Glacis Access control features  
abstract contract GlacisAccessControlClient is GlacisCommons, IGlacisAccessControlClient {
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) public allowedRoutes;

    bytes32 constant internal WILD_BYTES = bytes32(uint256(WILDCARD));
    address constant internal WILD_ADDR = address(WILDCARD);

    /// @notice Adds an allowed route for this client
    /// @param route Route to be added
    function _addAllowedRoute(
        GlacisRoute memory route
    ) internal {
        allowedRoutes[route.fromChainId][route.fromAddress][route.fromAdapter] = true;
    }

    /// @notice Removes an allowed route for this client
    /// @param route Allowed route to be removed
    function _removeAllowedRoute(
        GlacisRoute calldata route
    ) internal {
        allowedRoutes[route.fromChainId][route.fromAddress][route.fromAdapter] = false;
    }

    /// @notice Queries if a route from path GMP+Chain+Address is allowed for this client
    /// @param route_ Incoming message route
    /// @return True if route is allowed, false otherwise
    function isAllowedRoute(
        GlacisRoute memory route_,
        bytes memory // payload
    ) public view override returns (bool) {
        return
            allowedRoutes[route_.fromChainId][route_.fromAddress][route_.fromAdapter] ||
            allowedRoutes[WILDCARD][route_.fromAddress][route_.fromAdapter] ||
            allowedRoutes[WILDCARD][WILD_BYTES][route_.fromAdapter] ||
            allowedRoutes[route_.fromChainId][WILD_BYTES][route_.fromAdapter] ||
            (uint160(route_.fromAdapter) <= GLACIS_RESERVED_IDS && (
                allowedRoutes[route_.fromChainId][route_.fromAddress][WILD_ADDR] ||
                allowedRoutes[route_.fromChainId][WILD_BYTES][WILD_ADDR] ||
                allowedRoutes[WILDCARD][route_.fromAddress][WILD_ADDR] ||
                allowedRoutes[WILDCARD][WILD_BYTES][WILD_ADDR]
            ));
    }
}

// lib/v1-core/contracts/interfaces/IGlacisClient.sol

/// @title IGlacisClient
/// @notice An interface that defines the GMP modules (adapters) that the GlacisRouter interacts with.
abstract contract IGlacisClient is IGlacisAccessControlClient {
    uint256 private immutable DEFAULT_QUORUM;

    /// @param _defaultQuorum The default quorum that you would like. If you implement dynamic quorum, this value can be ignored 
    /// and set to 0  
    constructor(uint256 _defaultQuorum) {
        DEFAULT_QUORUM = _defaultQuorum;
    }

    /// @notice Receives message from GMP(s) through GlacisRouter
    /// @param fromAdapters Used adapters that sent this message (that reached quorum requirements)
    /// @param fromChainId Source chain (Glacis chain ID)
    /// @param fromAddress Source address on source chain
    /// @param payload Routed payload
    function receiveMessage(
        address[] calldata fromAdapters,
        uint256 fromChainId,
        bytes32 fromAddress,
        bytes calldata payload
    ) external virtual;

    /// @notice The quorum of messages that the contract expects with a specific message
    function getQuorum(
        GlacisCommons.GlacisData memory,    // glacis data
        bytes memory,                       // payload
        uint256                             // unique messages received so far (for dynamic quorum, usually unused)
    ) public view virtual returns (uint256) {
        return DEFAULT_QUORUM;
    }
}

// lib/v1-core/contracts/managers/GlacisRemoteCounterpartManager.sol

error GlacisRemoteCounterpartManager__RemoteCounterpartCannotHaveChainIdZero();
error GlacisRemoteCounterpartManager__CounterpartsAndChainIDsMustHaveSameLength();

/// @title Glacis Remote Counterpart Manager
/// @notice An inheritable contract that allows an owner to add and remove remote counterparts
/// @notice Is an ownable contract
contract GlacisRemoteCounterpartManager is
    IGlacisRemoteCounterpartManager,
    Ownable2Step
{
    mapping(uint256 => bytes32) internal remoteCounterpart;

    /// @notice Adds an authorized glacis counterpart component in a remote chain that interacts with this component
    /// @param chainIDs An array with chains of the glacis remote components
    /// @param counterpart An array of addresses of the glacis components on remote chains
    function addRemoteCounterparts(
        uint256[] calldata chainIDs,
        bytes32[] calldata counterpart
    ) external onlyOwner {
        if (chainIDs.length != counterpart.length)
            revert GlacisRemoteCounterpartManager__CounterpartsAndChainIDsMustHaveSameLength();
        for (uint256 i; i < chainIDs.length; ++i) {
            if (chainIDs[i] == 0)
                revert GlacisRemoteCounterpartManager__RemoteCounterpartCannotHaveChainIdZero();
            remoteCounterpart[chainIDs[i]] = counterpart[i];
        }
    }

    /// @notice Removes an authorized glacis counterpart component on remote chain that this components interacts with
    /// @param chainId The chainId to remove the remote component
    function removeRemoteCounterpart(uint256 chainId) external onlyOwner {
        if (chainId == 0)
            revert GlacisRemoteCounterpartManager__RemoteCounterpartCannotHaveChainIdZero();
        delete remoteCounterpart[chainId];
    }

    /// @notice Gets an authorized glacis counterpart component on remote chain that this components interacts with
    /// @param chainId The chainId to of the remote component
    function getRemoteCounterpart(
        uint256 chainId
    ) public view returns (bytes32) {
        return remoteCounterpart[chainId];
    }
}

// lib/v1-core/contracts/client/GlacisClient.sol

error GlacisClient__CanOnlyBeCalledByRouter();
error GlacisClient__InvalidRouterAddress();

/// @title Glacis Client
/// @dev This contract encapsulates Glacis client side logic, contracts inheriting this will have access to all
/// Glacis features
abstract contract GlacisClient is GlacisAccessControlClient, IGlacisClient {
    address public immutable GLACIS_ROUTER;

    event GlacisClient__MessageRouted(
        bytes32 indexed messageId,
        uint256 toChainId,
        bytes32 to
    );
    
    event GlacisClient__MessageArrived(
        address[] fromAdapters,
        uint256 fromChainId,
        bytes32 fromAddress
    );

    /// @param _glacisRouter This chain's deployment of the GlacisRouter  
    /// @param _quorum The initial default quorum for this client. If dynamic quorum is to be implemented (depending on payload)
    /// this value can be ignored and set to 0  
    constructor(
        address _glacisRouter,
        uint256 _quorum
    ) GlacisAccessControlClient() IGlacisClient(_quorum) {
        if (_glacisRouter == address(0))
            revert GlacisClient__InvalidRouterAddress();
        GLACIS_ROUTER = _glacisRouter;
    }

    /// @notice Routes the payload to the specific address on destination chain through GlacisRouter using a single specified GMP
    /// @param chainId Destination chain (Glacis chain ID)
    /// @param to Destination address on remote chain
    /// @param payload Payload to be routed
    /// @param adapter Glacis ID of the GMP to be used for the routing
    /// @param refundAddress Address to refund excess gas payment
    /// @param gasPayment Amount of gas to cover source and destination gas fees (excess will be refunded)
    function _routeSingle(
        uint256 chainId,
        bytes32 to,
        bytes memory payload,
        address adapter,
        address refundAddress,
        uint256 gasPayment
    ) internal returns (bytes32) {
        address[] memory adapters = new address[](1);
        adapters[0] = adapter;
        CrossChainGas[] memory fees = new CrossChainGas[](1);
        fees[0] = CrossChainGas({ 
            gasLimit: 0,
            nativeCurrencyValue: uint128(gasPayment)
        });
        (bytes32 messageId,) = IGlacisRouter(GLACIS_ROUTER).route{
            value: gasPayment
        }(chainId, to, payload, adapters, fees, refundAddress, false);
        emit GlacisClient__MessageRouted(messageId, chainId, to);
        return messageId;
    }

    /// @notice Routes the payload to the specific address on destination chain through GlacisRouter using
    /// specified GMPs.
    /// @param chainId Destination chain (Glacis chain ID)
    /// @param to Destination address on remote chain
    /// @param payload Payload to be routed
    /// @param adapters The adapters to use for redundant routing
    /// @param fees Payment for each GMP to cover source and destination gas fees (excess will be refunded)
    /// @param refundAddress Address to refund excess gas payment
    /// @param gasPayment Amount of gas to cover source and destination gas fees (excess will be refunded)
    function _routeRedundant(
        uint256 chainId,
        bytes32 to,
        bytes memory payload,
        address[] memory adapters,
        CrossChainGas[] memory fees,
        address refundAddress,
        uint256 gasPayment
    ) internal returns (bytes32) {
        (bytes32 messageId,) = IGlacisRouter(GLACIS_ROUTER).route{
            value: gasPayment
        }(chainId, to, payload, adapters, fees, refundAddress, false);
        emit GlacisClient__MessageRouted(messageId, chainId, to);
        return messageId;
    }

    /// @notice Routes the payload to the specific address on destination chain through GlacisRouter using GMPs
    /// specified in gmps array
    /// @param chainId Destination chain (Glacis chain ID)
    /// @param to Destination address on remote chain
    /// @param payload Payload to be routed
    /// @param adapters An array of custom adapters to be used for the routing
    /// @param fees Payment for each GMP to cover source and destination gas fees (excess will be refunded)
    /// @param refundAddress Address to refund excess gas payment
    /// @param retryable True to enable retry feature for this message
    /// @param gasPayment Amount of gas to cover source and destination gas fees (excess will be refunded)
    function _route(
        uint256 chainId,
        bytes32 to,
        bytes memory payload,
        address[] memory adapters,
        CrossChainGas[] memory fees,
        address refundAddress,
        bool retryable,
        uint256 gasPayment
    ) internal returns (bytes32,uint256) {
        (bytes32 messageId,uint256 nonce) = IGlacisRouter(GLACIS_ROUTER).route{
            value: gasPayment
        }(chainId, to, payload, adapters, fees, refundAddress, retryable);
        emit GlacisClient__MessageRouted(messageId, chainId, to);
        return (messageId,nonce);
    }

    /// @notice Routes the payload to the specific address on destination chain through GlacisRouter using GMPs
    /// specified in gmps array
    /// @param chainId Destination chain (Glacis chain ID)
    /// @param to Destination address on remote chain
    /// @param payload Payload to be routed
    /// @param adapters An array of adapters to be used for the routing
    /// @param fees Payment for each GMP to cover source and destination gas fees (excess will be refunded)
    /// @param refundAddress Address to refund excess gas payment
    /// @param messageId The message ID of the message to retry
    /// @param nonce The nonce emitted by the original sent message
    /// @param gasPayment Amount of gas to cover source and destination gas fees (excess will be refunded)
    function _retryRoute(
        uint256 chainId,
        bytes32 to,
        bytes memory payload,
        address[] memory adapters,
        CrossChainGas[] memory fees,
        address refundAddress,
        bytes32 messageId,
        uint256 nonce,
        uint256 gasPayment
    ) internal returns (bytes32) {
        IGlacisRouter(GLACIS_ROUTER).routeRetry{value: gasPayment}(
            chainId,
            to,
            payload,
            adapters,
            fees,
            refundAddress,
            messageId,
            nonce
        );
        emit GlacisClient__MessageRouted(messageId, chainId, to);
        return messageId;
    }

    /// @notice Receives message from GMP(s) through GlacisRouter
    /// @param fromAdapters addresses of the adapters sent this message (that reached quorum requirements)
    /// @param fromChainId Source chain (Glacis chain ID)
    /// @param fromAddress Source address on source chain
    /// @param payload Routed payload
    function receiveMessage(
        address[] memory fromAdapters,
        uint256 fromChainId,
        bytes32 fromAddress,
        bytes memory payload
    ) external virtual override {
        if (msg.sender != GLACIS_ROUTER)
            revert GlacisClient__CanOnlyBeCalledByRouter();
        _receiveMessage(fromAdapters, fromChainId, fromAddress, payload);
        emit GlacisClient__MessageArrived(fromAdapters, fromChainId, fromAddress);
    }

    /// @notice Receives message from GMP(s) through GlacisRouter
    /// @param fromAdapters Adapter addresses
    /// @param fromChainId Source chain (Glacis chain ID)
    /// @param fromAddress Source address on source chain
    /// @param payload Routed payload
    function _receiveMessage(
        address[] memory fromAdapters,
        uint256 fromChainId,
        bytes32 fromAddress,
        bytes memory payload
    ) internal virtual {}
}

// lib/v1-core/contracts/mediators/SimpleTokenMediator.sol

error SimpleTokenMediator__DestinationChainUnavailable();

/// @title Simple Token Mediator
/// @notice This contract burns and mints XERC-20 tokens without additional
/// features. There is no additional Glacis XERC-20 interface, tokens cannot
/// be sent with a payload, and there is no special interface for a client to
/// inherit from.
/// The `route` function has been replaced with a `sendCrossChain`
/// function to differentiate it from the routing with payload that the
/// GlacisTokenMediator has. Similarly, the retry function has been replaced
/// with a `sendCrossChainRetry`.
/// Developers using this must ensure that their token has the same address on
/// each chain.
contract SimpleTokenMediator is GlacisRemoteCounterpartManager, GlacisClient {
    using AddressBytes32 for address;
    using AddressBytes32 for bytes32;

    event SimpleTokenMediator__TokensMinted(address indexed, address indexed, uint256);
    event SimpleTokenMediator__TokensBurnt(address indexed, address indexed, uint256);

    constructor(
        address _glacisRouter,
        uint256 _quorum,
        address _owner
    ) GlacisClient(_glacisRouter, _quorum) {
        _transferOwnership(_owner);
    }

    address public xERC20Token;

    /// @notice Allows the owner to set the single xERC20 that this mediator sends
    /// @param _xERC20Token The address of the token that this mediator sends
    function setXERC20(address _xERC20Token) public onlyOwner {
        xERC20Token = _xERC20Token;
    }

    /// @notice Routes the payload to the specific address on destination chain through GlacisRouter using GMPs
    /// specified in gmps array
    /// @param chainId Destination chain (Glacis chain ID)
    /// @param to Destination address on remote chain
    /// @param adapters The GMP Adapters to use for routing
    /// @param fees Payment for each GMP to cover source and destination gas fees (excess will be refunded)
    /// @param refundAddress Address to refund excess gas payment
    /// @param tokenAmount Amount of token to send to remote contract
    function sendCrossChain(
        uint256 chainId,
        bytes32 to,
        address[] memory adapters,
        CrossChainGas[] memory fees,
        address refundAddress,
        uint256 tokenAmount
    ) public payable virtual returns (bytes32, uint256) {
        bytes32 destinationTokenMediator = remoteCounterpart[chainId];
        if (destinationTokenMediator == bytes32(0))
            revert SimpleTokenMediator__DestinationChainUnavailable();

        IXERC20(xERC20Token).burn(msg.sender, tokenAmount);
        bytes memory tokenPayload = packTokenPayload(to, tokenAmount);
        emit SimpleTokenMediator__TokensBurnt(
            msg.sender,
            xERC20Token,
            tokenAmount
        );
        return
            IGlacisRouter(GLACIS_ROUTER).route{value: msg.value}(
                chainId,
                destinationTokenMediator,
                tokenPayload,
                adapters,
                fees,
                refundAddress,
                true // Token Mediator always enables retry
            );
    }

    /// @notice Retries routing the payload to the specific address on destination chain using specified GMPs
    /// @param chainId Destination chain (Glacis chain ID)
    /// @param to Destination address on remote chain
    /// @param adapters The GMP Adapters to use for routing
    /// @param fees Payment for each GMP to cover source and destination gas fees (excess will be refunded)
    /// @param refundAddress Address to refund excess gas payment
    /// @param messageId The message ID of the message to retry
    /// @param nonce The nonce emitted by the original message routing
    /// @param tokenAmount Amount of token to send to remote contract
    /// @return A tuple with a bytes32 messageId and a uint256 nonce
    function sendCrossChainRetry(
        uint256 chainId,
        bytes32 to,
        address[] memory adapters,
        CrossChainGas[] memory fees,
        address refundAddress,
        bytes32 messageId,
        uint256 nonce,
        uint256 tokenAmount
    ) public payable virtual returns (bytes32, uint256) {
        // Pack with a function
        bytes memory tokenPayload = packTokenPayload(to, tokenAmount);

        // Use helper function (otherwise stack too deep)
        return
            _routeRetry(
                chainId,
                tokenPayload,
                adapters,
                fees,
                refundAddress,
                messageId,
                nonce
            );
    }

    /// A private function to help with stack to deep during retries.
    function _routeRetry(
        uint256 chainId,
        bytes memory tokenPayload,
        address[] memory adapters,
        CrossChainGas[] memory fees,
        address refundAddress,
        bytes32 messageId,
        uint256 nonce
    ) private returns (bytes32, uint256) {
        bytes32 destinationTokenMediator = remoteCounterpart[chainId];
        if (destinationTokenMediator == bytes32(0))
            revert SimpleTokenMediator__DestinationChainUnavailable();

        return
            IGlacisRouter(GLACIS_ROUTER).routeRetry{value: msg.value}(
                chainId,
                destinationTokenMediator,
                tokenPayload,
                adapters,
                fees,
                refundAddress,
                messageId,
                nonce
            );
    }

    /// @notice Receives a cross chain message from an IGlacisAdapter.
    /// @param payload Received payload from Glacis Router
    function _receiveMessage(
        address[] memory, // fromAdapters
        uint256, // fromChainId
        bytes32, // fromAddress
        bytes memory payload
    ) internal override {
        // Access control security is handled by allowed routes. No need to check for remoteCounterpart

        (bytes32 to, uint256 tokenAmount) = decodeTokenPayload(payload);

        // Mint
        address toAddress = to.toAddress();
        IXERC20(xERC20Token).mint(toAddress, tokenAmount);
        emit SimpleTokenMediator__TokensMinted(
            toAddress,
            xERC20Token,
            tokenAmount
        );
    }

    /// Packs a token payload into this contract's standard.
    function packTokenPayload(
        bytes32 to,
        uint256 tokenAmount
    ) internal pure returns (bytes memory) {
        return abi.encode(to, tokenAmount);
    }

    /// Decodes a token payload into this contract's standard.
    function decodeTokenPayload(
        bytes memory payload
    ) internal pure returns (bytes32 to, uint256 tokenAmount) {
        (to, tokenAmount) = abi.decode(payload, (bytes32, uint256));
    }

    /// @notice Add an allowed route for this client
    /// @param allowedRoute Route to be added
    function addAllowedRoute(
        GlacisCommons.GlacisRoute memory allowedRoute
    ) external onlyOwner {
        _addAllowedRoute(allowedRoute);
    }

    /// @notice Removes an allowed route for this client
    /// @param route Allowed route to be removed
    function removeAllowedRoute(
        GlacisCommons.GlacisRoute calldata route
    ) external onlyOwner {
        _removeAllowedRoute(route);
    }
}
