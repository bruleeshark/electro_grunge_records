// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║        ELECTRO GRUNGE COOP COIN  ( 💾 )                 ║
 * ║                                                              ║
 * ║  Total Supply:  100.000000000000000000  (100.0 tokens)       ║
 * ║  Decimals:      18                                           ║
 * ║  Standard:      ERC-20 + EIP-2612 Permit                    ║
 * ║  Ownership:     NONE — immutable at deploy                   ║
 * ║  Mintable:      NO — fixed supply forever                    ║
 * ║                                                              ║
 * ║  Allocation at deploy:                                       ║
 * ║    50.0  →  LP address (burned to 0xdead after pool)         ║
 * ║    33.0  →  Earthdrop wallet (IRL token drops, LA)           ║
 * ║    10.0  →  Advisors / seed investors                        ║
 * ║     5.0  →  Team / employees / DAO members                   ║
 * ║     1.0  →  Founder (Rachel / Cache Crash)                   ║
 * ║     1.0  →  Cofounder reserve (multisig, TBD)                ║
 * ║   ─────                                                      ║
 * ║   100.0  →  TOTAL SUPPLY (immutable)                         ║
 * ║                                                              ║
 * ║  Governance tiers:                                           ║
 * ║    any amount  →  cultural DAO votes (signings, merch, etc)  ║
 * ║    >= 1.0      →  financial votes (treasury, hiring, etc)    ║
 * ╚══════════════════════════════════════════════════════════════╝
 */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title  Electro Grunge Coop Coin
 * @notice Fixed-supply ERC-20 with EIP-2612 Permit. No owner. No mint.
 *         100.0 tokens. That's it.
 */
contract EGPT is IERC20, IERC20Metadata, IERC20Permit, IERC165 {

    // ─── ERC-20 storage ────────────────────────────────────────────────────

    string  private constant _NAME   = "Electro Grunge Coop Coin";
    string  private constant _SYMBOL = "\xF0\x9F\x92\xBE"; // 💾 UTF-8

    uint8   private constant _DECIMALS = 18;
    uint256 private constant _TOTAL    = 100 * 10 ** 18; // 100.0 tokens

    mapping(address => uint256)                     private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ─── EIP-2612 Permit storage ────────────────────────────────────────────

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 private constant _PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) private _nonces;

    bytes32 private immutable _DOMAIN_SEPARATOR;

    // ─── Allocation addresses — SET BEFORE DEPLOY ──────────────────────────

    /// @dev Replace these with your real addresses before deploying.
    address public constant LP_ADDRESS          = address(0); // TODO: Curve pool / 0xdead after LP creation
    address public constant EARTHDROP_ADDRESS   = address(0); // TODO: earthdrop hot wallet
    address public constant ADVISORS_ADDRESS    = address(0); // TODO: advisor multisig
    address public constant TEAM_ADDRESS        = address(0); // TODO: team multisig
    address public constant FOUNDER_ADDRESS     = address(0); // TODO: Rachel's wallet
    address public constant COFOUNDER_ADDRESS   = address(0); // TODO: cofounder reserve multisig

    // ─── Events ─────────────────────────────────────────────────────────────

    event GovernanceTierNote(
        string culturalThreshold,
        string financialThreshold
    );

    // ─── Constructor ────────────────────────────────────────────────────────

    constructor() {
        // EIP-712 domain separator — chain-specific, replay-safe
        _DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(_NAME)),
            keccak256("1"),
            block.chainid,
            address(this)
        ));

        // ── Mint all 100.0 tokens at deploy, split per allocation ──────────
        // NOTE: replace address(0) placeholders above with real addresses
        // before deploying. Sending to address(0) will revert.

        _mint(LP_ADDRESS,        50 * 10 ** 18); // 50.0  → LP (burn to 0xdead after pool)
        _mint(EARTHDROP_ADDRESS, 33 * 10 ** 18); // 33.0  → earthdrop
        _mint(ADVISORS_ADDRESS,  10 * 10 ** 18); // 10.0  → advisors / seed
        _mint(TEAM_ADDRESS,       5 * 10 ** 18); //  5.0  → team / DAO
        _mint(FOUNDER_ADDRESS,    1 * 10 ** 18); //  1.0  → founder
        _mint(COFOUNDER_ADDRESS,  1 * 10 ** 18); //  1.0  → cofounder reserve

        // Sanity check — total must equal _TOTAL
        require(_totalSupplyTracker == _TOTAL, "EGPT: supply mismatch");

        emit GovernanceTierNote(
            "any balance > 0: cultural DAO votes (signings, merch, events)",
            "balance >= 1e18 (1.0 token): financial votes (treasury, hiring)"
        );
    }

    // ─── Internal supply tracker ────────────────────────────────────────────

    uint256 private _totalSupplyTracker;

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "EGPT: mint to zero address");
        _totalSupplyTracker += amount;
        _balances[to]       += amount;
        emit Transfer(address(0), to, amount);
    }

    // ─── ERC-20 ─────────────────────────────────────────────────────────────

    function name()        external pure override returns (string memory) { return _NAME; }
    function symbol()      external pure override returns (string memory) { return _SYMBOL; }
    function decimals()    external pure override returns (uint8)         { return _DECIMALS; }
    function totalSupply() external pure override returns (uint256)       { return _TOTAL; }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 current = _allowances[from][msg.sender];
        if (current != type(uint256).max) {
            require(current >= amount, "EGPT: insufficient allowance");
            unchecked { _allowances[from][msg.sender] = current - amount; }
            emit Approval(from, msg.sender, current - amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "EGPT: transfer from zero");
        require(to   != address(0), "EGPT: transfer to zero");
        require(_balances[from] >= amount, "EGPT: insufficient balance");
        unchecked {
            _balances[from] -= amount;
            _balances[to]   += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner   != address(0), "EGPT: approve from zero");
        require(spender != address(0), "EGPT: approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // ─── EIP-2612 Permit ────────────────────────────────────────────────────

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external override {
        require(block.timestamp <= deadline, "EGPT: permit expired");
        bytes32 structHash = keccak256(abi.encode(
            _PERMIT_TYPEHASH, owner, spender, value, _nonces[owner]++, deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, structHash));
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "EGPT: invalid permit");
        _approve(owner, spender, value);
    }

    function nonces(address owner) external view override returns (uint256) {
        return _nonces[owner];
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    // ─── EIP-165 ────────────────────────────────────────────────────────────

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId         ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // ─── Governance view helpers ─────────────────────────────────────────────

    /**
     * @notice Returns true if the address can vote on cultural DAO proposals
     *         (signings, merch designs, events, etc).
     *         Threshold: any nonzero balance.
     */
    function canVoteCultural(address account) external view returns (bool) {
        return _balances[account] > 0;
    }

    /**
     * @notice Returns true if the address can vote on financial DAO proposals
     *         (treasury allocation, hiring, protocol parameters).
     *         Threshold: >= 1.0 token (1e18 wei).
     */
    function canVoteFinancial(address account) external view returns (bool) {
        return _balances[account] >= 1 * 10 ** 18;
    }
}
