// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {KipuBank} from "../../src/KipuBankV3.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockChainlinkAggregator} from "../mocks/MockChainlinkAggregator.sol";
import {MockUniswapRouter} from "../mocks/MockUniswapRouter.sol";

/**
 * @title KipuBankTestBase
 * @notice Base contract con setup común para todos los tests de KipuBank
 */
contract KipuBankTestBase is Test {
    // Contratos principales
    KipuBank public kipuBank;
    MockERC20 public usdc;
    MockERC20 public otherToken; // Ej: DAI, WBTC, etc.
    MockERC20 public weth;
    MockChainlinkAggregator public ethUsdFeed;
    MockUniswapRouter public uniswapRouter;

    // Usuarios de prueba
    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    address public attacker; // Para tests de reentrancy

    // Constantes para tests
    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant INITIAL_USDC = 1_000_000 * 1e6; // 1M USDC
    uint256 public constant INITIAL_OTHER_TOKEN = 1_000_000 * 1e18; // 1M tokens

    uint256 public constant BANK_CAP = 100 ether; // Cap por usuario por token
    uint256 public constant MAX_WITHDRAW_AMOUNT = 5000 * 1e8; // $5000 en formato de 8 decimales

    uint256 public constant SMALL_AMOUNT = 0.1 ether;
    uint256 public constant MEDIUM_AMOUNT = 1 ether;
    uint256 public constant LARGE_AMOUNT = 10 ether;

    uint256 public constant ETH_PRICE = 2000 * 1e8; // $2000 ETH/USD

    // Eventos del contrato KipuBank (para verificación)
    event KipuBank_Deposit(address origin, uint256 valor);
    event KipuBank_Withdraw(address destination, uint256 valor);
    event KipuBank_ChainlinkFeedUpdated(address feed);

    function setUp() public virtual {
        // Configurar usuarios
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        attacker = makeAddr("attacker");

        // Deploy WETH mock
        weth = new MockERC20("Wrapped Ether", "WETH", 18);

        // Deploy USDC mock (6 decimales como en mainnet)
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // Deploy otro token (18 decimales)
        otherToken = new MockERC20("Other Token", "OTHER", 18);

        // Deploy Chainlink price feed (ETH/USD con 8 decimales)
        ethUsdFeed = new MockChainlinkAggregator(
            8,
            "ETH / USD",
            1
        );
        ethUsdFeed.setAnswer(int256(ETH_PRICE)); // $2000

        // Deploy Uniswap Router
        uniswapRouter = new MockUniswapRouter(address(weth));

        // Deploy KipuBank
        kipuBank = new KipuBank(
            BANK_CAP,
            MAX_WITHDRAW_AMOUNT,
            address(ethUsdFeed),
            address(usdc),
            address(uniswapRouter)
        );

        // Dar ETH a todos los usuarios
        vm.deal(alice, INITIAL_BALANCE);
        vm.deal(bob, INITIAL_BALANCE);
        vm.deal(charlie, INITIAL_BALANCE);
        vm.deal(attacker, INITIAL_BALANCE);

        // Mint USDC a usuarios
        usdc.mint(alice, INITIAL_USDC);
        usdc.mint(bob, INITIAL_USDC);
        usdc.mint(charlie, INITIAL_USDC);

        // Mint otros tokens a usuarios
        otherToken.mint(alice, INITIAL_OTHER_TOKEN);
        otherToken.mint(bob, INITIAL_OTHER_TOKEN);
        otherToken.mint(charlie, INITIAL_OTHER_TOKEN);

        // Mint tokens al router para swaps
        usdc.mint(address(uniswapRouter), INITIAL_USDC * 10);
        otherToken.mint(address(uniswapRouter), INITIAL_OTHER_TOKEN * 10);

        // Labels para debugging
        vm.label(address(kipuBank), "KipuBank");
        vm.label(address(usdc), "USDC");
        vm.label(address(otherToken), "OtherToken");
        vm.label(address(weth), "WETH");
        vm.label(address(ethUsdFeed), "ETH/USD Feed");
        vm.label(address(uniswapRouter), "Uniswap Router");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(attacker, "Attacker");
    }

    // Helper functions

    /**
     * @notice Helper para aprobar USDC desde un usuario al KipuBank
     */
    function approveUSDC(address user, uint256 amount) public {
        vm.prank(user);
        usdc.approve(address(kipuBank), amount);
    }

    /**
     * @notice Helper para aprobar otros tokens desde un usuario al KipuBank
     */
    function approveOtherToken(address user, uint256 amount) public {
        vm.prank(user);
        otherToken.approve(address(kipuBank), amount);
    }

    /**
     * @notice Helper para depositar ETH desde un usuario
     */
    function depositEtherAs(address user, uint256 amount) public {
        vm.prank(user);
        kipuBank.depositEther{value: amount}();
    }

    /**
     * @notice Helper para depositar USDC desde un usuario
     */
    function depositUSDCAs(address user, uint256 amount) public {
        approveUSDC(user, amount);
        vm.prank(user);
        kipuBank.depositUSDC(amount);
    }

    /**
     * @notice Helper para depositar otro token desde un usuario
     */
    function depositOtherTokenAs(address user, uint256 amount) public {
        approveOtherToken(user, amount);
        vm.prank(user);
        kipuBank.depositOtherToken(amount, address(otherToken));
    }

    /**
     * @notice Helper para verificar el balance ETH de un usuario en KipuBank
     */
    function getEtherBalance(address user) public view returns (uint256) {
        return kipuBank.vaults(user, address(0));
    }

    /**
     * @notice Helper para verificar el balance USDC de un usuario en KipuBank
     */
    function getUSDCBalance(address user) public view returns (uint256) {
        return kipuBank.vaults(user, address(usdc));
    }

    /**
     * @notice Helper para convertir ETH a USD usando el precio del feed
     */
    function convertEthToUSD(uint256 ethAmount) public view returns (uint256) {
        return (ethAmount * uint256(ETH_PRICE)) / 1e20;
    }

    /**
     * @notice Helper para verificar que un usuario puede retirar cierta cantidad
     */
    function canWithdraw(address user, uint256 ethAmount) public view returns (bool) {
        uint256 userBalance = getEtherBalance(user);
        if (userBalance < ethAmount) return false;

        uint256 valueInUSD = convertEthToUSD(ethAmount);
        return valueInUSD <= MAX_WITHDRAW_AMOUNT;
    }
}
