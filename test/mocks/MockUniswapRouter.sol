// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MockUniswapRouter
 * @notice Mock de Uniswap V2 Router para testing con swaps configurables
 */
contract MockUniswapRouter {
    using SafeERC20 for IERC20;

    address public immutable WETH;

    // Configuración para simular diferentes escenarios
    bool public shouldRevert;
    uint256 public swapRatio = 1e18; // 1:1 por defecto (ajustable para simular slippage)

    // Eventos
    event SwapExecuted(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(address _weth) {
        WETH = _weth;
    }

    /**
     * @notice Simula un swap de tokens exactos
     * @dev Transfiere tokens del caller al router, luego transfiere tokens de salida
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(block.timestamp <= deadline, "MockRouter: EXPIRED");
        require(path.length >= 2, "MockRouter: INVALID_PATH");
        require(!shouldRevert, "MockRouter: SWAP_FAILED");

        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        // Transferir tokens de entrada del caller al router
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Calcular cantidad de salida basada en el ratio configurado
        uint256 amountOut = (amountIn * swapRatio) / 1e18;
        require(amountOut >= amountOutMin, "MockRouter: INSUFFICIENT_OUTPUT_AMOUNT");

        // Transferir tokens de salida al destinatario
        IERC20(tokenOut).safeTransfer(to, amountOut);

        // Construir array de amounts
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        amounts[path.length - 1] = amountOut;

        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut);
    }

    /**
     * @notice Simula un swap de ETH exacto por tokens
     */
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {
        require(block.timestamp <= deadline, "MockRouter: EXPIRED");
        require(path.length >= 2, "MockRouter: INVALID_PATH");
        require(path[0] == WETH, "MockRouter: INVALID_PATH");
        require(!shouldRevert, "MockRouter: SWAP_FAILED");

        uint256 amountIn = msg.value;
        address tokenOut = path[path.length - 1];

        // Calcular cantidad de salida basada en el ratio configurado
        uint256 amountOut = (amountIn * swapRatio) / 1e18;
        require(amountOut >= amountOutMin, "MockRouter: INSUFFICIENT_OUTPUT_AMOUNT");

        // Transferir tokens de salida al destinatario
        IERC20(tokenOut).safeTransfer(to, amountOut);

        // Construir array de amounts
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        amounts[path.length - 1] = amountOut;

        emit SwapExecuted(WETH, tokenOut, amountIn, amountOut);
    }

    // Funciones de configuración para tests

    /**
     * @notice Configura si el swap debe revertir (para simular errores)
     */
    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    /**
     * @notice Configura el ratio de swap (1e18 = 1:1, 2e18 = 2:1, etc.)
     */
    function setSwapRatio(uint256 _ratio) external {
        swapRatio = _ratio;
    }

    /**
     * @notice Permite al contrato recibir ETH
     */
    receive() external payable {}
}
